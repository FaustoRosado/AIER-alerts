# Team Credentials Workflow - How It Works

## 🔒 Your Credentials vs Team Credentials

### Your Paid Account Credentials (NOT Shared)

**Your credentials** in `~/.aws/credentials`:
```ini
[paid]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

**Important:**
- ❌ **NEVER pushed to GitHub** (protected by .gitignore)
- ❌ **NEVER shared directly with team**
- ✅ **Only stored on your local machine**
- ✅ **Only you use this account to create IAM users**

---

## 👥 How Teammates Get AWS Access

### Step 1: You Create IAM Users (One-Time Setup)

**You run** (from your machine with paid credentials):

```bash
cd data_viz
bash scripts/create_team_users.sh
```

**What happens:**
1. ✅ Script uses YOUR paid credentials
2. ✅ Creates 5 IAM users in YOUR AWS account:
   - `aier-javi`
   - `aier-shay`
   - `aier-cuoung`
   - `aier-cyberdog`
   - `aier-crystal`
3. ✅ Generates unique credentials for each team member
4. ✅ Saves to `team-credentials/` folder (gitignored)
5. ✅ Each gets their OWN access keys

**Result:**
```
team-credentials/
├── javi-credentials.txt       # Javi's unique keys
├── shay-credentials.txt       # Shay's unique keys
├── cuoung-credentials.txt     # Cuoung's unique keys
├── cyberdog-credentials.txt   # Your team credentials
└── crystal-credentials.txt    # Crystal's unique keys
```

### Step 2: You Distribute Credentials (Securely)

**You send each teammate ONLY their file:**

```bash
# Email/Slack Javi → javi-credentials.txt
# Email/Slack Shay → shay-credentials.txt
# Email/Slack Cuoung → cuoung-credentials.txt
# Email/Slack Crystal → crystal-credentials.txt
# Keep cyberdog-credentials.txt for yourself (if you want team member access)
```

**Security:**
- ✅ Each person gets ONLY their own credentials
- ✅ Use encrypted email or secure messaging
- ✅ Delete `team-credentials/` folder after distribution
- ❌ Never commit `team-credentials/` to Git (already in .gitignore)

### Step 3: Teammates Clone Repo

**Teammates run:**

```bash
git clone https://github.com/[org]/AIER-alerts.git
cd AIER-alerts
```

**What they get:**
- ✅ All code and scripts
- ✅ Documentation
- ✅ .gitignore (protects their credentials)
- ❌ NO credentials (they provide their own)

### Step 4: Teammates Configure Their Credentials

**Each teammate runs setup script:**

**Mac/Linux:**
```bash
bash scripts/aws-setup-mac.sh
```

**Windows:**
```powershell
.\scripts\aws-setup-windows.ps1
```

**Script prompts for:**
```
AWS Access Key ID: [from their credentials file]
AWS Secret Access Key: [from their credentials file]
Region: us-east-1
```

**Script creates on THEIR machine:**
```
~/.aws/credentials
[paid]
aws_access_key_id = [their unique key]
aws_secret_access_key = [their unique secret]
```

**Result:**
- ✅ Teammate now has AWS access
- ✅ Credentials stored locally on their machine
- ✅ Their credentials never in GitHub
- ✅ They can run all scripts

---

## 🔐 Security Model

### What's in GitHub Repository

```
AIER-alerts/
├── scripts/
│   ├── aws-setup-mac.sh          ✅ Code only (no credentials)
│   ├── create_team_users.sh      ✅ Code only (no credentials)
│   └── 01_init_terraform.sh      ✅ Code only (no credentials)
├── .gitignore                     ✅ Protects credentials
└── docs/                          ✅ Documentation only
```

**What's NOT in GitHub:**
- ❌ Your paid credentials
- ❌ Team member credentials
- ❌ `~/.aws/credentials` file
- ❌ `team-credentials/` folder
- ❌ Any access keys or secrets

### .gitignore Protection

Your `.gitignore` includes:
```gitignore
# AWS credentials
.aws/
credentials
config
*.pem
*.key

# Team credentials
team-credentials/
*credentials*.txt
*password*.txt

