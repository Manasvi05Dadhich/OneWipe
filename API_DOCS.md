# OneWipe API Documentation

## 🚀 **Base URLs**
- **Main Backend**: `http://localhost:3000`
- **Blockchain Service**: `http://localhost:4000` (also accessible via main backend proxy)

---

## 🛡️ **Authentication & Rate Limits**

### **Rate Limits**
- **Certificate Signing**: 5 requests/minute per IP
- **Certificate Verification**: 20 requests/minute per IP
- **General endpoints**: 10 requests/minute per IP

### **Headers**
```http
Content-Type: application/json
```

---

## 📊 **General Endpoints**

### **Backend Health Check**
```http
GET /api/status
```

**Response:**
```json
{
  "status": "Backend server is up and running!"
}
```

### **Blockchain Service Health**
```http
GET /api/blockchain/health
```

**Response:**
```json
{
  "status": "ok",
  "uptimeSec": 1234,
  "server": "http://localhost:4000",
  "network": "amoy",
  "contractAddress": "0x8469CfC74478b2A26BfB944ADefCD18e27f5D0b7",
  "contractReachable": true
}
```

---

## 🦀 **Wipe Operations**

### **Start Wipe Operation**
```http
POST /api/wipe/start
```

**Request Body:**
```json
{
  "targetPath": "C:\\path\\to\\wipe",
  "policy": "clear",
  "dryRun": false,
  "force": false
}
```

**Response:**
```json
{
  "success": true,
  "wipeId": "wipe-1758642326590-abc123",
  "message": "Wipe operation started",
  "status": "starting",
  "estimatedTime": "1-3 minutes"
}
```

### **Check Wipe Status**
```http
GET /api/wipe/status/{wipeId}
```

**Response:**
```json
{
  "success": true,
  "wipeId": "wipe-1758642326590-abc123",
  "status": "completed",
  "progress": 100,
  "targetPath": "C:\\path\\to\\wipe",
  "policy": "clear",
  "startTime": "2025-09-23T15:42:37.364Z",
  "completedTime": "2025-09-23T15:45:12.123Z",
  "certificate": {
    "success": true,
    "data": {
      "certID": "wipe-1758642326590-abc123",
      "txHash": "0x...",
      "polygonscan": "https://amoy.polygonscan.com/tx/0x..."
    }
  }
}
```

### **Get Detailed Wipe Results**
```http
GET /api/wipe/results/{wipeId}
```

**Response:**
```json
{
  "success": true,
  "wipeId": "wipe-1758642326590-abc123",
  "wipeDetails": {
    "folder": "C:\\path\\to\\wipe",
    "wiped_at": "2025-09-23T15:42:37.364Z",
    "policy": "Clear",
    "files": [
      {
        "name": "test.txt",
        "size_bytes": 1024,
        "path": "C:\\path\\to\\wipe\\test.txt",
        "passes": ["Pass 1: zeros"],
        "status": "completed"
      }
    ]
  },
  "certificate": {
    "success": true,
    "data": {
      "certID": "wipe-1758642326590-abc123",
      "certHashHex": "1bfc0d03...",
      "signatureBase64": "VkbAme1JS...",
      "txHash": "0xcbd2afab...",
      "polygonscan": "https://amoy.polygonscan.com/tx/0xcbd2afab..."
    }
  }
}
```

### **List All Wipes**
```http
GET /api/wipe/list
```

**Response:**
```json
{
  "success": true,
  "wipes": [
    {
      "wipeId": "wipe-1758642326590-abc123",
      "status": "completed",
      "targetPath": "C:\\path\\to\\wipe",
      "policy": "clear",
      "startTime": "2025-09-23T15:42:37.364Z",
      "completedTime": "2025-09-23T15:45:12.123Z",
      "hasCertificate": true
    }
  ]
}
```

---

## 🔐 **Certificate Operations**

### **Sign and Anchor Certificate**
```http
POST /api/blockchain/signAndAnchor
```

