#!/bin/bash
# ============================================================================
# Zero-Trust Hybrid AI Pipeline - Setup Distribution Script
# ============================================================================
#
# This script runs on Nexus (Mac Mini M4 Pro) and orchestrates setup of all
# machines in the distributed AI mesh.
#
# Contributors:
# - Shifty: Infrastructure setup, orchestration
# - Shay: HIPAA compliance verification, 3-tier routing
# - Javier: Integration testing, Presidio integration
#
# Features:
# 1. Checks for existing SSH keys (won't overwrite)
# 2. Tests Tailscale connectivity
# 3. Verifies SSH access
# 4. Guides key distribution
# 5. Validates inference services
# 6. Tests sensitive routing
#
# Usage:
#   chmod +x distribute-setup.sh
#   ./distribute-setup.sh
#
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Machine configuration
# Format: "Description|SSH Port|Shell Type"
declare -A MACHINES=(
    ["kali-nexus"]="Kali Linux VM (Security)|22|bash"
    ["phantom"]="Dell XPS Snapdragon (Mobile)|22|powershell"
    ["aegis"]="RTX 4080 Super (Primary Inference)|22|powershell"
    ["ryzen-ai"]="Ryzen AI 395 + 128GB (Multi-Model)|22|powershell"
)

# Service endpoints to verify
# Format: "Port|Service Name|Health Endpoint"
declare -A SERVICES=(
    ["kali-nexus"]="8080|Security API|/health"
    ["aegis"]="8080|llama-server|/health"
    ["ryzen-ai"]="11434|Ollama|/api/tags"
)

SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
SSH_PUB_KEY_PATH="$HOME/.ssh/id_ed25519.pub"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# ============================================================================
# Helper Functions
# ============================================================================

print_banner() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                                                                ║"
    echo "║     ${BOLD}Zero-Trust Hybrid AI Pipeline${NC}${CYAN}                            ║"
    echo "║     Setup & Distribution Script                                ║"
    echo "║                                                                ║"
    echo "║     Contributors: Shifty, Shay, Javier                        ║"
    echo "║                                                                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_header() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}  [✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}  [!]${NC} $1"
}

print_error() {
    echo -e "${RED}  [✗]${NC} $1"
}

print_info() {
    echo -e "${CYAN}  [i]${NC} $1"
}

wait_for_enter() {
    echo ""
    read -p "Press Enter to continue..."
}

# ============================================================================
# Step 1: SSH Key Management
# ============================================================================

