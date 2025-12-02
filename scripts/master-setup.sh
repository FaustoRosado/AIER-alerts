#!/bin/bash
# ============================================================================
# Zero-Trust Hybrid AI Pipeline - Master Setup Script
# ============================================================================
#
# This script sets up the complete distributed AI infrastructure across
# your hardware ecosystem:
#
#   • Phantom (Dell XPS Snapdragon) - Command Center
#   • Mac Mini M4 Pro (48GB) - Orchestrator + Backup Inference
#   • Aegis (RTX 4080 Super) - Primary Fast Inference
#   • Ryzen-AI (Ryzen AI 395, 128GB) - Multi-Model Specialist
#
# Prerequisites:
#   • Tailscale installed and connected on all machines
#   • SSH key authentication configured
#   • This script runs from Phantom or Mac Mini (orchestrator node)
#
# Usage:
#   chmod +x scripts/master-setup.sh
#   ./scripts/master-setup.sh
#
# ============================================================================

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Machine hostnames (Tailscale MagicDNS)
AEGIS="aegis"
RYZEN_AI="ryzen-ai"
MAC_MINI="mac-mini-m4"

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                               ║"
echo "║       Zero-Trust Hybrid AI Pipeline - Master Setup            ║"
echo "║                                                               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# ============================================================================
# Step 1: Verify Tailscale Connectivity
# ============================================================================

echo -e "${YELLOW}═══ Step 1: Verifying Tailscale Connectivity ═══${NC}"
echo ""

check_host() {
    local host=$1
    local name=$2
    
    if tailscale ping --timeout=5s "$host" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} $name ($host) - reachable"
        return 0
    else
        echo -e "  ${RED}✗${NC} $name ($host) - NOT reachable"
        return 1
    fi
}

CONNECTIVITY_OK=true

check_host "$AEGIS" "Aegis (RTX 4080 Super)" || CONNECTIVITY_OK=false
check_host "$RYZEN_AI" "Ryzen-AI (Ryzen AI 395)" || CONNECTIVITY_OK=false
check_host "$MAC_MINI" "Mac Mini M4 Pro" || CONNECTIVITY_OK=false

echo ""

if [ "$CONNECTIVITY_OK" = false ]; then
    echo -e "${RED}ERROR: Some machines are not reachable via Tailscale.${NC}"
    echo "Please ensure:"
    echo "  1. Tailscale is running on all machines"
    echo "  2. All machines are on the same Tailnet"
    echo "  3. MagicDNS is enabled"
    echo ""
    echo "Run 'tailscale status' to check connectivity."
    exit 1
fi

echo -e "${GREEN}All machines reachable via Tailscale${NC}"
echo ""

# ============================================================================
# Step 2: Verify SSH Access
# ============================================================================

echo -e "${YELLOW}═══ Step 2: Verifying SSH Access ═══${NC}"
echo ""

check_ssh() {
    local host=$1
    local name=$2
    
    if ssh -o ConnectTimeout=5 -o BatchMode=yes "$host" "echo ok" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} SSH to $name - working"
        return 0
    else
        echo -e "  ${RED}✗${NC} SSH to $name - FAILED"
        return 1
    fi
}

SSH_OK=true

check_ssh "$AEGIS" "Aegis" || SSH_OK=false
check_ssh "$RYZEN_AI" "Ryzen-AI" || SSH_OK=false

echo ""

if [ "$SSH_OK" = false ]; then
    echo -e "${YELLOW}WARNING: SSH access not fully configured.${NC}"
    echo ""
    echo "To fix, run on this machine:"
    echo "  ssh-copy-id $AEGIS"
    echo "  ssh-copy-id $RYZEN_AI"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo -e "${GREEN}SSH access verified${NC}"
echo ""

# ============================================================================
# Step 3: Setup Aegis (RTX 4080 Super)
# ============================================================================

echo -e "${YELLOW}═══ Step 3: Setting Up Aegis (Primary Inference) ═══${NC}"
echo ""

read -p "Setup Aegis now? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Copying setup script to Aegis..."
    scp inference-nodes/aegis/setup-aegis.sh "$AEGIS:~/setup-aegis.sh"
    
    echo "Running setup on Aegis (this may take 10-15 minutes)..."
    echo "You can monitor progress in another terminal with: ssh $AEGIS 'tail -f /tmp/aegis-setup.log'"
    echo ""
    
    ssh "$AEGIS" "chmod +x ~/setup-aegis.sh && ~/setup-aegis.sh 2>&1 | tee /tmp/aegis-setup.log"
    
    echo ""
    echo -e "${GREEN}✓ Aegis setup complete${NC}"
else
    echo "Skipping Aegis setup"
fi
echo ""

# ============================================================================
# Step 4: Setup Ryzen-AI (Ryzen AI 395)
# ============================================================================

echo -e "${YELLOW}═══ Step 4: Setting Up Ryzen-AI (Multi-Model Node) ═══${NC}"
echo ""

echo -e "${CYAN}NOTE: Ryzen-AI runs Windows 11. You have two options:${NC}"
echo ""
echo "  1. Copy the PowerShell script and run manually in Windows"
echo "  2. If OpenSSH is installed on Ryzen-AI, run remotely"
echo ""

