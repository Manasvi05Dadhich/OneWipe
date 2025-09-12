// api/index.js
const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

const signing = require("./signing");

const app = express();
app.use(cors());
app.use(bodyParser.json());

// Load contract details (saved after deploy)
const CONTRACT_JSON_PATH = path.join(__dirname, "../deployed/contract.json");
if (!fs.existsSync(CONTRACT_JSON_PATH)) {
  console.error("Deployed contract file not found:", CONTRACT_JSON_PATH);
  process.exit(1);
}
const contractData = JSON.parse(fs.readFileSync(CONTRACT_JSON_PATH, "utf8"));

async function getRegistry() {
  const Registry = await hre.ethers.getContractFactory("WipeCertificateRegistry");
  return Registry.attach(contractData.address);
}

// -------------------- NEW ENDPOINTS --------------------

// POST /signAndAnchor
// Body: { certID: string, certJSON: object }
app.post("/signAndAnchor", async (req, res) => {
  try {
    const { certID, certJSON } = req.body;
    if (!certID || !certJSON) {
      return res.status(400).json({ success: false, error: "certID and certJSON required" });
    }

    // Stable serialization (sort keys for consistency)
    const canonicalString = JSON.stringify(
      Object.keys(certJSON)
        .sort()
        .reduce((o, k) => { o[k] = certJSON[k]; return o; }, {})
    );

    // 1) Sign cert JSON
    const signatureBase64 = signing.signString(canonicalString);

    // 2) Create signed blob and compute SHA-256
    const signedBlob = canonicalString + "||" + signatureBase64;
    const certHashHex = signing.sha256Hex(signedBlob);

    // 3) Store hash on blockchain
    const registry = await getRegistry();
    const tx = await registry.storeCertificate(certID, certHashHex);
    const receipt = await tx.wait();

    return res.json({
      success: true,
      certID,
      certHashHex,
      signatureBase64,
      txHash: receipt.transactionHash,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// POST /verifyFull
// Body: { certID, certJSON, signatureBase64 }
app.post("/verifyFull", async (req, res) => {
  try {
    const { certID, certJSON, signatureBase64 } = req.body;
    if (!certID || !certJSON || !signatureBase64) {
      return res.status(400).json({ success: false, error: "certID, certJSON, and signatureBase64 required" });
    }

    const canonicalString = JSON.stringify(
      Object.keys(certJSON)
        .sort()
        .reduce((o, k) => { o[k] = certJSON[k]; return o; }, {})
    );

    // 1) Verify signature
    const sigOk = signing.verifySignature(canonicalString, signatureBase64);
    if (!sigOk) {
      return res.json({ success: true, validSignature: false, anchored: false });
    }

    // 2) Recompute hash and check on blockchain
    const signedBlob = canonicalString + "||" + signatureBase64;
    const certHashHex = signing.sha256Hex(signedBlob);

    const registry = await getRegistry();
    const anchored = await registry.verifyCertificate(certID, certHashHex);

    return res.json({ success: true, validSignature: true, anchored });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// -------------------- OLD ENDPOINT --------------------
// (still here if you need it)
app.post("/verifyCert", async (req, res) => {
  try {
    const { certID, certHash } = req.body;
    const registry = await getRegistry();
    const isValid = await registry.verifyCertificate(certID, certHash);
    res.json({ success: true, valid: isValid });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// Start API server
app.listen(4000, () => {
  console.log("API server running on http://localhost:4000");
});
