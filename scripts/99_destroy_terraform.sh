#!/bin/bash
# AIER Alert System - Destroy Terraform Infrastructure
# WARNING: This will delete ALL resources created by Terraform

set -e

echo "=================================================="
echo "AIER Alert System - Terraform Destroy"
echo "=================================================="
echo ""
echo "⚠️  WARNING: This will DELETE all AWS resources!"
echo ""
echo "This includes:"
echo "  - S3 buckets (and all data)"
echo "  - DynamoDB tables (and all data)"
echo "  - Lambda functions"
echo "  - CloudFront distributions"
echo "  - All related resources"
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

read -p "Type 'destroy' to confirm deletion: " CONFIRM

if [ "$CONFIRM" != "destroy" ]; then
    echo "Cancelled. No resources were deleted."
    exit 0
fi

echo ""
read -p "Are you ABSOLUTELY sure? (yes/no): " CONFIRM2

if [ "$CONFIRM2" != "yes" ]; then
    echo "Cancelled. No resources were deleted."
    exit 0
fi

# Navigate to terraform directory
cd terraform

echo ""
echo "Destroying infrastructure..."
echo ""

# Destroy terraform resources
terraform destroy -auto-approve

echo ""
echo "=================================================="
echo "Infrastructure Destroyed"
echo "=================================================="
echo ""
echo "All AWS resources have been deleted."
echo ""
echo "To redeploy:"
echo "  1. bash scripts/01_init_terraform.sh"
echo "  2. bash scripts/02_plan_terraform.sh"
echo "  3. bash scripts/03_apply_terraform.sh"
echo ""
