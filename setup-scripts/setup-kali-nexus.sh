#!/bin/bash
# ============================================================================
# Zero-Trust Hybrid AI Pipeline
# Kali-Nexus Setup Script
# ============================================================================
#
# This script runs on the Kali Linux VM hosted on Nexus Mac Mini.
# It configures SSH, installs security tools, and sets up the security
# scanning agent role.
#
# Prerequisites:
#   - Kali Linux installed and running
#   - Tailscale installed and connected (hostname: kali-nexus)
#   - Root or sudo access
#
# Usage:
#   chmod +x setup-kali-nexus.sh
#   sudo ./setup-kali-nexus.sh
#
# ============================================================================

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "============================================"
echo "Kali-Nexus Setup Script"
echo "Zero-Trust Hybrid AI Pipeline"
echo "============================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}ERROR: This script must be run as root (use sudo)${NC}"
    exit 1
fi

# Get the actual user (not root)
ACTUAL_USER=${SUDO_USER:-kali}
ACTUAL_HOME=$(eval echo ~$ACTUAL_USER)

echo "Setting up for user: $ACTUAL_USER"
echo "Home directory: $ACTUAL_HOME"
echo ""

# ============================================================================
# Step 1: Update System
# ============================================================================

echo -e "${YELLOW}Step 1: Updating system packages...${NC}"

apt-get update
apt-get upgrade -y

echo -e "${GREEN}System updated${NC}"
echo ""

# ============================================================================
# Step 2: Install and Configure OpenSSH Server
# ============================================================================

echo -e "${YELLOW}Step 2: Configuring SSH server...${NC}"

# Install OpenSSH server if not present
apt-get install -y openssh-server

# Backup original config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d)

# Configure SSH for security
cat > /etc/ssh/sshd_config.d/zero-trust.conf << 'EOF'
# Zero-Trust Hybrid AI Pipeline SSH Configuration

# Disable password authentication - keys only
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM yes

# Allow only key-based authentication
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

# Security hardening
PermitRootLogin no
MaxAuthTries 3
MaxSessions 5
ClientAliveInterval 300
ClientAliveCountMax 2

# Restrict to Tailscale network
# Note: ListenAddress restricts which interfaces SSH listens on
# We listen on all interfaces but firewall restricts access
ListenAddress 0.0.0.0

# Logging for audit trail
SyslogFacility AUTH
LogLevel VERBOSE
EOF

# Enable and start SSH
systemctl enable ssh
systemctl restart ssh

echo -e "${GREEN}SSH server configured${NC}"
echo ""

# ============================================================================
# Step 3: Setup SSH Directory and Authorized Keys
# ============================================================================

echo -e "${YELLOW}Step 3: Setting up SSH keys directory...${NC}"

# Create .ssh directory for user
SSH_DIR="$ACTUAL_HOME/.ssh"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
chown "$ACTUAL_USER:$ACTUAL_USER" "$SSH_DIR"

# Create authorized_keys file if it does not exist
AUTH_KEYS="$SSH_DIR/authorized_keys"
touch "$AUTH_KEYS"
chmod 600 "$AUTH_KEYS"
chown "$ACTUAL_USER:$ACTUAL_USER" "$AUTH_KEYS"

echo -e "${GREEN}SSH directory configured at $SSH_DIR${NC}"
echo ""
echo -e "${YELLOW}IMPORTANT: You need to add Nexus public key to authorized_keys${NC}"
echo "Run this on Nexus to get the public key:"
echo "  cat ~/.ssh/id_ed25519.pub"
echo ""
echo "Then paste it into: $AUTH_KEYS"
echo ""

# ============================================================================
# Step 4: Configure Firewall (UFW)
# ============================================================================

echo -e "${YELLOW}Step 4: Configuring firewall...${NC}"

# Install UFW if not present
apt-get install -y ufw

# Reset UFW to defaults
ufw --force reset

# Default policies
ufw default deny incoming
ufw default allow outgoing

# Allow SSH only from Tailscale network (100.64.0.0/10)
ufw allow from 100.64.0.0/10 to any port 22 proto tcp comment 'SSH from Tailscale'

# Allow security scanning ports from Tailscale (for API access)
ufw allow from 100.64.0.0/10 to any port 8080 proto tcp comment 'Security API from Tailscale'

# Enable UFW
ufw --force enable

echo -e "${GREEN}Firewall configured - SSH allowed from Tailscale only${NC}"
ufw status verbose
echo ""

# ============================================================================
# Step 5: Install Security Tools
# ============================================================================

echo -e "${YELLOW}Step 5: Installing security tools...${NC}"

