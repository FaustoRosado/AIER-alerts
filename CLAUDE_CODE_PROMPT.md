# Claude Code Desktop Master Prompt

## Project Context

You are helping build a Zero-Trust Hybrid AI Pipeline. This is a distributed AI inference system across multiple physical machines connected via Tailscale mesh VPN. The project enforces strict data boundaries where sensitive data never leaves local infrastructure while cloud services handle DevSecOps automation.

## Hardware Inventory

There are five compute environments to configure:

Machine 1: Nexus
- Hardware: Mac Mini M4 Pro with 48GB unified memory
- Operating System: macOS
- Role: Command center, orchestrator, Claude Code Desktop host, SSH key origin
- Tailscale hostname: nexus
- This is where you (Claude Code) are running

Machine 2: Kali-Nexus
- Hardware: Virtual machine running on Nexus Mac Mini via Parallels or UTM
- Operating System: Kali Linux
- Role: Security testing, penetration testing, security scanning agent
- Tailscale hostname: kali-nexus
- Network: Shares Nexus physical network but has own Tailscale identity

Machine 3: Phantom
- Hardware: Dell XPS 9345 with Snapdragon X Elite and 64GB DDR5-8000
- Operating System: Windows 11
- Role: Mobile command center, secondary orchestrator
- Tailscale hostname: phantom

Machine 4: Aegis
- Hardware: AMD Ryzen 9950X with RTX 4080 Super (16GB VRAM) and 64GB DDR5
- Operating System: Windows 11 Pro
- Role: Primary inference node, fastest generation
- Tailscale hostname: aegis
- Note: Has NVIDIA Game Ready drivers installed (Steam). These include CUDA runtime.

Machine 5: Ryzen-AI
- Hardware: Framework laptop with AMD Ryzen AI 395 and 128GB DDR5
- Operating System: Windows 11
- Role: Multi-model specialist, runs 6 models simultaneously, validation
- Tailscale hostname: ryzen-ai

## Current State

Tailscale is installed and running on all five machines. They can ping each other using Tailscale hostnames. SSH keys have not been distributed. The inference software (llama.cpp on Aegis, Ollama on Ryzen-AI) is not yet installed. The orchestrator service is not running.

## Your Tasks

Complete the following tasks in order. After each major task, verify it worked before proceeding.

### Task 1: Verify Tailscale Connectivity

From this machine (Nexus), verify all machines are reachable via Tailscale:

```bash
tailscale status
tailscale ping kali-nexus
tailscale ping phantom
tailscale ping aegis
tailscale ping ryzen-ai
```

Report which machines respond and which do not.

### Task 2: Generate and Distribute SSH Keys

SSH keys originate from Nexus (this machine). Generate an Ed25519 keypair if one does not exist:

```bash
if [ ! -f ~/.ssh/id_ed25519 ]; then
    ssh-keygen -t ed25519 -C "nexus@zero-trust-ai" -N "" -f ~/.ssh/id_ed25519
fi
```

Create the SSH config file at ~/.ssh/config with entries for all remote machines:

```
Host kali-nexus
    HostName kali-nexus
    User kali-nexus
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking accept-new

Host phantom
    HostName phantom
    User your-windows-username
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking accept-new

Host aegis
    HostName aegis
    User your-linux-username
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking accept-new

Host ryzen-ai
    HostName ryzen-ai
    User your-windows-username
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking accept-new
```

The user needs to provide actual usernames for each machine.

### Task 3: Create Remote Setup Scripts

Create scripts that will be copied to and executed on each remote machine.

For Kali-Nexus (Kali Linux VM), create a script that:
- Installs OpenSSH server if not present
- Configures SSH to accept key authentication
- Installs security tools (nmap, nikto, nuclei, trivy)
- Creates authorized_keys with Nexus public key
- Configures firewall to allow SSH from Tailscale network only

For Phantom (Windows 11), create a PowerShell script that:
- Enables OpenSSH server Windows feature
- Starts and enables the sshd service
- Creates .ssh directory and authorized_keys
- Sets correct permissions on authorized_keys
- Configures Windows Firewall for Tailscale SSH only

For Aegis (Windows 11 Pro with RTX 4080 Super), create a PowerShell script that:
- Verifies NVIDIA GPU and Game Ready drivers are working
- Enables OpenSSH server Windows feature
- Configures SSH for key-only authentication
- Installs Ollama (uses GPU automatically with Game Ready drivers)
- Configures Ollama for network access (OLLAMA_HOST=0.0.0.0)
- Downloads primary inference model (llama3.1:8b)
- Creates startup task for Ollama
- Configures Windows Firewall for Tailscale access only
- Creates authorized_keys with Nexus public key

For Ryzen-AI (Windows 11), create a PowerShell script that:
- Enables OpenSSH server
- Installs Ollama
- Configures Ollama for network access
- Pulls specialist models (qwen2.5-coder, phi3, codgemma, bge-m3, llama3.2)
- Creates startup script
- Configures firewall for Tailscale

### Task 4: Create Key Distribution Script

Create a master script that runs from Nexus and:
- Reads the public key from ~/.ssh/id_ed25519.pub
- Copies the setup script to each remote machine
- Executes the setup script on each remote machine
- Verifies SSH connectivity after setup
- Reports success or failure for each machine

### Task 5: Create Orchestrator Configuration

Update the orchestrator to use the correct Tailscale hostnames:
- Aegis backend at http://aegis:8080
- Ryzen-AI backend at http://ryzen-ai:11434
- Add Kali-Nexus as a security scanning endpoint

### Task 6: Create Health Check Scripts

Create scripts that verify the entire system is working:
- Check Tailscale connectivity to all nodes
- Check SSH connectivity to all nodes
- Check inference service health on Aegis
- Check Ollama health on Ryzen-AI
- Check orchestrator routing
- Report overall system status

### Task 7: Create Kali Security Integration

Configure Kali-Nexus to act as a security scanning agent:
- Create API endpoint for triggering scans
- Integrate with orchestrator for automated security checks
- Create scripts for common security tasks

### Task 8: Update Project Documentation

Update all documentation to reflect:
- Actual machine names (Nexus instead of Mac Mini)
- Kali-Nexus integration
- SSH key distribution from Nexus
- Complete network topology

## Constraints

Do not store passwords in scripts. Use SSH keys exclusively.

Do not expose any service to the public internet. All services should only be accessible via Tailscale.

Do not process or transmit any actual sensitive data during testing. Use synthetic test data only.

Assume the user will need to manually approve some steps, particularly the first SSH connection to Windows machines.

## Output Format

For each task:
1. State what you are about to do
2. Show the commands or file contents
3. Execute if appropriate
4. Report the result
5. Ask for confirmation before proceeding to next task

## Begin

Start with Task 1. Verify Tailscale connectivity and report status.
