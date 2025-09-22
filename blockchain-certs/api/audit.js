// api/audit.js
console.log("✅ audit.js loaded");   // Debug: confirm this file is running

const fs = require("fs");
const path = require("path");

const LOG_DIR = path.join(__dirname, "../logs");
const LOG_FILE = path.join(LOG_DIR, "audit.log");

// Ensure logs folder exists
if (!fs.existsSync(LOG_DIR)) {
  fs.mkdirSync(LOG_DIR, { recursive: true });
}

function logAction(action, details) {
  const entry = `[${new Date().toISOString()}] ${action}: ${details}\n`;
  fs.appendFileSync(LOG_FILE, entry, "utf8");
  console.log("AUDIT:", entry.trim()); // show in console too
}

// ✅ Correct export
module.exports = { logAction };
