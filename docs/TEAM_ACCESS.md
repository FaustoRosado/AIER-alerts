# Team Member AWS Access - Simple Guide

## AWS Lab Account Limitation

Your AWS account (`example-aws-user` in account `123456789012`) **does not have** federation permissions. This is normal for AWS lab/academy/learner accounts.

### What Doesn't Work
❌ Console view link generation (requires `sts:GetFederationToken`)

### What DOES Work ✅
✅ Direct AWS CLI access via setup scripts  
✅ All Terraform infrastructure deployment  
✅ All data pipeline operations  
✅ Full development workflow  

---

## Recommended Approach for Your Team

### Option 1: Direct Credentials (Recommended for Lab Accounts)

Each team member gets their own AWS credentials and configures them locally.

#### For Team Lead

1. **Create IAM users for each team member** (if you have permissions):
```bash
aws iam create-user --user-name aier-dev-alice
aws iam create-user --user-name aier-dev-bob
```

2. **Attach policy** (for development):
```bash
# Use existing policy or create custom one
aws iam attach-user-policy \
    --user-name aier-dev-alice \
    --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
```

3. **Create access keys**:
```bash
aws iam create-access-key --user-name aier-dev-alice
```

4. **Share credentials securely**:
   - Use encrypted email
   - Use password manager with secure sharing
   - Use Slack/Teams direct message (not public channels)
   - **Never** commit to Git

#### For Team Members

1. **Run setup script**:

   **Mac/Linux:**
   ```bash
   cd AIER-alerts
   bash scripts/aws-setup-mac.sh
   ```

   **Windows:**
   ```powershell
   cd AIER-alerts
   .\scripts\aws-setup-windows.ps1
   ```

2. **Enter credentials** when prompted:
   - AWS Access Key ID: [provided by team lead]
   - AWS Secret Access Key: [provided by team lead]
   - Region: us-east-1

3. **Verify connection**:
   ```bash
   aws sts get-caller-identity
   ```

4. **Start working**:
   ```bash
   bash scripts/01_init_terraform.sh
   bash scripts/02_plan_terraform.sh
   # etc.
   ```

---

### Option 2: Shared Credentials (Simple but Less Secure)

If IAM user creation is restricted, team members can share the same credentials.

⚠️ **Important**:
- Only use for development/learning
- Never use in production
- Everyone has same permissions
- Harder to audit who did what

#### For Team Lead

Share these credentials securely:
```
AWS_ACCESS_KEY_ID=[your access key]
AWS_SECRET_ACCESS_KEY=[your secret key]
AWS_DEFAULT_REGION=us-east-1
```

#### For Team Members

Run setup script and enter the shared credentials:
```bash
bash scripts/aws-setup-mac.sh
# Enter shared credentials when prompted
```

---

### Option 3: AWS Console Access (If Available)

If team members have AWS console login:

1. **Log in to AWS Console**:
   - URL: https://console.aws.amazon.com/
   - Account ID: 123456789012
   - Username: [provided by team lead]
   - Password: [provided by team lead]

2. **View resources manually**:
   - S3: https://s3.console.aws.amazon.com/
   - DynamoDB: https://console.aws.amazon.com/dynamodb/
   - Lambda: https://console.aws.amazon.com/lambda/
   - CloudFront: https://console.aws.amazon.com/cloudfront/

3. **Still need CLI for deployment**:
   - Run setup script for CLI access
   - Console is view-only for most operations

---

## Quick Reference for Team Members

### First Time Setup

```bash
# 1. Clone repository
git clone https://github.com/[org]/AIER-alerts.git
cd AIER-alerts

# 2. Configure AWS (enter credentials when prompted)
bash scripts/aws-setup-mac.sh

# 3. Verify
aws sts get-caller-identity

# 4. You're ready!
bash scripts/01_init_terraform.sh
```

### Daily Use

```bash
# Activate AWS profile (if needed)
export AWS_PROFILE=aier-project

# Or on Windows
$env:AWS_PROFILE = "aier-project"

# Deploy infrastructure
bash scripts/02_plan_terraform.sh
bash scripts/03_apply_terraform.sh

# Verify deployment
bash scripts/04_verify_deployment.sh
```

---

## Viewing Infrastructure

### Command Line (Always Available)

