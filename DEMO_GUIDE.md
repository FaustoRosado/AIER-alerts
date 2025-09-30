# Demo Guide - Zero-Trust Hybrid AI Pipeline

A linear walkthrough for live demos. Follow top to bottom - no scrolling back.

---

## PART 1: SETUP (Before the Demo)

### Open Two Terminals

| Terminal | Purpose | Where |
|----------|---------|-------|
| Terminal 1 | Orchestrator (stays running) | Must be in project folder |
| Terminal 2 | curl commands | Anywhere is fine |

### Terminal 1: Start the Orchestrator

```bash
cd /Volumes/Exchange/projects/zero-trust-hybrid-ai/orchestrator && source venv/bin/activate && python main.py
```

**What you just typed:**
- `cd ...` = Go to project folder
- `source venv/bin/activate` = Activate Python virtual environment (isolated packages)
- `python main.py` = Start the server

**What is venv?** A virtual environment keeps this project's Python packages separate from other projects. The `(venv)` prefix in your prompt means it's active.

**You should see:**
```
Orchestrator started. Backend status:
   Aegis (RTX 4080 Super): [online]
   Ryzen-AI (Ryzen AI 395): [online]
   Nexus (Mac Mini M4 Pro): [online]
```

### Terminal 2: Open New Tab

Press `Cmd+T` for a new tab. Stay in home directory - curl commands work from anywhere.

---

## PART 2: DEMO - BASIC INFERENCE

### Show: Simple Question (Human Readable)

```bash
curl -s -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"What is HIPAA?"}]}' \
  | jq -r '.choices[0].message.content'
```

**What this command does:**
| Part | Meaning |
|------|---------|
| `curl` | Command-line tool to make web requests |
| `-s` | Silent mode (no progress bar) |
| `-X POST` | Send data to server (not just fetch) |
| `http://localhost:8000/...` | Our orchestrator running locally |
| `-H "Content-Type: application/json"` | Tell server we're sending JSON |
| `-d '{...}'` | The JSON data (our question) |
| `\| jq -r '.choices[0].message.content'` | Extract just the answer text |

**The JSON explained:**
```json
{
  "messages": [
    {"role": "user", "content": "What is HIPAA?"}
  ]
}
```

| Field | What it means |
|-------|---------------|
| `messages` | Array of conversation messages |
| `role` | Who is speaking: "user", "system", or "assistant" |
| `content` | The actual text |

---

## PART 3: DEMO - PHI DETECTION (The Core Feature)

### Show: Sensitive Data Gets Detected

**Run this in Terminal 2:**
```bash
curl -s -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Patient John Smith SSN 123-45-6789 has diabetes"}]}' \
  | jq -r '.choices[0].message.content'
```

**Now look at Terminal 1 (orchestrator logs):**
```
Request analysis: route=local, tier0_protected=True, tier1_high=2, tier2_medium=0, tier3_clear=False
```

**Explain what they see:**
| Log Field | Meaning |
|-----------|---------|
| `route=local` | PHI detected - stays on local network |
| `tier0_protected=True` | Healthcare context detected (keyword match) |
| `tier1_high=2` | Found 2 high-risk entities (name + SSN) |
| `tier2_medium=0` | Zero medium-risk entities |
| `tier3_clear=False` | Not safe for cloud |

**This is the core feature:** The orchestrator automatically detected PHI and kept it local. No configuration needed.

### The 4-Tier Classification System

| Tier | Name | What Triggers It | Routing Decision |
|------|------|------------------|------------------|
| tier0 | PROTECTED | Keyword match (patient, diagnosis, vitals) | LOCAL ONLY |
| tier1 | HIGH | Presidio: SSN, names, credentials, financial | LOCAL ONLY |
| tier2 | MEDIUM | Presidio: IPs, device IDs, hostnames | ANONYMIZE -> cloud |
| tier3 | CLEAR | Nothing detected | ANY backend |

**Note:** See `demo/TIER_SYSTEM_EXPLAINED.md` for detailed technical explanation.

### Compare: Safe vs Sensitive

**Safe query (no PHI):**
```bash
curl -s -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"What is Kubernetes?"}]}' \
  | jq -r '.choices[0].message.content'
```
Log shows: `tier1_high=0, tier2_medium=0, tier3_clear=True` - No sensitive data detected.

**Sensitive query:**
```bash
curl -s -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Patient SSN 123-45-6789"}]}' \
  | jq -r '.choices[0].message.content'
```
Log shows: `tier1_high=1, tier0_protected=True` - SSN detected, routes local.

