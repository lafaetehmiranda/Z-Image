#!/usr/bin/env pwsh
# Script para reiniciar Docker e buildar Z-Image

Write-Host "=== Restart Docker & Build Z-Image ===" -ForegroundColor Cyan

Write-Host "`n[1/4] Tentando reiniciar Docker Desktop..." -ForegroundColor Yellow
try {
    # Parar Docker Desktop
    Stop-Process -Name "Docker Desktop" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 5
    
    # Iniciar Docker Desktop
    Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    Write-Host "✓ Docker Desktop reiniciado" -ForegroundColor Green
    Write-Host "⏳ Aguardando Docker inicializar (30 segundos)..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
} catch {
    Write-Host "⚠️  Não conseguiu reiniciar Docker automaticamente" -ForegroundColor Yellow
    Write-Host "Por favor, reinicie Docker Desktop manualmente e pressione Enter" -ForegroundColor Yellow
    Read-Host
}

Write-Host "`n[2/4] Verificando se Docker está respondendo..." -ForegroundColor Yellow
$retries = 0
$maxRetries = 10
while ($retries -lt $maxRetries) {
    try {
        $version = docker version --format "{{.Server.Version}}" 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Docker respondendo (versão $version)" -ForegroundColor Green
            break
        }
    } catch {}
    
    $retries++
    Write-Host "Tentativa $retries/$maxRetries..." -ForegroundColor Gray
    Start-Sleep -Seconds 5
}

if ($retries -eq $maxRetries) {
    Write-Host "✗ Docker não está respondendo" -ForegroundColor Red
    Write-Host "Por favor reinicie Docker Desktop manualmente" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n[3/4] Limpando builds anteriores..." -ForegroundColor Yellow
try {
    docker rm -f zimage-server-lite 2>$null
    docker rmi -f z-image-lightweight 2>$null
    Write-Host "✓ Limpeza concluída" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Alguns recursos podem não ter sido removidos" -ForegroundColor Yellow
}

Write-Host "`n[4/4] Buildando imagem lightweight..." -ForegroundColor Yellow
Write-Host "Isso pode levar 3-5 minutos...`n" -ForegroundColor Gray

cd C:\Users\USER\Z-Image
docker build -f Dockerfile.lightweight -t z-image-lightweight:latest .

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Build concluído com sucesso!" -ForegroundColor Green
    Write-Host "`nPara iniciar o container:" -ForegroundColor Cyan
    Write-Host "docker run -d --name zimage-server -p 8002:8002 -v zimage-cache:/cache z-image-lightweight:latest" -ForegroundColor White
    Write-Host "`nOu usar docker-compose:" -ForegroundColor Cyan
    Write-Host "docker-compose -f docker-compose.lightweight.yml up -d" -ForegroundColor White
} else {
    Write-Host "`n✗ Build falhou" -ForegroundColor Red
    Write-Host "Verifique os logs acima para detalhes" -ForegroundColor Yellow
}

