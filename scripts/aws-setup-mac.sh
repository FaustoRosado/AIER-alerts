#!/bin/bash
# AIER Alert System - AWS Setup Script for Mac/Linux
# This script configures AWS CLI access for team members

set -e

echo "=================================================="
echo "AIER Alert System - AWS Configuration Setup"
echo "=================================================="
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "ERROR: AWS CLI is not installed"
    echo "Please install from: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

echo "AWS CLI found: $(aws --version)"
echo ""

# Prompt for AWS credentials
echo "Please enter your AWS credentials:"
echo "(These will be provided by your team lead)"
echo ""

read -p "AWS Access Key ID: " AWS_ACCESS_KEY_ID
read -s -p "AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
echo ""
read -p "Default AWS Region [us-east-1]: " AWS_REGION
AWS_REGION=${AWS_REGION:-us-east-1}
echo ""

# Configure AWS CLI
echo "Configuring AWS CLI..."
aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID" --profile paid
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY" --profile paid
aws configure set region "$AWS_REGION" --profile paid
aws configure set output json --profile paid

# Test AWS connection
echo ""
echo "Testing AWS connectivity..."
if aws sts get-caller-identity --profile paid > /dev/null 2>&1; then
    echo "SUCCESS: AWS connection established"
    echo ""
    echo "Your AWS Identity:"
    aws sts get-caller-identity --profile paid
else
    echo "ERROR: Failed to connect to AWS"
    echo "Please verify your credentials and try again"
    exit 1
fi

# Set as default profile for this project
echo ""
echo "Setting paid profile as default for this session..."
export AWS_PROFILE=paid

# Create helper script for future sessions
cat > ~/.aier-aws-profile << 'EOF'
# AIER AWS Profile Helper
# Source this file to activate AIER AWS profile
export AWS_PROFILE=paid
echo "AWS Profile set to: paid"
EOF

chmod +x ~/.aier-aws-profile

echo ""
echo "=================================================="
echo "Setup Complete!"
echo "=================================================="
echo ""
echo "To use AIER AWS profile in future terminal sessions, run:"
echo "  source ~/.aier-aws-profile"
echo ""
echo "Or add this to your ~/.bashrc or ~/.zshrc:"
echo "  export AWS_PROFILE=paid"
echo ""
echo "Next steps:"
echo "  1. Download Kaggle dataset: python scripts/download-dataset.py"
echo "  2. Deploy infrastructure: cd terraform && terraform apply"
echo "  3. Start development servers"
echo ""
