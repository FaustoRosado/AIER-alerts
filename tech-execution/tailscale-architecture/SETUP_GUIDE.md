# Tailscale Setup Guide for Students

This guide provides simple, step-by-step instructions for installing and configuring Tailscale on different operating systems. Perfect for cybersecurity apprentices and students learning about secure networking.

## Table of Contents

1. [Before You Start](#before-you-start)
2. [Linux/macOS Setup](#linuxmacos-setup)
3. [Windows Setup](#windows-setup)
4. [AWS EC2 Setup](#aws-ec2-setup)
5. [Verification Steps](#verification-steps)
6. [Common Issues](#common-issues)

## Before You Start

### What You Need

1. **Tailscale Account** (free)
   - Sign up at: https://login.tailscale.com/start
   - Use your personal or school email

2. **Auth Key** (for automated setup)
   - Log in to Tailscale admin console
   - Go to Settings > Keys
   - Click "Generate auth key"
   - Check "Reusable" and "Preauthorized"
   - Save the key (starts with `tskey-auth-`)

3. **Administrator/Root Access**
   - You need admin rights to install and configure Tailscale

### Understanding Elevated Privileges

**Why do we need elevated privileges?**
- Tailscale modifies network settings
- It installs system services
- It configures firewall rules
- It enables IP forwarding for routing

## Linux/macOS Setup

### Step 1: Download the Script

```bash
# Navigate to the scripts directory
cd tech-execution/tailscale-architecture/

# Make the script executable
chmod +x setup-tailscale.sh
```

### Step 2: Run with Elevated Privileges

**On Linux:**
```bash
# Run with sudo (you'll be prompted for your password)
sudo ./setup-tailscale.sh
```

**On macOS:**
```bash
# Run with sudo (you'll be prompted for your password)
sudo ./setup-tailscale.sh
```

**What is `sudo`?**
- `sudo` = "Super User DO"
- Temporarily grants administrator privileges
- Required for system-level changes
- You'll enter your login password (not root password)

### Step 3: Follow the Prompts

The script will ask you:

1. **Auth key**: Paste your Tailscale auth key
   ```
   tskey-auth-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

2. **Subnet routes**: Enter your network CIDR (if setting up subnet router)
   ```
   10.0.0.0/16
   ```
   - Leave blank if not setting up subnet routing

3. **Device tags**: Enter tags for access control
   ```
   tag:dev-laptop
   ```
   - Or: `tag:aws-subnet-router` for cloud infrastructure

### Manual Installation (if script fails)

```bash
# Ubuntu/Debian
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --authkey=YOUR_KEY

# macOS (using Homebrew)
brew install tailscale
sudo tailscale up --authkey=YOUR_KEY
```

## Windows Setup

### Step 1: Open PowerShell as Administrator

**Method 1 - Using Start Menu:**
1. Click Start menu
2. Type "PowerShell"
3. Right-click "Windows PowerShell"
4. Select "Run as Administrator"
5. Click "Yes" on the User Account Control prompt

**Method 2 - Using Windows Terminal:**
1. Open Windows Terminal
2. Click the down arrow (v) next to the + sign
3. Hold Ctrl and click "Windows PowerShell"
4. This opens PowerShell as Administrator

**Method 3 - Using Run Dialog:**
1. Press `Win + R`
2. Type: `powershell`
3. Press `Ctrl + Shift + Enter` (instead of just Enter)
4. Click "Yes" on the UAC prompt

### Step 2: Navigate to Script Directory

```powershell
# Change to the scripts directory
cd C:\path\to\capstone\data_viz\tech-execution\tailscale-architecture\
```

### Step 3: Enable Script Execution (First Time Only)

Windows blocks script execution by default for security.

```powershell
# Check current execution policy
Get-ExecutionPolicy

# If it shows "Restricted", change it temporarily
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process

# This change only affects the current PowerShell session
```

**What is Execution Policy?**
- Security feature to prevent malicious scripts
- `RemoteSigned` = Allow local scripts, verify downloaded scripts
- `Scope Process` = Only for this PowerShell window

### Step 4: Run the Setup Script

```powershell
# Run the script
.\setup-tailscale.ps1
```

### Step 5: Follow the Prompts

The script will ask you:

1. **Auth key**: Paste your Tailscale auth key
2. **Subnet routes**: Enter your network CIDR (if applicable)
3. **Device tags**: Enter tags for organization

### Manual Installation (if script fails)

1. Download Tailscale installer:
   - Visit: https://tailscale.com/download/windows
   - Download `tailscale-setup-latest.exe`

2. Run the installer:
   - Double-click the downloaded file
   - Follow installation wizard
   - Allow firewall access when prompted

3. Configure Tailscale:
   - Open Tailscale from Start Menu
   - Click "Log in"
   - Complete authentication in browser

## AWS EC2 Setup

For EC2 instances (Amazon Linux 2 or Ubuntu):

### Step 1: Connect to EC2 Instance

```bash
# Connect via SSH
ssh -i your-key.pem ec2-user@your-instance-ip

# Or use AWS Systems Manager Session Manager (no SSH key needed)
aws ssm start-session --target i-xxxxxxxxx
```

### Step 2: Run Setup Script

```bash
# Download the script (if not already present)
curl -O https://raw.githubusercontent.com/your-repo/setup-tailscale.sh

# Make executable
chmod +x setup-tailscale.sh

# Run with sudo
sudo ./setup-tailscale.sh
```

### Step 3: Configure for Subnet Routing

When prompted:
- **Auth key**: Use your reusable auth key
- **Subnet routes**: `10.0.0.0/16` (your VPC CIDR)
- **Device tags**: `tag:aws-subnet-router`

### Step 4: Disable Source/Destination Check

AWS requires this for subnet routing:

```bash
# Get instance ID
INSTANCE_ID=$(ec2-metadata --instance-id | cut -d' ' -f2)

# Disable source/dest check (run from your local machine with AWS CLI)
aws ec2 modify-instance-attribute \
  --instance-id $INSTANCE_ID \
  --no-source-dest-check
```

## Verification Steps

### Check Tailscale Status

**Linux/macOS:**
```bash
tailscale status
```

**Windows:**
```powershell
& "C:\Program Files\Tailscale\tailscale.exe" status
```

Expected output:
```
# 100.x.x.x    hostname.domain    user@   linux   active; relay "nyc"
```

### Check Your Tailscale IP

```bash
tailscale ip
```

Expected output:
```
100.x.x.x
fd7a:xxxx:xxxx::x
```

### Test Connectivity

From another Tailscale device:

```bash
# Ping your new device
ping 100.x.x.x

# SSH via Tailscale (if enabled)
ssh user@100.x.x.x
```

### Check Subnet Routes (if applicable)

```bash
# View advertised routes
tailscale status --json | grep -i routes

# Or use Tailscale admin console
# https://login.tailscale.com/admin/machines
```

## Common Issues

### Issue 1: "Permission Denied" Error

**Problem:** Script won't run without sudo/admin rights

**Solution:**
```bash
# Linux/macOS
sudo ./setup-tailscale.sh

# Windows: Run PowerShell as Administrator (see instructions above)
```

### Issue 2: "Command Not Found" After Installation

**Problem:** Tailscale commands not in PATH

**Solution:**
```bash
# Linux: Reload shell or logout/login
source ~/.bashrc

# Or specify full path
/usr/bin/tailscale status

# Windows: Restart PowerShell or use full path
& "C:\Program Files\Tailscale\tailscale.exe" status
```

### Issue 3: Can't Connect to Tailnet

**Problem:** Shows "Logged out" or connection fails

**Solution:**
```bash
# Manually authenticate
sudo tailscale up --authkey=YOUR_KEY

# Or login interactively
sudo tailscale up
# Then visit the URL shown in your browser
```

### Issue 4: Firewall Blocking Connection

**Problem:** Tailscale shows "relay" connection instead of direct

**Solution:**
```bash
# Linux (UFW)
sudo ufw allow 41641/udp

# Linux (firewalld)
sudo firewall-cmd --permanent --add-port=41641/udp
sudo firewall-cmd --reload

# Windows: Script should handle this, but verify:
# Open Windows Defender Firewall
# Check for "Tailscale" rule on UDP port 41641
```

### Issue 5: Subnet Routes Not Working

**Problem:** Can't reach devices in advertised subnet

**Solution:**

1. **Verify IP forwarding is enabled:**
   ```bash
   # Linux
   cat /proc/sys/net/ipv4/ip_forward
   # Should show: 1
   
   # If not, enable it:
   sudo sysctl -w net.ipv4.ip_forward=1
   ```

2. **Check EC2 source/dest check is disabled:**
   ```bash
   aws ec2 describe-instance-attribute \
     --instance-id i-xxxxxxxxx \
     --attribute sourceDestCheck
   ```

3. **Approve routes in Tailscale admin console:**
   - Go to https://login.tailscale.com/admin/machines
   - Find your subnet router device
   - Click "Review" next to "Subnets"
   - Click "Approve" for the advertised routes

### Issue 6: PowerShell Script Won't Run

**Problem:** "Execution Policy" error in Windows

**Solution:**
```powershell
# Check current policy
Get-ExecutionPolicy

# Allow scripts for current session only
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process

# Then run the script again
.\setup-tailscale.ps1
```

## Best Practices for Students

1. **Use Tags**: Organize devices with meaningful tags
   - `tag:laptop-john` for personal devices
   - `tag:aws-prod` for production infrastructure
   - `tag:dev-env` for development systems

2. **Rotate Auth Keys**: Generate new keys every 6-12 months
   - Delete old keys from admin console
   - Update automated scripts with new keys

3. **Monitor Connections**: Regularly check Tailscale admin console
   - Review connected devices
   - Remove devices you no longer use
   - Check for suspicious connections

4. **Document Your Setup**: Keep notes on:
   - Which devices have Tailscale installed
   - What subnet routes each router advertises
   - Your tagging scheme and ACL rules

5. **Test Connectivity**: After setup, always verify:
   - Ping test between devices
   - Application connectivity (SSH, HTTP, etc.)
   - Subnet routing (if applicable)

## Security Reminders

1. **Protect Your Auth Keys**
   - Never commit auth keys to Git repositories
   - Store in password manager or secrets vault
   - Use environment variables in scripts

2. **Use Strong Authentication**
   - Enable 2FA on your Tailscale account
   - Use SSO if available through your school

3. **Apply Principle of Least Privilege**
   - Use ACLs to restrict access between devices
   - Only advertise necessary subnet routes
   - Regularly review and update permissions

4. **Keep Software Updated**
   - Update Tailscale client regularly
   - Apply OS security patches
   - Monitor Tailscale security advisories

## Additional Resources

- **Tailscale Documentation**: https://tailscale.com/kb/
- **Tailscale GitHub**: https://github.com/tailscale
- **Community Forum**: https://forum.tailscale.com/
- **Quick Start Guide**: https://tailscale.com/kb/1017/install/

## Getting Help

If you encounter issues:

1. **Check Tailscale logs:**
   ```bash
   # Linux
   sudo journalctl -u tailscaled -n 50
   
   # Windows
   Get-EventLog -LogName Application -Source Tailscale
   ```

2. **Run network check:**
   ```bash
   tailscale netcheck
   ```

3. **Contact your instructor or DevSecOps team**

4. **Consult Tailscale support** (for technical issues):
   - https://tailscale.com/contact/support

## Summary

You've learned:
- How to run scripts with elevated privileges
- Installing Tailscale on Linux, macOS, and Windows
- Configuring subnet routing for hybrid deployments
- Verifying your Tailscale setup
- Troubleshooting common issues

Practice these skills in your lab environment before applying to production systems!

