# OneWipe Service Startup Script
Write-Host "🚀 Starting OneWipe Services..." -ForegroundColor Green

# Start blockchain service in background
Write-Host "📦 Starting Blockchain Service (Port 4000)..." -ForegroundColor Yellow
$blockchainJob = Start-Job -ScriptBlock {
    Set-Location "C:\Users\manas\OneDrive\Desktop\OneWipe\blockchain-certs"
    cmd /c "node api/index.js"
}

# Wait a moment for blockchain service to start
Start-Sleep 3

# Start main backend
Write-Host "🌐 Starting Main Backend (Port 3000)..." -ForegroundColor Yellow
Set-Location "C:\Users\manas\OneDrive\Desktop\OneWipe"
cmd /c "node server.js"

# Cleanup background job when script ends
Write-Host "🛑 Stopping services..." -ForegroundColor Red
Stop-Job $blockchainJob
Remove-Job $blockchainJob