manage_ssh_keys() {
    print_header "Step 1: SSH Key Management"
    
    # Ensure .ssh directory exists with correct permissions
    if [ ! -d "$HOME/.ssh" ]; then
        print_step "Creating ~/.ssh directory..."
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
    fi
    
    # Check for existing keys
    if [ -f "$SSH_KEY_PATH" ]; then
        print_warning "Existing SSH key found"
        
        # Show key details
        FINGERPRINT=$(ssh-keygen -lf "$SSH_KEY_PATH" 2>/dev/null | awk '{print $2}')
        KEY_COMMENT=$(ssh-keygen -lf "$SSH_KEY_PATH" 2>/dev/null | awk '{print $3}')
        
        print_info "Fingerprint: $FINGERPRINT"
        print_info "Comment: $KEY_COMMENT"
        
        # Check if loaded in agent
        if ssh-add -l 2>/dev/null | grep -q "$FINGERPRINT"; then
            print_success "Key is loaded in ssh-agent"
        else
            print_step "Adding key to ssh-agent..."
            eval "$(ssh-agent -s)" > /dev/null 2>&1 || true
            ssh-add "$SSH_KEY_PATH" 2>/dev/null && print_success "Key added" || print_warning "Could not add to agent"
        fi
        
        echo ""
        read -p "Use this existing key? (Y/n): " USE_EXISTING
        
        if [[ "$USE_EXISTING" =~ ^[Nn] ]]; then
            # Backup existing keys
            BACKUP_DIR="$HOME/.ssh/backup_$(date +%Y%m%d_%H%M%S)"
            print_step "Backing up existing keys to $BACKUP_DIR"
            mkdir -p "$BACKUP_DIR"
            mv "$SSH_KEY_PATH" "$BACKUP_DIR/" 2>/dev/null || true
            mv "$SSH_PUB_KEY_PATH" "$BACKUP_DIR/" 2>/dev/null || true
            print_success "Backup complete"
            
            generate_ssh_key
        else
            print_success "Using existing key"
        fi
    else
        generate_ssh_key
    fi
    
    # Display the public key
    echo ""
    echo -e "${YELLOW}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  YOUR PUBLIC KEY (copy this to other machines):                ║${NC}"
    echo -e "${YELLOW}╠════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${YELLOW}║${NC}"
    echo -e "${GREEN}$(cat "$SSH_PUB_KEY_PATH")${NC}"
    echo -e "${YELLOW}║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

generate_ssh_key() {
    print_step "Generating new ED25519 SSH key..."
    ssh-keygen -t ed25519 -C "nexus@zero-trust-ai-$(date +%Y%m%d)" -N "" -f "$SSH_KEY_PATH"
    chmod 600 "$SSH_KEY_PATH"
    chmod 644 "$SSH_PUB_KEY_PATH"
    
    # Add to agent
    eval "$(ssh-agent -s)" > /dev/null 2>&1 || true
    ssh-add "$SSH_KEY_PATH" 2>/dev/null || true
    
    print_success "SSH key generated"
}

# ============================================================================
# Step 2: Tailscale Connectivity
# ============================================================================

check_tailscale() {
    print_header "Step 2: Tailscale Network Connectivity"
    
    # Verify Tailscale is installed
    if ! command -v tailscale &> /dev/null; then
        print_error "Tailscale is not installed!"
        print_info "Install from: https://tailscale.com/download"
        exit 1
    fi
    
    # Check connection status
    TS_STATUS=$(tailscale status --json 2>/dev/null || echo '{"BackendState":"Stopped"}')
    TS_STATE=$(echo "$TS_STATUS" | grep -o '"BackendState":"[^"]*"' | cut -d'"' -f4)
    
    if [ "$TS_STATE" != "Running" ]; then
        print_error "Tailscale is not running (state: $TS_STATE)"
        print_info "Run: tailscale up"
        exit 1
    fi
    
    # Get our IP
    MY_IP=$(tailscale ip -4 2>/dev/null || echo "unknown")
    MY_HOSTNAME=$(tailscale status --self --json 2>/dev/null | grep -o '"HostName":"[^"]*"' | cut -d'"' -f4 || hostname)
    
    print_success "Tailscale is running"
    print_info "This machine: $MY_HOSTNAME ($MY_IP)"
    echo ""
    
    # Test connectivity to each machine
    print_step "Testing connectivity to all machines..."
    echo ""
    
    ALL_REACHABLE=true
    
    for machine in "${!MACHINES[@]}"; do
        IFS='|' read -r desc port shell <<< "${MACHINES[$machine]}"
        
        printf "  %-15s %-35s " "$machine" "($desc)"
        
        if ping -c 1 -W 2 "$machine" &> /dev/null; then
            MACHINE_IP=$(getent hosts "$machine" 2>/dev/null | awk '{print $1}' || echo "")
            echo -e "${GREEN}✓ Reachable${NC} ${CYAN}$MACHINE_IP${NC}"
        else
            echo -e "${RED}✗ Not reachable${NC}"
            ALL_REACHABLE=false
        fi
    done
    
    echo ""
    
    if [ "$ALL_REACHABLE" = false ]; then
        print_warning "Some machines are not reachable"
        print_info "Ensure Tailscale is running on all machines"
        read -p "Continue anyway? (y/N): " CONTINUE
        [[ ! "$CONTINUE" =~ ^[Yy] ]] && exit 1
    else
        print_success "All machines reachable via Tailscale"
    fi
}

# ============================================================================
# Step 3: SSH Connectivity Test
# ============================================================================

test_ssh_connections() {
    print_header "Step 3: SSH Connectivity Test"
    
    print_info "Testing SSH access (machines without keys will fail - that's expected)"
    echo ""
    
    declare -A SSH_STATUS
    
    for machine in "${!MACHINES[@]}"; do
        IFS='|' read -r desc port shell <<< "${MACHINES[$machine]}"
        
        printf "  %-15s " "$machine"
        
        # Test SSH with timeout
        if timeout 5 ssh -o BatchMode=yes -o ConnectTimeout=3 -o StrictHostKeyChecking=accept-new "$machine" "echo OK" 2>/dev/null | grep -q "OK"; then
            echo -e "${GREEN}✓ SSH working${NC}"
            SSH_STATUS[$machine]="ok"
            
            # Additional shell test
            if [ "$shell" = "powershell" ]; then
                if timeout 5 ssh -o BatchMode=yes "$machine" "powershell -Command 'Write-Host PS'" 2>/dev/null | grep -q "PS"; then
                    print_info "    └── PowerShell confirmed"
                fi
            fi
        else
            echo -e "${YELLOW}○ Not configured${NC}"
            SSH_STATUS[$machine]="none"
        fi
    done
    
    echo ""
    
    # Count status
    CONFIGURED=0
    for status in "${SSH_STATUS[@]}"; do
        [ "$status" = "ok" ] && ((CONFIGURED++))
    done
    
    print_info "$CONFIGURED of ${#MACHINES[@]} machines have SSH configured"
}

# ============================================================================
# Step 4: Key Distribution Instructions
# ============================================================================

show_distribution_guide() {
    print_header "Step 4: SSH Key Distribution Guide"
    
    PUBLIC_KEY=$(cat "$SSH_PUB_KEY_PATH")
    
    cat << 'EOF'
  For each machine that needs SSH configured, follow these instructions:

EOF

    echo -e "  ${YELLOW}═══ WINDOWS MACHINES (Phantom, Aegis, Ryzen-AI) ═══${NC}"
    cat << EOF

  1. Open Notepad (or VS Code) as Administrator
  
  2. Create/edit this file:
     C:\\Users\\YOUR_USERNAME\\.ssh\\authorized_keys
  
  3. Paste your public key (shown above) and save
  
  4. For admin users, ALSO add to:
     C:\\ProgramData\\ssh\\administrators_authorized_keys
     
     This file needs specific permissions:
     - Right-click > Properties > Security
     - Remove all users except Administrators and SYSTEM
     - Both should have Full Control

EOF

    echo -e "  ${YELLOW}═══ LINUX MACHINES (Kali-Nexus) ═══${NC}"
    cat << EOF

  1. Open terminal (or SSH with password initially)
  
  2. Run these commands:
  
     mkdir -p ~/.ssh
     chmod 700 ~/.ssh
     echo '$PUBLIC_KEY' >> ~/.ssh/authorized_keys
     chmod 600 ~/.ssh/authorized_keys

EOF

    wait_for_enter
}

# ============================================================================
# Step 5: Run Setup Scripts
# ============================================================================

guide_setup_scripts() {
    print_header "Step 5: Setup Script Execution Guide"
    
    echo "  Each machine needs its setup script run:"
    echo ""
    
    # Kali-Nexus
    echo -e "  ${CYAN}┌─────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "  ${CYAN}│${NC} ${BOLD}KALI-NEXUS${NC} (Kali Linux VM - Security Scanning)                  ${CYAN}│${NC}"
    echo -e "  ${CYAN}├─────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "  ${CYAN}│${NC} Script: setup-kali-nexus.sh                                      ${CYAN}│${NC}"
    echo -e "  ${CYAN}│${NC} Run:    sudo ./setup-kali-nexus.sh                               ${CYAN}│${NC}"
    echo -e "  ${CYAN}│${NC} Test:   curl http://kali-nexus:8080/health                       ${CYAN}│${NC}"
    echo -e "  ${CYAN}└─────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    # Phantom
    echo -e "  ${CYAN}┌─────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "  ${CYAN}│${NC} ${BOLD}PHANTOM${NC} (Dell XPS - Mobile Command)                             ${CYAN}│${NC}"
    echo -e "  ${CYAN}├─────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "  ${CYAN}│${NC} Script: setup-phantom.ps1                                        ${CYAN}│${NC}"
    echo -e "  ${CYAN}│${NC} Run:    Set-ExecutionPolicy Bypass -Scope Process               ${CYAN}│${NC}"
    echo -e "  ${CYAN}│${NC}         .\\setup-phantom.ps1                                     ${CYAN}│${NC}"
    echo -e "  ${CYAN}│${NC} Test:   ssh phantom                                              ${CYAN}│${NC}"
    echo -e "  ${CYAN}└─────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    # Aegis
    echo -e "  ${CYAN}┌─────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "  ${CYAN}│${NC} ${BOLD}AEGIS${NC} (RTX 4080 Super - Primary Inference via llama.cpp)        ${CYAN}│${NC}"
    echo -e "  ${CYAN}├─────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "  ${CYAN}│${NC} Script: inference-nodes/aegis/setup-aegis.ps1                    ${CYAN}│${NC}"
    echo -e "  ${CYAN}│${NC} Run:    Set-ExecutionPolicy Bypass -Scope Process               ${CYAN}│${NC}"
    echo -e "  ${CYAN}│${NC}         .\\setup-aegis.ps1                                       ${CYAN}│${NC}"
    echo -e "  ${CYAN}│${NC} Test:   curl http://aegis:8080/health                            ${CYAN}│${NC}"
    echo -e "  ${CYAN}│${NC} Note:   Downloads ~5GB model, takes 20-30 mins                   ${CYAN}│${NC}"
    echo -e "  ${CYAN}└─────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    # Ryzen-AI
    echo -e "  ${CYAN}┌─────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "  ${CYAN}│${NC} ${BOLD}RYZEN-AI${NC} (128GB RAM - Multi-Model via Ollama)                  ${CYAN}│${NC}"
    echo -e "  ${CYAN}├─────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "  ${CYAN}│${NC} Script: inference-nodes/ryzen-ai/setup-ryzen-ai.ps1          ${CYAN}│${NC}"
    echo -e "  ${CYAN}│${NC} Run:    Set-ExecutionPolicy Bypass -Scope Process               ${CYAN}│${NC}"
    echo -e "  ${CYAN}│${NC}         .\\setup-ryzen-ai.ps1                                  ${CYAN}│${NC}"
    echo -e "  ${CYAN}│${NC} Test:   curl http://ryzen-ai:11434/api/tags                    ${CYAN}│${NC}"
    echo -e "  ${CYAN}│${NC} Note:   Downloads ~20GB models, uses USB-C boot                  ${CYAN}│${NC}"
    echo -e "  ${CYAN}│${NC}         Optional RAMDisk script created on Desktop               ${CYAN}│${NC}"
    echo -e "  ${CYAN}└─────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    wait_for_enter
}

# ============================================================================
# Step 6: Final Verification
# ============================================================================

verify_setup() {
    print_header "Step 6: Final Verification"
    
    echo "  Running comprehensive tests..."
    echo ""
    
    # SSH Tests
    echo -e "  ${BOLD}SSH Connectivity:${NC}"
    
    ALL_SSH_OK=true
    for machine in "${!MACHINES[@]}"; do
        printf "    %-15s " "$machine"
        
        if timeout 5 ssh -o BatchMode=yes -o ConnectTimeout=3 "$machine" "echo OK" 2>/dev/null | grep -q "OK"; then
            echo -e "${GREEN}✓ Connected${NC}"
        else
            echo -e "${RED}✗ Failed${NC}"
            ALL_SSH_OK=false
        fi
    done
    
    echo ""
    
    # Service Tests
    echo -e "  ${BOLD}Inference Services:${NC}"
    
    for machine in "${!SERVICES[@]}"; do
        IFS='|' read -r port service endpoint <<< "${SERVICES[$machine]}"
        printf "    %-15s %-20s " "$machine" "($service)"
        
        if curl -s --connect-timeout 5 "http://$machine:$port$endpoint" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Running${NC}"
        else
            echo -e "${YELLOW}○ Not responding${NC}"
        fi
    done
    
    echo ""
    
    # Summary
    if [ "$ALL_SSH_OK" = true ]; then
        print_success "All SSH connections working!"
    else
        print_warning "Some SSH connections need attention"
    fi
}

# ============================================================================
# Step 7: Generate Summary
# ============================================================================

generate_summary() {
    print_header "Setup Complete - Summary"
    
    cat << EOF
  ${GREEN}Configuration:${NC}
    SSH Private Key: $SSH_KEY_PATH
    SSH Public Key:  $SSH_PUB_KEY_PATH
    
  ${GREEN}Machines:${NC}
EOF

    for machine in "${!MACHINES[@]}"; do
        IFS='|' read -r desc port shell <<< "${MACHINES[$machine]}"
        
        if timeout 3 ssh -o BatchMode=yes -o ConnectTimeout=2 "$machine" "exit 0" 2>/dev/null; then
            echo -e "    ${GREEN}✓${NC} $machine - $desc"
        else
            echo -e "    ${YELLOW}○${NC} $machine - $desc"
        fi
    done
    
    cat << EOF

  ${GREEN}Next Steps:${NC}
    1. Install dependencies on Nexus:
       cd $PROJECT_DIR/orchestrator
       pip install -r requirements.txt
       python -m spacy download en_core_web_lg
    
    2. Start the orchestrator:
       python main.py
    
    3. Test the API:
       curl http://localhost:8000/backends
       curl http://localhost:8000/health

  ${GREEN}For Claude Code Desktop:${NC}
    1. Open project: $PROJECT_DIR
    2. Have Claude read: PROJECT_CONTEXT.md
    3. Then follow: CLAUDE_CODE_PROMPT.md

EOF
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    print_banner
    
    echo "  This script will configure SSH connectivity between Nexus"
    echo "  and all machines in your Zero-Trust AI mesh."
    echo ""
    echo "  Machines to configure:"
    for machine in "${!MACHINES[@]}"; do
        IFS='|' read -r desc port shell <<< "${MACHINES[$machine]}"
        echo "    • $machine: $desc"
    done
    echo ""
    
    wait_for_enter
    
    manage_ssh_keys
    check_tailscale
    test_ssh_connections
    show_distribution_guide
    guide_setup_scripts
    verify_setup
    generate_summary
    
    echo ""
    print_success "Distribution script complete!"
    echo ""
}

# Run main
main "$@"
