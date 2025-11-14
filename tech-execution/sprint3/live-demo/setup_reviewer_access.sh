#!/bin/bash
# Create 72-hour temporary AWS access for reviewer

set -e

REVIEWER_USER="sprint3-reviewer-$(date +%s)"
EXPIRY_DATE=$(date -u -v+72H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "+72 hours" +%Y-%m-%dT%H:%M:%SZ)

echo "creating 72-hour aws access for reviewer"
echo "user: $REVIEWER_USER"
echo "expires: $EXPIRY_DATE"
echo

# Create IAM user
echo "creating iam user..."
aws iam create-user --user-name "$REVIEWER_USER" --tags Key=Purpose,Value=Sprint3Demo Key=Expires,Value="$EXPIRY_DATE"

# Create access key
echo "generating access key..."
ACCESS_KEY=$(aws iam create-access-key --user-name "$REVIEWER_USER" --output json)

ACCESS_KEY_ID=$(echo $ACCESS_KEY | jq -r '.AccessKey.AccessKeyId')
SECRET_ACCESS_KEY=$(echo $ACCESS_KEY | jq -r '.AccessKey.SecretAccessKey')

echo "access key created: $ACCESS_KEY_ID"

# Create policy with time condition
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

POLICY_DOC=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadOnlyAccessWithExpiry",
      "Effect": "Allow",
      "Action": [
        "logs:Get*",
        "logs:Describe*",
        "logs:Filter*",
        "lambda:Get*",
        "lambda:List*",
        "lambda:Invoke",
        "states:Describe*",
        "states:List*",
        "states:GetExecutionHistory",
        "states:StartExecution",
        "events:List*",
        "events:Describe*",
        "events:PutEvents",
        "sns:List*",
        "sns:Get*",
        "config:Describe*",
        "config:Get*"
      ],
      "Resource": "*",
      "Condition": {
        "DateLessThan": {
          "aws:CurrentTime": "$EXPIRY_DATE"
        }
      }
    },
    {
      "Sid": "DenyAfterExpiry",
      "Effect": "Deny",
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "DateGreaterThan": {
          "aws:CurrentTime": "$EXPIRY_DATE"
        }
      }
    }
  ]
}
EOF
)

echo "attaching policy with 72-hour expiry..."
aws iam put-user-policy \
  --user-name "$REVIEWER_USER" \
  --policy-name ReadOnlyWithExpiry \
  --policy-document "$POLICY_DOC"

# Save credentials
cat > reviewer-credentials.json <<EOF
{
  "access_key_id": "$ACCESS_KEY_ID",
  "secret_access_key": "$SECRET_ACCESS_KEY",
  "region": "us-east-1",
  "expires": "$EXPIRY_DATE",
  "permissions": "read-only",
  "user_name": "$REVIEWER_USER",
  "auto_expires": true
}
EOF

echo
echo "credentials saved to reviewer-credentials.json"
echo

# Create cleanup reminder
cat > cleanup_after_72h.sh <<EOF
#!/bin/bash
# Run this after demo to clean up reviewer access

aws iam delete-access-key --user-name "$REVIEWER_USER" --access-key-id "$ACCESS_KEY_ID"
aws iam delete-user-policy --user-name "$REVIEWER_USER" --policy-name ReadOnlyWithExpiry
aws iam delete-user --user-name "$REVIEWER_USER"

echo "reviewer access cleaned up"
rm reviewer-credentials.json
rm cleanup_after_72h.sh
EOF

chmod +x cleanup_after_72h.sh

echo "setup complete!"
echo
echo "credentials file: reviewer-credentials.json (do not commit)"
echo "cleanup script: cleanup_after_72h.sh (run after 72 hours)"
echo
echo "access expires automatically at: $EXPIRY_DATE"
echo "credentials will stop working after expiry"
echo
echo "to test:"
echo "  export AWS_ACCESS_KEY_ID=$ACCESS_KEY_ID"
echo "  export AWS_SECRET_ACCESS_KEY=$SECRET_ACCESS_KEY"
echo "  aws sts get-caller-identity"

