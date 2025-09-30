# IAM Users Status - Current State

**Date**: September 29, 2024  
**Account**: 123456789012  
**Status**: Users exist, keys need regeneration

---

## ✅ IAM Users Exist in AWS

All 5 team members have IAM users created:
- ✅ aier-javi (no active keys - deleted for security)
- ✅ aier-shay (check keys)
- ✅ aier-cuoung (check keys)
- ✅ aier-cyberdog (check keys)
- ✅ aier-crystal (deleted, needs recreation)

**You do NOT need to create users again.**

---

## Current Situation

### What Happened
1. ✅ IAM users were created successfully
2. ⚠️ Some credentials were exposed in terminal
3. ✅ Exposed keys were deleted immediately
4. ⚠️ Credential files need to be regenerated

### What You Need Now

**Only regenerate the access keys** (users already exist in AWS)

---

## Simple Solution: Regenerate Keys Only

### Option 1: Manual Key Generation (Secure)

For each team member, generate keys without displaying:

```bash
export AWS_PROFILE=paid

# Javi
aws iam create-access-key --user-name aier-javi \
  --query 'AccessKey.[AccessKeyId,SecretAccessKey]' \
  --output text > /tmp/javi.key

# Shay  
aws iam create-access-key --user-name aier-shay \
  --query 'AccessKey.[AccessKeyId,SecretAccessKey]' \
  --output text > /tmp/shay.key

# Cuoung
aws iam create-access-key --user-name aier-cuoung \
  --query 'AccessKey.[AccessKeyId,SecretAccessKey]' \
  --output text > /tmp/cuoung.key

# Cyberdog (you)
aws iam create-access-key --user-name aier-cyberdog \
  --query 'AccessKey.[AccessKeyId,SecretAccessKey]' \
  --output text > /tmp/cyberdog.key

# Crystal (recreate user first if deleted)
aws iam create-user --user-name aier-crystal
aws iam attach-user-policy --user-name aier-crystal \
  --policy-arn arn:aws:iam::123456789012:policy/AIERDeveloperAccess
aws iam create-access-key --user-name aier-crystal \
  --query 'AccessKey.[AccessKeyId,SecretAccessKey]' \
  --output text > /tmp/crystal.key
```

Then view each file individually:
```bash
cat /tmp/javi.key
# Copy to credential file or send to Javi directly
# Then delete: rm /tmp/javi.key
```

### Option 2: Use Script But Redirect Output

```bash
export AWS_PROFILE=paid
cd /Volumes/Exchange/projects/capstone/data_viz

# Run script with output hidden
bash scripts/create_team_users.sh > /dev/null 2>&1

# Credential files will be in: ../team-credentials/
# You can then securely view and distribute them
```

---

## Recommended Simple Approach

### What You Should Do Now

1. **DON'T recreate the users** (they already exist)

2. **Generate access keys manually** (one at a time, view privately):

```bash
export AWS_PROFILE=paid

# Example for Javi
aws iam create-access-key --user-name aier-javi

# Output will show:
# {
#   "AccessKeyId": "AKIA...",
#   "SecretAccessKey": "..."
# }

# Copy these to a secure note/email
# Send to Javi privately
# Then he runs: bash scripts/aws-setup-mac.sh
# And enters those keys when prompted
```

3. **Repeat for each team member** when they're ready to start

---

## Alternative: Share Console Access Only (Initially)

Team members can start by just logging into AWS Console:

### Create Console Passwords
```bash
export AWS_PROFILE=paid

aws iam create-login-profile --user-name aier-javi \
  --password "TempJavi2024!" --password-reset-required

aws iam create-login-profile --user-name aier-shay \
  --password "TempShay2024!" --password-reset-required

# etc for each team member
```

Then tell team members:
- URL: https://console.aws.amazon.com/
- Account: 123456789012
- Username: aier-[yourname]
- Password: [temp password - will be forced to change]

They can **view resources** in console while you're presenting/demoing!

---

## Streamlined Workflow

### For You (Team Lead)

**Already Done** ✅:
- IAM users exist
- Policy attached
- Repository ready

**Still Need** 📝:
- Generate access keys (when team members need CLI access)
- OR create console passwords (for immediate console viewing)

### For Team Members

**Console Access** (Immediate):
```
1. Get temp password from you
2. Login to AWS Console
3. Change password
4. View resources as you deploy
```

**CLI Access** (For deployment):
```
1. Get access keys from you
2. Clone repo
3. Run: bash scripts/aws-setup-mac.sh
4. Enter keys
5. Deploy infrastructure
```

---

## Summary

✅ **Users created**: All 5 IAM users exist in AWS  
✅ **Policy attached**: All have developer permissions  
✅ **You're done creating users**: Don't run create_team_users.sh again  

**Next**: Just generate access keys OR console passwords as needed per team member

---

## Quick Commands

### Check users exist:
```bash
aws iam list-users | grep aier
```

### Generate keys for one member:
```bash
aws iam create-access-key --user-name aier-[name]
```

### Create console password:
```bash
aws iam create-login-profile --user-name aier-[name] \
  --password "TempPass123!" --password-reset-required
```

### View user details:
```bash
aws iam get-user --user-name aier-[name]
```

---

**Users are created. No need to run create script again. Just generate keys as needed!** ✅
