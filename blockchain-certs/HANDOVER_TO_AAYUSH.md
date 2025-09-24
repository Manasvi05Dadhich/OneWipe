# 🚀 **Blockchain APIs Handover to Aayush**

## **Step-by-Step Setup & Testing Guide**

### **STEP 1: Start Your Services**

1. **Open 2 terminals/command prompts:**

**Terminal 1 - Main Backend:**
```bash
npm start
```

**Terminal 2 - Blockchain Service:**
```bash
cd blockchain-certs
node api/index.js
```

2. **Verify services are running:**
```bash
# Test main backend
curl http://localhost:3000/api/status

# Test blockchain service  
curl http://localhost:4000/health
```

---

### **STEP 2: Test Critical APIs for Aayush**

#### **🔍 Health Check (MUST WORK)**
```bash
curl http://localhost:4000/health
```
**Expected Response:**
```json
{
  "status": "ok",
  "uptimeSec": 123,
  "server": "http://localhost:4000",
  "network": "amoy",
  "contractAddress": "0x8469CfC74478b2A26BfB944ADefCD18e27f5D0b7",
  "contractReachable": true
}
```

#### **🧪 Test Certificate Generation**
```bash
curl -X POST http://localhost:4000/signAndAnchor \
  -H "Content-Type: application/json" \
  -d '{
    "certID": "test-for-aayush-001",
    "certJSON": {
      "device": "Test Laptop for Portal",
      "wipedBy": "OneWipe-Test",
      "timestamp": "2025-01-24T05:45:00Z",
      "policy": "NIST-Clear"
    }
  }'
```

#### **✅ Test Certificate Verification**
```bash
curl -X POST http://localhost:4000/verifyFull \
  -H "Content-Type: application/json" \
  -d '{
    "certID": "test-for-aayush-001",
    "certJSON": {
      "device": "Test Laptop for Portal", 
      "wipedBy": "OneWipe-Test",
      "timestamp": "2025-01-24T05:45:00Z",
      "policy": "NIST-Clear"
    },
    "signatureBase64": "[SIGNATURE_FROM_PREVIOUS_STEP]"
  }'
```

---

### **STEP 3: Generate Test Data for Aayush**

**Run this script to create sample certificates:**

```bash
# Create 3 test certificates
for i in {1..3}; do
  curl -X POST http://localhost:4000/signAndAnchor \
    -H "Content-Type: application/json" \
    -d "{
      \"certID\": \"aayush-test-cert-$i\",
      \"certJSON\": {
        \"device\": \"Test Device $i\",
        \"wipedBy\": \"OneWipe-Portal-Test\",
        \"timestamp\": \"$(date -Iseconds)\",
        \"policy\": \"NIST-Clear\"
      }
    }"
done
```

---

### **STEP 4: Create API Info Package for Aayush**

Create a file `aayush-api-info.json`:

```json
{
  "baseURL": "http://localhost:4000",
  "endpoints": {
    "health": "GET /health",
    "verify": "POST /verifyFull", 
    "getCert": "GET /getCert/{certID}",
    "txStatus": "GET /txStatus/{certID}",
    "batchVerify": "POST /batchVerify"
  },
  "blockchain": {
    "network": "polygon-amoy",
    "contractAddress": "0x8469CfC74478b2A26BfB944ADefCD18e27f5D0b7",
    "explorer": "https://amoy.polygonscan.com"
  },
  "testCertificates": [
    "aayush-test-cert-1",
    "aayush-test-cert-2", 
    "aayush-test-cert-3"
  ]
}
```

---

### **STEP 5: CORS Configuration for Aayush's React App**

**Add this to your `blockchain-certs/api/index.js`:**

```javascript
// Add near the top after other imports
app.use(cors({
  origin: [
    'http://localhost:3000',  // Aayush's React dev server
    'http://localhost:3001',  // Alternative React port
    'http://127.0.0.1:3000',
    'http://127.0.0.1:3001'
  ],
  credentials: true
}));
```

---

### **STEP 6: What to Send Aayush**

**📧 Send Aayush these files:**

1. **`API_DOCS.md`** - Complete API documentation
2. **`aayush-api-info.json`** - Connection details
3. **Sample test certificates** (from Step 3)
4. **Your .env.template** - So he knows what environment variables exist

**📝 Email Template:**

```
Hi Aayush,

Here are the blockchain verification APIs for the OneWipe portal:

🔗 Base URL: http://localhost:4000
📚 Documentation: See attached API_DOCS.md
🧪 Test Data: 3 sample certificates created (IDs: aayush-test-cert-1, aayush-test-cert-2, aayush-test-cert-3)

Key endpoints for your React portal:
- Health: GET /health
- Verify Certificate: POST /verifyFull  
- Get Certificate: GET /getCert/{certID}
- Batch Verify: POST /batchVerify

The blockchain service will be running on localhost:4000 during development.

Let me know when you're ready to integrate!

- Manasvi
```

---

### **STEP 7: Verify Everything Works**

**Before sending to Aayush, run this final test:**

```bash
# 1. Health check
curl http://localhost:4000/health

# 2. Create a test certificate
curl -X POST http://localhost:4000/signAndAnchor \
  -H "Content-Type: application/json" \
  -d '{
    "certID": "final-test-001", 
    "certJSON": {
      "device": "Final Test Device",
      "wipedBy": "OneWipe-System",
      "timestamp": "2025-01-24T06:00:00Z"
    }
  }'

# 3. Verify the certificate (use signature from step 2)
curl -X POST http://localhost:4000/verifyFull \
  -H "Content-Type: application/json" \
  -d '{
    "certID": "final-test-001",
    "certJSON": {
      "device": "Final Test Device", 
      "wipedBy": "OneWipe-System",
      "timestamp": "2025-01-24T06:00:00Z"
    },
    "signatureBase64": "[PASTE_SIGNATURE_HERE]"
  }'

# 4. Get certificate from blockchain
curl http://localhost:4000/getCert/final-test-001
```

**✅ If all these work, you're ready to hand over to Aayush!**

---

## **🚨 Troubleshooting**

**If services won't start:**
1. Check if ports 3000/4000 are in use: `netstat -an | findstr :4000`
2. Install dependencies: `npm install` in both root and blockchain-certs folders
3. Check .env file exists with proper values

**If blockchain calls fail:**
1. Verify .env has PRIVATE_KEY and AMOY_RPC_URL
2. Check wallet has MATIC tokens for gas
3. Verify contract address is correct

**If CORS errors in Aayush's React app:**
1. Ensure CORS middleware is properly configured
2. Check React app is running on expected port
3. Add Aayush's domain to CORS origins