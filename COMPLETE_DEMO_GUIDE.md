# AIER Alert System - Complete Demo Guide for Non-Technical Beginners

**The Ultimate Step-by-Step Walkthrough from Zero to Demo**

---

## 🎯 What This Guide Is

This is a **complete, no-assumptions-made guide** for anyone who needs to understand and demo this AIER (AI-Based ER Alert) system, even if you've never programmed before or missed the entire project development.

**Who This Is For:**
- Team members who haven't been involved
- Stakeholders who need to understand the project
- Anyone preparing for the demo presentation
- Future maintainers of this system

---

## 📚 Table of Contents

### PART 1: UNDERSTANDING THE PROJECT
1. [What Is This Project? The Big Picture](#part-1-what-is-this-project)
2. [Project Objectives & Sprints](#project-objectives-sprints)
3. [Why This Matters - Real World Value](#why-this-matters)

### PART 2: FOUNDATIONAL CONCEPTS (For Dummies)
4. [Software Engineering 101](#software-engineering-101)
5. [Understanding SDLC (Software Development Lifecycle)](#understanding-sdlc)
6. [CI/CD Pipeline Explained](#cicd-pipeline)
7. [What Are APIs?](#what-are-apis)
8. [Databases Demystified](#databases-demystified)
9. [Infrastructure as Code (IaC)](#infrastructure-as-code)

### PART 3: TECHNOLOGY STACK BREAKDOWN
10. [Frontend Technologies](#frontend-technologies)
    - TypeScript vs JavaScript
    - Vue.js Framework
    - D3.js Visualizations
11. [Backend Technologies](#backend-technologies)
    - FastAPI
    - Python
12. [Cloud Infrastructure (AWS)](#cloud-infrastructure)

### PART 4: AWS SERVICES IN DETAIL
13. [Understanding IAM (Identity & Access Management)](#understanding-iam)
14. [S3 - Storage](#s3-storage)
15. [DynamoDB - Database](#dynamodb-database)
16. [Lambda - Serverless Computing](#lambda-serverless)
17. [CloudFront - Content Delivery](#cloudfront-cdn)

### PART 5: THE AIER ALERT SYSTEM
18. [How AIER Works - Online & Offline](#aier-system-architecture)
19. [Data Flow](#data-flow)
20. [Alert Mechanisms](#alert-mechanisms)

### PART 6: HANDS-ON DEMO
21. [Script Execution Guide](#script-execution-guide)
22. [Sequential Setup](#sequential-setup)
23. [Breaking Down Each Script](#breaking-down-scripts)
24. [Code Walkthrough](#code-walkthrough)

### PART 7: DEMO PREPARATION
25. [Demo Checklist](#demo-checklist)
26. [Troubleshooting Guide](#troubleshooting-guide)
27. [Common Questions & Answers](#common-questions)

---

## PART 1: WHAT IS THIS PROJECT?

### The Big Picture

**AIER = Artificial Intelligence ER Alert System**

This is a healthcare monitoring system that combines:
- **Real-time patient data visualization**
- **AI-powered risk assessment** 
- **Automated alert system**
- **Cloud-based infrastructure**
- **Security-first design (DevSecOps)**

**The Problem It Solves:**
In emergency rooms, medical staff are overwhelmed with patient data. Our system:
1. Collects patient vitals and medical history
2. Analyzes data to identify high-risk patients
3. Visualizes data in an easy-to-understand dashboard
4. Sends alerts when patients need immediate attention

**The Innovation:**
- **Online Mode**: Full cloud-powered system using AWS services
- **Offline Mode**: Local LLM (Large Language Model) can work without internet for remote locations or disasters

### Technology Layers Simplified

```
┌──────────────────────────────────────────────┐
│  FRONTEND (What Users See)                   │
│  - Dashboard showing patient data            │
│  - Charts and graphs (D3.js)                 │
│  - Interactive controls                      │
└──────────────────────────────────────────────┘
                    ↕
┌──────────────────────────────────────────────┐
│  API (The Messenger)                         │
│  - Connects frontend to backend              │
│  - RESTful API (FastAPI)                     │
└──────────────────────────────────────────────┘
                    ↕
┌──────────────────────────────────────────────┐
│  BACKEND (The Brain)                         │
│  - Python code processing data               │
│  - Business logic                            │
│  - Data validation                           │
└──────────────────────────────────────────────┘
                    ↕
┌──────────────────────────────────────────────┐
│  DATABASE (The Memory)                       │
│  - DynamoDB stores patient records           │
│  - S3 stores files                           │
└──────────────────────────────────────────────┘
                    ↕
┌──────────────────────────────────────────────┐
│  INFRASTRUCTURE (The Foundation)             │
│  - AWS cloud services                        │
│  - Terraform creates everything              │
└──────────────────────────────────────────────┘
```

---

## PROJECT OBJECTIVES & SPRINTS

### Capstone Mission

This project serves **three core objectives**:

#### 1. **Technical Mastery** 
Learn to build production-ready cloud applications:
- Infrastructure as Code (Terraform)
- Cloud-native architecture (AWS)
- Modern web development (TypeScript, Vue.js)
- Data visualization (D3.js)
- Security automation (DevSecOps)

#### 2. **Strategic Acumen**
Understand business and market:
- Healthcare technology market
- Service design and pricing
- Compliance (HIPAA)
- Team collaboration
- Documentation standards

#### 3. **Subject Matter Expertise**
Become healthcare IT specialists:
- Patient data management
- Medical data standards (FHIR)
- Healthcare APIs
- Emergency response systems

### Sprint Breakdown

**Sprint 1 (Weeks 1-2): Foundation**
- ✅ Project scoping & planning
- ✅ Technology stack selection
- ✅ AWS account setup
- ✅ Repository initialization

**Sprint 2 (Weeks 3-4): Infrastructure**
- ✅ Terraform configuration
- ✅ AWS resource provisioning
- ✅ CI/CD pipeline setup
- ✅ IAM user management

**Sprint 3 (Weeks 5-6): Backend Development**
- ✅ FastAPI application
- ✅ Database design (DynamoDB)
- ✅ Data pipeline (S3 + Lambda)
- ✅ API endpoints

**Sprint 4 (Weeks 7-8): Frontend Development**
- ✅ TypeScript type definitions
- ✅ Vue.js components
- ✅ D3.js visualizations
- ✅ API integration

**Sprint 5 (Weeks 9-10): Integration & Security**
- ✅ End-to-end testing
- ✅ Security hardening
- ✅ Performance optimization
- ✅ Monitoring setup

**Sprint 6 (Weeks 11-12): Demo Preparation**
- 🔄 Documentation completion
- 🔄 Demo preparation
- 🔄 Presentation materials
- 🔄 Final testing

---

## WHY THIS MATTERS

### Real-World Value

**Healthcare Impact:**
- **Problem**: Medication non-adherence costs $100-300B annually
- **Solution**: Real-time monitoring and alerts save lives
- **Market**: Healthcare IT is a $250B+ market growing 15% yearly

**Technical Skills:**
- Cloud architecture (AWS certification path)
- Modern web development (in-demand skills)
- DevSecOps practices (security automation)
- Data visualization (analytics career path)

**Career Relevance:**
This project demonstrates skills for roles like:
- Cloud Security Engineer ($120k-180k)
- DevSecOps Engineer ($110k-170k)
- Full-Stack Developer ($100k-150k)
- Healthcare IT Specialist ($90k-140k)

---

## PART 2: SOFTWARE ENGINEERING 101

### What Is Software Engineering?

**Simple Definition:** Software engineering is the systematic process of designing, building, testing, and maintaining computer programs.

**Key Principles:**

#### 1. **Modularity**
Breaking big problems into small pieces:
```
Large Application
├── Frontend Module
├── Backend Module  
├── Database Module
└── Infrastructure Module
```

#### 2. **Reusability**
Write code once, use it many times:
```python
# Instead of repeating code:
# Duplicate code 10 times...

# Write a reusable function:
def calculate_risk_score(patient_data):
    # Logic here
    return risk_score

# Use it anywhere:
risk1 = calculate_risk_score(patient1)
risk2 = calculate_risk_score(patient2)
```

#### 3. **Abstraction**
Hide complexity, show only what's needed:
```
User sees: "Click to upload file"
Behind scenes:
  - Validate file format
  - Check file size
  - Upload to S3
  - Trigger Lambda processing
  - Update database
  - Show confirmation
```

#### 4. **Documentation**
Explain your code for future you and others:
```python
def process_patient_data(data):
    """
    Processes patient data and calculates risk level.
    
    Args:
        data (dict): Patient medical data
        
    Returns:
        dict: Processed data with risk_level added
    """
    # Implementation...
```

---

## UNDERSTANDING SDLC

### Software Development Lifecycle

**SDLC** is the process of building software from idea to deployment.

### The 7 Phases

#### Phase 1: Planning
**What:** Define what we're building and why
**For AIER:** 
- Identified problem: ER staff need better patient monitoring
- Defined solution: Real-time dashboard with alerts
- Estimated timeline: 12 weeks
- Budget: ~$15/month AWS costs

#### Phase 2: Requirements Analysis
**What:** Detail exactly what the system must do
**For AIER:**
- Must display patient vitals
- Must calculate risk scores
- Must send alerts for critical patients
- Must work offline with LLM
- Must comply with HIPAA

#### Phase 3: Design
**What:** Plan the architecture and user experience
**For AIER:**
- System architecture diagram
- Database schema
- API endpoints specification
- UI/UX mockups
- Security model

#### Phase 4: Implementation (Coding)
**What:** Write the actual code
**For AIER:**
- Frontend: TypeScript + Vue.js
- Backend: Python + FastAPI
- Infrastructure: Terraform
- Data pipeline: Python scripts

#### Phase 5: Testing
**What:** Verify everything works correctly
**For AIER:**
- Unit tests (test individual functions)
- Integration tests (test components together)
- Security tests (vulnerability scanning)
- User acceptance testing

#### Phase 6: Deployment
**What:** Release to production
**For AIER:**
- Terraform provisions AWS infrastructure
- Frontend deployed to CloudFront
- Backend running on Lambda
- Database live on DynamoDB

#### Phase 7: Maintenance
**What:** Keep system running and improve it
**For AIER:**
- Monitor CloudWatch logs
- Fix bugs as discovered
- Add new features
- Update dependencies

### SDLC in Our Project

```
Week 1-2:  Planning & Requirements (Sprints 1)
Week 3-4:  Design & Architecture (Sprint 2)
Week 5-8:  Implementation (Sprints 3-4)
Week 9-10: Testing & Integration (Sprint 5)
Week 11-12: Deployment & Demo Prep (Sprint 6)
Ongoing: Maintenance
```

---

## CI/CD PIPELINE

### What Is CI/CD?

**CI = Continuous Integration**
Automatically test code every time someone makes changes

**CD = Continuous Deployment**
Automatically deploy code to production after tests pass

### Without CI/CD (Manual Process)

```
Developer writes code
  ↓
Developer manually tests
  ↓
Developer emails code to team
  ↓
Team manually reviews
  ↓
Team manually uploads to server
  ↓
Team manually configures server
  ↓
Hope nothing breaks!
```

**Problems:**
- Takes hours or days
- Human errors common
- Testing often skipped
- Deployment differences cause bugs

### With CI/CD (Automated)

```
Developer writes code
  ↓
Push to GitHub
  ↓
[AUTOMATIC]
  ├─ Run tests
  ├─ Security scan
  ├─ Build application
  ├─ Deploy to staging
  ├─ Run integration tests
  └─ Deploy to production (if all passed)
  ↓
Done in minutes!
```

**Benefits:**
- Fast (minutes vs hours)
- Consistent (same process every time)
- Safe (tests catch bugs before production)
- Documented (logs of every change)

### Our CI/CD Workflow

#### Tools We Use:
- **Git**: Version control
- **GitHub**: Code hosting
- **Terraform**: Infrastructure deployment
- **Scripts**: Automation

#### The Pipeline:

```bash
# 1. Code Check-in
git add .
git commit -m "Add patient risk calculation"
git push origin main

# 2. Automated Testing (would run)
# - Linting (code style check)
# - Unit tests
# - Type checking (TypeScript)
# - Security scanning

# 3. Build Phase
# - Compile TypeScript → JavaScript
# - Bundle frontend assets
# - Package Lambda functions
# - Generate documentation

# 4. Deploy Infrastructure
terraform plan   # Preview changes
terraform apply  # Deploy to AWS

# 5. Deploy Application
# - Upload frontend to S3
# - Update Lambda functions
# - Update CloudFront distribution

# 6. Verification
# - Health check endpoints
# - Smoke tests
# - Monitor logs

# 7. Notification
# - Slack/Email notification
# - Deployment dashboard update
```

---

## WHAT ARE APIs?

### API = Application Programming Interface

**Simple Analogy: Restaurant**

```
You (Frontend) → Waiter (API) → Kitchen (Backend)

1. You tell waiter your order (API Request)
2. Waiter tells kitchen (Processing)
3. Kitchen makes food (Backend logic)
4. Waiter brings food to you (API Response)
```

### REST API Explained

**REST = Representational State Transfer**

It's a way for computers to talk over the internet using standard methods:

**HTTP Methods:**
- `GET`: Read data ("Show me patients")
- `POST`: Create data ("Add new patient")
- `PUT`: Update data ("Change patient info")
- `DELETE`: Remove data ("Delete patient record")

### Example API Conversation

**Request (Frontend to Backend):**
```
GET /api/patients?risk_level=HIGH

Translation: "Give me all patients with HIGH risk level"
```

**Response (Backend to Frontend):**
```json
{
  "status": "success",
  "data": {
    "patients": [
      {
        "patient_id": "PT-00001",
        "name": "Anonymous",
        "risk_level": "HIGH",
        "heart_rate": 120,
        "blood_pressure": "180/110"
      }
    ],
    "count": 1
  }
}
```

### Our API Endpoints

Located in: `backend/app/main.py`

```
GET  /                          → API info
GET  /health                    → System health check
GET  /api/patients              → List all patients
GET  /api/patients/{id}         → Get specific patient
GET  /api/statistics            → Get summary statistics
GET  /api/visualizations/scatter → Get chart data
```

### How Frontend Uses API

```typescript
// TypeScript code in frontend
async function getPatients() {
  // Make API request
  const response = await fetch('http://localhost:8000/api/patients');
  
  // Parse JSON response
  const data = await response.json();
  
  // Use the data
  console.log(`Found ${data.count} patients`);
  displayPatients(data.patients);
}
```

---

## DATABASES DEMYSTIFIED

### What Is a Database?

**Simple Definition:** Organized storage for data with fast retrieval

**Real-Life Analogy:** Library
- Books = Data records
- Catalog system = Database index
- Librarian = Database management system

### Types of Databases

#### 1. **SQL (Relational) Databases**
Data in tables with strict structure

```
Patients Table:
┌────────────┬─────────┬─────┬──────────┐
│ patient_id │ name    │ age │ gender   │
├────────────┼─────────┼─────┼──────────┤
│ PT-00001   │ Alice   │ 45  │ Female   │
│ PT-00002   │ Bob     │ 52  │ Male     │
└────────────┴─────────┴─────┴──────────┘

Vitals Table:
┌────────────┬────────────┬──────────────┐
│ patient_id │ heart_rate │ blood_pressure│
├────────────┼────────────┼──────────────┤
│ PT-00001   │ 72         │ 120/80       │
│ PT-00002   │ 85         │ 130/85       │
└────────────┴────────────┴──────────────┘
```

**Examples:** PostgreSQL, MySQL, Oracle

#### 2. **NoSQL (Non-Relational) Databases**
Flexible structure, stores documents

```json
{
  "patient_id": "PT-00001",
  "name": "Alice",
  "age": 45,
  "vitals": {
    "heart_rate": 72,
    "blood_pressure": "120/80"
  },
  "medications": ["Metformin", "Lisinopril"]
}
```

**Examples:** DynamoDB (what we use), MongoDB, Cassandra

### Our Database: DynamoDB

**Why DynamoDB?**
- Serverless (no servers to manage)
- Scales automatically
- Pay only for usage
- Fast (single-digit millisecond response)
- AWS integrated

**Our Schema:**

```
Table: aier-patient-data

Primary Key:
  - patient_id (String) → Unique identifier
  - timestamp (Number) → When recorded

Attributes:
  - Age (Number)
  - Glucose (Number)
  - BMI (Number)
  - risk_level (String): LOW, MEDIUM, HIGH, CRITICAL
  - age_group (String): <30, 30-40, 40-50, 50-60, 60+
  - Outcome (Number): 0=no diabetes, 1=diabetes
  
Global Secondary Indexes:
  1. RiskLevelIndex → Query by risk_level
  2. AgeGroupIndex → Query by age_group
```

### Database Operations

**Create:**
```python
table.put_item(
    Item={
        'patient_id': 'PT-00001',
        'timestamp': 1234567890,
        'Age': 45,
        'Glucose': 120,
        'risk_level': 'MEDIUM'
    }
)
```

**Read:**
```python
response = table.get_item(
    Key={
        'patient_id': 'PT-00001',
        'timestamp': 1234567890
    }
)
```

**Query (with index):**
```python
response = table.query(
    IndexName='RiskLevelIndex',
    KeyConditionExpression=Key('risk_level').eq('HIGH')
)
```

**Update:**
```python
table.update_item(
    Key={'patient_id': 'PT-00001', 'timestamp': 1234567890},
    UpdateExpression='SET risk_level = :val',
    ExpressionAttributeValues={':val': 'HIGH'}
)
```

---

## INFRASTRUCTURE AS CODE

### What Is IaC?

**Traditional Way (Manual):**
1. Log into AWS Console
2. Click "Create S3 Bucket"
3. Enter name, select region
4. Configure permissions (20 clicks)
5. Enable encryption (5 clicks)
6. Repeat for 15+ resources...
7. Takes 2-3 hours, prone to mistakes

**Modern Way (Infrastructure as Code):**
```hcl
# main.tf
resource "aws_s3_bucket" "data_storage" {
  bucket = "aier-patient-data"
}

# Run once:
terraform apply

# Creates everything in 5 minutes!
```

### Benefits of IaC

#### 1. **Reproducibility**
Same code = same infrastructure every time
```bash
# Team member A creates infrastructure
terraform apply

# Team member B recreates identical infrastructure
terraform apply

# Result: Exactly the same!
```

#### 2. **Version Control**
Track infrastructure changes like code:
```bash
git log terraform/main.tf

# See who changed what and when:
# - John added DynamoDB encryption (2 weeks ago)
# - Sarah increased Lambda memory (1 week ago)
# - Mike added CloudFront CDN (yesterday)
```

#### 3. **Documentation**
The code IS the documentation:
```hcl
# This tells you exactly what exists:
resource "aws_s3_bucket" "data" { ... }
resource "aws_dynamodb_table" "patients" { ... }
resource "aws_lambda_function" "processor" { ... }
```

#### 4. **Automation**
Deploy with one command:
```bash
terraform apply -auto-approve
# Creates 15+ resources in AWS automatically
```

### Terraform Basics

#### **Resources**
Things you create in AWS:
```hcl
resource "aws_s3_bucket" "my_bucket" {
  bucket = "aier-data-storage"
}
```

#### **Variables**
Values you can change:
```hcl
variable "environment" {
  default = "development"
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "aier-data-${var.environment}"
}
# Result: "aier-data-development"
```

#### **Outputs**
Information to display after creation:
```hcl
output "bucket_name" {
  value = aws_s3_bucket.my_bucket.id
}
# After terraform apply: "bucket_name = aier-data-storage"
```

### Terraform Workflow

```bash
# 1. Initialize (download AWS provider)
terraform init

# 2. Preview changes
terraform plan
# Shows: Will create 15 resources

# 3. Apply changes
terraform apply
# Creates everything in AWS

# 4. Verify
terraform show
# Displays current state

# 5. Modify (edit main.tf)
# Add new resource or change existing

# 6. Preview changes again
terraform plan
# Shows: Will add 1 resource, modify 2 resources

# 7. Apply changes
terraform apply

# 8. Destroy everything (when done)
terraform destroy
# Deletes all resources to avoid charges
```

---

## PART 3: TECHNOLOGY STACK BREAKDOWN

### Frontend Technologies

#### TypeScript vs JavaScript

**JavaScript:** The original language for web browsers
```javascript
// JavaScript (no type checking)
function calculateAge(birthYear) {
  return 2025 - birthYear;
}

calculateAge("1990");  // ← String instead of number!
// Result: NaN (Not a Number) - BUG!
```

**TypeScript:** JavaScript + type safety
```typescript
// TypeScript (with types)
function calculateAge(birthYear: number): number {
  return 2025 - birthYear;
}

calculateAge("1990");  // ← ERROR before code even runs!
// TypeScript catches this mistake immediately
```

**Why TypeScript?**
- Catches bugs before runtime
- Better IDE autocomplete
- Self-documenting code
- Easier refactoring
- Industry standard for large projects

**Example from our project:**
```typescript
// frontend/src/types/patient.ts
interface Patient {
  patient_id: string;
  timestamp: number;
  Age: number;
  Glucose: number;
  BMI: number;
  risk_level: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
}

// Now TypeScript enforces this structure everywhere!
function displayPatient(patient: Patient) {
  console.log(patient.patient_id);  // ✓ OK
  console.log(patient.unknown);     // ✗ ERROR: property doesn't exist
}
```

#### Vue.js Framework

**What Is Vue.js?**
A JavaScript framework for building interactive user interfaces

**Without Framework (Plain JavaScript):**
```html
<div id="patient-count">Loading...</div>

<script>
  // Lots of manual DOM manipulation
  const element = document.getElementById('patient-count');
  fetch('/api/patients')
    .then(response => response.json())
    .then(data => {
      element.textContent = `Total: ${data.count}`;
    });
</script>
```

**With Vue.js:**
```vue
<template>
  <div>Total: {{ patientCount }}</div>
</template>

<script>
export default {
  data() {
    return { patientCount: 0 }
  },
  mounted() {
    fetch('/api/patients')
      .then(response => response.json())
      .then(data => {
        this.patientCount = data.count;  // Vue auto-updates display!
      });
  }
}
</script>
```

**Vue.js Features:**

**1. Reactive Data**
```vue
<template>
  <div>
    <input v-model="searchTerm" />
    <p>Searching for: {{ searchTerm }}</p>
  </div>
</template>

<script>
export default {
  data() {
    return { searchTerm: '' }
  }
}
</script>
<!-- Type in input → automatically updates paragraph -->
```

**2. Components**
```vue
<!-- PatientCard.vue -->
<template>
  <div class="card">
    <h3>{{ patient.patient_id }}</h3>
    <p>Risk: {{ patient.risk_level }}</p>
  </div>
</template>

<!-- Use many times: -->
<PatientCard :patient="patient1" />
<PatientCard :patient="patient2" />
<PatientCard :patient="patient3" />
```

**3. Conditional Rendering**
```vue
<div v-if="risk_level === 'CRITICAL'" class="alert-red">
  ⚠️ Critical Patient!
</div>
<div v-else-if="risk_level === 'HIGH'" class="alert-orange">
  ⚠ High Risk
</div>
<div v-else>
  ✓ Normal
</div>
```

#### D3.js Visualizations

**What Is D3.js?**
Data-Driven Documents - library for creating interactive charts and visualizations

**D3.js Power:**
- Binds data to visual elements
- Smooth animations
- Interactive charts
- Highly customizable

**Example: Scatter Plot**
```typescript
import * as d3 from 'd3';

// Data from API
const patients = [
  { bmi: 25, glucose: 120, risk: 'LOW' },
  { bmi: 32, glucose: 180, risk: 'HIGH' },
  // ...
];

// Create SVG canvas
const svg = d3.select('#chart')
  .append('svg')
  .attr('width', 600)
  .attr('height', 400);

// Draw circles for each patient
svg.selectAll('circle')
  .data(patients)
  .enter()
  .append('circle')
  .attr('cx', d => xScale(d.bmi))       // X position
  .attr('cy', d => yScale(d.glucose))   // Y position
  .attr('r', 5)                         // Radius
  .attr('fill', d => colorMap[d.risk]); // Color by risk

// Result: Interactive scatter plot!
```

**Our Visualizations:**
1. **Scatter Plot**: BMI vs Glucose
2. **Bar Chart**: Risk level distribution
3. **Line Chart**: Trends over time
4. **Pie Chart**: Age group breakdown

---

### Backend Technologies

#### FastAPI (Python Web Framework)

**What Is FastAPI?**
Modern Python framework for building APIs

**Why FastAPI?**
- Fast performance (comparable to Node.js)
- Automatic API documentation
- Type checking with Python type hints
- Async support
- Easy to learn

**Example Endpoint:**
```python
from fastapi import FastAPI

app = FastAPI()

@app.get("/api/patients")
async def get_patients():
    """
    Get list of all patients
    """
    patients = database.get_all_patients()
    return {
        "status": "success",
        "data": patients
    }

# FastAPI automatically:
# - Creates API documentation at /docs
# - Validates response format
# - Handles errors gracefully
# - Supports async operations
```

**Automatic Documentation:**
Visit `http://localhost:8000/docs` and FastAPI generates:
- Interactive API explorer
- Request/response examples
- Try-it-out functionality
- Schema definitions

**Type Safety:**
```python
from typing import List, Optional
from pydantic import BaseModel

class Patient(BaseModel):
    patient_id: str
    age: int
    risk_level: str

@app.get("/api/patients", response_model=List[Patient])
async def get_patients():
    # FastAPI validates response matches Patient model
    pass
```

---

## PART 4: AWS SERVICES IN DETAIL

### Understanding IAM

**IAM = Identity and Access Management**

Think of IAM as the security system for your AWS account.

**Key Concepts:**

#### 1. **Users**
Individual people or applications:
```
aier-javi       → Team member Javi
aier-shay       → Team member Shay
aier-cyberdog   → Team lead
aier-crystal    → Team member Crystal
aier-cuoung     → Team member Cuoung
```

#### 2. **Groups**
Collections of users with same permissions:
```
Group: AIER-Developers
  ├─ aier-javi
  ├─ aier-shay
  └─ aier-crystal

Permissions: Read/write to project resources
```

#### 3. **Policies**
Rules defining what users can do:
```json
{
  "Effect": "Allow",
  "Action": [
    "s3:GetObject",
    "s3:PutObject"
  ],
  "Resource": "arn:aws:s3:::aier-patient-data/*"
}
```
**Translation:** "Allow reading and writing files in aier-patient-data bucket"

#### 4. **Roles**
Temporary permissions for services:
```
Role: Lambda-Execution-Role
  Permissions:
    - Write logs to CloudWatch
    - Read from S3
    - Write to DynamoDB
    
Lambda function assumes this role to access other services
```

**Why IAM Matters:**

**Security:**
```
❌ Bad: Everyone has full admin access
   Risk: Accidental deletion, security breaches

✓ Good: Least privilege access
   Each person/service gets only what they need
```

**Auditability:**
```
CloudTrail logs every action:
- Who: aier-javi
- What: Deleted S3 object
- When: 2025-10-01 14:30:00
- Where: us-east-1
```

**Cost Control:**
```
Policy: Developers can't create expensive resources
- ✓ Can create S3 buckets
- ✗ Cannot create large RDS databases
```

**Our IAM Setup:**

```bash
# Create team users
bash scripts/create_team_users.sh

# Creates:
# 1. IAM users (aier-javi, aier-shay, etc.)
# 2. Access keys for each user
# 3. Group with developer permissions
# 4. Password for AWS Console access

# Each team member gets:
team-credentials/[name]-credentials.txt
  - Console login URL
  - Username
  - Temporary password
  - Access key ID
  - Secret access key
```

**IAM Best Practices:**

1. **Never share credentials**
   - Each person has their own
   - Credentials = password, keep secret

2. **Use MFA (Multi-Factor Authentication)**
   ```
   Login = Password + Phone code
   Much more secure!
   ```

3. **Rotate credentials regularly**
   ```bash
   # Every 90 days:
   aws iam create-access-key --user-name aier-javi
   aws iam delete-access-key --access-key-id OLD_KEY_ID
   ```

4. **Principle of least privilege**
   ```
   ✓ Give minimum permissions needed
   ✗ Don't give full admin unless necessary
   ```

---

### S3 - Storage

**S3 = Simple Storage Service**

**What Is S3?**
Object storage for files in the cloud

**Real-Life Analogy:**
S3 is like Google Drive or Dropbox, but for applications:
- Store any type of file
- Access from anywhere
- Pay only for what you store
- Unlimited capacity

**Key Concepts:**

#### Buckets
Top-level containers:
```
aier-patient-data-development/
  ├─ processed/
  │  ├─ patients.csv
  │  └─ vitals.json
  ├─ raw/
  │  └─ kaggle-diabetes.csv
  └─ archive/
     └─ backup-2025-10-01.zip

aier-frontend-development/
  ├─ index.html
  ├─ assets/
  │  ├─ main.js
  │  └─ styles.css
  └─ images/
     └─ logo.png
```

#### Objects
Files stored in buckets:
```
Object: processed/patients.csv
  - Size: 125 KB
  - Type: text/csv
  - Metadata: last-modified, content-type
  - URL: https://s3.amazonaws.com/aier-patient-data/processed/patients.csv
```

**S3 Features:**

#### 1. **Versioning**
Keep multiple versions of files:
```
patients.csv (version 1) - uploaded Monday
patients.csv (version 2) - uploaded Tuesday  ← Current
patients.csv (version 3) - uploaded Wednesday

Can restore any previous version!
```

#### 2. **Encryption**
All data encrypted automatically:
```
Upload: patients.csv
  ↓
[S3 Encrypts with AES-256]
  ↓
Stored: jh4k2jh4k2jhk34j (encrypted blob)
  ↓
[S3 Decrypts when you download]
  ↓
Download: patients.csv (original)
```

#### 3. **Access Control**
Who can access what:
```
Public: Everyone can read
Private: Only authorized users
```

#### 4. **Event Notifications**
Trigger actions when files uploaded:
```
File uploaded to S3
  ↓
Triggers Lambda function
  ↓
Lambda processes file
  ↓
Saves to DynamoDB
```

**Our S3 Usage:**

**Data Bucket:**
```
aier-patient-data-development/
  Purpose: Store patient data files
  
  Security:
    - Private (not public)
    - Encrypted (AES-256)
    - Versioned (can restore)
    - Logged (CloudTrail)
```

**Frontend Bucket:**
```
aier-frontend-development/
  Purpose: Host website files
  
  Configuration:
    - Website hosting enabled
    - CloudFront distribution
    - HTTPS enforced
```

**S3 Commands:**

```bash
# List buckets
aws s3 ls

# List files in bucket
aws s3 ls s3://aier-patient-data-development/

# Upload file
aws s3 cp patients.csv s3://aier-patient-data-development/processed/

# Download file
aws s3 cp s3://aier-patient-data-development/processed/patients.csv ./

# Sync directory (like rsync)
aws s3 sync ./frontend/dist/ s3://aier-frontend-development/

# Delete file
aws s3 rm s3://aier-patient-data-development/old-file.csv
```

---

### DynamoDB - Database

**What Is DynamoDB?**
NoSQL database service - stores data as JSON-like documents

**Why DynamoDB?**
- Serverless (no servers to manage)
- Fast (< 10ms response time)
- Scales automatically
- Pay per request
- Fully managed

**Structure:**

#### Tables
```
Table: aier-patient-data

Item (like a row):
{
  "patient_id": "PT-00001",    ← Primary Key
  "timestamp": 1696104000,      ← Sort Key
  "Age": 45,
  "Glucose": 120,
  "BMI": 28.5,
  "risk_level": "MEDIUM"
}
```

#### Keys

**Primary Key (Partition Key):**
```
patient_id = "PT-00001"

Purpose: Distributes data across partitions
Like: Filing cabinet drawer (partition) for each letter
```

**Sort Key (Range Key):**
```
timestamp = 1696104000

Purpose: Orders items within same partition
Allows: Get all records for patient over time
```

**Composite Key:**
```
Primary Key = patient_id + timestamp

Uniquely identifies each item:
  PT-00001 @ 1696104000 ≠ PT-00001 @ 1696108000
  
Enables: Time-series queries
```

#### Global Secondary Indexes (GSI)

Query by attributes other than primary key:

**RiskLevelIndex:**
```
Query: "Give me all HIGH risk patients"

Without GSI:
  - Scan entire table (slow, expensive)
  - Filter risk_level = "HIGH"
  - Returns results

With GSI:
  - Direct lookup in index (fast, cheap)
  - Returns results immediately
```

**Our Indexes:**
```
1. RiskLevelIndex
   Partition Key: risk_level
   Sort Key: timestamp
   
   Use case: Get all CRITICAL patients

2. AgeGroupIndex
   Partition Key: age_group
   Sort Key: timestamp
   
   Use case: Get all patients 60+
```

**DynamoDB Operations:**

**PutItem (Create/Update):**
```python
table.put_item(
    Item={
        'patient_id': 'PT-00001',
        'timestamp': 1696104000,
        'Age': 45,
        'Glucose': 120,
        'risk_level': 'MEDIUM'
    }
)
```

**GetItem (Read):**
```python
response = table.get_item(
    Key={
        'patient_id': 'PT-00001',
        'timestamp': 1696104000
    }
)
item = response['Item']
```

**Query (Multiple items):**
```python
# Get all records for patient
response = table.query(
    KeyConditionExpression=Key('patient_id').eq('PT-00001')
)

# Get patient records in time range
response = table.query(
    KeyConditionExpression=
        Key('patient_id').eq('PT-00001') &
        Key('timestamp').between(start, end)
)
```

**Scan (Read all):**
```python
response = table.scan()
all_items = response['Items']

# Warning: Expensive for large tables!
# Use Query with indexes instead
```

**UpdateItem:**
```python
table.update_item(
    Key={'patient_id': 'PT-00001', 'timestamp': 1696104000},
    UpdateExpression='SET risk_level = :val',
    ExpressionAttributeValues={':val': 'HIGH'}
)
```

**Delete:**
```python
table.delete_item(
    Key={'patient_id': 'PT-00001', 'timestamp': 1696104000}
)
```

**Capacity Modes:**

**On-Demand (Our choice):**
```
Pay per request:
  - $1.25 per million writes
  - $0.25 per million reads
  
Good for:
  - Unpredictable traffic
  - Development/testing
  - Spiky workloads
```

**Provisioned:**
```
Reserve capacity:
  - 10 read units/second
  - 5 write units/second
  
Good for:
  - Predictable traffic
  - Cost optimization
  - Production at scale
```

---

### Lambda - Serverless

**AWS Lambda** = Run code without managing servers

**Traditional Server:**
```
1. Buy/rent server
2. Install operating system
3. Install Python/Node.js
4. Deploy your code
5. Monitor server 24/7
6. Scale up/down manually
7. Pay for server running 24/7
```

**Lambda (Serverless):**
```
1. Upload code
2. Lambda runs it when triggered
3. Scales automatically
4. Pay only when code runs
```

**How Lambda Works:**

```
Trigger Event
  ↓
Lambda creates container
  ↓
Loads your code
  ↓
Runs your function
  ↓
Returns result
  ↓
Container destroyed

Total time: Milliseconds to seconds
```

**Lambda Triggers:**

```
S3 Upload → Lambda processes file
API request → Lambda returns data
Schedule (cron) → Lambda runs task
DynamoDB change → Lambda reacts
```

**Our Lambda Function:**

```
Name: aier-data-processor
Runtime: Python 3.9
Timeout: 300 seconds (5 minutes)
Memory: 512 MB

Trigger: S3 upload to processed/ folder

What it does:
1. Reads CSV file from S3
2. Validates data
3. Calculates risk scores
4. Writes to DynamoDB
5. Logs to CloudWatch
```

**Lambda Function Code Structure:**

```python
def handler(event, context):
    """
    Lambda entry point
    
    event: Information about what triggered Lambda
    context: Runtime information
    """
    
    # 1. Parse event
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']
    
    # 2. Download file from S3
    s3 = boto3.client('s3')
    file_content = s3.get_object(Bucket=bucket, Key=key)
    
    # 3. Process data
    data = parse_csv(file_content)
    processed = calculate_risk_scores(data)
    
    # 4. Save to DynamoDB
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('aier-patient-data')
    for record in processed:
        table.put_item(Item=record)
    
    # 5. Return success
    return {
        'statusCode': 200,
        'body': f'Processed {len(processed)} records'
    }
```

**Lambda Pricing:**

```
First 1 million requests/month: FREE
After that: $0.20 per million requests

Duration charges:
  $0.00001667 per GB-second

Example for our project:
  - 100 invocations/day
  - 2 seconds each
  - 512 MB memory
  
Cost: ~$0.05/month
```

**Lambda Limits:**

```
Timeout: Max 15 minutes
Memory: 128 MB - 10 GB
Payload: Max 6 MB (request/response)
Deployment package: Max 50 MB (zipped)
/tmp storage: Max 512 MB
```

---

### CloudFront - CDN

**CloudFront** = Content Delivery Network

**Problem:**
```
User in Tokyo requests website
  ↓
Request travels to Virginia (where S3 is)
  ↓
10,000 miles round trip
  ↓
Slow load time (2-3 seconds)
```

**Solution with CloudFront:**
```
User in Tokyo requests website
  ↓
CloudFront serves from Tokyo edge location
  ↓
50 miles round trip
  ↓
Fast load time (50-100 milliseconds)
```

**How CloudFront Works:**

```
First request:
  User → CloudFront (cache miss)
         → Origin (S3)
         → Return content
         → Cache in edge location

Subsequent requests:
  User → CloudFront (cache hit!)
         → Return from cache (fast!)
```

**Edge Locations:**

```
CloudFront has 400+ edge locations worldwide:

North America: 100+
Europe: 80+
Asia: 80+
South America: 20+
Africa: 10+
Australia: 10+

User always gets content from nearest location
```

**Cache Behavior:**

```
File Types:
  - Images (.jpg, .png): Cache for 24 hours
  - CSS/JS: Cache for 1 hour
  - HTML: Cache for 5 minutes
  - API calls: No cache (dynamic)

Cache invalidation:
  When you update files:
  aws cloudfront create-invalidation \
    --distribution-id EXAMPLEID \
    --paths "/*"
```

**Our CloudFront Setup:**

```
Distribution: AIER Frontend

Origin: aier-frontend-development S3 bucket

Settings:
  - HTTPS only (security)
  - Compress files (gzip)
  - Cache static assets
  - Custom error pages
  
URL: https://d123abc456def.cloudfront.net
```

**CloudFront Features:**

**1. HTTPS/SSL:**
```
All traffic encrypted
Free SSL certificate
Enforced HTTPS redirect
```

**2. Compression:**
```
Original file: 1 MB
Compressed: 200 KB (80% smaller!)
Faster downloads, lower bandwidth costs
```

**3. Geographic Restrictions:**
```
Can restrict access by country:
  Allow: US, Canada, UK
  Block: Others
  
(Not used in our project - worldwide access)
```

**4. Custom Error Pages:**
```
404 Not Found → Show friendly error page
500 Server Error → Show maintenance page
403 Forbidden → Show access denied page
```

**Performance Impact:**

```
Without CloudFront:
  - Load time: 2-5 seconds
  - Bandwidth: Full file size each time
  - Server load: High

With CloudFront:
  - Load time: 100-500 milliseconds
  - Bandwidth: Cached, compressed
  - Server load: Minimal
```

---

## PART 5: THE AIER ALERT SYSTEM

### AIER System Architecture

**AIER = AI-Based ER Alert System**

**Two Operating Modes:**

#### Online Mode (Full AWS Cloud)

```
Patient Data Source
  ↓
[S3 Storage]
  ↓ (Event Trigger)
[Lambda Processing]
  ↓
[DynamoDB Storage]
  ↓
[FastAPI Backend]
  ↓
[CloudFront CDN]
  ↓
[Vue.js Dashboard]
  ↓
Medical Staff View Data & Alerts
```

#### Offline Mode (Local LLM)

```
Patient Data (Local Device)
  ↓
[Local LLM Model]
  ↓
[Risk Analysis]
  ↓
[Local Storage]
  ↓
[Local Web Interface]
  ↓
Medical Staff (No Internet Needed)
```

**Use Cases:**

**Online Mode:**
- Hospital with reliable internet
- Real-time data sync across departments
- Cloud backup and redundancy
- Advanced analytics and reporting

**Offline Mode:**
- Rural clinics
- Disaster response (hurricanes, earthquakes)
- Military field hospitals
- Areas with unreliable connectivity
- Privacy-sensitive scenarios

### Data Flow (Online)

**Step-by-Step Process:**

#### 1. Data Acquisition
```
Source: Kaggle Diabetes Dataset
  768 patient records with:
    - Demographics (Age, Gender)
    - Vitals (Blood Pressure, BMI)
    - Lab Results (Glucose, Insulin)
    - Medical History (Pregnancies, Diabetes Pedigree)
    - Outcome (Diabetes or not)
```

#### 2. Data Preprocessing
```python
# Script: data-pipeline.py

def preprocess_data(raw_data):
    """
    1. Anonymize (remove/mask PII)
    2. Validate (check for errors)
    3. Enrich (add calculated fields)
    4. Format (structure for database)
    """
    
    processed = []
    for record in raw_data:
        # Anonymize
        patient_id = generate_anonymous_id()
        
        # Calculate risk score
        risk = calculate_risk(
            glucose=record['Glucose'],
            bmi=record['BMI'],
            age=record['Age'],
            blood_pressure=record['BloodPressure']
        )
        
        # Categorize age
        age_group = categorize_age(record['Age'])
        
        # Format
        processed_record = {
            'patient_id': patient_id,
            'timestamp': int(time.time()),
            'Age': record['Age'],
            'age_group': age_group,
            'Glucose': record['Glucose'],
            'BMI': record['BMI'],
            'risk_level': risk,
            'Outcome': record['Outcome']
        }
        
        processed.append(processed_record)
    
    return processed
```

#### 3. Upload to S3
```bash
# Upload processed CSV
aws s3 cp processed-patients.csv \
  s3://aier-patient-data-development/processed/

# S3 generates event
```

#### 4. Lambda Processing
```python
# Lambda function triggered automatically

def handler(event, context):
    # Get file info from event
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']
    
    # Download from S3
    csv_data = download_from_s3(bucket, key)
    
    # Parse CSV
    records = parse_csv(csv_data)
    
    # Write to DynamoDB (batched)
    batch_write_to_dynamodb(records)
    
    # Log success
    logger.info(f"Processed {len(records)} records")
```

#### 5. Storage in DynamoDB
```
Records stored with:
  - Fast retrieval (< 10ms)
  - Indexed by risk_level and age_group
  - Queryable by patient_id
  - Time-series support (timestamp)
```

#### 6. API Serving
```python
# FastAPI serves data to frontend

@app.get("/api/patients")
async def get_patients():
    # Query DynamoDB
    response = dynamodb_table.scan(Limit=50)
    
    # Format response
    return {
        "status": "success",
        "data": {
            "patients": response['Items'],
            "count": len(response['Items'])
        }
    }
```

#### 7. Frontend Display
```typescript
// Vue.js component fetches and displays

async function loadPatients() {
  // Call API
  const response = await fetch('/api/patients');
  const data = await response.json();
  
  // Update reactive state
  patients.value = data.data.patients;
  
  // Vue automatically re-renders UI
}

// D3.js visualizes
function createChart(patients) {
  // Scatter plot of BMI vs Glucose
  svg.selectAll('circle')
    .data(patients)
    .enter()
    .append('circle')
    .attr('cx', d => xScale(d.BMI))
    .attr('cy', d => yScale(d.Glucose))
    .attr('fill', d => colorByRisk(d.risk_level));
}
```

#### 8. Monitoring & Alerts
```
CloudWatch monitors:
  - Lambda execution time
  - DynamoDB throughput
  - API response times
  - Error rates

Alerts trigger if:
  - Error rate > 5%
  - Response time > 500ms
  - Lambda failures
```

### Alert Mechanisms

**Risk Level Calculation:**

```python
def calculate_risk_level(patient_data):
    """
    Calculates risk score based on multiple factors
    """
    score = 0
    
    # Age factor (0-30 points)
    if patient_data['Age'] > 60:
        score += 30
    elif patient_data['Age'] > 50:
        score += 20
    elif patient_data['Age'] > 40:
        score += 10
    
    # Glucose factor (0-40 points)
    if patient_data['Glucose'] > 180:
        score += 40
    elif patient_data['Glucose'] > 140:
        score += 30
    elif patient_data['Glucose'] > 120:
        score += 20
    
    # BMI factor (0-20 points)
    if patient_data['BMI'] > 35:
        score += 20
    elif patient_data['BMI'] > 30:
        score += 15
    elif patient_data['BMI'] > 25:
        score += 10
    
    # Blood Pressure factor (0-10 points)
    bp = patient_data['BloodPressure']
    if bp > 140:
        score += 10
    elif bp > 120:
        score += 5
    
    # Map score to risk level
    if score >= 70:
        return 'CRITICAL'
    elif score >= 50:
        return 'HIGH'
    elif score >= 30:
        return 'MEDIUM'
    else:
        return 'LOW'
```

**Alert Types:**

```
CRITICAL (Score 70+):
  - Visual: Red background, flashing
  - Audio: Alert sound
  - Notification: Push notification to staff
  - Action: Auto-escalate to supervisor

HIGH (Score 50-69):
  - Visual: Orange/yellow indicator
  - Notification: In-app notification
  - Action: Add to priority queue

MEDIUM (Score 30-49):
  - Visual: Yellow indicator
  - Action: Regular monitoring

LOW (Score < 30):
  - Visual: Green indicator
  - Action: Standard care
```

**Real-Time Updates:**

```
Option 1: Polling (Current simple approach)
  Frontend checks every 30 seconds:
    → GET /api/patients
    → Update if changes

Option 2: WebSockets (Real-time)
  Persistent connection:
    Server → Push updates immediately
    No delay, instant alerts

Option 3: Server-Sent Events (SSE)
  One-way real-time:
    Server → Stream updates to clients
    Simpler than WebSockets
```

---

## PART 6: HANDS-ON DEMO

### Script Execution Guide

**Scripts Location:** `/data_viz/scripts/`

**Scripts Overview:**

```
00_console_view_link.sh     → Get AWS Console link
00_security_check.sh        → Verify no credentials in code
01_init_terraform.sh        → Initialize Terraform
02_plan_terraform.sh        → Preview infrastructure changes
03_apply_terraform.sh       → Deploy infrastructure
04_verify_deployment.sh     → Verify everything created
99_destroy_terraform.sh     → Delete all resources

aws-setup-mac.sh           → Setup AWS CLI (Mac/Linux)
aws-setup-windows.ps1      → Setup AWS CLI (Windows)

create_team_users.sh       → Create IAM users
delete_team_users.sh       → Delete IAM users
update_iam_policy.sh       → Update IAM permissions

download-dataset.py        → Download Kaggle data
data-pipeline.py           → Process and upload data

demo.sh                    → Complete demo workflow
```

### Sequential Setup

**Complete Demo Workflow (From Scratch):**

#### Prerequisites Check
```bash
# 1. Check Git installed
git --version
# Expected: git version 2.x.x

# 2. Check AWS CLI installed  
aws --version
# Expected: aws-cli/2.x.x

# 3. Check Terraform installed
terraform --version
# Expected: Terraform v1.x.x

# 4. Check Python installed
python3 --version
# Expected: Python 3.9+

# 5. Check Node.js installed (for frontend)
node --version
# Expected: v18.x.x or higher
```

#### Step 1: AWS Configuration
```bash
# Run AWS setup script
cd /Volumes/Exchange/projects/capstone/data_viz
bash scripts/aws-setup-mac.sh

# This will prompt:
# AWS Access Key ID: [paste your access key]
# AWS Secret Access Key: [paste your secret key]
# Default region name: us-east-1
# Default output format: json

# Verify configuration
aws sts get-caller-identity

# Expected output:
# {
#     "UserId": "AIDAI...",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/aier-yourname"
# }
```

#### Step 2: Security Check
```bash
# Verify no credentials in code
bash scripts/00_security_check.sh

# Expected output:
# ✓ No AWS access keys found
# ✓ No private keys found
# ✓ No secret files found
# ✓ Security check passed!
```

#### Step 3: Initialize Infrastructure
```bash
# Initialize Terraform
bash scripts/01_init_terraform.sh

# What happens:
# 1. Changes to terraform/ directory
# 2. Runs: terraform init
# 3. Downloads AWS provider plugins
# 4. Initializes backend

# Expected output:
# Initializing the backend...
# Initializing provider plugins...
# - Finding hashicorp/aws versions matching "~> 5.0"...
# - Installing hashicorp/aws v5.x.x...
# 
# Terraform has been successfully initialized!
```

#### Step 4: Preview Changes
```bash
# Preview infrastructure
bash scripts/02_plan_terraform.sh

# What happens:
# 1. Changes to terraform/ directory
# 2. Runs: terraform plan
# 3. Shows what will be created

# Expected output:
# Terraform will perform the following actions:
#
#   # aws_s3_bucket.data_storage will be created
#   + resource "aws_s3_bucket" "data_storage" {
#       + bucket = "aier-data-development"
#       ...
#     }
#
#   # aws_dynamodb_table.patient_data will be created
#   + resource "aws_dynamodb_table" "patient_data" {
#       + name = "aier-patient-data"
#       ...
#     }
#
#   ... (15+ resources total)
#
# Plan: 15 to add, 0 to change, 0 to destroy.

# ⚠️ REVIEW THIS CAREFULLY!
# Make sure it's creating what you expect
```

#### Step 5: Deploy Infrastructure
```bash
# Deploy to AWS
bash scripts/03_apply_terraform.sh

# What happens:
# 1. Changes to terraform/ directory
# 2. Runs: terraform apply -auto-approve
# 3. Creates all resources in AWS

# This takes 5-10 minutes (CloudFront is slow)

# Expected output:
# aws_s3_bucket.data_storage: Creating...
# aws_dynamodb_table.patient_data: Creating...
# aws_iam_role.lambda_execution: Creating...
# ...
# aws_cloudfront_distribution.frontend: Creating... (this is slow)
# ...
# Apply complete! Resources: 15 added, 0 changed, 0 destroyed.
#
# Outputs:
# cloudfront_url = "https://d123abc456def.cloudfront.net"
# data_bucket_name = "aier-data-development"
# dynamodb_table_name = "aier-patient-data"
# frontend_bucket_name = "aier-frontend-development"
# lambda_function_name = "aier-data-processor"

# ✓ Infrastructure is now live in AWS!
```

#### Step 6: Verify Deployment
```bash
# Verify everything created successfully
bash scripts/04_verify_deployment.sh

# What happens:
# Checks for:
#   - S3 buckets
#   - DynamoDB tables
#   - Lambda functions
#   - CloudFront distributions

# Expected output:
# Checking S3 buckets...
# ✓ Found: aier-data-development
# ✓ Found: aier-frontend-development
#
# Checking DynamoDB tables...
# ✓ Found: aier-patient-data
#
# Checking Lambda functions...
# ✓ Found: aier-data-processor
#
# Checking CloudFront distributions...
# ✓ Found: EXAMPLEID
#
# ✓ All resources verified!
```

#### Step 7: Download & Process Data
```bash
# Download Kaggle dataset
python3 scripts/download-dataset.py

# Expected output:
# Downloading diabetes dataset...
# ✓ Downloaded: 768 rows
# ✓ Saved to: data/diabetes.csv

# Process and upload data
python3 scripts/data-pipeline.py

# Expected output:
# Loading data...
# ✓ Loaded 768 records
#
# Processing data...
# - Anonymizing patient IDs
# - Calculating risk scores
# - Categorizing age groups
# ✓ Processed 768 records
#
# Uploading to S3...
# ✓ Uploaded to: s3://aier-data-development/processed/patients.csv
#
# Triggering Lambda processing...
# ✓ Lambda triggered
#
# Waiting for DynamoDB update...
# ✓ Records in DynamoDB: 768
#
# ✓ Data pipeline complete!
```

#### Step 8: Start Backend
```bash
# Install Python dependencies
cd backend
pip3 install -r requirements.txt

# Expected output:
# Collecting fastapi
# Collecting uvicorn
# Collecting boto3
# ...
# Successfully installed fastapi-0.104.1 uvicorn-0.24.0 boto3-1.29.7

# Set environment variables
export AWS_REGION=us-east-1
export DYNAMODB_TABLE_NAME=aier-patient-data

# Start FastAPI server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Expected output:
# INFO:     Will watch for changes in these directories: ['/path/to/backend']
# INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
# INFO:     Started reloader process
# INFO:     Started server process
# INFO:     Waiting for application startup.
# INFO:     Application startup complete.

# Test API:
# Open browser: http://localhost:8000/docs
# Should see: FastAPI Swagger documentation

# ✓ Backend is running!
```

#### Step 9: Start Frontend
```bash
# Open new terminal window

cd frontend

# Install Node dependencies
npm install

# Expected output:
# added 237 packages, and audited 238 packages in 15s
# ...
# found 0 vulnerabilities

# Start Vue.js dev server
npm run dev

# Expected output:
# VITE v5.0.5  ready in 523 ms
#
# ➜  Local:   http://localhost:5173/
# ➜  Network: http://192.168.1.100:5173/
# ➜  press h to show help

# Open browser: http://localhost:5173/
# Should see: AIER Dashboard with patient data

# ✓ Frontend is running!
```

#### Step 10: View AWS Console
```bash
# Get console login link
bash scripts/00_console_view_link.sh

# Expected output:
# AWS Console Login:
# URL: https://console.aws.amazon.com/
# Account ID: 123456789012
#
# Resources to view:
# - S3: https://s3.console.aws.amazon.com/s3/buckets?region=us-east-1
# - DynamoDB: https://console.aws.amazon.com/dynamodb/home?region=us-east-1
# - Lambda: https://console.aws.amazon.com/lambda/home?region=us-east-1
# - CloudFront: https://console.aws.amazon.com/cloudfront/home

# Click links to view resources in AWS Console
```

---

### Breaking Down Scripts

Let's examine each script in detail.

#### 01_init_terraform.sh

```bash
#!/bin/bash
# Shebang: Tells system to use bash to run this script

set -e
# Exit immediately if any command fails

# Change to terraform directory
cd "$(dirname "$0")/../terraform"
# $(dirname "$0") = directory where script is located
# /../terraform = go up one level, then into terraform folder
# Result: Always runs from correct directory

echo "Initializing Terraform..."
terraform init

# terraform init does:
# 1. Download AWS provider plugin
# 2. Initialize backend (state storage)
# 3. Create .terraform/ directory

echo "✓ Terraform initialized!"
```

**When to run:** Once at the beginning, or after pulling new changes that modify Terraform configuration

#### 02_plan_terraform.sh

```bash
#!/bin/bash

set -e

cd "$(dirname "$0")/../terraform"

echo "Generating Terraform plan..."
echo ""

terraform plan

# terraform plan does:
# 1. Read main.tf and variables.tf
# 2. Check current AWS state
# 3. Calculate differences
# 4. Show what will change:
#    + = will create
#    ~ = will modify
#    - = will delete

echo ""
echo "Review the plan above."
echo "If it looks correct, run: bash scripts/03_apply_terraform.sh"
```

**When to run:** Before applying changes, to preview what will happen

#### 03_apply_terraform.sh

```bash
#!/bin/bash

set -e

cd "$(dirname "$0")/../terraform"

echo "Applying Terraform configuration..."
echo "This will create resources in AWS."
echo ""

terraform apply -auto-approve
# -auto-approve: Don't ask for confirmation
# Use with caution! Always run plan first.

# terraform apply does:
# 1. Create/update all resources defined in main.tf
# 2. Update terraform.tfstate file
# 3. Display outputs

echo ""
echo "✓ Infrastructure deployed!"
echo ""
echo "Outputs:"
terraform output
```

**When to run:** After reviewing plan, to actually deploy infrastructure

**Caution:** This creates real resources in AWS that may incur costs

#### 04_verify_deployment.sh

```bash
#!/bin/bash

set -e

echo "Verifying AWS deployment..."
echo ""

# Check S3 buckets
echo "Checking S3 buckets..."
aws s3 ls | grep aier | while read -r line; do
    echo "✓ Found S3 bucket: $line"
done

echo ""

# Check DynamoDB tables
echo "Checking DynamoDB tables..."
aws dynamodb list-tables \
    --query 'TableNames[?contains(@, `aier`)]' \
    --output text | tr '\t' '\n' | while read -r table; do
    echo "✓ Found DynamoDB table: $table"
done

echo ""

# Check Lambda functions
echo "Checking Lambda functions..."
aws lambda list-functions \
    --query 'Functions[?contains(FunctionName, `aier`)].FunctionName' \
    --output text | tr '\t' '\n' | while read -r func; do
    echo "✓ Found Lambda function: $func"
done

echo ""

# Check CloudFront distributions
echo "Checking CloudFront distributions..."
aws cloudfront list-distributions \
    --query 'DistributionList.Items[*].[Id,DomainName,Status]' \
    --output text | while read -r id domain status; do
    echo "✓ Found CloudFront distribution:"
    echo "  ID: $id"
    echo "  Domain: $domain"
    echo "  Status: $status"
done

echo ""
echo "✓ Verification complete!"
```

**When to run:** After applying infrastructure, to confirm everything was created

#### 99_destroy_terraform.sh

```bash
#!/bin/bash

set -e

cd "$(dirname "$0")/../terraform"

echo "⚠️  WARNING: This will destroy all infrastructure!"
echo "This action cannot be undone."
echo ""
read -p "Are you sure you want to proceed? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "Destroying infrastructure..."

terraform destroy -auto-approve

# terraform destroy does:
# 1. Delete all resources created by Terraform
# 2. Update terraform.tfstate
# 3. Clean up AWS

echo ""
echo "✓ All resources destroyed."
echo "Note: Check AWS Console to verify everything is deleted."
```

**When to run:** When you want to delete all infrastructure to avoid AWS charges

**Warning:** This is destructive and irreversible!

---

### Code Walkthrough

#### Terraform Configuration (main.tf)

Let's walk through the Terraform file section by section:

**Provider Configuration:**
```hcl
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "AIER-Alert-System"
      Component   = "Frontend-Visualization"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
```

**What this does:**
- Tells Terraform to use AWS
- Sets region (us-east-1)
- Adds tags to all resources automatically
- Tags help organize and track costs

**S3 Bucket for Data:**
```hcl
resource "aws_s3_bucket" "data_storage" {
  bucket = "${var.project_name}-data-${var.environment}"
  
  tags = {
    Name = "AIER Data Storage"
  }
}
```

**Breaking it down:**
- `resource`: Declares something to create
- `"aws_s3_bucket"`: Type of resource
- `"data_storage"`: Local name (used in Terraform)
- `bucket`: Actual bucket name in AWS
- `${var.project_name}`: Variable substitution
  - If project_name = "aier"
  - And environment = "development"
  - Result: "aier-data-development"

**S3 Encryption:**
```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "data_storage" {
  bucket = aws_s3_bucket.data_storage.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

**What this does:**
- Enables encryption on S3 bucket
- Uses AES-256 algorithm (military-grade encryption)
- All uploaded files automatically encrypted
- Required for HIPAA compliance

**DynamoDB Table:**
```hcl
resource "aws_dynamodb_table" "patient_data" {
  name           = "${var.project_name}-patient-data"
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
  
  global_secondary_index {
    name            = "RiskLevelIndex"
    hash_key        = "risk_level"
    range_key       = "timestamp"
    projection_type = "ALL"
  }
}
```

**Breaking it down:**
- `billing_mode = "PAY_PER_REQUEST"`: Only pay for what you use
- `hash_key`: Primary partition key (distributes data)
- `range_key`: Sort key (orders within partition)
- `attribute`: Define column types
  - "S" = String
  - "N" = Number
  - "B" = Binary
- `global_secondary_index`: Additional query patterns

**Lambda Function:**
```hcl
resource "aws_lambda_function" "data_processor" {
  filename      = "${path.module}/../backend/lambda_function.zip"
  function_name = "${var.project_name}-data-processor"
  role          = aws_iam_role.lambda_execution.arn
  handler       = "lambda_function.handler"
  runtime       = "python3.9"
  timeout       = 300
  memory_size   = 512
  
  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.patient_data.name
      S3_BUCKET_NAME      = aws_s3_bucket.data_storage.id
    }
  }
}
```

**Breaking it down:**
- `filename`: Path to Lambda code (must be zipped)
- `handler`: Entry point function (`file.function`)
- `runtime`: Python 3.9
- `timeout`: Max execution time (300 seconds = 5 minutes)
- `memory_size`: RAM allocated (512 MB)
- `environment.variables`: Env vars Lambda can access

**Lambda IAM Role:**
```hcl
resource "aws_iam_role" "lambda_execution" {
  name = "${var.project_name}-lambda-execution"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}
```

**What this does:**
- Creates IAM role for Lambda
- `assume_role_policy`: Who can use this role
- Lambda service can assume this role
- Necessary for Lambda to access other AWS services

**Lambda Permissions:**
```hcl
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda_execution.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.data_storage.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:BatchWriteItem"
        ]
        Resource = aws_dynamodb_table.patient_data.arn
      }
    ]
  })
}
```

**What Lambda can do:**
1. **CloudWatch Logs:**
   - Create log groups and streams
   - Write logs
   
2. **S3:**
   - Read objects (GetObject)
   - Write objects (PutObject)
   - Only in our specific bucket
   
3. **DynamoDB:**
   - Insert items (PutItem)
   - Batch insert (BatchWriteItem)
   - Only in our specific table

**Principle of Least Privilege:** Lambda only gets permissions it needs, nothing more

#### FastAPI Backend (main.py)

**API Initialization:**
```python
from fastapi import FastAPI

app = FastAPI(
    title="AIER Alert System API",
    description="API for patient monitoring",
    version="1.0.0"
)
```

**What this does:**
- Creates FastAPI application
- Sets API metadata
- Auto-generates documentation

**CORS Middleware:**
```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",  # Vue.js dev server
        "*"  # Allow all in development
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

**What this does:**
- CORS = Cross-Origin Resource Sharing
- Allows frontend (different port/domain) to call API
- Without this: Browser blocks API calls
- Security note: In production, restrict `allow_origins`

**Database Connection:**
```python
import boto3

AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
DYNAMODB_TABLE = os.getenv("DYNAMODB_TABLE_NAME", "aier-patient-data")

dynamodb = boto3.resource('dynamodb', region_name=AWS_REGION)
table = dynamodb.Table(DYNAMODB_TABLE)
```

**What this does:**
- Imports AWS SDK (boto3)
- Gets configuration from environment variables
- Creates DynamoDB connection
- Gets table reference

**Health Check Endpoint:**
```python
@app.get("/health")
async def health_check():
    try:
        # Test DynamoDB connection
        response = table.scan(Limit=1)
        
        return {
            "status": "healthy",
            "service": "api",
            "dynamodb": "connected"
        }
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"Service unhealthy: {str(e)}"
        )
```

**What this does:**
- Tests if API and database are working
- Used by monitoring systems
- Returns 200 if healthy, 503 if not

**Get Patients Endpoint:**
```python
@app.get("/api/patients")
async def get_patients(
    limit: int = Query(50, ge=1, le=100),
    risk_level: Optional[str] = None
):
    try:
        if risk_level:
            # Query using index
            response = table.query(
                IndexName='RiskLevelIndex',
                KeyConditionExpression=Key('risk_level').eq(risk_level.upper()),
                Limit=limit
            )
        else:
            # Scan all records
            response = table.scan(Limit=limit)
        
        return {
            "status": "success",
            "data": {
                "patients": response['Items'],
                "count": len(response['Items'])
            }
        }
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error: {str(e)}"
        )
```

**Breaking it down:**
- `@app.get("/api/patients")`: HTTP GET endpoint
- `async def`: Asynchronous function (non-blocking)
- `limit: int = Query(50, ge=1, le=100)`:
  - Optional query parameter
  - Default: 50
  - Minimum (ge): 1
  - Maximum (le): 100
- `risk_level: Optional[str]`: Optional filter parameter
- Returns JSON with status and data

**Usage examples:**
```
GET /api/patients
  → Returns 50 patients

GET /api/patients?limit=20
  → Returns 20 patients

GET /api/patients?risk_level=HIGH
  → Returns HIGH risk patients only

GET /api/patients?limit=10&risk_level=CRITICAL
  → Returns 10 CRITICAL risk patients
```

#### Vue.js Frontend (TypeScript)

**Type Definitions (patient.ts):**
```typescript
export interface Patient {
  patient_id: string;
  timestamp: number;
  Age: number;
  Glucose: number;
  BMI: number;
  BloodPressure: number;
  risk_level: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
  age_group: string;
  Outcome: number;
}

export interface PatientsResponse {
  status: string;
  data: {
    patients: Patient[];
    count: number;
    has_more?: boolean;
  };
  metadata?: {
    timestamp: string;
    filters?: Record<string, any>;
  };
}
```

**What this does:**
- Defines data structures
- TypeScript enforces these types
- Prevents runtime errors
- Provides IDE autocomplete

**API Client (client.ts):**
```typescript
import axios from 'axios';
import type { Patient, PatientsResponse } from '../types/patient';

const API_BASE_URL = 'http://localhost:8000';

const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

export async function getPatients(
  limit?: number,
  riskLevel?: string
): Promise<Patient[]> {
  const params: any = {};
  if (limit) params.limit = limit;
  if (riskLevel) params.risk_level = riskLevel;
  
  const response = await apiClient.get<PatientsResponse>('/api/patients', {
    params
  });
  
  return response.data.data.patients;
}
```

**Breaking it down:**
- `axios`: HTTP client library
- `apiClient.create()`: Configure default settings
- `baseURL`: API server address
- `timeout`: Cancel request after 10 seconds
- `getPatients()`: Type-safe function to fetch patients
- `Promise<Patient[]>`: Returns array of Patient objects

**Usage in Vue component:**
```typescript
<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { getPatients } from './api/client';
import type { Patient } from './types/patient';

// Reactive state
const patients = ref<Patient[]>([]);
const loading = ref(true);
const error = ref<string | null>(null);

// Load data when component mounts
onMounted(async () => {
  try {
    patients.value = await getPatients(50);
  } catch (err) {
    error.value = 'Failed to load patients';
  } finally {
    loading.value = false;
  }
});
</script>

<template>
  <div>
    <div v-if="loading">Loading...</div>
    <div v-else-if="error">{{ error }}</div>
    <div v-else>
      <div v-for="patient in patients" :key="patient.patient_id">
        {{ patient.patient_id }}: {{ patient.risk_level }}
      </div>
    </div>
  </div>
</template>
```

**Vue.js Features Used:**

1. **Reactivity (ref):**
   ```typescript
   const patients = ref<Patient[]>([]);
   // When patients.value changes, UI auto-updates
   ```

2. **Lifecycle Hooks (onMounted):**
   ```typescript
   onMounted(async () => {
     // Runs when component first displays
   });
   ```

3. **Conditional Rendering:**
   ```html
   <div v-if="loading">Loading...</div>
   <div v-else-if="error">{{ error }}</div>
   <div v-else><!-- Main content --></div>
   ```

4. **List Rendering:**
   ```html
   <div v-for="patient in patients" :key="patient.patient_id">
     <!-- Renders once for each patient -->
   </div>
   ```

---

## PART 7: DEMO PREPARATION

### Demo Checklist

**Pre-Demo Setup (Day Before):**

```markdown
Infrastructure:
□ AWS credentials configured
□ Terraform applied (infrastructure live)
□ All resources verified in AWS Console
□ Sample data loaded in DynamoDB
□ Lambda function tested
□ CloudFront distribution deployed

Backend:
□ Python dependencies installed
□ Environment variables set
□ FastAPI server tested
□ API documentation accessible (/docs)
□ Health check endpoint working

Frontend:
□ Node dependencies installed
□ Vue.js dev server working
□ API integration tested
□ Visualizations rendering correctly
□ Responsive design verified

Documentation:
□ README.md updated
□ Code comments complete
□ Architecture diagrams prepared
□ Slide deck ready
□ Demo script written

Team:
□ Everyone has AWS credentials
□ Everyone can access repository
□ Roles assigned (who presents what)
□ Backup presenter identified
□ Q&A preparation complete
```

**Demo Day Setup (1 Hour Before):**

```markdown
Terminal Windows:
□ Window 1: Backend server (uvicorn)
□ Window 2: Frontend server (npm run dev)
□ Window 3: AWS CLI commands
□ Window 4: Spare for troubleshooting

Browser Tabs:
□ Tab 1: Frontend (http://localhost:5173)
□ Tab 2: API docs (http://localhost:8000/docs)
□ Tab 3: AWS Console - S3
□ Tab 4: AWS Console - DynamoDB
□ Tab 5: AWS Console - Lambda
□ Tab 6: AWS Console - CloudFront
□ Tab 7: CloudWatch Logs
□ Tab 8: Presentation slides

Backup Plan:
□ Screenshots of working system
□ Pre-recorded video demo
□ Static HTML fallback
□ Printed documentation
```

**Demo Script (30 minutes):**

```markdown
Part 1: Introduction (3 minutes)
- Project overview
- Team introductions
- Problem statement
- Solution overview

Part 2: Architecture (5 minutes)
- System architecture diagram
- Technology stack explanation
- AWS services overview
- Data flow walkthrough

Part 3: Live Demo (15 minutes)
- Show AWS Console resources
- Run backend server
- Run frontend application
- Walk through key features:
  * Patient list display
  * Risk level filtering
  * Data visualizations (D3.js charts)
  * Real-time updates
  * Alert system
- Show API documentation
- Demonstrate API calls
- Display CloudWatch logs

Part 4: Code Walkthrough (5 minutes)
- Terraform configuration
- FastAPI endpoints
- Vue.js components
- TypeScript types

Part 5: Conclusion (2 minutes)
- Key achievements
- Technical challenges overcome
- Lessons learned
- Future enhancements
- Q&A
```

### Troubleshooting Guide

**Common Issues & Solutions:**

#### Issue: "terraform: command not found"
```bash
# Solution: Install Terraform
# Mac:
brew install terraform

# Verify:
terraform --version
```

#### Issue: "AWS credentials not configured"
```bash
# Solution: Run AWS configure
aws configure

# Or set environment variables:
export AWS_ACCESS_KEY_ID=YOUR_KEY
export AWS_SECRET_ACCESS_KEY=YOUR_SECRET
export AWS_DEFAULT_REGION=us-east-1
```

#### Issue: "Error: bucket already exists"
```bash
# Solution: Bucket names must be globally unique
# Edit terraform/variables.tf:
variable "project_name" {
  default = "aier-yourname"  # Add unique suffix
}

# Then:
terraform apply
```

#### Issue: "DynamoDB table not found"
```bash
# Check if table exists:
aws dynamodb list-tables

# Check table name in code matches Terraform:
# terraform/main.tf: resource "aws_dynamodb_table" "patient_data"
# backend/app/main.py: DYNAMODB_TABLE = "aier-patient-data"
```

#### Issue: "CORS error in browser console"
```python
# Solution: Update CORS settings in backend/app/main.py
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],  # Add your frontend URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

#### Issue: "Frontend shows empty data"
```bash
# Check:
1. Is backend running? (http://localhost:8000/health)
2. Is data in DynamoDB? (aws dynamodb scan --table-name aier-patient-data --limit 1)
3. Check browser console for errors (F12)
4. Check API endpoint URL in frontend code
```

#### Issue: "Lambda function not triggering"
```bash
# Check S3 event notification:
aws s3api get-bucket-notification-configuration \
  --bucket aier-data-development

# Verify Lambda has permission:
aws lambda get-policy --function-name aier-data-processor

# Check CloudWatch logs:
aws logs tail /aws/lambda/aier-data-processor --follow
```

#### Issue: "Port already in use"
```bash
# Backend (port 8000):
# Find process:
lsof -ti:8000

# Kill process:
kill -9 $(lsof -ti:8000)

# Frontend (port 5173):
kill -9 $(lsof -ti:5173)
```

#### Issue: "Module not found" errors
```bash
# Python (backend):
cd backend
pip3 install -r requirements.txt

# Node.js (frontend):
cd frontend
npm install
```

### Common Questions & Answers

**Q: What makes this project unique?**
A: Combination of modern cloud architecture, real healthcare data, offline capability via LLM, and strong security focus (DevSecOps). Plus TypeScript type safety and Infrastructure as Code.

**Q: How does it work offline?**
A: Local LLM model can run risk assessment algorithms without cloud connectivity. Data stored locally. Useful for remote clinics or disaster response.

**Q: Is it HIPAA compliant?**
A: Demonstrates HIPAA best practices:
- Encryption at rest (S3, DynamoDB)
- Encryption in transit (HTTPS)
- Access controls (IAM)
- Audit logging (CloudTrail)
- Data anonymization

However, full HIPAA compliance requires:
- Business Associate Agreement with AWS
- Additional security measures
- Regular audits

**Q: How much does it cost to run?**
A: Development environment: ~$5-15/month
- S3: <$1
- DynamoDB (on-demand): $1-5
- Lambda: <$1 (mostly free tier)
- CloudFront: $1-5
- Data transfer: $1-3

Production would cost more based on usage.

**Q: Can it scale?**
A: Yes! All serverless components auto-scale:
- S3: Unlimited storage
- DynamoDB: Auto-scales to millions of requests/second
- Lambda: Automatically scales to 1000 concurrent executions
- CloudFront: Global CDN handles traffic spikes

**Q: Why TypeScript instead of JavaScript?**
A: Type safety catches bugs before runtime, better IDE support, easier refactoring, self-documenting code, industry standard for large projects.

**Q: Why Vue.js instead of React?**
A: Both are excellent. Vue.js is:
- Easier learning curve
- Better documentation
- More intuitive API
- Smaller bundle size
- Progressive (can adopt incrementally)

Could easily swap for React or Angular.

**Q: What's the difference between Terraform and CloudFormation?**
A: 
- Terraform: Multi-cloud (AWS, Azure, GCP), large community, HCL language
- CloudFormation: AWS-only, deeper AWS integration, JSON/YAML

We chose Terraform for broader applicability.

**Q: How do you handle security vulnerabilities?**
A: 
- Dependency scanning (npm audit, pip-audit)
- Regular updates
- Security best practices (least privilege, encryption)
- Monitoring and alerts
- Code reviews

**Q: What would you add next?**
A: 
1. WebSocket for real-time updates
2. User authentication (Cognito)
3. More visualizations
4. Predictive analytics (ML)
5. Mobile app
6. Integration with EHR systems (HL7 FHIR)
7. Automated testing (Jest, Pytest)
8. CI/CD pipeline (GitHub Actions)

**Q: How do you ensure data privacy?**
A:
- Patient IDs anonymized
- No PII (Personally Identifiable Information)
- Encryption everywhere
- Access controls (IAM)
- Audit trails (CloudTrail)
- Private networks (VPC)

**Q: Can this be deployed to production?**
A: Mostly yes, but would need:
- Environment separation (dev/staging/prod)
- CI/CD pipeline
- Automated testing
- Monitoring and alerting (CloudWatch Alarms)
- Backup and disaster recovery
- Documentation
- Security hardening
- Performance optimization
- Cost optimization

**Q: What did you learn from this project?**
A:
- Cloud architecture design
- Infrastructure as Code
- Modern web development
- Security best practices
- Team collaboration
- Project management
- Healthcare IT domain knowledge

---

## Conclusion

This guide provides a complete walkthrough of the AIER Alert System from foundational concepts to hands-on demonstration. 

**Key Takeaways:**

1. **Software Engineering**: Modular design, documentation, SDLC
2. **Cloud Architecture**: AWS services working together
3. **Modern Web Development**: TypeScript, Vue.js, FastAPI
4. **Infrastructure as Code**: Terraform for reproducibility
5. **Security**: DevSecOps practices, IAM, encryption
6. **Healthcare IT**: HIPAA compliance, patient data management

**Remember:**

- Always review Terraform plans before applying
- Keep credentials secure (never commit to Git)
- Clean up resources when done (terraform destroy)
- Document as you build
- Test thoroughly before demo
- Have backups for demo day

**Success Criteria:**

✓ All team members understand the architecture  
✓ Everyone can run the system locally  
✓ Infrastructure deploys successfully  
✓ Data flows from source to visualization  
✓ Demo runs smoothly  
✓ Questions answered confidently  

**Next Steps:**

1. Review this guide with your team
2. Run through setup on your machine
3. Practice the demo multiple times
4. Prepare for Q&A
5. Document any issues and solutions
6. Create presentation materials
7. Schedule practice demos
8. Be ready to show your work!

**Good luck with your demo!** 🚀

---

*Last Updated: October 1, 2025*  
*Project: AIER Alert System*  
*Team: Cyber Security Fellowship Capstone*

