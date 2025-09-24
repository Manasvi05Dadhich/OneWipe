# 🚀 Quick Start Guide for Aayush

## What You Need to Know

**Your job:** Build a React portal where people can upload certificates and verify them.

**My job:** Provide blockchain APIs that verify those certificates.

---

## 🔗 API Base URL
```
http://localhost:4000
```

---

## 🎯 4 Endpoints You Need

### 1. **Health Check** (Test connection)
```javascript
GET /health

// Use this to check if my service is running
const checkHealth = async () => {
  try {
    const response = await fetch('http://localhost:4000/health');
    const data = await response.json();
    return data.status === 'ok';
  } catch (error) {
    return false; // Service down
  }
};
```

### 2. **Verify Certificate** (Main feature)
```javascript
POST /verifyFull

// This is your main verification function
const verifyCertificate = async (certificate) => {
  const response = await fetch('http://localhost:4000/verifyFull', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      certID: certificate.certID,
      certJSON: certificate.certJSON,
      signatureBase64: certificate.signatureBase64
    })
  });
  
  const result = await response.json();
  
  if (result.success) {
    return {
      valid: result.data.validSignature && result.data.anchored,
      signatureOK: result.data.validSignature,
      onBlockchain: result.data.anchored
    };
  } else {
    throw new Error(result.error);
  }
};
```

### 3. **Get Certificate Info** (Optional)
```javascript
GET /getCert/{certID}

// Get details about a certificate
const getCertInfo = async (certID) => {
  const response = await fetch(`http://localhost:4000/getCert/${certID}`);
  return await response.json();
};
```

### 4. **Batch Verify** (For multiple certificates)
```javascript
POST /batchVerify

// Verify up to 10 certificates at once
const batchVerify = async (certificates) => {
  const response = await fetch('http://localhost:4000/batchVerify', {
    method: 'POST', 
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ certificates })
  });
  return await response.json();
};
```

---

## 📄 Certificate Format

When users upload a JSON certificate, it looks like this:

```json
{
  "certID": "wipe-123456789",
  "certJSON": {
    "device": "Samsung SSD 970 EVO",
    "wipedBy": "OneWipe-System", 
    "timestamp": "2025-01-24T06:00:00Z",
    "policy": "NIST-Clear"
  },
  "signatureBase64": "VkbAme1JSVOR9iuNvqxmZZCNMMM4C/NJsLek5zUZHLI..."
}
```

---

## 🎨 Suggested React Components

### 1. **Certificate Upload Component**
```jsx
import React, { useState } from 'react';

const CertificateUpload = () => {
  const [result, setResult] = useState(null);
  
  const handleFileUpload = async (event) => {
    const file = event.target.files[0];
    const text = await file.text();
    const certificate = JSON.parse(text);
    
    try {
      const verification = await verifyCertificate(certificate);
      setResult(verification);
    } catch (error) {
      setResult({ error: error.message });
    }
  };
  
  return (
    <div>
      <input type="file" accept=".json" onChange={handleFileUpload} />
      {result && <VerificationResult result={result} />}
    </div>
  );
};
```

### 2. **Verification Result Component**
```jsx
const VerificationResult = ({ result }) => {
  if (result.error) {
    return <div className="error">❌ {result.error}</div>;
  }
  
  return (
    <div className={result.valid ? "success" : "invalid"}>
      <h3>{result.valid ? "✅ Valid Certificate" : "❌ Invalid Certificate"}</h3>
      <p>Digital Signature: {result.signatureOK ? "✅ Valid" : "❌ Invalid"}</p>
      <p>Blockchain Anchored: {result.onBlockchain ? "✅ Yes" : "❌ No"}</p>
    </div>
  );
};
```

---

## 🧪 Testing

1. **Start your React app**: `npm start`
2. **Test connection**: Call the health endpoint first
3. **Create test certificate**: I'll provide sample certificates for testing
4. **Upload & verify**: Test the verification flow

---

## 🆘 Need Help?

- **Service not running?** → Tell me, I'll start it
- **CORS errors?** → I've already configured CORS for localhost:3000 and :3001
- **Invalid certificates?** → I'll generate real test certificates for you
- **API questions?** → Check the full API_DOCS.md or ask me

---

## 🎯 Your Portal Goals

1. **File upload** → Let users upload JSON certificates
2. **Verification** → Call my API to verify authenticity  
3. **Results display** → Show valid/invalid with details
4. **Batch processing** → Handle multiple certificates
5. **Clean UI** → Make it user-friendly for regulators/buyers

**That's it! Focus on the React UI, I handle all the blockchain complexity.** 🚀