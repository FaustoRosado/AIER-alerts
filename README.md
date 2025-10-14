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
---

## 🚀 Quick Start Guide

### For Immediate Demonstration

If you want to see the AI/ER system in action immediately without full setup:

```bash
# 1. Clone and navigate to project
git clone https://github.com/FaustoRosado/AIER-alerts.git
cd AIER-alerts
git checkout tech-architecture

# 2. Run the demo simulation (creates all demo assets)
./scripts/mac/deploy-demo.sh

# 3. Run the interactive demo
./demo-assets/run-demo.sh

# 4. For full local development setup
./scripts/mac/setup-local.sh
./scripts/mac/run-local.sh
```

**Demo Features:**
- ✅ Simulated infrastructure deployment
- ✅ Sample log files and outputs
- ✅ Interactive demonstration script
- ✅ No real AWS resources required

### For Full Local Development

```bash
# 1. Complete environment setup
./scripts/mac/setup-local.sh

# 2. Start development server
./scripts/mac/run-local.sh start

# 3. Run integration tests
./scripts/mac/test-integration.sh run

# 4. Monitor server (in another terminal)
./scripts/mac/run-local.sh monitor
```

**Access Points:**
- 🌐 **Web Interface**: http://localhost:5000
- 🔗 **Health Check**: http://localhost:5000/health
- 📡 **API Endpoint**: http://localhost:5000/api/generate

---

## 💻 Local Development Workflow

### Complete Setup Process

#### Step 1: Environment Setup
```bash
# Run the automated setup script
./scripts/mac/setup-local.sh
```

This script will:
- ✅ Check and install dependencies (Python 3, Git, CMake, etc.)
- ✅ Create Python virtual environment
- ✅ Install required packages
- ✅ Clone and build llama.cpp
- ✅ Create necessary directories and configuration files
- ✅ Run initial tests

#### Step 2: Development Server Management
```bash
# Start the development server
./scripts/mac/run-local.sh start

# Check server status
./scripts/mac/run-local.sh status

# Monitor server in real-time
./scripts/mac/run-local.sh monitor

# Stop the server
./scripts/mac/run-local.sh stop
```

#### Step 3: Testing and Validation
```bash
# Run comprehensive integration tests
./scripts/mac/test-integration.sh run

# Check server health
./scripts/mac/run-local.sh health

# Test specific components
./scripts/mac/test-integration.sh health
```

### Development Commands Reference

| Command | Purpose | Example |
|---------|---------|---------|
| `./scripts/mac/setup-local.sh` | Complete environment setup | One-time setup |
| `./scripts/mac/run-local.sh start` | Start development server | Daily development |
| `./scripts/mac/run-local.sh status` | Check server status | Debugging |
| `./scripts/mac/test-integration.sh run` | Run all tests | Validation |
| `./scripts/mac/deploy-demo.sh` | Create demo assets | Presentations |

### Troubleshooting Common Issues

#### 1. **Python Virtual Environment Issues**
```bash
# If virtual environment fails to activate
rm -rf venv
./scripts/mac/setup-local.sh
```

#### 2. **Port Already in Use**
```bash
# Check what's using port 5000
lsof -i :5000

# Kill the process or use different port
export SERVER_PORT=5001
./scripts/mac/run-local.sh start
```

#### 3. **Model Loading Errors**
```bash
# Check if llama.cpp was built successfully
ls -la llama.cpp/build/bin/llama-cli

# Rebuild if necessary
cd llama.cpp && cmake --build build --config Release
```

#### 4. **Permission Errors**
```bash
# Fix script permissions
chmod +x scripts/mac/*.sh

# Fix directory permissions
sudo chown -R $(whoami) .
```

---

## 🔧 Infrastructure Deployment

### Automated Deployment with Terraform

#### Prerequisites for AWS Deployment
```bash
# 1. Install AWS CLI and configure credentials
brew install awscli
aws configure

# 2. Install Terraform
brew install terraform

# 3. Set up SSH key for EC2 access
ssh-keygen -t rsa -b 4096 -f ~/.ssh/aier-capstone-key
aws ec2 import-key-pair --key-name "aier-capstone-key" --public-key-material fileb://~/.ssh/aier-capstone-key.pub
```

