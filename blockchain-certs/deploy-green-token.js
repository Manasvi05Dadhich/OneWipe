// deploy-green-token.js
const { ethers } = require("ethers");
const fs = require("fs");
const path = require("path");

// Load environment
require("dotenv").config();

async function deployGreenToken() {
    console.log("🌱 Deploying Green Wipe Token (ERC-1155) contract...\n");

    // Setup provider and wallet
    const provider = new ethers.providers.JsonRpcProvider(process.env.AMOY_RPC_URL);
    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

    console.log("📡 Network:", await provider.getNetwork());
    console.log("💰 Deployer address:", wallet.address);
    console.log("💰 Balance:", ethers.utils.formatEther(await wallet.getBalance()), "MATIC\n");

    // First we need to compile the contract
    // For now, we'll use the ABI and bytecode from Remix or Hardhat compilation
    
    // This is a simplified deployment - in production you'd use Hardhat or similar
    const greenTokenContractData = {
        abi: [
            // ERC-1155 + Custom methods ABI would go here
            // For brevity, showing key methods only
            {
                "inputs": [],
                "stateMutability": "nonpayable",
                "type": "constructor"
            },
            {
                "inputs": [
                    {"internalType": "address", "name": "recipient", "type": "address"},
                    {"internalType": "string", "name": "deviceType", "type": "string"},
                    {"internalType": "string", "name": "certHash", "type": "string"},
                    {"internalType": "string", "name": "issuedTo", "type": "string"}
                ],
                "name": "mintGreenToken",
                "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
                "stateMutability": "nonpayable",
                "type": "function"
            },
            {
                "inputs": [{"internalType": "address", "name": "org", "type": "address"}],
                "name": "getOrganizationStats",
                "outputs": [
                    {"internalType": "string", "name": "orgName", "type": "string"},
                    {"internalType": "uint256", "name": "totalCO2", "type": "uint256"},
                    {"internalType": "uint256", "name": "devicesWiped", "type": "uint256"}
                ],
                "stateMutability": "view",
                "type": "function"
            },
            {
                "inputs": [],
                "name": "getGlobalStats",
                "outputs": [
                    {"internalType": "uint256", "name": "totalCO2", "type": "uint256"},
                    {"internalType": "uint256", "name": "totalDevices", "type": "uint256"}
                ],
                "stateMutability": "view",
                "type": "function"
            }
            // ... additional methods
        ],
        
        // This bytecode would come from compiling the Solidity contract
        // For demonstration, this is placeholder
        bytecode: "0x608060405234801561001057600080fd5b50..." // Actual bytecode would be much longer
    };

    try {
        // Create contract factory
        const GreenToken = new ethers.ContractFactory(
            greenTokenContractData.abi,
            greenTokenContractData.bytecode,
            wallet
        );

        console.log("🚀 Deploying contract...");
        
        // Deploy with higher gas settings
        const gasPrice = await provider.getGasPrice();
        const boostedGasPrice = gasPrice.mul(120).div(100); // 20% higher
        
        const greenToken = await GreenToken.deploy({
            gasLimit: 2000000,
            gasPrice: boostedGasPrice
        });

        console.log("📤 Deployment transaction:", greenToken.deployTransaction.hash);
        console.log("⏳ Waiting for confirmation...\n");

        await greenToken.deployed();

        console.log("✅ Green Token contract deployed!");
        console.log("📍 Contract address:", greenToken.address);
        console.log("🔗 Polygonscan:", `https://amoy.polygonscan.com/address/${greenToken.address}`);
        console.log("⛽ Gas used:", greenToken.deployTransaction.gasLimit?.toString());

        // Save contract info
        const deployedDir = path.join(__dirname, "deployed");
        if (!fs.existsSync(deployedDir)) {
            fs.mkdirSync(deployedDir);
        }

        const contractInfo = {
            address: greenToken.address,
            abi: greenTokenContractData.abi,
            deploymentTx: greenToken.deployTransaction.hash,
            deployedAt: new Date().toISOString(),
            network: "amoy",
            deployer: wallet.address
        };

        fs.writeFileSync(
            path.join(deployedDir, "green-token-contract.json"),
            JSON.stringify(contractInfo, null, 2)
        );

        console.log("💾 Contract info saved to deployed/green-token-contract.json");

        // Test the contract
        console.log("\n🧪 Testing contract functions...");
        
        // Test global stats (should be 0,0 initially)
        const globalStats = await greenToken.getGlobalStats();
        console.log("📊 Global stats - CO₂:", globalStats[0].toString(), "kg, Devices:", globalStats[1].toString());

        // Update environment template
        const envTemplate = `
# Add this to your .env file:
GREEN_TOKEN_CONTRACT_ADDRESS=${greenToken.address}
`;

        console.log("\n" + "=".repeat(50));
        console.log("🌱 GREEN TOKEN CONTRACT DEPLOYED SUCCESSFULLY! 🌱");
        console.log("=".repeat(50));
        console.log(envTemplate);
        console.log("Next steps:");
        console.log("1. Add the contract address to your .env file");
        console.log("2. Restart your blockchain service");
        console.log("3. Test minting Green Tokens after successful wipes");
        console.log("4. Check the sustainability dashboard in Flutter app");

    } catch (error) {
        console.error("❌ Deployment failed:", error);
        
        if (error.message.includes("insufficient funds")) {
            console.log("\n💡 Solution: Add MATIC to your wallet address:");
            console.log("   Wallet:", wallet.address);
            console.log("   Faucet: https://faucet.polygon.technology/");
        }
        
        process.exit(1);
    }
}

// Note about contract compilation
function showCompilationNote() {
    console.log("📝 Note: To fully deploy, you need to:");
    console.log("1. Compile the GreenWipeToken.sol contract");
    console.log("2. Use a tool like Hardhat, Remix, or Foundry");
    console.log("3. Update this script with the real ABI and bytecode");
    console.log("\nFor now, this script shows the deployment structure.");
    console.log("The actual deployment requires proper Solidity compilation.\n");
}

if (require.main === module) {
    showCompilationNote();
    
    // Uncomment this when you have compiled contract:
    // deployGreenToken().catch(console.error);
    
    console.log("🔧 Run this script after compiling GreenWipeToken.sol");
}

module.exports = { deployGreenToken };