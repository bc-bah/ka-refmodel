# Knowledge Assistant Docker Stack Shutdown Script

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Stopping Knowledge Assistant Stack" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Stop containers
Write-Host "Stopping Docker containers..." -ForegroundColor Yellow
$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
docker-compose -f docker-compose.local.yml down
Pop-Location

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Stack stopped successfully" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Failed to stop stack" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "To remove all data (WARNING: This deletes your database):" -ForegroundColor Yellow
Write-Host "  docker-compose -f docker-compose.local.yml down -v" -ForegroundColor Gray
Write-Host ""
