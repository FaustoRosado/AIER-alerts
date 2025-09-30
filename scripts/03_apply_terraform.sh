#!/bin/bash
# AIER Alert System - Apply Terraform Changes
# Deploy the infrastructure to AWS

set -e

echo "=================================================="
echo "AIER Alert System - Terraform Apply"
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

echo "WARNING: This will create AWS resources (costs may apply)"
echo ""
read -p "Do you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "Applying Terraform configuration..."
echo ""

# Apply terraform
terraform apply

echo ""
echo "=================================================="
echo "Terraform Apply Complete!"
echo "=================================================="
echo ""
echo "Infrastructure deployed successfully."
echo ""
echo "Next steps:"
echo "  1. Verify deployment: bash scripts/04_verify_deployment.sh"
echo "  2. View in console: bash scripts/00_console_view_link.sh"
echo "  3. Upload data: python scripts/data-pipeline.py --upload"
echo ""

# Save outputs to file
echo "Saving Terraform outputs..."
terraform output -json > ../config/terraform-outputs.json 2>/dev/null || mkdir -p ../config && terraform output -json > ../config/terraform-outputs.json

echo "Outputs saved to: config/terraform-outputs.json"
echo ""
