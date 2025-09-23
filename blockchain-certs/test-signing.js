// test-signing.js
require('dotenv').config();
const { ethers } = require('ethers');
const fs = require('fs');
const path = require('path');

const signing = require('./api/signing');

async function testSigning() {
    try {
        console.log('=== Testing Blockchain Connection ===');
        
        // Check env vars
        console.log('RPC URL:', process.env.AMOY_RPC_URL);
        console.log('Private Key Length:', process.env.PRIVATE_KEY ? process.env.PRIVATE_KEY.length : 'undefined');
        
        // Load contract data
        const CONTRACT_JSON_PATH = path.join(__dirname, 'deployed', 'contract.json');
        if (!fs.existsSync(CONTRACT_JSON_PATH)) {
            console.error('❌ Contract file not found:', CONTRACT_JSON_PATH);
            return;
        }
        
        const contractData = JSON.parse(fs.readFileSync(CONTRACT_JSON_PATH, 'utf8'));
        console.log('Contract Address:', contractData.address);
        
        // Test provider connection
        console.log('\n=== Testing RPC Connection ===');
        const provider = new ethers.providers.JsonRpcProvider(process.env.AMOY_RPC_URL);
        
        try {
            const network = await provider.getNetwork();
            console.log('✅ Network connected:', network.name, 'chainId:', network.chainId);
        } catch (err) {
            console.error('❌ Provider connection failed:', err.message);
            return;
        }
        
        // Test wallet
        console.log('\n=== Testing Wallet ===');
        try {
            const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
            const address = wallet.address;
            console.log('✅ Wallet address:', address);
            
            const balance = await wallet.getBalance();
            console.log('✅ Wallet balance:', ethers.utils.formatEther(balance), 'MATIC');
            
            if (balance.isZero()) {
                console.warn('⚠️ Wallet has zero balance - transactions will fail');
            }
        } catch (err) {
            console.error('❌ Wallet setup failed:', err.message);
            return;
        }
        
        // Test contract connection
        console.log('\n=== Testing Contract Connection ===');
        try {
            const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
            let abi = contractData.abi;
            if (typeof abi === 'string') {
                abi = JSON.parse(abi);
            }
            
            const contract = new ethers.Contract(contractData.address, abi, wallet);
            console.log('✅ Contract instance created');
            
            // Test a read-only function
            try {
                const result = await contract.getCertificate("test-nonexistent");
                console.log('✅ Contract read test successful (should be empty):', result);
            } catch (err) {
                console.error('❌ Contract read test failed:', err.message);
            }
            
        } catch (err) {
            console.error('❌ Contract setup failed:', err.message);
            return;
        }
        
        // Test signing functionality
        console.log('\n=== Testing Signing ===');
        try {
            const testData = { test: 'data', timestamp: new Date().toISOString() };
            const canonicalString = JSON.stringify(testData);
            const signature = signing.signString(canonicalString);
            console.log('✅ Signing works, signature length:', signature.length);
            
            const isValid = signing.verifySignature(canonicalString, signature);
            console.log('✅ Signature verification:', isValid ? 'VALID' : 'INVALID');
        } catch (err) {
            console.error('❌ Signing test failed:', err.message);
        }
        
    } catch (err) {
        console.error('❌ Test failed:', err);
    }
}

testSigning();