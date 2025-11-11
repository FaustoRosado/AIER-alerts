#!/bin/bash
# Create CloudWatch Logs subscription filter to forward logs to Lambda

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=us-east-1
LOG_GROUP="/aws/sprint4/app-logs"
FUNCTION_NAME="cloudwatch-to-splunk"

echo "Creating subscription filter..."

aws logs put-subscription-filter \
  --log-group-name "$LOG_GROUP" \
  --filter-name splunk-forwarder \
  --filter-pattern "" \
  --destination-arn "arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${FUNCTION_NAME}"

echo ""
echo "Subscription filter created successfully."
echo "Logs from $LOG_GROUP will now be forwarded to Lambda function."

