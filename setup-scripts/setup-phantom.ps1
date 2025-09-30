# ============================================================================
# Zero-Trust Hybrid AI Pipeline
# Phantom (Windows 11) Setup Script
# ============================================================================
#
# This script runs on Phantom (Dell XPS Snapdragon with Windows 11).
# It configures SSH server, sets up authorized keys, and prepares the
# machine as a secondary orchestrator.
#
# Prerequisites:
#   - Windows 11 with PowerShell 5.1+
#   - Tailscale installed and connected (hostname: phantom)
#   - Administrator privileges
#
# Usage:
#   1. Open PowerShell as Administrator
#   2. Set-ExecutionPolicy Bypass -Scope Process
#   3. .\setup-phantom.ps1
#
# ============================================================================

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Phantom Setup Script" -ForegroundColor Cyan
Write-Host "Zero-Trust Hybrid AI Pipeline" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# Step 1: Install OpenSSH Server
# ============================================================================

Write-Host "Step 1: Installing OpenSSH Server..." -ForegroundColor Yellow

# Check if OpenSSH Server is already installed
$sshCapability = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'

if ($sshCapability.State -ne "Installed") {
    Write-Host "  Installing OpenSSH Server..."
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
    Write-Host "  OpenSSH Server installed" -ForegroundColor Green
} else {
    Write-Host "  OpenSSH Server already installed" -ForegroundColor Green
}

# ============================================================================
# Step 2: Configure SSH Service
# ============================================================================

Write-Host ""
Write-Host "Step 2: Configuring SSH service..." -ForegroundColor Yellow

# Set service to start automatically
Set-Service -Name sshd -StartupType Automatic

# Start the service
Start-Service sshd

# Verify service is running
$sshStatus = Get-Service sshd
if ($sshStatus.Status -eq "Running") {
    Write-Host "  SSH service is running" -ForegroundColor Green
} else {
    Write-Host "  ERROR: SSH service failed to start" -ForegroundColor Red
    exit 1
}

# ============================================================================
# Step 3: Configure SSH for Key Authentication
# ============================================================================

Write-Host ""
Write-Host "Step 3: Configuring SSH for key authentication..." -ForegroundColor Yellow

# Create sshd_config if it doesn't exist or update it
$sshdConfigPath = "$env:ProgramData\ssh\sshd_config"
$sshdConfigDir = "$env:ProgramData\ssh"

if (-not (Test-Path $sshdConfigDir)) {
    New-Item -ItemType Directory -Path $sshdConfigDir -Force | Out-Null
}

# Backup existing config
if (Test-Path $sshdConfigPath) {
    $backupPath = "$sshdConfigPath.backup.$(Get-Date -Format 'yyyyMMdd')"
    Copy-Item $sshdConfigPath $backupPath -Force
    Write-Host "  Backed up existing config to $backupPath"
}

# Write new configuration
$sshdConfig = @"
# Zero-Trust Hybrid AI Pipeline SSH Configuration

# Port and Protocol
Port 22
Protocol 2

# Authentication
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no

# For standard users, use .ssh/authorized_keys in their profile
AuthorizedKeysFile .ssh/authorized_keys

# For administrators, use the central administrators_authorized_keys file
# Comment out these lines if you want admins to use their own authorized_keys
Match Group administrators
    AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys

# Security
PermitRootLogin no
MaxAuthTries 3
MaxSessions 5
ClientAliveInterval 300
ClientAliveCountMax 2

# Logging
SyslogFacility LOCAL0
LogLevel INFO

# Subsystem for SFTP
Subsystem sftp sftp-server.exe
"@

$sshdConfig | Out-File -FilePath $sshdConfigPath -Encoding ASCII -Force
Write-Host "  SSH configuration written" -ForegroundColor Green

# ============================================================================
# Step 4: Setup SSH Keys Directory
# ============================================================================

Write-Host ""
Write-Host "Step 4: Setting up SSH keys directory..." -ForegroundColor Yellow

$currentUser = $env:USERNAME
$sshDir = "$env:USERPROFILE\.ssh"
$authorizedKeysPath = "$sshDir\authorized_keys"

# Create .ssh directory
if (-not (Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
    Write-Host "  Created $sshDir"
}

# Create authorized_keys file
if (-not (Test-Path $authorizedKeysPath)) {
    New-Item -ItemType File -Path $authorizedKeysPath -Force | Out-Null
    Write-Host "  Created $authorizedKeysPath"
}

# Set proper permissions on .ssh directory
$acl = Get-Acl $sshDir
$acl.SetAccessRuleProtection($true, $false)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $currentUser, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
)
$acl.SetAccessRule($rule)
Set-Acl $sshDir $acl
Write-Host "  Set permissions on .ssh directory"

