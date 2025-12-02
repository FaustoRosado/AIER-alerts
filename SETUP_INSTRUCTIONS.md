# Zero-Trust Hybrid AI Pipeline
# Complete Setup Instructions

This document provides step-by-step instructions for setting up the entire distributed AI system. Read through the entire document before starting.

## Machine Overview

You have five compute environments to configure:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                                                                          │
│   NEXUS (Mac Mini M4 Pro)                                               │
│   ├── Role: Command Center, SSH Key Origin                              │
│   ├── Tailscale hostname: nexus                                         │
│   ├── Runs: Claude Code Desktop, Orchestrator                           │
│   │                                                                      │
│   └── KALI-NEXUS (Kali Linux VM inside Nexus)                          │
│       ├── Role: Security Scanning Agent                                 │
│       ├── Tailscale hostname: kali-nexus                                │
│       └── Runs: Security API, Scanning Tools                            │
│                                                                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   PHANTOM (Dell XPS Snapdragon)                                         │
│   ├── Role: Mobile Command Center                                       │
│   ├── Tailscale hostname: phantom                                       │
│   └── Runs: Backup Orchestrator                                         │
│                                                                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   AEGIS (RTX 4080 Super Desktop)                                        │
│   ├── Role: Primary Inference Node                                      │
│   ├── OS: Windows 11 Pro                                                │
│   ├── Tailscale hostname: aegis                                         │
│   ├── Note: Game Ready drivers include CUDA runtime                     │
│   └── Runs: Ollama with Llama 3.1 8B (70-90 tok/s)                     │
│                                                                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   RYZEN-AI (Framework Ryzen AI 395)                                   │
│   ├── Role: Multi-Model Specialist                                      │
│   ├── Tailscale hostname: ryzen-ai                                    │
│   └── Runs: Ollama with 6 specialist models                             │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Prerequisites

Before starting, verify Tailscale is installed and running on all machines. Each machine must have these exact hostnames in Tailscale:

- nexus
- kali-nexus
- phantom
- aegis
- ryzen-ai

Verify by running on any machine:

```
tailscale status
```

You should see all five machines listed.

---

## Part 1: Nexus Setup (Mac Mini M4 Pro)

This is your command center. All SSH keys originate from here.

### 1.1 Open Terminal on Nexus

### 1.2 Create Project Directory

```bash
mkdir -p ~/Projects
cd ~/Projects
```

### 1.3 Clone or Extract the Project

If you have the zip file:

```bash
unzip ~/Downloads/zero-trust-hybrid-ai.zip
cd zero-trust-hybrid-ai
```

If you pushed to GitHub:

```bash
git clone https://github.com/YOUR-USERNAME/zero-trust-hybrid-ai.git
cd zero-trust-hybrid-ai
```

### 1.4 Generate SSH Keys

```bash
ssh-keygen -t ed25519 -C "nexus@zero-trust-ai" -N "" -f ~/.ssh/id_ed25519
```

If you already have a key, skip this step.

### 1.5 View Your Public Key

```bash
cat ~/.ssh/id_ed25519.pub
```

Copy this entire line. You will paste it into each remote machine. It looks like:

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... nexus@zero-trust-ai
```

### 1.6 Create SSH Config

Create the file `~/.ssh/config` with this content (replace usernames):

```
Host kali-nexus
    HostName kali-nexus
    User kali-nexus
    IdentityFile ~/.ssh/id_ed25519

Host phantom
    HostName phantom
    User YOUR_PHANTOM_USERNAME
    IdentityFile ~/.ssh/id_ed25519

Host aegis
    HostName aegis
    User YOUR_AEGIS_USERNAME
    IdentityFile ~/.ssh/id_ed25519

Host ryzen-ai
    HostName ryzen-ai
    User YOUR_RYZENAI_USERNAME
    IdentityFile ~/.ssh/id_ed25519
```

### 1.7 Install Python Dependencies

```bash
cd ~/Projects/zero-trust-hybrid-ai/orchestrator
pip3 install -r requirements.txt
```

---

## Part 2: Kali-Nexus Setup (Kali Linux VM)

### 2.1 Open the Kali VM

Use Parallels, UTM, or whatever virtualization you use.

### 2.2 Verify Tailscale

Inside the Kali VM:

```bash
tailscale status
```

If Tailscale is not installed:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --hostname=kali-nexus
```

### 2.3 Copy the Setup Script

From Nexus terminal:

```bash
scp ~/Projects/zero-trust-hybrid-ai/setup-scripts/setup-kali-nexus.sh kali-nexus:~/
```

If this fails because SSH is not yet configured, use shared folders or manually copy the script.

### 2.4 Run the Setup Script on Kali

Inside the Kali VM:

```bash
chmod +x ~/setup-kali-nexus.sh
sudo ~/setup-kali-nexus.sh
```

This script installs SSH server, security tools, configures firewall, and creates the Security API service.

