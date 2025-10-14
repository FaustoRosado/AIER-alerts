# AI/ER Capstone Project - Sprint 2: Technical Architecture & Local LLM Implementation

## Team: AI/ER (pronounced "Air")
**Cybersecurity Capstone Project - Local LLM Emergency Response System**

---

## 🎯 Project Overview

**AI/ER** is a cybersecurity capstone project that demonstrates practical implementation of secure, local Large Language Model (LLM) deployment for emergency response scenarios. This project showcases real-world application of cybersecurity principles, Infrastructure as Code (IaC), and DevSecOps practices.

**Core Concept**: A secure, privacy-focused emergency response system using local LLMs that can operate offline and maintain data sovereignty while providing intelligent decision support.

---

## 📚 Educational Objectives for Cybersecurity Students

This project serves as a comprehensive learning platform covering:

### 🔒 Security Fundamentals
- **Data Privacy & Sovereignty**: Local LLM deployment ensures sensitive emergency data never leaves your infrastructure
- **Zero-Trust Architecture**: Every component is secured and verified
- **Defense in Depth**: Multiple security layers from network to application level

### 🏗️ Infrastructure & DevSecOps
- **Infrastructure as Code (IaC)**: Learn Terraform for repeatable, auditable infrastructure
- **CI/CD Pipelines**: Automated testing and deployment with GitHub Actions
- **Version Control**: Git workflows for collaborative development

### 🤖 AI/ML Security
- **Local Model Deployment**: Understanding the security implications of running models locally
- **Model Security**: Protecting against model poisoning and adversarial attacks
- **Privacy-Preserving AI**: Ensuring no data leakage in AI systems

---

## 🏃‍♂️ Sprint 2 Focus: Technical Architecture & Local LLM

**Sprint Goal**: Provision the foundational, version-controlled AWS CI/CD backbone using Terraform, establishing the automated pathway for code to travel from source control to an artifact repository.

**Corresponding Capstone Objective**: Provision Core CI/CD Infrastructure via IaC.

### Key Deliverables

1. **Version-Controlled Terraform Configuration**
2. **IAM Policy and Role Definitions (as Code)**
3. **Initial buildspec.yml for CI Pipeline**
4. **Local Llama.cpp Integration**
5. **HTML Front-End Interface**

---

## 🏛️ Technical Architecture

### Infrastructure Components

```
┌─────────────────────────────────────────────────────────────────┐
│                        AI/ER System                             │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │   Local     │  │   HTML      │  │  Llama.cpp  │              │
│  │   LLM       │  │  Front-End  │  │   Engine    │              │
│  │  Server     │  │  Interface  │  │             │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │  Terraform  │  │  GitHub     │  │     AWS     │              │
│  │     IaC     │  │  Actions    │  │  Resources  │              │
│  │             │  │   CI/CD     │  │             │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
└─────────────────────────────────────────────────────────────────┘
```

### Technology Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Language Model** | llama.cpp | Local LLM inference engine |
| **Infrastructure** | Terraform | Infrastructure as Code |
| **CI/CD** | GitHub Actions | Automated pipelines |
| **Cloud** | AWS | Secure hosting environment |
| **Frontend** | HTML/CSS/JavaScript | User interface |
| **Version Control** | Git | Code collaboration |

---

## 🔧 Local LLM Setup with llama.cpp

### What is llama.cpp?

**llama.cpp** is a C++ implementation for running Large Language Models locally on consumer hardware. Unlike cloud-based APIs, llama.cpp allows you to:

- Run models completely offline
- Maintain full control over your data
- Avoid API costs and rate limits
- Ensure privacy and security

### For Cybersecurity Students: Why Local LLMs Matter

1. **Data Sovereignty**: Emergency response data stays within your secured environment
2. **Offline Capability**: System works even during network outages
3. **No Vendor Lock-in**: You control the model and data
4. **Audit Trail**: Complete visibility into model behavior
5. **Cost Control**: No per-token API costs

