# View Knowledge Assistant Docker Stack Logs

param(
    [string]$Service = ""
)

$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot

if ($Service -eq "") {
    Write-Host "Viewing logs for all services..." -ForegroundColor Cyan
    Write-Host "Press Ctrl+C to exit" -ForegroundColor Gray
    Write-Host ""
    docker-compose -f docker-compose.local.yml logs -f
} else {
    Write-Host "Viewing logs for: $Service" -ForegroundColor Cyan
    Write-Host "Press Ctrl+C to exit" -ForegroundColor Gray
    Write-Host ""
    docker-compose -f docker-compose.local.yml logs -f $Service
}

Pop-Location
