// api/index.js
require("dotenv").config();   // ✅ Load .env variables

const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
const fs = require("fs");
const path = require("path");
const QRCode = require("qrcode");
const PDFDocument = require("pdfkit");
const { ethers } = require("ethers");

const signing = require("./signing");
const { logAction } = require("./audit");
const { createAuditTrail, validateCertificateData, addSecurityMetadata, checkRateLimit } = require("./geolocation");

const app = express();
app.use(cors());
app.use(bodyParser.json());

const DEPLOYED_DIR = path.join(__dirname, "../deployed");
const CONTRACT_JSON_PATH = path.join(DEPLOYED_DIR, "contract.json");
const TXS_JSON_PATH = path.join(DEPLOYED_DIR, "txs.json");

if (!fs.existsSync(CONTRACT_JSON_PATH)) {
  console.error("❌ Deployed contract file not found:", CONTRACT_JSON_PATH);
  process.exit(1);
}
const contractData = JSON.parse(fs.readFileSync(CONTRACT_JSON_PATH, "utf8"));

let txLog = {};
if (fs.existsSync(TXS_JSON_PATH)) {
  txLog = JSON.parse(fs.readFileSync(TXS_JSON_PATH, "utf8"));
}

// ✅ Fixed getRegistry: always parse ABI safely and log ENV
async function getRegistry() {
  console.log("DEBUG PRIVATE_KEY length:", process.env.PRIVATE_KEY ? process.env.PRIVATE_KEY.length : "undefined");
  console.log("DEBUG PRIVATE_KEY raw:", JSON.stringify(process.env.PRIVATE_KEY));
  console.log("DEBUG RPC URL:", process.env.AMOY_RPC_URL);

  const provider = new ethers.providers.JsonRpcProvider(process.env.AMOY_RPC_URL);
  const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

  let abi = contractData.abi;
  if (typeof abi === "string") {
    try {
      abi = JSON.parse(abi);
    } catch (err) {
      console.error("❌ Failed to parse ABI string:", err.message);
      throw err;
    }
  }

  return new ethers.Contract(contractData.address, abi, wallet);
}


// Track uptime
const startTime = Date.now();