---

## PART 4: DEMO - THE THREE ROLES

### Why We Need Roles

The AI needs to know who is speaking:

| Role | Who | Purpose |
|------|-----|---------|
| `system` | You (developer) | Set personality/rules BEFORE conversation |
| `user` | Human asking | The question or request |
| `assistant` | AI's previous response | For conversation memory |

### Show: Without System Prompt

```bash
curl -s -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Explain HIPAA"}]}' \
  | jq -r '.choices[0].message.content'
```

### Show: With System Prompt (Changes Behavior)

```bash
curl -s -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"system","content":"Explain everything like Im 5 years old"},{"role":"user","content":"Explain HIPAA"}]}' \
  | jq -r '.choices[0].message.content'
```

**The difference:** System prompt made it explain simply. Same question, different answer.

### Show: Conversation Memory (Multi-turn)

```bash
curl -s -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"What is HIPAA?"},{"role":"assistant","content":"HIPAA is the Health Insurance Portability and Accountability Act."},{"role":"user","content":"Give me an example of a violation."}]}' \
  | jq -r '.choices[0].message.content'
```

**Explain:** The AI sees the full conversation history. It knows "violation" refers to HIPAA because we included the previous exchange.

---

## PART 5: DEMO - AI PARAMETERS (Optimizers)

### Temperature: Creativity Control

```
0.0 -------- 0.5 -------- 1.0
 |            |            |
Robotic    Balanced    Creative
Same answer            Different
every time             each time
```

**Low temperature (deterministic):**
```bash
curl -s -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"temperature":0.1,"messages":[{"role":"user","content":"Name one color"}]}' \
  | jq -r '.choices[0].message.content'
```
Run 3 times - same answer each time.

**High temperature (creative):**
```bash
curl -s -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"temperature":1.0,"messages":[{"role":"user","content":"Name one color"}]}' \
  | jq -r '.choices[0].message.content'
```
Run 3 times - different answers.

### Max Tokens: Response Length

**Short response (50 tokens):**
```bash
curl -s -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"max_tokens":50,"messages":[{"role":"user","content":"Explain HIPAA in detail"}]}' \
  | jq -r '.choices[0].message.content'
```

**Long response (1000 tokens):**
```bash
curl -s -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"max_tokens":1000,"messages":[{"role":"user","content":"Explain HIPAA in detail"}]}' \
  | jq -r '.choices[0].message.content'
```

### All Parameters Quick Reference

| Parameter | Default | Range | Effect |
|-----------|---------|-------|--------|
| `temperature` | 0.7 | 0.0 - 2.0 | Creativity (higher = more random) |
| `max_tokens` | 2048 | 1 - 8192 | Response length limit |
| `top_p` | 1.0 | 0.0 - 1.0 | Alternative to temperature |
| `frequency_penalty` | 0.0 | -2.0 - 2.0 | Reduce word repetition |
| `presence_penalty` | 0.0 | -2.0 - 2.0 | Encourage new topics |

---

## PART 6: DEMO - BACKEND ROUTING

### Show: Health Check

```bash
curl -s http://localhost:8000/backends?refresh=true | python3 -m json.tool
```

**Output:**
```json
{
  "backends": [
    {"id": "aegis", "status": "online", "latency_ms": 45.2},
    {"id": "ryzen-ai", "status": "online", "latency_ms": 62.1},
    {"id": "nexus", "status": "online", "latency_ms": 2.3}
  ]
}
```

### Our Machines

| Machine | Hostname | What Runs | Speed |
|---------|----------|-----------|-------|
| RTX 4080 Super PC | aegis | llama.cpp + Llama 3.1 8B | 70-90 tok/s |
| 128GB Ryzen Laptop | ryzen-ai | Ollama (multi-model) | 8-15 tok/s |
| Mac Mini M4 Pro | nexus | Orchestrator | - |

### Show: Force Specific Backend

```bash
curl -s -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"preferred_backend":"ryzen-ai","messages":[{"role":"user","content":"Hello"}]}' \
  | jq -r '.choices[0].message.content'
```

Check Terminal 1 logs - it shows which backend handled the request.

### Show: Code Task (Routes to Ryzen-AI)

```bash
curl -s -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"task_type":"code","messages":[{"role":"user","content":"Write hello world in Python"}]}' \
  | jq -r '.choices[0].message.content'
```

Code tasks route to Ryzen-AI because it runs Qwen2.5-Coder (code-specialized model).

---

## PART 7: WHY WE BUILT IT THIS WAY

### Why JSON Format?

