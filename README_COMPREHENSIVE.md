# Zero-Trust Hybrid AI Pipeline

## Complete Technical Documentation for Team Meeting

**Project Lead:** Shifty  
**Contributors:** Javier Acosta, Team  
**Date:** November 2024  
**Status:** Active Development - Capstone Project

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [The Problem We're Solving](#the-problem-were-solving)
3. [Architecture Overview](#architecture-overview)
4. [Hardware Infrastructure](#hardware-infrastructure)
5. [Software Components](#software-components)
6. [Teammate Contributions Analysis](#teammate-contributions-analysis)
7. [Integration Strategy](#integration-strategy)
8. [Code Walkthrough](#code-walkthrough)
9. [Setup Instructions](#setup-instructions)
10. [Demo Scenarios](#demo-scenarios)
11. [Security Considerations](#security-considerations)
12. [Future Roadmap](#future-roadmap)

---

## Executive Summary

This project implements a **Zero-Trust Hybrid AI Pipeline** that enables organizations to use AI capabilities while maintaining strict data privacy compliance. The core principle is simple: **sensitive data never leaves your local infrastructure**.

We achieve this through a distributed architecture where:
- **Local inference nodes** process sensitive queries using on-premises hardware
- **Cloud services** handle DevSecOps automation, CI/CD, and non-sensitive workloads
- **Intelligent routing** automatically detects sensitive data and directs it appropriately

The target use case is **healthcare** (HIPAA compliance), but the architecture applies to any regulated industry: legal, financial, government, or any organization handling confidential data.

---

## The Problem We're Solving

### The AI Privacy Dilemma

Organizations face a critical challenge:

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│   "We want AI capabilities, but we can't send our data to       │
│    cloud AI services due to compliance requirements."            │
│                                                                  │
│   - Every healthcare CIO                                        │
│   - Every legal firm partner                                     │
│   - Every financial compliance officer                           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Real-World Impact

| Statistic | Value | Source |
|-----------|-------|--------|
| Healthcare breaches in 2023 | 725 | HHS OCR |
| Records affected | 133 million | HHS OCR |
| Average breach cost | $10.93 million | IBM Cost of Data Breach 2023 |
| Ransomware attacks on healthcare | 1 every 3 days | Check Point Research |

### Current Cloud AI Limitations

| Provider | HIPAA BAA | PHI Processing | Limitation |
|----------|-----------|----------------|------------|
| OpenAI (ChatGPT) | No | Not allowed | Cannot use for patient data |
| Anthropic Claude | Enterprise only | With controls | Expensive, still cloud |
| Google Gemini | Enterprise only | With controls | Expensive, still cloud |
| AWS Bedrock | Yes | With controls | Requires BAA, still cloud transmission |

### Our Solution

**Keep PHI local. Leverage cloud for everything else.**

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│   Patient Data  →  Local AI  →  Response                        │
│   (Never leaves your network)                                   │
│                                                                  │
│   Code/Config   →  Cloud CI/CD  →  Deployed to Local           │
│   (No sensitive data, just automation)                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Architecture Overview

### The Dual-Plane Model

Our architecture separates concerns into two distinct planes:

```
╔══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║                         ZERO-TRUST BOUNDARY                               ║
║                                                                           ║
║    ┌─────────────────────────────┐    ┌─────────────────────────────┐    ║
║    │     LOCAL PRIVATE PLANE     │    │      CLOUD PUBLIC PLANE     │    ║
║    │                             │    │                             │    ║
║    │  ┌─────────────────────┐   │    │   ┌─────────────────────┐   │    ║
║    │  │   Nexus (Command)   │   │    │   │   GitHub/CodeCommit │   │    ║
║    │  │   Mac Mini M4 Pro   │   │    │   │      (Source)       │   │    ║
║    │  └─────────┬───────────┘   │    │   └──────────┬──────────┘   │    ║
║    │            │               │    │              │              │    ║
║    │  ┌─────────▼───────────┐   │    │   ┌──────────▼──────────┐   │    ║
║    │  │  Orchestrator API   │   │    │   │    CodePipeline     │   │    ║
║    │  │     (FastAPI)       │   │    │   │    (Automation)     │   │    ║
║    │  └─────────┬───────────┘   │    │   └──────────┬──────────┘   │    ║
║    │            │               │    │              │              │    ║
║    │     ┌──────┴──────┐       │    │   ┌──────────▼──────────┐   │    ║
║    │     │             │       │    │   │     CodeBuild       │   │    ║
║    │     ▼             ▼       │    │   │  (Security Scans)   │   │    ║
║    │  ┌──────┐    ┌────────┐   │    │   └──────────┬──────────┘   │    ║
║    │  │Aegis │    │ Ryzen  │   │    │              │              │    ║
║    │  │RTX   │    │ Admin  │   │    │   ┌──────────▼──────────┐   │    ║
║    │  │4080  │    │ 128GB  │   │    │   │        ECR          │   │    ║
║    │  └──────┘    └────────┘   │    │   │  (Container Store)  │   │    ║
║    │                           │    │   └──────────┬──────────┘   │    ║
║    │  ┌─────────────────────┐  │    │              │              │    ║
║    │  │    Kali-Nexus       │  │    │   ┌──────────▼──────────┐   │    ║
║    │  │  (Security Scans)   │  │    │   │     Lightsail       │   │    ║
║    │  └─────────────────────┘  │    │   │   (Cloud API)       │   │    ║
║    │                           │    │   └─────────────────────┘   │    ║
║    └─────────────────────────────┘    └─────────────────────────────┘    ║
║                                                                           ║
║    DATA STAYS HERE                    ONLY CODE/CONFIG GOES HERE         ║
║    ─────────────────                  ──────────────────────────         ║
║    • Patient records                  • Terraform files                  ║
║    • SSN, DOB, Names                  • Docker images                    ║
║    • Medical history                  • CI/CD pipelines                  ║
║    • Financial data                   • Security scan results            ║
║    • Legal documents                  • Audit logs (anonymized)          ║
║                                                                           ║
╚══════════════════════════════════════════════════════════════════════════╝
```

### Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           REQUEST FLOW                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   User Input                                                                 │
│       │                                                                      │
│       ▼                                                                      │
│   ┌───────────────────────────────────────────────────────────────────┐     │
│   │                    GUARDRAIL CHECK                                 │     │
│   │                                                                    │     │
│   │   • Presidio PII Detection (Javier's contribution)                │     │
│   │   • Pattern matching for SSN, DOB, Names, Addresses               │     │
│   │   • Entity recognition for medical terms                          │     │
│   │                                                                    │     │
│   └───────────────────────────┬───────────────────────────────────────┘     │
│                               │                                              │
│               ┌───────────────┴───────────────┐                             │
│               │                               │                             │
│               ▼                               ▼                             │
│   ┌───────────────────────┐       ┌───────────────────────┐                │
│   │  ROUTE A: SENSITIVE   │       │  ROUTE B: SAFE        │                │
│   │  (LOCAL PROCESSING)   │       │  (CLOUD OPTIONAL)     │                │
│   │                       │       │                       │                │
│   │  "⚠️ Sensitive Data   │       │  "✅ No Sensitive     │                │
│   │   Detected! Routing   │       │   Data. Routing to    │                │
│   │   locally..."         │       │   Cloud..."           │                │
│   │                       │       │                       │                │
│   │  • Aegis (llama.cpp)  │       │  • AWS Bedrock        │                │
│   │  • Ryzen-AI (Ollama)│       │  • Or still local     │                │
│   │  • 70-90 tok/s        │       │  • User's choice      │                │
│   └───────────────────────┘       └───────────────────────┘                │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Hardware Infrastructure

### Machine Inventory

| Machine | Role | Specs | OS | Speed |
|---------|------|-------|-----|-------|
| **Nexus** | Command Center | Mac Mini M4 Pro, 48GB | macOS | 35-50 tok/s |
| **Kali-Nexus** | Security Agent | VM on Nexus | Kali Linux | N/A |
| **Phantom** | Mobile Command | Dell XPS Snapdragon, 64GB | Windows 11 | 15-25 tok/s |
| **Aegis** | Primary Inference | Ryzen 9950X, RTX 4080 Super 16GB, 64GB | Windows 11 Pro | **70-90 tok/s** |
| **Ryzen-AI** | Multi-Model | Ryzen AI 395, 128GB DDR5, USB-C boot | Windows 11 Pro | 8-15 tok/s |

### Why These Specific Machines?

**Memory Bandwidth Matters More Than Capacity**

LLM inference speed is determined by how fast you can move weights from memory to compute:

```
┌─────────────────────────────────────────────────────────────────┐
│                    MEMORY BANDWIDTH COMPARISON                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   RTX 4080 Super (GDDR6X)                                       │
│   ████████████████████████████████████████  736 GB/s            │
│                                                                  │
│   Mac Mini M4 Pro (Unified)                                     │
│   ████████████████  273 GB/s                                    │
│                                                                  │
│   Ryzen-AI DDR5-5600                                          │
│   █████  89.6 GB/s                                              │
│                                                                  │
│   Phantom DDR5-8000                                             │
│   ████████  135 GB/s                                            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

INSIGHT: Despite Ryzen-AI having 128GB RAM vs Aegis's 16GB VRAM,
         Aegis is 5-8x faster because bandwidth > capacity for inference.
```

**So Why Keep Ryzen-AI?**

Ryzen-AI excels at **multi-model scenarios**:

```python
# Ryzen-AI Scenario 4: Six models loaded simultaneously
models_in_memory = {
    "qwen2.5-coder:7b": "4.5 GB",   # Code generation
    "phi3:14b":         "8.0 GB",   # Validation
    "codellama:7b":     "4.0 GB",   # Code explanation
    "bge-m3":           "2.0 GB",   # Embeddings
    "llama3.2:3b":      "2.0 GB",   # Fast routing
    "whisper:large":    "3.0 GB",   # Audio transcription
}
# Total: ~24 GB, leaves 100+ GB free
# Benefit: Instant model switching, no reload delay
```

### Network Topology

```
┌─────────────────────────────────────────────────────────────────┐
│                      TAILSCALE MESH VPN                          │
│                                                                  │
│        100.x.x.1                      100.x.x.2                 │
│      ┌──────────┐                   ┌──────────┐                │
│      │  Nexus   │◄──────────────────│ Phantom  │                │
│      │(Command) │                   │ (Mobile) │                │
│      └────┬─────┘                   └──────────┘                │
│           │                                                      │
│           │ 100.x.x.3                                           │
│      ┌────┴─────┐                                               │
│      │  Nexus-  │                                               │
│      │  Kali    │                                               │
│      │(Security)│                                               │
│      └──────────┘                                               │
│           │                                                      │
│     ┌─────┴─────────────────────────┐                          │
│     │                               │                          │
│     ▼ 100.x.x.4                     ▼ 100.x.x.5               │
│ ┌──────────┐                   ┌──────────┐                    │
│ │  Aegis   │                   │  Ryzen   │                    │
│ │(Primary) │                   │  Admin   │                    │
│ │ RTX 4080 │                   │ 128GB    │                    │
│ └──────────┘                   └──────────┘                    │
│                                                                  │
│  All traffic encrypted with WireGuard                           │
│  MagicDNS enables hostname resolution                           │
│  ACLs restrict access to authorized machines only               │
└─────────────────────────────────────────────────────────────────┘
```

---

## Software Components

### Local Inference Stack

**Aegis (Primary - llama.cpp)**

```powershell
# Installation location
C:\llama.cpp\
├── llama-server.exe      # OpenAI-compatible API server
├── models\
│   └── Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf  # 4.9GB
└── start-server.ps1      # Startup script

# Startup command
.\llama-server.exe -m models\Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf `
    --host 0.0.0.0 --port 8080 `
    -ngl 99 `        # All layers on GPU
    -c 8192 `        # 8K context window
    -b 512 `         # Batch size
    --cont-batching  # Enable continuous batching
    -np 4            # 4 parallel sequences
```

**Ryzen-AI (Multi-Model - Ollama)**

```powershell
# Models stored in
$env:USERPROFILE\.ollama\models\

# Or optionally on RAMDisk (32GB allocation)
R:\ollama\models\

# Available models
ollama list
# NAME                    SIZE
# qwen2.5-coder:7b       4.5 GB
# phi3:14b               8.0 GB
# codellama:7b           4.0 GB
# nomic-embed-text       274 MB
# llama3.2:3b            2.0 GB
```

### Orchestrator Service

The orchestrator runs on Nexus and routes requests to appropriate backends:

```python
# orchestrator/main.py (simplified)

from fastapi import FastAPI
import httpx

app = FastAPI(title="Zero-Trust AI Orchestrator")

BACKENDS = {
    "aegis": {
        "url": "http://aegis:8080",
        "type": "llama.cpp",
        "speed": "70-90 tok/s",
        "specialty": ["general", "fast"]
    },
    "ryzen-ai": {
        "url": "http://ryzen-ai:11434",
        "type": "ollama",
        "speed": "8-15 tok/s",
        "specialty": ["code", "validation", "embedding"]
    }
}

@app.post("/v1/chat/completions")
async def chat(request: ChatRequest):
    # 1. Detect task type
    task = detect_task_type(request.messages)
    
    # 2. Check for PHI (uses Presidio - Javier's contribution)
    if contains_phi(request.messages):
        # ALWAYS route locally
        backend = select_local_backend(task)
    else:
        # Can use cloud if configured
        backend = select_optimal_backend(task)
    
    # 3. Forward request
    response = await forward_to_backend(backend, request)
    
    # 4. Return with metadata
    return {
        **response,
        "orchestration": {
            "backend": backend["name"],
            "task_type": task,
            "phi_detected": contains_phi(request.messages)
        }
    }
```

### Security Scanning Agent (Kali-Nexus)

```python
# Kali-Nexus Security API (simplified)
from fastapi import FastAPI, BackgroundTasks

app = FastAPI(title="Security Scanning Agent")

@app.post("/scan/iac")
async def scan_infrastructure(target_dir: str, background_tasks: BackgroundTasks):
    """Scan Terraform/Docker files for security issues"""
    
    # Run multiple scanners
    background_tasks.add_task(run_checkov, target_dir)
    background_tasks.add_task(run_trivy, target_dir)
    background_tasks.add_task(run_semgrep, target_dir)
    
    return {"status": "scanning", "scan_id": generate_id()}

@app.post("/scan/network")
async def scan_network(target: str):
    """Scan network for vulnerabilities"""
    
    # Uses nmap, nuclei
    results = await run_nmap(target)
    return {"findings": results}
```

---

## Teammate Contributions Analysis

### Javier Acosta's Contribution

Javier built a **Streamlit-based UI with intelligent PII routing**. This is excellent work that directly addresses the core zero-trust requirement.

#### What Javier Built

```python
# Javier's code (from screenshot)
import streamlit as st
import boto3
import json
import requests
from presidio_analyzer import AnalyzerEngine

# THE GUARDRAIL CHECK
with st.status("Analyzing sensitivity...", expanded=True) as status:
    pii_results = detect_pii(prompt)
    
    if pii_results:
        # --- ROUTE A: SENSITIVE (LOCAL) ---
        status.update(label="⚠️ Sensitive Data Detected! Routing locally...")
        detected_types = list(set([r.entity_type for r in pii_results]))
        st.write(f"Detected: {', '.join(detected_types)}")
        
        # Optional: Visualize what the model actually sees (Anonymized)
        safe_prompt_preview = anonymize_text(prompt, pii_results)
        st.code(f"Sanitized View for logs: {safe_prompt_preview}")
        
        # Execute Local Model
        response_text = query_local_ollama(prompt)
        route_badge = "🔒 Local Llama 3 (Private)"
        
    else:
        # --- ROUTE B: SAFE (CLOUD) ---
        status.update(label="✅ No Sensitive Data. Routing to Cloud...")
        
        # Visual debugger for cloud payload
        with st.expander("📡 View Cloud API Payload (AWS)"):
            st.json(payload)
        
        # Execute Cloud Model
        response_text = query_aws_bedrock(prompt)
        route_badge = "☁️ AWS Claude 3.5 (Public)"
```

#### Key Features from Javier's Implementation

| Feature | Description | Value |
|---------|-------------|-------|
| **Presidio Integration** | Microsoft's PII detection library | Industry-standard entity recognition |
| **Visual Feedback** | Streamlit status updates | Users see routing decision in real-time |
| **Anonymization Preview** | Shows sanitized version | Transparency for audit/debugging |
| **Dual Routing** | Local vs Cloud | Automatic based on content |
| **AWS Bedrock** | Claude 3.5 for non-sensitive | Leverages cloud when safe |

#### Architecture Diagram Analysis

Javier's architecture diagram shows:

```
Local Private Interface          Cloud (Non-sensitive)
─────────────────────           ─────────────────────
                                
User Device (Client)            GitHub/CodeCommit
       │                               │
       ▼                               ▼
Fast API (Local API)            CodePipeline
       │                               │
       ▼                               ▼
Local LLM (Llama.cpp)           CodeBuild (scans + build)
       │                               │
       ▼                               ▼
   Docker                       Amazon ECR
       │                               │
       └───────────────────────────────┘
                    │
                    ▼
            Amazon Lightsail
             (cloud api)
```

**Alignment with Our Project:**

| Javier's Component | Our Equivalent | Notes |
|-------------------|----------------|-------|
| Fast API (Local) | Orchestrator on Nexus | Same approach |
| Local LLM (Llama.cpp) | Aegis (llama.cpp) | Identical |
| Docker | Our containerization | Same |
| GitHub | Our GitHub source | Same |
| CodePipeline | Our Terraform CodePipeline | Same |
| CodeBuild | Our security scanning stage | Same |
| ECR | Our ECR repository | Same |
| Lightsail | Optional cloud endpoint | We use API Gateway + Lambda |

### How to Integrate Javier's Work

Javier's Presidio-based PII detection should become our **primary guardrail**:

```python
# Integration point in orchestrator/main.py

from presidio_analyzer import AnalyzerEngine
from presidio_anonymizer import AnonymizerEngine

# Initialize Presidio (Javier's approach)
analyzer = AnalyzerEngine()
anonymizer = AnonymizerEngine()

def detect_pii(text: str) -> list:
    """
    Detect PII using Microsoft Presidio.
    
    Returns list of detected entities:
    - PERSON (names)
    - PHONE_NUMBER
    - EMAIL_ADDRESS
    - CREDIT_CARD
    - US_SSN
    - US_DRIVER_LICENSE
    - MEDICAL_LICENSE
    - DATE_TIME (for DOB detection)
    - LOCATION
    - NRP (nationality, religion, political group)
    """
    results = analyzer.analyze(
        text=text,
        language='en',
        entities=[
            "PERSON", "PHONE_NUMBER", "EMAIL_ADDRESS",
            "CREDIT_CARD", "US_SSN", "US_DRIVER_LICENSE",
            "MEDICAL_LICENSE", "DATE_TIME", "LOCATION"
        ]
    )
    return results

def anonymize_for_logging(text: str, pii_results: list) -> str:
    """
    Create anonymized version for audit logs.
    PHI replaced with placeholders: [PERSON], [SSN], etc.
    """
    return anonymizer.anonymize(
        text=text,
        analyzer_results=pii_results
    ).text

# Usage in request handling
@app.post("/v1/chat/completions")
async def chat(request: ChatRequest):
    prompt_text = extract_prompt(request.messages)
    
    # Javier's PII detection
    pii_results = detect_pii(prompt_text)
    
    if pii_results:
        # Log anonymized version only
        safe_version = anonymize_for_logging(prompt_text, pii_results)
        logger.info(f"PHI detected, routing locally. Sanitized: {safe_version}")
        
        # Route to local only
        return await route_to_local(request)
    else:
        # Can consider cloud
        return await route_optimal(request)
```

### Recommended Integration Tasks

1. **Add Presidio to requirements.txt**
```
presidio-analyzer>=2.2.0
presidio-anonymizer>=2.2.0
spacy>=3.5.0
en_core_web_lg @ https://github.com/explosion/spacy-models/releases/download/en_core_web_lg-3.5.0/en_core_web_lg-3.5.0.tar.gz
```

2. **Create Streamlit UI** (based on Javier's design)
```python
# ui/app.py
import streamlit as st
from orchestrator_client import query

st.title("Zero-Trust AI Assistant")

prompt = st.text_area("Enter your query:")

if st.button("Submit"):
    with st.status("Processing...") as status:
        response = query(prompt)
        
        if response["phi_detected"]:
            status.update(label="🔒 Processed Locally", state="complete")
            st.success(f"Routed to: {response['backend']}")
        else:
            status.update(label="☁️ Cloud Available", state="complete")
            
        st.write(response["content"])
```

3. **Add AWS Bedrock fallback** (Javier's approach)
```python
# backends/aws_bedrock.py
import boto3
import json

def query_aws_bedrock(prompt: str) -> str:
    """
    Query AWS Bedrock Claude for non-sensitive requests.
    Requires AWS credentials and Bedrock access.
    """
    client = boto3.client('bedrock-runtime', region_name='us-east-1')
    
    body = json.dumps({
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 1024,
        "messages": [{"role": "user", "content": prompt}]
    })
    
    response = client.invoke_model(
        modelId="anthropic.claude-3-5-sonnet-20241022-v2:0",
        body=body
    )
    
    result = json.loads(response['body'].read())
    return result['content'][0]['text']
```

---

## Code Walkthrough

### Project Structure

```
zero-trust-hybrid-ai/
├── CLAUDE_CODE_PROMPT.md       # Prompt for Claude Code Desktop
├── README.md                   # This file
├── SETUP_INSTRUCTIONS.md       # Step-by-step setup guide
│
├── orchestrator/               # Central routing service
│   ├── main.py                # FastAPI application
│   ├── requirements.txt       # Python dependencies
│   └── Dockerfile             # Container build
│
├── inference-nodes/
│   ├── aegis/
│   │   └── setup-aegis.ps1    # Windows + llama.cpp + CUDA
│   └── ryzen-ai/
│       └── setup-ryzen-ai.ps1  # Windows + Ollama + RAMDisk
│
├── setup-scripts/
│   ├── distribute-setup.sh    # SSH key distribution
│   ├── setup-kali-nexus.sh    # Kali VM security tools
│   └── setup-phantom.ps1      # Windows SSH setup
│
├── mcp-servers/                # Claude Desktop integration
│   ├── claude_desktop_config.json
│   └── orchestrator-mcp/
│       └── index.js
│
├── terraform/                  # AWS Infrastructure as Code
│   └── main.tf                # S3, ECR, CodePipeline, Lambda
│
├── docker/
│   ├── docker-compose.yml     # Multi-profile compose
│   ├── prometheus/
│   │   └── prometheus.yml     # Metrics collection
│   └── grafana/
│       └── dashboards/
│           └── zero-trust-ai.json
│
├── .github/
│   └── workflows/
│       └── ci.yml             # GitHub Actions CI/CD
│
├── .devcontainer/
│   └── devcontainer.json      # GitHub Codespaces config
│
├── demo/
│   └── DEMO_SCRIPT.md         # 15-minute presentation
│
└── tests/
    └── test_orchestrator.py   # Pytest test suite
```

### Key Code Snippets

**1. Task Detection and Routing**

```python
# orchestrator/main.py

def detect_task_type(messages: list) -> str:
    """
    Analyze the request to determine optimal routing.
    
    Returns:
        - "code": Programming tasks → Ryzen-AI (Qwen2.5-Coder)
        - "validation": Needs review → Ryzen-AI (Phi-3)
        - "embedding": Vector generation → Ryzen-AI (BGE-M3)
        - "general": Standard queries → Aegis (fastest)
    """
    last_message = messages[-1]["content"].lower()
    
    # Code indicators
    code_patterns = [
        "write a function", "implement", "code", "script",
        "debug", "fix this", "```", "def ", "class ",
        "import ", "function", "variable"
    ]
    
    # Validation indicators
    validation_patterns = [
        "review", "check", "validate", "verify",
        "is this correct", "any issues", "security"
    ]
    
    # Embedding indicators
    embedding_patterns = [
        "embed", "vector", "similarity", "search",
        "retrieve", "rag", "knowledge base"
    ]
    
    if any(p in last_message for p in code_patterns):
        return "code"
    elif any(p in last_message for p in validation_patterns):
        return "validation"
    elif any(p in last_message for p in embedding_patterns):
        return "embedding"
    else:
        return "general"
```

**2. PHI Detection (Integrating Javier's Approach)**

```python
# orchestrator/phi_detection.py

import re
from typing import List, Tuple
from presidio_analyzer import AnalyzerEngine

# Initialize once at startup
_analyzer = None

def get_analyzer():
    global _analyzer
    if _analyzer is None:
        _analyzer = AnalyzerEngine()
    return _analyzer

def detect_phi(text: str) -> List[dict]:
    """
    Detect Protected Health Information using multiple methods:
    1. Microsoft Presidio (Javier's approach)
    2. Regex patterns for common formats
    3. Keyword detection for medical terms
    
    Returns list of detections with type and confidence.
    """
    detections = []
    
    # Method 1: Presidio (comprehensive)
    analyzer = get_analyzer()
    presidio_results = analyzer.analyze(text=text, language='en')
    
    for result in presidio_results:
        detections.append({
            "type": result.entity_type,
            "start": result.start,
            "end": result.end,
            "confidence": result.score,
            "method": "presidio"
        })
    
    # Method 2: Regex patterns (fast, specific)
    patterns = {
        "SSN": r"\b\d{3}-\d{2}-\d{4}\b",
        "PHONE": r"\b\d{3}[-.]?\d{3}[-.]?\d{4}\b",
        "DOB": r"\b(DOB|Date of Birth|Born)[\s:]+\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b",
        "MRN": r"\b(MRN|Medical Record)[\s:#]+\d+\b",
    }
    
    for phi_type, pattern in patterns.items():
        for match in re.finditer(pattern, text, re.IGNORECASE):
            detections.append({
                "type": phi_type,
                "start": match.start(),
                "end": match.end(),
                "confidence": 0.95,
                "method": "regex"
            })
    
    # Method 3: Medical keywords
    medical_keywords = [
        "patient", "diagnosis", "prescription", "medication",
        "symptoms", "treatment", "medical history", "allergies",
        "blood pressure", "heart rate", "temperature"
    ]
    
    text_lower = text.lower()
    if any(kw in text_lower for kw in medical_keywords):
        detections.append({
            "type": "MEDICAL_CONTEXT",
            "start": 0,
            "end": len(text),
            "confidence": 0.7,
            "method": "keyword"
        })
    
    return detections

def contains_phi(messages: List[dict]) -> bool:
    """
    Check if any message contains PHI.
    Returns True if PHI detected, False otherwise.
    """
    for message in messages:
        content = message.get("content", "")
        if detect_phi(content):
            return True
    return False
```

**3. Backend Selection**

```python
# orchestrator/routing.py

from typing import Optional
import httpx
import asyncio

class BackendRouter:
    def __init__(self, backends: dict):
        self.backends = backends
        self.health_cache = {}
        self.last_health_check = {}
    
    async def check_health(self, backend_id: str) -> bool:
        """Check if a backend is healthy."""
        config = self.backends[backend_id]
        url = config["url"]
        
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                if config["type"] == "llama.cpp":
                    response = await client.get(f"{url}/health")
                else:  # ollama
                    response = await client.get(f"{url}/api/tags")
                
                return response.status_code == 200
        except:
            return False
    
    async def select_backend(self, task_type: str, require_local: bool = False) -> dict:
        """
        Select the best backend for a task.
        
        Args:
            task_type: Type of task (general, code, validation, embedding)
            require_local: If True, only consider local backends
        
        Returns:
            Backend configuration dict
        """
        # Priority mapping
        task_backend_priority = {
            "general": ["aegis", "ryzen-ai", "nexus"],
            "code": ["ryzen-ai", "aegis"],
            "validation": ["ryzen-ai"],
            "embedding": ["ryzen-ai"],
        }
        
        priority_list = task_backend_priority.get(task_type, ["aegis"])
        
        # Check backends in priority order
        for backend_id in priority_list:
            if backend_id not in self.backends:
                continue
            
            if await self.check_health(backend_id):
                return {
                    "id": backend_id,
                    **self.backends[backend_id]
                }
        
        raise RuntimeError("No healthy backends available")
```

**4. Request Forwarding**

```python
# orchestrator/forwarding.py

import httpx
import json
from typing import AsyncIterator

async def forward_to_llama_cpp(backend: dict, request: dict) -> dict:
    """Forward request to llama.cpp server (Aegis)."""
    
    url = f"{backend['url']}/v1/chat/completions"
    
    async with httpx.AsyncClient(timeout=120.0) as client:
        response = await client.post(
            url,
            json={
                "messages": request["messages"],
                "max_tokens": request.get("max_tokens", 1024),
                "temperature": request.get("temperature", 0.7),
            }
        )
        
        return response.json()

async def forward_to_ollama(backend: dict, request: dict, model: str) -> dict:
    """Forward request to Ollama server (Ryzen-AI)."""
    
    url = f"{backend['url']}/api/chat"
    
    async with httpx.AsyncClient(timeout=120.0) as client:
        response = await client.post(
            url,
            json={
                "model": model,
                "messages": request["messages"],
                "stream": False,
            }
        )
        
        result = response.json()
        
        # Convert to OpenAI format
        return {
            "choices": [{
                "message": {
                    "role": "assistant",
                    "content": result["message"]["content"]
                }
            }],
            "model": model
        }
```

---

## Setup Instructions

### Quick Start (For Demo)

```bash
# On Nexus (Mac Mini M4 Pro)

# 1. Clone the project
git clone https://github.com/YOUR-ORG/zero-trust-hybrid-ai.git
cd zero-trust-hybrid-ai

# 2. Generate SSH keys
ssh-keygen -t ed25519 -C "nexus@zero-trust-ai" -N "" -f ~/.ssh/id_ed25519

# 3. View your public key (copy this to other machines)
cat ~/.ssh/id_ed25519.pub

# 4. Run the distribution script
chmod +x setup-scripts/distribute-setup.sh
./setup-scripts/distribute-setup.sh

# 5. Start the orchestrator
cd orchestrator
pip install -r requirements.txt
python main.py

# 6. Test
curl http://localhost:8000/backends
```

### Full Setup (See SETUP_INSTRUCTIONS.md)

The complete setup takes approximately 3 hours:

| Phase | Time | Tasks |
|-------|------|-------|
| Nexus setup | 15 min | SSH keys, Python deps |
| Kali-Nexus | 30 min | Security tools, API |
| Phantom | 20 min | SSH server |
| Aegis | 30 min | llama.cpp, model download |
| Ryzen-AI | 30 min | Ollama, 5 models |
| Integration | 15 min | Orchestrator, testing |

---

## Demo Scenarios

### Scenario 1: PHI Detection and Local Routing

```bash
# Send a request with obvious PHI
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{
      "role": "user",
      "content": "Patient: Maria Garcia, DOB: 03/15/1962, SSN: 987-65-4321. She reports chest pain and shortness of breath. BP 185/115. What is your assessment?"
    }]
  }'
```

**Expected Response:**
```json
{
  "choices": [{
    "message": {
      "role": "assistant",
      "content": "CRITICAL - IMMEDIATE ATTENTION REQUIRED\n\nThis presentation is concerning for acute coronary syndrome..."
    }
  }],
  "orchestration": {
    "backend": "aegis",
    "backend_type": "llama.cpp",
    "phi_detected": true,
    "detected_entities": ["PERSON", "DATE_TIME", "US_SSN"],
    "latency_ms": 1847,
    "data_location": "LOCAL_ONLY"
  }
}
```

### Scenario 2: Code Generation (Multi-Model)

```bash
# Send a code request
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{
      "role": "user",
      "content": "Write a Python function to validate HIPAA-compliant data handling"
    }],
    "require_validation": true
  }'
```

**Expected Response:**
```json
{
  "choices": [{
    "message": {
      "content": "```python\ndef validate_hipaa_handling(data: dict) -> tuple[bool, list]:\n    ..."
    }
  }],
  "orchestration": {
    "backend": "ryzen-ai",
    "model": "qwen2.5-coder:7b",
    "validation": {
      "validator_model": "phi3:14b",
      "passed": true,
      "confidence": 0.94,
      "checks": ["no_plaintext_phi", "uses_encryption", "audit_logging"]
    }
  }
}
```

### Scenario 3: Non-Sensitive Query (Cloud Option)

```bash
# General knowledge question (no PHI)
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{
      "role": "user",
      "content": "Explain the difference between symmetric and asymmetric encryption"
    }]
  }'
```

**Expected Response:**
```json
{
  "choices": [{
    "message": {
      "content": "Symmetric encryption uses a single shared key..."
    }
  }],
  "orchestration": {
    "backend": "aegis",
    "phi_detected": false,
    "cloud_eligible": true,
    "note": "Could route to AWS Bedrock if configured"
  }
}
```

---

## Security Considerations

### HIPAA Compliance Mapping

| HIPAA Requirement | Our Implementation |
|-------------------|-------------------|
| Access Controls | Tailscale ACLs restrict machine access |
| Audit Controls | All requests logged with anonymized PHI |
| Integrity | Multi-model validation pipeline |
| Transmission Security | WireGuard encryption (Tailscale) |
| Encryption at Rest | BitLocker (Windows), FileVault (Mac) |

### Defense in Depth

```
Layer 1: Network Isolation
├── Tailscale mesh VPN
├── No public internet exposure
└── ACL-based access control

Layer 2: PHI Detection
├── Presidio entity recognition (Javier)
├── Regex pattern matching
└── Keyword detection

Layer 3: Routing Enforcement
├── PHI = Local only (no exceptions)
├── Backend health checks
└── Fallback handling

Layer 4: Audit Trail
├── Request logging (anonymized)
├── Backend selection logged
└── Compliance metadata

Layer 5: Validation
├── Multi-model verification
├── Security scanning (Kali)
└── Code review automation
```

---

## Future Roadmap

### Phase 1: Core Infrastructure (Current)
- [x] Hardware provisioning
- [x] Tailscale mesh setup
- [x] Orchestrator service
- [x] Aegis llama.cpp setup
- [x] Ryzen-AI Ollama setup
- [ ] Kali-Nexus security tools
- [ ] Full integration testing

### Phase 2: Javier's Integration
- [ ] Add Presidio PII detection
- [ ] Streamlit UI
- [ ] AWS Bedrock fallback
- [ ] Anonymization preview

### Phase 3: Production Hardening
- [ ] Terraform AWS deployment
- [ ] GitHub Actions CI/CD
- [ ] Prometheus/Grafana monitoring
- [ ] Security scanning automation

### Phase 4: Advanced Features
- [ ] RAG with local embeddings
- [ ] Audio transcription (Whisper)
- [ ] Document processing
- [ ] Fine-tuned models

---

## Team Meeting Agenda

### Suggested 1-Hour Format

| Time | Topic | Presenter |
|------|-------|-----------|
| 0:00-0:10 | Problem Statement & Architecture | Shifty |
| 0:10-0:20 | Hardware & Network Setup | Shifty |
| 0:20-0:30 | Javier's PII Detection Demo | Javier |
| 0:30-0:40 | Live Demo: PHI Routing | Shifty |
| 0:40-0:50 | Integration Discussion | Team |
| 0:50-1:00 | Next Steps & Task Assignment | Team |

### Discussion Points

1. **Javier's Presidio integration** - How to incorporate into orchestrator?
2. **AWS Bedrock** - Do we want cloud fallback for non-sensitive queries?
3. **Streamlit UI** - Should this be the primary interface?
4. **Testing strategy** - How do we validate PHI detection accuracy?
5. **Deployment timeline** - Who handles which machines?

---

## Appendix: Quick Reference

### Machine Access

```bash
# SSH to any machine from Nexus
ssh kali-nexus
ssh phantom
ssh aegis
ssh ryzen-ai

# Check all systems
./scripts/check-all-systems.sh
```

### API Endpoints

```bash
# Orchestrator (Nexus)
curl http://localhost:8000/health
curl http://localhost:8000/backends
curl -X POST http://localhost:8000/v1/chat/completions -d '...'

# Aegis (llama.cpp)
curl http://aegis:8080/health
curl -X POST http://aegis:8080/v1/chat/completions -d '...'

# Ryzen-AI (Ollama)
curl http://ryzen-ai:11434/api/tags
curl -X POST http://ryzen-ai:11434/api/chat -d '...'

# Kali-Nexus (Security)
curl http://kali-nexus:8080/health
curl http://kali-nexus:8080/tools
```

### Common Commands

```bash
# Start Aegis inference (on Aegis)
C:\llama.cpp\start-server.bat

# Start Ryzen-AI (on Ryzen-AI)
ollama serve

# Start Orchestrator (on Nexus)
cd ~/Projects/zero-trust-hybrid-ai/orchestrator
python main.py

# View Aegis GPU usage
ssh aegis "nvidia-smi"

# View Ryzen-AI models
ssh ryzen-ai "ollama list"
```

---

*Document Version: 1.0*  
*Last Updated: November 2024*  
*Maintainer: Project Team*
