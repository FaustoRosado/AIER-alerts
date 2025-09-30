#!/bin/bash
# AIER Alert System - AWS Console View Link Generator
# NOTE: This script requires elevated AWS permissions (sts:GetFederationToken)
# Most AWS lab/academy accounts do NOT have this permission

set -euo pipefail

echo "=================================================="
echo "AIER Alert System - Console View Link Generator"
echo "=================================================="
echo ""
echo "⚠️  NOTE: This script requires admin permissions"
echo "    AWS lab/academy accounts typically lack:"
echo "    - sts:GetFederationToken"
echo ""
echo "    Alternative: Share credentials via setup scripts"
echo "    - Mac: bash scripts/aws-setup-mac.sh"
echo "    - Windows: .\\scripts\\aws-setup-windows.ps1"
echo ""

read -p "Do you have admin permissions? (yes/no): " HAS_PERMS

if [ "$HAS_PERMS" != "yes" ]; then
    echo ""
    echo "Use the AWS setup scripts instead:"
    echo "  Team members run: bash scripts/aws-setup-mac.sh"
    echo "  Provide them with temporary AWS credentials"
    echo ""
    exit 0
fi

echo ""

# Use existing AWS profile or default
if [ -z "${AWS_PROFILE:-}" ]; then
    echo "Using default AWS credentials..."
else
    echo "Using AWS profile: ${AWS_PROFILE}"
fi

# Check AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "ERROR: AWS CLI is not installed"
    exit 1
fi

# Check jq is installed
if ! command -v jq &> /dev/null; then
    echo "ERROR: jq is not installed (brew install jq or apt-get install jq)"
    exit 1
fi

# Set region
AWS_REGION=${AWS_REGION:-us-east-1}
echo "Using AWS Region: ${AWS_REGION}"
echo ""

# Create session name with timestamp
SESSION="aier-view-$(date +%Y%m%d-%H%M)"

# Read-only policy for viewing infrastructure
POLICY='{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["ec2:Describe*","vpc:Describe*","logs:Describe*","logs:Get*","logs:FilterLogEvents","cloudwatch:Describe*","cloudwatch:Get*","cloudwatch:List*","s3:ListAllMyBuckets","s3:Get*","s3:ListBucket","dynamodb:Describe*","dynamodb:List*","dynamodb:Scan","lambda:Get*","lambda:List*","apigateway:GET","cloudfront:Get*","cloudfront:List*","iam:ListAccountAliases"],"Resource":"*"}]}'

echo "Requesting federation token (valid for 12 hours)..."
CREDS=$(aws sts get-federation-token \
    --name "$SESSION" \
    --duration-seconds 43200 \
    --policy "$POLICY" \
    --query 'Credentials' \
    --output json 2>&1)

if echo "$CREDS" | grep -q "AccessDenied\|not authorized"; then
    echo ""
    echo "❌ ERROR: Access Denied"
    echo ""
    echo "Your AWS account does not have sts:GetFederationToken permission."
    echo "This is common in AWS lab/academy/learner accounts."
    echo ""
    echo "Alternative for team access:"
    echo "  1. Team lead creates IAM users with temporary credentials"
    echo "  2. Team members run: bash scripts/aws-setup-mac.sh"
    echo "  3. Enter provided credentials when prompted"
    echo ""
    exit 1
fi

if [ -z "$CREDS" ]; then
    echo "ERROR: Failed to get federation token"
    exit 1
fi

# Create session JSON for federation
SESS=$(echo "$CREDS" | jq -c '{sessionId:.AccessKeyId,sessionKey:.SecretAccessKey,sessionToken:.SessionToken}')

# URL encode the session
SESS_ENC=$(python3 -c 'import sys,urllib.parse as u; print(u.quote(sys.stdin.read().strip(), safe=""))' <<< "$SESS")

# Get signin token
echo "Getting signin token..."
TOKEN=$(curl -fsS "https://signin.aws.amazon.com/federation?Action=getSigninToken&SessionType=json&Session=${SESS_ENC}" | jq -r .SigninToken)

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
    echo "ERROR: Failed to get signin token"
    exit 1
fi

# Create destination URL
DEST=$(python3 -c "import os,urllib.parse as u; print(u.quote(f'https://console.aws.amazon.com/console/home?region={os.environ.get(\"AWS_REGION\",\"us-east-1\")}', safe=''))")

# Final federation URL
echo ""
echo "=================================================="
echo "SUCCESS! Console View Link Generated"
echo "=================================================="
echo ""
echo "Share this READ-ONLY console URL (valid for 12 hours):"
echo ""
echo "https://signin.aws.amazon.com/federation?Action=login&Issuer=AIER-Team&Destination=${DEST}&SigninToken=${TOKEN}"
echo ""
echo "=================================================="
echo ""
echo "Tips:"
echo "  - Copy the URL above"
echo "  - Share with team members via secure channel"
echo "  - URL expires after 12 hours"
echo "  - Read-only access (cannot modify resources)"
echo ""