/* ---------------- SIGN & ANCHOR ---------------- */
app.post("/signAndAnchor", async (req, res) => {
  // Declare variables at function scope for error handling
  let certID, certJSON, signatureBase64, certHashHex;
  
  try {
    // Rate limiting check
    const clientIP = req.get('X-Forwarded-For') || req.connection.remoteAddress || 'unknown';
    const rateCheck = checkRateLimit(clientIP, 5, 60000); // 5 requests per minute
    
    if (!rateCheck.allowed) {
      return res.status(429).json({ 
        success: false, 
        error: "Rate limit exceeded",
        details: `Too many requests. Try again at ${rateCheck.resetTime}`,
        remaining: rateCheck.remaining
      });
    }
    
    ({ certID, certJSON } = req.body);
    if (!certID || !certJSON) {
      return res.status(400).json({ success: false, error: "certID and certJSON required" });
    }
    
    // Validate certificate data integrity
    validateCertificateData(certJSON);
    
    // Create comprehensive audit trail
    const auditTrail = await createAuditTrail(req);
    
    // Add security metadata and audit trail
    const enhancedCertJSON = addSecurityMetadata(certJSON, auditTrail);

    const canonicalString = JSON.stringify(
      Object.keys(enhancedCertJSON).sort().reduce((o, k) => {
        o[k] = enhancedCertJSON[k];
        return o;
      }, {})
    );

    signatureBase64 = signing.signString(canonicalString);
    const signedBlob = canonicalString + "||" + signatureBase64;
    certHashHex = signing.sha256Hex(signedBlob);
    const registry = await getRegistry();

// ⛽ Better gas settings for faster confirmation
    const gasPrice = await registry.provider.getGasPrice();
    const boostedGasPrice = gasPrice.mul(150).div(100); // 50% higher gas price
    
    const tx = await registry.storeCertificate(certID, certHashHex, { 
      gasLimit: 300000,
      gasPrice: boostedGasPrice
    });
    console.log("📤 TX submitted:", tx.hash);
    console.log("⛽ Gas price:", ethers.utils.formatUnits(boostedGasPrice, 'gwei'), "gwei");

    // Wait for confirmation with 30 second timeout
    let receipt;
    try {
      receipt = await Promise.race([
        tx.wait(),
        new Promise((_, reject) => 
          setTimeout(() => {
            const timeoutError = new Error('Transaction confirmation timeout after 30 seconds');
            timeoutError.txHash = tx.hash; // Preserve the transaction hash
            reject(timeoutError);
          }, 30000)
        )
      ]);
    } catch (timeoutErr) {
      if (timeoutErr.message.includes('timeout')) {
        // Transaction was submitted but timed out - still log it
        console.log("⏰ Transaction timed out but was submitted:", tx.hash);
        console.log("🔗 Check status at:", `https://amoy.polygonscan.com/tx/${tx.hash}`);
        
        // Store partial info for later verification
        txLog[certID] = {
          txHash: tx.hash,
          certHash: certHashHex,
          signatureBase64,
          certJSON: enhancedCertJSON,
          submissionTime: new Date().toISOString(),
          status: 'pending'
        };
        fs.writeFileSync(TXS_JSON_PATH, JSON.stringify(txLog, null, 2));
        
        throw timeoutErr; // Re-throw to be caught by outer catch
      }
      throw timeoutErr;
    }
    console.log("✅ TX mined in block:", receipt.blockNumber, "hash:", receipt.transactionHash);


    txLog[certID] = {
      txHash: receipt.transactionHash,
      certHash: certHashHex,
      signatureBase64,
      certJSON: enhancedCertJSON,
      submissionTime: new Date().toISOString(),
      status: 'confirmed'
    };
    fs.writeFileSync(TXS_JSON_PATH, JSON.stringify(txLog, null, 2));

    logAction("signAndAnchor", `certID=${certID} txHash=${receipt.transactionHash}`);

    return res.json({
      success: true,
      data: {
        certID,
        certHashHex,
        signatureBase64,
        txHash: receipt.transactionHash,
        polygonscan: `https://amoy.polygonscan.com/tx/${receipt.transactionHash}`
      },
    });
  } catch (err) {
    console.error("❌ signAndAnchor error:", err);
    
    // Handle timeout specifically
    if (err.message.includes('timeout')) {
      return res.status(202).json({ 
        success: false, 
        error: 'Transaction submitted but confirmation timed out',
        details: 'The transaction was sent to the blockchain but confirmation is taking longer than expected. Check the transaction hash on Polygonscan.',
        data: {
          certID,
          certHashHex,
          signatureBase64,
          txHash: err.txHash,
          polygonscan: `https://amoy.polygonscan.com/tx/${err.txHash}`,
          status: 'pending'
        }
      });
    }
    
    res.status(500).json({ success: false, error: err.message });
  }
});

