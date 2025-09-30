# AIER Frontend Visualization - Repository Structure

## Complete File Organization

```
data_viz/
│
├── README.md                           # Quick start guide (root level only)
├── .gitignore                          # Git exclusion rules
│
├── docs/                               # All documentation consolidated here
│   ├── README.md                       # Detailed project overview
│   ├── SETUP.md                        # Step-by-step installation
│   ├── PROJECT_SUMMARY.md              # Complete project guide
│   ├── AWS_ACCESS_GUIDE.md             # AWS access management
│   ├── DATA_PIPELINE.md                # Data pipeline architecture
│   ├── CONTRIBUTORS.md                 # Team members and links
│   └── STRUCTURE.md                    # This file
│
├── scripts/                            # Automation scripts
│   ├── aws-setup-mac.sh                # AWS CLI setup for Mac/Linux
│   ├── aws-setup-windows.ps1           # AWS CLI setup for Windows
│   ├── download-dataset.py             # Kaggle dataset downloader
│   └── data-pipeline.py                # Data processing pipeline
│
├── terraform/                          # Infrastructure as Code
│   ├── main.tf                         # Main Terraform configuration
│   └── variables.tf                    # Terraform variables
│
├── backend/                            # FastAPI backend
│   ├── requirements.txt                # Python dependencies
│   └── app/
│       ├── main.py                     # FastAPI application
│       └── __init__.py                 # Python package marker
│
├── frontend/                           # Vue.js + TypeScript frontend
│   ├── package.json                    # Node.js dependencies
│   ├── tsconfig.json                   # TypeScript configuration
│   ├── tsconfig.node.json              # Node TypeScript config
│   ├── vite.config.ts                  # Vite build configuration
│   ├── index.html                      # Entry HTML file
│   └── src/
│       ├── main.ts                     # Application entry point
│       ├── App.vue                     # Root Vue component
│       ├── types/
│       │   └── patient.ts              # TypeScript type definitions
│       ├── api/
│       │   └── client.ts               # Typed API client
│       ├── components/                 # Vue components
│       │   ├── Dashboard.vue
│       │   ├── ScatterPlot.vue
│       │   └── StatisticsCard.vue
│       └── views/                      # Page components
│           └── HomeView.vue
│
└── data/                               # Local data storage
    ├── .gitkeep                        # Keep empty directory in git
    ├── diabetes.csv                    # Downloaded dataset (gitignored)
    ├── diabetes_processed.csv          # Processed data (gitignored)
    └── statistics.json                 # Generated stats (gitignored)
```

## File Purpose Reference

### Root Level
- **README.md**: Quick start guide with links to detailed docs
- **.gitignore**: Excludes build artifacts, secrets, OS files, parent directory files

### Documentation (docs/)
All comprehensive documentation consolidated in one location:
- **README.md**: Full project overview and architecture
- **SETUP.md**: Complete installation instructions
- **PROJECT_SUMMARY.md**: Detailed project guide
- **AWS_ACCESS_GUIDE.md**: Team AWS credential management
- **DATA_PIPELINE.md**: Pipeline architecture and flow
- **CONTRIBUTORS.md**: Team members and GitHub profiles
- **STRUCTURE.md**: This file - repository organization

### Scripts (scripts/)
Automation and utility scripts:
- **aws-setup-mac.sh**: Automated AWS CLI configuration for Mac/Linux
- **aws-setup-windows.ps1**: Automated AWS CLI configuration for Windows
- **download-dataset.py**: Downloads Kaggle diabetes dataset
- **data-pipeline.py**: Processes and uploads data to AWS

### Infrastructure (terraform/)
Infrastructure as Code for AWS resources:
- **main.tf**: Complete infrastructure definition (S3, Lambda, DynamoDB, CloudFront)
- **variables.tf**: Configurable variables for deployment

### Backend (backend/)
FastAPI Python backend:
- **requirements.txt**: Python package dependencies
- **app/main.py**: REST API implementation with endpoints

### Frontend (frontend/)
Vue.js 3 + TypeScript application:
- **package.json**: Node.js dependencies and scripts
- **tsconfig.json**: TypeScript compiler configuration
- **src/types/patient.ts**: Type-safe data structures
- **src/api/client.ts**: API client with type annotations
- **src/components/**: Reusable Vue components
- **src/views/**: Page-level components

### Data (data/)
Local data storage (contents gitignored):
- Downloaded and processed datasets
- Generated statistics files
- Only .gitkeep tracked to preserve directory

## Excluded Files

### From Git (.gitignore)
- Build artifacts (dist/, build/, node_modules/)
- Secrets and credentials (*.key, .env, kaggle.json)
- OS files (.DS_Store, ._*, Thumbs.db)
- IDE files (.vscode/, .idea/)
- Terraform state (*.tfstate)
- Log files (*.log)
- Temporary files (*.tmp, *.swp)
- Parent directory files (../*.md, ../*.txt, ../._*)

### Why Parent Files Excluded
The .gitignore specifically excludes markdown and text files from the parent capstone directory:
```
../*.md
../*.txt
../._*
```
This ensures the data_viz repository remains clean and only tracks its own documentation and files.

## Adding New Files

### Documentation
Place in `docs/` folder with descriptive name:
```
docs/NEW_FEATURE_GUIDE.md
```

### Scripts
Place in `scripts/` folder:
```
scripts/new-automation-script.py
```

### Frontend Components
Place in appropriate src subdirectory:
```
frontend/src/components/NewChart.vue
```

### Backend Modules
Place in `backend/app/`:
```
backend/app/models.py
backend/app/database.py
```

## Navigation Guide

### For Students Starting Out
1. Start with: `README.md` (root)
2. Then read: `docs/SETUP.md`
3. Understand architecture: `docs/DATA_PIPELINE.md`
4. Follow setup: `docs/README.md`

### For Development
1. Backend code: `backend/app/`
2. Frontend code: `frontend/src/`
3. Infrastructure: `terraform/`
4. Scripts: `scripts/`

### For Documentation
All documentation in: `docs/`

### For Contributors
- Team info: `docs/CONTRIBUTORS.md`
- Setup guide: `docs/SETUP.md`
- Architecture: `docs/DATA_PIPELINE.md`

## File Naming Conventions

### Documentation
- All caps with underscores: `AWS_ACCESS_GUIDE.md`
- Descriptive names: `DATA_PIPELINE.md`

### Scripts
- Lowercase with hyphens: `aws-setup-mac.sh`
- Platform indication: `-mac`, `-windows` suffix

### Code Files
- Lowercase with hyphens (components): `scatter-plot.vue`
- Lowercase with underscores (Python): `data_pipeline.py`
- camelCase (TypeScript): `patient.ts`, `client.ts`

## Repository Size

### Current Structure
- Documentation: ~6 files
- Scripts: 4 files
- Infrastructure: 2 files
- Backend: 2 files
- Frontend: 4+ files

### Data (Excluded from Git)
- Kaggle dataset: ~23 KB
- Processed data: ~30 KB
- Statistics: ~2 KB

## Maintenance

### Regular Updates Needed
- **docs/CONTRIBUTORS.md**: Add team members
- **README.md**: Update as features added
- **docs/SETUP.md**: Update for new dependencies

### Version Control
All changes tracked via Git except:
- Generated data files
- Build artifacts
- Secrets and credentials
- OS-specific files
