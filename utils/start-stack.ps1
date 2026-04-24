# Knowledge Assistant Docker Stack Startup Script

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Knowledge Assistant + llama.cpp Stack" -ForegroundColor Cyan
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

# Check if models directory exists and has GGUF files
Write-Host "[2/5] Checking models directory..." -ForegroundColor Yellow
$projectRoot = Split-Path -Parent $PSScriptRoot
$modelsDir = Join-Path $projectRoot "models"

if (!(Test-Path $modelsDir)) {
    Write-Host "      [WARNING] Models directory not found" -ForegroundColor Yellow
    Write-Host "      Creating ./models directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $modelsDir | Out-Null
    Write-Host "      [INFO] Please download GGUF models to ./models directory" -ForegroundColor Yellow
    Write-Host "      See docs/LLAMACPP_SETUP.md for instructions" -ForegroundColor Cyan
} else {
    $ggufFiles = Get-ChildItem -Path $modelsDir -Filter "*.gguf" -ErrorAction SilentlyContinue
    if ($ggufFiles.Count -gt 0) {
        Write-Host "      [OK] Found $($ggufFiles.Count) GGUF model(s):" -ForegroundColor Green
        foreach ($file in $ggufFiles | Select-Object -First 3) {
            $sizeMB = [math]::Round($file.Length / 1MB, 1)
            Write-Host "        - $($file.Name) ($sizeMB MB)" -ForegroundColor Gray
        }
    } else {
        Write-Host "      [WARNING] No GGUF models found in ./models" -ForegroundColor Yellow
        Write-Host "      Please download models before starting. See:" -ForegroundColor Yellow
        Write-Host "      docs/LLAMACPP_SETUP.md for instructions" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "      Quick download:" -ForegroundColor Cyan
        Write-Host "      .\utils\download-models.ps1" -ForegroundColor White
        Write-Host ""
        $continue = Read-Host "Continue anyway? (y/N)"
        if ($continue -ne 'y' -and $continue -ne 'Y') {
            exit 0
        }
    }
}

# Check if .env file exists
Write-Host "[3/5] Checking environment configuration..." -ForegroundColor Yellow
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
Write-Host "  - llama.cpp (Gen):  http://localhost:11434  (Gemma 4 26B)" -ForegroundColor White
Write-Host "  - llama.cpp (Embed): http://localhost:11435  (EmbeddingGemma 300M)" -ForegroundColor White
Write-Host ""
Write-Host "Useful Commands:" -ForegroundColor Cyan
Write-Host "  - View logs:        .\utils\view-logs.ps1" -ForegroundColor Gray
Write-Host "  - Stop stack:       .\utils\stop-stack.ps1" -ForegroundColor Gray
Write-Host "  - Test API:         .\utils\test-api.ps1" -ForegroundColor Gray
Write-Host "  - Restart:          docker-compose -f docker-compose.local.yml restart" -ForegroundColor Gray
Write-Host ""
Write-Host "First time setup:" -ForegroundColor Cyan
Write-Host "  1. Open http://localhost:3000" -ForegroundColor White
Write-Host "  2. Create your admin account" -ForegroundColor White
Write-Host "  3. Start chatting with Gemma 4!" -ForegroundColor White
Write-Host ""