/* ---------------- VERIFY FULL ---------------- */
app.post("/verifyFull", async (req, res) => {
  try {
    // Rate limiting check
    const clientIP = req.get('X-Forwarded-For') || req.connection.remoteAddress || 'unknown';
    const rateCheck = checkRateLimit(clientIP, 20, 60000); // 20 requests per minute for verification
    
    if (!rateCheck.allowed) {
      return res.status(429).json({ 
        success: false, 
        error: "Rate limit exceeded",
        details: `Too many requests. Try again at ${rateCheck.resetTime}`,
        remaining: rateCheck.remaining
      });
    }
    
    const { certID, certJSON, signatureBase64 } = req.body;
    if (!certID || !certJSON || !signatureBase64) {
      return res.status(400).json({ success: false, error: "certID, certJSON, and signatureBase64 required" });
    }

    const canonicalString = JSON.stringify(
      Object.keys(certJSON).sort().reduce((o, k) => {
        o[k] = certJSON[k];
        return o;
      }, {})
    );

    const sigOk = signing.verifySignature(canonicalString, signatureBase64);
    if (!sigOk) {
      logAction("verifyFull", `certID=${certID} signatureOk=false anchored=false`);
      return res.json({ success: true, data: { validSignature: false, anchored: false } });
    }

    const signedBlob = canonicalString + "||" + signatureBase64;
    const certHashHex = signing.sha256Hex(signedBlob);

    const registry = await getRegistry();
    const anchored = await registry.verifyCertificate(certID, certHashHex);

    // ✅ Auto-heal txLog
    if (!txLog[certID] || !txLog[certID].certJSON) {
      txLog[certID] = {
        ...(txLog[certID] || {}),
        certHash: certHashHex,
        signatureBase64,
        certJSON,
      };

      try {
        const certOnChain = await registry.getCertificate(certID);
        if (certOnChain && certOnChain[0]) {
          txLog[certID].txHash = txLog[certID].txHash || null;
        }
      } catch (e) {
        console.warn("⚠️ Could not fetch txHash for auto-heal:", e.message);
      }

      fs.writeFileSync(TXS_JSON_PATH, JSON.stringify(txLog, null, 2));
      logAction("verifyFull", `certID=${certID} retroactively updated txLog`);
    }

    logAction("verifyFull", `certID=${certID} signatureOk=${sigOk} anchored=${anchored}`);

    return res.json({ success: true, data: { validSignature: true, anchored } });
  } catch (err) {
    console.error("❌ verifyFull error:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/* ---------------- GET CERT ---------------- */
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

/* ---------------- QRCODE ---------------- */
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

/* ---------------- GENERATE PDF ---------------- */
app.post("/generatePdf", async (req, res) => {
  try {
    const { certID, certJSON, signatureBase64 } = req.body;
    if (!certID) {
      return res.status(400).json({ success: false, error: "certID required" });
    }

    let finalJSON = certJSON;
    let finalSig = signatureBase64;
    if (!finalJSON || !finalSig) {
      if (txLog[certID]) {
        finalSig = txLog[certID].signatureBase64 || "N/A";
      }
      const registry = await getRegistry();
      const cert = await registry.getCertificate(certID);
      if (!cert[0]) {
        return res.status(404).json({ success: false, error: "Certificate not found on chain" });
      }
      finalJSON = {
        device: "unknown",
        wipedBy: "unknown",
        timestamp: new Date(cert[1] * 1000).toISOString(),
        issuer: cert[2],
      };
    }

    const canonicalString = JSON.stringify(
      Object.keys(finalJSON).sort().reduce((o, k) => { o[k] = finalJSON[k]; return o; }, {}), null, 2
    );

    const txHash = txLog[certID] ? txLog[certID].txHash : null;
    const scanUrl = txHash
      ? `https://amoy.polygonscan.com/tx/${txHash}`
      : `https://your-verification-portal.example.com/verify/${certID}`;

    const qrDataUrl = await QRCode.toDataURL(scanUrl);
    const qrBase64 = qrDataUrl.replace(/^data:image\/png;base64,/, "");
    const qrBuffer = Buffer.from(qrBase64, "base64");

    const doc = new PDFDocument({ size: "A4", margin: 50 });
    const chunks = [];
    doc.on("data", (chunk) => chunks.push(chunk));
    doc.on("end", () => {
      const pdfBuffer = Buffer.concat(chunks);
      res.writeHead(200, {
        "Content-Type": "application/pdf",
        "Content-Disposition": `attachment; filename="${certID}.pdf"`,
        "Content-Length": pdfBuffer.length,
      });
      res.end(pdfBuffer);
    });

    doc.fontSize(20).text("OneWipe — Secure Wipe Certificate", { align: "center" });
    doc.moveDown(0.5);
    doc.fontSize(10).fillColor("#555").text("Immutable proof anchored on Polygon Amoy Testnet", { align: "center" });
    doc.moveDown(1.5);

    doc.fontSize(12).fillColor("#000");
    doc.text(`Certificate ID: ${certID}`);
    doc.text(`Device: ${finalJSON.device}`);
    doc.text(`Wiped By: ${finalJSON.wipedBy}`);
    doc.text(`Timestamp: ${finalJSON.timestamp}`);
    doc.text(`Issuer: ${finalJSON.issuer || "N/A"}`);
    doc.moveDown(1);

    doc.image(qrBuffer, { fit: [150, 150], align: "center" });
    doc.moveDown(0.5);
    doc.fontSize(9).text("Scan this QR to verify on Polygonscan", { align: "center" });
    doc.moveDown(1);

    doc.fontSize(10).text(`Blockchain TxHash: ${txHash || "N/A"}`, { width: 500 });

    doc.addPage();
    doc.fontSize(12).text("Canonical Certificate JSON:", { underline: true });
    doc.moveDown(0.5);
    doc.font("Courier").fontSize(9).text(canonicalString, { width: 500 });

    doc.addPage();
    doc.fontSize(12).text("Digital Signature (Base64):", { underline: true });
    doc.moveDown(0.5);
    doc.font("Courier").fontSize(8).text(finalSig, { width: 500 });

    doc.end();

    logAction("generatePdf", `certID=${certID} file=${certID}.pdf`);
  } catch (err) {
    console.error("❌ generatePdf error:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/* ---------------- STATS ---------------- */
app.get("/stats", async (req, res) => {
  try {
    const registry = await getRegistry();
    const certIDs = Object.keys(txLog);
    const totalCertificates = certIDs.length;

    let lastIssued = null;
    let issuers = new Map();
    let devices = new Map();

    for (let certID of certIDs) {
      let issuer = "Unknown";
      let tsNum = 0;
      let device = "Unknown";

      try {
        const cert = await registry.getCertificate(certID);
        if (cert && cert[0]) {
          issuer = cert[2];
          tsNum = Number(cert[1]);
        }

        if (txLog[certID] && txLog[certID].certJSON) {
          device = txLog[certID].certJSON.device || "Unknown";
        }
      } catch (e) {
        console.warn("⚠️ Blockchain lookup failed:", certID);
        tsNum = Math.floor(Date.now() / 1000);
      }

      issuers.set(issuer, (issuers.get(issuer) || 0) + 1);
      devices.set(device, (devices.get(device) || 0) + 1);

      if (tsNum > 0) {
        const tsDate = new Date(tsNum * 1000).toISOString();
        if (!lastIssued || tsDate > lastIssued) {
          lastIssued = tsDate;
        }
      }
    }

    const issuerStats = Object.fromEntries(issuers);
    const deviceStats = Object.fromEntries(devices);

    res.json({
      success: true,
      data: {
        totalCertificates,
        uniqueIssuers: issuers.size,
        lastIssued: lastIssued || "N/A",
        lastUpdatedAt: new Date().toISOString(),
        issuers: issuerStats,
        devices: deviceStats,
        topIssuer: [...issuers.entries()].sort((a, b) => b[1] - a[1])[0] || null,
        topDevice: [...devices.entries()].sort((a, b) => b[1] - a[1])[0] || null,
      },
    });
  } catch (err) {
    console.error("❌ stats error:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/* ---------------- CHECK TX STATUS ---------------- */
app.get("/txStatus/:id", async (req, res) => {
  try {
    const certID = req.params.id;
    if (!certID || !txLog[certID]) {
      return res.status(404).json({ success: false, error: "Certificate not found" });
    }

    const txHash = txLog[certID].txHash;
    if (!txHash) {
      return res.status(404).json({ success: false, error: "No transaction hash found" });
    }

    const provider = new ethers.providers.JsonRpcProvider(process.env.AMOY_RPC_URL);
    
    try {
      const receipt = await provider.getTransactionReceipt(txHash);
      
      if (receipt) {
        // Transaction confirmed!
        if (txLog[certID].status === 'pending') {
          txLog[certID].status = 'confirmed';
          txLog[certID].blockNumber = receipt.blockNumber;
          txLog[certID].confirmationTime = new Date().toISOString();
          fs.writeFileSync(TXS_JSON_PATH, JSON.stringify(txLog, null, 2));
        }
        
        // Get current block for confirmation count
        const currentBlock = await provider.getBlockNumber();
        const confirmations = currentBlock - receipt.blockNumber;
        
        return res.json({
          success: true,
          data: {
            certID,
            txHash,
            status: 'confirmed',
            blockNumber: receipt.blockNumber,
            confirmations,
            gasUsed: receipt.gasUsed.toString(),
            effectiveGasPrice: receipt.effectiveGasPrice ? receipt.effectiveGasPrice.toString() : null,
            transactionFee: receipt.effectiveGasPrice ? ethers.utils.formatEther(receipt.gasUsed.mul(receipt.effectiveGasPrice)) : null,
            confirmationTime: txLog[certID].confirmationTime,
            polygonscan: `https://amoy.polygonscan.com/tx/${txHash}`,
            blockExplorer: `https://amoy.polygonscan.com/block/${receipt.blockNumber}`
          }
        });
      } else {
        // Check if transaction exists but is pending
        try {
          const tx = await provider.getTransaction(txHash);
          if (tx) {
            return res.json({
              success: true,
              data: {
                certID,
                txHash,
                status: 'pending',
                gasPrice: tx.gasPrice.toString(),
                gasLimit: tx.gasLimit.toString(),
                nonce: tx.nonce,
                submissionTime: txLog[certID].submissionTime || 'unknown',
                polygonscan: `https://amoy.polygonscan.com/tx/${txHash}`
              }
            });
          } else {
            return res.json({
              success: false,
              data: {
                certID,
                txHash,
                status: 'not_found',
                error: 'Transaction not found on network',
                polygonscan: `https://amoy.polygonscan.com/tx/${txHash}`
              }
            });
          }
        } catch (txErr) {
          return res.json({
            success: true,
            data: {
              certID,
              txHash,
              status: 'pending',
              note: 'Transaction submitted, status check failed',
              polygonscan: `https://amoy.polygonscan.com/tx/${txHash}`
            }
          });
        }
      }
    } catch (err) {
      return res.json({
        success: true,
        data: {
          certID,
          txHash,
          status: 'unknown',
          error: err.message,
          polygonscan: `https://amoy.polygonscan.com/tx/${txHash}`
        }
      });
    }
  } catch (err) {
    console.error("❌ txStatus error:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/* ---------------- BATCH VERIFY ---------------- */
app.post("/batchVerify", async (req, res) => {
  try {
    const { certificates } = req.body;
    if (!certificates || !Array.isArray(certificates)) {
      return res.status(400).json({ success: false, error: "certificates array required" });
    }
    
    if (certificates.length > 10) {
      return res.status(400).json({ success: false, error: "Maximum 10 certificates per batch" });
    }
    
    const registry = await getRegistry();
    const results = [];
    
    for (const cert of certificates) {
      const { certID, certJSON, signatureBase64 } = cert;
      
      try {
        if (!certID || !certJSON || !signatureBase64) {
          results.push({
            certID: certID || 'unknown',
            success: false,
            error: 'Missing required fields'
          });
          continue;
        }
        
        // Verify signature
        const canonicalString = JSON.stringify(
          Object.keys(certJSON).sort().reduce((o, k) => {
            o[k] = certJSON[k];
            return o;
          }, {})
        );
        
        const sigOk = signing.verifySignature(canonicalString, signatureBase64);
        const signedBlob = canonicalString + "||" + signatureBase64;
        const certHashHex = signing.sha256Hex(signedBlob);
        const anchored = await registry.verifyCertificate(certID, certHashHex);
        
        results.push({
          certID,
          success: true,
          validSignature: sigOk,
          anchored,
          certHash: certHashHex
        });
        
      } catch (err) {
        results.push({
          certID: certID || 'unknown',
          success: false,
          error: err.message
        });
      }
    }
    
    const summary = {
      total: certificates.length,
      verified: results.filter(r => r.success && r.validSignature && r.anchored).length,
      failed: results.filter(r => !r.success).length,
      invalidSignature: results.filter(r => r.success && !r.validSignature).length,
      notAnchored: results.filter(r => r.success && r.validSignature && !r.anchored).length
    };
    
    logAction("batchVerify", `processed=${certificates.length} verified=${summary.verified}`);
    
    res.json({
      success: true,
      summary,
      results
    });
    
  } catch (err) {
    console.error("❌ batchVerify error:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/* ---------------- HEALTH ---------------- */
app.get("/health", async (req, res) => {
  const uptimeSec = Math.floor((Date.now() - startTime) / 1000);

  let contractReachable = false;
  try {
    const registry = await getRegistry();
    await registry.getCertificate("nonexistent");
    contractReachable = true;
  } catch {
    contractReachable = false;
  }

  res.json({
    status: "ok",
    uptimeSec,
    server: "http://localhost:4000",
    network: process.env.AMOY_RPC_URL ? "amoy" : "localhost",
    contractAddress: contractData.address,
    contractReachable,
    abiVersion: signing.sha256Hex(JSON.stringify(contractData.abi)).slice(0, 12),
  });
});

app.listen(4000, () => {
  console.log("🚀 API server running on http://localhost:4000");
});
