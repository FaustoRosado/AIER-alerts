# ============================================================================
# Zero-Trust Hybrid AI Pipeline
# Aegis (Windows 11 Pro + RTX 4080 Super) Setup Script
# ============================================================================
#
# This script configures Aegis as the primary inference node using llama.cpp
# with CUDA acceleration on the RTX 4080 Super.
#
# Why llama.cpp instead of Ollama?
#   - Direct CUDA control for maximum performance
#   - Continuous batching for higher throughput
#   - More configuration options (context size, batch size, etc.)
#   - OpenAI-compatible API out of the box
#
# Hardware: AMD Ryzen 9950X, RTX 4080 Super 16GB VRAM, 64GB DDR5
# OS: Windows 11 Pro
# Drivers: NVIDIA Game Ready (includes CUDA runtime)
#
# Prerequisites:
#   - Windows 11 Pro
#   - NVIDIA Game Ready drivers installed (you have these for Steam)
#   - Tailscale installed and connected (hostname: aegis)
#   - Administrator privileges
#
# Usage:
#   1. Open PowerShell as Administrator
#   2. Set-ExecutionPolicy Bypass -Scope Process
#   3. .\setup-aegis.ps1
#
# ============================================================================

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Aegis Setup Script" -ForegroundColor Cyan
Write-Host "Primary Inference Node - RTX 4080 Super" -ForegroundColor Cyan
Write-Host "Using llama.cpp with CUDA" -ForegroundColor Cyan
Write-Host "Zero-Trust Hybrid AI Pipeline" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$LLAMA_CPP_VERSION = "b7223"
$MODEL_NAME = "Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf"
$MODEL_URL = "https://huggingface.co/lmstudio-community/Meta-Llama-3.1-8B-Instruct-GGUF/resolve/main/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf"
$INSTALL_DIR = "C:\llama.cpp"
$MODELS_DIR = "C:\llama.cpp\models"
$PORT = 8080

# ============================================================================
# Step 1: Verify NVIDIA GPU and CUDA
# ============================================================================

Write-Host "Step 1: Verifying NVIDIA GPU and CUDA..." -ForegroundColor Yellow

$nvidiaSmi = Get-Command nvidia-smi -ErrorAction SilentlyContinue
if (-not $nvidiaSmi) {
    Write-Host "  ERROR: nvidia-smi not found" -ForegroundColor Red
    Write-Host "  Install NVIDIA Game Ready drivers from geforce.com/drivers" -ForegroundColor Red
    exit 1
}

Write-Host "  Checking GPU..."
$gpuInfo = & nvidia-smi --query-gpu=name,memory.total,driver_version,compute_cap --format=csv,noheader
Write-Host "  $gpuInfo" -ForegroundColor Green

$cudaVersion = (& nvidia-smi | Select-String "CUDA Version").ToString() -replace '.*CUDA Version:\s*(\d+\.\d+).*', '$1'
Write-Host "  CUDA Version: $cudaVersion" -ForegroundColor Green
Write-Host ""

# NOTE: SSH setup removed - configure SSH manually before running this script
$currentUser = $env:USERNAME

# ============================================================================
# Step 2: Configure Windows Firewall
# ============================================================================

Write-Host "Step 2: Configuring Windows Firewall..." -ForegroundColor Yellow

Get-NetFirewallRule -DisplayName "Aegis-*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule

New-NetFirewallRule -DisplayName "Aegis-SSH-Tailscale" `
    -Direction Inbound -Protocol TCP -LocalPort 22 `
    -RemoteAddress "100.64.0.0/10" -Action Allow | Out-Null

New-NetFirewallRule -DisplayName "Aegis-LlamaServer-Tailscale" `
    -Direction Inbound -Protocol TCP -LocalPort $PORT `
    -RemoteAddress "100.64.0.0/10" -Action Allow | Out-Null

Write-Host "  Firewall configured" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Step 3: Download llama.cpp
# ============================================================================

Write-Host "Step 3: Installing llama.cpp..." -ForegroundColor Yellow

New-Item -ItemType Directory -Path $INSTALL_DIR -Force | Out-Null
New-Item -ItemType Directory -Path $MODELS_DIR -Force | Out-Null

$llamaZipUrl = "https://github.com/ggml-org/llama.cpp/releases/download/$LLAMA_CPP_VERSION/llama-$LLAMA_CPP_VERSION-bin-win-cuda-12.4-x64.zip"
$cudartZipUrl = "https://github.com/ggml-org/llama.cpp/releases/download/$LLAMA_CPP_VERSION/cudart-llama-bin-win-cuda-12.4-x64.zip"
$llamaZipPath = "$env:TEMP\llama-cpp.zip"
$cudartZipPath = "$env:TEMP\cudart.zip"

Write-Host "  Downloading llama.cpp $LLAMA_CPP_VERSION..."
Invoke-WebRequest -Uri $llamaZipUrl -OutFile $llamaZipPath -UseBasicParsing

Write-Host "  Downloading CUDA runtime..."
Invoke-WebRequest -Uri $cudartZipUrl -OutFile $cudartZipPath -UseBasicParsing

