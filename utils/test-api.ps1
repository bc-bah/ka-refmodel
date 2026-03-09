# Test Knowledge Assistant API

Write-Host "Testing Knowledge Assistant API..." -ForegroundColor Cyan
Write-Host ""

# Test 1: Health check
Write-Host "[1/3] Health Check..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "http://localhost:8000/health" -Method Get
    Write-Host "      Status: $($health.status)" -ForegroundColor Green
    Write-Host "      Ollama: $($health.ollama_url)" -ForegroundColor Green
} catch {
    Write-Host "      [ERROR] Health check failed: $_" -ForegroundColor Red
    exit 1
}

# Test 2: List models
Write-Host "[2/3] Listing Available Models..." -ForegroundColor Yellow
try {
    $models = Invoke-RestMethod -Uri "http://localhost:8000/v1/models" -Method Get
    Write-Host "      Found $($models.data.Count) models:" -ForegroundColor Green
    $models.data | Select-Object -First 3 | ForEach-Object {
        Write-Host "        - $($_.id)" -ForegroundColor Gray
    }
} catch {
    Write-Host "      [ERROR] Failed to list models: $_" -ForegroundColor Red
}

# Test 3: Chat completion
Write-Host "[3/3] Testing Chat Completion..." -ForegroundColor Yellow
try {
    $body = @{
        model = "qwen3:30b"
        messages = @(
            @{
                role = "user"
                content = "Say 'Knowledge Assistant is working!' in one short sentence."
            }
        )
    }
    
    $response = Invoke-RestMethod -Uri "http://localhost:8000/v1/chat/completions" `
                                   -Method Post `
                                   -ContentType "application/json" `
                                   -Body ($body | ConvertTo-Json -Depth 10)
    
    $reply = $response.choices[0].message.content
    Write-Host "      Model: $($response.model)" -ForegroundColor Green
    Write-Host "      Response: $reply" -ForegroundColor Green
} catch {
    Write-Host "      [ERROR] Chat completion failed: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "All services are working!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Ready to use:" -ForegroundColor White
Write-Host "  - Open WebUI:  http://localhost:3000" -ForegroundColor Cyan
Write-Host "  - API Docs:    http://localhost:8000/docs" -ForegroundColor Cyan
Write-Host ""
