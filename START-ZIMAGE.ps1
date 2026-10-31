#!/usr/bin/env pwsh
# Start Z-Image Container

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  Starting Z-Image Docker Container" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

Write-Host "[1/3] Removing old container (if exists)..." -ForegroundColor Yellow
docker rm -f zimage-server 2>$null | Out-Null

Write-Host "[2/3] Starting new container..." -ForegroundColor Yellow
docker run -d `
    --name zimage-server `
    -p 8002:8002 `
    --restart unless-stopped `
    zimage-simple:latest

if ($LASTEXITCODE -eq 0) {
    Write-Host "OK - Container started!" -ForegroundColor Green
} else {
    Write-Host "ERRO - Failed to start container" -ForegroundColor Red
    exit 1
}

Write-Host "`n[3/3] Checking status..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

docker ps --filter "name=zimage-server" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "  Z-Image API is RUNNING!" -ForegroundColor Green
Write-Host "======================================`n" -ForegroundColor Cyan

Write-Host "Endpoints:" -ForegroundColor Yellow
Write-Host "  Health:  http://localhost:8002/health" -ForegroundColor White
Write-Host "  Info:    http://localhost:8002/info" -ForegroundColor White
Write-Host "  Docs:    http://localhost:8002/docs" -ForegroundColor White
Write-Host "  API:     http://localhost:8002/`n" -ForegroundColor White

Write-Host "Test it:" -ForegroundColor Yellow
Write-Host "  curl http://localhost:8002/health`n" -ForegroundColor Gray

Write-Host "View logs:" -ForegroundColor Yellow
Write-Host "  docker logs -f zimage-server`n" -ForegroundColor Gray

Write-Host "Stop it:" -ForegroundColor Yellow
Write-Host "  docker stop zimage-server`n" -ForegroundColor Gray

