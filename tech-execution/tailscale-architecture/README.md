# Tailscale Architecture for AWS Hybrid Deployment

## Overview

This documentation provides a comprehensive guide to implementing a secure Tailscale-based architecture for hybrid on-premises and AWS cloud deployments. The architecture focuses on maintaining persistent authentication, eliminating the need to reconfigure Tailnet permissions with each EC2 instance lifecycle event.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Persistent Authentication Strategy](#persistent-authentication-strategy)
4. [Implementation Steps](#implementation-steps)
5. [Security Considerations](#security-considerations)
6. [Troubleshooting](#troubleshooting)

## Architecture Overview

### Components

- **AWS VPC**: Private network infrastructure hosting application services
- **EC2 Subnet Routers**: Tailscale nodes advertising VPC CIDR blocks
- **On-Premises Nodes**: Development workstations and ER station endpoints
- **Tailscale Control Plane**: Authentication and ACL management
- **Route 53**: DNS resolution for edge endpoints
- **ALB with WAF/Shield**: Perimeter protection layer
- **CloudWatch/Splunk**: Centralized logging and monitoring

### Network Flow

```
Client Request
    |
    v
Route 53 DNS Resolution
    |
    v
CloudFront + WAF (DDoS Protection)
    |
    v
Application Load Balancer
    |
    v
Target Group (EC2 in Private Subnet)
    |
    v
Tailscale Subnet Router
    |
    v
Encrypted Tailscale Tunnel
    |
    v
On-Premises Inference Node
    |
    v
Response Path (Reverse)
```

## Prerequisites

### AWS Resources
- AWS Account with appropriate IAM permissions
- VPC with public and private subnets
- EC2 instances (t3.medium or larger recommended)
- Route 53 hosted zone
- Application Load Balancer
- CloudWatch Logs group

### Tailscale Requirements
- Tailscale account (Team or Enterprise tier recommended)
- API access token (generated from admin console)
- ACL policy defined for subnet routing

### Local Tools
- AWS CLI v2
- Terraform v1.5+
- jq (JSON processor)
- curl or wget

## Persistent Authentication Strategy

### Problem Statement

Standard Tailscale deployments require manual authentication for each new EC2 instance. When instances are destroyed and recreated (common in auto-scaling or infrastructure updates), the authentication keys expire, requiring manual intervention.

### Solution: Auth Keys with Reusable Tags

Tailscale provides authentication keys that can be:
1. **Pre-authorized**: Skip manual approval step
2. **Reusable**: Use same key for multiple devices
3. **Tagged**: Automatically apply device tags for ACL enforcement
4. **Ephemeral**: Automatically cleanup when device disconnects (optional)

### Implementation Strategy

#### 1. Generate Long-Lived Auth Keys

Create authentication keys through the Tailscale admin console or API:

```bash
# Using Tailscale API to generate auth key
TAILSCALE_API_KEY="tskey-api-xxxxx"
TAILNET="yourcompany.com"

curl -X POST "https://api.tailscale.com/api/v2/tailnet/${TAILNET}/keys" \
  -H "Authorization: Bearer ${TAILSCALE_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "capabilities": {
      "devices": {
        "create": {
          "reusable": true,
          "ephemeral": false,
          "preauthorized": true,
          "tags": ["tag:aws-subnet-router", "tag:prod-environment"]
        }
      }
    },
    "expirySeconds": 31536000,
    "description": "AWS Subnet Router - Production VPC"
  }'
```

**Key Parameters:**
- `reusable: true` - Auth key can be used multiple times
- `ephemeral: false` - Device persists in Tailnet after disconnect
- `preauthorized: true` - No manual approval required
- `tags` - Auto-apply device tags for ACL matching
- `expirySeconds: 31536000` - 1 year validity (adjust as needed)

#### 2. Store Auth Keys in AWS Secrets Manager

```bash
# Store Tailscale auth key securely
aws secretsmanager create-secret \
  --name "/tailscale/auth-keys/subnet-router" \
  --description "Tailscale auth key for AWS subnet routers" \
  --secret-string "tskey-auth-xxxxx-xxxxxxxxxxxxxx" \
  --region us-east-1 \
  --tags Key=Environment,Value=Production Key=Purpose,Value=Networking

# Create IAM policy for EC2 to read secret
cat > tailscale-secret-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:us-east-1:ACCOUNT_ID:secret:/tailscale/auth-keys/*"
    }
  ]
}
EOF

aws iam create-policy \
  --policy-name TailscaleAuthKeyAccess \
  --policy-document file://tailscale-secret-policy.json
```

#### 3. EC2 User Data Script with Persistent Configuration

```bash
#!/bin/bash
set -euo pipefail

# Configuration
REGION="us-east-1"
SECRET_NAME="/tailscale/auth-keys/subnet-router"
SUBNET_ROUTES="10.0.0.0/16"
ADVERTISE_TAGS="tag:aws-subnet-router,tag:prod-environment"

# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Retrieve auth key from Secrets Manager
AUTH_KEY=$(aws secretsmanager get-secret-value \
  --secret-id "${SECRET_NAME}" \
  --region "${REGION}" \
  --query 'SecretString' \
  --output text)

# Enable IP forwarding for subnet routing
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p /etc/sysctl.conf

# Start Tailscale with subnet router configuration
sudo tailscale up \
  --authkey="${AUTH_KEY}" \
  --advertise-routes="${SUBNET_ROUTES}" \
  --advertise-tags="${ADVERTISE_TAGS}" \
  --accept-dns=false \
  --ssh \
  --hostname="aws-subnet-router-$(ec2-metadata --instance-id | cut -d' ' -f2)"

# Verify connection
sudo tailscale status

# Create systemd override to persist configuration across reboots
sudo mkdir -p /etc/systemd/system/tailscaled.service.d
cat <<EOF_SYSTEMD | sudo tee /etc/systemd/system/tailscaled.service.d/override.conf
[Service]
Environment="TS_AUTHKEY=${AUTH_KEY}"
Environment="TS_ROUTES=${SUBNET_ROUTES}"
Environment="TS_TAGS=${ADVERTISE_TAGS}"
EOF_SYSTEMD

sudo systemctl daemon-reload
sudo systemctl enable tailscaled
```

## Implementation Steps

### Step 1: Configure Tailscale ACLs

Define ACL policy in Tailscale admin console (Access Controls):

```json
{
  "tagOwners": {
    "tag:aws-subnet-router": ["autogroup:admin"],
    "tag:prod-environment": ["autogroup:admin"],
    "tag:on-prem-client": ["autogroup:admin"],
    "tag:developer": ["autogroup:admin"]
  },
  "acls": [
    {
      "action": "accept",
      "src": ["tag:on-prem-client", "tag:developer"],
      "dst": ["tag:aws-subnet-router:*"]
    },
    {
      "action": "accept",
      "src": ["tag:aws-subnet-router"],
      "dst": ["tag:on-prem-client:*"]
    },
    {
      "action": "accept",
      "src": ["autogroup:admin"],
      "dst": ["*:*"]
    }
  ],
  "ssh": [
    {
      "action": "accept",
      "src": ["autogroup:admin"],
      "dst": ["tag:aws-subnet-router"],
      "users": ["autogroup:nonroot", "root"]
    }
  ]
}
```

**ACL Explanation:**
- `tagOwners`: Defines who can assign tags to devices
- `acls`: Network access rules between tagged devices
- `ssh`: SSH access rules using Tailscale SSH

### Step 2: Create Terraform Configuration

```hcl
# terraform/tailscale-infrastructure.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# IAM Role for EC2 Tailscale Subnet Router
resource "aws_iam_role" "tailscale_subnet_router" {
  name = "tailscale-subnet-router-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "Tailscale Subnet Router Role"
    Environment = var.environment
  }
}

# Attach Secrets Manager policy
resource "aws_iam_role_policy_attachment" "tailscale_secrets_access" {
  role       = aws_iam_role.tailscale_subnet_router.name
  policy_arn = aws_iam_policy.tailscale_auth_key_access.arn
}

# Instance profile
resource "aws_iam_instance_profile" "tailscale_subnet_router" {
  name = "tailscale-subnet-router-profile"
  role = aws_iam_role.tailscale_subnet_router.name
}

# Security Group for Tailscale
resource "aws_security_group" "tailscale_subnet_router" {
  name_description = "Security group for Tailscale subnet routers"
  vpc_id          = var.vpc_id

  # Tailscale uses UDP port 41641 for DERP relay
  ingress {
    description = "Tailscale DERP"
    from_port   = 41641
    to_port     = 41641
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS for Tailscale coordination server
  egress {
    description = "Tailscale coordination"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all traffic within VPC
  ingress {
    description = "Internal VPC traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Internal VPC traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name        = "Tailscale Subnet Router SG"
    Environment = var.environment
  }
}

# EC2 Instance for Tailscale Subnet Router
resource "aws_instance" "tailscale_subnet_router" {
  ami                    = var.amazon_linux_2_ami
  instance_type          = "t3.medium"
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.tailscale_subnet_router.id]
  iam_instance_profile   = aws_iam_instance_profile.tailscale_subnet_router.name
  
  user_data = templatefile("${path.module}/user-data/tailscale-setup.sh", {
    secret_name    = var.tailscale_auth_key_secret
    subnet_routes  = var.vpc_cidr
    advertise_tags = "tag:aws-subnet-router,tag:${var.environment}"
  })

  source_dest_check = false  # Required for subnet routing

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  tags = {
    Name        = "Tailscale Subnet Router"
    Environment = var.environment
    Purpose     = "Network Infrastructure"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Elastic IP for stable external connectivity
resource "aws_eip" "tailscale_subnet_router" {
  instance = aws_instance.tailscale_subnet_router.id
  domain   = "vpc"

  tags = {
    Name        = "Tailscale Subnet Router EIP"
    Environment = var.environment
  }
}

output "tailscale_subnet_router_private_ip" {
  value       = aws_instance.tailscale_subnet_router.private_ip
  description = "Private IP of Tailscale subnet router"
}

output "tailscale_subnet_router_public_ip" {
  value       = aws_eip.tailscale_subnet_router.public_ip
  description = "Public IP of Tailscale subnet router"
}
```

### Step 3: Deploy Infrastructure

```bash
# Navigate to Terraform directory
cd terraform/

# Initialize Terraform
terraform init

# Review planned changes
terraform plan \
  -var="aws_region=us-east-1" \
  -var="environment=production" \
  -var="vpc_id=vpc-xxxxx" \
  -var="vpc_cidr=10.0.0.0/16" \
  -var="public_subnet_id=subnet-xxxxx" \
  -var="tailscale_auth_key_secret=/tailscale/auth-keys/subnet-router"

# Apply configuration
terraform apply -auto-approve

# Verify deployment
INSTANCE_ID=$(terraform output -raw tailscale_subnet_router_instance_id)
aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].State.Name'
```

### Step 4: Enable Subnet Routes in Tailscale

After EC2 instance connects to Tailnet, approve subnet routes:

```bash
# List devices waiting for subnet route approval
tailscale status --json | jq '.Peer[] | select(.SubnetRoutes != null)'

# Approve subnet routes via API
DEVICE_ID="xxxxx"
curl -X POST "https://api.tailscale.com/api/v2/device/${DEVICE_ID}/routes" \
  -H "Authorization: Bearer ${TAILSCALE_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "routes": ["10.0.0.0/16"]
  }'
```

**Automated Approval (Optional):**

Enable auto-approval in ACL policy:

```json
{
  "autoApprovers": {
    "routes": {
      "10.0.0.0/16": ["tag:aws-subnet-router"]
    }
  }
}
```

### Step 5: Configure On-Premises Clients

Install Tailscale on development workstations and ER station endpoints:

```bash
# Install Tailscale on Linux/macOS
curl -fsSL https://tailscale.com/install.sh | sh

# Authenticate with tag
sudo tailscale up --authkey="tskey-auth-xxxxx" --advertise-tags="tag:on-prem-client"

# Verify connectivity to AWS VPC
ping 10.0.1.100  # Private IP in AWS VPC
```

## Security Considerations

### Authentication Security

1. **Auth Key Rotation**: Rotate auth keys annually or when compromised
2. **Secrets Manager Access**: Restrict IAM policies to minimum necessary permissions
3. **Key Scope**: Use different auth keys for different environments (dev/staging/prod)

### Network Security

1. **ACL Enforcement**: Implement least-privilege ACL policies
2. **SSH Access**: Use Tailscale SSH instead of opening port 22
3. **Audit Logging**: Enable Tailscale audit logs for compliance
4. **Network Segmentation**: Use tags to segment production and non-production

### Compliance Considerations

1. **HIPAA Alignment**: Tailscale provides encryption in transit (WireGuard protocol)
2. **Audit Trail**: Maintain logs of device connections and ACL changes
3. **Access Reviews**: Regularly review device tags and ACL policies
4. **Business Associate Agreement**: Obtain BAA from Tailscale for PHI environments

### Monitoring and Alerting

```bash
# CloudWatch alarm for Tailscale subnet router health
aws cloudwatch put-metric-alarm \
  --alarm-name tailscale-subnet-router-status \
  --alarm-description "Alert if Tailscale subnet router becomes unhealthy" \
  --metric-name StatusCheckFailed \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 1 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --evaluation-periods 2 \
  --dimensions Name=InstanceId,Value=$INSTANCE_ID \
  --alarm-actions arn:aws:sns:us-east-1:ACCOUNT_ID:infrastructure-alerts
```

## Troubleshooting

### Issue: EC2 Instance Cannot Connect to Tailnet

**Symptoms:**
- `tailscale status` shows "Logged out"
- UserData script fails during Tailscale authentication

**Resolution:**
```bash
# Check IAM permissions for Secrets Manager
aws sts get-caller-identity

# Verify secret value retrieval
aws secretsmanager get-secret-value \
  --secret-id /tailscale/auth-keys/subnet-router \
  --region us-east-1

# Check Tailscale logs
sudo journalctl -u tailscaled -n 100

# Manually authenticate if needed
sudo tailscale up --authkey="tskey-auth-xxxxx"
```

### Issue: Subnet Routes Not Advertising

**Symptoms:**
- On-premises clients cannot reach AWS VPC resources
- `tailscale status` shows connected but routes missing

**Resolution:**
```bash
# Verify IP forwarding is enabled
sudo sysctl net.ipv4.ip_forward
sudo sysctl net.ipv6.conf.all.forwarding

# Check if routes are advertised
tailscale status --json | jq '.Self.HostName, .Self.SubnetRoutes'

# Disable source/destination check on EC2
aws ec2 modify-instance-attribute \
  --instance-id i-xxxxx \
  --no-source-dest-check

# Approve routes in Tailscale admin console
# Or use API call from Step 4
```

### Issue: Persistent Configuration Lost After Reboot

**Symptoms:**
- Tailscale disconnects after EC2 reboot
- Need to manually run `tailscale up` again

**Resolution:**
```bash
# Verify systemd service is enabled
sudo systemctl status tailscaled
sudo systemctl enable tailscaled

# Check for environment variables in systemd override
cat /etc/systemd/system/tailscaled.service.d/override.conf

# If missing, recreate override configuration
sudo mkdir -p /etc/systemd/system/tailscaled.service.d
sudo tee /etc/systemd/system/tailscaled.service.d/override.conf <<EOF
[Service]
ExecStartPost=/usr/bin/tailscale up --authkey=${AUTH_KEY} --advertise-routes=${SUBNET_ROUTES}
EOF

sudo systemctl daemon-reload
sudo systemctl restart tailscaled
```

### Issue: High Latency Through Tailscale

**Symptoms:**
- Ping times >100ms to AWS resources
- Application performance degradation

**Resolution:**
```bash
# Check Tailscale connection path
tailscale status

# Verify direct connection (not relayed through DERP)
tailscale netcheck

# If using DERP relay, troubleshoot UDP connectivity
# Ensure security groups allow UDP 41641

# Test with iperf3 for bandwidth measurement
# On AWS instance:
iperf3 -s

# On client:
iperf3 -c 10.0.1.100
```

## Advanced Configurations

### Multi-Region Deployment

Deploy subnet routers in multiple AWS regions for redundancy:

```hcl
# Deploy in us-east-1, us-west-2, eu-west-1
module "tailscale_us_east" {
  source = "./modules/tailscale-subnet-router"
  region = "us-east-1"
  vpc_cidr = "10.0.0.0/16"
}

module "tailscale_us_west" {
  source = "./modules/tailscale-subnet-router"
  region = "us-west-2"
  vpc_cidr = "10.1.0.0/16"
}
```

### High Availability Configuration

Use Auto Scaling Group for automatic replacement:

```hcl
resource "aws_launch_template" "tailscale_subnet_router" {
  name_prefix   = "tailscale-subnet-router-"
  image_id      = var.amazon_linux_2_ami
  instance_type = "t3.medium"
  
  iam_instance_profile {
    name = aws_iam_instance_profile.tailscale_subnet_router.name
  }
  
  vpc_security_group_ids = [aws_security_group.tailscale_subnet_router.id]
  
  user_data = base64encode(templatefile("user-data/tailscale-setup.sh", {
    secret_name = var.tailscale_auth_key_secret
  }))
  
  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
    security_groups            = [aws_security_group.tailscale_subnet_router.id]
  }
}

resource "aws_autoscaling_group" "tailscale_subnet_router" {
  name                = "tailscale-subnet-router-asg"
  desired_capacity    = 2
  max_size            = 3
  min_size            = 1
  vpc_zone_identifier = [var.public_subnet_id]
  
  launch_template {
    id      = aws_launch_template.tailscale_subnet_router.id
    version = "$Latest"
  }
  
  health_check_type         = "EC2"
  health_check_grace_period = 300
  
  tag {
    key                 = "Name"
    value               = "Tailscale Subnet Router"
    propagate_at_launch = true
  }
}
```

## Best Practices

1. **Tag Management**: Use consistent tagging strategy for ACL enforcement
2. **Key Rotation**: Implement regular auth key rotation schedule
3. **Monitoring**: Set up CloudWatch alarms for subnet router health
4. **Documentation**: Maintain inventory of Tailscale devices and their purposes
5. **Testing**: Regularly test failover scenarios and connectivity
6. **Backup**: Document recovery procedures for complete Tailnet rebuild
7. **Updates**: Keep Tailscale client updated to latest stable version

## References

- [Tailscale Subnet Routers Documentation](https://tailscale.com/kb/1019/subnets/)
- [Tailscale API Reference](https://tailscale.com/api)
- [AWS Secrets Manager Best Practices](https://docs.aws.amazon.com/secretsmanager/latest/userguide/best-practices.html)
- [WireGuard Protocol Specification](https://www.wireguard.com/protocol/)

## Support

For issues specific to this implementation, contact your DevSecOps team. For Tailscale-specific issues, consult [Tailscale Support](https://tailscale.com/contact/support).

