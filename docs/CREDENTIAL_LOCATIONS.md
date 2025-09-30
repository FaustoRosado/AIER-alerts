# AWS Credential Locations - Where Your Access Keys Are Stored

## Your AWS Access Keys Location

### Primary Location: `~/.aws/credentials`

This is where your AWS access keys are stored after running the setup script.

**File location:**
- **Mac/Linux**: `~/.aws/credentials` (which is `/Users/[your-username]/.aws/credentials`)
- **Windows**: `%USERPROFILE%\.aws\credentials` (which is `C:\Users\[your-username]\.aws\credentials`)

**File contents:**
```ini
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

[aier-project]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

### Configuration File: `~/.aws/config`

This stores your default region and profile settings.

**File location:**
- **Mac/Linux**: `~/.aws/config`
- **Windows**: `%USERPROFILE%\.aws\config`

**File contents:**
```ini
[default]
region = us-east-1
output = json

[profile aier-project]
region = us-east-1
output = json
```

---

## How to View Your Credentials

### Option 1: View Files Directly

**Mac/Linux:**
```bash
# View credentials
cat ~/.aws/credentials

# View config
cat ~/.aws/config
```

**Windows PowerShell:**
```powershell
# View credentials
Get-Content $env:USERPROFILE\.aws\credentials

# View config
Get-Content $env:USERPROFILE\.aws\config
```

### Option 2: Check Current Identity

```bash
# See which account/user is currently active
aws sts get-caller-identity
```

**Output shows:**
- UserId: Your IAM user ID
- Account: AWS account number (123456789012)
- Arn: Your IAM user ARN

### Option 3: List Configured Profiles

```bash
# Mac/Linux
cat ~/.aws/credentials | grep '\[.*\]'

# Windows
Get-Content $env:USERPROFILE\.aws\credentials | Select-String '\[.*\]'
```

---

## Credential Storage Hierarchy

AWS looks for credentials in this order:

### 1. Environment Variables (Highest Priority)
```bash
export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
export AWS_DEFAULT_REGION=us-east-1
```

**Check if set:**
```bash
echo $AWS_ACCESS_KEY_ID
echo $AWS_DEFAULT_REGION
```

### 2. AWS Credentials File
`~/.aws/credentials` - Stored after running `aws configure` or setup script

### 3. AWS Config File
`~/.aws/config` - Stores region and profile settings

### 4. IAM Role (EC2/Lambda/ECS)
If running on AWS infrastructure, uses attached IAM role

---

## For AIER Project

### What You Need

Your current working credentials are:
- **Account**: `123456789012`
- **User**: `example-aws-user`
- **Region**: `us-east-1`
- **Profile**: `default` (or `aier-project` if configured)

### Location of Your Keys

```bash
# Your credentials are stored here:
~/.aws/credentials

# Check them:
cat ~/.aws/credentials
```

### Active Profile

```bash
# Check which profile is active
echo $AWS_PROFILE

# If not set, it uses [default] profile
# To use aier-project profile:
export AWS_PROFILE=aier-project
```

---

## Security: What IS Stored vs What Should NOT Be

### ✅ Safe to Store in ~/.aws/credentials
- AWS Access Key ID (starts with AKIA...)
- AWS Secret Access Key
- Session tokens (temporary credentials)

These files are:
- ✅ Local to your computer
- ✅ Not in Git repository (.gitignore excludes them)
- ✅ Protected by your user account permissions
- ✅ Used automatically by AWS CLI and SDKs

### ❌ NEVER Store Credentials In:
- Git repositories
- Project files
- Code files (.py, .js, .ts, .sh)
- Documentation files
- Screenshots
- Chat messages
- Email (unencrypted)

---

## How Scripts Use Your Credentials

### Terraform Scripts

```bash
bash scripts/03_apply_terraform.sh
```

**How it finds credentials:**
1. Checks for `AWS_PROFILE` environment variable
2. Falls back to `[default]` profile in `~/.aws/credentials`
3. Uses keys to authenticate with AWS
4. Creates infrastructure in your account

### Data Pipeline Scripts

```bash
python scripts/data-pipeline.py --upload
```

**How it finds credentials:**
1. Uses boto3 (AWS SDK for Python)
2. boto3 checks environment variables first
3. Then checks `~/.aws/credentials`
4. Authenticates and uploads to S3

### All Scripts

Every AWS-related script/command follows this pattern:
```
Script → AWS SDK → Credentials File (~/.aws/credentials) → AWS API
```

---

## Credential File Permissions

### Check Permissions

**Mac/Linux:**
```bash
ls -la ~/.aws/
```

**Should show:**
```
-rw-------  1 yourname  staff  116 Sep 29 20:00 config
-rw-------  1 yourname  staff  234 Sep 29 20:00 credentials
```

The `rw-------` (600) means:
- ✅ You can read and write
- ❌ No one else can read or write
- ✅ Good security!

### Fix Permissions if Needed

**Mac/Linux:**
```bash
chmod 600 ~/.aws/credentials
chmod 600 ~/.aws/config
```

**Windows:**
```powershell
# Already protected by NTFS permissions
```

---

## Backup Your Credentials

### Create Secure Backup

**Option 1: Encrypted Backup**
```bash
# Mac (using disk utility)
hdiutil create -encryption -size 10m -volname "aws-backup" ~/Desktop/aws-backup.dmg
# Copy credentials to mounted volume
cp ~/.aws/credentials /Volumes/aws-backup/
# Eject to encrypt
hdiutil eject /Volumes/aws-backup

