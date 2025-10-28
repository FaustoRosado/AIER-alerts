# Tailscale Setup Script for Windows
# Purpose: Install and configure Tailscale with subnet routing capabilities
# Usage: Run PowerShell as Administrator, then: .\setup-tailscale.ps1

#Requires -RunAsAdministrator

# Set error action preference
$ErrorActionPreference = "Stop"

# Function to print colored messages
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Error-Custom "This script must be run as Administrator"
    Write-Host ""
    Write-Host "To run as Administrator:"
    Write-Host "  1. Right-click PowerShell"
    Write-Host "  2. Select 'Run as Administrator'"
    Write-Host "  3. Navigate to script directory"
    Write-Host "  4. Run: .\setup-tailscale.ps1"
    exit 1
}

Write-Info "Starting Tailscale installation and configuration"

# Check if Tailscale is already installed
function Test-TailscaleInstalled {
    $tailscalePath = "C:\Program Files\Tailscale\tailscale.exe"
    return Test-Path $tailscalePath
}

# Install Tailscale
function Install-Tailscale {
    if (Test-TailscaleInstalled) {
        Write-Info "Tailscale is already installed"
        return
    }
    
    Write-Info "Downloading Tailscale installer..."
    
    $installerUrl = "https://pkgs.tailscale.com/stable/tailscale-setup-latest.exe"
    $installerPath = "$env:TEMP\tailscale-setup.exe"
    
    try {
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath
        Write-Info "Downloaded Tailscale installer"
        
        Write-Info "Installing Tailscale (this may take a minute)..."
        Start-Process -FilePath $installerPath -Args "/silent" -Wait
        
        Write-Info "Tailscale installed successfully"
        
        # Cleanup
        Remove-Item $installerPath -Force
    }
    catch {
        Write-Error-Custom "Failed to download or install Tailscale: $_"
        exit 1
    }
}

# Enable IP forwarding
function Enable-IPForwarding {
    Write-Info "Enabling IP forwarding for subnet routing..."
    
    try {
        # Enable IPv4 forwarding
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" `
                        -Name "IPEnableRouter" `
                        -Value 1
        
        Write-Info "IP forwarding enabled (reboot may be required for full effect)"
    }
    catch {
        Write-Warning-Custom "Could not enable IP forwarding: $_"
    }
}

# Configure Windows Firewall
function Configure-Firewall {
    Write-Info "Configuring Windows Firewall for Tailscale..."
    
    try {
        $ruleName = "Tailscale"
        $existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
        
        if ($null -eq $existingRule) {
            New-NetFirewallRule -DisplayName $ruleName `
                               -Direction Inbound `
                               -Protocol UDP `
                               -LocalPort 41641 `
                               -Action Allow `
                               -Profile Any `
                               -Description "Tailscale VPN"
            
            Write-Info "Firewall rule created for Tailscale"
        }
        else {
            Write-Info "Firewall rule already exists for Tailscale"
        }
    }
    catch {
        Write-Warning-Custom "Could not configure firewall: $_"
    }
}

# Configure Tailscale
function Configure-Tailscale {
    Write-Info "Tailscale configuration options:"
    Write-Host ""
    Write-Host "You will need:"
    Write-Host "  1. Tailscale auth key (from https://login.tailscale.com/admin/settings/keys)"
    Write-Host "  2. Subnet routes to advertise (e.g., 10.0.0.0/16)"
    Write-Host "  3. Device tags (e.g., tag:aws-subnet-router)"
    Write-Host ""
    
    $authKey = Read-Host "Enter Tailscale auth key"
    $subnetRoutes = Read-Host "Enter subnet routes to advertise (comma-separated)"
    $deviceTags = Read-Host "Enter device tags (comma-separated)"
    
    Write-Info "Starting Tailscale with configuration..."
    
    $tailscaleExe = "C:\Program Files\Tailscale\tailscale.exe"
    
    $args = @(
        "up"
        "--authkey=$authKey"
        "--advertise-routes=$subnetRoutes"
        "--advertise-tags=$deviceTags"
        "--accept-dns=false"
    )
    
    try {
        & $tailscaleExe $args
        Write-Info "Tailscale started successfully"
    }
    catch {
        Write-Error-Custom "Failed to start Tailscale: $_"
        exit 1
    }
}

# Verify installation
function Test-TailscaleStatus {
    Write-Info "Verifying Tailscale installation..."
    
    $tailscaleExe = "C:\Program Files\Tailscale\tailscale.exe"
    
    try {
        $status = & $tailscaleExe status
        Write-Info "Tailscale is running"
        Write-Host ""
        Write-Host $status
    }
    catch {
        Write-Error-Custom "Tailscale is not running properly: $_"
        exit 1
    }
}

# Check if Tailscale service is running
function Test-TailscaleService {
    $service = Get-Service -Name "Tailscale" -ErrorAction SilentlyContinue
    
    if ($null -eq $service) {
        return $false
    }
    
    return $service.Status -eq "Running"
}

# Main execution
function Main {
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host "  Tailscale Setup for Windows" -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host ""
    
    Install-Tailscale
    Enable-IPForwarding
    Configure-Firewall
    
    Write-Host ""
    $configure = Read-Host "Do you want to configure Tailscale now? (y/n)"
    
    if ($configure -eq "y" -or $configure -eq "Y") {
        Configure-Tailscale
        Test-TailscaleStatus
    }
    else {
        Write-Info "Skipping configuration. Run Tailscale from Start Menu to configure later"
    }
    
    Write-Host ""
    Write-Info "Setup complete!"
    Write-Info "Next steps:"
    Write-Host "  1. If you haven't configured yet, open Tailscale from Start Menu"
    Write-Host "  2. Verify connection: tailscale status"
    Write-Host "  3. Check IP: tailscale ip"
    Write-Host ""
    Write-Warning-Custom "Note: A system reboot may be required for IP forwarding to take full effect"
}

# Run main function
Main


