# ZERO-TRUST HYBRID AI PIPELINE
# Complete Setup Instructions

Project Lead: Sheniese Aracena-Baez (Shay)
Contributors: Shifty (Infrastructure), Javier Acosta (Integration)

These instructions tell you exactly what to do and on which computer.

================================================================================
PART 1: INITIAL SETUP
================================================================================

STEP 1.1: Download and Extract
Computer: NEXUS (Mac Mini)

Open Terminal and run:

    cd ~/Projects
    unzip ~/Downloads/zero-trust-hybrid-ai.zip
    cd zero-trust-hybrid-ai
    ls -la

You should see all project files listed.

--------------------------------------------------------------------------------

STEP 1.2: Install Tailscale on All Machines

Computer: NEXUS (Mac Mini)

    brew install tailscale
    sudo tailscaled
    tailscale up

Follow the browser prompt to authenticate.

Computer: AEGIS (Windows RTX 4080)

    1. Download Tailscale from https://tailscale.com/download/windows
    2. Run the installer
    3. Click the Tailscale icon in system tray
    4. Click "Connect"
    5. Authenticate in browser

Computer: RYZEN-AI (Windows 128GB RAM)

    Same as Aegis:
    1. Download Tailscale from https://tailscale.com/download/windows
    2. Run installer
    3. Connect and authenticate

Computer: KALI-NEXUS (Kali Linux VM)

    curl -fsSL https://tailscale.com/install.sh | sh
    sudo tailscale up

    Follow browser prompt to authenticate.

Computer: PHANTOM (Dell XPS Windows)

    Same as Aegis:
    1. Download Tailscale from https://tailscale.com/download/windows
    2. Run installer
    3. Connect and authenticate

--------------------------------------------------------------------------------

STEP 1.3: Verify Tailscale Connectivity
Computer: NEXUS (Mac Mini)

    tailscale status

You should see all machines listed. Then test connectivity:

    ping aegis
    ping ryzen-ai
    ping kali-nexus
    ping phantom

All should respond. If any fails, check Tailscale is running on that machine.


================================================================================
PART 2: SSH KEY SETUP
================================================================================

STEP 2.1: Generate SSH Key
Computer: NEXUS (Mac Mini)

    cd ~/Projects/zero-trust-hybrid-ai/setup-scripts
    chmod +x distribute-setup.sh
    ./distribute-setup.sh

The script will display your public key. It looks like:

    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... nexus@zero-trust-ai

COPY THIS ENTIRE LINE. You will paste it on each other machine.

STEP 2.1b: Create SSH Config
Computer: NEXUS (Mac Mini)

Create the SSH config file so you don't have to type usernames every time:

    nano ~/.ssh/config

Add these lines (note: usernames differ from home folder names on some machines):

    Host aegis
        HostName aegis
        User aegis

    Host ryzen-ai
        HostName ryzen-ai
        User YOUR_SSH_USER

    Host kali-nexus
        HostName kali-nexus
        User kali-nexus

    Host phantom
        HostName phantom
        User YOUR_SSH_USER

    Host nexus
        HostName nexus
        User nexus

Save with Ctrl+O, Enter, Ctrl+X.

--------------------------------------------------------------------------------

STEP 2.2: Add SSH Key to Aegis
Computer: AEGIS (Windows RTX 4080)

Open PowerShell as Administrator (right-click, Run as Administrator):

    # Enable SSH Server
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
    Start-Service sshd
    Set-Service -Name sshd -StartupType Automatic

    # Create SSH directory
    mkdir $env:USERPROFILE\.ssh -Force

    # Open notepad to create authorized_keys
    notepad $env:USERPROFILE\.ssh\authorized_keys

In Notepad:
1. Paste the public key from Step 2.1
2. Save and close

Now create the admin keys file:

    notepad C:\ProgramData\ssh\administrators_authorized_keys

In Notepad:
1. Paste the same public key
2. Save and close

Fix permissions on administrators_authorized_keys:
1. Right-click C:\ProgramData\ssh\administrators_authorized_keys
2. Properties > Security > Advanced
3. Click "Disable inheritance"
4. Choose "Remove all inherited permissions"
5. Click Add > Select a principal
6. Type "Administrators", click OK
7. Check "Full control", click OK
8. Click Add > Select a principal
9. Type "SYSTEM", click OK
10. Check "Full control", click OK
11. Click Apply, OK