#### Deployment Commands
```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Deploy infrastructure (requires approval)
terraform apply

# Check deployment status
terraform show

# View outputs
terraform output
```

#### Post-Deployment Access
```bash
# Get bastion host IP
BASTION_IP=$(terraform output -raw bastion_public_ip)

# Connect to LLM server through bastion
ssh -A -J ec2-user@$BASTION_IP ec2-user@10.0.101.100

# Check server status on remote machine
curl http://localhost:5000/health
```

### Cost Management

**Estimated Monthly Costs:**
- **t3.medium (LLM Server)**: ~$30/month
- **t3.micro (Bastion Host)**: ~$8/month
- **NAT Gateway**: ~$32/month (first GB free)
- **VPC Flow Logs**: ~$5/month

**Cost Optimization Tips:**
- Use `t3.micro` for bastion host (minimal resource needs)
- Implement auto-scaling for production workloads
- Use spot instances for development environments
- Set up billing alerts in AWS Cost Explorer

### Monitoring and Alerting

#### CloudWatch Setup
```bash
# Create log group for application logs
aws logs create-log-group --log-group-name /aws/llm-server/aier-capstone

# Set up metric filters for security events
aws logs put-metric-filter \
  --log-group-name /aws/llm-server/aier-capstone \
  --filter-name SecurityEvents \
  --filter-pattern "ERROR || WARN" \
  --metric-transformations metricName=SecurityEvents,metricNamespace=AIER,metricValue=1
```

#### Alert Configuration
```bash
# CPU utilization alarm
aws cloudwatch put-metric-alarm \
  --alarm-name "LLM-Server-High-CPU" \
  --alarm-description "LLM Server CPU utilization is too high" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=InstanceId,Value=i-1234567890abcdef0
```

---

## 🎯 Demonstration Guide

### For Instructors and Reviewers

#### Quick Demo (5 minutes)
```bash
# 1. Run demo simulation
./scripts/mac/deploy-demo.sh

# 2. Show demo assets
ls -la demo-assets/

# 3. Run interactive demo
./demo-assets/run-demo.sh
```

#### Technical Deep Dive (15 minutes)
```bash
# 1. Show project structure
tree -a

# 2. Demonstrate local setup
./scripts/mac/setup-local.sh

# 3. Run integration tests
./scripts/mac/test-integration.sh run

# 4. Show terraform configuration
cd terraform && terraform plan

# 5. Demonstrate security features
grep -r "security" src/ | head -10
```

#### Architecture Walkthrough (20 minutes)
1. **Network Architecture**: Explain VPC design and security groups
2. **Application Architecture**: Show Flask server and llama.cpp integration
3. **CI/CD Pipeline**: Demonstrate GitHub Actions workflow
4. **Security Implementation**: Highlight defense in depth strategy

### Demo Checklist for Presentations

- [ ] **Environment Setup**: `./scripts/mac/setup-local.sh` runs successfully
- [ ] **Server Startup**: `./scripts/mac/run-local.sh start` works
- [ ] **Integration Tests**: `./scripts/mac/test-integration.sh run` passes
- [ ] **Web Interface**: http://localhost:5000 loads correctly
- [ ] **API Functionality**: POST requests to `/api/generate` work
- [ ] **Security Features**: Input validation and logging demonstrated
- [ ] **Infrastructure Simulation**: `./scripts/mac/deploy-demo.sh` creates assets
- [ ] **Documentation**: README.md and guides are comprehensive

### Common Demo Scenarios

#### Scenario 1: Local Development
```bash
# Show local development workflow
./scripts/mac/run-local.sh start
# Open browser to http://localhost:5000
# Demonstrate real-time interaction
./scripts/mac/test-integration.sh run
```

#### Scenario 2: Infrastructure Deployment
```bash
# Show terraform deployment simulation
cd terraform
terraform plan  # Show planned infrastructure
./scripts/mac/deploy-demo.sh  # Create demo evidence
```

#### Scenario 3: Security Demonstration
```bash
# Show security features
grep -A 10 -B 5 "validate_prompt" src/llm_server/app.py
# Demonstrate input validation
curl -X POST http://localhost:5000/api/generate -H "Content-Type: application/json" -d '{"prompt": ""}'
```

