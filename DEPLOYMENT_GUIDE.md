# OneWipe Production Deployment Guide

## 🚀 **Quick Start**

### **1. Prerequisites**
```bash
# Install Docker and Docker Compose
docker --version
docker-compose --version

# Verify Node.js (for local development)
node --version  # Should be 18+
npm --version
```

### **2. Environment Setup**
```bash
# Copy environment template
cp .env.template .env

# Edit .env with your values
nano .env  # or use your preferred editor
```

**Required Environment Variables:**
```env
AMOY_RPC_URL=https://polygon-amoy.g.alchemy.com/v2/YOUR_API_KEY
PRIVATE_KEY=0xYOUR_ETHEREUM_PRIVATE_KEY
```

### **3. Deploy with Docker**
```bash
# Build and start all services
docker-compose up -d

# Check service status
docker-compose ps

# View logs
docker-compose logs -f backend
docker-compose logs -f blockchain
```

### **4. Health Checks**
```bash
# Backend health
curl http://localhost:3000/api/status

# Blockchain service health
curl http://localhost:4000/health

# Monitoring (if enabled)
curl http://localhost:9090  # Prometheus
curl http://localhost:3001  # Grafana (admin/onewipe123)
```

---

## 📊 **Service Architecture**

### **Core Services**
- **Backend API** (Port 3000): Main REST API with Rust CLI integration
- **Blockchain Service** (Port 4000): Certificate signing and blockchain operations

### **Monitoring Stack (Optional)**
- **Prometheus** (Port 9090): Metrics collection
- **Grafana** (Port 3001): Dashboards and visualization  
- **Loki** (Port 3100): Log aggregation
- **Promtail**: Log shipping

---

## 🔧 **Configuration**

### **Production Settings**
```env
NODE_ENV=production
RATE_LIMIT_WINDOW=60000
RATE_LIMIT_MAX_REQUESTS=10
LOG_LEVEL=info
```

### **Security Hardening**
```env
# Enable CORS restrictions
CORS_ORIGIN=https://your-frontend-domain.com

# SSL/TLS certificates
SSL_KEY_PATH=/path/to/ssl/private.key
SSL_CERT_PATH=/path/to/ssl/certificate.crt
```

### **Scaling Configuration**
```yaml
# In docker-compose.yml, add scaling options
backend:
  deploy:
    replicas: 3
    resources:
      limits:
        cpus: '0.5'
        memory: 512M
```

---

## 📊 **Monitoring & Logging**

### **Metrics Available**
- API request rates and response times
- Certificate generation success/failure rates
- Blockchain transaction status
- System resource usage
- Rate limiting statistics

### **Log Locations**
```bash
# Container logs
docker-compose logs backend
docker-compose logs blockchain

# Persistent logs (if volumes mounted)
./logs/backend.log
./blockchain-certs/logs/blockchain.log
```

### **Grafana Dashboards**
Access at `http://localhost:3001` (admin/onewipe123)

**Default dashboards include:**
- API Performance Overview
- Blockchain Transaction Monitoring  
- System Resource Usage
- Certificate Generation Stats

---

## 🔒 **Security Best Practices**

### **1. Environment Security**
```bash
# Secure environment file permissions
chmod 600 .env

# Use secrets management in production
# Consider Docker secrets or external secret stores
```

### **2. Network Security**
```yaml
# In docker-compose.yml
networks:
  internal:
    driver: bridge
    internal: true  # No external access
  external:
    driver: bridge
```

### **3. Container Security**
- Non-root users in containers ✅
- Read-only file systems where possible ✅
- Limited container capabilities ✅
- Regular security updates ✅

### **4. Rate Limiting**
```env
# Adjust based on your needs
RATE_LIMIT_MAX_REQUESTS=10
RATE_LIMIT_WINDOW=60000  # 1 minute
```

---

## 📈 **Scaling & Performance**

### **Horizontal Scaling**
```bash
# Scale backend instances
docker-compose up -d --scale backend=3

# Use load balancer (nginx example)
server {
    upstream backend {
        server backend_1:3000;
        server backend_2:3000;
        server backend_3:3000;
    }
}
```

### **Resource Optimization**
```yaml
# Memory and CPU limits
services:
  backend:
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
        reservations:
          memory: 256M
          cpus: '0.25'
```

