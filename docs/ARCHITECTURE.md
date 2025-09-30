# AIER Alert System - Architecture Topology

## System Architecture Diagram

```mermaid
graph TD
    subgraph "Patient Intake / On-Premise (API 1)"
        A[Client/Monitoring Device] --> B{API 1: FastAPI};
        B --> C[1. Ingest & Validate Vitals];
        C --> D[2. Construct Prompt];
        D --> E[3. Local Inference w/ llama.cpp];
        E --> F[4. Parse & Triage];
        F --> G{Decision};
        G -- "Clear / Non-Critical" --> H[Log Locally];
        G -- "Clear / Critical" --> I[Trigger Immediate Local Alert];
        G -- "Uncertain / Escalate" --> J[(Persistent Queue)];
    end

    subgraph "Cloud Platform (AWS)"
        J -- "Sync when connection restored" --> K{API 2: Lambda/ECS};
        K --> L[1. Process Queued/Escalated Data];
        L --> M[2. Invoke Larger LLM (6B-7B)];
        M --> N[3. Final Decision Analysis];
        N --> O{Dispatch Layer};
        O --> P[("fa:fa-aws AWS SNS")];
        O --> Q[("fa:fa-aws AWS EventBridge")];
        R[("fa:fa-aws DynamoDB")] <--> K;
        S[("fa:fa-aws S3")] <--> K;
    end

    subgraph "Notification & Downstream Systems"
        P -- Pub/Sub --> T[SMS, Email, Pager];
        Q -- Event Bus --> U[EHR Update, Dashboard, Team Paging];
    end

    subgraph "DevSecOps & Monitoring"
        V[("fa:fa-github GitHub Actions CI/CD")];
        V -- "SAST, DAST, IaC Scans" --> W{Deployment Gate};
        X[("fa:fa-aws Terraform IaC")] --> Y[AWS Infrastructure];
        Y --> Z[("fa:fa-splunk Splunk & fa:fa-aws CloudWatch")];
        W --> Y;
    end

    %% Styles
    style A fill:#f9f,stroke:#333,stroke-width:2px
    style T fill:#f9f,stroke:#333,stroke-width:2px
    style U fill:#f9f,stroke:#333,stroke-width:2px

    %% Links (relative to GitHub repo root)
    click B "https://github.com/FaustoRosado/AIER-alerts/tree/main/backend" "Go to API 1 Code"
    click K "https://github.com/FaustoRosado/AIER-alerts/tree/main/backend" "Go to API 2 Code"
    click X "https://github.com/FaustoRosado/AIER-alerts/tree/main/terraform" "Go to Terraform Code"
    click V "https://github.com/FaustoRosado/AIER-alerts/actions" "Go to GitHub Actions"
```

## Architecture Overview

### Local Layer (On-Premise)

**API 1 - FastAPI Endpoint**
- Location: `backend/app/main.py`
- Purpose: Lightweight local processing
- Model: 2B-4B parameters (llama.cpp)
- Capability: Runs offline during cloud outages

**Features:**
- Validates patient vitals in real-time
- Runs local AI inference
- Triages into: Clear/Non-Critical, Clear/Critical, or Uncertain
- Persists escalations to queue during outages

---

### Cloud Layer (AWS)

**API 2 - Lambda/ECS Endpoint**
- Location: `backend/app/` (deployed to AWS)
- Purpose: Advanced processing and escalation handling
- Model: 6B-7B parameters (larger, more capable)
- Capability: Handles complex cases

**AWS Services:**
- **S3**: Data lake for vitals history and model artifacts
- **DynamoDB**: Real-time patient data and triage results
- **Lambda**: Serverless data processing
- **SNS**: Alert distribution (SMS, email, pager)
- **EventBridge**: Event-driven automation (EHR updates, team paging)

---

### Hybrid Architecture Benefits

**Failover Logic:**
```
If cloud is down:
  → Local API continues processing
  → Critical alerts still trigger
  → Escalations queued locally
  
When cloud returns:
  → Queue syncs automatically
  → Escalations processed
  → No alerts missed
```

**Resilience:**
- No single point of failure
- Local continues if cloud fails
- Cloud enhances when available
- Automatic failover and recovery

---

### DevSecOps Pipeline

**Infrastructure as Code:**
- **Terraform**: All AWS resources defined in code
- **Location**: `terraform/main.tf`
- **Automated**: Deploy with numbered scripts (01-04)

**CI/CD Pipeline:**
- **GitHub Actions**: Automated testing and deployment
- **Security Scans**: SAST, DAST, IaC scanning
- **Deployment Gates**: Must pass security before deploy

**Monitoring:**
- **CloudWatch**: AWS service metrics and logs
- **Splunk**: Advanced log aggregation and analysis
- **Alerts**: Automated anomaly detection

---

### Data Flow

```
Patient Monitoring Device
    ↓
API 1 (FastAPI Local)
    ↓
Local AI Model (llama.cpp 2B-4B)
    ↓
Decision:
├─ Non-Critical → Local Log
├─ Critical → Immediate Alert
└─ Uncertain → Queue for Cloud
    ↓
API 2 (AWS Lambda/ECS)
    ↓
Larger AI Model (6B-7B)
    ↓
Final Analysis
    ↓
Dispatch:
├─ SNS → SMS/Email/Pager
└─ EventBridge → EHR/Dashboard/Teams
```

---

### Visualization Demo (This Repository)

**Current Implementation:**
- **Data Source**: Kaggle Diabetes Dataset (demo data)
- **Pipeline**: `scripts/data-pipeline.py`
- **Storage**: S3 → Lambda → DynamoDB
- **API**: FastAPI serving patient data
- **Frontend**: Vue.js + TypeScript + D3.js visualizations