### 2.5 Add the Nexus Public Key

Still inside Kali:

```bash
echo 'YOUR_PUBLIC_KEY_HERE' >> ~/.ssh/authorized_keys
```

Replace YOUR_PUBLIC_KEY_HERE with the actual key from step 1.5.

### 2.6 Verify from Nexus

Back on Nexus terminal:

```bash
ssh kali-nexus "echo 'Connection successful'"
```

### 2.7 Verify Security API

```bash
curl http://kali-nexus:8080/health
curl http://kali-nexus:8080/tools
```

---

## Part 3: Phantom Setup (Dell XPS Windows 11)

### 3.1 Copy the Script to Phantom

Use USB drive, OneDrive, or email to copy this file to Phantom:

```
~/Projects/zero-trust-hybrid-ai/setup-scripts/setup-phantom.ps1
```

### 3.2 Open PowerShell as Administrator on Phantom

Right-click PowerShell and select "Run as Administrator".

### 3.3 Run the Setup Script

```powershell
Set-ExecutionPolicy Bypass -Scope Process
cd C:\path\to\script
.\setup-phantom.ps1
```

### 3.4 Add the Nexus Public Key

Open Notepad as Administrator and edit:

```
%USERPROFILE%\.ssh\authorized_keys
```

Paste the public key from step 1.5. Save the file.

If your user is an administrator, also add the key to:

```
C:\ProgramData\ssh\administrators_authorized_keys
```

### 3.5 Verify from Nexus

On Nexus:

```bash
ssh phantom "echo 'Connection successful'"
```

---

## Part 4: Aegis Setup (Windows 11 Pro + RTX 4080)

Aegis runs Windows 11 Pro with an RTX 4080 Super. The Game Ready drivers you have installed for Steam already include the CUDA runtime. We use llama.cpp for maximum performance.

### 4.1 Copy the Script to Aegis

Use USB drive, OneDrive, or email to copy:

```
~/Projects/zero-trust-hybrid-ai/inference-nodes/aegis/setup-aegis.ps1
```

### 4.2 Open PowerShell as Administrator on Aegis

Right-click PowerShell and select "Run as Administrator".

### 4.3 Run the Setup Script

```powershell
Set-ExecutionPolicy Bypass -Scope Process
cd C:\path\to\script
.\setup-aegis.ps1
```

This script:
- Verifies NVIDIA GPU and CUDA runtime
- Enables OpenSSH Server
- Downloads llama.cpp pre-built CUDA binaries
- Downloads Llama 3.1 8B Q4_K_M model (~4.9GB)
- Creates startup task for auto-launch
- Configures firewall for Tailscale only

### 4.4 Add the Nexus Public Key

Same process as other Windows machines. Edit:

```
%USERPROFILE%\.ssh\authorized_keys
```

If your user is an administrator, also add to:

```
C:\ProgramData\ssh\administrators_authorized_keys
```

### 4.5 Verify from Nexus

```bash
ssh aegis "echo 'Connection successful'"
curl http://aegis:8080/health
```

---

## Part 5: Ryzen-AI Setup (Windows 11 Pro on USB-C + Ryzen AI)

Ryzen-AI runs Windows 11 Pro from an external USB-C drive with 128GB RAM and ImDisk Virtual Disk Driver for optional RAMDisk support.

### 5.1 Copy the Script to Ryzen-AI

Use USB drive, OneDrive, or email to copy:

```
~/Projects/zero-trust-hybrid-ai/inference-nodes/ryzen-ai/setup-ryzen-ai.ps1
```

### 5.2 Open PowerShell as Administrator on Ryzen-AI

### 5.3 Run the Setup Script

```powershell
Set-ExecutionPolicy Bypass -Scope Process
cd C:\path\to\script
.\setup-ryzen-ai.ps1
```

This script:
- Detects external USB-C drive boot
- Detects ImDisk for optional RAMDisk
- Enables OpenSSH Server
- Installs Ollama
- Downloads 5 specialist models (~20GB total)
- Creates startup task
- Creates RAMDisk helper script on Desktop (if ImDisk available)

### 5.4 Add the Nexus Public Key

Same process as other Windows machines. Edit:

```
%USERPROFILE%\.ssh\authorized_keys
```

Paste the public key.

### 5.5 Optional: RAMDisk for Models

With 128GB RAM and ImDisk installed, a script will be created on your Desktop to enable RAMDisk for faster model loading:

```powershell
.\Desktop\Setup-RAMDisk-Models.ps1
```

This allocates 32GB to a RAMDisk and copies models there. Run after each boot (RAMDisk contents lost on reboot).

### 5.6 Verify from Nexus

```bash
ssh ryzen-ai "echo 'Connection successful'"
curl http://ryzen-ai:11434/api/tags
```

---

## Part 6: Start the Orchestrator

Back on Nexus:

### 6.1 Create Environment File

