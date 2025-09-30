#!/bin/bash
# AIER Alert System - Verify Deployment
# Check that all AWS resources were created successfully

set -e

echo "=================================================="
echo "AIER Alert System - Deployment Verification"
echo "=================================================="
echo ""

# Check AWS credentials - use paid profile
if [ -z "${AWS_PROFILE:-}" ]; then
    export AWS_PROFILE=paid
fi

echo "Verifying AWS resources..."
echo ""

# Check S3 buckets
echo "1. Checking S3 buckets..."
S3_BUCKETS=$(aws s3 ls | grep -i aier | wc -l || echo "0")
if [ "$S3_BUCKETS" -gt 0 ]; then
    echo "   ✓ Found ${S3_BUCKETS} AIER S3 bucket(s)"
    aws s3 ls | grep -i aier
else
    echo "   ✗ No AIER S3 buckets found"
fi
echo ""

# Check DynamoDB tables
echo "2. Checking DynamoDB tables..."
DYNAMO_TABLES=$(aws dynamodb list-tables --query 'TableNames[?contains(@, `aier`)]' --output text | wc -w || echo "0")
if [ "$DYNAMO_TABLES" -gt 0 ]; then
    echo "   ✓ Found ${DYNAMO_TABLES} AIER DynamoDB table(s)"
    aws dynamodb list-tables --query 'TableNames[?contains(@, `aier`)]' --output text
else
    echo "   ✗ No AIER DynamoDB tables found"
fi
echo ""

# Check Lambda functions
echo "3. Checking Lambda functions..."
LAMBDA_FUNCS=$(aws lambda list-functions --query 'Functions[?contains(FunctionName, `aier`)]' --output text | wc -l || echo "0")
if [ "$LAMBDA_FUNCS" -gt 0 ]; then
    echo "   ✓ Found ${LAMBDA_FUNCS} AIER Lambda function(s)"
    aws lambda list-functions --query 'Functions[?contains(FunctionName, `aier`)].FunctionName' --output text
else
    echo "   ✗ No AIER Lambda functions found"
fi
echo ""

# Check CloudFront distributions
echo "4. Checking CloudFront distributions..."
CF_DISTS=$(aws cloudfront list-distributions --query 'DistributionList.Items[?contains(Comment, `AIER`)]' --output text 2>/dev/null | wc -l || echo "0")
if [ "$CF_DISTS" -gt 0 ]; then
    echo "   ✓ Found ${CF_DISTS} AIER CloudFront distribution(s)"
else
    echo "   ✗ No AIER CloudFront distributions found"
fi
echo ""

echo "=================================================="
echo "Verification Complete"
echo "=================================================="
echo ""
echo "Next steps:"
echo "  - View console: bash scripts/00_console_view_link.sh"
echo "  - Upload data: python scripts/data-pipeline.py --upload"
echo "  - View logs: aws logs tail /aws/lambda/aier-data-processor --follow"
echo ""
