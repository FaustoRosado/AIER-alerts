#!/bin/bash
# AI/ER Capstone Project - AWS Deployment Script for macOS
# Sprint 2: AWS Infrastructure Deployment Integration
#
# This script handles AWS deployment of the AI/ER infrastructure
# Designed for demonstration and production deployment

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
TERRAFORM_DIR="terraform"
SSH_KEY_NAME="aier-capstone-key"
AWS_REGION="${AWS_REGION:-us-east-1}"
PROJECT_NAME="${PROJECT_NAME:-aier-capstone}"

# Check AWS CLI and authentication
check_aws_setup() {
    log_info "Checking AWS setup..."

    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed."
        log_info "Please install AWS CLI:"
        log_info "https://aws.amazon.com/cli/"
        exit 1
    fi

    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured or invalid."
        log_info "Please configure AWS credentials:"
        log_info "aws configure"
        exit 1
    fi

    # Get account info
    local account_id
    account_id=$(aws sts get-caller-identity --query Account --output text)

    log_success "AWS setup verified"
    log_info "  • Account ID: $account_id"
    log_info "  • Region: $AWS_REGION"
    log_info "  • Project: $PROJECT_NAME"
}

# Check Terraform installation
check_terraform() {
    log_info "Checking Terraform installation..."

    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed."
        log_info "Please install Terraform:"
        log_info "https://www.terraform.io/downloads"
        exit 1
    fi

    local tf_version
    tf_version=$(terraform version -json | jq -r '.terraform_version' 2>/dev/null || echo "unknown")
    log_success "Terraform installed: $tf_version"
}

# Setup SSH key for EC2 access
setup_ssh_key() {
    log_info "Setting up SSH key for EC2 access..."

    local key_file="$HOME/.ssh/$SSH_KEY_NAME"

    # Check if key already exists
    if [[ -f "$key_file" ]]; then
        log_warning "SSH key already exists: $key_file"
        return 0
    fi

    # Generate SSH key
    ssh-keygen -t rsa -b 4096 -f "$key_file" -N "" -C "AI/ER Capstone SSH Key"

    if [[ ! -f "$key_file" ]]; then
        error_exit "Failed to generate SSH key"
    fi

    # Import key to AWS
    log_info "Importing SSH key to AWS..."
    aws ec2 import-key-pair \
        --key-name "$SSH_KEY_NAME" \
        --public-key-material "fileb://$key_file.pub" \
        --region "$AWS_REGION" || error_exit "Failed to import SSH key to AWS"

    log_success "SSH key setup complete"
    log_info "  • Private key: $key_file"
    log_info "  • Public key: $key_file.pub"
    log_info "  • AWS key name: $SSH_KEY_NAME"
}

# Initialize and validate Terraform
init_terraform() {
    log_info "Initializing Terraform..."

    cd "$TERRAFORM_DIR"

    # Initialize Terraform
    terraform init || error_exit "Terraform initialization failed"

    # Validate configuration
    terraform validate || error_exit "Terraform validation failed"

    # Format check
    if terraform fmt --check --recursive; then
        log_success "Terraform format check passed"
    else
        log_warning "Terraform formatting issues found. Running terraform fmt..."
        terraform fmt --recursive
    fi

    cd - > /dev/null
}

# Plan infrastructure deployment
plan_deployment() {
    log_info "Planning infrastructure deployment..."

    cd "$TERRAFORM_DIR"

    # Generate deployment plan
    terraform plan \
        -var "aws_region=$AWS_REGION" \
        -var "project_name=$PROJECT_NAME" \
        -var "environment=sandbox" \
        -out=tfplan || error_exit "Terraform plan failed"

    # Show plan summary
    log_info "Infrastructure plan generated:"
    terraform show -json tfplan | jq -r '.resource_changes[]? | select(.change.actions[0] != "no-op") | "- \(.change.actions[0] | ascii_upcase): \(.address)"' || true

    cd - > /dev/null
}

# Deploy infrastructure
deploy_infrastructure() {
    log_info "Deploying infrastructure to AWS..."

    cd "$TERRAFORM_DIR"

    # Apply the plan
    terraform apply -auto-approve tfplan || error_exit "Infrastructure deployment failed"

    # Show deployment outputs
    log_success "Infrastructure deployed successfully!"
    log_info ""
    log_info "📋 Deployment Outputs:"

    terraform output -json | jq -r 'to_entries[] | "  \(.key): \(.value.value)"'

    cd - > /dev/null
}

# Test infrastructure deployment
test_infrastructure() {
    log_info "Testing infrastructure deployment..."

    cd "$TERRAFORM_DIR"

    # Get bastion host IP
    local bastion_ip
    bastion_ip=$(terraform output -raw bastion_public_ip 2>/dev/null || echo "")

    if [[ -n "$bastion_ip" ]]; then
        log_success "✓ Bastion host accessible at: $bastion_ip"

        # Test SSH connectivity (without actually connecting)
        if nc -z -w5 "$bastion_ip" 22; then
            log_success "✓ SSH port accessible on bastion host"
        else
            log_warning "⚠ SSH port not accessible (may be behind security group)"
        fi
    else
        log_error "✗ Could not retrieve bastion host IP"
    fi

    # Get LLM server private IP
    local llm_private_ip
    llm_private_ip=$(terraform output -raw llm_server_private_ip 2>/dev/null || echo "")

    if [[ -n "$llm_private_ip" ]]; then
        log_success "✓ LLM server configured with private IP: $llm_private_ip"
    else
        log_error "✗ Could not retrieve LLM server private IP"
    fi

    cd - > /dev/null
}