### Prerequisites

Before setting up llama.cpp, ensure you have:

```bash
# Required tools
git --version          # Git for version control
cmake --version        # Build system
make --version         # Build tool

# Recommended hardware
# - 8GB+ RAM for 7B models
# - 16GB+ RAM for 13B models
# - 30GB+ RAM for 70B models
# - Modern CPU with AVX2 support (most post-2013 CPUs)
```

### Step-by-Step Installation Guide

#### 1. Clone and Build llama.cpp

```bash
# Navigate to your project directory
cd /Volumes/AI_Projects/tech-arch

# Clone the llama.cpp repository
git clone https://github.com/ggerganov/llama.cpp.git

# Navigate to llama.cpp directory
cd llama.cpp

# Build the project (this may take several minutes)
cmake -B build
cmake --build build --config Release
```

#### 2. Download a Model

For this project, we'll use a small, instruction-tuned model suitable for emergency response scenarios:

```bash
# Create models directory
mkdir -p ../models

# Download a 7B parameter model (requires ~4GB disk space)
# Note: This is a placeholder - actual download would be from HuggingFace
curl -L -o ../models/llama-7b-q4_0.gguf \
  https://huggingface.co/TheBloke/Llama-2-7B-GGUF/resolve/main/llama-2-7b.Q4_0.gguf
```

#### 3. Test the Model

```bash
# Basic functionality test
./build/bin/llama-cli \
  -m ../models/llama-7b-q4_0.gguf \
  -p "Explain how local LLMs improve cybersecurity in emergency response systems" \
  -n 200
```

### Model Configuration for Emergency Response

Create a model configuration file for consistent behavior:

```json
// models/config.json
{
  "model_path": "llama-7b-q4_0.gguf",
  "prompt_template": "You are an AI emergency response assistant. Provide clear, accurate information for emergency situations. Context: {context}\n\nQuestion: {question}\n\nAnswer:",
  "max_tokens": 150,
  "temperature": 0.1,
  "top_p": 0.9,
  "repeat_penalty": 1.1,
  "security_filtering": true
}
```

---

## 🏗️ Infrastructure as Code (IaC) with Terraform

### Understanding Infrastructure as Code

**Infrastructure as Code (IaC)** is the practice of managing and provisioning computing infrastructure through machine-readable definition files, rather than physical hardware configuration or interactive configuration tools.

**Why IaC for Cybersecurity?**
- **Auditability**: Every change is tracked in version control
- **Reproducibility**: Environments can be recreated exactly
- **Compliance**: Automated security policy enforcement
- **Disaster Recovery**: Infrastructure can be rebuilt from code

### AWS Architecture Overview

Our Terraform configuration creates a secure, two-tier network architecture:

```
Internet Gateway
       │
       ▼
Public Subnet (Web Tier)
  ┌─────────────────────────────────┐
  │     NAT Gateway                 │
  └─────────────────────────────────┘
       │
       ▼
Private Subnet (Application Tier)
  ┌─────────────────────────────────┐
  │     Local LLM Server            │
  │     Emergency Database          │
  └─────────────────────────────────┘
```

### Core Terraform Files Explained

#### 1. **variables.tf** - Configuration Variables

```hcl
variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "sandbox"
}
```

**For Beginners**: Variables make your infrastructure flexible and reusable across different environments (dev, staging, production).

#### 2. **network-core.tf** - Network Infrastructure

```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.environment}-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-public-subnet"
  }
}
```

**Security Lesson**: Notice how we use `map_public_ip_on_launch = true` only for public subnets, keeping private subnets isolated.

#### 3. **routing.tf** - Network Routing

```hcl
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
```

#### 4. **versions.tf** - Provider Management