```bash
# List S3 buckets
aws s3 ls | grep aier

# List DynamoDB tables
aws dynamodb list-tables

# List Lambda functions
aws lambda list-functions --query 'Functions[?contains(FunctionName, `aier`)].FunctionName'

# Get CloudFront distributions
aws cloudfront list-distributions --query 'DistributionList.Items[*].[Id,DomainName,Status]' --output table
```

### AWS Console (If You Have Access)

Direct links to view resources:
- **S3**: https://s3.console.aws.amazon.com/s3/buckets?region=us-east-1
- **DynamoDB**: https://console.aws.amazon.com/dynamodbv2/home?region=us-east-1#tables
- **Lambda**: https://console.aws.amazon.com/lambda/home?region=us-east-1#/functions
- **CloudFront**: https://console.aws.amazon.com/cloudfront/v3/home

---

## Security Best Practices

### DO ✅
- Store credentials in `~/.aws/credentials` (done by setup script)
- Use separate credentials per team member (if possible)
- Set environment variable: `export AWS_PROFILE=aier-project`
- Run security check before commits: `bash scripts/00_security_check.sh`
- Log out / clear credentials when done
- Rotate credentials every 90 days

### DON'T ❌
- **Never** commit credentials to Git
- **Never** share credentials in public channels
- **Never** post credentials in screenshots
- **Never** commit `.env` files
- **Never** hardcode credentials in code
- **Never** use root account credentials

---

## Troubleshooting

### "Credentials not found"

```bash
# Check current identity
aws sts get-caller-identity

# If fails, reconfigure
bash scripts/aws-setup-mac.sh
```

### "Access Denied" errors

```bash
# Verify you're using correct profile
echo $AWS_PROFILE

# Check what policies you have
aws iam list-attached-user-policies --user-name [your-username]

# Contact team lead for permission adjustment
```

### "Region not set"

```bash
# Set region explicitly
export AWS_DEFAULT_REGION=us-east-1

# Or configure permanently
aws configure set region us-east-1 --profile aier-project
```

---

## Cost Management

### Team Lead: Monitor Costs

```bash
# Get current month costs
aws ce get-cost-and-usage \
    --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
    --granularity MONTHLY \
    --metrics BlendedCost \
    --group-by Type=SERVICE

# Set billing alert (via console)
# AWS Console → Billing → Budgets → Create Budget
```

### Team Members: Be Cost-Conscious

```bash
# Destroy infrastructure when done
bash scripts/99_destroy_terraform.sh

# Check what's running
aws s3 ls
aws dynamodb list-tables
aws lambda list-functions
```

---

## Alternative: AWS CLI Credentials Export

For quick sharing (less secure, temporary use only):

### Team Lead Exports:
```bash
# Get temporary credentials
aws sts get-session-token --duration-seconds 43200

# Share output (expires in 12 hours):
{
    "AccessKeyId": "ASIA...",
    "SecretAccessKey": "...",
    "SessionToken": "...",
    "Expiration": "2024-09-30T12:00:00Z"
}
```

### Team Member Imports:
```bash
export AWS_ACCESS_KEY_ID="ASIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."

# Verify
aws sts get-caller-identity
```

---

## Summary

### What Your Team Should Do

1. ✅ Use `aws-setup-mac.sh` or `aws-setup-windows.ps1`
2. ✅ Get credentials from team lead
3. ✅ Configure AWS CLI locally
4. ✅ Follow workflow in `docs/WORKFLOW.md`
5. ✅ Use command-line tools to view infrastructure
6. ✅ (Optional) Use AWS Console if you have access

### What Your Team Cannot Do (Due to Lab Account)

- ❌ Generate federation console links
- ❌ Create IAM users (if permissions restricted)
- ❌ Modify billing settings

### But Everything Else Works! ✅

- ✅ Deploy Terraform infrastructure
- ✅ Upload data to S3
- ✅ Populate DynamoDB
- ✅ Run Lambda functions
- ✅ Access CloudFront
- ✅ Complete development workflow
- ✅ All scripts except `00_console_view_link.sh`

---

**Your team can successfully complete the entire project workflow!**

The console link limitation is minor - your team has full CLI and (possibly) console access, which is sufficient for all development and deployment tasks.
