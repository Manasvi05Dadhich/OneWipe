// test-transaction.js
require('dotenv').config();
const { ethers } = require('ethers');
const fs = require('fs');
const path = require('path');

const signing = require('./api/signing');

async function testTransaction() {
    try {
        console.log('=== Testing Actual Transaction ===');
        
        // Load contract data
        const CONTRACT_JSON_PATH = path.join(__dirname, 'deployed', 'contract.json');
        const contractData = JSON.parse(fs.readFileSync(CONTRACT_JSON_PATH, 'utf8'));
        
        // Set up provider and wallet
        const provider = new ethers.providers.JsonRpcProvider(process.env.AMOY_RPC_URL);
        const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
        
        let abi = contractData.abi;
        if (typeof abi === 'string') {
            abi = JSON.parse(abi);
        }
        
        const registry = new ethers.Contract(contractData.address, abi, wallet);
        
        // Simulate the exact same data as the API call
        const certID = `test-cert-${Date.now()}`;
        const certJSON = {
            device: "Test Device",
            wipedBy: "Test User",
            timestamp: new Date().toISOString(),
            issuer: wallet.address
        };
        
        console.log('\\n=== Preparing Certificate ===');
        console.log('Certificate ID:', certID);
        console.log('Certificate JSON:', certJSON);
        
        // Create canonical string (same as API)
        const canonicalString = JSON.stringify(
            Object.keys(certJSON).sort().reduce((o, k) => {
                o[k] = certJSON[k];
                return o;
            }, {})
        );
        
        console.log('\\n=== Signing Certificate ===');
        const signatureBase64 = signing.signString(canonicalString);
        const signedBlob = canonicalString + "||" + signatureBase64;
        const certHashHex = signing.sha256Hex(signedBlob);
        
        console.log('Canonical String:', canonicalString);
        console.log('Signature (first 50 chars):', signatureBase64.substring(0, 50) + '...');
        console.log('Certificate Hash:', certHashHex);
        
        console.log('\\n=== Estimating Gas ===');
        try {
            const gasEstimate = await registry.estimateGas.storeCertificate(certID, certHashHex);
            console.log('✅ Gas estimate:', gasEstimate.toString());
            
            // Get current gas price
            const gasPrice = await provider.getGasPrice();
            console.log('✅ Gas price:', ethers.utils.formatUnits(gasPrice, 'gwei'), 'gwei');
            
            // Calculate cost
            const txCost = gasEstimate.mul(gasPrice);
            console.log('✅ Transaction cost:', ethers.utils.formatEther(txCost), 'MATIC');
            
        } catch (err) {
            console.error('❌ Gas estimation failed:', err.message);
            
            // Try to get more detailed error
            if (err.error) {
                console.error('❌ Detailed error:', err.error);
            }
            if (err.reason) {
                console.error('❌ Reason:', err.reason);
            }
            return;
        }
        
        console.log('\\n=== Sending Transaction ===');
        try {
            // Try with explicit gas settings
            const tx = await registry.storeCertificate(certID, certHashHex, { 
                gasLimit: 300000,
                gasPrice: ethers.utils.parseUnits('30', 'gwei') // 30 gwei
            });
            
            console.log('✅ Transaction submitted:', tx.hash);
            console.log('⏳ Waiting for confirmation...');
            
            const receipt = await tx.wait();
            console.log('✅ Transaction confirmed!');
            console.log('   Block:', receipt.blockNumber);
            console.log('   Hash:', receipt.transactionHash);
            console.log('   Gas used:', receipt.gasUsed.toString());
            console.log('   Polygonscan:', `https://amoy.polygonscan.com/tx/${receipt.transactionHash}`);
            
            // Verify the certificate was stored
            console.log('\\n=== Verifying Storage ===');
            const storedCert = await registry.getCertificate(certID);
            console.log('✅ Certificate verified on chain:', {
                certHash: storedCert.certHash,
                timestamp: new Date(storedCert.timestamp * 1000).toISOString(),
                issuer: storedCert.issuer
            });
            
        } catch (err) {
            console.error('❌ Transaction failed:', err.message);
            
            // More detailed error logging
            if (err.error) {
                console.error('❌ Error details:', err.error);
            }
            if (err.reason) {
                console.error('❌ Reason:', err.reason);
            }
            if (err.code) {
                console.error('❌ Error code:', err.code);
            }
            
            // Check if it's a known error type
            if (err.message.includes('insufficient funds')) {
                console.error('💰 This is a balance issue');
            } else if (err.message.includes('gas')) {
                console.error('⛽ This is a gas-related issue');
            } else if (err.message.includes('nonce')) {
                console.error('🔢 This is a nonce issue');
            } else if (err.message.includes('timeout')) {
                console.error('⏰ This is a timeout issue');
            }
        }
        
    } catch (err) {
        console.error('❌ Test failed:', err);
    }
}

testTransaction();