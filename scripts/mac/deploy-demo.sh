#!/bin/bash
# AI/ER Capstone Project - Deployment Simulation Script for macOS
# Sprint 2: Deployment Simulation and Demonstration
#
# This script simulates the deployment process and creates
# demonstration assets for showcasing the AI/ER system

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Configuration
DEMO_DIR="demo-assets"
SCREENSHOT_DIR="$DEMO_DIR/screenshots"
LOG_DIR="$DEMO_DIR/logs"

# Create demo directories
setup_demo_directories() {
    log_info "Setting up demo directories..."

    mkdir -p "$SCREENSHOT_DIR" "$LOG_DIR"

    # Create demo metadata
    cat > "$DEMO_DIR/README.md" << 'EOF'
# AI/ER Capstone Project - Demo Assets

This directory contains assets for demonstrating the AI/ER system:

## Contents

- `screenshots/` - Interface screenshots for documentation
- `logs/` - Sample log files showing system operation
- `deployment-simulation.log` - Record of deployment simulation
- `demo-config.json` - Configuration used for demo

## Demo Scenarios

1. **Local Development**: Show local LLM server running
2. **Infrastructure as Code**: Demonstrate Terraform deployment
3. **CI/CD Pipeline**: Show automated testing and deployment
4. **Security Features**: Highlight security controls and monitoring

## Usage

Run the demo simulation:
```bash
./scripts/mac/deploy-demo.sh
```

This creates all demo assets without requiring actual infrastructure deployment.
EOF

    log_success "Demo directories created"
}

# Simulate Terraform deployment
simulate_terraform_deployment() {
    log_info "Simulating Terraform deployment..."

    # Create fake Terraform output
    mkdir -p "$DEMO_DIR/terraform-output"

    cat > "$DEMO_DIR/terraform-output/terraform.tfstate" << 'EOF'
{
  "version": 4,
  "terraform_version": "1.5.0",
  "serial": 1,
  "lineage": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "outputs": {
    "vpc_id": {
      "value": "vpc-1234567890abcdef0",
      "type": "string"
    },
    "llm_server_instance_id": {
      "value": "i-1234567890abcdef0",
      "type": "string"
    }
  },
  "resources": [
    {
      "mode": "managed",
      "type": "aws_instance",
      "name": "llm_server",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 1,
          "attributes": {
            "ami": "ami-12345678",
            "instance_type": "t3.medium",
            "private_ip": "10.0.101.100",
            "public_ip": null,
            "tags": {
              "Name": "aier-llm-server",
              "Environment": "sandbox"
            }
          }
        }
      ]
    }
  ]
}
EOF

    # Simulate deployment steps
    log_info "  → Initializing Terraform..."
    sleep 2
    log_success "  ✓ Terraform initialized"

    log_info "  → Planning infrastructure..."
    sleep 3
    log_success "  ✓ Infrastructure planned (15 resources)"

    log_info "  → Applying configuration..."
    sleep 4
    log_success "  ✓ Infrastructure deployed successfully"

    # Create deployment log
    cat > "$DEMO_DIR/deployment-simulation.log" << 'EOF'
[2025-10-13 14:30:00] Starting deployment simulation
[2025-10-13 14:30:02] Terraform initialized
[2025-10-13 14:30:05] Infrastructure plan generated
[2025-10-13 14:30:05] Plan: 15 to add, 0 to change, 0 to destroy
[2025-10-13 14:30:09] Applying infrastructure changes
[2025-10-13 14:30:13] Infrastructure deployed successfully
[2025-10-13 14:30:13] Cost estimate: $75.00/month
[2025-10-13 14:30:13] Security scan: PASSED
[2025-10-13 14:30:13] Deployment completed
EOF

    log_success "Terraform deployment simulation complete"
}

