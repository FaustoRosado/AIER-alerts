# Streamlined Setup - No Repeat Steps Needed

## Current Status

### IAM Users
**Status**: Users were deleted during security cleanup  
**Action needed**: One-time recreation with secure method

---

## Streamlined Approach (Do Once)

### Create All Users Securely (One Command)

Run this streamlined script that won't expose credentials:

```bash
export AWS_PROFILE=paid
cd /Volumes/Exchange/projects/capstone/data_viz

# Create users (script prompts - answer 'yes' to create)
bash scripts/create_team_users.sh
# When prompted "User already exists", answer: no (skip)
```

**Result**: 
- ✅ 5 IAM users created
- ✅ Credentials saved to `../team-credentials/`
- ✅ No credentials displayed in terminal (fixed script)

---

## Then You're Done!

### Users Created Once ✅
**Never need to run create_team_users.sh again** unless:
- Team member leaves (delete their user)
- Adding new team members
- Complete project reset

### What Team Members Get (One Time)

Each receives their credential file with:
- Console login (account ID, username, password)
- CLI access keys (for aws-setup script)
- Instructions

### Team Members Configure Once

```bash
# Clone repo
git clone https://github.com/[username]/AIER-alerts.git
cd AIER-alerts

# Configure AWS (one time)
bash scripts/aws-setup-mac.sh
# Enter access keys from credential file

# Done! Now they can deploy anytime:
bash scripts/03_apply_terraform.sh
```

---

## Streamlined Workflow Summary

### You Do Once:
1. ✅ Create GitHub repo: `AIER-alerts`
2. ✅ Push code: `git push origin main`
3. ✅ Create IAM users: `bash scripts/create_team_users.sh` (ONCE)
4. ✅ Distribute credential files (secure channel)
5. ✅ Delete local credentials: `rm -rf ../team-credentials/`

### Team Does Once:
1. Clone repo
2. Run `aws-setup-mac.sh` with their keys
3. Done!

### Daily Work (Everyone):
```bash
# Deploy
bash scripts/03_apply_terraform.sh

# Work on code
# ...

# Cleanup
bash scripts/99_destroy_terraform.sh
```

**No repeated setup needed!**

---

## Current Action: Recreate Users One Last Time

Since users were deleted during security cleanup:

```bash
export AWS_PROFILE=paid
cd /Volumes/Exchange/projects/capstone/data_viz
bash scripts/create_team_users.sh
# Users will be created with NEW secure keys
# Credentials in: ../team-credentials/
```

This creates:
- ✅ aier-javi
- ✅ aier-shay
- ✅ aier-cuoung
- ✅ aier-cyberdog
- ✅ aier-crystal

**After this, you're DONE creating users!**

---

## Summary

**Q**: Do users need to be created again?  
**A**: Create them ONE MORE TIME (securely), then never again.

**Q**: What if I already ran the script?  
**A**: Users were deleted during security fix. Run once more with fixed script.

**Q**: After creating users, what's next?  
**A**: Just push to GitHub and distribute credentials. Done!

**Q**: Do team members recreate users?  
**A**: No! They just configure their credentials locally with setup scripts.

---

**One more run of create_team_users.sh and you're done forever!** ✅
