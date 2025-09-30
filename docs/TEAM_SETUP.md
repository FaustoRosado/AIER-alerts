# Team Member Setup Guide - IAM Users

## Quick Setup for Team Lead

Create IAM users with temporary passwords for all team members in one command.

---

## Step 1: Create Team IAM Users

Run the automated script:

```bash
cd data_viz
bash scripts/create_team_users.sh
```

### What This Does

Creates IAM users for:
- **javi** (username: `aier-javi`)
- **shay** (username: `aier-shay`)
- **cuoung** (username: `aier-cuoung`)
- **cyberdog** (username: `aier-cyberdog`)
- **crystal** (username: `aier-crystal`)

Each user gets:
1. ✅ IAM username with `aier-` prefix
2. ✅ Temporary password (must change on first login)
3. ✅ AWS CLI access keys (for command line)
4. ✅ Developer policy with appropriate permissions
5. ✅ Credentials file saved in `team-credentials/`

### Permissions Granted

Team members can:
- ✅ Full access to S3 buckets (`aier-*`)
- ✅ Full access to DynamoDB tables (`aier-*`)
- ✅ Full access to Lambda functions (`aier-*`)
- ✅ Read/write CloudWatch logs
- ✅ View CloudFront distributions
- ✅ View their own IAM user info
- ✅ Run all Terraform scripts
- ✅ Deploy and destroy infrastructure

Team members cannot:
- ❌ Create new IAM users
- ❌ Modify billing settings
- ❌ Delete other users' resources
- ❌ Access root account

---

## Step 2: Distribute Credentials

### Credentials Files Created

After running the script, check:
```bash
ls -1 team-credentials/
```

You'll see:
```
javi-credentials.txt
shay-credentials.txt
cuoung-credentials.txt
cyberdog-credentials.txt
crystal-credentials.txt
```

### Secure Distribution Methods

**Option 1: Encrypted Email**
- Use encrypted email service (ProtonMail, etc.)
- Attach credential file
- Send to team member

**Option 2: Password Manager**
- Use 1Password, LastPass, Bitwarden shared vault
- Upload credential file
- Share with specific team member

**Option 3: Secure Messaging**
- Use Signal, WhatsApp (disappearing messages)
- Send credentials in separate messages
- Never use unencrypted channels

**Option 4: In-Person/Video Call**
- Share screen showing credentials
- Team member writes down manually
- Delete after confirmed

### ⚠️ NEVER:
- ❌ Commit credentials to Git
- ❌ Post in public Slack/Discord channels
- ❌ Send via unencrypted email
- ❌ Share in screenshots
- ❌ Upload to cloud storage

---

## Step 3: Team Members - First Login

### For AWS Console (Browser)

Each team member receives a credentials file with:

**Example:**
```
AWS Console Login:
URL: https://console.aws.amazon.com/
Account ID: 123456789012
IAM Username: aier-javi
Temporary Password: Abc123!@#XyzQwerty
```

**Steps:**
1. Go to: https://console.aws.amazon.com/
2. Choose "IAM user"
3. Enter Account ID: `123456789012`
4. Click "Next"
5. Enter IAM Username: `aier-[yourname]`
6. Enter Temporary Password (from credentials file)
7. **System will force password change**
8. Create new strong password (min 8 characters)
9. Confirm new password
10. You're in!

### For AWS CLI (Command Line)

Each team member gets access keys:

**Example:**
```
AWS CLI Access Keys:
AWS Access Key ID: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Region: us-east-1
```

**Steps:**
1. Open terminal
2. Navigate to project: `cd AIER-alerts`
3. Run setup script:
   ```bash
   bash scripts/aws-setup-mac.sh
   ```
4. When prompted, enter:
   - Access Key ID: [from credentials file]
   - Secret Access Key: [from credentials file]
   - Region: `us-east-1`
5. Verify:
   ```bash
   aws sts get-caller-identity
   ```
6. Should show your IAM username

---

## Step 4: Verify Team Access

### Team Lead Verification

Check all users created:
```bash
aws iam list-users --query 'Users[?contains(UserName, `aier`)].UserName' --output table
```

Expected output:
```
-------------------
|   ListUsers     |
+------------------+
|  aier-javi      |
|  aier-shay      |
|  aier-cuoung    |
|  aier-cyberdog  |
|  aier-crystal   |
+------------------+
```

Check user permissions:
```bash
aws iam list-attached-user-policies --user-name aier-javi
```

### Team Member Verification

Each member runs:
```bash
# Check identity
aws sts get-caller-identity

# Check S3 access
aws s3 ls

# Check DynamoDB access
aws dynamodb list-tables

# Check Lambda access
aws lambda list-functions
```

If all commands work without errors, access is properly configured!

---

## Complete Team Workflow

### Team Lead (One-Time Setup)