---

## 🧪 Testing Strategy

### Test Categories

#### 1. **Unit Tests**
```bash
# Test individual components
python3 -m pytest src/tests/ -v
```

#### 2. **Integration Tests**
```bash
# Test complete system integration
./scripts/mac/test-integration.sh run
```

#### 3. **Security Tests**
```bash
# Test security controls
./scripts/mac/test-integration.sh security
```

#### 4. **Performance Tests**
```bash
# Test system performance
./scripts/mac/test-integration.sh performance
```

### Automated Testing Pipeline

The project includes automated testing through:

1. **GitHub Actions**: CI/CD pipeline with automated validation
2. **Local Scripts**: Comprehensive test suite for development
3. **Integration Tests**: End-to-end system validation
4. **Security Scanning**: Automated vulnerability detection

### Test Results and Reporting

All tests generate detailed reports in the `logs/` directory:

- `test-results.log`: Comprehensive test execution logs
- `coverage-report.html`: Code coverage analysis
- `security-scan-results.json`: Security vulnerability reports
- `performance-metrics.json`: System performance data

---

## 🔒 Security Testing

### Automated Security Validation

#### Input Validation Testing
```bash
# Test various input scenarios
./scripts/mac/test-integration.sh input-validation

# Results show:
# ✅ Empty prompts rejected
# ✅ Malicious input filtered
# ✅ XSS attempts blocked
# ✅ SQL injection prevented
```

#### Authentication Testing
```bash
# Test access controls
./scripts/mac/test-integration.sh auth

# Results show:
# ✅ API endpoints protected
# ✅ Unauthorized access blocked
# ✅ Session management secure
```

#### Network Security Testing
```bash
# Test network isolation
./scripts/mac/test-integration.sh network

# Results show:
# ✅ Private subnets isolated
# ✅ Security groups restrictive
# ✅ Flow logs capturing traffic
```

### Manual Security Testing

#### Penetration Testing Checklist
- [ ] **Network Scanning**: Nmap scans for open ports
- [ ] **Vulnerability Assessment**: Nessus/OpenVAS scans
- [ ] **Web Application Testing**: OWASP ZAP testing
- [ ] **API Security Testing**: Postman security tests
- [ ] **Authentication Testing**: Brute force simulation

#### Security Headers Validation
```bash
# Check security headers
curl -I http://localhost:5000/

# Expected headers:
# X-Content-Type-Options: nosniff
# X-Frame-Options: DENY
# X-XSS-Protection: 1; mode=block
```

---

## 📊 Monitoring and Observability

### Local Development Monitoring

#### Real-time Server Monitoring
```bash
# Monitor server in real-time
./scripts/mac/run-local.sh monitor

# Shows:
# • Request count and errors
# • Response times
# • System resource usage
# • Error rates
```

#### Log Analysis
```bash
# View recent server logs
tail -f logs/llm_server.log

# Search for security events
grep "ERROR\|WARN" logs/llm_server.log

# Analyze API usage patterns
grep "API request processed" logs/llm_server.log | wc -l
```

### Infrastructure Monitoring

#### AWS CloudWatch Integration
```bash
# Check CloudWatch metrics
aws cloudwatch list-metrics --namespace AWS/EC2

# View custom application metrics
aws cloudwatch get-metric-statistics \
  --metric-name RequestCount \
  --namespace AIER/Application \
  --start-time $(date -d '1 hour ago' +%s) \
  --end-time $(date +%s) \
  --period 300 \
  --statistics Sum
```

#### Log Aggregation
```bash
# View VPC Flow Logs
aws logs tail /aws/vpc/flowlogs/aier-capstone --follow

# Check application logs
aws logs tail /aws/llm-server/aier-capstone --follow
```

### Alert Configuration

#### Critical Alerts Setup
```bash
# High CPU usage alert
aws cloudwatch put-metric-alarm \
  --alarm-name "LLM-Server-High-CPU" \
  --alarm-description "LLM Server CPU utilization is too high" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --alarm-actions arn:aws:sns:us-east-1:123456789012:aier-alerts
```

---

## 🚨 Troubleshooting Guide

### Common Issues and Solutions

