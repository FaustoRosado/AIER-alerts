# Zero-Trust Hybrid AI Pipeline
## 15-Minute Demo Script for Cyber Security Fellows

---

## Pre-Demo Checklist

Before starting, verify:
- [ ] Orchestrator running: `curl http://localhost:8000/health`
- [ ] Ollama responding: `curl http://localhost:11434/api/tags`
- [ ] Terminal windows positioned (one for commands, one for logs)
- [ ] Browser tabs ready for slides/diagrams

---

## [0:00 - 2:00] Introduction: The Problem

### Slide 1: The Healthcare AI Dilemma

**SAY:**
> "Healthcare organizations face a critical challenge: they need AI capabilities to improve patient care, but sending Protected Health Information to cloud AI services creates massive compliance and security risks."

**SHOW (statistics):**
- 725 healthcare breaches in 2023 affecting 133M records
- Average healthcare breach cost: $10.93 million
- HIPAA violations: $100-$50,000 per violation, up to $1.5M annually

**SAY:**
> "The Ascension Health ransomware attack in 2024 showed how centralized systems become single points of failure. When their systems went down, clinicians had to revert to paper processes."

### Slide 2: Why Not Just Use Cloud AI?

**SAY:**
> "Can't we just use ChatGPT or Claude for healthcare? Let's look at why that's problematic."

**SHOW (table):**

| Cloud AI Service | BAA Available? | PHI Processing? |
|------------------|----------------|-----------------|
| OpenAI (ChatGPT) | ❌ No | ❌ Prohibited |
| Anthropic (Claude API) | ✅ Yes (Enterprise) | ⚠️ Limited |
| Google (Gemini) | ⚠️ Workspace only | ⚠️ Limited |
| AWS Bedrock | ✅ Yes | ✅ With controls |

**SAY:**
> "Even with a BAA, you're trusting that the cloud provider's security is perfect. One misconfiguration, one breach, and your patients' data is exposed. Our solution: keep PHI local, leverage cloud for everything else."

---

## [2:00 - 5:00] Architecture Walkthrough

### Slide 3: Zero-Trust Hybrid Architecture

**SHOW (architecture diagram from README):**

```
┌─────────────────────────────────────────────────────────────────┐
│                     LOCAL TRUST ZONE                             │
│                                                                  │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐                   │
│  │  Aegis   │    │Ryzen-AI│    │ Mac Mini │                   │
│  │   GPU    │    │   NPU    │    │   M4 Pro │                   │
│  │ 70tok/s  │    │ MultiMod │    │ 35tok/s  │                   │
│  └────┬─────┘    └────┬─────┘    └────┬─────┘                   │
│       │               │               │                          │
│       └───────────┬───┴───────────────┘                          │
│                   │                                              │
│           ┌───────┴───────┐                                      │
│           │  ORCHESTRATOR │                                      │
│           │  Smart Router │                                      │
│           └───────┬───────┘                                      │
│                   │                                              │
│  ═══════════════════════════════════════════════════════════    │
│            ZERO-TRUST BOUNDARY - PHI STOPS HERE                  │
│  ═══════════════════════════════════════════════════════════    │
└───────────────────┼─────────────────────────────────────────────┘
                    │ (anonymized only)
                    ▼
          ┌─────────────────────┐
          │    CLOUD SERVICES   │
          │   DevSecOps, Logs   │
          │   ❌ NO PHI EVER    │
          └─────────────────────┘
```

**SAY:**
> "This is our Zero-Trust Hybrid Architecture. Let me walk you through the key principles."

**EXPLAIN:**
1. **Local Trust Zone**: All PHI processing happens here. We control the hardware, the software, the network.
2. **Multiple Inference Nodes**: Not just one AI—we have specialized models for different tasks.
3. **Orchestrator**: Intelligent routing based on task type, not just load balancing.
4. **Zero-Trust Boundary**: This line is inviolable. PHI never crosses it.
5. **Cloud Services**: DevOps automation, monitoring, logging—but never patient data.

### Slide 4: Hardware Role Assignment

**SHOW (hardware table):**

| Machine | Role | Why This Role? |
|---------|------|----------------|
| **Aegis** (RTX 4080) | Primary Inference | 736 GB/s bandwidth = fastest |
| **Ryzen-AI** (128GB) | Multi-Model Specialist | Keeps 6 models loaded |
| **Mac Mini** (48GB) | Orchestrator + Backup | Always-on coordination |
| **Phantom** (Snapdragon) | Mobile Command | Direct from anywhere |