# Core security tools
apt-get install -y \
    nmap \
    nikto \
    sqlmap \
    dirb \
    gobuster \
    hydra \
    john \
    hashcat \
    metasploit-framework \
    burpsuite \
    wireshark \
    tcpdump \
    netcat-openbsd \
    socat \
    curl \
    wget \
    git \
    python3-pip \
    python3-venv \
    jq

echo -e "${GREEN}Core security tools installed${NC}"
echo ""

# ============================================================================
# Step 6: Install Additional Scanning Tools
# ============================================================================

echo -e "${YELLOW}Step 6: Installing additional scanners...${NC}"

# Install Nuclei (vulnerability scanner)
echo "Installing Nuclei..."
if ! command -v nuclei &> /dev/null; then
    GO_VERSION="1.21.0"
    wget -q "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -O /tmp/go.tar.gz
    rm -rf /usr/local/go
    tar -C /usr/local -xzf /tmp/go.tar.gz
    rm /tmp/go.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    echo 'export PATH=$PATH:/usr/local/go/bin' >> "$ACTUAL_HOME/.bashrc"
    
    /usr/local/go/bin/go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
    cp /root/go/bin/nuclei /usr/local/bin/ 2>/dev/null || cp "$ACTUAL_HOME/go/bin/nuclei" /usr/local/bin/ 2>/dev/null || true
fi

# Install Trivy (container/IaC scanner)
echo "Installing Trivy..."
if ! command -v trivy &> /dev/null; then
    wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor -o /usr/share/keyrings/trivy.gpg
    echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | tee /etc/apt/sources.list.d/trivy.list
    apt-get update
    apt-get install -y trivy
fi

# Install Checkov (IaC security scanner)
echo "Installing Checkov..."
pip3 install checkov --break-system-packages 2>/dev/null || pip3 install checkov

# Install semgrep (static analysis)
echo "Installing Semgrep..."
pip3 install semgrep --break-system-packages 2>/dev/null || pip3 install semgrep

echo -e "${GREEN}Additional scanners installed${NC}"
echo ""

# ============================================================================
# Step 7: Create Security Scanning Scripts
# ============================================================================

echo -e "${YELLOW}Step 7: Creating security scanning scripts...${NC}"

# Create scripts directory
SCRIPTS_DIR="$ACTUAL_HOME/security-scripts"
mkdir -p "$SCRIPTS_DIR"

# Network scan script
cat > "$SCRIPTS_DIR/scan-network.sh" << 'EOF'
#!/bin/bash
# Scan Tailscale network for active hosts and open ports

TARGET="${1:-100.64.0.0/10}"
OUTPUT_DIR="$HOME/scan-results/$(date +%Y%m%d)"
mkdir -p "$OUTPUT_DIR"

echo "Scanning network: $TARGET"
echo "Results will be saved to: $OUTPUT_DIR"

# Quick ping scan
echo "Running ping scan..."
nmap -sn "$TARGET" -oN "$OUTPUT_DIR/ping-scan.txt"

# Port scan on discovered hosts
echo "Running port scan on live hosts..."
nmap -sV -sC -p- --open -iL <(grep "Nmap scan report" "$OUTPUT_DIR/ping-scan.txt" | awk '{print $5}') -oN "$OUTPUT_DIR/port-scan.txt" 2>/dev/null

echo "Scan complete. Results in $OUTPUT_DIR"
EOF

# Infrastructure scan script
cat > "$SCRIPTS_DIR/scan-iac.sh" << 'EOF'
#!/bin/bash
# Scan Infrastructure as Code for security issues

TARGET_DIR="${1:-.}"
OUTPUT_DIR="$HOME/scan-results/iac-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUTPUT_DIR"

echo "Scanning IaC in: $TARGET_DIR"
echo "Results will be saved to: $OUTPUT_DIR"

# Run Checkov
echo "Running Checkov..."
checkov -d "$TARGET_DIR" --output-file-path "$OUTPUT_DIR" --output cli --output json 2>/dev/null

# Run Trivy for IaC
echo "Running Trivy config scan..."
trivy config "$TARGET_DIR" --format json --output "$OUTPUT_DIR/trivy-config.json" 2>/dev/null

# Run Semgrep
echo "Running Semgrep..."
semgrep --config auto "$TARGET_DIR" --json --output "$OUTPUT_DIR/semgrep.json" 2>/dev/null

echo "IaC scan complete. Results in $OUTPUT_DIR"
EOF

# Container scan script
cat > "$SCRIPTS_DIR/scan-container.sh" << 'EOF'
#!/bin/bash
# Scan container images for vulnerabilities

