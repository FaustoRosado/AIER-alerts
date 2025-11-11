# CloudWatch to Splunk Deployment

## Prerequisites

- Splunk instance with HEC enabled
- HEC token created
- AWS Lambda access
- CloudWatch log group from Task 1

## Step 1: Configure Splunk HEC

1. Open Splunk web interface
2. Settings > Data Inputs > HTTP Event Collector
3. Create new token
4. Save token value
5. Note HEC URL: `https://your-splunk:8088/services/collector/event`

## Step 2: Create Lambda Deployment Package

```bash
cd cloudwatch-splunk
zip function.zip lambda.py
```

## Step 3: Create Lambda Function

```bash
aws lambda create-function \
  --function-name cloudwatch-to-splunk \
  --runtime python3.11 \
  --role arn:aws:iam::ACCOUNT_ID:role/sprint4-lambda-logs-role \
  --handler lambda.handler \
  --zip-file fileb://function.zip \
  --timeout 60 \
  --memory-size 256
```

Replace ACCOUNT_ID with your AWS account ID.

## Step 4: Set Environment Variables

```bash
aws lambda update-function-configuration \
  --function-name cloudwatch-to-splunk \
  --environment Variables="{SPLUNK_HEC_URL=https://your-splunk:8088/services/collector/event,SPLUNK_HEC_TOKEN=your-token-here}"
```

## Step 5: Add CloudWatch Logs Permission

```bash
aws lambda add-permission \
  --function-name cloudwatch-to-splunk \
  --statement-id cloudwatch-logs \
  --action lambda:InvokeFunction \
  --principal logs.amazonaws.com
```

## Step 6: Create Subscription Filter

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=us-east-1

aws logs put-subscription-filter \
  --log-group-name /aws/sprint4/app-logs \
  --filter-name splunk-forwarder \
  --filter-pattern "" \
  --destination-arn arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:cloudwatch-to-splunk
```

## Step 7: Test Log Forwarding

```bash
aws logs put-log-events \
  --log-group-name /aws/sprint4/app-logs \
  --log-stream-name test-stream \
  --log-events timestamp=$(date +%s)000,message="Test log from CloudWatch"
```

## Step 8: Verify in Splunk

Search in Splunk:
```
index=main sourcetype=aws:cloudwatch earliest=-5m
```

## Screenshots Required

1. Splunk HEC token configuration
2. Lambda function configuration
3. Lambda environment variables
4. CloudWatch subscription filter
5. Test log event in CloudWatch
6. Logs appearing in Splunk search

