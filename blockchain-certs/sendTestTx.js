require("dotenv").config();
const { ethers } = require("ethers");

async function main() {
  const provider = new ethers.providers.JsonRpcProvider(process.env.AMOY_RPC_URL);
  const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

  console.log("Using wallet:", wallet.address);

  // Send 0 MATIC to yourself (just a no-op tx to confirm broadcast)
  const tx = await wallet.sendTransaction({
    to: wallet.address,
    value: ethers.utils.parseEther("0")
  });

  console.log("Tx sent:", tx.hash);

  const receipt = await tx.wait();
  console.log("✅ Mined in block:", receipt.blockNumber);
}

main().catch(console.error);
