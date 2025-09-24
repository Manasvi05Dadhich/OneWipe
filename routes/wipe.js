const express = require('express');
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const axios = require('axios');
const router = express.Router();

// Store active wipe operations
const activeWipes = new Map();

// Ensure logs directory exists
const logsDir = path.join(__dirname, '..', 'wipe-logs');
if (!fs.existsSync(logsDir)) {
    fs.mkdirSync(logsDir, { recursive: true });
}

// Generate unique wipe ID
function generateWipeId() {
    return `wipe-${Date.now()}-${crypto.randomBytes(4).toString('hex')}`;
}

// Get geolocation info (mock - you can integrate real geo service)
function getGeoLocation() {
    return {
        country: process.env.DEFAULT_COUNTRY || 'Unknown',
        city: process.env.DEFAULT_CITY || 'Unknown',
        timezone: Intl.DateTimeFormat().resolvedOptions().timeZone
    };
}

// Call Rust CLI for wiping
function callRustWipe(targetPath, policy, outputPath, options = {}) {
    return new Promise((resolve, reject) => {
        const rustCliPath = path.join(__dirname, '..', 'rust_cli', 'target', 'release', 'rust_cli.exe');
        
        const args = [
            '--target', targetPath,
            '--policy', policy,
            '--output', outputPath
        ];
        
        if (options.dryRun) args.push('--dry-run');
        if (options.force) args.push('--force');
        
        console.log(`🦀 Calling Rust CLI: ${rustCliPath} ${args.join(' ')}`);
        
        const rustProcess = spawn(rustCliPath, args);
        
        let stdout = '';
        let stderr = '';
        
        rustProcess.stdout.on('data', (data) => {
            stdout += data.toString();
            console.log(`📋 Rust stdout: ${data}`);
        });
        
        rustProcess.stderr.on('data', (data) => {
            stderr += data.toString();
            console.log(`⚠️  Rust stderr: ${data}`);
        });
        
        rustProcess.on('close', (code) => {
            if (code === 0) {
                resolve({ stdout, stderr, success: true });
            } else {
                reject({ stdout, stderr, success: false, code });
            }
        });
        
        rustProcess.on('error', (err) => {
            reject({ error: err.message, success: false });
        });
    });
}

// Trigger certificate generation after successful wipe
async function generateCertificate(wipeLog, wipeId) {
    try {
        const geoInfo = getGeoLocation();
        
        const certData = {
            device: wipeLog.folder,
            wipedBy: 'OneWipe-System',
            timestamp: wipeLog.wiped_at,
            policy: wipeLog.policy,
            filesCount: wipeLog.files.length,
            totalSizeBytes: wipeLog.files.reduce((sum, file) => sum + file.size_bytes, 0),
            wipeId: wipeId,
            geo: geoInfo,
            auditTrail: {
                systemUser: process.env.USERNAME || 'unknown',
                hostname: process.env.COMPUTERNAME || 'unknown',
                platform: process.platform,
                nodeVersion: process.version
            }
        };
        
        console.log('🔐 Generating certificate for wipe:', wipeId);
        
        // Call blockchain service to sign and anchor
        const response = await axios.post('http://localhost:4000/signAndAnchor', {
            certID: wipeId,
            certJSON: certData
        }, {
            timeout: 35000 // 35 second timeout
        });
        
        console.log('✅ Certificate generated:', response.data);
        return response.data;
        
    } catch (error) {
        console.error('❌ Certificate generation failed:', error.message);
        return {
            success: false,
            error: error.message,
            txHash: error.response?.data?.data?.txHash || null,
            polygonscan: error.response?.data?.data?.polygonscan || null
        };
    }
}

// Simulate Rust CLI with realistic mock data
function simulateRustWipe(targetPath, policy, outputPath, options = {}) {
    return new Promise((resolve) => {
        console.log(`🎭 Simulating Rust CLI: ${policy} wipe of ${targetPath}`);
        
        // Create mock wipe log data
        const mockWipeLog = {
            folder: targetPath,
            wiped_at: new Date().toISOString(),
            policy: policy === 'clear' ? 'Clear' : 'DoD',
            files: [
                {
                    name: 'document1.pdf',
                    size_bytes: 1024768,
                    path: path.join(targetPath, 'document1.pdf'),
                    passes: policy === 'clear' ? ['Pass 1: zeros'] : ['Pass 1: zeros', 'Pass 2: ones', 'Pass 3: random'],
                    status: options.dryRun ? 'dry-run' : 'completed'
                },
                {
                    name: 'sensitive_data.xlsx',
                    size_bytes: 2048512,
                    path: path.join(targetPath, 'sensitive_data.xlsx'),
                    passes: policy === 'clear' ? ['Pass 1: zeros'] : ['Pass 1: zeros', 'Pass 2: ones', 'Pass 3: random'],
                    status: options.dryRun ? 'dry-run' : 'completed'
                },
                {
                    name: 'confidential.docx',
                    size_bytes: 512256,
                    path: path.join(targetPath, 'confidential.docx'),
                    passes: policy === 'clear' ? ['Pass 1: zeros'] : ['Pass 1: zeros', 'Pass 2: ones', 'Pass 3: random'],
                    status: options.dryRun ? 'dry-run' : 'completed'
                }
            ]
        };
        
        // Write mock log file
        try {
            fs.writeFileSync(outputPath, JSON.stringify(mockWipeLog, null, 2));
            console.log(`✅ Mock wipe log created at: ${outputPath}`);
            
            // Simulate processing time
            setTimeout(() => {
                resolve({ stdout: 'Mock wipe completed successfully', stderr: '', success: true });
            }, options.dryRun ? 2000 : 5000); // 2s for dry run, 5s for full simulation
            
        } catch (error) {
            console.error('❌ Failed to write mock log:', error);
            resolve({ stdout: '', stderr: error.message, success: false });
        }
    });
}

