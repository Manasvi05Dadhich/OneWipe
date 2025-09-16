// scripts/interact.js
const hre = require("hardhat");

async function main() {
  const [signer] = await hre.ethers.getSigners();
  console.log("Using account:", signer.address);

  const CONTRACT_ADDRESS = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"; // update if redeployed

  const Registry = await hre.ethers.getContractFactory("WipeCertificateRegistry");
  const registry = await Registry.attach(CONTRACT_ADDRESS);

  const certID = "cert1";
  const certHash = "abc123";

  console.log(`Storing certificate id='${certID}' hash='${certHash}' ...`);
  const tx = await registry.storeCertificate(certID, certHash);
  await tx.wait();
  console.log("Stored on-chain.");

  console.log("Verifying stored certificate...");
  const isValid = await registry.verifyCertificate(certID, certHash);
  console.log("verifyCertificate() ->", isValid);

  console.log("Reading full certificate data:");
  const cert = await registry.getCertificate(certID);
  console.log(cert);
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