Expand-Archive -Path $llamaZipPath -DestinationPath $INSTALL_DIR -Force
Expand-Archive -Path $cudartZipPath -DestinationPath $INSTALL_DIR -Force
Remove-Item $llamaZipPath
Remove-Item $cudartZipPath

# Move files to root if in subdirectory
$serverExe = Get-ChildItem -Path $INSTALL_DIR -Recurse -Filter "llama-server.exe" | Select-Object -First 1
if ($serverExe -and $serverExe.DirectoryName -ne $INSTALL_DIR) {
    Get-ChildItem -Path $serverExe.DirectoryName | Move-Item -Destination $INSTALL_DIR -Force -ErrorAction SilentlyContinue
}

Write-Host "  llama.cpp installed to $INSTALL_DIR" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Step 4: Download Model
# ============================================================================

Write-Host "Step 4: Downloading Llama 3.1 8B model (~4.9GB)..." -ForegroundColor Yellow

$modelPath = "$MODELS_DIR\$MODEL_NAME"

if (-not (Test-Path $modelPath)) {
    try {
        Start-BitsTransfer -Source $MODEL_URL -Destination $modelPath -DisplayName "Downloading Llama 3.1 8B"
    } catch {
        Invoke-WebRequest -Uri $MODEL_URL -OutFile $modelPath -UseBasicParsing
    }
}

$modelSize = [math]::Round((Get-Item $modelPath).Length / 1GB, 2)
Write-Host "  Model downloaded: $modelSize GB" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Step 5: Create Startup Script
# ============================================================================

Write-Host "Step 5: Creating startup scripts..." -ForegroundColor Yellow

$startupScript = @"
# Aegis llama-server Startup Script
# RTX 4080 Super optimal settings

`$ErrorActionPreference = "SilentlyContinue"

`$INSTALL_DIR = "$INSTALL_DIR"
`$MODEL_PATH = "$modelPath"
`$PORT = $PORT

# Check if already running
`$existing = Get-Process -Name "llama-server" -ErrorAction SilentlyContinue
if (`$existing) {
    Write-Host "llama-server already running (PID: `$(`$existing.Id))"
    exit 0
}

Write-Host "Starting llama-server on port `$PORT..."

Set-Location `$INSTALL_DIR

# RTX 4080 Super settings:
#   -ngl 99 = All layers on GPU
#   -c 8192 = 8K context
#   -b 512  = Batch size
#   -np 4   = Parallel sequences
.\llama-server.exe -m "`$MODEL_PATH" --host 0.0.0.0 --port `$PORT -ngl 99 -c 8192 -b 512 --cont-batching -np 4
"@

$startupScriptPath = "$INSTALL_DIR\start-server.ps1"
$startupScript | Out-File -FilePath $startupScriptPath -Encoding UTF8

$batchScript = "@echo off`r`ncd /d $INSTALL_DIR`r`npowershell -ExecutionPolicy Bypass -File start-server.ps1"
$batchScriptPath = "$INSTALL_DIR\start-server.bat"
$batchScript | Out-File -FilePath $batchScriptPath -Encoding ASCII

Write-Host "  Created: $startupScriptPath" -ForegroundColor Green
Write-Host "  Created: $batchScriptPath" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Step 6: Create Scheduled Task
# ============================================================================

Write-Host "Step 6: Creating auto-start task..." -ForegroundColor Yellow

$taskName = "AegisLlamaServer"
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$startupScriptPath`"" `
    -WorkingDirectory $INSTALL_DIR

$trigger = New-ScheduledTaskTrigger -AtLogon -User $currentUser
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$principal = New-ScheduledTaskPrincipal -UserId $currentUser -LogonType Interactive -RunLevel Highest

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal | Out-Null

Write-Host "  Auto-start task created" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Step 7: Start Server Now
# ============================================================================

Write-Host "Step 7: Starting server..." -ForegroundColor Yellow

Start-Process -FilePath "powershell.exe" `
    -ArgumentList "-ExecutionPolicy Bypass -File `"$startupScriptPath`"" `
    -WorkingDirectory $INSTALL_DIR `
    -WindowStyle Minimized

Write-Host "  Server starting (wait 30s for model load)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

try {
    $health = Invoke-RestMethod -Uri "http://localhost:$PORT/health" -TimeoutSec 10
    Write-Host "  Server is running" -ForegroundColor Green
} catch {
    Write-Host "  Server may still be loading model" -ForegroundColor Yellow
}
Write-Host ""

# ============================================================================
# Complete
# ============================================================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Aegis Setup Complete" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "API Endpoint: http://aegis:$PORT"
Write-Host ""
Write-Host "Endpoints:"
Write-Host "  GET  /health"
Write-Host "  POST /completion"
Write-Host "  POST /v1/chat/completions (OpenAI compatible)"
Write-Host ""
Write-Host "Files:"
Write-Host "  Install: $INSTALL_DIR"
Write-Host "  Model: $modelPath"
Write-Host "  Start: $batchScriptPath"
Write-Host ""
Write-Host "Test from Nexus:" -ForegroundColor Yellow
Write-Host "   curl http://aegis:$PORT/health"
Write-Host ""