**Request Body:**
```json
{
  "certID": "unique-cert-id-123",
  "certJSON": {
    "device": "C:\\path\\to\\device",
    "wipedBy": "OneWipe-System",
    "timestamp": "2025-09-23T15:42:37.364Z",
    "policy": "Clear",
    "filesCount": 5,
    "totalSizeBytes": 10240
  }
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "certID": "unique-cert-id-123",
    "certHashHex": "1bfc0d03fbde1404c95591aaddc68be4dcbc6692367ff45d6b4aa25045867214",
    "signatureBase64": "VkbAme1JSVOR9iuNvqxmZZCNMMM4C/NJsLek5zUZHLI...",
    "txHash": "0xcbd2afabd3bdb94ee877bde30df76a25c0e736cad2e7e9c2e07fb1ec773ee34e",
    "polygonscan": "https://amoy.polygonscan.com/tx/0xcbd2afabd3bdb94ee877bde30df76a25c0e736cad2e7e9c2e07fb1ec773ee34e"
  }
}
```

**Timeout Response (202):**
```json
{
  "success": false,
  "error": "Transaction submitted but confirmation timed out",
  "details": "The transaction was sent to the blockchain but confirmation is taking longer than expected. Check the transaction hash on Polygonscan.",
  "data": {
    "certID": "unique-cert-id-123",
    "certHashHex": "1bfc0d03...",
    "signatureBase64": "VkbAme1JS...",
    "txHash": "0xcbd2afab...",
    "polygonscan": "https://amoy.polygonscan.com/tx/0xcbd2afab...",
    "status": "pending"
  }
}
```

### **Verify Certificate**
```http
POST /api/blockchain/verifyFull
```

**Request Body:**
```json
{
  "certID": "unique-cert-id-123",
  "certJSON": {
    "device": "C:\\path\\to\\device",
    "wipedBy": "OneWipe-System",
    "timestamp": "2025-09-23T15:42:37.364Z"
  },
  "signatureBase64": "VkbAme1JSVOR9iuNvqxmZZCNMMM4C/NJsLek5zUZHLI..."
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "validSignature": true,
    "anchored": true
  }
}
```

### **Batch Verify Certificates**
```http
POST /api/blockchain/batchVerify
```

**Request Body:**
```json
{
  "certificates": [
    {
      "certID": "cert-1",
      "certJSON": { "device": "...", "wipedBy": "...", "timestamp": "..." },
      "signatureBase64": "..."
    },
    {
      "certID": "cert-2", 
      "certJSON": { "device": "...", "wipedBy": "...", "timestamp": "..." },
      "signatureBase64": "..."
    }
  ]
}
```

**Response:**
```json
{
  "success": true,
  "summary": {
    "total": 2,
    "verified": 2,
    "failed": 0,
    "invalidSignature": 0,
    "notAnchored": 0
  },
  "results": [
    {
      "certID": "cert-1",
      "success": true,
      "validSignature": true,
      "anchored": true,
      "certHash": "1bfc0d03..."
    },
    {
      "certID": "cert-2",
      "success": true,
      "validSignature": true,
      "anchored": true,
      "certHash": "2aef1b04..."
    }
  ]
}
```

### **Check Transaction Status**
```http
GET /api/blockchain/txStatus/{certID}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "certID": "unique-cert-id-123",
    "txHash": "0xcbd2afabd3bdb94ee877bde30df76a25c0e736cad2e7e9c2e07fb1ec773ee34e",
    "status": "confirmed",
    "blockNumber": 1234567,
    "confirmations": 15,
    "gasUsed": "65432",
    "transactionFee": "0.001234567",
    "confirmationTime": "2025-09-23T15:43:12.123Z",
    "polygonscan": "https://amoy.polygonscan.com/tx/0xcbd2afab...",
    "blockExplorer": "https://amoy.polygonscan.com/block/1234567"
  }
}
```

### **Get Certificate Details**
```http
GET /api/blockchain/getCert/{certID}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "certID": "unique-cert-id-123",
    "certHash": "1bfc0d03fbde1404c95591aaddc68be4dcbc6692367ff45d6b4aa25045867214",
    "timestamp": 1758642157,
    "timestampReadable": "2025-09-23T15:42:37.000Z",
    "issuer": "0x40CEB901a74D1EcaeED5B1A4b3d6B08389bc43a7",
    "txHash": "0xcbd2afabd3bdb94ee877bde30df76a25c0e736cad2e7e9c2e07fb1ec773ee34e"
  }
}
```