// Mock function - always use simulation
async function ensureRustCLI() {
    console.log('🎭 Using mock Rust CLI simulation');
    return Promise.resolve();
}

// Start wipe operation
router.post('/start', async (req, res) => {
    try {
        const { targetPath, policy = 'clear', dryRun = false, force = false } = req.body;
        
        if (!targetPath) {
            return res.status(400).json({ 
                success: false, 
                error: 'targetPath is required' 
            });
        }
        
        // Check if target exists
        if (!fs.existsSync(targetPath)) {
            return res.status(400).json({ 
                success: false, 
                error: 'Target path does not exist' 
            });
        }
        
        // Ensure Rust CLI is available
        await ensureRustCLI();
        
        const wipeId = generateWipeId();
        const outputPath = path.join(logsDir, `${wipeId}.json`);
        
        // Store operation info
        activeWipes.set(wipeId, {
            status: 'starting',
            targetPath,
            policy,
            dryRun,
            startTime: new Date().toISOString(),
            progress: 0
        });
        
        // Start async wipe process
        (async () => {
            try {
                activeWipes.set(wipeId, { ...activeWipes.get(wipeId), status: 'wiping', progress: 25 });
                
                const wipeResult = await simulateRustWipe(targetPath, policy, outputPath, { dryRun, force });
                
                if (!wipeResult.success) {
                    throw new Error(`Wipe failed: ${wipeResult.stderr}`);
                }
                
                activeWipes.set(wipeId, { ...activeWipes.get(wipeId), status: 'generating-certificate', progress: 75 });
                
                // Read wipe log
                const wipeLogData = JSON.parse(fs.readFileSync(outputPath, 'utf8'));
                
                // Generate certificate
                const certResult = await generateCertificate(wipeLogData, wipeId);
                
                // Update final status
                activeWipes.set(wipeId, {
                    ...activeWipes.get(wipeId),
                    status: 'completed',
                    progress: 100,
                    wipeLog: wipeLogData,
                    certificate: certResult,
                    completedTime: new Date().toISOString()
                });
                
                console.log(`✅ Wipe ${wipeId} completed successfully`);
                
            } catch (error) {
                console.error(`❌ Wipe ${wipeId} failed:`, error.message);
                activeWipes.set(wipeId, {
                    ...activeWipes.get(wipeId),
                    status: 'failed',
                    error: error.message,
                    failedTime: new Date().toISOString()
                });
            }
        })();
        
        res.json({
            success: true,
            wipeId,
            message: 'Wipe operation started',
            status: 'starting',
            estimatedTime: dryRun ? '30 seconds' : '1-3 minutes'
        });
        
    } catch (error) {
        console.error('❌ Failed to start wipe:', error);
        res.status(500).json({ 
            success: false, 
            error: error.message 
        });
    }
});

// Get wipe status
router.get('/status/:id', (req, res) => {
    const wipeId = req.params.id;
    const operation = activeWipes.get(wipeId);
    
    if (!operation) {
        return res.status(404).json({
            success: false,
            error: 'Wipe operation not found'
        });
    }
    
    res.json({
        success: true,
        wipeId,
        ...operation
    });
});

// Get wipe results (detailed)
router.get('/results/:id', (req, res) => {
    const wipeId = req.params.id;
    const operation = activeWipes.get(wipeId);
    
    if (!operation) {
        return res.status(404).json({
            success: false,
            error: 'Wipe operation not found'
        });
    }
    
    if (operation.status !== 'completed') {
        return res.json({
            success: false,
            error: 'Wipe not yet completed',
            currentStatus: operation.status
        });
    }
    
    res.json({
        success: true,
        wipeId,
        wipeDetails: operation.wipeLog,
        certificate: operation.certificate,
        polygonscan: operation.certificate?.data?.polygonscan
    });
});

// List all wipes
router.get('/list', (req, res) => {
    const wipes = Array.from(activeWipes.entries()).map(([id, data]) => ({
        wipeId: id,
        status: data.status,
        targetPath: data.targetPath,
        policy: data.policy,
        startTime: data.startTime,
        completedTime: data.completedTime,
        hasCertificate: !!data.certificate?.success
    }));
    
    res.json({ success: true, wipes });
});

// Legacy endpoint for backward compatibility
router.post('/', async (req, res) => {
    // Redirect old format to new format
    const { path: devicePath, method } = req.body;
    
    const mappedPolicy = method === 'secure' ? 'dod' : 'clear';
    
    res.json({
        success: true,
        message: 'Please use the new endpoint format',
        newEndpoint: '/api/wipe/start',
        requestBody: {
            targetPath: devicePath,
            policy: mappedPolicy
        }
    });
});

module.exports = router;