# Set proper permissions on authorized_keys
$acl = Get-Acl $authorizedKeysPath
$acl.SetAccessRuleProtection($true, $false)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $currentUser, "FullControl", "None", "None", "Allow"
)
$acl.SetAccessRule($rule)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "SYSTEM", "FullControl", "None", "None", "Allow"
)
$acl.AddAccessRule($rule)
Set-Acl $authorizedKeysPath $acl
Write-Host "  Set permissions on authorized_keys"

# If user is an administrator, also set up administrators_authorized_keys
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    $adminAuthKeysPath = "$env:ProgramData\ssh\administrators_authorized_keys"
    
    if (-not (Test-Path $adminAuthKeysPath)) {
        New-Item -ItemType File -Path $adminAuthKeysPath -Force | Out-Null
    }
    
    # Set ACL for administrators_authorized_keys
    $acl = Get-Acl $adminAuthKeysPath
    $acl.SetAccessRuleProtection($true, $false)
    
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        "Administrators", "FullControl", "None", "None", "Allow"
    )
    $acl.SetAccessRule($rule)
    
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        "SYSTEM", "FullControl", "None", "None", "Allow"
    )
    $acl.AddAccessRule($rule)
    
    Set-Acl $adminAuthKeysPath $acl
    Write-Host "  Set up administrators_authorized_keys at $adminAuthKeysPath"
}

Write-Host "  SSH keys directory configured" -ForegroundColor Green

# ============================================================================
# Step 5: Configure Windows Firewall
# ============================================================================

Write-Host ""
Write-Host "Step 5: Configuring Windows Firewall..." -ForegroundColor Yellow

# Remove default OpenSSH rules that allow from anywhere
$existingRules = Get-NetFirewallRule -DisplayName "*OpenSSH*" -ErrorAction SilentlyContinue
if ($existingRules) {
    $existingRules | Remove-NetFirewallRule
    Write-Host "  Removed default OpenSSH firewall rules"
}

# Add rule for Tailscale network only (100.64.0.0/10)
$ruleName = "OpenSSH-Server-Tailscale"
$existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue

if (-not $existingRule) {
    New-NetFirewallRule -DisplayName $ruleName `
        -Direction Inbound `
        -Protocol TCP `
        -LocalPort 22 `
        -RemoteAddress "100.64.0.0/10" `
        -Action Allow `
        -Profile Any `
        -Description "Allow SSH from Tailscale network only"
    Write-Host "  Created firewall rule for Tailscale SSH" -ForegroundColor Green
} else {
    Write-Host "  Tailscale SSH firewall rule already exists" -ForegroundColor Green
}

# ============================================================================
# Step 6: Install Python (for orchestrator backup)
# ============================================================================

Write-Host ""
Write-Host "Step 6: Checking Python installation..." -ForegroundColor Yellow

$pythonInstalled = Get-Command python -ErrorAction SilentlyContinue

if (-not $pythonInstalled) {
    Write-Host "  Python not found. Please install Python 3.11+ manually from python.org"
    Write-Host "  Or use: winget install Python.Python.3.11"
} else {
    $pythonVersion = python --version
    Write-Host "  Python installed: $pythonVersion" -ForegroundColor Green
}

# ============================================================================
# Step 7: Restart SSH Service
# ============================================================================

Write-Host ""
Write-Host "Step 7: Restarting SSH service..." -ForegroundColor Yellow

Restart-Service sshd
Start-Sleep -Seconds 2

$sshStatus = Get-Service sshd
if ($sshStatus.Status -eq "Running") {
    Write-Host "  SSH service restarted successfully" -ForegroundColor Green
} else {
    Write-Host "  WARNING: SSH service may not have restarted properly" -ForegroundColor Red
}

# ============================================================================
# Step 8: Display Summary
# ============================================================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Phantom Setup Complete" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "SSH Configuration:"
Write-Host "  Config file: $sshdConfigPath"
Write-Host "  Authorized keys: $authorizedKeysPath"
if ($isAdmin) {
    Write-Host "  Admin keys: $adminAuthKeysPath"
}
Write-Host ""
Write-Host "Firewall:"
Write-Host "  SSH allowed from Tailscale (100.64.0.0/10) only"
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Get the public key from Nexus:"
Write-Host "   On Nexus, run: cat ~/.ssh/id_ed25519.pub"
Write-Host ""
Write-Host "2. Add the public key to authorized_keys:"
Write-Host "   Paste the key into: $authorizedKeysPath"

if ($isAdmin) {
    Write-Host "   AND into: $adminAuthKeysPath"
}

Write-Host ""
Write-Host "3. Test SSH from Nexus:"
Write-Host "   ssh phantom"
Write-Host ""
Write-Host "4. If connection fails, check:"
Write-Host "   - Tailscale is running: tailscale status"
Write-Host "   - SSH service: Get-Service sshd"
Write-Host "   - Firewall: Get-NetFirewallRule -DisplayName '*Tailscale*'"
Write-Host ""