---

## 📄 **Document Generation**

### **Generate QR Code**
```http
GET /api/blockchain/qrcode/{certID}
```

**Response:** Binary PNG image

### **Generate PDF Certificate**
```http
POST /api/blockchain/generatePdf
```

**Request Body:**
```json
{
  "certID": "unique-cert-id-123",
  "certJSON": {
    "device": "C:\\path\\to\\device",
    "wipedBy": "OneWipe-System",
    "timestamp": "2025-09-23T15:42:37.364Z"
  },
  "signatureBase64": "VkbAme1JSVOR9iuNvqxmZZCNMMM4C/NJsLek5zUZHLI..."
}
```

**Response:** Binary PDF file

---

## 📊 **Statistics & Monitoring**

### **Service Statistics**
```http
GET /api/blockchain/stats
```

**Response:**
```json
{
  "success": true,
  "data": {
    "totalCertificates": 42,
    "uniqueIssuers": 3,
    "lastIssued": "2025-09-23T15:42:37.364Z",
    "lastUpdatedAt": "2025-09-23T15:50:12.123Z",
    "issuers": {
      "0x40CEB901a74D1EcaeED5B1A4b3d6B08389bc43a7": 40,
      "0x1234567890123456789012345678901234567890": 2
    },
    "devices": {
      "C:\\Windows": 15,
      "D:\\Data": 10,
      "E:\\Files": 17
    },
    "topIssuer": ["0x40CEB901a74D1EcaeED5B1A4b3d6B08389bc43a7", 40],
    "topDevice": ["E:\\Files", 17]
  }
}
```

---

## ❌ **Error Responses**

### **Rate Limit Exceeded (429)**
```json
{
  "success": false,
  "error": "Rate limit exceeded",
  "details": "Too many requests. Try again at 2025-09-23T15:51:12.123Z",
  "remaining": 0
}
```

### **Validation Error (400)**
```json
{
  "success": false,
  "error": "Missing required fields: device, timestamp"
}
```

### **Certificate Not Found (404)**
```json
{
  "success": false,
  "error": "Certificate not found"
}
```

### **Service Error (500)**
```json
{
  "success": false,
  "error": "Internal server error message"
}
```

---

## 🔧 **Frontend Integration Examples**

### **JavaScript/Fetch**
```javascript
// Start a wipe operation
const startWipe = async (targetPath, policy = 'clear') => {
  const response = await fetch('http://localhost:3000/api/wipe/start', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ targetPath, policy, force: true })
  });
  
  return await response.json();
};

// Poll wipe status
const pollWipeStatus = async (wipeId) => {
  const response = await fetch(`http://localhost:3000/api/wipe/status/${wipeId}`);
  const data = await response.json();
  
  if (data.status === 'completed') {
    console.log('Wipe completed!', data.certificate);
  }
  
  return data;
};

// Verify certificate
const verifyCertificate = async (certID, certJSON, signatureBase64) => {
  const response = await fetch('http://localhost:3000/api/blockchain/verifyFull', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ certID, certJSON, signatureBase64 })
  });
  
  return await response.json();
};
```

### **React Hook Example**
```jsx
import { useState, useEffect } from 'react';

