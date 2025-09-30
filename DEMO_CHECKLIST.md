# AIER Alert System - Demo Checklist

## Pre-Demo QA Checks

Run these checks before showing your team:

### 1. Security Check ✅

```bash
cd /Volumes/Exchange/projects/capstone/data_viz
bash scripts/00_security_check.sh
```

**Expected output:**
```
✓ No AWS access keys found
✓ No private key files found
✓ No secret files found
✓ No data files found
✓ .gitignore exists
✓ Key patterns found in .gitignore
✓ No sensitive files in staging area
✓ Security check passed - safe to push
```

### 2. AWS Credentials Working ✅

```bash
export AWS_PROFILE=paid
aws sts get-caller-identity
```

**Expected output:**
```json
{
    "UserId": "...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/example-aws-user"
}
```

### 3. Check Current AWS Resources ✅

```bash
# Should show nothing (clean state)
aws s3 ls | grep -i aier
aws dynamodb list-tables | grep -i aier
aws lambda list-functions --query 'Functions[?contains(FunctionName, `aier`)].FunctionName'
```

### 4. Terraform Initialization (Dry-Run) ✅

```bash
cd terraform
terraform init
```

**Expected output:**
```
Terraform has been successfully initialized!
```

### 5. Terraform Plan (Preview) ✅

```bash
terraform plan
```

**Expected output:**
```
Plan: 15 to add, 0 to change, 0 to destroy
```

**What it shows:**
- 2 S3 buckets
- 1 DynamoDB table
- 1 Lambda function
- 1 CloudFront distribution
- IAM roles and policies
- CloudWatch log groups

---

## Automated Demo Script

### Quick Demo

Run the complete automated demo:

```bash
cd /Volumes/Exchange/projects/capstone/data_viz
bash scripts/demo.sh
```

**What it does:**
1. ✅ Security check
2. ✅ AWS credentials verification
3. ✅ List current resources
4. ✅ Terraform init
5. ✅ Terraform plan (preview)
6. ✅ Show team user configuration
7. ✅ Display repository structure
8. ✅ List documentation
9. ✅ List scripts
10. ✅ Summary and next steps

**Duration**: ~5-10 minutes (with pauses for review)

---

## Manual Demo for Team

### Presentation Flow

#### Slide 1: Project Overview
```
"We've built a complete healthcare data visualization system
using AWS infrastructure, Terraform, and DevSecOps practices."
```

**Show**: `README.md`

#### Slide 2: Security First
```bash
bash scripts/00_security_check.sh
```

```
"All credentials are protected. Nothing sensitive goes to GitHub."
```

**Show**: Security check passing

#### Slide 3: AWS Integration
```bash
export AWS_PROFILE=paid
aws sts get-caller-identity
```

```
"We're connected to our paid AWS account."
```

**Show**: AWS account info

#### Slide 4: Infrastructure as Code
```bash
cd terraform
cat main.tf | head -50
```

```
"Our entire infrastructure is defined in code.
Terraform will create all these AWS resources for us."
```

**Show**: Terraform code

#### Slide 5: Infrastructure Preview
```bash
terraform plan
```

```
"Let me show you what will be created...
[Walk through the plan output]
- S3 buckets for data and frontend
- DynamoDB for patient records
- Lambda for data processing
- CloudFront for global distribution"
```

**Show**: Terraform plan output

#### Slide 6: Workflow Scripts
```bash
cd ..
ls -1 scripts/
```

```
"We have numbered workflow scripts that make deployment easy:
01 - Initialize
02 - Plan
03 - Apply (deploy)
04 - Verify
99 - Destroy (cleanup)"
```

**Show**: Script listing

#### Slide 7: Team Access
```bash
cat scripts/create_team_users.sh | grep -A 5 "TEAM_MEMBERS"
```

```
"Each team member gets their own IAM user with credentials.
The script creates: javi, shay, cuoung, cyberdog, crystal"
```

**Show**: Team members in script

#### Slide 8: Documentation
```bash
ls -1 docs/
```

```
"Complete documentation for:
- Setup and workflow
- AWS console viewing
- Team credential management
- Data pipeline architecture
- Security best practices"
```

**Show**: Documentation files

#### Slide 9: Data Pipeline
```bash
cat scripts/data-pipeline.py | head -30
```

```
"Our data pipeline:
1. Downloads Kaggle diabetes dataset
2. Validates and cleans data
3. Anonymizes for HIPAA compliance
4. Uploads to S3
5. Triggers Lambda processing
6. Populates DynamoDB"
```

**Show**: Pipeline code

#### Slide 10: Repository Structure
```bash
tree -L 2 -I 'node_modules|venv|.terraform'
```

```
"Clean, organized structure:
- Documentation in docs/
- Scripts for workflow
- Terraform for infrastructure
- Frontend (Vue + TypeScript)
- Backend (FastAPI)"
```

**Show**: Directory tree

---

## Q&A Preparation

### Common Questions

**Q: Are credentials safe?**
**A:** Yes, show `.gitignore` protecting:
```bash
cat .gitignore | grep -A 5 "credentials"
```

**Q: How do team members get access?**
**A:** Show workflow:
```bash
cat docs/TEAM_CREDENTIALS_WORKFLOW.md | head -50
```

**Q: Can we view in AWS Console?**
**A:** Yes, show:
```bash
cat docs/CONSOLE_VIEWING.md | head -30
```

**Q: How much does it cost?**
**A:** Show estimate:
```
Development: $5-15/month
- S3: <$1
- DynamoDB: $1-5
- Lambda: <$1 (free tier)
- CloudFront: $1-5
```

**Q: How long to deploy?**
**A:** 
```
- Terraform apply: 5-10 minutes
- Data upload: 1-2 minutes
- Total setup: ~15 minutes
```