**SAY:**
> "Notice Aegis has only 16GB VRAM but is our primary inference node. Why? Memory *bandwidth*, not capacity. The RTX 4080's 736 GB/s crushes DDR5's 90 GB/s. Ryzen-AI wins on multi-model—128GB means zero reload delays."

---

## [5:00 - 9:00] Live Demo: Local Inference

### Demo 1: Check System Status

**TYPE (in terminal):**
```bash
curl http://localhost:8000/backends | jq
```

**EXPECTED OUTPUT:**
```json
{
  "backends": [
    {
      "id": "aegis",
      "name": "Aegis (RTX 4080 Super)",
      "status": "online",
      "latency_ms": 12.5
    },
    {
      "id": "ryzen-ai", 
      "name": "Ryzen-AI (Ryzen AI 395)",
      "status": "online",
      "latency_ms": 18.2
    }
  ]
}
```

**SAY:**
> "All backends online. The orchestrator constantly monitors their health and will route around failures."

### Demo 2: Process Sensitive Data Locally

**TYPE:**
```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{
      "role": "user",
      "content": "Patient John Doe, DOB 1955-03-15, presents with chest pain radiating to left arm, BP 180/110, HR 112. Classify urgency."
    }]
  }' | jq
```

**WHILE RUNNING, SAY:**
> "Watch this request. It contains obvious PHI—patient name, date of birth, symptoms. This is being processed entirely on our local Aegis node."

**SHOW RESPONSE:**
```json
{
  "choices": [{
    "message": {
      "content": "URGENT - HIGH PRIORITY\n\nThis presentation suggests possible acute coronary syndrome..."
    }
  }],
  "orchestration": {
    "backend": "aegis",
    "model": "llama-3.1-8b",
    "latency_ms": 847
  }
}
```

**SAY:**
> "Notice the response metadata: processed by Aegis using Llama 3.1 8B in 847ms. That patient data never left our network."

### Demo 3: Show Logs Proving Local Processing

**TYPE (in second terminal):**
```bash
docker logs ollama-gpu 2>&1 | tail -20
```

**SAY:**
> "These logs show the inference happening on our local GPU. No cloud API calls. No data exfiltration. Complete privacy."

---

## [9:00 - 12:00] Validation Pipeline Demo

### Demo 4: Validation with Second Model

**SAY:**
> "One model can make mistakes. Our architecture uses a validation pipeline—expensive generation on the fast model, thorough review on a reasoning model."

**TYPE:**
```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{
      "role": "user",
      "content": "Write a Python function to validate patient SSN format"
    }],
    "task_type": "code",
    "require_validation": true
  }' | jq
```

**SHOW RESPONSE:**
```json
{
  "choices": [{
    "message": {
      "content": "```python\nimport re\n\ndef validate_ssn(ssn: str) -> bool:\n    pattern = r'^\\d{3}-\\d{2}-\\d{4}$'\n    return bool(re.match(pattern, ssn))\n```"
    }
  }],
  "orchestration": {
    "backend": "ryzen-ai",
    "model": "qwen2.5-coder:7b",
    "latency_ms": 2340,
    "validation": {
      "valid": true,
      "confidence": 0.92,
      "issues": []
    }
  }
}
```

**SAY:**
> "This request went to Ryzen-AI's Qwen2.5-Coder specialist. Then Phi-3 14B validated the output—checking for security issues, logic errors, best practices. Two models, double-checked, all local."

### Demo 5: Multi-Model Instant Switching

**SAY:**
> "Ryzen-AI keeps 6 models loaded in 128GB RAM. Watch how fast we can switch."

**TYPE:**
```bash
# First model
time curl -s http://ryzen-ai:11434/api/chat -d '{"model":"qwen2.5-coder:7b","messages":[{"role":"user","content":"hi"}]}'

# Immediate switch to different model
time curl -s http://ryzen-ai:11434/api/chat -d '{"model":"phi3:14b","messages":[{"role":"user","content":"hi"}]}'
```

**SAY:**
> "Sub-second model switching. No loading delays. This is the Scenario 4 architecture—specialized models for specialized tasks, all instantly available."

---

## [12:00 - 14:00] Security Deep Dive

### Slide 5: Zero-Trust Network Architecture

**SHOW (network diagram):**

