#!/bin/bash
# AI/ER Capstone Project - LLM Server Setup Script
# Sprint 2: Automated Server Configuration
#
# This script configures an EC2 instance as a secure LLM server
# Designed for educational purposes to demonstrate secure deployment practices

set -euo pipefail

# Logging function for audit trails
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
LOG_FILE="/var/log/aier-setup.log"

# Start logging
exec > >(tee -a "$LOG_FILE") 2>&1

log "Starting AI/ER LLM Server setup for $SERVER_NAME"

# Update system packages
log "Updating system packages..."
yum update -y || error_exit "Failed to update packages"

# Install required packages
log "Installing required packages..."
yum install -y \
    git \
    cmake \
    gcc-c++ \
    python3 \
    python3-pip \
    htop \
    wget \
    curl \
    || error_exit "Failed to install packages"

# Install Python dependencies
log "Installing Python dependencies..."
pip3 install --user flask flask-cors || error_exit "Failed to install Python packages"

# Create application user for security
log "Creating application user..."
useradd -m -s /bin/bash aier || error_exit "Failed to create user"
usermod -aG wheel aier

# Create application directories
log "Creating application directories..."
mkdir -p /opt/aier/{models,logs,src}
chown -R aier:aier /opt/aier

# Clone llama.cpp repository
log "Cloning llama.cpp repository..."
cd /opt/aier
git clone https://github.com/ggerganov/llama.cpp.git || error_exit "Failed to clone llama.cpp"

# Build llama.cpp
log "Building llama.cpp..."
cd llama.cpp
cmake -B build || error_exit "CMake configuration failed"
cmake --build build --config Release -j$(nproc) || error_exit "Build failed"

# Download a small model for demonstration (optional)
log "Downloading sample model..."
cd /opt/aier/models
# Note: In production, use secure model download methods
# wget -q https://huggingface.co/TheBloke/Llama-2-7B-GGUF/resolve/main/llama-2-7b.Q4_0.gguf || log "Model download skipped"

# Create Flask application
log "Creating Flask application..."
cat > /opt/aier/src/app.py << 'EOF'
#!/usr/bin/env python3
import os
import subprocess
import logging
from flask import Flask, request, jsonify

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)

@app.route('/')
def index():
    return "AI/ER LLM Server Running"

@app.route('/api/generate', methods=['POST'])
def generate():
    try:
        data = request.get_json()
        prompt = data.get('prompt', '')

        # Basic response for demonstration
        return jsonify({
            "success": True,
            "response": f"Processed: {prompt[:50]}...",
            "model": "demo-mode"
        })
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)
EOF

# Create systemd service
log "Creating systemd service..."
cat > /etc/systemd/system/aier-llm-server.service << EOF
[Unit]
Description=AI/ER LLM Server
After=network.target

[Service]
Type=simple
User=aier
WorkingDirectory=/opt/aier/src
ExecStart=/usr/bin/python3 /opt/aier/src/app.py
Restart=always
RestartSec=10

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/aier/logs

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=aier-llm-server

[Install]
WantedBy=multi-user.target
EOF

# Configure firewall
log "Configuring firewall..."
yum install -y firewalld || error_exit "Failed to install firewalld"
systemctl enable firewalld
systemctl start firewalld

# Allow only necessary ports
firewall-cmd --permanent --add-port=5000/tcp
firewall-cmd --permanent --add-port=22/tcp
firewall-cmd --reload

# Enable and start service
log "Enabling and starting LLM server service..."
systemctl daemon-reload
systemctl enable aier-llm-server.service
systemctl start aier-llm-server.service || error_exit "Failed to start service"

# Set up log rotation
log "Setting up log rotation..."
cat > /etc/logrotate.d/aier-llm-server << EOF
/opt/aier/logs/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 aier aier
}
EOF

# Create basic health check script
log "Creating health check script..."
cat > /opt/aier/health_check.sh << 'EOF'
#!/bin/bash
# Simple health check for AI/ER LLM Server

SERVER_URL="http://localhost:5000"

# Check if service is running
if ! systemctl is-active --quiet aier-llm-server; then
    echo "Service not running"
    exit 1
fi

# Check if port is accessible
if ! curl -s --max-time 5 "$SERVER_URL" > /dev/null; then
    echo "Service not responding"
    exit 1
fi

echo "Service is healthy"
exit 0
EOF

chmod +x /opt/aier/health_check.sh

# Set up cron job for health checks
echo "*/5 * * * * /opt/aier/health_check.sh >> /opt/aier/logs/health.log 2>&1" | crontab -u aier -

log "AI/ER LLM Server setup completed successfully"

# Final status
systemctl status aier-llm-server.service --no-pager
log "Setup complete. Server accessible at http://$(hostname -I | awk '{print $1}'):5000"