# Linux (using gpg)
tar czf - ~/.aws | gpg -c > aws-backup.tar.gz.gpg
```

**Option 2: Password Manager**
- Copy contents of `~/.aws/credentials`
- Store in 1Password, LastPass, Bitwarden
- Add note: "AIER Project AWS Credentials"

**Option 3: Secure Note**
- Create encrypted note
- Copy access key ID and secret key
- Store in secure location

---

## Multiple AWS Accounts

If working with multiple AWS accounts, use profiles:

### View All Profiles

```bash
cat ~/.aws/credentials
```

**Example with multiple profiles:**
```ini
[default]
aws_access_key_id = AKIA...DEFAULT
aws_secret_access_key = wJal...DEFAULT

[aier-project]
aws_access_key_id = AKIA...AIER
aws_secret_access_key = wJal...AIER

[personal]
aws_access_key_id = AKIA...PERSONAL
aws_secret_access_key = wJal...PERSONAL
```

### Switch Between Profiles

```bash
# Use specific profile
export AWS_PROFILE=aier-project

# Verify which profile is active
aws sts get-caller-identity

# Use different profile for one command
aws s3 ls --profile personal
```

---

## Regenerating Credentials

If you need to create new access keys:

### Via AWS Console

1. Log in: https://console.aws.amazon.com/
2. Go to: IAM → Users → [your username]
3. Click: Security credentials tab
4. Click: Create access key
5. Copy both keys
6. Run: `bash scripts/aws-setup-mac.sh`
7. Enter new keys

### Via AWS CLI

```bash
# Create new access key
aws iam create-access-key --user-name example-aws-user

# Output shows new keys - save them!

# Update local configuration
bash scripts/aws-setup-mac.sh
# Enter new keys when prompted

# Delete old key (after confirming new one works)
aws iam delete-access-key \
  --user-name example-aws-user \
  --access-key-id AKIAOLD...
```

---

## Troubleshooting

### Can't Find Credentials File

**Mac/Linux:**
```bash
# Check if directory exists
ls -la ~/.aws/

# If not, create it
mkdir -p ~/.aws

# Run setup script
bash scripts/aws-setup-mac.sh
```

**Windows:**
```powershell
# Check if directory exists
Test-Path $env:USERPROFILE\.aws

# If not, create it
New-Item -ItemType Directory -Path $env:USERPROFILE\.aws

# Run setup script
.\scripts\aws-setup-windows.ps1
```

### Credentials Not Working

```bash
# Test current credentials
aws sts get-caller-identity

# If error, reconfigure
bash scripts/aws-setup-mac.sh

# Or manually edit
nano ~/.aws/credentials
```

### Wrong Profile Active

```bash
# Check current profile
echo $AWS_PROFILE

# Change profile
export AWS_PROFILE=aier-project

# Make permanent (add to ~/.bashrc or ~/.zshrc)
echo 'export AWS_PROFILE=aier-project' >> ~/.zshrc
```

---

## Quick Reference

### View Your Credentials
```bash
cat ~/.aws/credentials
```

### View Your Config
```bash
cat ~/.aws/config
```

### Check Active Identity
```bash
aws sts get-caller-identity
```

### Reconfigure Credentials
```bash
bash scripts/aws-setup-mac.sh
```

### Set Profile for Session
```bash
export AWS_PROFILE=aier-project
```

### Location Summary

| What | Where |
|------|-------|
| Access Keys | `~/.aws/credentials` |
| Region/Config | `~/.aws/config` |
| Environment Variable | `$AWS_PROFILE`, `$AWS_ACCESS_KEY_ID` |
| Active Identity | `aws sts get-caller-identity` |

---

## Security Checklist

- [x] Credentials stored in `~/.aws/credentials` only
- [x] File permissions set to 600 (read/write for owner only)
- [x] `.gitignore` excludes `~/.aws/` directory
- [x] No credentials in code files
- [x] No credentials in screenshots
- [x] Secure backup created (encrypted)
- [x] Access keys rotated every 90 days
- [x] MFA enabled (if possible)

---

**Your AWS access keys are safely stored in `~/.aws/credentials` and ready for use!** 🔐