```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

**Version Pinning**: This prevents unexpected changes when providers update, ensuring consistent deployments.

#### 5. **outputs.tf** - Infrastructure Outputs

```hcl
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}
```

---

## 🚀 CI/CD Pipeline with GitHub Actions

### Pipeline Architecture

Our GitHub Actions pipeline follows a **GitOps** workflow:

```
Code Commit → Pull Request → Automated Validation → Manual Approval → Merge → Automated Deployment
```

### Pipeline Stages Explained

#### 1. **Source Stage**
- **Trigger**: Pull Request against main branch
- **Security**: Branch protection rules prevent direct pushes

#### 2. **Build Stage**
```yaml
- name: Terraform Format Check
  run: terraform fmt --check

- name: Terraform Validate
  run: terraform validate
```

#### 3. **Test Stage**
```yaml
- name: Terraform Plan
  run: terraform plan -no-color
  continue-on-error: true
```

#### 4. **Deploy Stage**
```yaml
- name: Terraform Apply
  run: terraform apply -auto-approve
  if: github.ref == 'refs/heads/main'
```

### Security Gates

The pipeline implements multiple security controls:

1. **Required Status Checks**: All automated tests must pass
2. **Manual Approval**: Senior team member review required
3. **Secret Scanning**: GitHub automatically detects credentials
4. **Branch Protection**: Main branch cannot be deleted or force-pushed

---

## 🔒 Security Considerations

### Principle of Least Privilege

Every AWS resource follows the principle of least privilege:

```hcl
resource "aws_iam_role" "llm_server" {
  name = "llm-server-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}
```

### Network Security

- **VPC Isolation**: Models run in private subnets
- **Security Groups**: Restrictive inbound/outbound rules
- **No Public IPs**: Private resources are never directly accessible

### Data Protection

- **Encryption at Rest**: All storage encrypted
- **Encryption in Transit**: TLS for all communications
- **Access Logging**: Comprehensive audit trails

---

## 🛠️ Local Development Setup

### 1. Environment Setup

```bash
# Clone the repository
git clone https://github.com/FaustoRosado/AIER-alerts.git
cd AIER-alerts

# Create Python virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Model Configuration

```python
# config/model_config.py
MODEL_CONFIG = {
    "model_path": "models/llama-7b-q4_0.gguf",
    "context_window": 2048,
    "max_tokens": 150,
    "temperature": 0.1,
    "security_mode": True
}
```

### 3. Emergency Response Prompts

```python
EMERGENCY_PROMPTS = {
    "heart_rate": "Analyze heart rate data and provide emergency response recommendations...",
    "security_incident": "Assess security incident and recommend immediate actions...",
    "system_failure": "Diagnose system failure and provide recovery steps..."
}
```

---

## 📋 Replication Guide

### For Other Teams

1. **Clone and Setup**
   ```bash
   git clone <repository-url>
   cd AIER-alerts
   git checkout tech-architecture
   ```

2. **Install Dependencies**
   ```bash
   # Terraform
   brew install terraform  # macOS

   # llama.cpp
   cd llama.cpp && cmake -B build && cmake --build build --config Release
   ```

3. **Configure Environment**
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```

4. **Deploy Infrastructure**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

### Demo Checklist

- [ ] Local LLM responds to emergency prompts
- [ ] Terraform infrastructure deploys successfully
- [ ] CI/CD pipeline runs without errors
- [ ] Security controls are properly configured
- [ ] Documentation is complete and accurate

---

## 📚 Learning Outcomes

By completing this sprint, students will understand:

1. **Infrastructure as Code**: How to provision secure, scalable infrastructure
2. **Local AI Deployment**: Privacy and security benefits of local models
3. **DevSecOps Practices**: Automated security in development workflows
4. **Version Control**: Collaborative development with Git
5. **Cloud Security**: AWS security best practices

---

## 🔗 Resources

- [llama.cpp Documentation](https://github.com/ggerganov/llama.cpp)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

---

## 📞 Support

For questions about this implementation, please refer to:
- Project documentation in `/docs`
- Team member contributions in `/team`
- Security guidelines in `/security`

**Remember**: This is a learning environment. Focus on understanding the "why" behind each security decision, not just the implementation details.
