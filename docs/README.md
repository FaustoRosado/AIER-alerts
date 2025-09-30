# AIER Alert System - Frontend Visualization

## Project Overview

This repository contains the frontend visualization and data pipeline for the AI-Based ER Alert System with Hybrid API & DevSecOps Fortification. The system demonstrates real-time patient monitoring using the Kaggle Diabetes Dataset.

## Purpose

Provide healthcare professionals with an interactive dashboard to:
- Visualize patient vital signs and risk factors
- Monitor real-time alerts from the AIER system
- Analyze trends in patient data
- Demonstrate hybrid cloud/local architecture capabilities

## Architecture Overview

```
Data Flow:
Kaggle Dataset → S3 → Lambda Processing → DynamoDB → FastAPI → Vue.js Frontend
                                                    ↓
                                                CloudFront CDN
```

## Technology Stack

### Frontend
- **TypeScript**: Type-safe JavaScript for reduced runtime errors
- **Vue.js 3**: Progressive frontend framework
- **D3.js**: Data visualization library
- **Axios**: HTTP client for API communication

### Backend
- **FastAPI**: Modern Python web framework
- **Pydantic**: Data validation
- **Boto3**: AWS SDK for Python

### Infrastructure
- **Terraform**: Infrastructure as Code
- **AWS S3**: Data storage
- **AWS Lambda**: Serverless data processing
- **AWS DynamoDB**: NoSQL database
- **AWS API Gateway**: REST API management
- **AWS CloudFront**: Content delivery network

## Repository Structure

```
data_viz/
├── README.md                   # This file
├── SETUP.md                    # Detailed setup instructions
├── .gitignore                  # Git ignore rules
├── frontend/                   # Vue.js + TypeScript application
│   ├── src/
│   ├── package.json
│   └── tsconfig.json
├── backend/                    # FastAPI application
│   ├── app/
│   ├── requirements.txt
│   └── Dockerfile
├── terraform/                  # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── scripts/                    # Deployment and utility scripts
│   ├── aws-setup-mac.sh
│   ├── aws-setup-windows.ps1
│   ├── deploy.sh
│   └── data-pipeline.py
├── data/                       # Local data directory
│   └── .gitkeep
└── docs/                       # Additional documentation
    ├── AWS_ACCESS_GUIDE.md
    ├── DATA_PIPELINE.md
    └── DEPLOYMENT.md
```

## Quick Start

### Prerequisites
- Node.js 18+ and npm
- Python 3.9+
- AWS CLI configured
- Terraform 1.6+
- Git

### Installation Steps

1. Clone the repository:
```bash
git clone https://github.com/[your-org]/aier-frontend-visualization.git
cd aier-frontend-visualization
```

2. Set up AWS access (choose your platform):
```bash
# Mac/Linux
bash scripts/aws-setup-mac.sh

# Windows PowerShell
.\scripts\aws-setup-windows.ps1
```

3. Download Kaggle dataset (requires Kaggle API key):
```bash
python scripts/download-dataset.py
```

4. Deploy infrastructure:
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

5. Start backend:
```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload
```

6. Start frontend:
```bash
cd frontend
npm install
npm run dev
```

## Key Features

### Real-Time Data Visualization
- Interactive scatter plots showing patient risk factors
- Time-series charts for vital signs monitoring
- Heat maps for correlation analysis
- Dashboard with filtering and drill-down capabilities

### Hybrid Architecture Demo
- Demonstrates local vs. cloud processing
- Failover simulation capabilities
- Alert routing visualization

### Security Features
- HIPAA-compliant data handling
- Encrypted data transmission
- Anonymized patient identifiers
- Role-based access control

## Learning Objectives

Students will learn:
1. Modern frontend development with TypeScript and Vue.js
2. Data visualization using D3.js
3. RESTful API design with FastAPI
4. Infrastructure as Code with Terraform
5. AWS cloud services integration
6. DevSecOps practices in healthcare applications

## Related Repositories

- [AIER-Alert-System-Backend](link) - Core AI alert system
- [AIER-DevSecOps-Pipeline](link) - CI/CD and security scanning

## Documentation

- [Setup Guide](SETUP.md) - Step-by-step installation
- [AWS Access Guide](docs/AWS_ACCESS_GUIDE.md) - Managing team AWS access
- [Data Pipeline Documentation](docs/DATA_PIPELINE.md) - Understanding data flow
- [Deployment Guide](docs/DEPLOYMENT.md) - Production deployment

## Support

For questions or issues:
1. Check the documentation in `/docs`
2. Review the setup guide in `SETUP.md`
3. Contact the team lead

## License

This project is part of the Cyber Security Fellowship capstone program.

## Team

Cyber Security Fellowship - [Insert Team Name]
Project Lead: Javier (Documentation Lead)
