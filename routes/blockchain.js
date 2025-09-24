const express = require('express');
const axios = require('axios');
const router = express.Router();

// Configuration for the blockchain service
const BLOCKCHAIN_SERVICE_URL = 'http://localhost:4000';

// Helper function to forward requests to blockchain service
async function forwardToBlockchainService(endpoint, method = 'GET', data = null) {
    try {
        const config = {
            method: method.toLowerCase(),
            url: `${BLOCKCHAIN_SERVICE_URL}${endpoint}`,
            timeout: 30000, // 30 second timeout
        };
        
        if (data) {
            config.data = data;
            config.headers = {
                'Content-Type': 'application/json',
            };
        }
        
        const response = await axios(config);
        return {
            success: true,
            data: response.data,
            status: response.status
        };
    } catch (error) {
        console.error(`Error forwarding to blockchain service: ${error.message}`);
        return {
            success: false,
            error: error.response?.data || error.message,
            status: error.response?.status || 500
        };
    }
}

// POST /api/blockchain/signAndAnchor
// Signs certificate and anchors on blockchain
router.post('/signAndAnchor', async (req, res) => {
    console.log('📝 Forwarding signAndAnchor request to blockchain service');
    console.log('Request body:', req.body);
    
    const result = await forwardToBlockchainService('/signAndAnchor', 'POST', req.body);
    
    if (result.success) {
        console.log('✅ Certificate signed and anchored successfully');
        res.status(result.status).json(result.data);
    } else {
        console.error('❌ Failed to sign and anchor certificate:', result.error);
        res.status(result.status).json({
            success: false,
            error: result.error,
            message: 'Failed to sign and anchor certificate'
        });
    }
});

// POST /api/blockchain/verifyFull
// Verifies certificate signature and blockchain anchor
router.post('/verifyFull', async (req, res) => {
    console.log('🔍 Forwarding verifyFull request to blockchain service');
    
    const result = await forwardToBlockchainService('/verifyFull', 'POST', req.body);
    
    if (result.success) {
        console.log('✅ Certificate verification completed');
        res.status(result.status).json(result.data);
    } else {
        console.error('❌ Certificate verification failed:', result.error);
        res.status(result.status).json({
            success: false,
            error: result.error,
            message: 'Certificate verification failed'
        });
    }
});

// GET /api/blockchain/getCert/:id
// Gets certificate details from blockchain
router.get('/getCert/:id', async (req, res) => {
    const certId = req.params.id;
    console.log(`📋 Forwarding getCert request for certificate: ${certId}`);
    
    const result = await forwardToBlockchainService(`/getCert/${certId}`, 'GET');
    
    if (result.success) {
        console.log('✅ Certificate details retrieved successfully');
        res.status(result.status).json(result.data);
    } else {
        console.error('❌ Failed to get certificate details:', result.error);
        res.status(result.status).json({
            success: false,
            error: result.error,
            message: 'Failed to retrieve certificate details'
        });
    }
});

// GET /api/blockchain/qrcode/:id
// Gets QR code for certificate verification
router.get('/qrcode/:id', async (req, res) => {
    const certId = req.params.id;
    console.log(`📱 Forwarding QR code request for certificate: ${certId}`);
    
    try {
        const response = await axios({
            method: 'get',
            url: `${BLOCKCHAIN_SERVICE_URL}/qrcode/${certId}`,
            responseType: 'arraybuffer',
            timeout: 10000
        });
        
        res.set('Content-Type', 'image/png');
        res.send(response.data);
    } catch (error) {
        console.error('❌ Failed to get QR code:', error.message);
        res.status(error.response?.status || 500).json({
            success: false,
            error: error.message,
            message: 'Failed to generate QR code'
        });
    }
});

// POST /api/blockchain/generatePdf
// Generates PDF certificate with blockchain proof
router.post('/generatePdf', async (req, res) => {
    console.log('📄 Forwarding PDF generation request to blockchain service');
    
    try {
        const response = await axios({
            method: 'post',
            url: `${BLOCKCHAIN_SERVICE_URL}/generatePdf`,
            data: req.body,
            responseType: 'arraybuffer',
            headers: {
                'Content-Type': 'application/json',
            },
            timeout: 30000
        });
        
        res.set('Content-Type', 'application/pdf');
        res.set('Content-Disposition', `attachment; filename="certificate-${req.body.certID || 'unknown'}.pdf"`);
        res.send(response.data);
    } catch (error) {
        console.error('❌ Failed to generate PDF:', error.message);
        res.status(error.response?.status || 500).json({
            success: false,
            error: error.message,
            message: 'Failed to generate PDF certificate'
        });
    }
});

// GET /api/blockchain/health
// Health check for blockchain service
router.get('/health', async (req, res) => {
    console.log('🏥 Checking blockchain service health');
    
    const result = await forwardToBlockchainService('/health', 'GET');
    
    if (result.success) {
        console.log('✅ Blockchain service is healthy');
        res.status(result.status).json({
            ...result.data,
            proxy_status: 'healthy',
            proxy_timestamp: new Date().toISOString()
        });
    } else {
        console.error('❌ Blockchain service is unhealthy:', result.error);
        res.status(result.status).json({
            success: false,
            error: result.error,
            message: 'Blockchain service is not responding',
            proxy_status: 'unhealthy',
            proxy_timestamp: new Date().toISOString()
        });
    }
});

module.exports = router;