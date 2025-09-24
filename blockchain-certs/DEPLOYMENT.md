# OneWipe Smart Contract Deployment Guide

## 🏗️ Current Deployment Status

### **Production Contract**
- **Network**: Polygon Amoy Testnet
- **Chain ID**: 80002
- **Contract Address**: `0x8469CfC74478b2A26BfB944ADefCD18e27f5D0b7`
- **Deployed**: ✅ Active
- **Polygonscan**: https://amoy.polygonscan.com/address/0x8469CfC74478b2A26BfB944ADefCD18e27f5D0b7

### **Deployment Wallet**
- **Address**: `0x40CEB901a74D1EcaeED5B1A4b3d6B08389bc43a7`
- **Balance**: 199.78 MATIC (sufficient for operations)
- **Role**: Contract owner and certificate issuer

---

## 🔧 Smart Contract Functions

### **Core Functions**
1. **storeCertificate(certID, certHash)** - Store new certificate
2. **getCertificate(certID)** - Retrieve certificate data  
3. **verifyCertificate(certID, certHash)** - Verify certificate integrity
4. **owner()** - Get contract owner address

### **Events**
- **CertificateStored(certID, certHash, issuer, timestamp)** - Emitted on new certificates

---

## 🚀 Re-deployment Instructions

If you need to redeploy the contract:

### **1. Prerequisites**
```bash
# Install dependencies
npm install

# Set environment variables in .env
AMOY_RPC_URL=https://polygon-amoy.g.alchemy.com/v2/YOUR_API_KEY
PRIVATE_KEY=0xYOUR_PRIVATE_KEY_HERE
```

### **2. Deploy Contract**
```bash
# Using Hardhat
npx hardhat run scripts/deploy.js --network amoy

# Or using the deployment script
node scripts/deploy.js
```

### **3. Verify Contract (Optional)**
```bash
# Verify on Polygonscan
npx hardhat verify --network amoy DEPLOYED_ADDRESS
```

### **4. Update Configuration**
After deployment, update the contract address in:
- `deployed/contract.json`
- Environment variables if needed
- API service configuration

---

## 🔍 Testing & Verification

### **Test Contract Functions**
```bash
# Run interaction tests
node scripts/interact.js

# Check network connectivity
node checkNetwork.js

# Send test transaction
node sendTestTx.js
```

### **API Health Check**
```bash
curl http://localhost:4000/health
# Should return contract reachability status
```

---

## 📊 Gas Costs & Performance

### **Current Settings**
- **Gas Limit**: 300,000 (sufficient for certificate storage)
- **Gas Price**: 150% of network average (for faster confirmation)
- **Estimated Cost**: ~0.01 MATIC per certificate

### **Optimization Tips**
- Store minimal data on-chain (only hash + metadata)
- Use events for detailed logging
- Batch operations when possible (future enhancement)

---

## 🛠️ Troubleshooting

### **Common Issues**

1. **Transaction Timeout**
   - Increase gas price in production
   - Current timeout: 30 seconds (configurable)

2. **Insufficient Funds**
   - Check wallet balance: must have >0.1 MATIC
   - Get testnet MATIC: https://faucet.polygon.technology/

3. **RPC Issues**
   - Verify Alchemy API key is complete
   - Test with different RPC endpoint if needed

4. **Contract Not Found**
   - Verify contract address in deployed/contract.json
   - Check if contract exists on Polygonscan

### **Emergency Procedures**

1. **Service Down**
   ```bash
   # Restart blockchain service
   node api/index.js
   ```

2. **Contract Migration**
   - Deploy new contract
   - Update deployed/contract.json
   - Migrate existing certificate data (if needed)

---

## 📈 Future Enhancements

### **Planned Improvements**
- [ ] **Batch Operations**: Store multiple certificates in one transaction
- [ ] **Access Control**: Role-based permissions for different issuers  
- [ ] **Contract Upgrades**: Proxy pattern for upgradeable contracts
- [ ] **Mainnet Deployment**: When ready for production

### **Monitoring**
- Transaction success rates
- Gas cost optimization
- Network health checks
- Certificate storage analytics

---

## 🔐 Security Notes

### **Current Security Measures**
- Private key stored in environment variables
- Contract owner verification
- Hash-based certificate integrity
- Immutable storage on blockchain

### **Best Practices**
- Regular security audits
- Private key rotation
- Multi-signature wallet (future)
- Rate limiting on API endpoints