```
┌────────────────────────────────────────────────────────────┐
│                    TAILSCALE MESH VPN                       │
│                                                             │
│    ┌─────────┐      ┌─────────┐      ┌─────────┐          │
│    │ Phantom │◄────►│ Mac Mini│◄────►│  Aegis  │          │
│    │ 100.x.x │      │ 100.x.x │      │ 100.x.x │          │
│    └─────────┘      └─────────┘      └─────────┘          │
│         │                │                │                │
│         └────────────────┼────────────────┘                │
│                          │                                  │
│                    ┌─────┴─────┐                           │
│                    │Ryzen-AI │                           │
│                    │ 100.x.x   │                           │
│                    └───────────┘                           │
│                                                             │
│    ACL: Only orchestrator can reach inference nodes        │
│    ACL: Inference nodes can validate each other            │
│    ACL: External access BLOCKED by default                 │
└────────────────────────────────────────────────────────────┘
```

**SAY:**
> "Tailscale provides WireGuard encryption between all nodes. ACLs enforce that only authorized machines can reach inference endpoints. No public internet exposure."

### Slide 6: HIPAA Compliance Mapping

**SHOW (compliance table):**

| HIPAA Requirement | Our Implementation |
|-------------------|-------------------|
| Access Controls (164.312(a)) | Tailscale ACLs + SSH keys |
| Audit Controls (164.312(b)) | All requests logged locally |
| Integrity Controls (164.312(c)) | Validation pipeline |
| Transmission Security (164.312(e)) | WireGuard encryption |
| Encryption at Rest | BitLocker/LUKS on all nodes |

**SAY:**
> "Because PHI never leaves our controlled infrastructure, we satisfy HIPAA requirements without needing BAAs with cloud AI providers. We are the covered entity's own infrastructure."

---

## [14:00 - 15:00] Wrap-Up & Next Steps

### Slide 7: Key Takeaways

**SAY:**
> "Let me leave you with three key takeaways..."

1. **Zero-Trust = Zero Exceptions**: PHI never crosses the boundary. Period.
2. **Local ≠ Slow**: Our RTX 4080 hits 70-90 tok/s—faster than most cloud APIs.
3. **Multi-Model > Single Model**: Specialized models + validation = better outcomes.

### Slide 8: Try It Yourself

**SHOW:**
```
GitHub Repository:
  github.com/your-org/zero-trust-hybrid-ai

Quick Start (Codespaces):
  Click "Open in Codespaces" badge
  Wait 3 minutes
  Demo ready!

For Your Own Hardware:
  1. Install Tailscale on all machines
  2. Clone repo, run setup scripts
  3. Start orchestrator
  4. Configure your AI IDE
```

### Questions?

**SAY:**
> "That's our Zero-Trust Hybrid AI Pipeline. Questions?"

**COMMON QUESTIONS:**

**Q: How does this compare to AWS Bedrock with HIPAA?**
> A: Bedrock requires BAAs and shared responsibility. Our approach gives you complete control—you own the entire chain of custody.

**Q: What if my GPU dies?**
> A: The orchestrator automatically routes to the next available backend. Mac Mini and Ryzen-AI provide redundancy.

**Q: Can this scale to a hospital?**
> A: Yes—add more inference nodes, put the orchestrator behind a load balancer. The architecture scales horizontally.

**Q: How hard is this to maintain?**
> A: Easier than a Kubernetes cluster. Tailscale handles networking. Systemd handles services. Updates are `git pull && docker compose up`.

---

## Demo Fallback Scripts

If something goes wrong during the live demo:

### Fallback 1: Orchestrator Not Responding

```bash
# Check if running
docker ps | grep orchestrator

# Restart if needed
docker compose -f docker/docker-compose.yml restart orchestrator

# Or start from scratch
docker compose -f docker/docker-compose.yml --profile demo up -d
```

### Fallback 2: Ollama Not Responding

```bash
# Check Ollama container
docker logs ollama-gpu 2>&1 | tail -20

# Restart Ollama
docker restart ollama-gpu

# Pull model if missing
docker exec ollama-gpu ollama pull llama3.2:3b
```

### Fallback 3: Network Issues

```bash
# Check Tailscale status
tailscale status

# Force reconnect
tailscale down && tailscale up

# Test direct connectivity
ping aegis
curl http://aegis:8080/health
```

---

## Post-Demo Resources

Share with students:
- GitHub repo link
- This demo script (sanitized)
- Architecture diagrams
- Reading list:
  - HIPAA Security Rule guidance
  - Tailscale ACL documentation
  - llama.cpp performance tuning

---

*Demo script version 1.0 - Updated for 48GB Mac Mini M4 Pro spec*
