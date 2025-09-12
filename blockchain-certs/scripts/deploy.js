// scripts/deploy.js
const fs = require("fs");
const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with:", deployer.address);

  const Registry = await hre.ethers.getContractFactory("WipeCertificateRegistry");
  const registry = await Registry.deploy();
  await registry.deployed();

  console.log("Deployed to:", registry.address);

  // Save address + ABI
  const data = {
    address: registry.address,
    abi: JSON.parse(registry.interface.format("json"))
  };
  fs.writeFileSync("./deployed/contract.json", JSON.stringify(data, null, 2));
  console.log("Saved to deployed/contract.json");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