**Demonstrates:**
- AWS infrastructure setup
- Data processing pipeline
- Real-time visualization capabilities
- Hybrid architecture principles

---

## Component Locations in Repository

### Backend (API Layer)
- **FastAPI Application**: `backend/app/main.py`
- **Dependencies**: `backend/requirements.txt`
- **Endpoints**: 
  - `/api/patients` - Patient data
  - `/api/statistics` - Aggregated stats
  - `/api/visualizations/*` - Chart data

### Infrastructure (Terraform)
- **Main Config**: `terraform/main.tf`
- **Variables**: `terraform/variables.tf`
- **Resources**:
  - S3 buckets (data + frontend)
  - DynamoDB table
  - Lambda function
  - CloudFront distribution
  - IAM roles and policies

### Frontend (Visualization)
- **TypeScript Types**: `frontend/src/types/patient.ts`
- **API Client**: `frontend/src/api/client.ts`
- **Configuration**: `frontend/package.json`, `frontend/tsconfig.json`

### Data Pipeline
- **Download**: `scripts/download-dataset.py`
- **Process**: `scripts/data-pipeline.py`
- **Workflow**: Kaggle → S3 → Lambda → DynamoDB → API → Frontend

### Deployment Scripts
- **Initialize**: `scripts/01_init_terraform.sh`
- **Plan**: `scripts/02_plan_terraform.sh`
- **Deploy**: `scripts/03_apply_terraform.sh`
- **Verify**: `scripts/04_verify_deployment.sh`
- **Cleanup**: `scripts/99_destroy_terraform.sh`

---

## Technology Stack

### Local Layer
- **Language**: Python 3.9+
- **Framework**: FastAPI
- **AI Model**: llama.cpp (2B-4B parameters)
- **Deployment**: On-premise servers or edge devices

### Cloud Layer
- **Infrastructure**: AWS (S3, DynamoDB, Lambda, CloudFront)
- **IaC**: Terraform 1.5+
- **AI Model**: 6B-7B parameters (EC2/ECS)
- **Notifications**: SNS, EventBridge
- **Monitoring**: CloudWatch, Splunk

### Frontend
- **Language**: TypeScript 5.3+
- **Framework**: Vue.js 3
- **Visualization**: D3.js
- **Build**: Vite

### DevSecOps
- **Version Control**: Git, GitHub
- **CI/CD**: GitHub Actions
- **Security**: SAST, DAST, IaC scanning
- **Secrets**: AWS Secrets Manager, SSM Parameter Store

---

## Security Architecture

### Data Protection
- **At Rest**: S3/DynamoDB encryption with KMS
- **In Transit**: TLS 1.2+ for all API calls
- **Access Control**: IAM roles with least privilege
- **Anonymization**: No PII in demo dataset

### Network Security
- **VPC**: Network isolation for cloud resources
- **Security Groups**: Restricted ingress/egress
- **Private Subnets**: Backend services isolated
- **CloudFront**: DDoS protection and WAF

### Compliance
- **HIPAA-Ready**: Encryption, audit logs, access controls
- **Anonymized Data**: Demo uses synthetic patient IDs
- **Audit Trail**: CloudWatch logs, CloudTrail events

---

## Scalability

### Local Layer
- **Horizontal**: Multiple edge devices
- **Vertical**: GPU instances for faster inference
- **Load Balancing**: ALB for multiple API instances

### Cloud Layer
- **Auto-Scaling**: Lambda scales automatically
- **DynamoDB**: On-demand capacity
- **CloudFront**: Global CDN with edge caching
- **Multi-Region**: Can deploy to multiple AWS regions

---

## Cost Optimization

### Development Environment
- **S3**: <$1/month
- **DynamoDB**: $1-5/month (on-demand)
- **Lambda**: <$1/month (free tier)
- **CloudFront**: $1-5/month
- **Total**: $5-15/month

### Production Considerations
- Use reserved instances for EC2
- Enable S3 lifecycle policies
- Implement DynamoDB auto-scaling
- CloudWatch log retention policies
- Spot instances for batch processing

---

## Viewing This Diagram

### On GitHub
The diagram will render automatically on GitHub when viewing this file:
https://github.com/FaustoRosado/AIER-alerts/blob/main/docs/ARCHITECTURE.md

### Locally
View using:
- **VSCode**: Install Mermaid extension
- **Obsidian**: Native Mermaid support
- **Mermaid Live Editor**: https://mermaid.live/

### In Documentation
Copy the diagram to presentations, reports, or other documentation as needed.

---

## Next Steps

### Current Repository (Visualization Demo)
This repository demonstrates the **data pipeline and visualization** components using:
- Kaggle diabetes dataset
- AWS infrastructure
- Interactive frontend

### Full AIER System (Future)
Complete implementation would add:
- Local AI model integration (llama.cpp)
- Larger cloud AI model (6B-7B)
- SNS alert distribution
- EventBridge automation
- VPC networking
- Multi-region deployment

---

## References

- **Repository**: https://github.com/FaustoRosado/AIER-alerts
- **Main README**: [README.md](../README.md)
- **Setup Guide**: [SETUP.md](SETUP.md)
- **Workflow**: [WORKFLOW.md](WORKFLOW.md)
- **Data Pipeline**: [DATA_PIPELINE.md](DATA_PIPELINE.md)

---

**This architecture demonstrates a production-ready hybrid healthcare alert system with resilience, security, and scalability built in.**
