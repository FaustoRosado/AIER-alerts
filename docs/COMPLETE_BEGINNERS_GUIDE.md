# AIER Alert System - Complete Beginner's Guide

**For People Who Have Never Programmed or Used GitHub**

This guide assumes ZERO technical knowledge. We'll explain everything step-by-step.

---

## Table of Contents

1. [What Is This Project?](#what-is-this-project)
2. [Prerequisites - What You Need](#prerequisites)
3. [Understanding GitHub (The Basics)](#understanding-github)
4. [Understanding Terraform (The Basics)](#understanding-terraform)
5. [Understanding AWS (The Basics)](#understanding-aws)
6. [Getting Started - First Time Setup](#getting-started)
7. [Understanding the CLI (Command Line)](#understanding-the-cli)
8. [Step-by-Step Deployment Guide](#deployment-guide)
9. [Understanding the Code](#understanding-the-code)
10. [Troubleshooting](#troubleshooting)

---

## What Is This Project?

**AIER = Artificial Intelligence ER Alerts**

This is a healthcare monitoring system that:
- Stores patient data in the cloud (AWS)
- Processes medical information automatically
- Can send alerts when patients need attention
- Shows data through a website dashboard

Think of it like:
- **S3 (Storage)** = A filing cabinet in the cloud where we keep patient data
- **DynamoDB (Database)** = A digital spreadsheet that organizes patient information
- **Lambda (Processing)** = A robot that automatically processes data
- **CloudFront (Website)** = The way people access the dashboard from anywhere

---

## Prerequisites - What You Need

### 1. A Computer
- Mac, Windows, or Linux
- Internet connection

### 2. GitHub Account
- Free account at https://github.com
- Think of it as "Google Drive for code"

### 3. AWS Account
- Amazon's cloud services
- Your instructor will give you credentials (username and password)

### 4. Software to Install
We'll walk through installing each one:
- **Terminal/Command Prompt** (already on your computer)
- **Git** (for downloading code)
- **AWS CLI** (for talking to Amazon's cloud)
- **Terraform** (for creating cloud infrastructure automatically)

---

## Understanding GitHub (The Basics)

### What is GitHub?

GitHub is like Google Drive, but for code. Instead of Word documents, you store code files.

### Key Concepts

**Repository (Repo)**: A folder that contains your project
- Example: `AIER-alerts` is the repository name
- URL: `https://github.com/[your-username]/AIER-alerts`

**Clone**: Making a copy of the code on your computer
```bash
# This downloads the code to your computer
git clone https://github.com/[your-username]/AIER-alerts.git
```

**Commit**: Saving your changes with a description
```bash
# Like clicking "Save" in Word, but with a note about what you changed
git commit -m "I fixed the patient data display"
```

**Push**: Uploading your changes to GitHub
```bash
# Like uploading to Google Drive
git push
```

**Pull**: Downloading changes others made
```bash
# Like downloading someone else's updates from Google Drive
git pull
```

### Visual Explanation

```
YOUR COMPUTER                    GITHUB (Cloud)
┌─────────────┐                 ┌─────────────┐
│  Your Code  │  ─── push ───>  │  Repository │
│             │                  │             │
│             │  <─── pull ────  │             │
└─────────────┘                 └─────────────┘
```

---

## Understanding Terraform (The Basics)

### What is Terraform?

Terraform is a tool that creates cloud infrastructure automatically. Instead of clicking buttons in AWS for hours, you write what you want in a file, and Terraform creates it all for you.

**Analogy**: Terraform is like ordering a house from a catalog. Instead of building it brick by brick, you describe what you want, and it gets built automatically.

### Key Terraform Concepts

**Infrastructure as Code (IaC)**: Writing what you want in a file
```
Instead of:
1. Log into AWS
2. Click "Create S3 Bucket"
3. Name it
4. Set permissions
5. Click Save
(Repeat 20 times for different resources)

You write:
resource "aws_s3_bucket" "data" {
  bucket = "aier-patient-data"
}

Terraform does all 20 things automatically!
```

**terraform init**: Prepares Terraform (do this once)
```bash
terraform init
# Like installing an app before you can use it
```

**terraform plan**: Shows what will be created (preview)
```bash
terraform plan
# Like "Print Preview" before printing a document
# Shows: "I will create these 15 things in AWS"
```

**terraform apply**: Actually creates everything
```bash
terraform apply
# Like clicking "Print" - actually does the work
# Creates S3 buckets, databases, etc.
```

**terraform destroy**: Deletes everything
```bash
terraform destroy
# Removes all the cloud resources (to avoid charges)
```

### Terraform Workflow

```
1. terraform init     → Install/prepare
2. terraform plan     → Preview what will happen
3. terraform apply    → Create everything
4. (use your infrastructure)
5. terraform destroy  → Delete everything when done
```

---

## Understanding AWS (The Basics)

### What is AWS?

AWS (Amazon Web Services) is like renting computers and storage from Amazon. Instead of buying servers, you rent them and pay only for what you use.

### Key AWS Services We Use

**1. S3 (Simple Storage Service)**
- **What**: Cloud storage for files
- **Like**: Dropbox or Google Drive
- **We use it for**: Storing patient data files (CSV files, JSON files)
- **Cost**: ~$1/month for our project

```
S3 Bucket: aier-patient-data-123
├── patients.csv          (list of patients)
├── vitals.json          (vital signs data)
└── processed/           (processed data)
```

**2. DynamoDB**
- **What**: A database (organized data storage)
- **Like**: An Excel spreadsheet in the cloud
- **We use it for**: Structured patient records
- **Cost**: ~$5/month for our project

```
DynamoDB Table: aier-patients
┌──────────────┬─────────┬──────────────┬──────────┐
│  Patient ID  │  Name   │  Heart Rate  │  Status  │
├──────────────┼─────────┼──────────────┼──────────┤
│  PT-001      │  John   │  72          │  Normal  │
│  PT-002      │  Jane   │  95          │  Alert   │
└──────────────┴─────────┴──────────────┴──────────┘
```

**3. Lambda**
- **What**: Code that runs automatically when triggered
- **Like**: A robot that processes data when new data arrives
- **We use it for**: Processing patient data automatically
- **Cost**: ~$1/month (mostly free tier)

```
When a file is uploaded to S3 →
Lambda automatically processes it →
Saves results to DynamoDB
```

**4. CloudFront**
- **What**: Content delivery network (makes websites fast globally)
- **Like**: Having copies of your website in cities worldwide
- **We use it for**: Serving the dashboard website quickly
- **Cost**: ~$5/month

---

## Getting Started - First Time Setup

### Step 1: Install Git

**Mac**:
```bash
# Open Terminal (press Cmd+Space, type "Terminal")
# Check if git is already installed:
git --version

# If not installed, install it:
xcode-select --install
```

**Windows**:
1. Go to: https://git-scm.com/download/win
2. Download and run the installer
3. Use default settings (just click "Next")
4. Open "Git Bash" from Start Menu

**Check if it worked**:
```bash
git --version
# Should show: git version 2.x.x
```

### Step 2: Install AWS CLI

**Mac**:
```bash
# Download installer
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"

# Install
sudo installer -pkg AWSCLIV2.pkg -target /

# Check if it worked
aws --version
```

**Windows**:
1. Go to: https://aws.amazon.com/cli/
2. Download "AWS CLI MSI installer for Windows"
3. Run the installer
4. Open Command Prompt
5. Check: `aws --version`

### Step 3: Install Terraform

**Mac**:
```bash
# Install Homebrew first (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Terraform
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Check
terraform --version
```

**Windows**:
1. Go to: https://www.terraform.io/downloads
2. Download Windows version
3. Extract the ZIP file
4. Move `terraform.exe` to `C:\Windows\System32\`
5. Check: `terraform --version`

### Step 4: Get AWS Credentials

Your instructor will give you a file like this:

```
AWS Access Key ID: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLE
Region: us-east-1
```

**KEEP THIS SECRET!** These are like your password to AWS.

### Step 5: Configure AWS CLI

```bash
# Run this command
aws configure

# It will ask 4 questions:

AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
# ↑ Paste your Access Key ID from the credentials file

AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLE
# ↑ Paste your Secret Access Key

Default region name [None]: us-east-1
# ↑ Type: us-east-1

Default output format [None]: json
# ↑ Type: json
```

**Test if it worked**:
```bash
aws sts get-caller-identity

# Should show:
# {
#     "UserId": "...",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/aier-yourname"
# }
```

### Step 6: Clone the Repository

```bash
# Navigate to where you want to store the project
# On Mac:
cd ~/Documents

# On Windows:
cd C:\Users\YourName\Documents

# Clone (download) the code
git clone https://github.com/[your-username]/AIER-alerts.git

# Go into the folder
cd AIER-alerts

# Look at what's in the folder
ls
```

---

## Understanding the CLI (Command Line)

### What is the CLI?

**CLI = Command Line Interface**

Instead of clicking buttons with your mouse, you type commands to tell the computer what to do.

**Why use CLI?**
- Faster for repetitive tasks
- More powerful
- Can automate things
- Looks professional

### Essential Commands

**Navigation Commands**:

```bash
# pwd = Print Working Directory (where am I?)
pwd
# Output: /Users/yourname/Documents/AIER-alerts

# ls = List (what files are here?)
ls
# Shows files and folders

# cd = Change Directory (move to a folder)
cd terraform          # Go into terraform folder
cd ..                 # Go back one folder
cd ~/Documents        # Go to Documents folder

# mkdir = Make Directory (create a folder)
mkdir test-folder

# rm = Remove (delete a file)
rm file.txt

# rm -r = Remove Recursively (delete a folder)
rm -r test-folder
```

**File Commands**:

```bash
# cat = Show file contents
cat README.md

# head = Show first 10 lines
head terraform/main.tf

# tail = Show last 10 lines
tail scripts/demo.sh

# grep = Search for text
grep "aier" README.md
```

**Getting Help**:

```bash
# Most commands have help
terraform --help
aws --help
git --help

# Or add -h
ls -h
```

### CLI Symbols Explained

```bash
# ~ = Your home directory
cd ~              # Go to /Users/yourname/ (Mac) or C:\Users\YourName\ (Windows)

# . = Current directory
./script.sh       # Run script in current folder

# .. = Parent directory
cd ..             # Go up one folder

# / = Root directory (top level)
cd /              # Go to computer's root

# - = Previous directory
cd -              # Go back to where you just were

# * = Wildcard (any characters)
ls *.md           # Show all markdown files

# | = Pipe (send output to another command)
ls | grep "test"  # List files, then search for "test"

# > = Redirect output to file
ls > files.txt    # Save list of files to files.txt

# >> = Append to file
echo "new" >> files.txt  # Add "new" to end of file
```

### Practice Exercises

Try these in Terminal/Command Prompt:

```bash
# 1. Where am I?
pwd

# 2. What files are here?
ls

# 3. Go to Desktop
cd ~/Desktop

# 4. Create a test folder
mkdir my-test-folder

# 5. Go into it
cd my-test-folder

# 6. Create a file
echo "Hello World" > test.txt

# 7. Read the file
cat test.txt

# 8. Go back
cd ..

# 9. Delete the test folder
rm -r my-test-folder

# 10. Confirm it's gone
ls
```

---

## Step-by-Step Deployment Guide

Now let's actually deploy the AIER system to AWS!

### Step 1: Navigate to the Project

```bash
# Open Terminal (Mac) or Git Bash (Windows)

# Go to the project folder
cd ~/Documents/AIER-alerts

# Make sure you're in the right place
pwd
# Should show: /Users/yourname/Documents/AIER-alerts

# Look at what's here
ls
```

You should see:
```
README.md
docs/
scripts/
terraform/
backend/
frontend/
```

### Step 2: Initialize Terraform

```bash
# Go into the terraform folder
cd terraform

# Initialize Terraform (downloads required plugins)
terraform init
```

**What's happening?**
```
Terraform needs plugins to talk to AWS. This downloads them.

Like installing the "AWS adapter" for Terraform.

You only need to do this once (or if you delete the .terraform folder).
```

**Expected output**:
```
Initializing the backend...
Initializing provider plugins...
- Finding latest version of hashicorp/aws...
- Installing hashicorp/aws v5.x.x...

Terraform has been successfully initialized!
```

**If you see errors**, check:
- Are you in the `terraform/` folder? (`pwd` should show `.../terraform`)
- Do you have internet connection?
- Try again: `terraform init`

### Step 3: Preview What Will Be Created

```bash
# Show a preview of what Terraform will create
terraform plan
```

**What's happening?**
```
Terraform reads main.tf and variables.tf
Then checks AWS to see what already exists
Then shows you what it will create/change/delete

This is like "Print Preview" - it shows you what will happen
but doesn't actually do anything yet.
```

**You'll see output like**:
```
Terraform will perform the following actions:

  # aws_s3_bucket.patient_data will be created
  + resource "aws_s3_bucket" "patient_data" {
      + bucket = "aier-patient-data-123"
      + ...
    }

  # aws_dynamodb_table.patients will be created
  + resource "aws_dynamodb_table" "patients" {
      + name = "aier-patients"
      + ...
    }

  # aws_lambda_function.data_processor will be created
  + resource "aws_lambda_function" "data_processor" {
      + function_name = "aier-data-processor"
      + ...
    }

Plan: 15 to add, 0 to change, 0 to destroy.
```

**Understanding the output**:
- `+` = Will be created (new)
- `~` = Will be modified (changed)
- `-` = Will be deleted
- `Plan: X to add` = Summary at the bottom

**Read through this carefully!** Make sure it's creating what you expect.

### Step 4: Create the Infrastructure

```bash
# Actually create everything in AWS
terraform apply
```

**What's happening?**
```
Now Terraform actually creates everything in AWS:
1. Creates S3 buckets
2. Creates DynamoDB table
3. Creates Lambda function
4. Sets up CloudFront
5. Configures permissions
6. Sets up monitoring

This takes 5-10 minutes.
```

**Terraform will ask for confirmation**:
```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value:
```

**Type exactly**: `yes` (then press Enter)

**Expected output**:
```
aws_s3_bucket.patient_data: Creating...
aws_dynamodb_table.patients: Creating...
aws_iam_role.lambda_role: Creating...
aws_s3_bucket.patient_data: Creation complete after 3s
aws_dynamodb_table.patients: Creation complete after 8s
...
Apply complete! Resources: 15 added, 0 changed, 0 destroyed.

Outputs:

cloudfront_url = "d123456789.cloudfront.net"
s3_bucket_name = "aier-patient-data-123"
dynamodb_table = "aier-patients"
```

**This means it worked!** 🎉

### Step 5: Verify Everything Was Created

```bash
# Check S3 buckets
aws s3 ls | grep aier
# Should show: aier-patient-data-123

# Check DynamoDB tables
aws dynamodb list-tables | grep aier
# Should show: aier-patients

# Check Lambda functions
aws lambda list-functions | grep aier
# Should show: aier-data-processor

# Or use our verification script
cd ..  # Go back to main folder
bash scripts/04_verify_deployment.sh
```

### Step 6: View in AWS Console (Optional)

You can also see everything in your web browser:

1. Go to: https://console.aws.amazon.com/
2. Log in with your credentials
3. Make sure region is set to "US East (N. Virginia)" (top right)
4. Click on services:
   - **S3**: Click "S3" → Find "aier-patient-data-123"
   - **DynamoDB**: Search "DynamoDB" → Tables → "aier-patients"
   - **Lambda**: Search "Lambda" → Functions → "aier-data-processor"

### Step 7: Upload Some Test Data

```bash
# Create a simple test file
echo "patient_id,name,heart_rate,status" > test-data.csv
echo "PT-001,John,72,normal" >> test-data.csv
echo "PT-002,Jane,95,alert" >> test-data.csv

# Upload to S3
aws s3 cp test-data.csv s3://aier-patient-data-123/test-data.csv

# Verify it's there
aws s3 ls s3://aier-patient-data-123/
```

**What happened?**
1. You created a CSV file with fake patient data
2. Uploaded it to your S3 bucket
3. Lambda automatically processed it
4. Data was saved to DynamoDB

**Check if Lambda processed it**:
```bash
# View Lambda logs
aws logs tail /aws/lambda/aier-data-processor --follow
```

### Step 8: Clean Up (When Done)

**IMPORTANT**: To avoid AWS charges, delete everything when you're done:

```bash
# Go to terraform folder
cd terraform

# Delete everything
terraform destroy
```

**Terraform will ask for confirmation**:
```
Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value:
```

**Type**: `yes`

**Expected output**:
```
aws_cloudfront_distribution.frontend: Destroying...
aws_lambda_function.data_processor: Destroying...
aws_dynamodb_table.patients: Destroying...
aws_s3_bucket.patient_data: Destroying...
...
Destroy complete! Resources: 15 destroyed.
```

**Everything is now deleted from AWS. No charges!**

---

## Understanding the Code

### Project Structure

```
AIER-alerts/
├── README.md                    # Project overview
├── docs/                        # Documentation
│   ├── SETUP.md                # Setup instructions
│   ├── WORKFLOW.md             # Team workflow
│   └── ...                     # More docs
├── scripts/                     # Automation scripts
│   ├── 01_init_terraform.sh    # Initialize Terraform
│   ├── 02_plan_terraform.sh    # Preview changes
│   ├── 03_apply_terraform.sh   # Deploy infrastructure
│   ├── 04_verify_deployment.sh # Verify it worked
│   └── 99_destroy_terraform.sh # Delete everything
├── terraform/                   # Infrastructure code
│   ├── main.tf                 # Main infrastructure definition
│   └── variables.tf            # Configuration settings
├── backend/                     # Python backend code
│   ├── app/
│   │   └── main.py            # API endpoints
│   └── requirements.txt        # Python dependencies
└── frontend/                    # Website code
    ├── src/
    │   ├── types/
    │   └── api/
    └── package.json            # JavaScript dependencies
```

### Understanding terraform/main.tf

This file tells Terraform what to create in AWS. Let's break it down section by section:

#### 1. Provider Configuration

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

**In plain English**:
```
"Terraform, we're going to use AWS"
"Use version 5.0 or newer of the AWS plugin"
"Create everything in the us-east-1 region"
```

**Like**:
```
Before building a house, you declare:
"We're building in Virginia"
"Use modern building codes (version 5.0)"
```

#### 2. S3 Bucket for Data

```hcl
resource "aws_s3_bucket" "patient_data" {
  bucket = "aier-patient-data-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name        = "AIER Patient Data"
    Environment = var.environment
    Project     = "AIER"
  }
}
```

**In plain English**:
```
"Create an S3 bucket (cloud storage)"
"Name it: aier-patient-data-[random number]"
"Tag it so we can find it later"
```

**Like**:
```
Create a storage unit
Label it: "AIER Patient Data - Unit 123"
Add tags: "Healthcare Project, Development"
```

#### 3. S3 Bucket Encryption

```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "patient_data" {
  bucket = aws_s3_bucket.patient_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

**In plain English**:
```
"Encrypt everything in this bucket"
"Use AES256 encryption (very secure)"
```

**Like**:
```
Put a lock on the storage unit
Use a high-security lock (AES256)
```

#### 4. DynamoDB Table

```hcl
resource "aws_dynamodb_table" "patients" {
  name           = "aier-patients"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "patient_id"
  range_key      = "timestamp"

  attribute {
    name = "patient_id"
    type = "S"  # S = String
  }

  attribute {
    name = "timestamp"
    type = "N"  # N = Number
  }

  tags = {
    Name        = "AIER Patients"
    Environment = var.environment
  }
}
```

**In plain English**:
```
"Create a database table called 'aier-patients'"
"Only charge me for what I use (PAY_PER_REQUEST)"
"Each row is identified by patient_id + timestamp"
"patient_id is text, timestamp is a number"
```

**Like**:
```
Create a spreadsheet called "Patients"
Columns:
- patient_id (text) - PRIMARY KEY
- timestamp (number) - SORT KEY
- (other columns created automatically as needed)

Each patient can have multiple records (different timestamps)
```

**Example data**:
```
┌─────────────┬─────────────┬─────────────┬────────┐
│ patient_id  │ timestamp   │ heart_rate  │ status │
├─────────────┼─────────────┼─────────────┼────────┤
│ PT-001      │ 1609459200  │ 72          │ normal │
│ PT-001      │ 1609462800  │ 75          │ normal │
│ PT-002      │ 1609459200  │ 95          │ alert  │
└─────────────┴─────────────┴─────────────┴────────┘
```

#### 5. Lambda Function

```hcl
resource "aws_lambda_function" "data_processor" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "aier-data-processor"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "python3.11"

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.patients.name
      S3_BUCKET      = aws_s3_bucket.patient_data.id
    }
  }
}
```

**In plain English**:
```
"Create a Lambda function (automated code)"
"Name it: aier-data-processor"
"Use Python 3.11 to run it"
"When it runs, tell it about our DynamoDB table and S3 bucket"
```

**Like**:
```
Hire a robot worker
Job: "Process patient data"
Skills: Python programming
Give it access to:
  - The database (DynamoDB)
  - The file storage (S3)

When a file is uploaded to S3, the robot:
1. Reads the file
2. Validates the data
3. Saves to DynamoDB
```

#### 6. CloudFront Distribution

```hcl
resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.frontend.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.frontend.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.frontend.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
  }
}
```

**In plain English**:
```
"Create a CloudFront distribution (global CDN)"
"Serve the website from S3"
"Cache content for fast loading"
"Force HTTPS for security"
```

**Like**:
```
Open a chain of stores worldwide
Main warehouse: S3 bucket (Virginia)
Stores in: New York, London, Tokyo, Sydney, etc.

When someone visits the website:
1. CloudFront finds the closest store
2. Serves the website from there (fast!)
3. Updates from main warehouse when needed
```

### Understanding terraform/variables.tf

```hcl
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "AIER"
}
```

**In plain English**:
```
"These are settings you can change"

aws_region: Where to create resources (default: us-east-1)
environment: Is this dev or production? (default: development)
project_name: What to call this project (default: AIER)
```

**Like**:
```
Configuration form:
- Where should we build? [Virginia]
- Development or Production? [Development]
- Project name? [AIER]

You can change these without editing main.tf
```

### Understanding the Scripts

#### scripts/01_init_terraform.sh

```bash
#!/bin/bash
cd "$(dirname "$0")/../terraform"
terraform init
```

**Line by line**:
```bash
#!/bin/bash
# This tells the computer "run this with bash"

cd "$(dirname "$0")/../terraform"
# Go to the terraform folder (no matter where you run this from)

terraform init
# Initialize Terraform
```

#### scripts/02_plan_terraform.sh

```bash
#!/bin/bash
cd "$(dirname "$0")/../terraform"
terraform plan
```

**What it does**:
```
1. Go to terraform folder
2. Show what will be created/changed/deleted
```

#### scripts/03_apply_terraform.sh

```bash
#!/bin/bash
cd "$(dirname "$0")/../terraform"
terraform apply -auto-approve
```

**What it does**:
```
1. Go to terraform folder
2. Create everything in AWS
3. -auto-approve: Don't ask for confirmation (be careful!)
```

#### scripts/04_verify_deployment.sh

```bash
#!/bin/bash

echo "Checking S3 buckets..."
aws s3 ls | grep aier

echo "Checking DynamoDB tables..."
aws dynamodb list-tables | grep aier

echo "Checking Lambda functions..."
aws lambda list-functions --query 'Functions[?contains(FunctionName, `aier`)].FunctionName'
```

**What it does**:
```
Check if everything was created:
1. List S3 buckets with "aier" in the name
2. List DynamoDB tables with "aier" in the name
3. List Lambda functions with "aier" in the name
```

#### scripts/99_destroy_terraform.sh

```bash
#!/bin/bash
cd "$(dirname "$0")/../terraform"
terraform destroy -auto-approve
```

**What it does**:
```
1. Go to terraform folder
2. Delete everything from AWS
3. -auto-approve: Don't ask for confirmation
```

---

## Common Workflows

### Workflow 1: Deploy for the First Time

```bash
# 1. Clone the repository
git clone https://github.com/[your-username]/AIER-alerts.git
cd AIER-alerts

# 2. Configure AWS
aws configure
# Enter your credentials

# 3. Initialize Terraform
bash scripts/01_init_terraform.sh

# 4. Preview what will be created
bash scripts/02_plan_terraform.sh

# 5. Create everything
bash scripts/03_apply_terraform.sh

# 6. Verify it worked
bash scripts/04_verify_deployment.sh
```

### Workflow 2: Make Changes and Update

```bash
# 1. Edit terraform files
nano terraform/main.tf

# 2. Preview changes
bash scripts/02_plan_terraform.sh

# 3. Apply changes
bash scripts/03_apply_terraform.sh
```

### Workflow 3: Upload Data

```bash
# 1. Get your S3 bucket name
aws s3 ls | grep aier
# Output: aier-patient-data-abc123

# 2. Upload a file
aws s3 cp my-data.csv s3://aier-patient-data-abc123/

# 3. Check if Lambda processed it
aws logs tail /aws/lambda/aier-data-processor --follow
```

### Workflow 4: Query Data

```bash
# List all patients
aws dynamodb scan --table-name aier-patients

# Get specific patient
aws dynamodb get-item \
  --table-name aier-patients \
  --key '{"patient_id": {"S": "PT-001"}, "timestamp": {"N": "1609459200"}}'
```

### Workflow 5: Clean Up

```bash
# Delete everything
bash scripts/99_destroy_terraform.sh

# Verify it's gone
bash scripts/04_verify_deployment.sh
# Should show: No resources found
```

---

## Troubleshooting

### Problem: "terraform: command not found"

**Solution**:
```bash
# Check if Terraform is installed
which terraform

# If not installed, install it:
# Mac:
brew install terraform

# Windows: Download from terraform.io
```

### Problem: "Error: No valid credential sources found"

**Solution**:
```bash
# Configure AWS credentials
aws configure

# Test if it worked
aws sts get-caller-identity
```

### Problem: "Error: creating S3 Bucket... BucketAlreadyExists"

**Solution**:
```bash
# S3 bucket names must be globally unique
# Edit terraform/variables.tf and change the bucket name
# Or destroy and recreate:
terraform destroy
terraform apply
```

### Problem: "Access Denied" errors

**Solution**:
```bash
# Check your IAM permissions
aws sts get-caller-identity

# Make sure your IAM user has these permissions:
# - S3FullAccess
# - DynamoDBFullAccess
# - LambdaFullAccess
# - CloudFrontFullAccess
# - IAMReadOnlyAccess
```

### Problem: Terraform is slow

**This is normal!** CloudFront distributions take 15-20 minutes to create.

```bash
# You can skip CloudFront for faster testing
# Edit terraform/main.tf and comment out the cloudfront_distribution resource:

# resource "aws_cloudfront_distribution" "frontend" {
#   ...
# }
```

### Problem: "Error locking state"

**Solution**:
```bash
# Someone else is running Terraform at the same time
# Wait for them to finish, or:
terraform force-unlock <lock-id>
```

### Problem: Can't delete S3 bucket

**Solution**:
```bash
# S3 buckets must be empty before deletion
# Get bucket name
aws s3 ls | grep aier

# Empty the bucket
aws s3 rm s3://aier-patient-data-abc123/ --recursive

# Then destroy
terraform destroy
```

---

## Glossary

**API**: Application Programming Interface - a way for programs to talk to each other

**AWS**: Amazon Web Services - Amazon's cloud computing platform

**Bucket**: A container for files in S3 (like a folder in the cloud)

**CLI**: Command Line Interface - typing commands instead of clicking buttons

**CloudFront**: AWS's content delivery network (makes websites fast globally)

**Commit**: Saving your code changes with a description

**DynamoDB**: AWS's NoSQL database (like a spreadsheet in the cloud)

**Git**: Version control system for tracking code changes

**GitHub**: Website for hosting Git repositories (like Google Drive for code)

**IAM**: Identity and Access Management - AWS's security system

**Infrastructure as Code (IaC)**: Writing what you want in files instead of clicking buttons

**Lambda**: AWS's serverless computing - code that runs automatically when triggered

**Repository (Repo)**: A folder containing your project's code

**S3**: Simple Storage Service - AWS's file storage

**Terraform**: Tool for creating cloud infrastructure automatically

**VPC**: Virtual Private Cloud - your own private network in AWS

---

## Practice Exercises

### Exercise 1: Basic Terraform

```bash
# 1. Create a simple Terraform file
mkdir my-first-terraform
cd my-first-terraform

# 2. Create main.tf
cat > main.tf << 'EOF'
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "test" {
  bucket = "my-test-bucket-$(whoami)-$(date +%s)"
}
EOF

# 3. Initialize
terraform init

# 4. Plan
terraform plan

# 5. Apply
terraform apply

# 6. Check it exists
aws s3 ls | grep my-test-bucket

# 7. Clean up
terraform destroy
```

### Exercise 2: Upload and Query Data

```bash
# 1. Get your bucket name
BUCKET=$(aws s3 ls | grep aier-patient-data | awk '{print $3}')

# 2. Create test data
cat > test.csv << 'EOF'
patient_id,name,age,heart_rate
PT-001,Alice,45,72
PT-002,Bob,56,85
PT-003,Carol,38,78
EOF

# 3. Upload
aws s3 cp test.csv s3://$BUCKET/

# 4. Check it's there
aws s3 ls s3://$BUCKET/

# 5. Query DynamoDB
aws dynamodb scan --table-name aier-patients --limit 5
```

### Exercise 3: Modify Infrastructure

```bash
# 1. Edit main.tf to add a new S3 bucket
cd terraform

# Add this to main.tf:
cat >> main.tf << 'EOF'

resource "aws_s3_bucket" "logs" {
  bucket = "aier-logs-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name = "AIER Logs"
    Purpose = "Log Storage"
  }
}
EOF

# 2. Plan the change
terraform plan

# 3. Apply the change
terraform apply

# 4. Verify
aws s3 ls | grep aier-logs

# 5. Remove it
# Delete the lines from main.tf, then:
terraform apply
```

---

## Next Steps

### After You Can Deploy Successfully:

1. **Understand the code better**
   - Read through `terraform/main.tf` slowly
   - Try to understand each resource
   - Ask questions about anything unclear

2. **Customize the infrastructure**
   - Change bucket names
   - Add tags
   - Modify Lambda function

3. **Add monitoring**
   - Set up CloudWatch alarms
   - Create dashboards
   - Monitor costs

4. **Learn more Terraform**
   - Official tutorials: https://learn.hashicorp.com/terraform
   - AWS provider docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs

5. **Learn more AWS**
   - AWS Free Tier: https://aws.amazon.com/free/
   - AWS Training: https://aws.amazon.com/training/

---

## Getting Help

### Resources:

- **AIER Documentation**: Check the `docs/` folder
- **Terraform Docs**: https://www.terraform.io/docs
- **AWS Docs**: https://docs.aws.amazon.com/
- **GitHub Docs**: https://docs.github.com/

### When Asking for Help:

Include:
1. **What you were trying to do**
2. **What command you ran**
3. **The complete error message**
4. **What you've already tried**

Example:
```
I was trying to deploy the infrastructure with:
  terraform apply

I got this error:
  Error: creating S3 Bucket... BucketAlreadyExists

I tried:
  - Running terraform destroy first
  - Checking if the bucket exists (it doesn't)

Can you help?
```

---

## Summary

**You've learned**:
- ✅ What GitHub, Terraform, and AWS are
- ✅ How to use the command line
- ✅ How to install required tools
- ✅ How to configure AWS credentials
- ✅ How to deploy infrastructure with Terraform
- ✅ How to verify deployment
- ✅ How to clean up resources
- ✅ How to troubleshoot common problems

**You can now**:
- Clone the AIER repository
- Deploy the entire infrastructure to AWS
- Verify it's working
- Upload data
- Query data
- Delete everything

**Remember**:
- Always run `terraform plan` before `terraform apply`
- Always run `terraform destroy` when done (to avoid charges)
- Keep your AWS credentials secret
- Read error messages carefully
- Ask for help when stuck

---

**You're ready to use the AIER Alert System!** 🚀

Start with the deployment guide above and work through it step by step. Don't skip steps! Each one builds on the previous one.

Good luck! 🎉

