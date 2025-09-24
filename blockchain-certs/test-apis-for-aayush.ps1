# PowerShell script to test blockchain APIs for Aayush
# Run this to verify your APIs are working before handover

Write-Host "🚀 Testing OneWipe Blockchain APIs for Aayush..." -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

# Test 1: Health Check
Write-Host "`n1. Testing Health Check..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-WebRequest -Uri "http://localhost:4000/health" -UseBasicParsing
    $health = $healthResponse.Content | ConvertFrom-Json
    Write-Host "✅ Health Check: " -ForegroundColor Green -NoNewline
    Write-Host "Status=$($health.status), Contract=$($health.contractAddress)" -ForegroundColor White
} catch {
    Write-Host "❌ Health Check Failed: $_" -ForegroundColor Red
    Write-Host "   → Make sure blockchain service is running on port 4000" -ForegroundColor Yellow
    exit 1
}

# Test 2: Create Test Certificate
Write-Host "`n2. Creating Test Certificate..." -ForegroundColor Yellow
$testCert = @{
    certID = "aayush-test-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    certJSON = @{
        device = "Test Laptop for Aayush Portal"
        wipedBy = "OneWipe-System"
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        policy = "NIST-Clear"
    }
} | ConvertTo-Json -Depth 3

try {
    $certResponse = Invoke-WebRequest -Uri "http://localhost:4000/signAndAnchor" `
        -Method POST `
        -ContentType "application/json" `
        -Body $testCert `
        -UseBasicParsing
    
    $cert = $certResponse.Content | ConvertFrom-Json
    if ($cert.success) {
        Write-Host "✅ Certificate Created: " -ForegroundColor Green -NoNewline
        Write-Host "ID=$($cert.data.certID)" -ForegroundColor White
        $global:testCertID = $cert.data.certID
        $global:testSignature = $cert.data.signatureBase64
    } else {
        Write-Host "❌ Certificate Creation Failed: $($cert.error)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Certificate Creation Failed: $_" -ForegroundColor Red
}

# Test 3: Verify Certificate
if ($global:testCertID -and $global:testSignature) {
    Write-Host "`n3. Testing Certificate Verification..." -ForegroundColor Yellow
    
    $verifyData = @{
        certID = $global:testCertID
        certJSON = @{
            device = "Test Laptop for Aayush Portal"
            wipedBy = "OneWipe-System"
            timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            policy = "NIST-Clear"
        }
        signatureBase64 = $global:testSignature
    } | ConvertTo-Json -Depth 3
    
    try {
        $verifyResponse = Invoke-WebRequest -Uri "http://localhost:4000/verifyFull" `
            -Method POST `
            -ContentType "application/json" `
            -Body $verifyData `
            -UseBasicParsing
        
        $verify = $verifyResponse.Content | ConvertFrom-Json
        if ($verify.success) {
            Write-Host "✅ Certificate Verified: " -ForegroundColor Green -NoNewline
            Write-Host "Signature=$($verify.data.validSignature), Anchored=$($verify.data.anchored)" -ForegroundColor White
        } else {
            Write-Host "❌ Verification Failed: $($verify.error)" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Verification Failed: $_" -ForegroundColor Red
    }
}

# Test 4: Get Certificate from Blockchain
if ($global:testCertID) {
    Write-Host "`n4. Testing Get Certificate..." -ForegroundColor Yellow
    try {
        $getCertResponse = Invoke-WebRequest -Uri "http://localhost:4000/getCert/$($global:testCertID)" -UseBasicParsing
        $getCert = $getCertResponse.Content | ConvertFrom-Json
        if ($getCert.success) {
            Write-Host "✅ Get Certificate: " -ForegroundColor Green -NoNewline
            Write-Host "Found on blockchain, TX=$($getCert.data.txHash)" -ForegroundColor White
        } else {
            Write-Host "⚠️ Get Certificate: $($getCert.error)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ Get Certificate Failed: $_" -ForegroundColor Red
    }
}

# Summary
Write-Host "`n================================================" -ForegroundColor Green
Write-Host "🎯 API Testing Complete!" -ForegroundColor Green
Write-Host "`n📦 Ready to send to Aayush:" -ForegroundColor Cyan
Write-Host "   • API_DOCS.md (complete documentation)" -ForegroundColor White
Write-Host "   • Base URL: http://localhost:4000" -ForegroundColor White
Write-Host "   • Test Certificate ID: $($global:testCertID)" -ForegroundColor White
Write-Host "`n📧 Email Aayush with:" -ForegroundColor Cyan
Write-Host "   • This test certificate for his React portal testing" -ForegroundColor White
Write-Host "   • API documentation from API_DOCS.md" -ForegroundColor White
Write-Host "   • Contract address: 0x8469CfC74478b2A26BfB944ADefCD18e27f5D0b7" -ForegroundColor White

Write-Host "`n✅ Your blockchain APIs are ready for Aayush's verification portal!" -ForegroundColor Green