### **Database Integration** (Future)
```yaml
# PostgreSQL for persistent data
postgres:
  image: postgres:15-alpine
  environment:
    POSTGRES_DB: onewipe
    POSTGRES_USER: onewipe
    POSTGRES_PASSWORD: ${DB_PASSWORD}
  volumes:
    - postgres_data:/var/lib/postgresql/data
```

---

## 🔄 **Backup & Recovery**

### **Important Data to Backup**
```bash
# Blockchain certificates and signatures
./blockchain-certs/deployed/txs.json

# Wipe operation logs  
./wipe-logs/

# Application logs
./logs/

# Configuration
.env
./blockchain-certs/.env
```

### **Backup Script Example**
```bash
#!/bin/bash
# backup.sh
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups/onewipe_${DATE}"

mkdir -p "$BACKUP_DIR"
cp -r ./blockchain-certs/deployed "$BACKUP_DIR/"
cp -r ./wipe-logs "$BACKUP_DIR/"
cp -r ./logs "$BACKUP_DIR/"
cp .env "$BACKUP_DIR/"

tar -czf "${BACKUP_DIR}.tar.gz" "$BACKUP_DIR"
rm -rf "$BACKUP_DIR"

echo "Backup created: ${BACKUP_DIR}.tar.gz"
```

---

## 🚨 **Troubleshooting**

### **Common Issues**

#### **Services Won't Start**
```bash
# Check logs for errors
docker-compose logs backend
docker-compose logs blockchain

# Verify environment variables
docker-compose config

# Check port conflicts
netstat -tlnp | grep :3000
```

#### **Blockchain Connection Issues**
```bash
# Test RPC endpoint
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  $AMOY_RPC_URL

# Verify private key format (should start with 0x)
echo $PRIVATE_KEY
```

#### **Memory Issues**
```bash
# Monitor resource usage
docker stats

# Increase memory limits in docker-compose.yml
# Or add swap space to host system
```

### **Health Checks**
```bash
# Service health endpoints
curl http://localhost:3000/api/status
curl http://localhost:4000/health

# Docker health status
docker-compose ps
```

---

## 📱 **Frontend Integration**

### **API Endpoints for Frontend**
```javascript
// Base URLs
const API_BASE = 'http://localhost:3000/api';
const BLOCKCHAIN_BASE = 'http://localhost:3000/api/blockchain';

// Example integration
const startWipe = async (targetPath) => {
  const response = await fetch(`${API_BASE}/wipe/start`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ 
      targetPath, 
      policy: 'dod',  // or 'clear'
      force: true 
    })
  });
  return response.json();
};
```

### **CORS Configuration** (Production)
```javascript
// In server.js, add CORS middleware
const cors = require('cors');
app.use(cors({
  origin: process.env.CORS_ORIGIN || 'http://localhost:3000',
  credentials: true
}));
```

---

## 🔄 **Updates & Maintenance**

### **Update Process**
```bash
# Pull latest changes
git pull origin main

# Rebuild and restart services
docker-compose build --no-cache
docker-compose up -d

# Verify deployment
docker-compose ps
curl http://localhost:3000/api/status
```

### **Database Migrations** (Future)
```bash
# Run migrations after updates
docker-compose exec backend npm run migrate

# Backup before major updates
./backup.sh
```

### **Monitoring Maintenance**
```bash
# Clean up old logs (retain 7 days)
find ./logs -name "*.log" -mtime +7 -delete

# Prometheus data retention
# Configure in prometheus.yml: --storage.tsdb.retention.time=15d
```

---

## 📋 **Production Checklist**

### **Pre-Deployment**
- [ ] Environment variables configured
- [ ] SSL certificates installed (if using HTTPS)
- [ ] Firewall rules configured
- [ ] Backup strategy implemented
- [ ] Monitoring dashboards configured

### **Post-Deployment**
- [ ] Health checks passing
- [ ] API endpoints responding correctly
- [ ] Blockchain connectivity verified
- [ ] Monitoring alerts configured
- [ ] Log rotation configured
- [ ] Performance baseline established

### **Security Review**
- [ ] Private keys secured
- [ ] Rate limiting configured
- [ ] CORS properly restricted
- [ ] Container security hardened
- [ ] Network segmentation applied

---

This deployment guide provides everything needed to run OneWipe in production! 🚀