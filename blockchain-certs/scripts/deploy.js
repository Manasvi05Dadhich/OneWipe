const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with:", deployer.address);

  const Registry = await hre.ethers.getContractFactory("WipeCertificateRegistry");
  const registry = await Registry.deploy();
  await registry.deployed();

  console.log("WipeCertificateRegistry deployed to:", registry.address);

  // Save address + ABI to deployed/contract.json
  const deployedDir = path.join(__dirname, "../deployed");
  if (!fs.existsSync(deployedDir)) {
    fs.mkdirSync(deployedDir);
  }

  const contractData = {
    address: registry.address,
    abi: JSON.parse(registry.interface.format("json")),
  };

  fs.writeFileSync(
    path.join(deployedDir, "contract.json"),
    JSON.stringify(contractData, null, 2)
  );

  console.log("Contract details saved to deployed/contract.json");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