```bash
# 1. Create all team users
bash scripts/create_team_users.sh

# 2. Check generated credentials
ls team-credentials/

# 3. Securely send each file to respective team member

# 4. Clean up credentials folder after distribution
rm -rf team-credentials/
```

### Team Members (First-Time Setup)

```bash
# 1. Receive credentials file from team lead

# 2. Save file securely (not in Git repo!)

# 3. Run AWS CLI setup
bash scripts/aws-setup-mac.sh
# Enter access key ID and secret key when prompted

# 4. Verify access
aws sts get-caller-identity

# 5. Log into AWS Console
# Go to https://console.aws.amazon.com/
# Use Account ID, IAM username, temporary password
# Change password when prompted

# 6. Delete credentials file (already configured)
rm ~/Downloads/[yourname]-credentials.txt
```

---

## Team Member Quick Reference

### Daily Commands

```bash
# Activate AWS profile (if needed)
export AWS_PROFILE=aier-project

# Verify identity
aws sts get-caller-identity

# Deploy infrastructure
bash scripts/01_init_terraform.sh
bash scripts/02_plan_terraform.sh
bash scripts/03_apply_terraform.sh

# Verify deployment
bash scripts/04_verify_deployment.sh

# Upload data
python scripts/data-pipeline.py --upload

# Clean up
bash scripts/99_destroy_terraform.sh
```

### AWS Console Shortcuts

- **S3**: https://s3.console.aws.amazon.com/s3/buckets?region=us-east-1
- **DynamoDB**: https://console.aws.amazon.com/dynamodbv2/home?region=us-east-1#tables
- **Lambda**: https://console.aws.amazon.com/lambda/home?region=us-east-1#/functions
- **CloudWatch**: https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups

---

## Security Best Practices

### Password Requirements

When changing from temporary password:
- Minimum 8 characters
- At least 1 uppercase letter
- At least 1 lowercase letter
- At least 1 number
- At least 1 special character (!@#$%^&*)

### Access Key Rotation

Every 90 days:
```bash
# List current keys
aws iam list-access-keys --user-name aier-[yourname]

# Create new key
aws iam create-access-key --user-name aier-[yourname]

# Update local config with new keys
bash scripts/aws-setup-mac.sh

# Delete old key
aws iam delete-access-key --user-name aier-[yourname] --access-key-id [OLD_KEY_ID]
```

### MFA (Optional but Recommended)

Enable multi-factor authentication:
1. Log into AWS Console
2. Go to IAM → Users → [your username]
3. Security credentials tab
4. Click "Assign MFA device"
5. Follow setup with authenticator app (Google Authenticator, Authy, etc.)

---

## Troubleshooting

### "Access Denied" Error

**Problem**: Can't access AWS services
**Solution**:
```bash
# Check current identity
aws sts get-caller-identity

# If shows different user, reconfigure
bash scripts/aws-setup-mac.sh

# Verify policy attached
aws iam list-attached-user-policies --user-name aier-[yourname]
```

### "Invalid Credentials" Error

**Problem**: Access keys don't work
**Solution**:
1. Verify you copied keys correctly (no extra spaces)
2. Check credentials file in `~/.aws/credentials`
3. Reconfigure: `bash scripts/aws-setup-mac.sh`
4. Contact team lead if keys need to be regenerated

### Can't Log Into Console

**Problem**: Password doesn't work
**Solution**:
1. Double-check username format: `aier-[yourname]`
2. Verify Account ID: `123456789012`
3. Use temporary password from credentials file (first login)
4. Contact team lead to reset password if needed

### Password Reset Required

**Problem**: Console forces password change
**Solution**: This is normal! Create new strong password when prompted.

---

## Removing Team Access (Project End)

When project is complete:

```bash
# Delete all team IAM users
bash scripts/delete_team_users.sh

# Type 'delete' to confirm
```

This removes:
- All IAM users
- Their access keys
- Their console login
- Their permissions

The developer policy remains (can be deleted manually if needed).

---

## Summary

### What Team Lead Does:
1. ✅ Run `create_team_users.sh`
2. ✅ Distribute credentials securely
3. ✅ Verify team can access AWS
4. ✅ Delete credentials folder after distribution

### What Team Members Do:
1. ✅ Receive credentials file
2. ✅ Run `aws-setup-mac.sh` with access keys
3. ✅ Log into console and change password
4. ✅ Verify access with test commands
5. ✅ Delete credentials file
6. ✅ Start working on project!

### Security Reminders:
- ⚠️ Never commit credentials to Git
- ⚠️ Distribute via secure channels only
- ⚠️ Change console password on first login
- ⚠️ Rotate access keys every 90 days
- ⚠️ Enable MFA if possible
- ⚠️ Delete credentials file after setup

---

**Your team now has secure, individual AWS access with proper permissions!** 🔐