IMAGE="${1:-}"
OUTPUT_DIR="$HOME/scan-results/container-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUTPUT_DIR"

if [ -z "$IMAGE" ]; then
    echo "Usage: $0 <image-name>"
    exit 1
fi

echo "Scanning container: $IMAGE"
echo "Results will be saved to: $OUTPUT_DIR"

# Run Trivy
echo "Running Trivy vulnerability scan..."
trivy image "$IMAGE" --format json --output "$OUTPUT_DIR/trivy-vulns.json"
trivy image "$IMAGE" --format table --output "$OUTPUT_DIR/trivy-vulns.txt"

echo "Container scan complete. Results in $OUTPUT_DIR"
EOF

# Make scripts executable
chmod +x "$SCRIPTS_DIR"/*.sh
chown -R "$ACTUAL_USER:$ACTUAL_USER" "$SCRIPTS_DIR"

echo -e "${GREEN}Security scripts created in $SCRIPTS_DIR${NC}"
echo ""

# ============================================================================
# Step 8: Create Security API Service
# ============================================================================

echo -e "${YELLOW}Step 8: Creating Security API service...${NC}"

# Create Python virtual environment
VENV_DIR="$ACTUAL_HOME/security-api"
python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"

# Install FastAPI
pip install fastapi uvicorn httpx

# Create the API
cat > "$VENV_DIR/main.py" << 'EOF'
"""
Zero-Trust Hybrid AI Pipeline
Kali-Nexus Security Scanning API

This API provides endpoints for triggering security scans from the orchestrator.
All scans run locally on the Kali VM and return results.
"""

from fastapi import FastAPI, HTTPException, BackgroundTasks
from pydantic import BaseModel
from typing import Optional, List
import subprocess
import os
import json
from datetime import datetime

app = FastAPI(
    title="Kali-Nexus Security API",
    description="Security scanning agent for Zero-Trust Hybrid AI Pipeline",
    version="1.0.0"
)

RESULTS_DIR = os.path.expanduser("~/scan-results")
os.makedirs(RESULTS_DIR, exist_ok=True)


class ScanRequest(BaseModel):
    target: str
    scan_type: str  # network, iac, container, code
    options: Optional[dict] = {}


class ScanResult(BaseModel):
    scan_id: str
    status: str
    scan_type: str
    target: str
    started_at: str
    completed_at: Optional[str]
    findings: Optional[List[dict]]
    raw_output: Optional[str]


# Store for tracking scans
scans = {}


@app.get("/health")
def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "kali-nexus-security",
        "timestamp": datetime.utcnow().isoformat()
    }


@app.get("/tools")
def list_tools():
    """List available security tools"""
    tools = []
    
    tool_checks = [
        ("nmap", "nmap --version"),
        ("nikto", "nikto -Version"),
        ("nuclei", "nuclei -version"),
        ("trivy", "trivy --version"),
        ("checkov", "checkov --version"),
        ("semgrep", "semgrep --version"),
        ("sqlmap", "sqlmap --version"),
    ]
    
    for name, cmd in tool_checks:
        try:
            result = subprocess.run(
                cmd.split(), 
                capture_output=True, 
                text=True, 
                timeout=10
            )
            tools.append({
                "name": name,
                "available": result.returncode == 0,
                "version": result.stdout.split('\n')[0] if result.returncode == 0 else None
            })
        except Exception:
            tools.append({"name": name, "available": False, "version": None})
    
    return {"tools": tools}


@app.post("/scan/network")
async def scan_network(request: ScanRequest, background_tasks: BackgroundTasks):
    """Trigger a network scan"""
    scan_id = f"net-{datetime.utcnow().strftime('%Y%m%d%H%M%S')}"
    
    scans[scan_id] = {
        "scan_id": scan_id,
        "status": "running",
        "scan_type": "network",
        "target": request.target,
        "started_at": datetime.utcnow().isoformat(),
        "completed_at": None,
        "findings": None
    }
    
    background_tasks.add_task(run_network_scan, scan_id, request.target)
    
    return {"scan_id": scan_id, "status": "started"}


def run_network_scan(scan_id: str, target: str):
    """Run network scan in background"""
    try:
        output_file = f"{RESULTS_DIR}/{scan_id}.txt"
        
        # Run nmap
        result = subprocess.run(
            ["nmap", "-sV", "-sC", "--open", "-oN", output_file, target],
            capture_output=True,
            text=True,
            timeout=600
        )
        
        scans[scan_id]["status"] = "completed"
        scans[scan_id]["completed_at"] = datetime.utcnow().isoformat()
        scans[scan_id]["raw_output"] = result.stdout
        
    except Exception as e:
        scans[scan_id]["status"] = "failed"
        scans[scan_id]["error"] = str(e)


@app.post("/scan/iac")
async def scan_iac(request: ScanRequest, background_tasks: BackgroundTasks):
    """Trigger Infrastructure as Code scan"""
    scan_id = f"iac-{datetime.utcnow().strftime('%Y%m%d%H%M%S')}"
    
    scans[scan_id] = {
        "scan_id": scan_id,
        "status": "running",
        "scan_type": "iac",
        "target": request.target,
        "started_at": datetime.utcnow().isoformat(),
        "completed_at": None,
        "findings": None
    }
    
    background_tasks.add_task(run_iac_scan, scan_id, request.target)
    
    return {"scan_id": scan_id, "status": "started"}


def run_iac_scan(scan_id: str, target_dir: str):
    """Run IaC scan in background"""
    try:
        output_file = f"{RESULTS_DIR}/{scan_id}.json"
        
        # Run Checkov
        result = subprocess.run(
            ["checkov", "-d", target_dir, "--output", "json"],
            capture_output=True,
            text=True,
            timeout=300
        )
        
        findings = []
        if result.stdout:
            try:
                checkov_results = json.loads(result.stdout)
                if isinstance(checkov_results, list):
                    for check_type in checkov_results:
                        if "results" in check_type:
                            failed = check_type["results"].get("failed_checks", [])
                            for f in failed:
                                findings.append({
                                    "tool": "checkov",
                                    "severity": f.get("severity", "unknown"),
                                    "resource": f.get("resource", "unknown"),
                                    "check": f.get("check_id", "unknown"),
                                    "message": f.get("check_result", {}).get("message", "")
                                })
            except json.JSONDecodeError:
                pass
        
        scans[scan_id]["status"] = "completed"
        scans[scan_id]["completed_at"] = datetime.utcnow().isoformat()
        scans[scan_id]["findings"] = findings
        
        # Save results
        with open(output_file, 'w') as f:
            json.dump(scans[scan_id], f, indent=2)
        
    except Exception as e:
        scans[scan_id]["status"] = "failed"
        scans[scan_id]["error"] = str(e)


@app.get("/scan/{scan_id}")
def get_scan_result(scan_id: str):
    """Get scan results by ID"""
    if scan_id not in scans:
        raise HTTPException(status_code=404, detail="Scan not found")
    
    return scans[scan_id]


@app.get("/scans")
def list_scans():
    """List all scans"""
    return {"scans": list(scans.values())}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
EOF

chown -R "$ACTUAL_USER:$ACTUAL_USER" "$VENV_DIR"

# Create systemd service
cat > /etc/systemd/system/security-api.service << EOF
[Unit]
Description=Kali-Nexus Security Scanning API
After=network.target

[Service]
Type=simple
User=$ACTUAL_USER
WorkingDirectory=$VENV_DIR
ExecStart=$VENV_DIR/bin/python -m uvicorn main:app --host 0.0.0.0 --port 8080
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable security-api
systemctl start security-api

echo -e "${GREEN}Security API service created and started${NC}"
echo ""

# ============================================================================
# Step 9: Verify Installation
# ============================================================================

echo -e "${YELLOW}Step 9: Verifying installation...${NC}"
echo ""

echo "SSH Status:"
systemctl status ssh --no-pager | head -5
echo ""

echo "Firewall Status:"
ufw status
echo ""

echo "Security API Status:"
systemctl status security-api --no-pager | head -5
echo ""

echo "Installed Tools:"
for tool in nmap nikto nuclei trivy checkov semgrep; do
    if command -v $tool &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} $tool"
    else
        echo -e "  ${RED}✗${NC} $tool"
    fi
done
echo ""

# ============================================================================
# Complete
# ============================================================================

echo "============================================"
echo -e "${GREEN}Kali-Nexus Setup Complete${NC}"
echo "============================================"
echo ""
echo "Next Steps:"
echo ""
echo "1. Add Nexus public key to authorized_keys:"
echo "   From Nexus, run: cat ~/.ssh/id_ed25519.pub"
echo "   Then paste into: $AUTH_KEYS"
echo ""
echo "2. Test SSH from Nexus:"
echo "   ssh kali-nexus"
echo ""
echo "3. Test Security API:"
echo "   curl http://kali-nexus:8080/health"
echo "   curl http://kali-nexus:8080/tools"
echo ""
echo "Security scripts are in: $SCRIPTS_DIR"
echo "Scan results will be saved to: $ACTUAL_HOME/scan-results"
echo ""