--------------------------------------------------------------------------------

STEP 2.3: Add SSH Key to Ryzen-AI
Computer: RYZEN-AI (Windows 128GB RAM)

Open PowerShell as Administrator:

    # Enable SSH Server
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
    Start-Service sshd
    Set-Service -Name sshd -StartupType Automatic

    # Create SSH directory
    mkdir $env:USERPROFILE\.ssh -Force

    # Open notepad to create authorized_keys
    notepad $env:USERPROFILE\.ssh\authorized_keys

Paste the public key, save.

    notepad C:\ProgramData\ssh\administrators_authorized_keys

Paste the public key, save. Fix permissions same as Step 2.2.

--------------------------------------------------------------------------------

STEP 2.4: Add SSH Key to Kali-Nexus
Computer: KALI-NEXUS (Kali Linux VM)

Open terminal:

    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    nano ~/.ssh/authorized_keys

Paste the public key from Step 2.1, then Ctrl+O to save, Ctrl+X to exit.

    chmod 600 ~/.ssh/authorized_keys
    sudo systemctl enable ssh
    sudo systemctl start ssh

--------------------------------------------------------------------------------

STEP 2.5: Add SSH Key to Phantom
Computer: PHANTOM (Dell XPS Windows)

Open PowerShell as Administrator:

    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
    Start-Service sshd
    Set-Service -Name sshd -StartupType Automatic
    mkdir $env:USERPROFILE\.ssh -Force
    notepad $env:USERPROFILE\.ssh\authorized_keys

Paste the public key, save.

    notepad C:\ProgramData\ssh\administrators_authorized_keys

Paste the public key, save. Fix permissions same as Step 2.2.

--------------------------------------------------------------------------------

STEP 2.6: Test All SSH Connections
Computer: NEXUS (Mac Mini)

    ssh aegis "echo SUCCESS"
    ssh ryzen-ai "echo SUCCESS"
    ssh kali-nexus "echo SUCCESS"
    ssh phantom "echo SUCCESS"

All four should print "SUCCESS". If any fails, go back and check that machine.


================================================================================
PART 3: INFERENCE NODE SETUP
================================================================================

STEP 3.1: Set Up Aegis (llama.cpp)
Computer: NEXUS (Mac Mini)

First, copy the setup script to Aegis:

    scp ~/Projects/zero-trust-hybrid-ai/inference-nodes/aegis/setup-aegis.ps1 aegis:C:/Users/YOUR_WIN_USER/

Computer: AEGIS (Windows RTX 4080)

Open PowerShell as Administrator:

    Set-ExecutionPolicy Bypass -Scope Process
    cd $env:USERPROFILE
    .\setup-aegis.ps1

This will:
- Download llama.cpp (about 50MB)
- Download Llama 3.1 8B model (about 5GB) - takes 10-20 minutes
- Configure for RTX 4080 Super
- Set up auto-start

When complete, verify from Nexus:

Computer: NEXUS (Mac Mini)

    curl http://aegis:8080/health

Should return: {"status":"ok"}

--------------------------------------------------------------------------------

STEP 3.2: Set Up Ryzen-AI (Ollama)
Computer: NEXUS (Mac Mini)

Copy the setup script:

    scp ~/Projects/zero-trust-hybrid-ai/inference-nodes/ryzen-ai/setup-ryzen-ai.ps1 ryzen-ai:C:/Users/YOUR_WIN_USER/

Computer: RYZEN-AI (Windows 128GB RAM)

Open PowerShell as Administrator:

    Set-ExecutionPolicy Bypass -Scope Process
    cd $env:USERPROFILE
    .\setup-ryzen-ai.ps1

This will:
- Install Ollama
- Download models (about 20GB total) - takes 20-30 minutes
- Configure firewall
- Create optional RAMDisk script on Desktop

When complete, verify from Nexus:

Computer: NEXUS (Mac Mini)

    curl http://ryzen-ai:11434/api/tags

Should return a JSON list of models.

--------------------------------------------------------------------------------

STEP 3.3: Set Up Kali-Nexus (Security Tools)
Computer: NEXUS (Mac Mini)