const useWipeStatus = (wipeId) => {
  const [status, setStatus] = useState(null);
  const [loading, setLoading] = useState(true);
  
  useEffect(() => {
    if (!wipeId) return;
    
    const checkStatus = async () => {
      try {
        const response = await fetch(`/api/wipe/status/${wipeId}`);
        const data = await response.json();
        setStatus(data);
        
        if (data.status === 'completed' || data.status === 'failed') {
          setLoading(false);
        }
      } catch (error) {
        console.error('Status check failed:', error);
      }
    };
    
    checkStatus();
    const interval = setInterval(checkStatus, 5000); // Poll every 5 seconds
    
    return () => clearInterval(interval);
  }, [wipeId]);
  
  return { status, loading };
};
```

### **Flutter/Dart Example**
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class OneWipeAPI {
  static const String baseUrl = 'http://localhost:3000/api';
  
  static Future<Map<String, dynamic>> startWipe({
    required String targetPath,
    String policy = 'clear',
    bool dryRun = false,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/wipe/start'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'targetPath': targetPath,
        'policy': policy,
        'dryRun': dryRun,
        'force': true,
      }),
    );
    
    return jsonDecode(response.body);
  }
  
  static Future<Map<String, dynamic>> checkWipeStatus(String wipeId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/wipe/status/$wipeId'),
    );
    
    return jsonDecode(response.body);
  }
  
  static Future<Map<String, dynamic>> verifyCertificate({
    required String certID,
    required Map<String, dynamic> certJSON,
    required String signatureBase64,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/blockchain/verifyFull'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'certID': certID,
        'certJSON': certJSON,
        'signatureBase64': signatureBase64,
      }),
    );
    
    return jsonDecode(response.body);
  }
}
```

---

## 🚀 **Typical Frontend Workflow**

### **1. One-Click Secure Wipe Flow**
```javascript
const performSecureWipe = async (targetPath) => {
  // 1. Start wipe operation
  const wipeResult = await startWipe(targetPath, 'dod'); // DoD 3-pass
  const { wipeId } = wipeResult;
  
  // 2. Poll status until completion
  let status;
  do {
    await new Promise(resolve => setTimeout(resolve, 5000)); // Wait 5s
    status = await pollWipeStatus(wipeId);
  } while (status.status === 'starting' || status.status === 'wiping' || status.status === 'generating-certificate');
  
  // 3. Return completion result with certificate
  if (status.status === 'completed') {
    return {
      success: true,
      wipeDetails: status.wipeLog,
      certificate: status.certificate,
      polygonscanLink: status.certificate?.data?.polygonscan,
      canDownloadPDF: true,
      canDownloadQR: true
    };
  } else {
    throw new Error(`Wipe failed: ${status.error}`);
  }
};
```

### **2. Certificate Verification Flow**
```javascript
const verifyWipeCertificate = async (certID, certData, signature) => {
  // 1. Verify signature and blockchain anchoring
  const verification = await verifyCertificate(certID, certData, signature);
  
  if (verification.success && verification.data.validSignature && verification.data.anchored) {
    // 2. Get additional details from blockchain
    const certDetails = await fetch(`/api/blockchain/getCert/${certID}`);
    const details = await certDetails.json();
    
    return {
      verified: true,
      onChain: true,
      blockNumber: details.data.timestamp,
      issuer: details.data.issuer,
      polygonscanLink: `https://amoy.polygonscan.com/tx/${details.data.txHash}`
    };
  } else {
    return { verified: false, reason: 'Invalid signature or not anchored' };
  }
};
```

---

## 🛡️ **Security Best Practices**

1. **Always validate API responses** before using data
2. **Handle rate limiting** gracefully with retry logic
3. **Store sensitive data securely** (never log private keys)
4. **Use HTTPS in production** (these examples use HTTP for local development)
5. **Implement proper error handling** for all API calls
6. **Cache verification results** to reduce API calls
7. **Validate certificate data** before displaying to users

---

## 🔍 **Testing & Debugging**

### **Test Endpoints with cURL**
```bash
# Health check
curl http://localhost:3000/api/status

# Start dry-run wipe
curl -X POST http://localhost:3000/api/wipe/start \
  -H "Content-Type: application/json" \
  -d '{"targetPath":"C:\\temp","policy":"clear","dryRun":true,"force":true}'

# Check blockchain service
curl http://localhost:3000/api/blockchain/health

# Get service statistics
curl http://localhost:3000/api/blockchain/stats
```

### **Common Issues**
1. **Services not running**: Check if both backend (3000) and blockchain service (4000) are running
2. **Rate limits**: Wait for rate limit reset time before retrying
3. **Invalid paths**: Ensure target paths exist and are accessible
4. **Network issues**: Check if Polygon Amoy network is accessible

---

This documentation provides everything your frontend team needs to integrate with the OneWipe API!