# Show infrastructure status
show_infrastructure_status() {
    log_info "Infrastructure Status:"

    cd "$TERRAFORM_DIR"

    # Show Terraform state
    if terraform show &>/dev/null; then
        log_success "✓ Terraform state: Active"

        # Show resource status
        log_info "📊 Resource Status:"
        terraform state list | head -10

        # Show outputs
        log_info ""
        log_info "🔧 Infrastructure Outputs:"
        terraform output || log_warning "No outputs available"
    else
        log_error "✗ No Terraform state found"
    fi

    cd - > /dev/null
}

# Cleanup infrastructure
cleanup_infrastructure() {
    log_warning "This will destroy all AWS resources created by this deployment!"
    read -p "Are you sure you want to continue? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log_info "Cleanup cancelled"
        return 0
    fi

    log_info "Destroying infrastructure..."

    cd "$TERRAFORM_DIR"

    # Destroy infrastructure
    terraform destroy -auto-approve || error_exit "Infrastructure cleanup failed"

    log_success "Infrastructure cleanup completed"

    cd - > /dev/null
}

# Create connection script for accessing deployed resources
create_connection_script() {
    log_info "Creating connection script..."

    cd "$TERRAFORM_DIR"

    local bastion_ip
    bastion_ip=$(terraform output -raw bastion_public_ip 2>/dev/null || echo "")

    if [[ -n "$bastion_ip" ]]; then
        # Create SSH connection script
        cat > "../scripts/mac/connect-to-llm-server.sh" << EOF
#!/bin/bash
# AI/ER Capstone Project - LLM Server Connection Script
# Generated for deployment in $AWS_REGION

set -euo pipefail

B ASTION_HOST="$bastion_ip"
LLM_SERVER_IP="$(terraform output -raw llm_server_private_ip)"
SSH_KEY="$HOME/.ssh/$SSH_KEY_NAME"

log_info() {
    echo -e "\${BLUE}[INFO]\${NC} \$*"
}

log_success() {
    echo -e "\${GREEN}[SUCCESS]\${NC} \$*"
}

log_error() {
    echo -e "\${RED}[ERROR]\${NC} \$*"
}

if [[ ! -f "\$SSH_KEY" ]]; then
    log_error "SSH key not found: \$SSH_KEY"
    log_info "Please run the setup script first"
    exit 1
fi

log_info "Connecting to LLM server through bastion host..."
log_info "  • Bastion: \$BASTION_HOST"
log_info "  • Target: \$LLM_SERVER_IP"

# Connect using SSH agent forwarding
ssh -A -J ec2-user@\$BASTION_HOST ec2-user@\$LLM_SERVER_IP

log_success "Connection established!"
EOF

        chmod +x "../scripts/mac/connect-to-llm-server.sh"

        log_success "Connection script created: scripts/mac/connect-to-llm-server.sh"

        cd - > /dev/null
    else
        log_warning "Could not create connection script (bastion IP not available)"
    fi
}

# Main deployment function
deploy_aws() {
    log_info "🚀 Starting AI/ER AWS Infrastructure Deployment"
    log_info "This will deploy real AWS resources (costs may apply)"

    check_aws_setup
    check_terraform
    setup_ssh_key
    init_terraform
    plan_deployment

    log_warning "About to deploy real AWS infrastructure!"
    read -p "Do you want to continue with deployment? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log_info "Deployment cancelled"
        return 0
    fi

    deploy_infrastructure
    test_infrastructure
    create_connection_script

    log_success "🎉 AWS infrastructure deployment completed!"
    log_info ""
    show_infrastructure_status
}

# Main function
main() {
    local action="${1:-deploy}"

    case "$action" in
        "deploy")
            deploy_aws
            ;;
        "plan")
            check_aws_setup
            check_terraform
            setup_ssh_key
            init_terraform
            plan_deployment
            ;;
        "apply")
            check_aws_setup
            check_terraform
            cd "$TERRAFORM_DIR"
            deploy_infrastructure
            test_infrastructure
            create_connection_script
            cd - > /dev/null
            ;;
        "status")
            check_aws_setup
            show_infrastructure_status
            ;;
        "test")
            check_aws_setup
            test_infrastructure
            ;;
        "cleanup")
            check_aws_setup
            cleanup_infrastructure
            ;;
        "connect")
            local script_path="scripts/mac/connect-to-llm-server.sh"
            if [[ -f "$script_path" ]]; then
                exec "$script_path"
            else
                log_error "Connection script not found. Run deploy first."
                exit 1
            fi
            ;;
        *)
            echo "Usage: $0 {deploy|plan|apply|status|test|cleanup|connect}"
            echo ""
            echo "Commands:"
            echo "  deploy  - Complete AWS infrastructure deployment"
            echo "  plan    - Generate deployment plan only"
            echo "  apply   - Apply planned infrastructure"
            echo "  status  - Show infrastructure status"
            echo "  test    - Test infrastructure functionality"
            echo "  cleanup - Destroy all AWS resources"
            echo "  connect - Connect to deployed LLM server"
            echo ""
            echo "Environment Variables:"
            echo "  AWS_REGION=region    # AWS region (default: us-east-1)"
            echo "  PROJECT_NAME=name    # Project name (default: aier-capstone)"
            echo ""
            echo "Examples:"
            echo "  $0 deploy           # Complete deployment"
            echo "  $0 plan             # Review what will be deployed"
            echo "  AWS_REGION=us-west-2 $0 deploy"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