Copy the setup script:

    scp ~/Projects/zero-trust-hybrid-ai/setup-scripts/setup-kali-nexus.sh kali-nexus:~/

Computer: KALI-NEXUS (Kali Linux VM)

    chmod +x ~/setup-kali-nexus.sh
    sudo ~/setup-kali-nexus.sh

When complete, verify from Nexus:

Computer: NEXUS (Mac Mini)

    curl http://kali-nexus:8080/health

--------------------------------------------------------------------------------

STEP 3.4: Set Up Orchestrator
Computer: NEXUS (Mac Mini)

    cd ~/Projects/zero-trust-hybrid-ai/orchestrator

    # Create virtual environment
    python3 -m venv venv
    source venv/bin/activate

    # Install dependencies
    pip install -r requirements.txt

    # Download spacy model for Presidio
    python -m spacy download en_core_web_lg

    # Start orchestrator
    python main.py

Leave this terminal running. The orchestrator is now active on port 8000.

--------------------------------------------------------------------------------

STEP 3.5: Verify Complete Infrastructure
Computer: NEXUS (Mac Mini)

Open a new terminal:

    # Check orchestrator
    curl http://localhost:8000/health

    # List backends
    curl http://localhost:8000/backends

    # Test routing with PHI (should route LOCAL)
    curl -X POST http://localhost:8000/analyze \
      -H "Content-Type: application/json" \
      -d '{"text": "Patient John Smith, SSN 123-45-6789"}'

The response should show: "route": "local"


================================================================================
PART 4: GITHUB REPOSITORY REBUILD
================================================================================

STEP 4.1: Open Claude Code Desktop
Computer: NEXUS (Mac Mini)

1. Open Claude Code Desktop application
2. Point it to: ~/Projects/zero-trust-hybrid-ai
3. Wait for it to index the project

--------------------------------------------------------------------------------

STEP 4.2: Load Project Context

In Claude Code Desktop, paste this prompt:

    Read the file PROJECT_CONTEXT.md and commit its contents to your memory.

    This is the Zero-Trust Hybrid AI Pipeline project.
    Project Lead: Sheniese Aracena-Baez (Shay)
    Contributors: Shifty (Infrastructure), Javier Acosta (Integration)

    Key facts:
    - Aegis runs llama.cpp on port 8080
    - Ryzen-AI runs Ollama on port 11434
    - All machines connect via Tailscale
    - Shay designed the 3-tier routing system
    - Tier 1 data NEVER leaves local infrastructure

    Confirm you have loaded this context.

Wait for Claude to confirm.

--------------------------------------------------------------------------------

STEP 4.3: Rebuild GitHub Repository

In Claude Code Desktop, paste the entire contents of CLAUDE_CODE_PROMPTS.md,
starting from "PROMPT 1: REBUILD GITHUB REPOSITORY".

