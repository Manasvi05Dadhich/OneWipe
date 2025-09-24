require("dotenv").config();
const { ethers } = require("ethers");

async function main() {
  const provider = new ethers.providers.JsonRpcProvider(process.env.AMOY_RPC_URL);
  const network = await provider.getNetwork();
  console.log("Connected to chain:", network);
}

main();
