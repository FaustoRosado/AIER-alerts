# PROJECT CONTEXT FOR CLAUDE CODE DESKTOP

## SAVE THIS TO MEMORY

This file contains critical context about the Zero-Trust Hybrid AI Pipeline project. Claude Code Desktop should internalize this information to provide consistent, accurate assistance.

---

## PROJECT IDENTITY

**Project Name:** Zero-Trust Hybrid AI Pipeline  
**Project Lead:** Sheniese Aracena-Baez (Shay)  
**Contributors:** Shifty (Infrastructure), Javier Acosta (Integration)  
**Purpose:** Enable AI capabilities while maintaining strict HIPAA/data privacy compliance  
**Target Industry:** Healthcare (HIPAA), Legal, Financial  
**Status:** Active development, capstone project  

---

## CORE PRINCIPLE (MEMORIZE THIS)

**Sensitive data NEVER leaves local infrastructure.**

The 3-Tier Routing System (Shay's design):
- **Tier 1 (HIGH RISK)** → LOCAL ONLY (SSN, names, medical data, credentials)
- **Tier 2 (MEDIUM RISK)** → Anonymize → Cloud allowed (IPs, device IDs)
- **Tier 3 (SAFE)** → Cloud allowed (general questions)

---

## TEAM CONTRIBUTIONS

### Sheniese (Shay) - Project Lead, Security Architecture
**Role:** Project lead, 3-tier routing design, HIPAA compliance
**Files:** `orchestrator/sensitive_routing.py`
**Key contributions:**
- Designed and implemented 3-tier classification system
- HIPAA 18 Safe Harbor identifier coverage
- Fail-closed error handling architecture
- Security audit and gap identification
- Confidence thresholds for detection
- Anonymization pipeline for Tier 2 data

### Shifty - Infrastructure and DevOps
**Role:** Infrastructure setup, orchestration, hardware configuration
**Key contributions:**
- Distributed architecture implementation
- Tailscale mesh networking configuration
- Orchestrator service development
- Setup automation scripts
- CI/CD pipeline

### Javier Acosta - Integration and UI
**Role:** Presidio integration, user interface, cloud integration
**Key contributions:**
- Microsoft Presidio PII detection integration
- Streamlit visualization UI
- AWS Bedrock cloud integration
- Visual feedback for routing decisions

---

## HARDWARE INVENTORY (MEMORIZE THIS)

| Hostname | Hardware | OS | Role | Port | Software |
|----------|----------|-----|------|------|----------|
| **nexus** | Mac Mini M4 Pro 48GB | macOS | Command center | 8000 | Orchestrator |
| **kali-nexus** | VM on Nexus | Kali Linux | Security scanning | 8080 | Security API |
| **phantom** | Dell XPS Snapdragon 64GB | Windows 11 | Mobile command | - | Backup |
| **aegis** | Ryzen 9950X + RTX 4080 Super | Windows 11 Pro | PRIMARY inference | 8080 | **llama.cpp** |
| **ryzen-ai** | Ryzen AI 395 + 128GB RAM | Windows 11 Pro (USB-C) | Multi-model | 11434 | Ollama |

### CRITICAL SPECS TO REMEMBER

1. **Aegis uses llama.cpp** (NOT Ollama) on port **8080**
2. **Ryzen-AI runs from external USB-C drive** with ImDisk RAMDisk
3. **All machines connected via Tailscale mesh VPN**
4. **SSH keys originate from Nexus only**
5. **Game Ready drivers on Aegis include CUDA runtime** (no separate install)

---

## 3-TIER ROUTING DETAILS (Shay's System)

### Tier 1 Entities (HIGH RISK - LOCAL ONLY)
```python
TIER_1_ENTITIES = {
    # HIPAA Identifiers
    "PERSON", "EMAIL_ADDRESS", "PHONE_NUMBER", "US_SSN",
    "DATE_TIME", "LOCATION", "ADDRESS", "ZIP_CODE",
    
    # Medical
    "MEDICAL_LICENSE", "US_DRIVER_LICENSE", "PASSPORT",
    
    # Financial
    "CREDIT_CARD", "BANK_ACCOUNT", "IBAN_CODE",
    
    # Credentials
    "PASSWORD", "API_KEY", "SECRET_KEY", "ACCESS_TOKEN",
}
```

### Tier 2 Entities (MEDIUM RISK - ANONYMIZE)
```python
TIER_2_ENTITIES = {
    "IP_ADDRESS", "MAC_ADDRESS", "DEVICE_ID", "HOSTNAME",
    "EMPLOYEE_ID", "VENDOR_ID", "PROJECT_CODE", "TICKET_ID",
}
```

### HIPAA Keywords (Elevate to Tier 1)
```python
HIPAA_KEYWORDS = {
    "patient", "diagnosis", "prognosis", "treatment", 
    "prescription", "medication", "symptoms", "vitals",
    "medical history", "hipaa", "phi", "ehr", "emr",
}
```

---

## API ENDPOINTS

### Orchestrator (http://nexus:8000)
```
GET  /health              - Health check
GET  /backends            - List backends with status
POST /v1/chat/completions - OpenAI-compatible (routes based on sensitivity)
POST /analyze             - Analyze text sensitivity without inference
```

### Aegis (http://aegis:8080) - llama.cpp
```
GET  /health              - Health check
POST /v1/chat/completions - OpenAI-compatible chat
POST /completion          - Native llama.cpp endpoint
```

### Ryzen-AI (http://ryzen-ai:11434) - Ollama
```
GET  /api/tags            - List models
POST /api/chat            - Chat with model
POST /api/embeddings      - Generate embeddings
```

---

## FILE STRUCTURE

```
zero-trust-hybrid-ai/
├── orchestrator/
│   ├── main.py                    # FastAPI orchestrator
│   ├── sensitive_routing.py       # Shay's 3-tier routing
│   └── requirements.txt           # Includes Presidio
│
├── inference-nodes/
│   ├── aegis/setup-aegis.ps1      # llama.cpp on Windows
│   └── ryzen-ai/setup-ryzen-ai.ps1  # Ollama + RAMDisk
│
├── setup-scripts/
│   ├── distribute-setup.sh        # SSH key distribution
│   ├── setup-kali-nexus.sh        # Security tools
│   └── setup-phantom.ps1          # Windows SSH
│
├── PROJECT_CONTEXT.md             # THIS FILE - commit to memory
├── CLAUDE_CODE_PROMPT.md          # Task instructions
└── README_COMPREHENSIVE.md        # Full team documentation
```

---

## REMEMBER THESE FACTS

1. **3-tier routing** (not binary) - Shay's contribution
2. **Aegis = llama.cpp on port 8080** (NOT Ollama)
3. **Ryzen-AI = Ollama on port 11434** (USB-C drive, RAMDisk)
4. **PHI detection uses Presidio + keyword matching**
5. **All audit logs use anonymized text only**
6. **Tailscale mesh VPN** for all inter-machine communication
7. **SSH keys originate from Nexus Mac Mini**
8. **Cloud receives NO Tier 1 data ever**

---

## WHEN HELPING WITH THIS PROJECT

1. Always use the 3-tier routing system for sensitive data decisions
2. Remember Aegis uses llama.cpp (port 8080), not Ollama
3. Check sensitivity before suggesting cloud services
4. Reference Shay's `sensitive_routing.py` for PHI detection
5. Use Tailscale hostnames (aegis, ryzen-ai, kali-nexus, phantom)
6. Validate SSH connectivity before remote operations
7. Test with: `curl http://aegis:8080/health`

---

*Commit this context to memory for consistent project assistance.*