This prompt will:
- Clone the existing repo (https://github.com/FaustoRosado/AIER-alerts)
- Back up all existing branches (main, ai-siem-infra, sprint3-v2, tech-architecture, tech-execution)
- Create 17 commits showing project progression
- Attribute commits correctly (Shay as lead, Shifty infrastructure, Javier integration)
- Create feature branches
- Archive old branches
- Create release tags

Wait for Claude to complete all phases.

--------------------------------------------------------------------------------

STEP 4.4: Security Audit

In Claude Code Desktop, paste the contents of PROMPT 2 from CLAUDE_CODE_PROMPTS.md.

This will audit the code for HIPAA compliance and fix any issues.

Wait for completion.

--------------------------------------------------------------------------------

STEP 4.5: Build Demo Components

In Claude Code Desktop, paste the contents of PROMPT 3 from CLAUDE_CODE_PROMPTS.md.

This creates:
- Streamlit demo application
- Sample test data
- Presentation script
- Student tutorial

Wait for completion.

--------------------------------------------------------------------------------

STEP 4.6: Create Verification Scripts

In Claude Code Desktop, paste the contents of PROMPT 4 from CLAUDE_CODE_PROMPTS.md.

This creates scripts to verify infrastructure.

Wait for completion.

--------------------------------------------------------------------------------

STEP 4.7: Finalize Documentation

In Claude Code Desktop, paste the contents of PROMPT 5 from CLAUDE_CODE_PROMPTS.md.

This reviews and finalizes all documentation.

Wait for completion.


================================================================================
PART 5: RUN THE DEMO
================================================================================

STEP 5.1: Start Streamlit Demo
Computer: NEXUS (Mac Mini)

    cd ~/Projects/zero-trust-hybrid-ai/demo
    pip install streamlit
    streamlit run capstone_demo.py

Browser opens to http://localhost:8501

--------------------------------------------------------------------------------

STEP 5.2: Demo Walkthrough

1. Show backend status - all machines should show green/connected
2. Enter a Tier 1 query: "Patient Maria Garcia, SSN 987-65-4321"
   - Watch it route to LOCAL
   - Show detected entities
3. Enter a Tier 2 query: "Server at 192.168.1.100 needs restart"
   - Show anonymization (<IP_ADDRESS>)
4. Enter a Tier 3 query: "Explain how TCP works"
   - Show it allows cloud routing
5. Explain Shay's 3-tier design and why it matters for HIPAA


================================================================================
PART 6: VERIFICATION CHECKLIST
================================================================================

Before presentation, verify all items:

NETWORK:
[ ] Tailscale running on all machines
[ ] Can ping aegis, ryzen-ai, kali-nexus, phantom from Nexus

SSH:
[ ] ssh aegis works
[ ] ssh ryzen-ai works
[ ] ssh kali-nexus works
[ ] ssh phantom works

SERVICES:
[ ] curl http://aegis:8080/health returns OK
[ ] curl http://ryzen-ai:11434/api/tags returns model list
[ ] curl http://localhost:8000/health returns OK
[ ] curl http://localhost:8000/backends shows all backends

ROUTING:
[ ] PHI query routes to LOCAL
[ ] IP address query shows anonymization
[ ] General question allows cloud

GITHUB:
[ ] Main branch has proper commit history
[ ] Commits attributed correctly (Shay, Shifty, Javier)
[ ] Feature branches exist
[ ] Archive branches exist
[ ] Release tags exist (v0.1.0, v0.2.0, v0.3.0, v1.0.0)

DEMO:
[ ] Streamlit app runs
[ ] Backend status shows correctly
[ ] Routing visualization works


================================================================================
TROUBLESHOOTING
================================================================================

PROBLEM: Tailscale machine not reachable
SOLUTION: On that machine, run: tailscale up
          Check: tailscale status

PROBLEM: SSH permission denied
SOLUTION: Check authorized_keys file exists
          On Windows, check administrators_authorized_keys permissions

PROBLEM: Aegis not responding
SOLUTION: SSH to aegis, check if llama-server running:
          Get-Process llama-server
          If not, run: C:\llama.cpp\start-llama-server.bat

PROBLEM: Ryzen-AI not responding
SOLUTION: SSH to ryzen-ai, restart Ollama:
          ollama serve

PROBLEM: Orchestrator error about Presidio
SOLUTION: Run: python -m spacy download en_core_web_lg

PROBLEM: Git push rejected
SOLUTION: Use: git push origin main --force-with-lease
          (Only after confirming backups exist)


================================================================================
FILE LOCATIONS
================================================================================

Main instruction file:
    ~/Projects/zero-trust-hybrid-ai/COMPLETE_INSTRUCTIONS.md

Claude Code prompts:
    ~/Projects/zero-trust-hybrid-ai/CLAUDE_CODE_PROMPTS.md

Orchestrator:
    ~/Projects/zero-trust-hybrid-ai/orchestrator/main.py
    ~/Projects/zero-trust-hybrid-ai/orchestrator/sensitive_routing.py

Setup scripts:
    ~/Projects/zero-trust-hybrid-ai/inference-nodes/aegis/setup-aegis.ps1
    ~/Projects/zero-trust-hybrid-ai/inference-nodes/ryzen-ai/setup-ryzen-ai.ps1
    ~/Projects/zero-trust-hybrid-ai/setup-scripts/distribute-setup.sh

Demo:
    ~/Projects/zero-trust-hybrid-ai/demo/capstone_demo.py
    ~/Projects/zero-trust-hybrid-ai/demo/presentation_script.md


================================================================================
END OF INSTRUCTIONS
================================================================================
