# ZERO-TRUST HYBRID AI PIPELINE
# Master Build Guide

Project Lead: Sheniese Aracena-Baez (Shay)
Infrastructure: Shifty
Integration: Javier Acosta

This document contains everything needed to build, deploy, and demonstrate the Zero-Trust Hybrid AI Pipeline. It is organized in execution order with explicit machine assignments for every step.

---

## TABLE OF CONTENTS

1. Project Overview (For Teaching Javier and Shay)
2. Machine Reference
3. Phase 1: Local Infrastructure Setup (Automated via Claude Code)
4. Phase 2: Verification and Testing
5. Phase 3: AWS Cloud Configuration (Manual with Documentation)
6. Phase 4: Demo Preparation
7. Phase 5: Live Demonstration Script
8. Appendix: Troubleshooting

---

# SECTION 1: PROJECT OVERVIEW
# For Teaching Javier and Shay

This section explains the architecture so Javier and Shay can understand and present the system confidently.

## What We Built

We built a hybrid AI system that processes sensitive data locally while using cloud services for security automation. The key innovation is that patient data, credentials, and other sensitive information never leave your local machines. The cloud only handles code scanning, container building, and deployment automation.

## Why This Matters for Healthcare

HIPAA requires that Protected Health Information (PHI) be secured. Most AI services like ChatGPT or Claude API send your data to remote servers. Our system keeps PHI on local hardware while still benefiting from AI capabilities.

## The Three-Tier Routing System (Shay's Design)

Shay designed a classification system that examines every query before processing:

Tier 1 (High Risk - Local Only):
This tier catches anything that could identify a patient or expose credentials. Social Security numbers, patient names, medical record numbers, diagnoses, medications, credit cards, API keys, passwords. If the system detects any of these, the query stays on local hardware. It never touches the internet.

Tier 2 (Medium Risk - Anonymize First):
This tier handles operational data like IP addresses, device IDs, employee IDs. The system replaces these with placeholder values before allowing cloud processing. The cloud sees "192.168.xxx.xxx" instead of the real IP.

Tier 3 (Safe - Cloud Allowed):
General questions with no sensitive data can go to cloud AI services if local systems are busy or unavailable. Questions like "explain TCP handshake" or "write a Python function to sort a list" contain nothing sensitive.

## The Hardware Setup

We have five machines connected through Tailscale, which creates a private mesh network that works even when machines are on different physical networks.

NEXUS (Mac Mini M4 Pro with 48GB RAM):
This is the command center. It runs the orchestrator service that receives all AI requests, analyzes them for sensitivity, and routes them to the appropriate backend. Think of it as the traffic controller. Port 8000.

AEGIS (Desktop with Ryzen 9950X CPU and RTX 4080 Super GPU):
This is the primary inference node. It runs llama.cpp, which is an optimized runtime for running large language models. The RTX 4080 Super has fast GDDR6X memory (736 GB/s bandwidth) which makes it ideal for AI inference. We run a Llama 3.1 8B model here. Port 8080.

RYZEN-AI (Framework laptop with Ryzen AI 395 and 128GB RAM):
This is the multi-model specialist. It runs Ollama, which can host multiple AI models simultaneously. With 128GB RAM, we can keep several models loaded and switch between them instantly. We use this for specialized tasks like code generation (Qwen Coder), embeddings (BGE-M3), and validation (Phi-3). Port 11434.

KALI-NEXUS (Kali Linux VM):
This runs security scanning tools. During the demo, we use it to show real-time security monitoring and log aggregation. Port 8080.

PHANTOM (Dell XPS with Snapdragon and 64GB RAM):
This is the backup command center. If Nexus goes down, Phantom can take over orchestration. It has SSH access to all other machines.

## How Data Flows

When a user sends a request:

Step 1: The request arrives at the orchestrator on Nexus.

