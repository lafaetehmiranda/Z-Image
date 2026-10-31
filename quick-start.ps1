#!/usr/bin/env pwsh
# Quick Start Z-Image - Roda localmente SEM Docker

Write-Host "=== Z-Image Quick Start (Sem Docker) ===" -ForegroundColor Cyan

# Verificar Python
Write-Host "`n[1/5] Verificando Python..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    Write-Host "OK - $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "ERRO - Python nao encontrado" -ForegroundColor Red
    Write-Host "Instale Python 3.10+ de https://python.org" -ForegroundColor Yellow
    exit 1
}

# Criar venv
Write-Host "`n[2/5] Criando ambiente virtual..." -ForegroundColor Yellow
if (Test-Path "venv") {
    Write-Host "OK - venv ja existe" -ForegroundColor Green
} else {
    python -m venv venv
    if ($LASTEXITCODE -eq 0) {
        Write-Host "OK - venv criado" -ForegroundColor Green
    } else {
        Write-Host "ERRO - Falha ao criar venv" -ForegroundColor Red
        exit 1
    }
}

# Ativar venv
Write-Host "`n[3/5] Ativando ambiente virtual..." -ForegroundColor Yellow
& ".\venv\Scripts\Activate.ps1"
if ($LASTEXITCODE -eq 0) {
    Write-Host "OK - venv ativado" -ForegroundColor Green
} else {
    Write-Host "ERRO - Falha ao ativar venv" -ForegroundColor Red
    exit 1
}

# Instalar dependencias
Write-Host "`n[4/5] Instalando dependencias..." -ForegroundColor Yellow
Write-Host "Isso pode levar 5-10 minutos na primeira vez..." -ForegroundColor Gray

$packages = @(
    "fastapi==0.115.6",
    "uvicorn[standard]==0.34.0",
    "python-multipart==0.0.20",
    "torch>=2.5.0",
    "transformers>=4.51.0",
    "safetensors",
    "loguru",
    "pillow",
    "accelerate",
    "huggingface_hub>=0.25.0"
)

pip install --upgrade pip setuptools wheel
pip install $packages

if ($LASTEXITCODE -eq 0) {
    Write-Host "OK - Dependencias instaladas" -ForegroundColor Green
} else {
    Write-Host "ERRO - Falha na instalacao" -ForegroundColor Red
    exit 1
}

# Iniciar servidor
Write-Host "`n[5/5] Iniciando servidor Z-Image..." -ForegroundColor Yellow
Write-Host "ATENCAO: Primeira execucao baixa ~12GB de modelo!" -ForegroundColor Magenta
Write-Host "Pode levar 10-30 minutos dependendo da internet`n" -ForegroundColor Magenta

Write-Host "Servidor iniciando em http://localhost:8002" -ForegroundColor Cyan
Write-Host "Docs: http://localhost:8002/docs" -ForegroundColor Cyan
Write-Host "Pressione Ctrl+C para parar`n" -ForegroundColor Yellow

python docker_api.py

