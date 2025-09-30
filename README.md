# Zero-Trust Hybrid AI Pipeline

A privacy-preserving AI infrastructure designed for HIPAA-compliant healthcare applications. This system enables AI capabilities while ensuring sensitive patient data never leaves local infrastructure.

---

## The Problem

Healthcare organizations face a critical dilemma: they need AI capabilities to improve patient care, but existing cloud AI services pose unacceptable privacy risks. A single HIPAA violation can result in fines up to $1.5 million per incident, and the reputational damage can be far greater.

Current solutions force a choice between capability and compliance. This project eliminates that tradeoff.

---

## Our Solution

A dual-plane architecture that separates concerns:

**Local Plane (Private)**
- Runs AI inference on local hardware
- Processes all sensitive data
- Continues operating during outages
- No external API calls for PHI

**Cloud Plane (DevSecOps)**
- Handles security scanning
- Manages CI/CD automation
- Provides governance and compliance
- Receives only anonymized data or code

The key insight: sensitive data never crosses the boundary between planes.

---

## Team

**Sheniese Aracena-Baez (Shay)** - Project Lead, Security Architecture
- Designed 4-tier classification system
- HIPAA compliance architecture
- Security audit and gap remediation
- Fail-closed error handling design

**Shifty** - Infrastructure, DevOps
- Distributed architecture implementation
- Tailscale mesh networking
- Orchestrator service
- Setup automation

**Javier Acosta** - Integration, UI
- Microsoft Presidio integration
- Streamlit visualization
- AWS Bedrock integration
- User interface development

---

## 4-Tier Classification System

Unlike simple binary classification, our system uses four tiers:

| Tier | Name | What Triggers It | Routing Decision |
|------|------|------------------|------------------|
| tier0 | PROTECTED | Keyword match (patient, diagnosis, vitals) | LOCAL ONLY |
| tier1 | HIGH | Presidio: SSN, names, credentials, financial | LOCAL ONLY |
| tier2 | MEDIUM | Presidio: IPs, device IDs, hostnames | ANONYMIZE -> cloud |
| tier3 | CLEAR | Nothing detected | ANY backend |

**Tier 0: Protected Context (Local Only)**
- Healthcare keywords detected (patient, diagnosis, vitals, etc.)
- No specific PII but contextually sensitive
- Note: Uses hardcoded keyword set (known limitation)

**Tier 1: High Risk (Local Only)**
- Patient names, SSN, dates of birth
- Medical record numbers
- Prescription information
- Credit cards, bank accounts
- Credentials and API keys

These never leave local infrastructure under any circumstances.

**Tier 2: Medium Risk (Anonymize First)**
- IP addresses
- Device identifiers
- Employee IDs
- Ticket numbers

These can go to cloud services after replacing identifiers with placeholders.

**Tier 3: Clear (Cloud Allowed)**
- General technical questions
- Code assistance requests
- Concept explanations

These have no privacy restrictions.

---

## Hardware Configuration

| Machine | Hardware | Role | Port |
|---------|----------|------|------|
| Nexus | Mac Mini M4 Pro 48GB | Command center, orchestrator | 8000 |
| Aegis | Ryzen 9950X + RTX 4080 Super | Primary inference (llama.cpp) | 8080 |
| Ryzen-AI | Ryzen AI 395 + 128GB RAM | Multi-model inference (Ollama) | 11434 |
| Kali-Nexus | Kali Linux VM | Security scanning | 8080 |
| Phantom | Dell XPS Snapdragon 64GB | Mobile command | - |

All machines connect via Tailscale mesh VPN.

---

## Quick Start

1. Clone this repository to your orchestrator machine (Nexus)

2. Install Python dependencies:
   ```
   cd orchestrator
   pip install -r requirements.txt
   python -m spacy download en_core_web_lg
   ```

3. Run the setup distribution script:
   ```
   cd setup-scripts
   chmod +x distribute-setup.sh
   ./distribute-setup.sh
   ```

4. Follow the instructions to configure each machine

5. Start the orchestrator:
   ```
   cd orchestrator
   python main.py
   ```

6. Verify the setup:
   ```
   curl http://localhost:8000/health
   curl http://localhost:8000/backends
   ```

---

## Project Structure

```
zero-trust-hybrid-ai/
├── orchestrator/
│   ├── main.py                 # FastAPI orchestrator service
│   ├── sensitive_routing.py    # 4-tier classification logic (Shay)
│   └── requirements.txt
│
├── inference-nodes/
│   ├── aegis/
│   │   └── setup-aegis.ps1     # llama.cpp setup for Windows
│   └── ryzen-ai/
│       └── setup-ryzen-ai.ps1 # Ollama setup with RAMDisk
│
├── setup-scripts/
│   ├── distribute-setup.sh     # SSH key distribution
│   ├── setup-kali-nexus.sh     # Security tools setup
│   └── setup-phantom.ps1       # Windows SSH setup
│
├── demo/
│   ├── capstone_demo.py        # Streamlit demonstration
│   ├── sample_data.py          # Test cases
│   └── presentation_script.md  # 15-minute presentation
│
├── terraform/
│   └── main.tf                 # AWS infrastructure
│
├── docker/
│   ├── docker-compose.yml      # Monitoring stack
│   └── prometheus/             # Metrics configuration
│
├── docs/
│   ├── ARCHITECTURE.md
│   ├── SECURITY_MODEL.md
│   ├── DEPLOYMENT_GUIDE.md
│   └── API_REFERENCE.md
│
├── PROJECT_CONTEXT.md          # Project context
└── README.md                   # This file
```

---

## Security Model

The security model is built on these principles:

**Defense in Depth**
- Network isolation via Tailscale
- Application-level routing decisions
- Anonymization for medium-risk data
- Encrypted transport for all traffic

**Fail-Closed Design**
- If PII detection fails, route to local
- If backends are unavailable, reject request
- If anonymization fails, keep local

**Audit Compliance**
- All logs use anonymized text
- Routing decisions are recorded
- No PHI in any external system

---

## API Reference

**Health Check**
```
GET /health
Response: {"status": "healthy", "backends": 3}
```

**List Backends**
```
GET /backends
Response: [{"name": "aegis", "status": "online"}, ...]
```

**Chat Completion**
```
POST /v1/chat/completions
Body: {"messages": [{"role": "user", "content": "..."}]}
Response: {"choices": [...], "routing": {"tier": 1, "backend": "aegis"}}
```

**Analyze Sensitivity**
```
POST /analyze
Body: {"text": "Patient John Smith..."}
Response: {"tier": 1, "entities": [...], "route": "local"}
```

---

## License

MIT License - See LICENSE file for details.

---

## Acknowledgments

- Microsoft Presidio for PII detection
- Meta for Llama models
- Ollama for local model serving
- Tailscale for mesh networking
