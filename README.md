# AIER Alert System - Frontend Visualization

## Quick Start

This repository contains the frontend visualization and data pipeline for the AI-Based ER Alert System using the Kaggle Diabetes Dataset.

## Repository Structure

```
data_viz/
├── README.md                   # This file - quick start guide
├── .gitignore                  # Git ignore rules
│
├── docs/                       # Complete documentation
│   ├── README.md              # Detailed project overview
│   ├── SETUP.md               # Step-by-step setup instructions
│   ├── PROJECT_SUMMARY.md     # Complete project guide
│   ├── AWS_ACCESS_GUIDE.md    # Team AWS access management
│   └── DATA_PIPELINE.md       # Data pipeline documentation
│
├── scripts/                    # Deployment and utility scripts
│   ├── aws-setup-mac.sh
│   ├── aws-setup-windows.ps1
│   ├── download-dataset.py
│   └── data-pipeline.py
│
├── terraform/                  # Infrastructure as Code
│   ├── main.tf
│   └── variables.tf
│
├── backend/                    # FastAPI application
│   ├── requirements.txt
│   └── app/
│
├── frontend/                   # Vue.js + TypeScript
│   ├── package.json
│   └── src/
│
└── data/                       # Local data directory
```

## Technology Stack

- **Frontend**: TypeScript, Vue.js 3, D3.js
- **Backend**: FastAPI (Python)
- **Infrastructure**: Terraform, AWS (S3, Lambda, DynamoDB, CloudFront)
- **Data**: Kaggle Diabetes Dataset

## Quick Setup

### Prerequisites
- Node.js 18+
- Python 3.9+
- AWS CLI configured
- Terraform 1.6+

### Installation

1. Configure AWS access:
```bash
# Mac/Linux
bash scripts/aws-setup-mac.sh

# Windows PowerShell
.\scripts\aws-setup-windows.ps1
```

2. Download dataset:
```bash
python scripts/download-dataset.py
```

3. Deploy infrastructure:
```bash
cd terraform
terraform init
terraform apply
```

4. Start backend:
```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload
```

5. Start frontend:
```bash
cd frontend
npm install
npm run dev
```

## Documentation

All detailed documentation is in the `docs/` folder:

- **[docs/WORKFLOW.md](docs/WORKFLOW.md)** - Complete team workflow (start here!)
- **[docs/CONSOLE_VIEWING.md](docs/CONSOLE_VIEWING.md)** - View infrastructure in AWS Console
- **[docs/SETUP.md](docs/SETUP.md)** - Detailed setup guide
- **[docs/TEAM_ACCESS.md](docs/TEAM_ACCESS.md)** - Team member AWS access
- **[docs/README.md](docs/README.md)** - Complete project overview
- **[docs/PROJECT_SUMMARY.md](docs/PROJECT_SUMMARY.md)** - Full project documentation
- **[docs/AWS_ACCESS_GUIDE.md](docs/AWS_ACCESS_GUIDE.md)** - AWS credential management
- **[docs/DATA_PIPELINE.md](docs/DATA_PIPELINE.md)** - Data pipeline architecture

## Team

**Project**: AI-Based ER Alert System with Hybrid API & DevSecOps Fortification  
**Program**: Cyber Security Fellowship  
**Repository**: AIER-alerts

### Contributors

Team members and GitHub links will be added here.

## Support

For questions or issues:
1. Check documentation in `docs/`
2. Review setup guide: `docs/SETUP.md`
3. Contact project lead

## License

This project is part of the Cyber Security Fellowship capstone program.
