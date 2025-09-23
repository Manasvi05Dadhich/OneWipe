// Integration Test Script for OneWipe
const axios = require('axios');

const BACKEND_URL = 'http://localhost:3000';
const BLOCKCHAIN_URL = 'http://localhost:4000';

async function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function testBackendHealth() {
    try {
        console.log('🔍 Testing Backend Health...');
        const response = await axios.get(`${BACKEND_URL}/api/status`);
        console.log('✅ Backend is healthy:', response.data);
        return true;
    } catch (error) {
        console.error('❌ Backend health check failed:', error.message);
        return false;
    }
}

async function testBlockchainHealth() {
    try {
        console.log('🔍 Testing Blockchain Service Health...');
        const response = await axios.get(`${BLOCKCHAIN_URL}/health`);
        console.log('✅ Blockchain service is healthy');
        return true;
    } catch (error) {
        console.error('❌ Blockchain service health check failed:', error.message);
        return false;
    }
}

async function testProxyIntegration() {
    try {
        console.log('🔍 Testing Proxy Integration...');
        const response = await axios.get(`${BACKEND_URL}/api/blockchain/health`);
        console.log('✅ Proxy integration working:', response.data);
        return true;
    } catch (error) {
        console.error('❌ Proxy integration failed:', error.message);
        return false;
    }
}

async function testCertificateFlow() {
    try {
        console.log('🔍 Testing Certificate Signing & Anchoring...');
        
        const testCert = {
            certID: `test-cert-${Date.now()}`,
            certJSON: {
                device: "test-device",
                wipedBy: "Integration Test",
                policy: "DoD 5220.22-M",
                timestamp: new Date().toISOString()
            }
        };

        const response = await axios.post(`${BACKEND_URL}/api/blockchain/signAndAnchor`, testCert);
        
        if (response.data.success) {
            console.log('✅ Certificate signed and anchored successfully!');
            console.log('📋 Certificate ID:', testCert.certID);
            console.log('🔗 Transaction Hash:', response.data.data.txHash);
            console.log('🌐 PolygonScan:', response.data.data.polygonscan);
            return testCert.certID;
        } else {
            console.error('❌ Certificate signing failed:', response.data);
            return null;
        }
    } catch (error) {
        console.error('❌ Certificate flow test failed:', error.message);
        return null;
    }
}

async function testCertificateVerification(certID) {
    try {
        console.log('🔍 Testing Certificate Verification...');
        
        await sleep(2000); // Wait for blockchain confirmation
        
        const response = await axios.get(`${BACKEND_URL}/api/blockchain/getCert/${certID}`);
        
        if (response.data.success) {
            console.log('✅ Certificate verification successful!');
            console.log('📋 Certificate Details:', response.data.data);
            return true;
        } else {
            console.error('❌ Certificate verification failed:', response.data);
            return false;
        }
    } catch (error) {
        console.error('❌ Certificate verification test failed:', error.message);
        return false;
    }
}

async function runIntegrationTests() {
    console.log('🚀 OneWipe Integration Tests Starting...\n');
    
    let results = {
        backend: false,
        blockchain: false,
        proxy: false,
        certificate: false,
        verification: false
    };
    
    // Test 1: Backend Health
    results.backend = await testBackendHealth();
    console.log('');
    
    // Test 2: Blockchain Service Health  
    results.blockchain = await testBlockchainHealth();
    console.log('');
    
    // Test 3: Proxy Integration
    results.proxy = await testProxyIntegration();
    console.log('');
    
    // Test 4: Certificate Flow
    if (results.backend && results.proxy) {
        const certID = await testCertificateFlow();
        results.certificate = !!certID;
        console.log('');
        
        // Test 5: Certificate Verification
        if (certID) {
            results.verification = await testCertificateVerification(certID);
        }
    } else {
        console.log('⏭️  Skipping certificate tests due to service unavailability');
    }
    
    // Final Results
    console.log('\n' + '='.repeat(50));
    console.log('📊 INTEGRATION TEST RESULTS');
    console.log('='.repeat(50));
    console.log('Backend Health:', results.backend ? '✅ PASS' : '❌ FAIL');
    console.log('Blockchain Service:', results.blockchain ? '✅ PASS' : '❌ FAIL');
    console.log('Proxy Integration:', results.proxy ? '✅ PASS' : '❌ FAIL');
    console.log('Certificate Signing:', results.certificate ? '✅ PASS' : '❌ FAIL');
    console.log('Certificate Verification:', results.verification ? '✅ PASS' : '❌ FAIL');
    
    const totalTests = Object.keys(results).length;
    const passedTests = Object.values(results).filter(r => r).length;
    
    console.log('\n📈 Overall Score:', `${passedTests}/${totalTests} tests passed`);
    
    if (passedTests === totalTests) {
        console.log('🎉 ALL TESTS PASSED! Integration is working perfectly!');
    } else {
        console.log('⚠️  Some tests failed. Check the logs above for details.');
    }
}

// Handle command line usage
if (require.main === module) {
    runIntegrationTests().catch(console.error);
}

module.exports = { runIntegrationTests };