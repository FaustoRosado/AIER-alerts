# AIER Alert System - Team Workflow Guide

## Complete Workflow for Team Members

This guide provides step-by-step instructions for team members to set up, deploy, and manage the AIER Alert System infrastructure.

---

## Prerequisites

Before starting, ensure you have:
- AWS access credentials (provided by team lead)
- Mac, Linux, or Windows computer
- Internet connection

---

## Workflow Scripts

All scripts are in the `scripts/` directory. Run them in order:

### Script Overview

```
scripts/
├── aws-setup-mac.sh              # Initial AWS setup (Mac/Linux)
├── aws-setup-windows.ps1         # Initial AWS setup (Windows)
├── download-dataset.py           # Download Kaggle diabetes dataset
├── data-pipeline.py              # Process and upload data
│
├── 00_console_view_link.sh       # Generate read-only console URL
├── 01_init_terraform.sh          # Initialize Terraform
├── 02_plan_terraform.sh          # Review infrastructure changes
├── 03_apply_terraform.sh         # Deploy infrastructure
├── 04_verify_deployment.sh       # Verify resources created
└── 99_destroy_terraform.sh       # Delete all resources
```

---

## Step-by-Step Workflow

### Phase 1: Initial Setup (One-time)

#### 1.1 Configure AWS Credentials

**Mac/Linux:**
```bash
cd data_viz
bash scripts/aws-setup-mac.sh
```

**Windows PowerShell:**
```powershell
cd data_viz
.\scripts\aws-setup-windows.ps1
```

What this does:
- Prompts for AWS credentials (from team lead)
- Configures AWS CLI with `aier-project` profile
- Tests connectivity
- Creates helper script for future sessions

**Output:**
```
SUCCESS: AWS connection established
Your AWS Identity: [account details]
```

#### 1.2 Install Required Tools

**Mac:**
```bash
# Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install tools
brew install python node terraform jq

# Python packages
pip install boto3 pandas kaggle
```

**Linux:**
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y python3 python3-pip nodejs npm jq

# Install Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Python packages
pip3 install boto3 pandas kaggle
```

**Windows:**
```powershell
# Install Chocolatey (if not installed)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install tools
choco install python nodejs terraform jq -y

# Python packages
pip install boto3 pandas kaggle
```

---

### Phase 2: Data Preparation

#### 2.1 Download Dataset

```bash
cd data_viz
python scripts/download-dataset.py
```

**First-time setup:**
1. Create Kaggle account: https://www.kaggle.com
2. Go to Account → API → Create New API Token
3. Save `kaggle.json` to `~/.kaggle/` (Mac/Linux) or `%USERPROFILE%\.kaggle\` (Windows)

**Output:**
```
SUCCESS: Dataset ready for processing
File: data/diabetes.csv
```

#### 2.2 Process Dataset (Optional - can do after infrastructure)

```bash
python scripts/data-pipeline.py
```

This validates, cleans, and anonymizes the data. Use `--upload` flag after infrastructure is deployed.

---

### Phase 3: Infrastructure Deployment

#### 3.1 Initialize Terraform

```bash
cd data_viz
bash scripts/01_init_terraform.sh
```

**What this does:**
- Downloads Terraform providers (AWS)
- Initializes backend
- Prepares for deployment

**Output:**
```
Terraform has been successfully initialized!
```

#### 3.2 Plan Infrastructure

```bash
bash scripts/02_plan_terraform.sh
```

**What this does:**
- Shows what will be created
- Estimates costs
- Saves plan to file

**Review the output carefully:**
```
Plan: 15 to add, 0 to change, 0 to destroy
```

Resources that will be created:
- 2 S3 buckets (data storage + frontend)
- 1 DynamoDB table (patient data)
- 1 Lambda function (data processor)
- 1 CloudFront distribution (CDN)
- IAM roles and policies
- CloudWatch log groups

#### 3.3 Deploy Infrastructure

```bash
bash scripts/03_apply_terraform.sh
```

**Confirmation required:**
- Type `yes` when prompted
- Deployment takes 5-10 minutes
- Creates all AWS resources

**Output:**
```
Apply complete! Resources: 15 added, 0 changed, 0 destroyed.

