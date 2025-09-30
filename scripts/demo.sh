#!/bin/bash
# AIER Alert System - Demo Script
# Quick demonstration of complete workflow for team QA

set -e

echo "=========================================="
echo "AIER Alert System - Complete Demo"
echo "=========================================="
echo ""
echo "This demo will walk through the complete workflow:"
echo "  1. Security check"
echo "  2. AWS credentials verification"
echo "  3. Terraform initialization (dry-run)"
echo "  4. Infrastructure plan (preview)"
echo "  5. Team user creation (dry-run)"
echo ""

read -p "Press Enter to start demo..."

# Use paid profile
export AWS_PROFILE=paid

echo ""
echo "=========================================="
echo "Step 1: Security Audit"
echo "=========================================="
echo ""
echo "Running security check to verify no credentials will be pushed..."
echo ""

bash scripts/00_security_check.sh

read -p "Press Enter to continue..."

echo ""
echo "=========================================="
echo "Step 2: AWS Credentials Check"
echo "=========================================="
echo ""
echo "Verifying AWS connection..."
echo ""

aws sts get-caller-identity

echo ""
echo "✓ Connected to AWS account"
echo ""

read -p "Press Enter to continue..."

echo ""
echo "=========================================="
echo "Step 3: List Current AWS Resources"
echo "=========================================="
echo ""

echo "Checking S3 buckets (filtering for 'aier')..."
aws s3 ls 2>/dev/null | grep -i aier || echo "  No AIER buckets found (expected before deployment)"
echo ""

echo "Checking DynamoDB tables (filtering for 'aier')..."
aws dynamodb list-tables --query 'TableNames[?contains(@, `aier`)]' --output text 2>/dev/null | grep -q . && \
  aws dynamodb list-tables --query 'TableNames[?contains(@, `aier`)]' --output text || \
  echo "  No AIER tables found (expected before deployment)"
echo ""

echo "Checking Lambda functions (filtering for 'aier')..."
aws lambda list-functions --query 'Functions[?contains(FunctionName, `aier`)].FunctionName' --output text 2>/dev/null | grep -q . && \
  aws lambda list-functions --query 'Functions[?contains(FunctionName, `aier`)].FunctionName' --output text || \
  echo "  No AIER functions found (expected before deployment)"
echo ""

read -p "Press Enter to continue..."

echo ""
echo "=========================================="
echo "Step 4: Terraform Initialization"
echo "=========================================="
echo ""
echo "Initializing Terraform (safe operation - downloads providers)..."
echo ""

cd terraform
terraform init -input=false

echo ""
echo "✓ Terraform initialized successfully"
echo ""

read -p "Press Enter to continue..."

echo ""
echo "=========================================="
echo "Step 5: Terraform Plan (Dry-Run)"
echo "=========================================="
echo ""
echo "Generating infrastructure plan..."
echo "This shows what WOULD be created (no actual changes)"
echo ""

terraform plan -input=false

echo ""
echo "✓ Terraform plan complete"
echo ""
echo "Review the plan above to see what will be created:"
echo "  - S3 buckets (data storage + frontend)"
echo "  - DynamoDB table (patient data)"
echo "  - Lambda function (data processor)"
echo "  - CloudFront distribution (CDN)"
echo "  - IAM roles and policies"
echo ""

cd ..

read -p "Press Enter to continue..."

echo ""
echo "=========================================="
echo "Step 6: Team User Creation (Preview)"
echo "=========================================="
echo ""
echo "Team members configured in create_team_users.sh:"
cat scripts/create_team_users.sh | grep -A 5 "TEAM_MEMBERS=" | head -7
echo ""
echo "NOTE: Not actually creating users in this demo"
echo "To create users, run: bash scripts/create_team_users.sh"
echo ""

read -p "Press Enter to continue..."

echo ""
echo "=========================================="
echo "Step 7: Repository Structure"
echo "=========================================="
echo ""
echo "Project structure:"
tree -L 2 -I 'node_modules|venv|.terraform' . 2>/dev/null || find . -maxdepth 2 -type d -not -path '*/.*' | head -20
echo ""

read -p "Press Enter to continue..."

echo ""
echo "=========================================="
echo "Step 8: Documentation Available"
echo "=========================================="
echo ""
echo "Complete documentation:"
ls -1 docs/*.md | while read file; do
    echo "  ✓ $(basename $file)"
done
echo ""

read -p "Press Enter to continue..."

echo ""
echo "=========================================="
echo "Step 9: Scripts Available"
echo "=========================================="
echo ""
echo "Workflow scripts:"
ls -1 scripts/*.sh | while read file; do
    echo "  ✓ $(basename $file)"
done
echo ""
echo "Data pipeline scripts:"
ls -1 scripts/*.py 2>/dev/null | while read file; do
    echo "  ✓ $(basename $file)"
done
echo ""

read -p "Press Enter to continue..."

echo ""
echo "=========================================="
echo "Demo Complete!"
echo "=========================================="
echo ""
echo "Summary:"
echo "  ✓ Security check passed - safe to push to GitHub"
echo "  ✓ AWS credentials working (paid profile)"
echo "  ✓ Terraform initialized and plan generated"
echo "  ✓ Team user creation script ready"
echo "  ✓ All documentation in place"
echo "  ✓ All workflow scripts ready"
echo ""
echo "Next steps for actual deployment:"
echo "  1. Create team IAM users:"
echo "     bash scripts/create_team_users.sh"
echo ""
echo "  2. Deploy infrastructure:"
echo "     bash scripts/01_init_terraform.sh"
echo "     bash scripts/02_plan_terraform.sh"
echo "     bash scripts/03_apply_terraform.sh"
echo ""
echo "  3. Verify deployment:"
echo "     bash scripts/04_verify_deployment.sh"
echo ""
echo "  4. Upload data:"
echo "     python scripts/data-pipeline.py --upload"
echo ""
echo "  5. Team members clone and configure:"
echo "     git clone [repo-url]"
echo "     bash scripts/aws-setup-mac.sh"
echo ""
echo "  6. Cleanup when done:"
echo "     bash scripts/99_destroy_terraform.sh"
echo ""
echo "Ready to push to GitHub: AIER-alerts"
echo ""
