#!/bin/bash
# Test log forwarding to Lambda

LOG_GROUP="/aws/sprint4/app-logs"
LOG_STREAM="test-stream-$(date +%s)"

echo "Creating log stream and sending test log..."

# Create log stream
aws logs create-log-stream \
  --log-group-name "$LOG_GROUP" \
  --log-stream-name "$LOG_STREAM"

# Wait a moment
sleep 1

# Send test log event
aws logs put-log-events \
  --log-group-name "$LOG_GROUP" \
  --log-stream-name "$LOG_STREAM" \
  --log-events timestamp=$(date +%s)000,message="Test log from CloudWatch to Splunk - $(date)"

echo ""
echo "Test log sent to $LOG_GROUP"
echo "Check Lambda function logs to verify forwarding."