# Create sample log files
create_sample_logs() {
    log_info "Creating sample log files..."

    # Server logs
    cat > "$LOG_DIR/server-access.log" << 'EOF'
127.0.0.1 - - [13/Oct/2025:14:30:15 -0400] "GET / HTTP/1.1" 200 1234
127.0.0.1 - - [13/Oct/2025:14:30:16 -0400] "GET /static/css/styles.css HTTP/1.1" 200 5678
127.0.0.1 - - [13/Oct/2025:14:30:17 -0400] "GET /static/js/app.js HTTP/1.1" 200 9012
127.0.0.1 - - [13/Oct/2025:14:30:18 -0400] "POST /api/generate HTTP/1.1" 200 345
127.0.0.1 - - [13/Oct/2025:14:30:19 -0400] "GET /health HTTP/1.1" 200 89
EOF

    # Application logs
    cat > "$LOG_DIR/application.log" << 'EOF'
[2025-10-13 14:30:15] INFO: AI/ER LLM Server starting on 127.0.0.1:5000
[2025-10-13 14:30:15] INFO: Loading model: llama-7b-q4_0.gguf
[2025-10-13 14:30:16] INFO: Model loaded successfully
[2025-10-13 14:30:16] INFO: Server ready for requests
[2025-10-13 14:30:18] INFO: API request processed - Success: True, Tokens: 25
[2025-10-13 14:30:19] INFO: Health check requested
EOF

    # Security logs
    cat > "$LOG_DIR/security.log" << 'EOF'
[2025-10-13 14:30:15] INFO: Security module initialized
[2025-10-13 14:30:15] INFO: Input validation enabled
[2025-10-13 14:30:15] INFO: XSS protection active
[2025-10-13 14:30:15] INFO: Rate limiting configured
[2025-10-13 14:30:18] INFO: Prompt validation passed: "cybersecurity best practices"
[2025-10-13 14:30:18] INFO: Response generated successfully
EOF

    # Error logs (minimal for demo)
    cat > "$LOG_DIR/error.log" << 'EOF'
[2025-10-13 14:30:20] WARNING: Model response truncated (limit: 150 tokens)
[2025-10-13 14:30:21] INFO: Rate limit applied (10 requests/minute)
EOF

    log_success "Sample log files created"
}

# Create demo configuration
create_demo_config() {
    log_info "Creating demo configuration..."

    cat > "$DEMO_DIR/demo-config.json" << 'EOF'
{
  "project": {
    "name": "AI/ER Capstone Project",
    "version": "2.0.0-sprint2",
    "description": "Local LLM Emergency Response System"
  },
  "deployment": {
    "environment": "sandbox",
    "region": "us-east-1",
    "timestamp": "2025-10-13T14:30:00Z"
  },
  "infrastructure": {
    "vpc_id": "vpc-1234567890abcdef0",
    "llm_server_private_ip": "10.0.101.100",
    "bastion_public_ip": "1.2.3.4"
  },
  "security": {
    "encryption_enabled": true,
    "access_logging": true,
    "threat_detection": true,
    "compliance_framework": "none"
  },
  "monitoring": {
    "health_checks": true,
    "log_aggregation": true,
    "alerting": true
  },
  "demo_features": [
    "Local LLM integration",
    "Infrastructure as Code",
    "CI/CD pipeline",
    "Security controls",
    "Real-time monitoring"
  ]
}
EOF

    log_success "Demo configuration created"
}

# Simulate CI/CD pipeline
simulate_cicd_pipeline() {
    log_info "Simulating CI/CD pipeline execution..."

    # Create pipeline log
    cat > "$DEMO_DIR/pipeline-execution.log" << 'EOF'
[2025-10-13 14:25:00] Starting GitHub Actions pipeline
[2025-10-13 14:25:01] Checking out code (commit: efd2d40)
[2025-10-13 14:25:05] Setting up Terraform 1.5.0
[2025-10-13 14:25:06] Running terraform fmt --check
[2025-10-13 14:25:07] Terraform format check: PASSED
[2025-10-13 14:25:10] Running terraform validate
[2025-10-13 14:25:11] Terraform validation: PASSED
[2025-10-13 14:25:15] Running terraform plan
[2025-10-13 14:25:18] Infrastructure plan generated
[2025-10-13 14:25:18] Plan: 15 to add, 0 to change, 0 to destroy
[2025-10-13 14:25:20] Running security scan with Checkov
[2025-10-13 14:25:25] Security scan: PASSED
[2025-10-13 14:25:25] All checks passed
[2025-10-13 14:25:25] Pipeline completed successfully
EOF

    log_success "CI/CD pipeline simulation complete"
}

