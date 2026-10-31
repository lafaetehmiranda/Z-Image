#!/usr/bin/env pwsh
# Test if Docker is working and build minimal image

Write-Host "=== Test Docker & Build Minimal Z-Image ===" -ForegroundColor Cyan

Write-Host "`n[1/3] Testing Docker..." -ForegroundColor Yellow
$dockerWorks = $false
try {
    $timeout = 5
    $job = Start-Job -ScriptBlock { docker ps -q }
    Wait-Job $job -Timeout $timeout | Out-Null
    if ($job.State -eq 'Completed') {
        $dockerWorks = $true
        Write-Host "OK - Docker esta funcionando" -ForegroundColor Green
    } else {
        Stop-Job $job
        Remove-Job $job
        Write-Host "ERRO - Docker nao responde em ${timeout}s" -ForegroundColor Red
    }
} catch {
    Write-Host "ERRO - Docker nao esta acessivel" -ForegroundColor Red
}

if (-not $dockerWorks) {
    Write-Host "`nSOLUCAO:" -ForegroundColor Yellow
    Write-Host "1. Abra Docker Desktop" -ForegroundColor White
    Write-Host "2. Espere ele inicializar completamente (icone verde)" -ForegroundColor White
    Write-Host "3. Execute este script novamente`n" -ForegroundColor White
    Write-Host "OU use a alternativa sem Docker:" -ForegroundColor Cyan
    Write-Host ".\start-local.ps1`n" -ForegroundColor White
    exit 1
}

Write-Host "`n[2/3] Building minimal image (1-2 minutos)..." -ForegroundColor Yellow
cd C:\Users\USER\Z-Image

$buildStart = Get-Date
docker build -f Dockerfile.minimal -t zimage-minimal:latest .

if ($LASTEXITCODE -eq 0) {
    $buildTime = ((Get-Date) - $buildStart).TotalSeconds
    Write-Host "OK - Build concluido em $([math]::Round($buildTime))s" -ForegroundColor Green
} else {
    Write-Host "ERRO - Build falhou" -ForegroundColor Red
    exit 1
}

Write-Host "`n[3/3] Starting container..." -ForegroundColor Yellow
docker rm -f zimage-minimal 2>$null | Out-Null
docker run -d --name zimage-minimal -p 8002:8002 zimage-minimal:latest

if ($LASTEXITCODE -eq 0) {
    Start-Sleep -Seconds 3
    Write-Host "OK - Container iniciado" -ForegroundColor Green
    
    Write-Host "`nTesting API..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8002/health" -TimeoutSec 5
        Write-Host "SUCESSO - API esta funcionando!" -ForegroundColor Green
        Write-Host ($response | ConvertTo-Json) -ForegroundColor White
        
        Write-Host "`nEndpoints disponiveis:" -ForegroundColor Cyan
        Write-Host "Health: http://localhost:8002/health" -ForegroundColor White
        Write-Host "Info:   http://localhost:8002/info" -ForegroundColor White
        Write-Host "Docs:   http://localhost:8002/docs" -ForegroundColor White
    } catch {
        Write-Host "AVISO - API ainda nao esta respondendo (pode levar alguns segundos)" -ForegroundColor Yellow
        Write-Host "Teste manualmente: curl http://localhost:8002/health" -ForegroundColor White
    }
} else {
    Write-Host "ERRO - Falha ao iniciar container" -ForegroundColor Red
}

Write-Host "`nContainer status:" -ForegroundColor Cyan
docker ps --filter "name=zimage-minimal" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

