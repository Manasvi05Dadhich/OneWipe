// geolocation.js - Enhanced geolocation and audit trail services
const crypto = require('crypto');

// Mock geolocation service - replace with real service in production
async function getGeolocationFromIP(ip) {
    // In production, use services like:
    // - ipapi.co
    // - ipgeolocation.io
    // - MaxMind GeoIP
    
    try {
        // Mock data for development
        return {
            ip: ip || 'unknown',
            country: process.env.DEFAULT_COUNTRY || 'Unknown',
            countryCode: process.env.DEFAULT_COUNTRY_CODE || 'UN',
            region: process.env.DEFAULT_REGION || 'Unknown',
            regionCode: process.env.DEFAULT_REGION_CODE || 'UN',
            city: process.env.DEFAULT_CITY || 'Unknown',
            timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
            isp: 'Unknown ISP',
            org: 'Unknown Organization',
            latitude: 0.0,
            longitude: 0.0
        };
    } catch (error) {
        console.warn('⚠️ Geolocation lookup failed:', error.message);
        return {
            ip: ip || 'unknown',
            country: 'Unknown',
            countryCode: 'UN',
            region: 'Unknown',
            regionCode: 'UN',
            city: 'Unknown',
            timezone: 'UTC',
            error: 'Geolocation service unavailable'
        };
    }
}

// Get system information for audit trail
function getSystemInfo() {
    return {
        hostname: process.env.COMPUTERNAME || process.env.HOSTNAME || 'unknown',
        platform: process.platform,
        arch: process.arch,
        nodeVersion: process.version,
        uptime: Math.floor(process.uptime()),
        memory: {
            used: Math.floor(process.memoryUsage().rss / 1024 / 1024), // MB
            heap: Math.floor(process.memoryUsage().heapUsed / 1024 / 1024) // MB
        }
    };
}

// Get network information
function getNetworkInfo(req) {
    return {
        userAgent: req.get('User-Agent') || 'unknown',
        acceptLanguage: req.get('Accept-Language') || 'unknown',
        origin: req.get('Origin') || 'unknown',
        referer: req.get('Referer') || 'unknown',
        forwarded: req.get('X-Forwarded-For') || req.connection.remoteAddress || 'unknown'
    };
}

// Create comprehensive audit trail
async function createAuditTrail(req) {
    const timestamp = new Date().toISOString();
    const clientIP = req.get('X-Forwarded-For') || req.connection.remoteAddress || 'unknown';
    
    // Get geolocation (async)
    const geo = await getGeolocationFromIP(clientIP);
    
    // Get system info
    const system = getSystemInfo();
    
    // Get network info
    const network = getNetworkInfo(req);
    
    // Create unique session ID
    const sessionId = crypto.randomBytes(16).toString('hex');
    
    return {
        timestamp,
        sessionId,
        geolocation: geo,
        system,
        network,
        security: {
            tlsVersion: req.connection.tlsVersion || null,
            cipher: req.connection.getCipher ? req.connection.getCipher() : null,
            authorized: req.connection.authorized || false
        },
        integrity: {
            auditHash: crypto.createHash('sha256')
                .update(JSON.stringify({ timestamp, sessionId, geo, system }))
                .digest('hex')
        }
    };
}

// Validate certificate data integrity
function validateCertificateData(certJSON) {
    const required = ['device', 'wipedBy', 'timestamp'];
    const missing = required.filter(field => !certJSON[field]);
    
    if (missing.length > 0) {
        throw new Error(`Missing required fields: ${missing.join(', ')}`);
    }
    
    // Validate timestamp format
    if (!Date.parse(certJSON.timestamp)) {
        throw new Error('Invalid timestamp format');
    }
    
    // Validate device path (basic)
    if (typeof certJSON.device !== 'string' || certJSON.device.length < 1) {
        throw new Error('Invalid device specification');
    }
    
    return true;
}

// Add security headers to certificate
function addSecurityMetadata(certJSON, auditTrail) {
    return {
        ...certJSON,
        security: {
            issuer: 'OneWipe Secure Certificate Authority',
            version: '1.0',
            standard: 'OneWipe-2025',
            auditTrail,
            compliance: {
                gdpr: true,
                ccpa: true,
                iso27001: true,
                nist: true
            },
            encryption: {
                algorithm: 'RSA-2048',
                hashFunction: 'SHA-256',
                signatureStandard: 'PKCS#1 v1.5'
            }
        }
    };
}

// Rate limiting helper
const rateLimitStore = new Map();

function checkRateLimit(clientIP, limit = 10, window = 60000) { // 10 requests per minute
    const now = Date.now();
    const clientHistory = rateLimitStore.get(clientIP) || [];
    
    // Remove old entries
    const recentRequests = clientHistory.filter(time => now - time < window);
    
    if (recentRequests.length >= limit) {
        return {
            allowed: false,
            remaining: 0,
            resetTime: new Date(Math.min(...recentRequests) + window).toISOString()
        };
    }
    
    // Add current request
    recentRequests.push(now);
    rateLimitStore.set(clientIP, recentRequests);
    
    return {
        allowed: true,
        remaining: limit - recentRequests.length,
        resetTime: new Date(now + window).toISOString()
    };
}

// Clean up old rate limit entries (call periodically)
function cleanupRateLimit() {
    const now = Date.now();
    const window = 60000; // 1 minute
    
    for (const [ip, history] of rateLimitStore.entries()) {
        const recentRequests = history.filter(time => now - time < window);
        if (recentRequests.length === 0) {
            rateLimitStore.delete(ip);
        } else {
            rateLimitStore.set(ip, recentRequests);
        }
    }
}

// Cleanup every 5 minutes
setInterval(cleanupRateLimit, 5 * 60 * 1000);

module.exports = {
    getGeolocationFromIP,
    getSystemInfo,
    getNetworkInfo,
    createAuditTrail,
    validateCertificateData,
    addSecurityMetadata,
    checkRateLimit,
    cleanupRateLimit
};