# Create demonstration script
create_demo_script() {
    log_info "Creating interactive demo script..."

    cat > "$DEMO_DIR/run-demo.sh" << 'EOF'
#!/bin/bash
# AI/ER Interactive Demo Script

echo "🎉 Welcome to AI/ER Capstone Project Demo"
echo ""
echo "This demo showcases:"
echo "• Local LLM integration with llama.cpp"
echo "• Infrastructure as Code with Terraform"
echo "• CI/CD pipeline with GitHub Actions"
echo "• Security-first architecture"
echo ""

read -p "Press Enter to start the demo..."

echo ""
echo "📋 Demo Steps:"
echo "1. Starting local development server..."
echo "2. Showing infrastructure deployment..."
echo "3. Demonstrating security features..."
echo "4. Running integration tests..."

# Simulate server startup
echo ""
echo "🚀 Starting AI/ER LLM Server..."
sleep 2
echo "✅ Server started successfully"
echo "🌐 Access at: http://localhost:5000"

# Simulate infrastructure
echo ""
echo "🏗️ Infrastructure Status:"
echo "✅ VPC: vpc-1234567890abcdef0"
echo "✅ LLM Server: i-1234567890abcdef0 (10.0.101.100)"
echo "✅ Bastion Host: i-0987654321fedcba0 (1.2.3.4)"
echo "✅ Security Groups: Configured"
echo "✅ NAT Gateway: Active"

# Simulate security checks
echo ""
echo "🔒 Security Validation:"
echo "✅ Input validation: Active"
echo "✅ XSS protection: Enabled"
echo "✅ Access logging: Operational"
echo "✅ Encryption: Configured"

echo ""
echo "🎯 Demo complete! All systems operational."
echo ""
echo "📚 For more information, see:"
echo "• README.md - Project documentation"
echo "• DEPLOYMENT_EVIDENCE.md - Technical details"
echo "• SPRINT2_TEAM_CONTRIBUTIONS.md - Team work"
EOF

    chmod +x "$DEMO_DIR/run-demo.sh"

    log_success "Interactive demo script created"
}

# Main deployment simulation function
simulate_deployment() {
    log_info "🚀 Starting AI/ER Deployment Simulation"
    log_info "This creates demo assets for showcasing without real deployment"

    setup_demo_directories
    simulate_terraform_deployment
    create_sample_logs
    create_demo_config
    simulate_cicd_pipeline
    create_demo_script

    log_success "🎉 Deployment simulation completed!"
    log_info ""
    log_info "Demo assets created in: $DEMO_DIR/"
    log_info ""
    log_info "To run the interactive demo:"
    log_info "  $DEMO_DIR/run-demo.sh"
    log_info ""
    log_info "To view deployment evidence:"
    log_info "  cat $DEMO_DIR/deployment-simulation.log"
    log_info ""
    log_info "For a complete walkthrough, see DEPLOYMENT_EVIDENCE.md"
}

# Main function
main() {
    local action="${1:-simulate}"

    case "$action" in
        "simulate")
            simulate_deployment
            ;;
        "clean")
            log_info "Cleaning demo assets..."
            rm -rf "$DEMO_DIR"
            log_success "Demo assets cleaned"
            ;;
        "status")
            if [[ -d "$DEMO_DIR" ]]; then
                log_success "Demo assets exist in: $DEMO_DIR/"
                ls -la "$DEMO_DIR/"
            else
                log_warning "No demo assets found"
            fi
            ;;
        *)
            echo "Usage: $0 {simulate|clean|status}"
            echo ""
            echo "Commands:"
            echo "  simulate - Create deployment simulation and demo assets"
            echo "  clean    - Remove all demo assets"
            echo "  status   - Show status of demo assets"
            echo ""
            echo "Examples:"
            echo "  $0 simulate  # Create demo for presentation"
            echo "  $0 status    # Check demo assets"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