Step 2: The orchestrator passes the text through Presidio (Microsoft's PII detection library) and our custom keyword matching.

Step 3: Based on what it finds, the orchestrator assigns a tier (1, 2, or 3).

Step 4: If Tier 1, the request goes to Aegis or Ryzen-AI (local only). If Tier 2, sensitive parts get anonymized first. If Tier 3, the request can go anywhere.

Step 5: The AI model processes the request and returns a response.

Step 6: The orchestrator logs the transaction (with anonymized text only) and returns the response to the user.

## The Cloud Component

The cloud plane handles DevSecOps only. It never sees patient data. Here is what runs in AWS:

S3: Stores pipeline artifacts and anonymized audit logs.
ECR: Stores container images for the orchestrator.
CodePipeline/CodeBuild: Automates building and testing (or GitHub Actions as a free alternative).
Lambda: Runs serverless functions for webhooks and notifications.
API Gateway: Provides HTTPS endpoints for external integrations.

The key principle: code and configuration replicate to the cloud. Patient data never does.

## Security Scanning

Every code commit triggers automated scanning:

Secret Scanning: Catches accidentally committed API keys or passwords.
SAST (Static Application Security Testing): Finds vulnerabilities in source code.
SCA (Software Composition Analysis): Checks dependencies for known vulnerabilities.
IaC Scanning: Validates Terraform configurations for security misconfigurations.
Container Scanning: Scans Docker images before deployment.

These scans run in CodeBuild and report findings to Security Hub.

---

# SECTION 2: MACHINE REFERENCE

Keep this table handy during setup and demonstration.

| Machine | Hostname | SSH User | Home Folder | Role | Port |
|---------|----------|----------|-------------|------|------|
| Mac Mini | nexus | nexus | /Users/nexus | Orchestrator | 8000 |
| RTX Desktop | aegis | aegis | C:\Users\YOUR_WIN_USER | llama.cpp Inference | 8080 |
| 128GB Laptop | ryzen-ai | YOUR_SSH_USER | C:\Users\YOUR_WIN_USER | Ollama Multi-Model | 11434 |
| Kali VM | kali-nexus | kali-nexus | /home/kali-nexus | Security Tools | 8080 |
| Dell XPS | phantom | YOUR_SSH_USER | C:\Users\YOUR_WIN_USER | Backup Command | - |

SSH Config (already configured on NEXUS and PHANTOM):

```
Host aegis
    HostName aegis
    User aegis

Host ryzen-ai
    HostName ryzen-ai
    User YOUR_SSH_USER

Host kali-nexus
    HostName kali-nexus
    User kali-nexus

Host phantom
    HostName phantom
    User YOUR_SSH_USER

Host nexus
    HostName nexus
    User nexus
```

---

# SECTION 3: PHASE 1 - LOCAL INFRASTRUCTURE SETUP
# Automated via Claude Code Desktop

This phase deploys the local AI infrastructure. Claude Code Desktop on Nexus will SSH into each machine and run setup scripts. You can start this and let it run while you sleep.

## Pre-Flight Checklist

Before starting automation, verify from NEXUS:

```bash
# Test SSH to all machines (should not ask for password)
ssh aegis "echo AEGIS OK"
ssh ryzen-ai "echo RYZEN-AI OK"
ssh kali-nexus "echo KALI-NEXUS OK"
ssh phantom "echo PHANTOM OK"

# Test Tailscale connectivity
ping -c 1 aegis
ping -c 1 ryzen-ai
ping -c 1 kali-nexus
ping -c 1 phantom
```

All four should respond without password prompts.

## Claude Code Desktop Setup

Computer: NEXUS

Open Claude Code Desktop and point it to the project directory:

```
~/Projects/zero-trust-hybrid-ai
```

## Prompt 1: Load Project Context

Copy and paste this into Claude Code Desktop:

```
Read the file PROJECT_CONTEXT.md and commit it to memory.

This is the Zero-Trust Hybrid AI Pipeline project.

Key facts you must remember:
- Project lead is Shay (Sheniese Aracena-Baez)
- Aegis runs llama.cpp on port 8080 (NOT Ollama)
- Ryzen-AI runs Ollama on port 11434
- Kali-Nexus runs security tools on port 8080
- All machines connected via Tailscale mesh VPN
- SSH is already configured and working
- Sensitive data (PHI) must NEVER leave local infrastructure

Machine SSH details:
- aegis: user aegis, home folder C:\Users\YOUR_WIN_USER
- ryzen-ai: user YOUR_SSH_USER, home folder C:\Users\YOUR_WIN_USER
- kali-nexus: user kali-nexus, home folder /home/kali-nexus
- phantom: user YOUR_SSH_USER, home folder C:\Users\YOUR_WIN_USER

Confirm you have loaded this context.
```

Wait for confirmation before proceeding.

## Prompt 2: Deploy Inference Nodes

Copy and paste this into Claude Code Desktop:

```
Deploy the inference node setup scripts to all machines in parallel. SSH is already configured and working.

Execute these tasks. Do not ask questions. Make reasonable decisions and proceed. Report progress as you go.

TASK 1 - AEGIS (llama.cpp with RTX 4080 Super):
Run these commands from this machine (nexus):
scp inference-nodes/aegis/setup-aegis.ps1 aegis:C:/Users/YOUR_WIN_USER/
ssh aegis "powershell -ExecutionPolicy Bypass -File C:/Users/YOUR_WIN_USER/setup-aegis.ps1"

This will download llama.cpp and the Llama 3.1 8B model (approximately 5GB). It takes 20-30 minutes.

When complete, verify with:
curl http://aegis:8080/health

TASK 2 - RYZEN-AI (Ollama multi-model):
Run these commands from this machine (nexus):
scp inference-nodes/ryzen-ai/setup-ryzen-ai.ps1 ryzen-ai:C:/Users/YOUR_WIN_USER/
ssh ryzen-ai "powershell -ExecutionPolicy Bypass -File C:/Users/YOUR_WIN_USER/setup-ryzen-ai.ps1"

This will install Ollama and download multiple models (approximately 20GB total). It takes 30-45 minutes.

When complete, verify with:
curl http://ryzen-ai:11434/api/tags

TASK 3 - KALI-NEXUS (Security tools):
Run these commands from this machine (nexus):
scp setup-scripts/setup-kali-nexus.sh kali-nexus:~/
ssh kali-nexus "chmod +x ~/setup-kali-nexus.sh && sudo ~/setup-kali-nexus.sh"

When complete, verify with:
curl http://kali-nexus:8080/health

Run all three tasks. Report when each completes and show the verification output.
```

This prompt runs the heavy lifting. Model downloads are the slow part. Let it run.

## Prompt 3: Set Up Local Orchestrator

After the inference nodes are deployed (or in parallel in a new terminal), paste this:

```
Set up the orchestrator service on this machine (nexus).

Run these commands:
cd ~/Projects/zero-trust-hybrid-ai/orchestrator
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python -m spacy download en_core_web_lg

The spacy model download takes a few minutes.

When complete, start the orchestrator:
python main.py

Keep it running. This is the central service that routes all AI requests.

Verify it works:
curl http://localhost:8000/health
curl http://localhost:8000/backends
```

## Prompt 4: Full Infrastructure Verification

After all services are running, paste this:

```
Verify the complete infrastructure is working. Run these tests and report results.

TEST 1 - Orchestrator Health:
curl http://localhost:8000/health

Expected: {"status":"healthy"}

TEST 2 - Backend Status:
curl http://localhost:8000/backends

Expected: JSON showing aegis, ryzen-ai with status "online"

TEST 3 - Aegis Direct:
curl http://aegis:8080/health

Expected: {"status":"ok"}

TEST 4 - Ryzen-AI Direct:
curl http://ryzen-ai:11434/api/tags

Expected: JSON listing available models

TEST 5 - Sensitivity Analysis (Tier 1 - should route LOCAL):
curl -X POST http://localhost:8000/analyze \
  -H "Content-Type: application/json" \
  -d '{"text": "Patient John Smith, SSN 123-45-6789, diagnosed with diabetes"}'

Expected: route = "local", tier = 1, hipaa_relevant = true

TEST 6 - Sensitivity Analysis (Tier 2 - should anonymize):
curl -X POST http://localhost:8000/analyze \
  -H "Content-Type: application/json" \
  -d '{"text": "Server at 192.168.1.100 needs restart"}'

Expected: route = "local" or "anonymize", tier = 2

TEST 7 - Sensitivity Analysis (Tier 3 - cloud allowed):
curl -X POST http://localhost:8000/analyze \
  -H "Content-Type: application/json" \
  -d '{"text": "Explain how TCP handshakes work"}'

Expected: route = "any", tier = 3

Report all results with pass/fail status.
```

---

# SECTION 4: PHASE 2 - VERIFICATION AND TESTING

This phase confirms everything works before the demo. Run these from NEXUS after Phase 1 completes.

## Manual Verification Commands

Computer: NEXUS

Run each command and verify the output:

```bash
# Check orchestrator
curl -s http://localhost:8000/health | jq .

# List all backends with status
curl -s http://localhost:8000/backends | jq .

# Test Aegis directly
curl -s http://aegis:8080/health

# Test Ryzen-AI directly
curl -s http://ryzen-ai:11434/api/tags | jq .

# Test a simple inference on Aegis
curl -X POST http://aegis:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{"role": "user", "content": "Say hello in one word"}],
    "max_tokens": 10
  }' | jq .

# Test routing through orchestrator
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{"role": "user", "content": "What is 2+2?"}],
    "max_tokens": 50
  }' | jq .
```

## Test the 3-Tier Routing

These queries demonstrate Shay's routing system:

```bash
# Tier 1: PHI - Must route locally
curl -X POST http://localhost:8000/analyze \
  -H "Content-Type: application/json" \
  -d '{"text": "Patient Maria Garcia, DOB 03/15/1985, MRN 12345678"}'

# Tier 1: Credentials - Must route locally
curl -X POST http://localhost:8000/analyze \
  -H "Content-Type: application/json" \
  -d '{"text": "API key is sk-1234567890abcdef"}'

# Tier 2: Infrastructure - Anonymize
curl -X POST http://localhost:8000/analyze \
  -H "Content-Type: application/json" \
  -d '{"text": "Check server 10.0.0.50 for issues"}'

# Tier 3: General - Cloud allowed
curl -X POST http://localhost:8000/analyze \
  -H "Content-Type: application/json" \
  -d '{"text": "Write a function to calculate factorial"}'
```

---

# SECTION 5: PHASE 3 - AWS CLOUD CONFIGURATION
# Manual Steps with Detailed Documentation

This is where automation stops. The following steps require AWS console access and manual configuration. Document everything as you go for your capstone report.

## Free Tier Considerations

The Terraform configuration in this project uses several AWS services. Here is what is free and what is not:

FREE (within limits):
- S3: 5GB storage, 20,000 GET requests, 2,000 PUT requests per month
- Lambda: 1 million requests, 400,000 GB-seconds per month
- API Gateway: 1 million HTTP API calls per month
- ECR: 500MB storage for private repositories
- CodeBuild: 100 build minutes per month
- CloudWatch: 10 custom metrics, 5GB log ingestion

NOT FREE:
- CodePipeline: $1 per active pipeline per month
- Lightsail: Starts at $3.50/month for smallest container
- Security Hub: $0.0010 per security check

For a capstone demo, you can stay within free tier by:
1. Using GitHub Actions instead of CodePipeline (free for public repos)
2. Skipping Lightsail and running containers locally
3. Running Security Hub briefly for demonstration only

## Step 5.1: AWS CLI Configuration

Computer: NEXUS

If not already configured:

```bash
# Install AWS CLI if needed
brew install awscli

# Configure with your credentials
aws configure
```

Enter your AWS Access Key ID, Secret Access Key, default region (us-east-1), and output format (json).

Verify:

```bash
aws sts get-caller-identity
```

This should show your account ID and ARN.

## Step 5.2: Create S3 Buckets Manually (Free Tier Safe)

Instead of running full Terraform, create minimal resources manually:

```bash
# Create artifact bucket
aws s3 mb s3://zero-trust-ai-artifacts-$(date +%s)

# Create audit log bucket
aws s3 mb s3://zero-trust-ai-audit-$(date +%s)

# Enable versioning on audit bucket
aws s3api put-bucket-versioning \
  --bucket zero-trust-ai-audit-TIMESTAMP \
  --versioning-configuration Status=Enabled
```

Record the bucket names. You will need them for the pipeline.

## Step 5.3: Create ECR Repository (Free Tier: 500MB)

```bash
# Create repository
aws ecr create-repository \
  --repository-name zero-trust-ai/orchestrator \
  --image-scanning-configuration scanOnPush=true

# Get the repository URI
aws ecr describe-repositories \
  --repository-names zero-trust-ai/orchestrator \
  --query 'repositories[0].repositoryUri' \
  --output text
```

Record the repository URI.

## Step 5.4: Push Container Image to ECR

Computer: NEXUS

```bash
# Navigate to orchestrator directory
cd ~/Projects/zero-trust-hybrid-ai/orchestrator

# Get ECR login
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Build the container
docker build -t zero-trust-orchestrator .

# Tag for ECR
docker tag zero-trust-orchestrator:latest YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/zero-trust-ai/orchestrator:latest

# Push to ECR
docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/zero-trust-ai/orchestrator:latest
```

## Step 5.5: GitHub Actions Alternative to CodePipeline (Free)

Instead of CodePipeline ($1/month), use GitHub Actions. The workflow file is already in the project:

```
.github/workflows/ci.yml
```

This workflow runs on every push and performs:
- Secret scanning with gitleaks
- Python linting
- Dependency vulnerability check
- Container build
- Push to ECR (if credentials configured)

To enable:
1. Go to your GitHub repository settings
2. Navigate to Secrets and Variables > Actions
3. Add secrets: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION
4. Push a commit to trigger the workflow

## Step 5.6: Document Your AWS Setup

For your capstone report, document:

1. Which AWS services you deployed
2. How you configured IAM permissions (principle of least privilege)
3. What security scanning is in place
4. How the CI/CD pipeline works
5. Cost estimates for production deployment

Take screenshots of:
- ECR repository showing scan results
- GitHub Actions workflow runs
- S3 bucket configurations
- Any Security Hub findings

---

# SECTION 6: PHASE 4 - DEMO PREPARATION

## Demo Environment Checklist

Before the presentation, verify:

Computer: NEXUS

```bash
# All services running
curl -s http://localhost:8000/health
curl -s http://aegis:8080/health
curl -s http://ryzen-ai:11434/api/tags | head -5

# Streamlit demo app works
cd ~/Projects/zero-trust-hybrid-ai/demo
pip install streamlit
streamlit run capstone_demo.py
```

The Streamlit app should open in your browser at http://localhost:8501

## Prepare Terminal Windows

Open four terminal windows on NEXUS:

Terminal 1: Orchestrator logs
```bash
cd ~/Projects/zero-trust-hybrid-ai/orchestrator
source venv/bin/activate
python main.py
```

Terminal 2: Live testing
```bash
# Keep this open for running curl commands during demo
```

Terminal 3: SSH to Aegis for monitoring
```bash
ssh aegis
# Can run Get-Process or nvidia-smi to show GPU activity
```

Terminal 4: SSH to Kali-Nexus for security demonstration
```bash
ssh kali-nexus
# Can run security scanning tools
```

---

# SECTION 7: PHASE 5 - LIVE DEMONSTRATION SCRIPT

This section provides a walkthrough for the 15-minute demo to cyber security fellows.

## Introduction (2 minutes)

Start with the problem statement:

"Healthcare organizations need AI capabilities, but sending patient data to cloud AI services violates HIPAA. We built a hybrid system that keeps sensitive data local while using cloud services for security automation."

Show the architecture diagram (in the PDF or on a slide).

Explain the three-tier routing:
- Tier 1: PHI stays local, period
- Tier 2: Infrastructure data gets anonymized
- Tier 3: General queries can use cloud if needed

## Live Demonstration (8 minutes)

### Part 1: Show the Infrastructure (2 minutes)

Terminal 2 on NEXUS:

```bash
# Show all backends
curl -s http://localhost:8000/backends | jq .
```

Point out:
- Aegis (RTX 4080, llama.cpp) - primary inference
- Ryzen-AI (128GB RAM, Ollama) - multi-model
- Status shows "online" for both

### Part 2: Demonstrate Tier 1 Routing (3 minutes)

"Watch what happens when we send patient data."

```bash
# Send PHI through the orchestrator
curl -X POST http://localhost:8000/analyze \
  -H "Content-Type: application/json" \
  -d '{"text": "Patient Maria Garcia, SSN 987-65-4321, diagnosed with hypertension"}'
```

Point out in the response:
- route: "local"
- tier: 1
- hipaa_relevant: true
- entities_detected: PERSON, US_SSN
- "This query will NEVER leave our local hardware"

Now show it actually works:

```bash
# Send through orchestrator for inference
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{"role": "user", "content": "Summarize the condition for patient John Doe with diabetes and hypertension"}],
    "max_tokens": 100
  }' | jq .
```

Point out:
- Response came from Aegis (local)
- No cloud APIs were called
- The orchestrator logs show routing decision

### Part 3: Show Tier 2 Anonymization (1 minute)

```bash
curl -X POST http://localhost:8000/analyze \
  -H "Content-Type: application/json" \
  -d '{"text": "Server at 192.168.1.100 is showing high CPU usage"}'
```

Point out:
- IP address detected
- Would be anonymized before any cloud processing
- "Operational data can go to cloud, but not in identifiable form"

### Part 4: Show Tier 3 General Query (1 minute)

```bash
curl -X POST http://localhost:8000/analyze \
  -H "Content-Type: application/json" \
  -d '{"text": "Explain the difference between TCP and UDP"}'
```

Point out:
- No sensitive entities
- route: "any"
- "This could safely use cloud AI if our local systems were busy"

### Part 5: Show Security (1 minute)

If Kali-Nexus security tools are running:

```bash
ssh kali-nexus "curl -s http://localhost:8080/health"
```

Mention:
- Security scanning happens on every code commit
- Container images scanned before deployment
- Audit logs stored (anonymized) for compliance

## AWS Architecture Explanation (3 minutes)

Show the Terraform or diagrams and explain:

"The cloud side never sees patient data. It only handles:"
- Code repository (GitHub)
- Build automation (CodeBuild or GitHub Actions)
- Container registry (ECR) with vulnerability scanning
- Artifact storage (S3)
- Anonymized audit logs (S3)

"Every code change goes through five security scans before deployment."

Walk through the scanning types briefly:
- Secret scanning catches exposed credentials
- SAST finds code vulnerabilities
- Dependency scanning checks for vulnerable packages
- IaC scanning validates Terraform
- Container scanning checks Docker images

## Questions and Discussion (2 minutes)

Common questions to prepare for:

"What if the local hardware fails?"
- Phantom (backup command center) can take over
- Multiple inference nodes provide redundancy
- Orchestrator can be containerized and run anywhere

"How does this scale?"
- Add more inference nodes to the mesh
- Cloud container handles non-sensitive workloads
- Kubernetes orchestration for larger deployments

"What about model updates?"
- Models can be updated locally (offline capable)
- Or triggered through secure cloud pipeline
- Hash validation ensures model integrity

---

# SECTION 8: APPENDIX - TROUBLESHOOTING

## SSH Connection Issues

If SSH asks for password:
```bash
# Check key is loaded
ssh-add -l

# If empty, add the key
ssh-add ~/.ssh/id_ed25519
```

If still failing, verify authorized_keys on the target machine:
- Windows: Check both %USERPROFILE%\.ssh\authorized_keys AND C:\ProgramData\ssh\administrators_authorized_keys
- Linux: Check ~/.ssh/authorized_keys with permissions 600

## Orchestrator Not Starting

Check Python environment:
```bash
cd ~/Projects/zero-trust-hybrid-ai/orchestrator
source venv/bin/activate
pip list | grep -E "fastapi|uvicorn|presidio"
```

If packages missing:
```bash
pip install -r requirements.txt
python -m spacy download en_core_web_lg
```

## Aegis Not Responding

SSH to Aegis and check:
```powershell
Get-Process | Where-Object { $_.ProcessName -like "*llama*" }
```

If not running:
```powershell
cd C:\llama.cpp
.\start-llama-server.bat
```

Check GPU is recognized:
```powershell
nvidia-smi
```

## Ryzen-AI Not Responding

SSH to Ryzen-AI and check:
```powershell
ollama list
ollama serve
```

If models not present:
```powershell
ollama pull llama3.2:3b
ollama pull qwen2.5-coder:7b
```

## Tailscale Connectivity

If machines cannot ping each other:
```bash
tailscale status
```

If machine shows as offline:
- On that machine, run: tailscale up
- Check: tailscale status

---

# QUICK REFERENCE: CLAUDE CODE PROMPTS IN ORDER

For copy-paste convenience, here are all Claude Code Desktop prompts in sequence:

## Prompt 1: Load Context
[See Section 3, Prompt 1]

## Prompt 2: Deploy Inference Nodes
[See Section 3, Prompt 2]

## Prompt 3: Set Up Orchestrator
[See Section 3, Prompt 3]

## Prompt 4: Verify Infrastructure
[See Section 3, Prompt 4]

---

# END OF MASTER BUILD GUIDE

Team: Shay (Project Lead), Shifty (Infrastructure), Javier (Integration)
Capstone: API Security and DevSecOps
Focus: Zero-trust data routing, HIPAA compliance, hybrid cloud architecture
