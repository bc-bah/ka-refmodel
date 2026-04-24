# Download Gemma 4 Models for llama.cpp
# This script downloads GGUF models from Hugging Face

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Gemma 4 Model Downloader" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Determine project root and models directory
$projectRoot = Split-Path -Parent $PSScriptRoot
$modelsDir = Join-Path $projectRoot "models"

# Create models directory if it doesn't exist
if (!(Test-Path $modelsDir)) {
    Write-Host "Creating models directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $modelsDir | Out-Null
    Write-Host "[OK] Models directory created: $modelsDir" -ForegroundColor Green
    Write-Host ""
}

# Check if Hugging Face CLI is installed
Write-Host "Checking for Hugging Face CLI..." -ForegroundColor Yellow
$hfInstalled = $null -ne (Get-Command "huggingface-cli" -ErrorAction SilentlyContinue)

if (!$hfInstalled) {
    Write-Host "[INFO] Hugging Face CLI not found" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To install Hugging Face CLI, run:" -ForegroundColor Cyan
    Write-Host "  pip install huggingface-hub" -ForegroundColor White
    Write-Host ""
    Write-Host "Alternative: Download manually from:" -ForegroundColor Cyan
    Write-Host "  https://huggingface.co/ggml-org/gemma-4-9b-it-GGUF" -ForegroundColor White
    Write-Host ""
    
    $installNow = Read-Host "Install huggingface-hub now? (y/N)"
    if ($installNow -eq 'y' -or $installNow -eq 'Y') {
        Write-Host "Installing huggingface-hub..." -ForegroundColor Yellow
        pip install huggingface-hub
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] huggingface-hub installed successfully" -ForegroundColor Green
            $hfInstalled = $true
        } else {
            Write-Host "[ERROR] Failed to install huggingface-hub" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "Exiting. Please install manually and run this script again." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "[OK] Hugging Face CLI is available" -ForegroundColor Green
Write-Host ""

# Model options
Write-Host "Available Gemma 4 9B quantizations:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. Q4_K_M  (~5.5 GB) - Recommended for most users" -ForegroundColor White
Write-Host "  2. Q5_K_M  (~6.5 GB) - Better quality" -ForegroundColor White
Write-Host "  3. Q6_K    (~7.5 GB) - High quality" -ForegroundColor White
Write-Host "  4. Q8_0    (~9.5 GB) - Highest quality" -ForegroundColor White
Write-Host "  5. f16     (~18 GB)  - Full precision (for development)" -ForegroundColor White
Write-Host ""
Write-Host "  A. All quantizations (download all)" -ForegroundColor Yellow
Write-Host ""

$choice = Read-Host "Select quantization to download (1-5 or A)"

# Map choice to model filename
$modelFile = switch ($choice) {
    "1" { "gemma-4-9b-it-Q4_K_M.gguf" }
    "2" { "gemma-4-9b-it-Q5_K_M.gguf" }
    "3" { "gemma-4-9b-it-Q6_K.gguf" }
    "4" { "gemma-4-9b-it-Q8_0.gguf" }
    "5" { "gemma-4-9b-it-f16.gguf" }
    "A" { "all" }
    "a" { "all" }
    default {
        Write-Host "[ERROR] Invalid choice: $choice" -ForegroundColor Red
        exit 1
    }
}

$repoId = "ggml-org/gemma-4-9b-it-GGUF"

if ($modelFile -eq "all") {
    Write-Host ""
    Write-Host "Downloading all quantizations..." -ForegroundColor Yellow
    Write-Host "This will download approximately 55 GB of models" -ForegroundColor Yellow
    Write-Host ""
    
    $confirm = Read-Host "Continue? (y/N)"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        Write-Host "Download cancelled." -ForegroundColor Yellow
        exit 0
    }
    
    Write-Host ""
    Write-Host "Downloading all GGUF files from $repoId..." -ForegroundColor Cyan
    Write-Host "This may take a while depending on your internet connection..." -ForegroundColor Gray
    Write-Host ""
    
    Push-Location $modelsDir
    huggingface-cli download $repoId --include "*.gguf" --local-dir . --local-dir-use-symlinks False
    Pop-Location
} else {
    # Check if model already exists
    $modelPath = Join-Path $modelsDir $modelFile
    if (Test-Path $modelPath) {
        Write-Host ""
        Write-Host "[INFO] Model already exists: $modelFile" -ForegroundColor Yellow
        $overwrite = Read-Host "Re-download? (y/N)"
        if ($overwrite -ne 'y' -and $overwrite -ne 'Y') {
            Write-Host "Download cancelled." -ForegroundColor Yellow
            exit 0
        }
    }
    
    Write-Host ""
    Write-Host "Downloading $modelFile..." -ForegroundColor Cyan
    Write-Host "From: $repoId" -ForegroundColor Gray
    Write-Host "To: $modelsDir" -ForegroundColor Gray
    Write-Host ""
    Write-Host "This may take a while depending on your internet connection..." -ForegroundColor Gray
    Write-Host ""
    
    Push-Location $modelsDir
    huggingface-cli download $repoId $modelFile --local-dir . --local-dir-use-symlinks False
    Pop-Location
}

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Download Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    
    # List downloaded models
    $ggufFiles = Get-ChildItem -Path $modelsDir -Filter "*.gguf"
    Write-Host "Models in $modelsDir:" -ForegroundColor Cyan
    foreach ($file in $ggufFiles) {
        $sizeMB = [math]::Round($file.Length / 1MB, 1)
        $sizeGB = [math]::Round($file.Length / 1GB, 2)
        if ($sizeGB -ge 1) {
            Write-Host "  - $($file.Name) ($sizeGB GB)" -ForegroundColor White
        } else {
            Write-Host "  - $($file.Name) ($sizeMB MB)" -ForegroundColor White
        }
    }
    Write-Host ""
    
    # Check if docker-compose needs updating
    $dockerComposePath = Join-Path $projectRoot "docker-compose.local.yml"
    if (Test-Path $dockerComposePath) {
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "  1. Verify docker-compose.local.yml points to your model" -ForegroundColor White
        Write-Host "     (default: gemma-4-9b-it-Q4_K_M.gguf)" -ForegroundColor Gray
        Write-Host "  2. Start the stack:" -ForegroundColor White
        Write-Host "     .\utils\start-stack.ps1" -ForegroundColor Gray
        Write-Host ""
    }
} else {
    Write-Host ""
    Write-Host "[ERROR] Download failed" -ForegroundColor Red
    Write-Host ""
    Write-Host "You can manually download from:" -ForegroundColor Yellow
    Write-Host "  https://huggingface.co/$repoId" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}