Outputs:
cloudfront_url = "https://d1234567890.cloudfront.net"
data_bucket_name = "aier-data-dev"
dynamodb_table_name = "aier-patient-data"
```

#### 3.4 Verify Deployment

```bash
bash scripts/04_verify_deployment.sh
```

**Checks:**
- S3 buckets exist
- DynamoDB table created
- Lambda function deployed
- CloudFront distribution active

**Output:**
```
✓ Found 2 AIER S3 bucket(s)
✓ Found 1 AIER DynamoDB table(s)
✓ Found 1 AIER Lambda function(s)
✓ Found 1 AIER CloudFront distribution(s)
```

---

### Phase 4: Data Upload

#### 4.1 Upload Processed Data to AWS

```bash
python scripts/data-pipeline.py --upload
```

**What this does:**
- Validates dataset
- Cleans and anonymizes
- Engineers features (risk scores)
- Uploads to S3
- Triggers Lambda processing
- Populates DynamoDB

**Output:**
```
Uploaded: s3://aier-data-dev/processed/diabetes_processed_20241001.csv
DynamoDB populated with 768 records
```

---

### Phase 5: Console Access (For Viewing)

#### 5.1 View in AWS Console Browser (Recommended)

**No special script needed!** Team members can log directly into AWS Console:

**URL**: https://console.aws.amazon.com/

**Login with**:
- Account ID: `123456789012`
- IAM Username: [from team lead]
- Password: [from team lead]

**Then navigate to**:
- **S3**: https://s3.console.aws.amazon.com/s3/buckets?region=us-east-1
- **DynamoDB**: https://console.aws.amazon.com/dynamodbv2/home?region=us-east-1#tables
- **Lambda**: https://console.aws.amazon.com/lambda/home?region=us-east-1#/functions
- **CloudFront**: https://console.aws.amazon.com/cloudfront/v3/home

**Watch resources appear/disappear** as you run Terraform scripts!

**See**: `docs/CONSOLE_VIEWING.md` for detailed guide with screenshots workflow.

#### 5.2 Console View Link (Alternative - Requires Admin)

```bash
bash scripts/00_console_view_link.sh
```

**Note**: Requires `sts:GetFederationToken` permission (not available in lab accounts).

**Alternative**: Use direct console login (5.1 above) - works perfectly!

---

### Phase 6: Development

#### 6.1 Start Backend

```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

**Access:**
- API: http://localhost:8000
- Docs: http://localhost:8000/docs

#### 6.2 Start Frontend

```bash
cd frontend
npm install
npm run dev
```

**Access:**
- Frontend: http://localhost:5173

---

### Phase 7: Cleanup (When Done)

#### 7.1 Destroy Infrastructure

```bash
bash scripts/99_destroy_terraform.sh
```

**⚠️ WARNING:**
- Deletes ALL resources
- Deletes ALL data
- Cannot be undone
- Type `destroy` to confirm

**Use this:**
- After demo/testing
- To avoid AWS charges
- At end of sprint

---

## Common Tasks

### View CloudWatch Logs

```bash
# Lambda logs
aws logs tail /aws/lambda/aier-data-processor --follow

# API Gateway logs (if configured)
aws logs tail /aws/apigateway/aier-api --follow
```

### Check S3 Contents

```bash
# List buckets
aws s3 ls | grep aier

# List files in data bucket
aws s3 ls s3://aier-data-dev/processed/
```

### Query DynamoDB

```bash
# Scan table (first 10 items)
aws dynamodb scan --table-name aier-patient-data --limit 10

# Get specific patient
aws dynamodb get-item \
  --table-name aier-patient-data \
  --key '{"patient_id":{"S":"PT-00001"},"timestamp":{"N":"1640995200"}}'
```

### Test API Endpoints

```bash
# Health check
curl http://localhost:8000/health

# Get patients
curl http://localhost:8000/api/patients?limit=10

# Get statistics
curl http://localhost:8000/api/statistics
```

---

## Troubleshooting

### AWS Credentials Not Working

```bash
# Check current identity
aws sts get-caller-identity

# Reconfigure if needed
aws configure --profile aier-project
```

### Terraform State Locked

```bash
# If terraform is stuck
cd terraform
terraform force-unlock [LOCK_ID from error message]
```

