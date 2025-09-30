#!/bin/bash
# AIER Alert System - Plan Terraform Changes
# Review what will be created/modified before applying

set -e

echo "=================================================="
echo "AIER Alert System - Terraform Plan"
echo "=================================================="
echo ""

# Check if in correct directory
if [ ! -f "terraform/main.tf" ]; then
    echo "ERROR: Please run this script from the data_viz directory"
    exit 1
fi

# Check AWS credentials - use paid profile
if [ -z "${AWS_PROFILE:-}" ]; then
    export AWS_PROFILE=paid
fi

# Navigate to terraform directory
cd terraform

echo "Generating Terraform plan..."
echo ""

# Run terraform plan
terraform plan -out=tfplan

echo ""
echo "=================================================="
echo "Terraform Plan Generated"
echo "=================================================="
echo ""
echo "Review the plan above carefully."
echo ""
echo "The plan shows:"
echo "  + Resources to be CREATED"
echo "  ~ Resources to be MODIFIED"
echo "  - Resources to be DESTROYED"
echo ""
echo "Next step:"
echo "  - If plan looks good: bash scripts/03_apply_terraform.sh"
echo "  - If changes needed: Edit terraform/*.tf files"
echo ""
