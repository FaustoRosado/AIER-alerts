#!/bin/bash
# Launch EC2 instance for Tailscale relay

KEY_NAME="${1:-my-lab-key}"
INSTANCE_TYPE="${2:-t2.micro}"

echo "Launching EC2 instance for Tailscale relay..."
echo "Key pair: $KEY_NAME"
echo "Instance type: $INSTANCE_TYPE"
echo ""

# Get latest Amazon Linux 2 AMI
AMI_ID=$(aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" \
  --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
  --output text)

if [ -z "$AMI_ID" ]; then
  echo "Error: Could not find Amazon Linux 2 AMI"
  exit 1
fi

echo "Using AMI: $AMI_ID"
echo ""

# Launch instance
INSTANCE_OUTPUT=$(aws ec2 run-instances \
  --image-id "$AMI_ID" \
  --instance-type "$INSTANCE_TYPE" \
  --key-name "$KEY_NAME" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=sprint4-tailscale}]' \
  --output json)

INSTANCE_ID=$(echo "$INSTANCE_OUTPUT" | jq -r '.Instances[0].InstanceId')

echo "Instance launched: $INSTANCE_ID"
echo ""
echo "Waiting for instance to be running..."
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

echo "Getting public IP..."
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo ""
echo "=========================================="
echo "EC2 Instance Ready"
echo "=========================================="
echo "Instance ID: $INSTANCE_ID"
echo "Public IP: $PUBLIC_IP"
echo ""
echo "SSH command:"
echo "  ssh -i ~/.ssh/${KEY_NAME}.pem ec2-user@${PUBLIC_IP}"
echo ""
echo "📸 Screenshot: EC2 instance in AWS Console"
echo ""

