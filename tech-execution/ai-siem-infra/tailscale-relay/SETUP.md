# Tailscale EC2 Relay Setup

Launch EC2 instance and configure as Tailscale relay node.

## Prerequisites

- AWS CLI configured
- Tailscale account

## Step 1: Launch EC2 Instance

```bash
aws ec2 run-instances \
  --image-id ami-06dd5c911c0d8dcdc \
  --instance-type t3.micro \
  --key-name sprint4-ec2-key \
  --subnet-id subnet-XXXXX \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=sprint4-tailscale}]'
```

## Step 2: Create SSH Key Pair

```bash
aws ec2 create-key-pair --key-name sprint4-ec2-key --query 'KeyMaterial' --output text > ~/.ssh/sprint4-ec2-key.pem
chmod 400 ~/.ssh/sprint4-ec2-key.pem
```

## Step 3: Configure Network

### Internet Gateway

```bash
VPC_ID=$(aws ec2 describe-instances --instance-ids i-INSTANCE-ID --query 'Reservations[0].Instances[0].VpcId' --output text)
IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
```

### Route Table

```bash
RTB_ID=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[0].RouteTableId' --output text)
aws ec2 create-route --route-table-id $RTB_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
```

### Security Group

```bash
SG_ID=$(aws ec2 describe-instances --instance-ids i-INSTANCE-ID --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
```

### Elastic IP

```bash
EIP_ALLOC=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text)
aws ec2 associate-address --instance-id i-INSTANCE-ID --allocation-id $EIP_ALLOC
```

## Step 4: SSH to Instance

```bash
ssh -i ~/.ssh/sprint4-ec2-key.pem ec2-user@PUBLIC_IP
```

## Step 5: Install Tailscale

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

Authenticate with Tailscale account when prompted.

## Step 6: Configure Hostname

```bash
sudo tailscale set --hostname=ec2-tailscale-relay
tailscale status
tailscale ip -4
```

## Step 7: Verify Connection

From local machine:

```bash
tailscale status | grep ec2-tailscale-relay
ping ec2-tailscale-relay.tailnet.ts.net
```

## Troubleshooting

**SSH Timeout:**
- Verify security group allows port 22
- Check route table has active route to internet gateway
- Ensure instance has public IP or Elastic IP

**Route Blackhole:**
```bash
aws ec2 delete-route --route-table-id $RTB_ID --destination-cidr-block 0.0.0.0/0
aws ec2 create-route --route-table-id $RTB_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
```
