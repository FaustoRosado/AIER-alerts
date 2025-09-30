#!/bin/bash
# AIER Alert System - Create Team Member IAM Users
# Creates IAM users with temporary passwords (must reset on first login)

set -e

echo "=================================================="
echo "AIER Alert System - Create Team IAM Users"
echo "=================================================="
echo ""

# Check AWS credentials
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "ERROR: AWS credentials not configured"
    echo "Run: aws configure"
    exit 1
fi

echo "Current AWS Identity:"
aws sts get-caller-identity
echo ""

# Team members
TEAM_MEMBERS=(
    "javi"
    "shay"
    "cuoung"
    "cyberdog"
    "crystal"
)

# Generate random temporary password
generate_password() {
    # Generate 16 character password with letters, numbers, and symbols
    LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c 16
}

# Policy for AIER developers
POLICY_NAME="AIERDeveloperAccess"
POLICY_ARN=""

echo "Step 1: Creating/Verifying Developer Policy..."
echo ""

# Check if policy exists
EXISTING_POLICY=$(aws iam list-policies --query "Policies[?PolicyName=='${POLICY_NAME}'].Arn" --output text 2>/dev/null || echo "")

if [ -z "$EXISTING_POLICY" ]; then
    echo "Creating ${POLICY_NAME} policy..."
    
    # Create policy JSON
    POLICY_DOC='{
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "S3Access",
          "Effect": "Allow",
          "Action": [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject",
            "s3:ListBucket",
            "s3:ListAllMyBuckets"
          ],
          "Resource": [
            "arn:aws:s3:::aier-*",
            "arn:aws:s3:::aier-*/*"
          ]
        },
        {
          "Sid": "DynamoDBAccess",
          "Effect": "Allow",
          "Action": [
            "dynamodb:GetItem",
            "dynamodb:PutItem",
            "dynamodb:UpdateItem",
            "dynamodb:DeleteItem",
            "dynamodb:Query",
            "dynamodb:Scan",
            "dynamodb:DescribeTable",
            "dynamodb:ListTables"
          ],
          "Resource": "arn:aws:dynamodb:*:*:table/aier-*"
        },
        {
          "Sid": "LambdaAccess",
          "Effect": "Allow",
          "Action": [
            "lambda:InvokeFunction",
            "lambda:GetFunction",
            "lambda:UpdateFunctionCode",
            "lambda:UpdateFunctionConfiguration",
            "lambda:ListFunctions"
          ],
          "Resource": "arn:aws:lambda:*:*:function:aier-*"
        },
        {
          "Sid": "CloudWatchLogs",
          "Effect": "Allow",
          "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:DescribeLogStreams",
            "logs:DescribeLogGroups",
            "logs:FilterLogEvents",
            "logs:GetLogEvents"
          ],
          "Resource": "arn:aws:logs:*:*:*"
        },
        {
          "Sid": "CloudFrontReadAccess",
          "Effect": "Allow",
          "Action": [
            "cloudfront:GetDistribution",
            "cloudfront:ListDistributions"
          ],
          "Resource": "*"
        },
        {
          "Sid": "IAMReadAccess",
          "Effect": "Allow",
          "Action": [
            "iam:GetUser",
            "iam:GetAccountSummary",
            "iam:ListAccountAliases"
          ],
          "Resource": "*"
        },
        {
          "Sid": "STSAccess",
          "Effect": "Allow",
          "Action": [
            "sts:GetCallerIdentity"
          ],
          "Resource": "*"
        },
        {
          "Sid": "EC2DescribeAccess",
          "Effect": "Allow",
          "Action": [
            "ec2:Describe*"
          ],
          "Resource": "*"
        }
      ]
    }'
    
    POLICY_ARN=$(aws iam create-policy \
        --policy-name ${POLICY_NAME} \
        --policy-document "$POLICY_DOC" \
        --description "Developer access for AIER Alert System project" \
        --query 'Policy.Arn' \
        --output text)
    
    echo "✓ Policy created: ${POLICY_ARN}"
else
    POLICY_ARN=$EXISTING_POLICY
    echo "✓ Policy already exists: ${POLICY_ARN}"
fi

echo ""
echo "Step 2: Creating Team Member IAM Users..."
echo ""

