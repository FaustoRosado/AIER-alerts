# Secure Credential Distribution Guide

## ⚠️ CRITICAL: Never Use Regular Slack or Unencrypted Email

**DON'T** send via:
- ❌ Regular Slack messages (can be accessed by admins, stored forever)
- ❌ Public Slack channels (visible to everyone)
- ❌ Regular email (unencrypted, can be intercepted)
- ❌ Text messages (SMS - unencrypted)
- ❌ Discord/Teams public channels

---

## ✅ SECURE Distribution Methods (Ranked Best to Worst)

### Option 1: In-Person or Video Call (BEST - Recommended)

**Most Secure Method:**

1. Schedule 1-on-1 video call with each team member
2. Share your screen showing their credential file
3. They write down or copy the information
4. Verify they have it
5. Delete the file immediately after

**Why this is best:**
- No digital transmission
- No stored copies
- Immediate verification
- Can delete right away

**Example script:**
```
"Hey Javi, hop on a quick video call. I'll share your AWS credentials."
[Share screen]
"Here's your info - copy it now..."
[They confirm]
"Got it? Great, I'm deleting this file now."
```

---

### Option 2: Encrypted Email (Good)

**Use encrypted email services:**

**Services that encrypt:**
- **ProtonMail** (https://proton.me/mail) - End-to-end encrypted
- **Tutanota** (https://tutanota.com) - End-to-end encrypted
- **Gmail with Confidential Mode** - Prevents forwarding/downloading

**How to use:**

1. **ProtonMail/Tutanota:**
   ```
   - Send email to team member
   - Attach credential file
   - Set expiration (24 hours)
   - Recipient needs ProtonMail/Tutanota account
   ```

2. **Gmail Confidential Mode:**
   ```
   - Compose email in Gmail
   - Click "Confidential Mode" icon (lock with clock)
   - Copy/paste credential file contents into email
   - Set expiration: 1 day
   - Set passcode via SMS (optional)
   - Send
   - Email cannot be forwarded/downloaded
   ```

**Gmail Confidential Mode Steps:**
1. Open Gmail → Compose
2. Click the lock+clock icon at bottom
3. Set: Expires in 1 day
4. Click Save
5. Paste credential file contents
6. Send to team member
7. They must view in Gmail (can't forward)

---

### Option 3: Password Manager with Secure Sharing

**Use shared password managers:**

**1Password:**
```
1. Open 1Password
2. Create "Secure Note" for each team member
3. Paste credential file contents
4. Share via 1Password link
5. Set to expire after 1 view or 24 hours
```

**Bitwarden Send:**
```
1. Go to: https://send.bitwarden.com/
2. Upload credential file
3. Set deletion after: 1 day or 1 access
4. Set password (optional)
5. Generate link
6. Send link via regular Slack/email
7. Send password separately (if set)
```

**LastPass:**
```
1. Create Secure Note
2. Share with team member's email
3. They receive notification
4. Access through LastPass
```

---

### Option 4: Encrypted File Transfer

**Create password-protected ZIP:**

**Mac/Linux:**
```bash
cd /Volumes/Exchange/projects/capstone/team-credentials

# Create encrypted ZIP for each person
zip -e javi-creds.zip javi-credentials.txt
# Enter password when prompted

# Send ZIP via regular email
# Send password via different channel (Slack DM, text, phone call)
```

**7-Zip (Windows/Mac/Linux):**
```bash
# Download 7-Zip
# Right-click file → 7-Zip → Add to archive
# Set encryption: AES-256
# Set password
# Send file via email
# Send password separately
```

---

### Option 5: Slack DM + Password Protection (Acceptable for Learning)

**If you must use Slack:**

1. **Encrypt credentials first:**
   ```bash
   cd /Volumes/Exchange/projects/capstone/team-credentials
   
   # Create password-protected file
   zip -e javi-creds.zip javi-credentials.txt
   # Password: [something strong]
   ```

2. **Send ZIP in Slack DM** (direct message, not channel):
   ```
   "Here's your AWS credentials. Password in next message."
   ```

3. **Send password in separate DM after 1 minute:**
   ```
   "Password: [the password]"
   ```

4. **Tell them to:**
   ```
   "Download the ZIP, extract with password, save somewhere secure,
   then delete the Slack messages and ZIP file."
   ```

---

## 🚨 BEST PRACTICE: Two-Channel Distribution

**Split the information across two channels:**

**Channel 1 (Email/Slack):** Send Access Key ID + Instructions
**Channel 2 (Phone/Video):** Tell them Secret Access Key verbally

**Example:**

**Email to Javi:**
```
Subject: AIER AWS Credentials - Part 1

Hi Javi,

Your AWS Access Key ID: AKIAIOSFODNN7EXAMPLE
Region: us-east-1
Username: aier-javi

I'll call you now to give you the secret access key (too sensitive for email).

Setup:
1. Clone: git clone https://github.com/[username]/AIER-alerts.git
2. cd AIER-alerts
3. Run: bash scripts/aws-setup-mac.sh
4. Enter the access key ID above
5. Enter the secret key I give you on the phone

Documentation: docs/WORKFLOW.md
```

**Phone call to Javi:**
```
"Hey Javi, your AWS secret access key is: [read slowly]
Write it down? Ok, I'll delete this now."
```

---

## Recommended Approach for Your Team

### Best Method: Video Call + Screen Share

**Steps:**
1. Schedule quick 5-min call with each person
2. Share screen showing their credential file
3. They copy/save the information
4. Verify they have it
5. Delete file while on call
6. They can start immediately

**Advantages:**
- ✅ Most secure
- ✅ Immediate verification
- ✅ Can help with setup
- ✅ No stored digital copies
- ✅ Personal touch

### Alternative: Gmail Confidential Mode

If video calls aren't possible:

```
For each team member:
1. Copy their credential file contents
2. Gmail → Compose
3. Enable Confidential Mode (expires in 1 day)
4. Paste contents
5. Send
6. Tell them via Slack: "Check your email for AWS credentials"
```

---

## What Each Team Member Gets

**Example (Javi's credentials):**
```
AWS Console Login:
URL: https://console.aws.amazon.com/
Account ID: 123456789012
IAM Username: aier-javi
Temporary Password: [16-char password]

AWS CLI Access Keys:
AWS Access Key ID: AKIAIOSFODNN7EXAMPLE[unique]
AWS Secret Access Key: [unique secret]
Region: us-east-1

Setup Instructions:
1. Clone repo
2. Run: bash scripts/aws-setup-mac.sh
3. Enter keys above
4. Done!
```

---

## After Distribution Checklist

For each team member, confirm:

1. ✅ They received credentials
2. ✅ They saved them securely (password manager recommended)
3. ✅ They can clone the repo
4. ✅ They ran aws-setup script successfully
5. ✅ They can run: `aws sts get-caller-identity`
6. ✅ They deleted any email/message with credentials

Then you delete:
```bash
rm -rf /Volumes/Exchange/projects/capstone/team-credentials/
```

---

## Summary: Recommended Distribution Flow

**For 5 team members:**

### Quick & Secure (15 minutes total):
```
1. Schedule group video call (all 5)
2. Share screen one-by-one
3. "Javi, here are your credentials..." [shows file]
4. Javi copies
5. "Shay, here are yours..." [shows file]
6. Shay copies
7. Repeat for all 5
8. Everyone confirms
9. Delete all files during call
10. Everyone can start immediately
```

### Individual Messages (If preferred):
```
Use Gmail Confidential Mode:
- 1 email per person
- Expires in 1 day
- Tell them via Slack to check email
- More private than Slack
```

---

## ⚠️ Never Do This

**DON'T:**
- ❌ Post in public Slack channels
- ❌ Send via regular email without encryption
- ❌ Leave credentials in Slack messages
- ❌ Take screenshots with credentials
- ❌ Put in shared documents

**These can be:**
- Accessed by company admins
- Stored forever
- Searchable by others
- Accidentally shared

---

## My Recommendation for Your Situation

**Best for your team:**

1. **Quick group video call** (5-10 minutes)
   - Most secure
   - Fastest
   - Everyone gets set up together
   - Can help troubleshoot immediately

2. **Or Gmail Confidential Mode** (if async)
   - One email per person
   - Expires automatically
   - Can't be forwarded
   - Reasonably secure for learning environment

**Then immediately:**
```bash
rm -rf /Volumes/Exchange/projects/capstone/team-credentials/
```

---

**What would you like to do: Group video call or Gmail Confidential Mode?** 🤔
