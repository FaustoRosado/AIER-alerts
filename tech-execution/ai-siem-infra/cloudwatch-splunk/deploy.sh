#!/bin/bash
# Deploy Lambda function to forward CloudWatch logs to Splunk

# Get AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=us-east-1

# IAM role created in Task 1 (Terraform)
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/sprint4-lambda-logs-role"

echo "Creating Lambda function..."

# Create Lambda function with Python runtime
aws lambda create-function \
  --function-name cloudwatch-to-splunk \
  --runtime python3.11 \
  --role "$ROLE_ARN" \
  --handler lambda.handler \
  --zip-file fileb://function.zip \
  --timeout 60 \
  --memory-size 256

echo ""
echo "Lambda function created."
echo ""
echo "Next steps:"
echo "1. Set Splunk HEC URL and token as environment variables"
echo "2. Add permission for CloudWatch Logs to invoke Lambda"
echo "3. Create subscription filter to forward logs"
echo ""
echo "See DEPLOY.md for detailed instructions."