**Q: Can we test without deploying?**
**A:** Yes, show:
```bash
terraform plan  # Preview only
```

---

## Live Deployment Demo (Optional)

If you want to actually deploy during demo:

### Step 1: Deploy Infrastructure
```bash
bash scripts/03_apply_terraform.sh
# Type 'yes' when prompted
```

**Duration**: 5-10 minutes

**Watch in AWS Console** (separate browser window):
- S3: https://s3.console.aws.amazon.com/
- DynamoDB: https://console.aws.amazon.com/dynamodb/
- Lambda: https://console.aws.amazon.com/lambda/

### Step 2: Verify Deployment
```bash
bash scripts/04_verify_deployment.sh
```

### Step 3: Show Resources in Console
Open browser to AWS Console and show:
- S3 buckets created
- DynamoDB table with indexes
- Lambda function configured
- CloudFront distribution deploying

### Step 4: Cleanup (After Demo)
```bash
bash scripts/99_destroy_terraform.sh
# Type 'destroy' and 'yes' to confirm
```

**Duration**: 5-10 minutes

---

## Screenshots to Prepare

### Before Demo

Take screenshots of:

1. **AWS Console - Before**
   - S3: No AIER buckets
   - DynamoDB: No AIER tables
   - Lambda: No AIER functions

2. **Terraform Plan Output**
   ```bash
   terraform plan > terraform-plan.txt
   ```

3. **Security Check Passing**
   ```bash
   bash scripts/00_security_check.sh > security-check.txt
   ```

4. **Repository Structure**
   ```bash
   tree -L 2 > structure.txt
   ```

### After Demo (if deploying)

5. **AWS Console - After**
   - S3: AIER buckets visible
   - DynamoDB: AIER table with data
   - Lambda: AIER function deployed

6. **Verification Output**
   ```bash
   bash scripts/04_verify_deployment.sh > verification.txt
   ```

---

## Demo Script Talking Points

### Opening (30 seconds)
"We've built a complete healthcare data visualization system with AWS infrastructure, automated deployment, and security-first design."

### Problem Statement (1 minute)
"Healthcare systems need resilient alert systems. We're demonstrating the infrastructure layer using real medical data from Kaggle."

### Solution Overview (2 minutes)
"Our solution uses:
- Infrastructure as Code (Terraform)
- AWS cloud services (S3, DynamoDB, Lambda, CloudFront)
- Secure team collaboration (IAM users)
- Automated workflows (numbered scripts)
- Complete documentation"

### Technical Demo (5-7 minutes)
1. Show security check passing
2. Show AWS connection
3. Show Terraform plan (what will be created)
4. Show workflow scripts
5. Show team user creation process
6. Show documentation

### Team Workflow (2-3 minutes)
1. You create IAM users
2. Team members clone repo
3. Team members configure credentials
4. Team members deploy infrastructure
5. Everyone can view in AWS Console

### Closing (1 minute)
"Everything is ready to push to GitHub. Team members can clone and deploy independently. All credentials are protected. Complete documentation is in place."

---

## Quick Check Commands

Run these during demo to show everything works:

```bash
# 1. Security status
bash scripts/00_security_check.sh | grep "✓\|✗"

# 2. AWS identity
aws sts get-caller-identity --query '[Account,Arn]' --output text

# 3. Available scripts
ls -1 scripts/*.sh | wc -l

# 4. Documentation files
ls -1 docs/*.md | wc -l

# 5. Terraform resources to create
cd terraform && terraform plan -no-color | grep "Plan:"

# 6. Current AWS resources (should be empty initially)
aws s3 ls | grep -c aier || echo "0"
```

---

## Timing Guide

**Quick Demo (10 minutes):**
- Security check: 1 min
- AWS verification: 1 min
- Terraform plan: 3 min
- Workflow overview: 3 min
- Q&A: 2 min

**Full Demo with Deployment (30 minutes):**
- Introduction: 2 min
- Security check: 2 min
- AWS verification: 2 min
- Terraform plan: 5 min
- **Deploy infrastructure: 10 min** ⏱️
- Verify in console: 5 min
- Team workflow explanation: 2 min
- Q&A: 2 min

**Presentation Only (15 minutes):**
- Slides/overview: 5 min
- Code walkthrough: 5 min
- Documentation tour: 3 min
- Q&A: 2 min

---

## Success Criteria

Demo is successful if you can show:

- ✅ Security check passes
- ✅ AWS credentials working
- ✅ Terraform plan generates (shows 15 resources to create)
- ✅ All workflow scripts present and documented
- ✅ Team user creation ready
- ✅ Complete documentation available
- ✅ Repository ready for GitHub
- ✅ No credentials in code
- ✅ .gitignore protecting sensitive files

---

## Post-Demo Actions

After successful demo:

1. **Push to GitHub**
   ```bash
   git add .
   git commit -m "Complete AIER Alert System infrastructure"
   git push origin main
   ```

2. **Create Team IAM Users**
   ```bash
   bash scripts/create_team_users.sh
   ```

3. **Distribute Credentials**
   - Send each team member their credentials file
   - Via encrypted email or secure messaging

4. **Share Repository**
   - Send GitHub URL to team
   - Share documentation links

5. **Schedule Team Setup Session**
   - Walk team through cloning
   - Help with credential setup
   - First deployment together

---

## Ready to Demo! 🚀

**Run the automated demo:**
```bash
cd /Volumes/Exchange/projects/capstone/data_viz
bash scripts/demo.sh
```

**Or follow manual steps above for more control.**

Your team will see:
- Professional, secure infrastructure setup
- Complete documentation
- Easy-to-use workflow scripts
- Ready to deploy and learn from

**Good luck with your demo!**
