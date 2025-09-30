#!/bin/bash
# AIER Alert System - Initialize Terraform
# Run this first to set up Terraform backend and download providers

set -e

echo "=================================================="
echo "AIER Alert System - Terraform Initialization"
echo "=================================================="
echo ""

# Check if in correct directory
if [ ! -f "terraform/main.tf" ]; then
    echo "ERROR: Please run this script from the data_viz directory"
    echo "Current directory: $(pwd)"
    exit 1
fi

# Check AWS credentials - use paid profile
if [ -z "${AWS_PROFILE:-}" ]; then
    echo "Setting AWS_PROFILE to paid..."
    export AWS_PROFILE=paid
fi

echo "Verifying AWS credentials..."
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "ERROR: AWS credentials not configured"
    echo "Run: bash scripts/aws-setup-mac.sh"
    exit 1
fi

echo "AWS credentials verified"
echo ""

# Navigate to terraform directory
cd terraform

echo "Initializing Terraform..."
echo ""

# Initialize Terraform
terraform init

echo ""
echo "=================================================="
echo "Terraform Initialization Complete!"
echo "=================================================="
echo ""
echo "Next steps:"
echo "  1. Review the plan: bash scripts/02_plan_terraform.sh"
echo "  2. Deploy infrastructure: bash scripts/03_apply_terraform.sh"
echo ""
