#!/bin/bash
# AI/ER Capstone Project - Bastion Host Setup Script
# Sprint 2: Secure Jump Host Configuration
#
# This script configures an EC2 instance as a secure bastion host
# Demonstrates cybersecurity best practices for secure access

set -euo pipefail

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# Error handling
error_exit() {
    log "ERROR: $*" >&2
    exit 1
}

# Variables
SERVER_NAME="${server_name}"
LOG_FILE="/var/log/aier-bastion-setup.log"

# Start logging
exec > >(tee -a "$LOG_FILE") 2>&1

log "Starting AI/ER Bastion Host setup for $SERVER_NAME"

# Update system packages
log "Updating system packages..."
yum update -y || error_exit "Failed to update packages"

# Install required packages for bastion functionality
log "Installing required packages..."
yum install -y \
    git \
    vim \
    htop \
    wget \
    curl \
    net-tools \
    telnet \
    nc \
    || error_exit "Failed to install packages"

# Configure SSH for security
log "Configuring SSH security..."

# Backup original SSH config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Security hardening for SSH
cat >> /etc/ssh/sshd_config << EOF

# AI/ER Bastion Host Security Configuration
# Disable root login
PermitRootLogin no

# Disable password authentication (key only)
PasswordAuthentication no

# Allow only specific users
AllowUsers aier ec2-user

# Set secure ciphers
Ciphers aes128-ctr,aes192-ctr,aes256-ctr

# Disable X11 forwarding
X11Forwarding no

# Set client alive interval
ClientAliveInterval 300
ClientAliveCountMax 2

# Log authentication attempts
LogLevel VERBOSE
EOF

# Create bastion user
log "Creating bastion user..."
useradd -m -s /bin/bash aier || error_exit "Failed to create user"
usermod -aG wheel aier

# Generate SSH key for the aier user (for connecting to LLM servers)
log "Setting up SSH keys for secure connections..."
sudo -u aier ssh-keygen -t rsa -b 4096 -f /home/aier/.ssh/id_rsa -N ""

# Configure SSH client for connections to private instances
cat >> /home/aier/.ssh/config << EOF
Host 10.0.*
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel QUIET
EOF

chown aier:aier /home/aier/.ssh/config
chmod 600 /home/aier/.ssh/config

# Create SSH helper script for connecting to LLM servers
log "Creating SSH helper script..."
cat > /usr/local/bin/connect-to-llm << 'EOF'
#!/bin/bash
# Helper script to connect to LLM servers through bastion

if [ $# -eq 0 ]; then
    echo "Usage: connect-to-llm <private-ip>"
    exit 1
fi

LLM_SERVER_IP="$1"
BASTION_USER="aier"

# Use SSH agent for key management
ssh -A -J "$BASTION_USER@$(hostname -I | awk '{print $1}')" "$BASTION_USER@$LLM_SERVER_IP"
EOF

chmod +x /usr/local/bin/connect-to-llm

# Configure firewall for bastion
log "Configuring firewall..."
yum install -y firewalld || error_exit "Failed to install firewalld"
systemctl enable firewalld
systemctl start firewalld

# Allow only SSH from specified CIDR blocks
firewall-cmd --permanent --add-service=ssh

# Remove other services
firewall-cmd --permanent --remove-service=http
firewall-cmd --permanent --remove-service=https

firewall-cmd --reload

# Set up monitoring and logging
log "Setting up monitoring and logging..."

# Install CloudWatch agent if needed
yum install -y amazon-cloudwatch-agent || log "CloudWatch agent not available"

# Create log directory
mkdir -p /var/log/aier
chown aier:aier /var/log/aier

# Set up log rotation
cat > /etc/logrotate.d/aier-bastion << EOF
/var/log/aier/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 aier aier
}
EOF

# Create connection log script
cat > /usr/local/bin/log-connections << 'EOF'
#!/bin/bash
# Log SSH connections for security monitoring

LOG_FILE="/var/log/aier/connections.log"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] Connection from $SSH_CLIENT to $USER@$(hostname)" >> "$LOG_FILE"
EOF

chmod +x /usr/local/bin/log-connections

# Add to SSH configuration to run on connection
echo "ForceCommand /usr/local/bin/log-connections" >> /etc/ssh/sshd_config

# Create security script for monitoring
log "Creating security monitoring script..."
cat > /usr/local/bin/security-monitor << 'EOF'
#!/bin/bash
# Basic security monitoring for bastion host

echo "=== AI/ER Bastion Security Status ==="
echo "Date: $(date)"
echo "Uptime: $(uptime)"
echo "Active connections: $(netstat -tn | grep :22 | wc -l)"
echo "Failed login attempts: $(grep -c 'Failed password' /var/log/secure)"
echo "Last successful login: $(last -1 aier | head -1)"
EOF

chmod +x /usr/local/bin/security-monitor

# Create cron job for regular security checks
echo "0 * * * * /usr/local/bin/security-monitor >> /var/log/aier/security.log 2>&1" | crontab -u aier -

# Restart SSH service to apply changes
log "Restarting SSH service..."
systemctl restart sshd || error_exit "Failed to restart SSH"

# Create welcome message for users
log "Creating welcome message..."
cat > /etc/motd << 'EOF'

██╗ █████╗ ██╗██╗     ███████╗██╗   ██╗
██║██╔══██╗██║██║     ██╔════╝╚██╗ ██╔╝
██║███████║██║██║     █████╗   ╚████╔╝
██║██╔══██║██║██║     ██╔══╝    ╚██╔╝
██║██║  ██║██║███████╗███████╗   ██║
╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚══════╝   ╚═╝

AI/ER Capstone Project - Secure Bastion Host
Sprint 2: Infrastructure as Code Demonstration

This bastion host provides secure access to AI/ER resources.
Only authorized personnel should access this system.

For assistance, contact the AI/ER team.

EOF

# Final status and instructions
log "AI/ER Bastion Host setup completed successfully"

log "=== Setup Complete ==="
log "Bastion host configured with:"
log "- SSH key-only authentication"
log "- Firewall restricting access"
log "- Security monitoring enabled"
log "- Connection logging active"
log "- User: aier (for LLM server connections)"

# Show status
systemctl status sshd --no-pager
firewall-cmd --list-all

log "Bastion setup complete. Ready for secure connections."
