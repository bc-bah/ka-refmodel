# Knowledge Assistant Docker Stack Startup Script

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Knowledge Assistant + Open WebUI Stack" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
Write-Host "[1/5] Checking Docker Desktop..." -ForegroundColor Yellow
try {
    docker info | Out-Null
    Write-Host "      [OK] Docker is running" -ForegroundColor Green
} catch {
    Write-Host "      [ERROR] Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

# Check if Ollama is running locally
Write-Host "[2/5] Checking local Ollama..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" -UseBasicParsing -ErrorAction Stop
    Write-Host "      [OK] Ollama is running" -ForegroundColor Green
    
    # Display available models
    $models = ($response.Content | ConvertFrom-Json).models
    Write-Host "      Available models:" -ForegroundColor Cyan
    foreach ($model in $models | Select-Object -First 5) {
        Write-Host "        - $($model.name)" -ForegroundColor Gray
    }
} catch {
    Write-Host "      [WARNING] Ollama is not running at http://localhost:11434" -ForegroundColor Yellow
    Write-Host "      The stack will still start, but LLM features won't work." -ForegroundColor Yellow
    Write-Host "      Start Ollama with: ollama serve" -ForegroundColor Yellow
}

# Check if .env file exists
Write-Host "[3/5] Checking environment configuration..." -ForegroundColor Yellow
$projectRoot = Split-Path -Parent $PSScriptRoot
if (!(Test-Path "$projectRoot\.env")) {
    Write-Host "      [INFO] Creating .env file from .env.example" -ForegroundColor Yellow
    Copy-Item "$projectRoot\.env.example" "$projectRoot\.env"
    Write-Host "      [OK] .env file created" -ForegroundColor Green
} else {
    Write-Host "      [OK] .env file exists" -ForegroundColor Green
}

# Build and start Docker containers
Write-Host "[4/5] Building and starting Docker containers..." -ForegroundColor Yellow
Write-Host "      This may take a few minutes on first run..." -ForegroundColor Gray
Push-Location $projectRoot
docker-compose -f docker-compose.local.yml up -d --build
Pop-Location

if ($LASTEXITCODE -eq 0) {
    Write-Host "      [OK] Containers started successfully" -ForegroundColor Green
} else {
    Write-Host "      [ERROR] Failed to start containers" -ForegroundColor Red
    exit 1
}

# Wait for services to be healthy
Write-Host "[5/5] Waiting for services to be ready..." -ForegroundColor Yellow
Write-Host "      PostgreSQL..." -ForegroundColor Gray
Start-Sleep -Seconds 5

$maxAttempts = 30
$attempt = 0
$kaReady = $false

while ($attempt -lt $maxAttempts -and !$kaReady) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -UseBasicParsing -ErrorAction Stop
        $kaReady = $true
    } catch {
        $attempt++
        Write-Host "      Waiting for KA Backend... ($attempt/$maxAttempts)" -ForegroundColor Gray
        Start-Sleep -Seconds 2
    }
}

if ($kaReady) {
    Write-Host "      [OK] Knowledge Assistant API is ready" -ForegroundColor Green
} else {
    Write-Host "      [WARNING] KA Backend is taking longer than expected" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Stack is running!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Services:" -ForegroundColor Cyan
Write-Host "  - Open WebUI:       http://localhost:3000" -ForegroundColor White
Write-Host "  - KA API:           http://localhost:8000" -ForegroundColor White
Write-Host "  - KA API Docs:      http://localhost:8000/docs" -ForegroundColor White
Write-Host "  - PostgreSQL:       localhost:5433" -ForegroundColor White
Write-Host "  - Ollama (Host):    http://localhost:11434" -ForegroundColor White
Write-Host ""
Write-Host "Useful Commands:" -ForegroundColor Cyan
Write-Host "  - View logs:        docker-compose -f docker-compose.local.yml logs -f" -ForegroundColor Gray
Write-Host "  - Stop stack:       .\stop-stack.ps1" -ForegroundColor Gray
Write-Host "  - Restart:          docker-compose -f docker-compose.local.yml restart" -ForegroundColor Gray
Write-Host ""
Write-Host "First time setup:" -ForegroundColor Cyan
Write-Host "  1. Open http://localhost:3000" -ForegroundColor White
Write-Host "  2. Create your admin account" -ForegroundColor White
Write-Host "  3. Start chatting with your local models!" -ForegroundColor White
Write-Host ""