**Q: Why not just send plain text?**

| Format | Example | Problem |
|--------|---------|---------|
| Plain text | "What is HIPAA?" | No way to set temperature, roles, etc. |
| JSON | `{"messages":[...], "temperature":0.7}` | Structured, can include all options |

### Why OpenAI Format?

We use the same format as OpenAI/ChatGPT:
```json
{"model":"auto","messages":[{"role":"user","content":"Hello"}]}
```

**Why:** Every AI tool (Cursor, LangChain, etc.) already speaks this format. We're compatible with everything.

### Why Local LLMs?

| Reason | Benefit |
|--------|---------|
| PHI never leaves network | HIPAA compliant |
| No API costs | Free inference |
| Works offline | No internet dependency |
| Fast | 50-100ms latency vs 500-2000ms cloud |

### Why Separate Orchestrator?

```
User Request → Orchestrator → Scans for PHI → Routes to Backend
                    ↓
              Aegis OR Ryzen-AI
```

Orchestrator handles security/routing. Backends just run models. If one backend dies, others keep working.

---

## PART 8: WHAT'S NEXT (Hybrid Cloud)

### Current State (100% Local)

```
+------------------+
|  Your Network    |
|  Nexus → Aegis   |
|       → Ryzen-AI |
+------------------+
       X  ← No cloud
```

### Future State (Hybrid)

```
+------------------+          +------------------+
|  Your Network    |  Tier 3  |  Cloud           |
|  Nexus → Aegis   | -------> |  Cloud LLM API   |
|       → Ryzen-AI |          |                  |
+------------------+          +------------------+
   PHI stays here              Safe queries only
```

### What's Done vs Future

| Feature | Status |
|---------|--------|
| Local inference | Done |
| PHI detection | Done |
| 3-tier routing | Done |
| Cloud integration | Future |
| Anonymization | Future |
| Web UI | Future |

---

## QUICK REFERENCE - COPY/PASTE COMMANDS

### Setup
```bash
# Start orchestrator (Terminal 1)
cd /Volumes/Exchange/projects/zero-trust-hybrid-ai/orchestrator && source venv/bin/activate && python main.py
```

### Basic Tests
```bash
# Health check
curl http://localhost:8000/health

# Simple question
curl -s -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"What is HIPAA?"}]}' \
  | jq -r '.choices[0].message.content'

# PHI test (watch logs)
curl -s -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Patient SSN 123-45-6789"}]}' \
  | jq -r '.choices[0].message.content'
```

### Role Examples
```bash
# With system prompt
curl -s -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"system","content":"Be very brief"},{"role":"user","content":"What is HIPAA?"}]}' \
  | jq -r '.choices[0].message.content'

# With personality
curl -s -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"system","content":"You are a pirate"},{"role":"user","content":"What is HIPAA?"}]}' \
  | jq -r '.choices[0].message.content'
```

### Parameter Examples
```bash
# Low temperature
curl -s -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"temperature":0.1,"messages":[{"role":"user","content":"Name one color"}]}' \
  | jq -r '.choices[0].message.content'

# High temperature
curl -s -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"temperature":1.0,"messages":[{"role":"user","content":"Name one color"}]}' \
  | jq -r '.choices[0].message.content'

# Short response
curl -s -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"max_tokens":50,"messages":[{"role":"user","content":"Explain HIPAA"}]}' \
  | jq -r '.choices[0].message.content'
```

### Backend Examples
```bash
# Check backends
curl -s http://localhost:8000/backends?refresh=true | python3 -m json.tool

# Force specific backend
curl -s -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"preferred_backend":"aegis","messages":[{"role":"user","content":"Hello"}]}' \
  | jq -r '.choices[0].message.content'

# Code task
curl -s -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"task_type":"code","messages":[{"role":"user","content":"Write hello world in Python"}]}' \
  | jq -r '.choices[0].message.content'
```

---

## TROUBLESHOOTING

### "No module named 'fastapi'"
You forgot to activate venv:
```bash
source venv/bin/activate
```

### "Connection refused"
Orchestrator not running. Start it in Terminal 1.

### "jq: command not found"
Install jq:
```bash
brew install jq
```

### Slow responses
- Aegis should be 70-90 tok/s
- Ryzen-AI is 8-15 tok/s (CPU, normal to be slower)

---

## TEAM

- **Shay (Sheniese Aracena-Baez)** - 3-tier routing, HIPAA compliance
- **Shifty** - Infrastructure, orchestration, hardware
- **Javier Acosta** - Presidio integration, Streamlit UI