#### 1. **Server Won't Start**
```bash
# Check if port 5000 is in use
lsof -i :5000

# Check Python environment
python3 -c "import flask; print('Flask version:', flask.__version__)"

# Check log file for errors
tail -20 logs/llm_server.log
```

#### 2. **Model Loading Errors**
```bash
# Verify llama.cpp build
ls -la llama.cpp/build/bin/llama-cli

# Check model file exists
ls -la models/

# Rebuild llama.cpp if needed
cd llama.cpp && cmake --build build --config Release
```

#### 3. **Permission Errors**
```bash
# Fix script permissions
chmod +x scripts/mac/*.sh

# Fix directory permissions
sudo chown -R $(whoami) .

# Check if running as correct user
whoami && id
```

#### 4. **Network Connectivity Issues**
```bash
# Test local connectivity
curl http://localhost:5000/health

# Check firewall settings
sudo ufw status

# Test DNS resolution
nslookup localhost
```

#### 5. **Memory Issues**
```bash
# Check system memory
free -h

# Monitor process memory usage
ps aux | grep python

# Adjust model parameters for lower memory usage
# Edit model configuration to use smaller context window
```

### Debug Mode

#### Enable Debug Logging
```bash
# Set debug level in environment
export LOG_LEVEL=DEBUG

# Or modify .env file
echo "LOG_LEVEL=DEBUG" >> .env

# Restart server to apply changes
./scripts/mac/run-local.sh restart
```

#### Remote Debugging
```bash
# Enable remote debugging (if needed)
export FLASK_DEBUG=1
export FLASK_ENV=development

# Start server with debug features
./scripts/mac/run-local.sh start
```

### Performance Issues

#### Memory Optimization
```bash
# Monitor memory usage
htop

# Check for memory leaks
valgrind --leak-check=full python3 src/llm_server/app.py

# Optimize model parameters
# Reduce context window size
# Use quantization for smaller models
```

#### CPU Optimization
```bash
# Monitor CPU usage
top -p $(pgrep -f "python3 src/llm_server/app.py")

# Use multiple workers for production
# Configure gunicorn or similar WSGI server
```

---

## 📋 Deployment Checklist

### Pre-Deployment
- [ ] **Environment Setup**: All dependencies installed
- [ ] **Configuration**: `.env` file properly configured
- [ ] **Testing**: All integration tests pass
- [ ] **Security**: Input validation and logging verified
- [ ] **Documentation**: README and guides updated

### Infrastructure Deployment
- [ ] **AWS Credentials**: Configured and tested
- [ ] **SSH Keys**: Generated and imported to AWS
- [ ] **Terraform**: Initialized and validated
- [ ] **Network**: VPC and subnets configured
- [ ] **Security Groups**: Properly restrictive

### Post-Deployment
- [ ] **Connectivity**: Bastion and LLM server accessible
- [ ] **Application**: Web interface and API functional
- [ ] **Monitoring**: Logs and metrics collecting
- [ ] **Security**: Access controls verified
- [ ] **Performance**: Response times acceptable

### Rollback Plan
- [ ] **Terraform State**: Backed up before deployment
- [ ] **Database Backups**: Application data preserved
- [ ] **Rollback Script**: Ready for quick reversion
- [ ] **Communication**: Team notified of rollback procedures

---

## 🎓 Educational Resources

### For Cybersecurity Students

#### Key Learning Objectives
1. **Infrastructure as Code**: Master Terraform for secure deployments
2. **DevSecOps Practices**: Implement security in CI/CD pipelines
3. **Local AI Security**: Understand privacy and security implications
4. **Network Security**: Design secure multi-tier architectures
5. **Access Management**: Implement least privilege and zero trust

#### Hands-on Exercises
1. **Modify Infrastructure**: Change VPC configuration and redeploy
2. **Security Hardening**: Add additional security controls
3. **Performance Tuning**: Optimize model parameters and server settings
4. **Monitoring Setup**: Configure comprehensive observability
5. **Incident Response**: Practice security incident handling

#### Further Reading
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/best-practices/index.html)
- [DevSecOps Handbook](https://www.gitlab.com/handbook/engineering/security/dev-sec-ops/)
- [Cybersecurity for AI Systems](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-213.pdf)

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