read -p "Which option? (1/2/skip) " -n 1 -r
echo ""

case $REPLY in
    1)
        echo "The setup script is at: inference-nodes/ryzen-ai/setup-ryzen-ai.ps1"
        echo ""
        echo "Copy it to Ryzen-AI and run in PowerShell as Administrator:"
        echo "  Set-ExecutionPolicy Bypass -Scope Process"
        echo "  .\\setup-ryzen-ai.ps1"
        ;;
    2)
        echo "Attempting remote PowerShell execution..."
        scp inference-nodes/ryzen-ai/setup-ryzen-ai.ps1 "$RYZEN_AI:~/setup-ryzen-ai.ps1"
        ssh "$RYZEN_AI" "powershell -ExecutionPolicy Bypass -File ~/setup-ryzen-ai.ps1"
        echo -e "${GREEN}✓ Ryzen-AI setup complete${NC}"
        ;;
    *)
        echo "Skipping Ryzen-AI setup"
        ;;
esac
echo ""

# ============================================================================
# Step 5: Setup Local Orchestrator
# ============================================================================

echo -e "${YELLOW}═══ Step 5: Setting Up Local Orchestrator ═══${NC}"
echo ""

echo "Installing Python dependencies..."
pip install -r orchestrator/requirements.txt

echo ""
echo "Creating orchestrator configuration..."

# Detect current machine
CURRENT_HOST=$(hostname)

cat > orchestrator/.env << EOF
# Orchestrator Configuration
# Generated by master-setup.sh

# Backend URLs (Tailscale MagicDNS)
AEGIS_URL=http://${AEGIS}:8080
RYZEN_AI_URL=http://${RYZEN_AI}:11434
MAC_MINI_URL=http://${MAC_MINI}:11434

# Current machine
CURRENT_HOST=${CURRENT_HOST}
EOF

echo -e "${GREEN}✓ Orchestrator configured${NC}"
echo ""

# ============================================================================
# Step 6: Start Orchestrator
# ============================================================================

echo -e "${YELLOW}═══ Step 6: Starting Orchestrator ═══${NC}"
echo ""

echo "Starting orchestrator in background..."
cd orchestrator
nohup python main.py > ../logs/orchestrator.log 2>&1 &
ORCHESTRATOR_PID=$!
cd ..

echo "Orchestrator PID: $ORCHESTRATOR_PID"
echo ""

# Wait for startup
echo "Waiting for orchestrator to start..."
sleep 5

# Test health endpoint
if curl -s http://localhost:8000/health | grep -q "healthy"; then
    echo -e "${GREEN}✓ Orchestrator is healthy${NC}"
else
    echo -e "${YELLOW}WARNING: Orchestrator may not be fully ready${NC}"
    echo "Check logs: tail -f logs/orchestrator.log"
fi
echo ""

# ============================================================================
# Step 7: Verify Full System
# ============================================================================

echo -e "${YELLOW}═══ Step 7: Verifying Full System ═══${NC}"
echo ""

echo "Checking all backends..."
curl -s http://localhost:8000/backends | python3 -c "
import json, sys
data = json.load(sys.stdin)
for backend in data.get('backends', []):
    status = '✓' if backend.get('status') == 'online' else '✗'
    print(f\"  {status} {backend.get('name', 'Unknown')}: {backend.get('status', 'unknown')}\")
"
echo ""

# ============================================================================
# Step 8: Test Inference
# ============================================================================

echo -e "${YELLOW}═══ Step 8: Testing Inference ═══${NC}"
echo ""

echo "Sending test request..."
RESPONSE=$(curl -s -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Say hello in 5 words or less"}]}')

echo "$RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
content = data.get('choices', [{}])[0].get('message', {}).get('content', 'No response')
backend = data.get('orchestration', {}).get('backend', 'unknown')
latency = data.get('orchestration', {}).get('latency_ms', '?')
print(f\"Response: {content[:100]}...\")
print(f\"Backend: {backend} | Latency: {latency}ms\")
"
echo ""

# ============================================================================
# Done!
# ============================================================================

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                               ║"
echo "║              Setup Complete! 🚀                               ║"
echo "║                                                               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo "Your Zero-Trust Hybrid AI Pipeline is ready!"
echo ""
echo "Endpoints:"
echo "  • Orchestrator API:  http://localhost:8000"
echo "  • API Documentation: http://localhost:8000/docs"
echo "  • Aegis Direct:      http://${AEGIS}:8080"
echo "  • Ryzen-AI Direct: http://${RYZEN_AI}:11434"
echo ""
echo "Quick Commands:"
echo "  • Check status:      curl http://localhost:8000/backends"
echo "  • View logs:         tail -f logs/orchestrator.log"
echo "  • Stop orchestrator: kill $ORCHESTRATOR_PID"
echo ""
echo "Next Steps:"
echo "  1. Configure your AI IDE (see docs/IDE_SETUP.md)"
echo "  2. Run the demo: ./demo/run-demo.sh"
echo "  3. Read the full docs: cat README.md"
echo ""
