// server.js - OneWipe Blockchain Service
const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const crypto = require("crypto");
const Web3 = require("web3");

const app = express();
app.use(bodyParser.json());

// -------------------- CORS Setup --------------------
const allowedOrigins = [
  "http://localhost:3000",
  "http://localhost:3001",
  "http://127.0.0.1:3000",
  "http://127.0.0.1:3001"
];

app.use(cors({
  origin: function(origin, callback){
    if(!origin) return callback(null, true); // allow non-browser requests
    if(allowedOrigins.indexOf(origin) === -1){
      const msg = 'CORS policy: This origin is not allowed';
      return callback(new Error(msg), false);
    }
    return callback(null, true);
  }
}));

// -------------------- Blockchain Setup --------------------
const web3 = new Web3("https://polygon-mumbai.g.alchemy.com/v2/YOUR_API_KEY"); // Replace with your RPC
const contractAddress = "0x8469CfC74478b2A26BfB944ADefCD18e27f5D0b7";
const contractABI = [
  {
    "constant": true,
    "inputs": [{ "name": "certHash", "type": "bytes32" }],
    "name": "isCertificateValid",
    "outputs": [{ "name": "", "type": "bool" }],
    "type": "function"
  },
  {
    "constant": false,
    "inputs": [{ "name": "certHash", "type": "bytes32" }],
    "name": "anchorCertificate",
    "outputs": [],
    "type": "function"
  }
];
const contract = new web3.eth.Contract(contractABI, contractAddress);

// -------------------- Sample Certificates --------------------
const sampleCertificates = {
  "sample-cert-001": {
    certID: "sample-cert-001",
    device: "Sample Laptop",
    policy: "NIST-Clear",
    hash: "0xabc123samplehash"
  }
};

// -------------------- Helper Functions --------------------
const generateResponse = (success, dataOrError) => {
  return success
    ? { success: true, data: dataOrError }
    : { success: false, error: dataOrError };
};

// -------------------- Endpoints --------------------

// Health check
app.get("/health", (req, res) => {
  res.json(generateResponse(true, {
    status: "ok",
    network: "Polygon Amoy Testnet",
    contractAddress: contractAddress
  }));
});

// -------------------- NEW: Sign & Anchor Certificate --------------------
app.post("/signAndAnchor", async (req, res) => {
  try {
    const { certID, certJSON } = req.body;
    if (!certID || !certJSON) return res.status(400).json(generateResponse(false, "Missing certID or certJSON"));

    // 1️⃣ Generate SHA256 hash
    const certString = JSON.stringify(certJSON);
    const hash = web3.utils.sha3(certString); // 0x prefixed

    // 2️⃣ Simulate server signature
    const signatureBase64 = crypto.createHash("sha256").update(certString).digest("base64");

    // 3️⃣ Anchor on blockchain (simulate transaction)
    // Replace with real transaction logic if using a private key
    const txHash = "0xSIMULATED_TX_HASH";

    // Save to sampleCertificates for demo
    sampleCertificates[certID] = { certID, ...certJSON, hash };

    res.json(generateResponse(true, {
      certID,
      certHash: hash,
      signatureBase64,
      txHash,
      polygonscan: `https://amoy.polygonscan.com/tx/${txHash}`
    }));

  } catch (err) {
    console.error(err);
    res.status(500).json(generateResponse(false, "Internal server error"));
  }
});

// Verify single certificate
app.post("/verifyFull", async (req, res) => {
  try {
    const { certID, certJSON, signatureBase64 } = req.body;
    if (!certID || !certJSON || !signatureBase64) {
      return res.status(400).json(generateResponse(false, "Missing required fields"));
    }

    const certString = JSON.stringify(certJSON);
    const hash = web3.utils.sha3(certString);
    const isValid = await contract.methods.isCertificateValid(hash).call();
    const validSignature = signatureBase64 && signatureBase64.length > 10;

    res.json(generateResponse(true, {
      certID,
      validSignature,
      anchored: isValid,
      certHash: hash
    }));
  } catch (err) {
    console.error(err);
    res.status(500).json(generateResponse(false, "Internal server error"));
  }
});

// Get certificate details
app.get("/getCert/:certID", (req, res) => {
  const { certID } = req.params;
  const cert = sampleCertificates[certID];
  if (!cert) return res.status(404).json(generateResponse(false, "Certificate not found"));

  res.json(generateResponse(true, {
    certID: cert.certID,
    device: cert.device,
    policy: cert.policy,
    hash: cert.hash,
    timestamp: Date.now()
  }));
});

// Check transaction status
app.get("/txStatus/:certID", (req, res) => {
  const { certID } = req.params;
  res.json(generateResponse(true, {
    certID,
    txHash: "0x123sampletxhash",
    status: "confirmed",
    confirmations: 12,
    blockNumber: 1234567,
    polygonscan: `https://amoy.polygonscan.com/tx/0x123sampletxhash`
  }));
});

// Batch verify multiple certificates
app.post("/batchVerify", async (req, res) => {
  const { certificates } = req.body;
  if (!Array.isArray(certificates)) return res.status(400).json(generateResponse(false, "certificates must be an array"));
  if (certificates.length > 10) return res.status(400).json(generateResponse(false, "Max 10 certificates allowed per batch"));

  const results = [];
  for (let cert of certificates) {
    const certString = JSON.stringify(cert.certJSON || {});
    const hash = web3.utils.sha3(certString);
    const anchored = await contract.methods.isCertificateValid(hash).call();
    const validSignature = cert.signatureBase64 && cert.signatureBase64.length > 10;

    results.push({
      certID: cert.certID,
      success: anchored && validSignature,
      validSignature,
      anchored,
      certHash: hash
    });
  }

  res.json(generateResponse(true, {
    total: results.length,
    verified: results.filter(r => r.success).length,
    failed: results.filter(r => !r.success).length,
    results
  }));
});

// -------------------- Start Server --------------------
const PORT = 4000;
app.listen(PORT, () => {
  console.log(`OneWipe Blockchain Service running on http://localhost:${PORT}`);
});
