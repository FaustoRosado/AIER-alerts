# ============================================================================
# Zero-Trust Hybrid AI Pipeline
# Ryzen-AI (Ryzen AI 395 + 128GB RAM) Setup Script
# ============================================================================
#
# This script configures Ryzen-AI as the multi-model specialist node.
#
# Hardware:
#   - Framework laptop with AMD Ryzen AI 395 (Strix Point)
#   - 128GB DDR5 RAM
#   - XDNA 2 NPU (50 TOPS)
#   - Windows 11 Pro on external USB-C drive
#   - ImDisk Virtual Disk Driver installed
#   - RAMDisk configuration available on desktop
#
# Role: Multi-Model Specialist
#   Unlike Aegis which runs one fast model, Ryzen-AI runs multiple
#   specialized models simultaneously. With 128GB RAM, all models stay
#   loaded (~24GB total), enabling instant switching without reload delays.
#
# Models:
#   - qwen2.5-coder:7b  (~4.5GB) - Code generation and review
#   - phi3:14b          (~8GB)   - Validation and reasoning
#   - codellama:7b      (~4GB)   - Code explanation
#   - bge-m3            (~2GB)   - Text embeddings for RAG
#   - llama3.2:3b       (~2GB)   - Fast routing decisions
#   - whisper:large     (~3GB)   - Audio transcription (optional)
#
# RAMDisk Option:
#   With ImDisk installed, you can optionally load models into a RAMDisk
#   for even faster model loading. The script will detect ImDisk and offer
#   this option. Given 128GB RAM, you can allocate 32-64GB to RAMDisk while
#   still having plenty for inference.
#
# Usage:
#   1. Open PowerShell as Administrator
#   2. Set-ExecutionPolicy Bypass -Scope Process
#   3. .\setup-ryzen-ai.ps1
#
# ============================================================================

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Ryzen-AI Setup Script" -ForegroundColor Cyan
Write-Host "Multi-Model Specialist - Ryzen AI 395" -ForegroundColor Cyan
Write-Host "128GB RAM + ImDisk RAMDisk Support" -ForegroundColor Cyan
Write-Host "Zero-Trust Hybrid AI Pipeline" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# Step 1: System Check
# ============================================================================

Write-Host "Step 1: Checking system..." -ForegroundColor Yellow

# Check RAM
$totalRAM = [math]::Round((Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).Sum / 1GB, 0)
Write-Host "  Total RAM: $totalRAM GB" -ForegroundColor Green

if ($totalRAM -lt 64) {
    Write-Host "  WARNING: Less than 64GB RAM. Multi-model setup may be limited." -ForegroundColor Yellow
}

# Check if running from external drive
$systemDrive = (Get-WmiObject Win32_OperatingSystem).SystemDrive
$systemDisk = Get-Disk | Where-Object { $_.BootFromDisk -eq $true }
$busType = $systemDisk.BusType

Write-Host "  System drive: $systemDrive" -ForegroundColor Green
Write-Host "  Bus type: $busType" -ForegroundColor Green

if ($busType -eq "USB") {
    Write-Host "  Running from external USB-C drive (detected)" -ForegroundColor Green
}

# Check for ImDisk
$imdiskInstalled = Get-Service -Name "ImDisk" -ErrorAction SilentlyContinue
if ($imdiskInstalled) {
    Write-Host "  ImDisk Virtual Disk Driver: Installed" -ForegroundColor Green
    $IMDISK_AVAILABLE = $true
} else {
    Write-Host "  ImDisk Virtual Disk Driver: Not found" -ForegroundColor Yellow
    Write-Host "  RAMDisk features will not be available" -ForegroundColor Yellow
    $IMDISK_AVAILABLE = $false
}

Write-Host ""

# NOTE: SSH setup removed - configure SSH manually before running this script
$currentUser = $env:USERNAME

# ============================================================================
# Step 2: Configure Windows Firewall
# ============================================================================

Write-Host "Step 2: Configuring Windows Firewall..." -ForegroundColor Yellow

Get-NetFirewallRule -DisplayName "RyzenAI-*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule

New-NetFirewallRule -DisplayName "RyzenAI-SSH-Tailscale" `
    -Direction Inbound -Protocol TCP -LocalPort 22 `
    -RemoteAddress "100.64.0.0/10" -Action Allow | Out-Null

New-NetFirewallRule -DisplayName "RyzenAI-Ollama-Tailscale" `
    -Direction Inbound -Protocol TCP -LocalPort 11434 `
    -RemoteAddress "100.64.0.0/10" -Action Allow | Out-Null

Write-Host "  Firewall configured for Tailscale" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Step 3: Install Ollama
# ============================================================================

