# Z-Image Docker Build Script
param(
    [switch]$NoCache,
    [switch]$Start
)

$ErrorActionPreference = "Stop"

Write-Host "==============================" -ForegroundColor Cyan
Write-Host "Z-Image Docker Build" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Model: Z-Image-Turbo" -ForegroundColor Yellow
Write-Host "Capabilities: Text-to-Image AI Generation" -ForegroundColor Yellow
Write-Host ""

$buildArgs = @()
if ($NoCache) {
    $buildArgs += "--no-cache"
}

Write-Host "Starting Docker Build..." -ForegroundColor Cyan
Write-Host "This will take 5-10 minutes..." -ForegroundColor Yellow
Write-Host ""

$startTime = Get-Date

try {
    docker build --load -t zimage-api:latest @buildArgs .
    
    if ($LASTEXITCODE -eq 0) {
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMinutes
        
        Write-Host ""
        Write-Host "Build Successful!" -ForegroundColor Green
        Write-Host "Build Time: $([math]::Round($duration, 1)) minutes" -ForegroundColor Yellow
        Write-Host ""
        
        if ($Start) {
            Write-Host "Starting Z-Image server..." -ForegroundColor Cyan
            docker-compose up -d
            Write-Host ""
            Write-Host "Server starting..." -ForegroundColor Green
            Write-Host "API Docs: http://localhost:8002/docs" -ForegroundColor Yellow
            Write-Host "Health: http://localhost:8002/health" -ForegroundColor Yellow
        } else {
            Write-Host "Next steps:" -ForegroundColor Cyan
            Write-Host "  docker-compose up -d" -ForegroundColor White
            Write-Host "  http://localhost:8002/docs" -ForegroundColor White
        }
        Write-Host ""
    } else {
        throw "Docker build failed"
    }
    
} catch {
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalMinutes
    
    Write-Host ""
    Write-Host "Build Failed" -ForegroundColor Red
    Write-Host "Time elapsed: $([math]::Round($duration, 1)) minutes" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}
