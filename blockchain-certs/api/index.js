// api/index.js
const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
const hre = require("hardhat");
const fs = require("fs");
const path = require("path");
const QRCode = require("qrcode");

const signing = require("./signing");

const app = express();
app.use(cors());
app.use(bodyParser.json());

// -------------------- CONFIG --------------------
const DEPLOYED_DIR = path.join(__dirname, "../deployed");
const CONTRACT_JSON_PATH = path.join(DEPLOYED_DIR, "contract.json");
const TXS_JSON_PATH = path.join(DEPLOYED_DIR, "txs.json");

if (!fs.existsSync(CONTRACT_JSON_PATH)) {
  console.error("❌ Deployed contract file not found:", CONTRACT_JSON_PATH);
  process.exit(1);
}
const contractData = JSON.parse(fs.readFileSync(CONTRACT_JSON_PATH, "utf8"));

// Load tx log (or init empty)
let txLog = {};
if (fs.existsSync(TXS_JSON_PATH)) {
  txLog = JSON.parse(fs.readFileSync(TXS_JSON_PATH, "utf8"));
}

async function getRegistry() {
  const Registry = await hre.ethers.getContractFactory("WipeCertificateRegistry");
  return Registry.attach(contractData.address);
}

// -------------------- ENDPOINTS --------------------

// POST /signAndAnchor
app.post("/signAndAnchor", async (req, res) => {
  try {
    const { certID, certJSON } = req.body;
    if (!certID || !certJSON) {
      return res.status(400).json({ success: false, error: "certID and certJSON required" });
    }

    const canonicalString = JSON.stringify(
      Object.keys(certJSON)
        .sort()
        .reduce((o, k) => {
          o[k] = certJSON[k];
          return o;
        }, {})
    );

    const signatureBase64 = signing.signString(canonicalString);
    const signedBlob = canonicalString + "||" + signatureBase64;
    const certHashHex = signing.sha256Hex(signedBlob);

    const registry = await getRegistry();
    const tx = await registry.storeCertificate(certID, certHashHex);
    const receipt = await tx.wait();

    // Save txHash to local log for QR codes
    txLog[certID] = { txHash: receipt.transactionHash, certHash: certHashHex };
    fs.writeFileSync(TXS_JSON_PATH, JSON.stringify(txLog, null, 2));

    return res.json({
      success: true,
      data: {
        certID,
        certHashHex,
        signatureBase64,
        txHash: receipt.transactionHash,
      },
    });
  } catch (err) {
    console.error("❌ signAndAnchor error:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// POST /verifyFull
app.post("/verifyFull", async (req, res) => {
  try {
    const { certID, certJSON, signatureBase64 } = req.body;
    if (!certID || !certJSON || !signatureBase64) {
      return res.status(400).json({ success: false, error: "certID, certJSON, and signatureBase64 required" });
    }

    const canonicalString = JSON.stringify(
      Object.keys(certJSON)
        .sort()
        .reduce((o, k) => {
          o[k] = certJSON[k];
          return o;
        }, {})
    );

    const sigOk = signing.verifySignature(canonicalString, signatureBase64);
    if (!sigOk) {
      return res.json({ success: true, data: { validSignature: false, anchored: false } });
    }

    const signedBlob = canonicalString + "||" + signatureBase64;
    const certHashHex = signing.sha256Hex(signedBlob);

    const registry = await getRegistry();
    const anchored = await registry.verifyCertificate(certID, certHashHex);

    return res.json({ success: true, data: { validSignature: true, anchored } });
  } catch (err) {
    console.error("❌ verifyFull error:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// GET /getCert/:id
app.get("/getCert/:id", async (req, res) => {
  try {
    const certID = req.params.id;
    if (!certID) {
      return res.status(400).json({ success: false, error: "certID required" });
    }

    const registry = await getRegistry();
    const cert = await registry.getCertificate(certID);

    if (!cert[0]) {
      return res.status(404).json({ success: false, error: "Certificate not found" });
    }

    const tsNum = Number(cert[1]);
    const tsDate = new Date(tsNum * 1000).toISOString();

    return res.json({
      success: true,
      data: {
        certID,
        certHash: cert[0],
        timestamp: tsNum,
        timestampReadable: tsDate,
        issuer: cert[2],
        txHash: txLog[certID] ? txLog[certID].txHash : null,
      },
    });
  } catch (err) {
    console.error("❌ getCert error:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// GET /qrcode/:id
app.get("/qrcode/:id", async (req, res) => {
  try {
    const certID = req.params.id;
    if (!certID || !txLog[certID]) {
      return res.status(404).json({ success: false, error: "Certificate not found or no txHash" });
    }

    const txHash = txLog[certID].txHash;
    const scanUrl = `https://amoy.polygonscan.com/tx/${txHash}`;

    const qrDataUrl = await QRCode.toDataURL(scanUrl);
    const base64Data = qrDataUrl.replace(/^data:image\/png;base64,/, "");
    const img = Buffer.from(base64Data, "base64");

    res.writeHead(200, {
      "Content-Type": "image/png",
      "Content-Length": img.length,
    });
    res.end(img);
  } catch (err) {
    console.error("❌ qrcode error:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// GET /health
app.get("/health", (req, res) => {
  res.json({
    status: "ok",
    server: "http://localhost:4000",
    network: process.env.AMOY_RPC_URL ? "amoy" : "localhost",
    contractAddress: contractData.address,
    abiVersion: signing.sha256Hex(JSON.stringify(contractData.abi)).slice(0, 12), // short ABI hash
  });
});

// -------------------- START SERVER --------------------
app.listen(4000, () => {
  console.log("🚀 API server running on http://localhost:4000");
});
