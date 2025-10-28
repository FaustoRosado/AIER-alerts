#!/bin/bash
# Tailscale Setup Script for Linux/macOS
# Purpose: Install and configure Tailscale with subnet routing capabilities
# Usage: sudo ./setup-tailscale.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    print_error "This script must be run as root (use sudo)"
    echo "Run: sudo ./setup-tailscale.sh"
    exit 1
fi

print_info "Starting Tailscale installation and configuration"

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
else
    print_error "Cannot detect OS. /etc/os-release not found"
    exit 1
fi

print_info "Detected OS: $OS $VERSION"

# Install Tailscale based on OS
install_tailscale() {
    print_info "Installing Tailscale..."
    
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        curl -fsSL https://tailscale.com/install.sh | sh
    elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ] || [ "$OS" = "amzn" ]; then
        curl -fsSL https://tailscale.com/install.sh | sh
    elif [ "$OS" = "darwin" ]; then
        print_info "macOS detected. Install via: brew install tailscale"
        exit 0
    else
        print_error "Unsupported OS: $OS"
        exit 1
    fi
    
    print_info "Tailscale installed successfully"
}

# Enable IP forwarding for subnet routing
enable_ip_forwarding() {
    print_info "Enabling IP forwarding for subnet routing..."
    
    echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf > /dev/null
    echo 'net.ipv6.conf.all.forwarding = 1' | tee -a /etc/sysctl.conf > /dev/null
    
    sysctl -p /etc/sysctl.conf > /dev/null
    
    print_info "IP forwarding enabled"
}

# Configure firewall (if applicable)
configure_firewall() {
    print_info "Checking firewall configuration..."
    
    if command -v ufw &> /dev/null; then
        print_info "UFW detected, allowing Tailscale..."
        ufw allow 41641/udp comment 'Tailscale'
    elif command -v firewall-cmd &> /dev/null; then
        print_info "firewalld detected, allowing Tailscale..."
        firewall-cmd --permanent --add-port=41641/udp
        firewall-cmd --reload
    else
        print_warning "No firewall detected or firewall not managed by script"
    fi
}

# Prompt for configuration
configure_tailscale() {
    print_info "Tailscale configuration options:"
    echo ""
    echo "You will need:"
    echo "  1. Tailscale auth key (from https://login.tailscale.com/admin/settings/keys)"
    echo "  2. Subnet routes to advertise (e.g., 10.0.0.0/16)"
    echo "  3. Device tags (e.g., tag:aws-subnet-router)"
    echo ""
    
    read -p "Enter Tailscale auth key: " AUTH_KEY
    read -p "Enter subnet routes to advertise (comma-separated): " SUBNET_ROUTES
    read -p "Enter device tags (comma-separated): " DEVICE_TAGS
    
    print_info "Starting Tailscale with configuration..."
    
    tailscale up \
        --authkey="${AUTH_KEY}" \
        --advertise-routes="${SUBNET_ROUTES}" \
        --advertise-tags="${DEVICE_TAGS}" \
        --accept-dns=false \
        --ssh
    
    print_info "Tailscale started successfully"
}

# Enable and start service
enable_service() {
    print_info "Enabling Tailscale service..."
    
    systemctl enable tailscaled
    systemctl start tailscaled
    
    print_info "Tailscale service enabled and started"
}

# Verify installation
verify_installation() {
    print_info "Verifying Tailscale installation..."
    
    if tailscale status &> /dev/null; then
        print_info "Tailscale is running"
        echo ""
        tailscale status
    else
        print_error "Tailscale is not running properly"
        exit 1
    fi
}

# Main execution
main() {
    install_tailscale
    enable_ip_forwarding
    configure_firewall
    enable_service
    
    echo ""
    read -p "Do you want to configure Tailscale now? (y/n): " CONFIGURE
    
    if [ "$CONFIGURE" = "y" ] || [ "$CONFIGURE" = "Y" ]; then
        configure_tailscale
        verify_installation
    else
        print_info "Skipping configuration. Run 'sudo tailscale up' to configure later"
    fi
    
    echo ""
    print_info "Setup complete!"
    print_info "Next steps:"
    echo "  1. If you haven't configured yet, run: sudo tailscale up --authkey=YOUR_KEY"
    echo "  2. Verify connection: tailscale status"
    echo "  3. Check IP: tailscale ip"
}

main


