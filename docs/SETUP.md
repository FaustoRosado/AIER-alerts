# AIER Frontend Visualization - Setup Guide

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [AWS Account Setup](#aws-account-setup)
3. [Local Development Environment](#local-development-environment)
4. [Data Pipeline Setup](#data-pipeline-setup)
5. [Infrastructure Deployment](#infrastructure-deployment)
6. [Frontend Development](#frontend-development)
7. [Backend Development](#backend-development)
8. [Testing](#testing)
9. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software

#### Node.js and npm
- Version: Node.js 18+ and npm 9+
- Download: https://nodejs.org/
- Verify installation:
```bash
node --version
npm --version
```

#### Python
- Version: Python 3.9 or higher
- Download: https://www.python.org/downloads/
- Verify installation:
```bash
python --version
pip --version
```

#### AWS CLI
- Version: AWS CLI v2
- Installation guide: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
- Verify installation:
```bash
aws --version
```

#### Terraform
- Version: Terraform 1.6+
- Download: https://www.terraform.io/downloads
- Verify installation:
```bash
terraform --version
```

#### Git
- Version: Latest stable
- Download: https://git-scm.com/downloads
- Verify installation:
```bash
git --version
```

## AWS Account Setup

### Option 1: Using Provided Scripts (Recommended for Students)

#### For Mac/Linux Users

Run the automated setup script:
```bash
cd scripts
bash aws-setup-mac.sh
```

This script will:
- Prompt for AWS credentials
- Configure AWS CLI profile
- Set up default region
- Test connectivity
- Create necessary IAM policies

#### For Windows Users

Run the PowerShell script:
```powershell
cd scripts
.\aws-setup-windows.ps1
```

This script performs the same setup as the Mac version.

### Option 2: Manual AWS Configuration

1. Obtain AWS credentials from your team lead:
   - AWS Access Key ID
   - AWS Secret Access Key
   - Default region (e.g., us-east-1)

2. Configure AWS CLI:
```bash
aws configure
```

3. Enter credentials when prompted:
```
AWS Access Key ID: [your-access-key]
AWS Secret Access Key: [your-secret-key]
Default region name: us-east-1
Default output format: json
```

4. Verify configuration:
```bash
aws sts get-caller-identity
```

You should see your account information.

### Team Member Access Management

Team leads can grant temporary access using the provided IAM policy templates. See `docs/AWS_ACCESS_GUIDE.md` for details.

## Local Development Environment

### 1. Clone the Repository

```bash
git clone https://github.com/[your-org]/aier-frontend-visualization.git
cd aier-frontend-visualization
```

### 2. Install Python Dependencies

Create a virtual environment:
```bash
python -m venv venv

# Mac/Linux
source venv/bin/activate

# Windows
.\venv\Scripts\activate
```

Install backend dependencies:
```bash
pip install -r backend/requirements.txt
```

### 3. Install Node.js Dependencies

```bash
cd frontend
npm install
cd ..
```

## Data Pipeline Setup

### 1. Download Kaggle Dataset

First, set up Kaggle API credentials:

1. Create Kaggle account at https://www.kaggle.com
2. Go to Account settings → API → Create New API Token
3. This downloads `kaggle.json`
4. Move file to correct location:

```bash
# Mac/Linux
mkdir -p ~/.kaggle
mv kaggle.json ~/.kaggle/
chmod 600 ~/.kaggle/kaggle.json

# Windows (PowerShell)
mkdir $env:USERPROFILE\.kaggle -Force
Move-Item kaggle.json $env:USERPROFILE\.kaggle\
```

Download the diabetes dataset:
```bash
python scripts/download-dataset.py
```

This creates `data/diabetes.csv` with the Kaggle diabetes dataset.

### 2. Process and Upload Data

Run the data pipeline script:
```bash
python scripts/data-pipeline.py --upload
```

This script:
- Validates the dataset
- Cleans and anonymizes patient data
- Uploads to S3 bucket
- Triggers Lambda processing
- Populates DynamoDB

## Infrastructure Deployment

### 1. Initialize Terraform

```bash
cd terraform
terraform init
```

### 2. Review Infrastructure Plan

```bash
terraform plan
```

Review the resources that will be created:
- S3 buckets for data storage
- Lambda functions for processing
- DynamoDB tables
- API Gateway
- CloudFront distribution
- IAM roles and policies

### 3. Deploy Infrastructure

```bash
terraform apply
```

Type `yes` when prompted.

This takes approximately 5-10 minutes.

### 4. Save Outputs

Terraform will output important values:
```bash
terraform output > ../config/terraform-outputs.txt
```

These outputs include:
- API Gateway URL
- CloudFront distribution URL
- S3 bucket names
- DynamoDB table names

## Frontend Development

### 1. Configure API Endpoint

Edit `frontend/src/config/api.ts`:
```typescript
export const API_BASE_URL = 'https://[your-api-gateway-url]';
```

Use the API Gateway URL from Terraform outputs.

### 2. Install Dependencies

```bash
cd frontend
npm install
```

### 3. Start Development Server

```bash
npm run dev
```

The frontend will be available at `http://localhost:5173`

### 4. Build for Production

```bash
npm run build
```

This creates optimized files in `frontend/dist/`

## Backend Development

### 1. Configure Environment Variables

Create `backend/.env`:
```
AWS_REGION=us-east-1
DYNAMODB_TABLE_NAME=[from-terraform-output]
S3_BUCKET_NAME=[from-terraform-output]
CORS_ORIGINS=http://localhost:5173
```

### 2. Start Development Server

```bash
cd backend
uvicorn app.main:app --reload --port 8000
```

The API will be available at `http://localhost:8000`

### 3. View API Documentation

FastAPI provides automatic documentation:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Testing

### Backend Tests

```bash
cd backend
pytest tests/ -v
```

### Frontend Tests

```bash
cd frontend
npm run test
```

### Integration Tests

```bash
python scripts/integration-test.py
```

This tests the complete data flow from frontend to backend to AWS services.

## Troubleshooting

### AWS CLI Not Configured

Error: `Unable to locate credentials`

Solution:
```bash
aws configure
```
Enter your credentials when prompted.

### Terraform State Lock

Error: `Error acquiring the state lock`

Solution:
```bash
cd terraform
terraform force-unlock [LOCK_ID]
```

### Port Already in Use

Error: `Address already in use`

Solution:
```bash
# Find process using port 8000
lsof -i :8000

# Kill the process
kill -9 [PID]
```

### Node Modules Issues

Error: `Module not found`

Solution:
```bash
cd frontend
rm -rf node_modules package-lock.json
npm install
```

### Python Dependencies Issues

Error: `No module named 'fastapi'`

Solution:
```bash
pip install --upgrade pip
pip install -r requirements.txt
```

## Next Steps

After completing setup:

1. Review the [Data Pipeline Documentation](docs/DATA_PIPELINE.md)
2. Explore the frontend code in `frontend/src/`
3. Test API endpoints using the Swagger UI
4. Review security configurations in Terraform files
5. Start building your custom visualizations

## Getting Help

If you encounter issues not covered here:

1. Check the main README.md
2. Review documentation in `/docs`
3. Contact your team lead
4. Check AWS CloudWatch Logs for backend errors

## Summary Checklist

Before starting development, ensure:

- [ ] AWS CLI configured and tested
- [ ] Python virtual environment activated
- [ ] Node.js dependencies installed
- [ ] Kaggle dataset downloaded
- [ ] Terraform infrastructure deployed
- [ ] Environment variables configured
- [ ] Backend server running
- [ ] Frontend development server running
- [ ] API connectivity tested

You are now ready to develop and demonstrate the AIER Frontend Visualization system.