# Create team members (no associative array needed - writing directly to files)
for username in "${TEAM_MEMBERS[@]}"; do
    USER_NAME="aier-${username}"
    
    echo "-----------------------------------"
    echo "Creating user: ${USER_NAME}"
    echo "-----------------------------------"
    
    # Check if user exists
    if aws iam get-user --user-name ${USER_NAME} > /dev/null 2>&1; then
        echo "⚠️  User ${USER_NAME} already exists"
        
        read -p "Delete and recreate? (yes/no): " RECREATE
        if [ "$RECREATE" == "yes" ]; then
            # Delete access keys
            ACCESS_KEYS=$(aws iam list-access-keys --user-name ${USER_NAME} --query 'AccessKeyMetadata[].AccessKeyId' --output text)
            for key in $ACCESS_KEYS; do
                aws iam delete-access-key --user-name ${USER_NAME} --access-key-id $key
                echo "  Deleted access key: $key"
            done
            
            # Detach policies
            ATTACHED_POLICIES=$(aws iam list-attached-user-policies --user-name ${USER_NAME} --query 'AttachedPolicies[].PolicyArn' --output text)
            for policy in $ATTACHED_POLICIES; do
                aws iam detach-user-policy --user-name ${USER_NAME} --policy-arn $policy
                echo "  Detached policy: $policy"
            done
            
            # Delete login profile (password)
            aws iam delete-login-profile --user-name ${USER_NAME} 2>/dev/null || true
            
            # Delete user
            aws iam delete-user --user-name ${USER_NAME}
            echo "  Deleted user"
        else
            echo "  Skipping user creation"
            echo ""
            continue
        fi
    fi
    
    # Create user
    aws iam create-user --user-name ${USER_NAME} > /dev/null
    echo "✓ Created IAM user: ${USER_NAME}"
    
    # Attach policy
    aws iam attach-user-policy \
        --user-name ${USER_NAME} \
        --policy-arn ${POLICY_ARN}
    echo "✓ Attached developer policy"
    
    # Generate temporary password
    TEMP_PASSWORD=$(generate_password)
    
    # Create login profile with password reset required
    aws iam create-login-profile \
        --user-name ${USER_NAME} \
        --password "${TEMP_PASSWORD}" \
        --password-reset-required > /dev/null
    echo "✓ Created login profile (password reset required)"
    
    # Create access keys for CLI (output hidden for security)
    ACCESS_KEY_OUTPUT=$(aws iam create-access-key --user-name ${USER_NAME} --output json 2>&1)
    ACCESS_KEY_ID=$(echo $ACCESS_KEY_OUTPUT | jq -r '.AccessKey.AccessKeyId' 2>/dev/null)
    SECRET_ACCESS_KEY=$(echo $ACCESS_KEY_OUTPUT | jq -r '.AccessKey.SecretAccessKey' 2>/dev/null)
    
    echo "✓ Created access keys for CLI (saved to file only, not displayed)"
    echo ""
    
    # Save credentials to file
    mkdir -p ../team-credentials
    cat > ../team-credentials/${username}-credentials.txt << EOF
========================================
AIER Alert System - Credentials
========================================
Team Member: ${username}

AWS Console Login:
------------------
URL: https://console.aws.amazon.com/
Account ID: $(aws sts get-caller-identity --query Account --output text)
IAM Username: ${USER_NAME}
Temporary Password: ${TEMP_PASSWORD}

⚠️  IMPORTANT: You MUST change this password on first login!

AWS CLI Access Keys:
--------------------
AWS Access Key ID: ${ACCESS_KEY_ID}
AWS Secret Access Key: ${SECRET_ACCESS_KEY}
Region: us-east-1

Setup Instructions:
-------------------
1. Run: bash scripts/aws-setup-mac.sh
   (or .\scripts\aws-setup-windows.ps1 on Windows)

2. When prompted, enter:
   - Access Key ID: ${ACCESS_KEY_ID}
   - Secret Access Key: ${SECRET_ACCESS_KEY}
   - Region: us-east-1

3. For Console access:
   - Go to: https://console.aws.amazon.com/
   - Enter Account ID: $(aws sts get-caller-identity --query Account --output text)
   - Enter Username: ${USER_NAME}
   - Enter Temporary Password: ${TEMP_PASSWORD}
   - You will be forced to create a new password

Permissions:
------------
- S3: Full access to aier-* buckets
- DynamoDB: Full access to aier-* tables
- Lambda: Full access to aier-* functions
- CloudWatch: Logs access
- CloudFront: Read-only access
- IAM: Read your own user info

========================================
Generated: $(date)
========================================
EOF
    
    echo "✓ Saved credentials to: team-credentials/${username}-credentials.txt"
    echo ""
done

echo ""
echo "=================================================="
echo "Team User Creation Complete!"
echo "=================================================="
echo ""
echo "Created ${#TEAM_MEMBERS[@]} IAM users:"
for username in "${TEAM_MEMBERS[@]}"; do
    echo "  - aier-${username}"
done
echo ""
echo "Credentials saved in: team-credentials/"
echo ""
echo "⚠️  IMPORTANT SECURITY NOTES:"
echo "  1. Distribute credentials via SECURE channel (encrypted email, password manager)"
echo "  2. DO NOT commit team-credentials/ folder to Git (it's in .gitignore)"
echo "  3. Users MUST change password on first console login"
echo "  4. Rotate access keys every 90 days"
echo "  5. Delete credentials files after distribution"
echo ""
echo "Next steps:"
echo "  1. Securely send each team member their credentials file"
echo "  2. Team members run: bash scripts/aws-setup-mac.sh"
echo "  3. Team members enter their access keys when prompted"
echo "  4. Team members can log into AWS Console and change password"
echo ""
echo "To delete all team users later:"
echo "  bash scripts/delete_team_users.sh"
echo ""
