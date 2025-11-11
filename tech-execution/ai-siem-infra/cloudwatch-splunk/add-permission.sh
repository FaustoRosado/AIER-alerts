#!/bin/bash
# Add CloudWatch Logs permission to Lambda function

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
FUNCTION_NAME="cloudwatch-to-splunk"

echo "Adding CloudWatch Logs permission to Lambda function..."

aws lambda add-permission \
  --function-name "$FUNCTION_NAME" \
  --statement-id cloudwatch-logs \
  --action lambda:InvokeFunction \
  --principal logs.amazonaws.com \
  --source-arn "arn:aws:logs:us-east-1:${ACCOUNT_ID}:log-group:/aws/sprint4/app-logs:*"

echo ""
echo "Permission added successfully."