# Secrets
.env
.env.*
secrets.json
kaggle.json
```

### Verification

**Check what would be pushed:**
```bash
cd data_viz
bash scripts/00_security_check.sh
```

**Should show:**
```
✓ No AWS access keys found
✓ No private key files found
✓ No secret files found
✓ Security check passed - safe to push
```

---

## 📋 Complete Workflow Example

### You (Team Lead with Paid Account)

```bash
# 1. Create IAM users for team
bash scripts/create_team_users.sh
# → Creates team-credentials/ folder with 5 files

# 2. Securely send each file to respective teammate
# → javi-credentials.txt → javi@email.com
# → shay-credentials.txt → shay@email.com
# → etc.

# 3. Delete credentials folder (already distributed)
rm -rf team-credentials/

# 4. Push code to GitHub
git add .
git commit -m "Initial commit"
git push origin main

# 5. Your paid credentials stay local
cat ~/.aws/credentials
# Shows YOUR paid credentials only
```

### Javi (Teammate)

```bash
# 1. Clone repository
git clone https://github.com/[org]/AIER-alerts.git
cd AIER-alerts

# 2. Receive javi-credentials.txt from team lead
# Save to ~/Downloads/javi-credentials.txt

# 3. Run setup script
bash scripts/aws-setup-mac.sh

# 4. Enter credentials when prompted
# Access Key ID: [from javi-credentials.txt]
# Secret Access Key: [from javi-credentials.txt]
# Region: us-east-1

# 5. Verify access
aws sts get-caller-identity
# Shows: aier-javi

# 6. Start working
bash scripts/01_init_terraform.sh
bash scripts/02_plan_terraform.sh
bash scripts/03_apply_terraform.sh
```

### Shay (Another Teammate)

```bash
# Same process as Javi, but with shay-credentials.txt
# Gets their OWN unique access keys
# Completely independent from Javi
```

---

## 🔄 How Scripts Use Credentials

### All Scripts Now Use "paid" Profile

Every script automatically sets:
```bash
export AWS_PROFILE=paid
```

**For you:**
- Uses YOUR paid account credentials
- Full admin access

**For teammates:**
- Uses THEIR credentials (stored in [paid] profile on their machine)
- Limited to IAM user permissions
- Can deploy/destroy infrastructure
- Cannot create new IAM users

---

## ❓ Common Questions

### Q: Will my teammates see my paid credentials?
**A:** No. Your credentials stay on your local machine only.

### Q: What credentials do teammates use?
**A:** They use the IAM user credentials you create for them via `create_team_users.sh`.

### Q: Are credentials in the GitHub repo?
**A:** No. All credentials are protected by .gitignore.

### Q: How do I verify credentials won't be pushed?
**A:** Run: `bash scripts/00_security_check.sh`

### Q: Can teammates deploy infrastructure?
**A:** Yes! They use their IAM user credentials which have developer permissions.

### Q: What if a teammate leaves?
**A:** Run: `bash scripts/delete_team_users.sh` to remove their IAM user.

### Q: How do teammates know which credentials to use?
**A:** The setup scripts automatically configure the `[paid]` profile with their credentials.

---

## 🎯 Key Takeaways

### Your Responsibilities:
1. ✅ Keep your paid credentials secure (never share, never commit)
2. ✅ Create IAM users for teammates using `create_team_users.sh`
3. ✅ Distribute credentials securely (encrypted channels)
4. ✅ Delete `team-credentials/` folder after distribution
5. ✅ Run security check before pushing: `00_security_check.sh`

### Teammates' Responsibilities:
1. ✅ Clone repository from GitHub
2. ✅ Receive credentials file from you (secure channel)
3. ✅ Run setup script with their credentials
4. ✅ Keep credentials secure (never commit)
5. ✅ Delete credentials file after configuration

### GitHub Contains:
- ✅ Code and scripts (no credentials)
- ✅ Documentation
- ✅ .gitignore protection
- ❌ Zero credentials or secrets

---

## ✅ Security Checklist

Before pushing to GitHub:

```bash
# 1. Run security check
bash scripts/00_security_check.sh

# 2. Verify no credentials staged
git status

# 3. Check .gitignore is working
git check-ignore ~/.aws/credentials
# Should output: ~/.aws/credentials

git check-ignore team-credentials/
# Should output: team-credentials/

# 4. Safe to push
git push origin main
```

---

**Your paid credentials are protected. Teammates get their own IAM user credentials. GitHub stays clean!** 🔒
