# AWS Access Management Guide for AIER Project

## Overview

This guide explains how to manage AWS access for team members working on the AIER Alert System Frontend Visualization project.

## Access Levels

### Full Access (Team Lead / DevOps)
- Complete control over all AWS resources
- Ability to create/modify IAM policies
- Access to billing and cost management
- Terraform state management

### Developer Access (Team Members)
- Read/write access to project resources
- Cannot modify IAM policies
- Cannot access billing information
- Can deploy and test applications

### Read-Only Access (Reviewers)
- View-only access to resources
- Access to CloudWatch logs
- Cannot modify infrastructure

## Setting Up Team Member Access

### Prerequisites

1. AWS account with administrative access
2. AWS CLI configured on local machine
3. Terraform installed

### Step 1: Create IAM User

Using AWS Console:

1. Navigate to IAM service
2. Click "Users" then "Add users"
3. Enter username (e.g., "aier-dev-john")
4. Select "Access key - Programmatic access"
5. Click "Next: Permissions"

### Step 2: Attach Policy

Attach the pre-configured policy for developers:

```bash
aws iam attach-user-policy \
    --user-name aier-dev-john \
    --policy-arn arn:aws:iam::[ACCOUNT-ID]:policy/AIERDeveloperAccess
```

### Step 3: Generate Access Keys

```bash
aws iam create-access-key --user-name aier-dev-john
```

Save the output:
- AccessKeyId
- SecretAccessKey

IMPORTANT: Store these securely. The secret key cannot be retrieved later.

### Step 4: Provide Credentials to Team Member

Send credentials securely:
- Use encrypted email
- Use a password manager with secure sharing
- Use AWS Secrets Manager for sensitive data

DO NOT:
- Send via plain text email
- Post in Slack/Discord
- Commit to Git repository

### Step 5: Team Member Setup

The team member should run the appropriate setup script:

Mac/Linux:
```bash
bash scripts/aws-setup-mac.sh
```

Windows:
```powershell
.\scripts\aws-setup-windows.ps1
```

## IAM Policy for Developers

The following policy provides appropriate access for development work:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3Access",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::aier-data-*",
        "arn:aws:s3:::aier-data-*/*"
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
        "dynamodb:Scan"
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
        "lambda:UpdateFunctionConfiguration"
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
        "logs:DescribeLogStreams"
      ],
      "Resource": "arn:aws:logs:*:*:log-group:/aws/lambda/aier-*"
    },
    {
      "Sid": "APIGatewayAccess",
      "Effect": "Allow",
      "Action": [
        "apigateway:GET",
        "apigateway:POST"
      ],
      "Resource": "arn:aws:apigateway:*::/restapis/*"
    },
    {
      "Sid": "CloudFrontAccess",
      "Effect": "Allow",
      "Action": [
        "cloudfront:GetDistribution",
        "cloudfront:ListDistributions"
      ],
      "Resource": "*"
    }
  ]
}
```

## Temporary Access for Short-Term Contributors

For reviewers or guest contributors who need temporary access:

### Option 1: Time-Limited Access Keys

Create access keys with automatic expiration:

```bash
# Create temporary user
aws iam create-user --user-name aier-temp-reviewer

# Attach read-only policy
aws iam attach-user-policy \
    --user-name aier-temp-reviewer \
    --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess

# Create access key
aws iam create-access-key --user-name aier-temp-reviewer
```

Set calendar reminder to delete after 7 days:

```bash
aws iam delete-user --user-name aier-temp-reviewer
```

### Option 2: Assume Role

For more secure temporary access, use IAM roles:

1. Create a role with appropriate permissions
2. Grant AssumeRole permission to the temporary user
3. User assumes role for limited time period

## Revoking Access

When a team member leaves or access is no longer needed:

### Step 1: Deactivate Access Keys

```bash
# List access keys for user
aws iam list-access-keys --user-name aier-dev-john

# Deactivate key
aws iam update-access-key \
    --user-name aier-dev-john \
    --access-key-id AKIAIOSFODNN7EXAMPLE \
    --status Inactive
```

### Step 2: Delete Access Keys

```bash
aws iam delete-access-key \
    --user-name aier-dev-john \
    --access-key-id AKIAIOSFODNN7EXAMPLE
```

### Step 3: Remove User (if needed)

```bash
# Detach all policies
aws iam list-attached-user-policies --user-name aier-dev-john
aws iam detach-user-policy \
    --user-name aier-dev-john \
    --policy-arn [POLICY-ARN]