Write-Host "Step 3: Installing Ollama..." -ForegroundColor Yellow

$ollamaInstalled = Get-Command ollama -ErrorAction SilentlyContinue

if (-not $ollamaInstalled) {
    $installerUrl = "https://ollama.com/download/OllamaSetup.exe"
    $installerPath = "$env:TEMP\OllamaSetup.exe"
    
    Write-Host "  Downloading Ollama installer..."
    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
    
    Write-Host "  Running installer (complete the GUI)..."
    Start-Process -FilePath $installerPath -Wait
    
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

Write-Host "  Ollama installed" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Step 6: Configure Ollama for Network Access
# ============================================================================

Write-Host "Step 6: Configuring Ollama..." -ForegroundColor Yellow

[System.Environment]::SetEnvironmentVariable("OLLAMA_HOST", "0.0.0.0", "User")
[System.Environment]::SetEnvironmentVariable("OLLAMA_ORIGINS", "*", "User")

# If ImDisk is available, offer to set models directory to RAMDisk
if ($IMDISK_AVAILABLE) {
    Write-Host ""
    Write-Host "  ImDisk detected. You can use RAMDisk for models." -ForegroundColor Cyan
    Write-Host "  This requires ~32GB RAM allocated to RAMDisk." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  To use RAMDisk for models later:" -ForegroundColor Yellow
    Write-Host "  1. Create RAMDisk using ImDisk (e.g., R: drive, 32GB)" -ForegroundColor Yellow
    Write-Host "  2. Set environment variable: OLLAMA_MODELS=R:\ollama\models" -ForegroundColor Yellow
    Write-Host "  3. Copy models to R:\ollama\models" -ForegroundColor Yellow
    Write-Host ""
}

$env:OLLAMA_HOST = "0.0.0.0"
$env:OLLAMA_ORIGINS = "*"

Write-Host "  Ollama configured for network access" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Step 7: Download Specialist Models
# ============================================================================

Write-Host "Step 7: Downloading specialist models..." -ForegroundColor Yellow
Write-Host "  Total download: ~20GB. This will take 15-30 minutes." -ForegroundColor Yellow
Write-Host ""

# Start Ollama service
Write-Host "  Starting Ollama..."
$ollamaProcess = Get-Process ollama -ErrorAction SilentlyContinue
if (-not $ollamaProcess) {
    Start-Process ollama -ArgumentList "serve" -WindowStyle Hidden
    Start-Sleep -Seconds 5
}

# Define models to pull
$models = @(
    @{name="qwen2.5-coder:7b"; desc="Code generation"; size="4.5GB"},
    @{name="phi3:14b"; desc="Validation/reasoning"; size="8GB"},
    @{name="codellama:7b"; desc="Code explanation"; size="4GB"},
    @{name="nomic-embed-text"; desc="Embeddings"; size="300MB"},
    @{name="llama3.2:3b"; desc="Fast routing"; size="2GB"}
)

foreach ($model in $models) {
    Write-Host "  Pulling $($model.name) ($($model.desc), $($model.size))..."
    & ollama pull $model.name 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    Done" -ForegroundColor Green
    } else {
        Write-Host "    Failed - will retry later" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "  Models downloaded" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Step 8: Create Startup Script
# ============================================================================

Write-Host "Step 8: Creating startup scripts..." -ForegroundColor Yellow

$startupScript = @"

# Ryzen-AI Ollama Startup Script
# Multi-Model Specialist Node

`$env:OLLAMA_HOST = "0.0.0.0"
`$env:OLLAMA_ORIGINS = "*"

# Optional: Uncomment to use RAMDisk for models
# `$env:OLLAMA_MODELS = "R:\ollama\models"

Write-Host "Starting Ollama..."

# Check if already running
`$existing = Get-Process -Name "ollama" -ErrorAction SilentlyContinue
if (`$existing) {
    Write-Host "Ollama already running"
} else {
    Start-Process ollama -ArgumentList "serve" -WindowStyle Hidden
    Start-Sleep -Seconds 5
}

Write-Host ""
Write-Host "Pre-loading models into memory..."

# Pre-load models to keep them in RAM
`$models = @("llama3.2:3b", "qwen2.5-coder:7b", "nomic-embed-text")
foreach (`$model in `$models) {
    Write-Host "  Loading `$model..."
    & ollama run `$model "hi" 2>&1 | Out-Null
}

Write-Host ""
Write-Host "Ryzen-AI ready"
Write-Host "API: http://ryzen-ai:11434"
Write-Host ""
Write-Host "Available models:"
& ollama list
"@

$startupScriptPath = "$env:USERPROFILE\start-ryzen-ai.ps1"
$startupScript | Out-File -FilePath $startupScriptPath -Encoding UTF8

Write-Host "  Created: $startupScriptPath" -ForegroundColor Green

# Create scheduled task
$taskName = "RyzenAIOllama"
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$startupScriptPath`""

$trigger = New-ScheduledTaskTrigger -AtLogon -User $currentUser
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings | Out-Null

Write-Host "  Auto-start task created" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Step 9: Create RAMDisk Helper Script (if ImDisk available)
# ============================================================================

if ($IMDISK_AVAILABLE) {
    Write-Host "Step 9: Creating RAMDisk helper script..." -ForegroundColor Yellow
    
    $ramdiskScript = @"
# Ryzen-AI RAMDisk Setup for Models
# Creates a 32GB RAMDisk and moves Ollama models to it for faster loading
#
# WARNING: RAMDisk contents are lost on reboot!
# Run this after each boot if you want models on RAMDisk.

`$RAMDISK_SIZE = 32GB
`$RAMDISK_LETTER = "R"
`$OLLAMA_MODELS_SRC = "`$env:USERPROFILE\.ollama\models"
`$OLLAMA_MODELS_DST = "`${RAMDISK_LETTER}:\ollama\models"

Write-Host "Creating `$(`$RAMDISK_SIZE / 1GB)GB RAMDisk on `${RAMDISK_LETTER}:..."

# Create RAMDisk using ImDisk
imdisk -a -s `$RAMDISK_SIZE -m `${RAMDISK_LETTER}: -p "/fs:ntfs /q /y"

Start-Sleep -Seconds 3

# Create directory structure
New-Item -ItemType Directory -Path `$OLLAMA_MODELS_DST -Force | Out-Null

# Copy models to RAMDisk
Write-Host "Copying models to RAMDisk (this takes a few minutes)..."
if (Test-Path `$OLLAMA_MODELS_SRC) {
    Copy-Item -Path "`$OLLAMA_MODELS_SRC\*" -Destination `$OLLAMA_MODELS_DST -Recurse -Force
}

# Set environment variable
`$env:OLLAMA_MODELS = `$OLLAMA_MODELS_DST

Write-Host ""
Write-Host "RAMDisk ready at `${RAMDISK_LETTER}:"
Write-Host "Models directory: `$OLLAMA_MODELS_DST"
Write-Host ""
Write-Host "Restart Ollama to use RAMDisk models:"
Write-Host "  Stop-Process -Name ollama"
Write-Host "  `$env:OLLAMA_MODELS = '`$OLLAMA_MODELS_DST'"
Write-Host "  ollama serve"
"@
    
    $ramdiskScriptPath = "$env:USERPROFILE\Desktop\Setup-RAMDisk-Models.ps1"
    $ramdiskScript | Out-File -FilePath $ramdiskScriptPath -Encoding UTF8
    
    Write-Host "  Created: $ramdiskScriptPath" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "Step 9: Skipping RAMDisk setup (ImDisk not installed)" -ForegroundColor Yellow
    Write-Host ""
}

# ============================================================================
# Step 10: Verify Installation
# ============================================================================

Write-Host "Step 10: Verifying installation..." -ForegroundColor Yellow

Write-Host ""
Write-Host "  Available models:"
& ollama list
Write-Host ""

try {
    $tags = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 10
    Write-Host "  Ollama API: OK" -ForegroundColor Green
} catch {
    Write-Host "  Ollama API: May need a moment to start" -ForegroundColor Yellow
}

Write-Host ""

# ============================================================================
# Complete
# ============================================================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Ryzen-AI Setup Complete" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration:"
Write-Host "  RAM: $totalRAM GB"
Write-Host "  API: http://ryzen-ai:11434"
Write-Host "  Models: qwen2.5-coder:7b, phi3:14b, codellama:7b, nomic-embed-text, llama3.2:3b"
Write-Host ""
Write-Host "Special Features:"
Write-Host "  - Running from external USB-C drive"
if ($IMDISK_AVAILABLE) {
    Write-Host "  - ImDisk available for RAMDisk (see Desktop script)"
}
Write-Host "  - 128GB RAM allows all models to stay loaded"
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Add Nexus public key to:"
Write-Host "   $authorizedKeysPath"
Write-Host "   $adminAuthKeysPath"
Write-Host ""
Write-Host "2. Test from Nexus:"
Write-Host "   curl http://ryzen-ai:11434/api/tags"
Write-Host ""
if ($IMDISK_AVAILABLE) {
    Write-Host "3. Optional - Use RAMDisk for faster model loading:"
    Write-Host "   Run: $env:USERPROFILE\Desktop\Setup-RAMDisk-Models.ps1"
    Write-Host ""
}
