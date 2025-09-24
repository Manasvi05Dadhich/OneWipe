// api/signing.js
const fs = require('fs');
const crypto = require('crypto');
const path = require('path');

const PRIVATE_KEY_PATH = path.join(__dirname, '../keys/private.pem');
const PUBLIC_KEY_PATH = path.join(__dirname, '../keys/public.pem');

// Load private key
function loadPrivateKey() {
  return fs.readFileSync(PRIVATE_KEY_PATH, 'utf8');
}

// Load public key
function loadPublicKey() {
  return fs.readFileSync(PUBLIC_KEY_PATH, 'utf8');
}

// Sign a string using RSA-SHA256
function signString(rawString) {
  const privateKey = loadPrivateKey();
  const sign = crypto.createSign('SHA256');
  sign.update(rawString);
  sign.end();
  return sign.sign(privateKey, 'base64');  // signature as base64
}

// Verify a signature
function verifySignature(rawString, signatureBase64) {
  const publicKey = loadPublicKey();
  const verify = crypto.createVerify('SHA256');
  verify.update(rawString);
  verify.end();
  return verify.verify(publicKey, signatureBase64, 'base64');
}

// Compute SHA-256 hex digest
function sha256Hex(rawString) {
  return crypto.createHash('sha256').update(rawString).digest('hex');
}

module.exports = {
  signString,
  verifySignature,
  sha256Hex,
};
