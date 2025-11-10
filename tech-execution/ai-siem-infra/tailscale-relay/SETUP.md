# Sprint 4: Tailscale EC2 Relay Setup

## Overview

Launch EC2 instance and configure as Tailscale relay node.

## Prerequisites

- AWS CLI configured
- Terraform Task 1 complete
- Tailscale account (seclabs.ai@)

## Step 1: Launch EC2 Instance

```bash
aws ec2 run-instances \
  --image-id ami-06dd5c911c0d8dcdc \
  --instance-type t3.micro \
  --key-name sprint4-ec2-key \
  --subnet-id subnet-XXXXX \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=sprint4-tailscale}]'
```

## Step 2: Configure Network Access

### Create Internet Gateway

```bash
VPC_ID=$(aws ec2 describe-instances --instance-ids i-INSTANCE-ID --query 'Reservations[0].Instances[0].VpcId' --output text)
IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
```

### Add Route to Internet Gateway

```bash
RTB_ID=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[0].RouteTableId' --output text)
aws ec2 create-route --route-table-id $RTB_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
```

### Enable Public IP on Subnet

```bash
SUBNET_ID=$(aws ec2 describe-instances --instance-ids i-INSTANCE-ID --query 'Reservations[0].Instances[0].SubnetId' --output text)
aws ec2 modify-subnet-attribute --subnet-id $SUBNET_ID --map-public-ip-on-launch
```

## Step 3: Create SSH Key Pair

```bash
aws ec2 create-key-pair --key-name sprint4-ec2-key --query 'KeyMaterial' --output text > ~/.ssh/sprint4-ec2-key.pem
chmod 400 ~/.ssh/sprint4-ec2-key.pem
```

Note: Launch new instance with this key pair if existing instance doesn't have matching key.

## Step 4: Configure Security Group

```bash
SG_ID=$(aws ec2 describe-instances --instance-ids i-INSTANCE-ID --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
```

## Step 5: Allocate and Associate Elastic IP

```bash
EIP_ALLOC=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text)
aws ec2 associate-address --instance-id i-INSTANCE-ID --allocation-id $EIP_ALLOC
```

## Step 6: Attach IAM Role for SSM (Optional)

```bash
PROFILE_ARN=$(aws iam get-instance-profile --instance-profile-name EC2-SSM-Profile --query 'InstanceProfile.Arn' --output text)
aws ec2 associate-iam-instance-profile --instance-id i-INSTANCE-ID --iam-instance-profile Arn=$PROFILE_ARN
```

Note: SSM registration takes 2-5 minutes. SSH is faster for immediate access.

## Step 7: SSH to Instance

```bash
ssh -i ~/.ssh/sprint4-ec2-key.pem ec2-user@PUBLIC_IP
```

## Step 8: Install Tailscale

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

Authenticate with Tailscale account: seclabs.ai@

## Step 9: Configure Tailscale

```bash
sudo tailscale set --hostname=ec2-tailscale-relay
tailscale status
tailscale ip -4
```

## Step 10: Verify from Other Nodes

From local machine or other Tailscale nodes:

```bash
tailscale status | grep ec2-tailscale-relay
ping ec2-tailscale-relay.tailnet.ts.net
```

## Troubleshooting

### SSH Timeout

- Verify security group allows port 22
- Check route table has active route to internet gateway (not blackhole)
- Ensure instance has public IP or Elastic IP
- Wait 30-60 seconds after network changes

### Route Blackhole

```bash
# Delete and recreate route
aws ec2 delete-route --route-table-id $RTB_ID --destination-cidr-block 0.0.0.0/0
aws ec2 create-route --route-table-id $RTB_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
```

### Missing SSH Key

Create new key pair and launch new instance with it. Cannot change key pair on existing instance.

## Instance Details

- Instance ID: i-INSTANCE-ID
- Public IP: PUBLIC_IP
- Key: ~/.ssh/sprint4-ec2-key.pem
- Hostname: ec2-tailscale-relay

## Screenshots Required

1. EC2 instance in AWS Console
2. SSH connection successful
3. Tailscale installation output
4. tailscale status showing EC2 node
5. tailscale ip -4 output
6. Verification from local machine showing EC2 node