# Delete user
aws iam delete-user --user-name aier-dev-john
```

## Security Best Practices

### For Team Leads

1. **Use MFA**: Enable multi-factor authentication on all accounts
2. **Rotate Keys**: Rotate access keys every 90 days
3. **Least Privilege**: Grant minimum necessary permissions
4. **Audit Regularly**: Review IAM users and permissions monthly
5. **Monitor Usage**: Check CloudTrail logs for unusual activity

### For Team Members

1. **Protect Keys**: Never commit credentials to Git
2. **Use Profiles**: Use AWS CLI profiles to manage multiple accounts
3. **Secure Storage**: Store credentials in AWS credentials file only
4. **Report Issues**: Immediately report suspected credential exposure
5. **Clean Up**: Remove local credentials when project ends

## Credential Rotation

### When to Rotate

- Every 90 days (recommended)
- When team member leaves project
- If credentials are suspected to be compromised
- Before project demo or presentation

### How to Rotate

For team members:

1. Generate new access key:
```bash
aws iam create-access-key --user-name aier-dev-john
```

2. Update local configuration:
```bash
aws configure set aws_access_key_id NEW_KEY_ID --profile aier-project
aws configure set aws_secret_access_key NEW_SECRET_KEY --profile aier-project
```

3. Test new credentials:
```bash
aws sts get-caller-identity --profile aier-project
```

4. Deactivate old key:
```bash
aws iam update-access-key \
    --user-name aier-dev-john \
    --access-key-id OLD_KEY_ID \
    --status Inactive
```

5. After confirming everything works, delete old key:
```bash
aws iam delete-access-key \
    --user-name aier-dev-john \
    --access-key-id OLD_KEY_ID
```

## Troubleshooting Access Issues

### Issue: "Access Denied" errors

**Cause**: Insufficient IAM permissions

**Solution**:
1. Verify current identity:
```bash
aws sts get-caller-identity
```

2. Check attached policies:
```bash
aws iam list-attached-user-policies --user-name [USERNAME]
```

3. Contact team lead to adjust permissions

### Issue: "Invalid credentials"

**Cause**: Incorrect access keys or expired credentials

**Solution**:
1. Verify credentials file:
```bash
cat ~/.aws/credentials
```

2. Reconfigure AWS CLI:
```bash
aws configure --profile aier-project
```

3. If keys are expired, request new keys from team lead

### Issue: "Region not available"

**Cause**: Incorrect AWS region configuration

**Solution**:
```bash
aws configure set region us-east-1 --profile aier-project
```

## Cost Management

Team members with developer access can view their resource usage but not modify billing.

### View Your Resource Usage

```bash
# List S3 buckets and sizes
aws s3 ls

# Count DynamoDB items
aws dynamodb scan --table-name aier-patient-data --select COUNT

# List Lambda functions
aws lambda list-functions
```

### Cost-Saving Tips

1. Stop EC2 instances when not in use
2. Delete unused S3 objects
3. Use appropriate Lambda memory settings
4. Clean up old DynamoDB items
5. Remove unused CloudWatch log groups

## Emergency Procedures

### Suspected Credential Compromise

If you believe your AWS credentials have been exposed:

1. **Immediately notify team lead**
2. Do not delete anything yet
3. Team lead will:
   - Deactivate compromised keys
   - Generate new keys
   - Review CloudTrail for unauthorized activity
   - Assess potential impact

### Account Lockout

If you are locked out of AWS:

1. Verify network connectivity
2. Check if keys are active (ask team lead)
3. Verify correct profile is selected
4. Request new access keys if needed

## Reference

### Useful AWS CLI Commands

```bash
# Check current identity
aws sts get-caller-identity

# List all IAM users
aws iam list-users

# View attached policies
aws iam list-attached-user-policies --user-name [USERNAME]

# Test S3 access
aws s3 ls

# Test DynamoDB access
aws dynamodb list-tables

# View CloudWatch logs
aws logs describe-log-groups
```

### Environment Variables

Set these for convenience:

```bash
export AWS_PROFILE=aier-project
export AWS_DEFAULT_REGION=us-east-1
```

## Support

For AWS access issues:

1. Check this guide first
2. Review setup scripts in `/scripts`
3. Contact team lead: [Insert contact info]
4. Email AWS support (for billing/account issues)
