// test-fixed-api.js
const http = require('http');

function makeRequest(options, postData) {
    return new Promise((resolve, reject) => {
        const req = http.request(options, (res) => {
            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => {
                try {
                    resolve(JSON.parse(data));
                } catch (e) {
                    resolve(data);
                }
            });
        });
        
        req.on('error', reject);
        
        if (postData) {
            req.write(JSON.stringify(postData));
        }
        req.end();
    });
}

async function testFixedAPI() {
    try {
        console.log('=== Testing Fixed API with Timeout ===');
        
        // Wait a bit for service to start
        await new Promise(resolve => setTimeout(resolve, 2000));
        
        // Test health endpoint
        console.log('\n1. Testing health endpoint...');
        const health = await makeRequest({
            hostname: 'localhost',
            port: 4000,
            path: '/health',
            method: 'GET'
        });
        
        if (health.status === 'ok') {
            console.log('✅ Blockchain service is healthy');
            console.log('   Network:', health.network);
            console.log('   Contract reachable:', health.contractReachable);
        } else {
            console.log('❌ Health check failed:', health);
            return;
        }
        
        // Test signing with timeout
        console.log('\n2. Testing certificate signing (30s timeout)...');
        const certID = `timeout-test-${Date.now()}`;
        const certJSON = {
            device: "Test Device",
            wipedBy: "Test User", 
            timestamp: new Date().toISOString(),
            issuer: "Test Issuer"
        };
        
        const startTime = Date.now();
        console.log(`   Signing certificate: ${certID}`);
        console.log(`   Start time: ${new Date().toISOString()}`);
        
        try {
            const result = await makeRequest({
                hostname: 'localhost',
                port: 4000,
                path: '/signAndAnchor',
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                }
            }, { certID, certJSON });
            
            const elapsed = Math.round((Date.now() - startTime) / 1000);
            
            if (result.success) {
                console.log(`✅ Transaction confirmed in ${elapsed} seconds!`);
                console.log('   TX Hash:', result.data.txHash);
                console.log('   Polygonscan:', result.data.polygonscan);
            } else if (result.error && result.error.includes('timeout')) {
                console.log(`⏰ Transaction timed out after ${elapsed} seconds (expected)`);
                console.log('   TX Hash:', result.data?.txHash);
                console.log('   Status:', result.data?.status);
                console.log('   Polygonscan:', result.data?.polygonscan);
                
                if (result.data?.txHash) {
                    console.log('\n3. Testing transaction status check...');
                    const statusResult = await makeRequest({
                        hostname: 'localhost',
                        port: 4000,
                        path: `/txStatus/${certID}`,
                        method: 'GET'
                    });
                    
                    console.log('   Status check result:', statusResult.data?.status);
                    console.log('   Check later at:', statusResult.data?.polygonscan);
                }
            } else {
                console.log('❌ Unexpected result:', result);
            }
            
        } catch (err) {
            console.log('❌ Request failed:', err.message);
        }
        
    } catch (err) {
        console.error('❌ Test failed:', err);
    }
}

testFixedAPI();