### Port Already in Use

```bash
# Find process using port 8000
lsof -i :8000

# Kill process
kill -9 [PID]
```

### Dataset Not Found

```bash
# Re-download dataset
python scripts/download-dataset.py

# Check if file exists
ls -lh data/diabetes.csv
```

---

## Cost Management

### Estimated Costs (Development)

- **S3 Storage**: <$1/month
- **DynamoDB**: $1-5/month (on-demand)
- **Lambda**: <$1/month (free tier)
- **CloudFront**: $1-5/month
- **Total**: $5-15/month

### Cost-Saving Tips

1. **Destroy when not in use:**
   ```bash
   bash scripts/99_destroy_terraform.sh
   ```

2. **Monitor usage:**
   ```bash
   aws ce get-cost-and-usage \
     --time-period Start=2024-01-01,End=2024-01-31 \
     --granularity MONTHLY \
     --metrics BlendedCost
   ```

3. **Set billing alerts** (via AWS Console)

---

## Security Checklist

Before pushing to GitHub:

- [ ] No AWS credentials in code
- [ ] No API keys hardcoded
- [ ] `.gitignore` properly configured
- [ ] `kaggle.json` not in repo
- [ ] Data files excluded
- [ ] `.env` files excluded

**Check:**
```bash
cd data_viz
git status
# Verify no sensitive files listed
```

---

## Team Collaboration

### For Reviewers (Read-Only Access)

1. Get console URL from team member:
   ```bash
   bash scripts/00_console_view_link.sh
   ```

2. Access expires after 12 hours

3. Can view but not modify resources

### For Developers (Full Access)

1. Get AWS credentials from team lead

2. Run setup script:
   ```bash
   bash scripts/aws-setup-mac.sh  # or windows
   ```

3. Can deploy and modify infrastructure

---

## Quick Reference

### Daily Workflow

```bash
# 1. Activate AWS profile
source ~/.aier-aws-profile  # Mac/Linux
# or
. $HOME\aier-aws-profile.ps1  # Windows

# 2. Start backend
cd backend && uvicorn app.main:app --reload &

# 3. Start frontend
cd frontend && npm run dev &

# 4. Develop and test
```

### Deploy Changes

```bash
# 1. Plan changes
bash scripts/02_plan_terraform.sh

# 2. Review plan

# 3. Apply if good
bash scripts/03_apply_terraform.sh

# 4. Verify
bash scripts/04_verify_deployment.sh
```

### End of Day

```bash
# Stop services (Ctrl+C)

# Optionally destroy to save costs
bash scripts/99_destroy_terraform.sh
```

---

## Support

### Getting Help

1. Check this workflow guide
2. Review `docs/SETUP.md`
3. Check `docs/DATA_PIPELINE.md`
4. Contact team lead
5. Check CloudWatch logs

### Common Commands

```bash
# AWS identity
aws sts get-caller-identity

# List resources
aws s3 ls
aws dynamodb list-tables
aws lambda list-functions

# Terraform status
cd terraform && terraform state list
```

---

## Best Practices

### Version Control

- Commit often
- Write descriptive messages
- Create feature branches
- Review before merging

### AWS Management

- Use descriptive resource names
- Tag all resources
- Monitor costs
- Clean up unused resources

### Security

- Never commit credentials
- Use IAM roles when possible
- Follow least privilege principle
- Rotate credentials regularly

---

## Summary

**Complete workflow in order:**

1. ✅ AWS Setup (`aws-setup-mac.sh`)
2. ✅ Download Dataset (`download-dataset.py`)
3. ✅ Initialize Terraform (`01_init_terraform.sh`)
4. ✅ Plan Infrastructure (`02_plan_terraform.sh`)
5. ✅ Deploy Infrastructure (`03_apply_terraform.sh`)
6. ✅ Verify Deployment (`04_verify_deployment.sh`)
7. ✅ Upload Data (`data-pipeline.py --upload`)
8. ✅ Start Development (backend + frontend)
9. ✅ Generate Console Link (`00_console_view_link.sh`)
10. ✅ Cleanup When Done (`99_destroy_terraform.sh`)

**Your team can now emulate this workflow independently!**