```bash
cd ~/Projects/zero-trust-hybrid-ai/orchestrator
cat > .env << EOF
AEGIS_URL=http://aegis:8080
RYZEN_AI_URL=http://ryzen-ai:11434
KALI_URL=http://kali-nexus:8080
EOF
```

### 6.2 Start the Orchestrator

```bash
python3 main.py
```

### 6.3 Verify Everything Works

In a new terminal:

```bash
# Check backends
curl http://localhost:8000/backends

# Send a test request
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Hello, what can you do?"}]}'
```

---

## Part 7: System Health Check

Run the health check script:

```bash
~/Projects/zero-trust-hybrid-ai/scripts/check-all-systems.sh
```

Expected output:

```
Zero-Trust Hybrid AI Pipeline - System Status
==============================================

Tailscale Connectivity:
  ✓ kali-nexus - reachable
  ✓ phantom - reachable
  ✓ aegis - reachable
  ✓ ryzen-ai - reachable

SSH Connectivity:
  ✓ kali-nexus - SSH working
  ✓ phantom - SSH working
  ✓ aegis - SSH working
  ✓ ryzen-ai - SSH working

Inference Services:
  Aegis (llama-server): ✓ running
  Ryzen-AI (Ollama): ✓ running
  Kali-Nexus (Security API): ✓ running

Local Orchestrator:
  Orchestrator API: ✓ running
```

---

## Part 8: Using Claude Code Desktop

Now you can use Claude Code Desktop on Nexus to manage the entire system.

### 8.1 Open Claude Code Desktop

### 8.2 Point It at the Project

Open the folder:

```
~/Projects/zero-trust-hybrid-ai
```

### 8.3 Load the Prompt

Copy the contents of `CLAUDE_CODE_PROMPT.md` into Claude Code.

Or simply tell Claude Code:

"Read the file CLAUDE_CODE_PROMPT.md and follow the instructions."

### 8.4 What Claude Code Can Do

With SSH configured, Claude Code on Nexus can:

- SSH into any remote machine and run commands
- Deploy updates to inference nodes
- Trigger security scans on Kali-Nexus
- Monitor system health
- Debug issues across the mesh
- Update configurations
- View logs from any machine

---

## Troubleshooting

### SSH Connection Refused

The SSH service is not running or the firewall is blocking.

On Linux:
```bash
sudo systemctl status ssh
sudo ufw status
```

On Windows:
```powershell
Get-Service sshd
Get-NetFirewallRule -DisplayName "*SSH*"
```

### Permission Denied (publickey)

The public key is not in authorized_keys or permissions are wrong.

On Linux:
```bash
ls -la ~/.ssh/
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

On Windows:
Check that the key is in the correct file and that the file permissions are set correctly (use icacls).

### Tailscale Host Not Found

MagicDNS might not be enabled or the hostname is wrong.

Check Tailscale admin console for the actual hostname, or use the Tailscale IP address directly:

```bash
tailscale status | grep aegis
```

### llama-server / Ollama Not Responding

Check the service status:

On Aegis (Windows):
```powershell
# Check if Ollama is running
Get-Process ollama -ErrorAction SilentlyContinue

# Start Ollama manually
ollama serve

# Check GPU is detected
nvidia-smi
```

On Ryzen-AI (Windows):
```powershell
ollama serve
```

---

## Summary Checklist

Mark each item as you complete it:

```
[ ] Nexus: Project extracted/cloned
[ ] Nexus: SSH key generated
[ ] Nexus: SSH config created
[ ] Nexus: Python dependencies installed

[ ] Kali-Nexus: Tailscale connected
[ ] Kali-Nexus: Setup script run
[ ] Kali-Nexus: Public key added
[ ] Kali-Nexus: SSH verified
[ ] Kali-Nexus: Security API verified

[ ] Phantom: Setup script run
[ ] Phantom: Public key added
[ ] Phantom: SSH verified

[ ] Aegis: Public key added (ssh-copy-id)
[ ] Aegis: Setup script run
[ ] Aegis: SSH verified
[ ] Aegis: llama-server verified

[ ] Ryzen-AI: Setup script run
[ ] Ryzen-AI: Public key added
[ ] Ryzen-AI: SSH verified
[ ] Ryzen-AI: Ollama verified

[ ] Orchestrator: Environment file created
[ ] Orchestrator: Started and verified
[ ] System: Health check passes
```

---

## Time Estimate

| Task | Time |
|------|------|
| Nexus setup | 15 minutes |
| Kali-Nexus setup | 30 minutes |
| Phantom setup | 20 minutes |
| Aegis setup | 30 minutes (includes model download) |
| Ryzen-AI setup | 30 minutes (includes model download) |
| Orchestrator setup | 10 minutes |
| Testing and verification | 15 minutes |
| **Total** | **~3 hours** |

Much of this time is waiting for downloads and installations. You can work on multiple machines in parallel to reduce total time.
