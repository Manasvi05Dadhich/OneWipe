require("@nomiclabs/hardhat-ethers");
require("dotenv").config();

const { AMOY_RPC_URL, PRIVATE_KEY } = process.env;

if (!AMOY_RPC_URL || !PRIVATE_KEY) {
  console.warn("Warning: AMOY_RPC_URL or PRIVATE_KEY is missing in .env");
  // We still export config so local hardhat works
}

module.exports = {
  solidity: {
    compilers: [
      { version: "0.8.17" }
    ]
  },
  networks: {
    hardhat: {
      // local hardhat config (default)
    },
    amoy: {
      url: AMOY_RPC_URL || "https://rpc-amoy.polygon.technology",
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : []
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  }
};
