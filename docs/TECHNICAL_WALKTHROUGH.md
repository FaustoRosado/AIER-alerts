# Zero-Trust Hybrid AI Pipeline: Technical Walkthrough

**A Beginner-Friendly Deep Dive for Capstone Teammates**

Written by Shifty | December 2025

---

## Table of Contents

1. [The Big Picture: What Are We Building?](#the-big-picture)
2. [Cloud vs Local AI: The Core Tradeoff](#cloud-vs-local)
3. [LLM Primer: Models, Parameters, and Tokens](#llm-primer)
4. [Why 5 Machines? The "Distributed AI" Concept](#why-5-machines)
5. [The Network: How Machines Talk to Each Other](#the-network)
6. [Setting Up Remote Machines: SSH Deep Dive](#ssh-deep-dive)
7. [Installing Ollama: Package Management Across OSes](#installing-ollama)
8. [The One-Liner Philosophy: Why We Script This Way](#one-liner-philosophy)
9. [Model Pulling: What's Actually Happening](#model-pulling)
10. [The Orchestrator: Traffic Cop for AI](#the-orchestrator)
11. [Troubleshooting War Stories](#troubleshooting)
12. [For Your Capstone Presentation](#capstone-notes)

---

## The Big Picture: What Are We Building? <a name="the-big-picture"></a>

Imagine you're running a hospital. You have patient data (super sensitive), IT logs (kinda sensitive), and general questions ("what's the weather?"). You wouldn't send patient data to Google, right?

That's our problem. We want AI assistance, but we need to control WHERE that data goes.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        THE ZERO-TRUST CONCEPT                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   "Never trust, always verify"                                              │
│                                                                             │
│   Traditional:  User ──► Cloud AI ──► Response                              │
│                         (data leaves your control)                          │
│                                                                             │
│   Zero-Trust:   User ──► [ANALYZE] ──► Is this sensitive?                   │
│                              │                                              │
│                              ├── YES ──► Local AI (never leaves building)   │
│                              │                                              │
│                              └── NO ───► Cloud OK (if configured)           │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### The 3-Tier Sensitivity Model (Shay's Contribution)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          SENSITIVITY TIERS                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   TIER 1 - HIGH RISK (RED)          Examples:                               │
│   ├── SSN, Names, Medical Records   "Patient John Smith SSN 123-45-6789"    │
│   ├── HIPAA-covered data             ──► ALWAYS stays local, no exceptions  │
│   └── Route: LOCAL ONLY                                                     │
│                                                                             │
│   TIER 2 - MEDIUM RISK (YELLOW)     Examples:                               │
│   ├── IP addresses, Device IDs      "Error from 192.168.1.50"               │
│   ├── Could identify someone         ──► Anonymize first, then cloud OK     │
│   └── Route: ANONYMIZE → CLOUD OK                                           │
│                                                                             │
│   TIER 3 - SAFE (GREEN)             Examples:                               │
│   ├── General questions             "How do I write a for loop?"            │
│   ├── No identifying info            ──► Cloud is fine                      │
│   └── Route: CLOUD ALLOWED                                                  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Cloud vs Local AI: The Core Tradeoff <a name="cloud-vs-local"></a>

Before we dive into the technical stuff, let's understand WHY we're doing this at all.

### How Cloud AI Works (ChatGPT, Claude, etc.)

When you use ChatGPT, here's what actually happens:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          CLOUD AI WORKFLOW                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   YOUR DEVICE                    THE INTERNET              OPENAI'S SERVERS │
│   ┌──────────┐                  ┌───────────┐              ┌──────────────┐ │
│   │          │   Your prompt    │           │  Your prompt │              │ │
│   │ "Explain │ ────────────────►│  Routers  │─────────────►│   GPT-4      │ │
│   │  HIPAA"  │                  │  Cables   │              │   (MASSIVE)  │ │
│   │          │                  │  ISPs     │              │              │ │
│   │          │◄─────────────────│           │◄─────────────│  175 BILLION │ │
│   │          │   The response   │           │   Response   │  parameters  │ │
│   └──────────┘                  └───────────┘              └──────────────┘ │
│                                                                             │
│   What you DON'T control:                                                   │
│   - Where your data is stored                                               │
│   - Who can read it (OpenAI employees, subpoenas, breaches)                 │
│   - How long it's retained                                                  │
│   - Whether it trains future models                                         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### How Local AI Works (What We Built)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          LOCAL AI WORKFLOW                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   YOUR DEVICE                         YOUR HARDWARE (same building/network) │
│   ┌──────────┐                        ┌────────────────────────────────────┐│
│   │          │   Your prompt          │                                    ││
│   │ "Patient │ ──────────────────────►│   Llama 3.1 8B                     ││
│   │  John    │   (never leaves        │   (running on YOUR GPU)            ││
│   │  Smith"  │    your network)       │                                    ││
│   │          │◄──────────────────────│   8 BILLION parameters             ││
│   │          │   Response             │   (fits in 16GB VRAM)              ││
│   └──────────┘                        └────────────────────────────────────┘│
│                                                                             │
│   What you DO control:                                                      │
│   - Data never leaves your infrastructure                                   │
│   - No third party ever sees it                                             │
│   - You own the hardware, you control retention                             │
│   - No usage fees (you already bought the GPU)                              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### The Tradeoff Table

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      CLOUD VS LOCAL: THE REAL TALK                          │
├────────────────────┬─────────────────────────┬──────────────────────────────┤
│                    │      CLOUD AI           │       LOCAL AI               │
├────────────────────┼─────────────────────────┼──────────────────────────────┤
│ Model Size         │ MASSIVE (175B-1T+)      │ Smaller (3B-70B typically)   │
│                    │ Can't run this at home  │ Fits on consumer hardware    │
├────────────────────┼─────────────────────────┼──────────────────────────────┤
│ Quality            │ Best available          │ "Good enough" to excellent   │
│                    │ (for now)               │ Rapidly improving            │
├────────────────────┼─────────────────────────┼──────────────────────────────┤
│ Speed              │ 50-100 tokens/sec       │ 8-90 tokens/sec              │
│                    │ (depends on tier)       │ (depends on hardware)        │
├────────────────────┼─────────────────────────┼──────────────────────────────┤
│ Cost               │ $0.01-0.10 per 1K tok   │ FREE after hardware          │
│                    │ (adds up fast)          │ (electricity only)           │
├────────────────────┼─────────────────────────┼──────────────────────────────┤
│ Privacy            │ ZERO                    │ TOTAL                        │
│                    │ They see everything     │ Never leaves your network    │
├────────────────────┼─────────────────────────┼──────────────────────────────┤
│ Compliance         │ Maybe? Check their ToS  │ YOU control compliance       │
│ (HIPAA, etc.)      │ Often NOT compliant     │ Can be fully compliant       │
├────────────────────┼─────────────────────────┼──────────────────────────────┤
│ Upfront Cost       │ $0                      │ $500-$5000+                  │
│                    │ (pay as you go)         │ (GPU, RAM, hardware)         │
├────────────────────┼─────────────────────────┼──────────────────────────────┤
│ Internet Required  │ YES, always             │ NO (fully offline capable)   │
└────────────────────┴─────────────────────────┴──────────────────────────────┘
```

### Why Local Matters for Healthcare/Finance/Gov

```
SCENARIO: Hospital IT department

Doctor types: "Patient John Smith, DOB 03/15/1982, diagnosed with HIV,
              prescribed Truvada. Review treatment plan."

CLOUD AI PATH:
  - This text travels over the internet
  - OpenAI's servers process it
  - Logged, possibly stored, possibly used for training
  - HIPAA VIOLATION - patient data left the covered entity

LOCAL AI PATH:
  - Text goes to YOUR server in YOUR data center
  - Processed on YOUR hardware
  - Never leaves the building
  - HIPAA COMPLIANT - data stayed within covered entity
```

---

## LLM Primer: Models, Parameters, and Tokens <a name="llm-primer"></a>

Let's break down the jargon. This is the stuff that makes AI people sound smart at parties.

### What IS a Large Language Model?

Think of an LLM as a very sophisticated autocomplete. You give it text, it predicts what comes next.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       LLM: THE AUTOCOMPLETE ANALOGY                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Your phone's autocomplete:                                                │
│   "I'll be there in" → [5 minutes] [10 minutes] [a bit]                     │
│                                                                             │
│   An LLM's autocomplete (but MUCH more sophisticated):                      │
│   "The mitochondria is" → "the powerhouse of the cell, responsible for..."  │
│                                                                             │
│   The difference? Scale and training.                                       │
│   - Phone: Trained on your texts                                            │
│   - LLM: Trained on the entire internet (trillions of words)                │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Parameters: The Model's "Brain Size"

Parameters are the numbers inside the model that determine its behavior. More parameters = more "knowledge capacity" but also more resources needed.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         MODEL SIZES EXPLAINED                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Model Name          Parameters    File Size    RAM Needed   Quality       │
│   ─────────────────────────────────────────────────────────────────────     │
│   llama3.2:3b         3 billion     2.0 GB       4-6 GB       Basic         │
│   codellama:7b        7 billion     3.8 GB       8-10 GB      Good          │
│   llama3.1:8b         8 billion     4.9 GB       10-12 GB     Good+         │
│   phi3:14b            14 billion    7.9 GB       16-20 GB     Very Good     │
│   llama3:70b          70 billion    40 GB        80+ GB       Excellent     │
│   GPT-4 (cloud)       ~1 trillion   ???          ???          Best (today)  │
│                                                                             │
│   THE RULE OF THUMB:                                                        │
│   - Disk space ≈ Parameters × 0.5-1.0 bytes (with compression)              │
│   - RAM needed ≈ Disk size × 1.2-2.0 (model loads into memory)              │
│   - Bigger = smarter but slower and hungrier                                │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Tokens: The Currency of AI

LLMs don't read words—they read "tokens." A token is roughly 3-4 characters or about 0.75 words.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           TOKENIZATION EXAMPLE                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Original text: "Hello, how are you doing today?"                          │
│                                                                             │
│   Tokenized:     [Hello] [,] [ how] [ are] [ you] [ doing] [ today] [?]     │
│                  Token 1  2    3      4      5       6        7      8      │
│                                                                             │
│   That's 8 tokens for 7 words.                                              │
│                                                                             │
│   ───────────────────────────────────────────────────────────────────────   │
│                                                                             │
│   Tricky cases:                                                             │
│   "ChatGPT" → [Chat] [G] [PT]     = 3 tokens (splits unusual words)         │
│   "123456"  → [123] [456]         = 2 tokens (numbers chunk weirdly)        │
│   "🎉"       → [🎉]                = 1 token (emoji = 1 token usually)       │
│                                                                             │
│   ───────────────────────────────────────────────────────────────────────   │
│                                                                             │
│   WHY TOKENS MATTER:                                                        │
│   - Cloud AI charges per token ($0.01 per 1,000 tokens = adds up)           │
│   - Context window measured in tokens (8K, 32K, 128K)                       │
│   - Speed measured in tokens/second (tok/s)                                 │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Context Window: The Model's "Memory"

The context window is how much text the model can "see" at once. This includes your prompt AND its response.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         CONTEXT WINDOW LIMITS                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                    8,192 TOKEN CONTEXT WINDOW                       │   │
│   ├─────────────────────────────────────────────────────────────────────┤   │
│   │ [System prompt: 200 tokens]                                         │   │
│   │ [Your question: 500 tokens]                                         │   │
│   │ [AI response: 2000 tokens]                                          │   │
│   │ [Your follow-up: 300 tokens]                                        │   │
│   │ [AI response: 1500 tokens]                                          │   │
│   │ [Your next question: 400 tokens]                                    │   │
│   │ [...]                                                               │   │
│   │                                                                     │   │
│   │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░ Used: 4900 / 8192            │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│   When you hit the limit, older messages get "forgotten" (truncated).       │
│   That's why long conversations sometimes lose context.                     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Tokens Per Second: Speed Matters

When we say "70 tokens/second," here's what that means in practice:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        SPEED COMPARISON (REAL WORLD)                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Average human reading speed: ~250 words/minute = ~4 words/second          │
│   Average LLM response: ~200-500 words                                      │
│                                                                             │
│   ───────────────────────────────────────────────────────────────────────   │
│                                                                             │
│   AEGIS (RTX 4080 Super, 70 tok/s):                                         │
│   - 70 tokens ≈ 52 words per second                                         │
│   - 300 word response = ~6 seconds                                          │
│   - Feels INSTANT                                                           │
│                                                                             │
│   RYZEN-AI (CPU only, 10 tok/s):                                            │
│   - 10 tokens ≈ 7.5 words per second                                        │
│   - 300 word response = ~40 seconds                                         │
│   - Feels slow but acceptable                                               │
│                                                                             │
│   Your phone (if it could run this):                                        │
│   - Maybe 2 tok/s                                                           │
│   - 300 word response = ~3+ minutes                                         │
│   - Painful                                                                 │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Quantization: Making Models Smaller

Full models are HUGE. Quantization compresses them by reducing numerical precision.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      QUANTIZATION: THE COMPRESSION TRICK                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Original model (FP32 - full precision):                                   │
│   Parameter value: 0.123456789012345                                        │
│   Bits per parameter: 32                                                    │
│   8B model size: 32 GB                                                      │
│                                                                             │
│   Quantized model (Q4_K_M - 4-bit):                                         │
│   Parameter value: 0.12 (rounded)                                           │
│   Bits per parameter: 4-5                                                   │
│   8B model size: 4.9 GB                                                     │
│                                                                             │
│   ───────────────────────────────────────────────────────────────────────   │
│                                                                             │
│   COMMON QUANTIZATION LEVELS:                                               │
│   Q2_K  - Smallest, lowest quality (barely usable)                          │
│   Q4_K_M - Great balance (what we use)      ◄── SWEET SPOT                  │
│   Q5_K_M - Higher quality, larger                                           │
│   Q8_0  - Near-original quality                                             │
│   F16   - Half precision (big but high quality)                             │
│   F32   - Full precision (massive, rarely used)                             │
│                                                                             │
│   Rule of thumb: Q4_K_M gives ~95% of full quality at ~15% of the size     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Why We Downloaded THESE Specific Models

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     OUR MODEL SELECTION STRATEGY                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   NEED: Fast general chat                                                   │
│   CHOICE: llama3.2:3b (2 GB)                                                │
│   WHY: Small = fast. Good enough for routing decisions and quick answers.  │
│                                                                             │
│   NEED: Code generation                                                     │
│   CHOICE: qwen2.5-coder:7b (4.7 GB)                                         │
│   WHY: Trained specifically on code. Outperforms general models at coding. │
│                                                                             │
│   NEED: Deep reasoning / validation                                         │
│   CHOICE: phi3:14b (7.9 GB)                                                 │
│   WHY: Microsoft's Phi-3 punches above its weight for reasoning tasks.     │
│                                                                             │
│   NEED: Semantic search / embeddings                                        │
│   CHOICE: bge-m3 (1.2 GB)                                                   │
│   WHY: Not a chat model - converts text to vectors for similarity search.  │
│                                                                             │
│   NEED: Fast GPU inference                                                  │
│   CHOICE: llama3.1:8b on RTX 4080 Super                                     │
│   WHY: Sweet spot of quality vs speed. GPU makes it blazing fast.          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Why 5 Machines? The "Distributed AI" Concept <a name="why-5-machines"></a>

Running AI locally is expensive. You need beefy hardware. But different tasks need different capabilities. So we split the work.

### The Machine Roster

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           OUR 5-MACHINE MESH                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────┐                                                           │
│   │   PHANTOM   │  Your laptop. Where you TYPE commands.                    │
│   │ Dell XPS    │  ARM64 Snapdragon X Elite, Windows 11 ARM                 │
│   │ 9345 64GB   │  The "command center" when mobile.                        │
│   └──────┬──────┘                                                           │
│          │                                                                  │
│          │ SSH + Tailscale VPN                                              │
│          │                                                                  │
│   ┌──────┴──────────────────────────────────────────────────────────┐       │
│   │                    TAILSCALE MESH NETWORK                        │       │
│   │            (encrypted tunnel across internet)                    │       │
│   └──────┬──────────────────┬───────────────────┬───────────────────┘       │
│          │                  │                   │                           │
│   ┌──────▼──────┐    ┌──────▼──────┐    ┌──────▼──────┐                     │
│   │    AEGIS    │    │  RYZEN-AI   │    │    NEXUS    │                     │
│   │  Windows PC │    │  Linux PC   │    │  Mac Mini   │                     │
│   │ RTX 4080 S  │    │ 128GB RAM   │    │   M4 Pro    │                     │
│   │             │    │             │    │             │                     │
│   │ llama.cpp   │    │  Ollama     │    │  Ollama     │                     │
│   │ CUDA/GPU    │    │ Multi-model │    │  Backup     │                     │
│   │ 70-90 tok/s │    │ 8-15 tok/s  │    │ 35-50 tok/s │                     │
│   └─────────────┘    └─────────────┘    └─────────────┘                     │
│                                                                             │
│   ┌─────────────┐                                                           │
│   │ KALI-NEXUS  │  Security scanning VM (Trivy, Nuclei, etc.)               │
│   │   (Kali)    │  Not for inference, for scanning containers.              │
│   └─────────────┘                                                           │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Why These Specific Roles?

**AEGIS (Windows, RTX 4080 Super)**
- Has a serious GPU. NVIDIA's CUDA makes AI inference FAST.
- 70-90 tokens/second = nearly instant responses
- Runs llama.cpp (lightweight, GPU-optimized)
- PRIMARY workhorse for general questions

**RYZEN-AI (Linux, 128GB RAM)**
- Monster RAM = can load multiple models simultaneously
- Runs Ollama (easy multi-model management)
- SPECIALIST node: code models, validation, embeddings
- Slower (8-15 tok/s) but can do things others can't

**NEXUS (Mac Mini M4 Pro)**
- Apple Silicon is surprisingly good at AI
- Acts as BACKUP when you're on the road
- Also runs the orchestrator (the traffic cop)
- 35-50 tok/s on Metal acceleration

---

## The Network: How Machines Talk to Each Other <a name="the-network"></a>

### The Problem with "Normal" Networks

Your home network has a router. Everything behind it shares one public IP. This creates problems:

```
PROBLEM: Traditional Networking

  Your Home                              The Internet
  ┌──────────────────────┐              ┌──────────────────────┐
  │ Aegis: 192.168.1.10  │              │                      │
  │ Ryzen: 192.168.1.11  │──── Router ──│  Public IP: 1.2.3.4  │
  │ Nexus: 192.168.1.12  │    (NAT)     │                      │
  └──────────────────────┘              └──────────────────────┘

  When you're at a coffee shop, you CAN'T reach 192.168.1.10.
  It's a "private" IP. The internet doesn't know how to route there.
```

### Tailscale: The Magic VPN

Tailscale creates a virtual network that works EVERYWHERE.

```
SOLUTION: Tailscale Mesh VPN

  ┌─────────────────────────────────────────────────────────────────────────┐
  │                     TAILSCALE VIRTUAL NETWORK                           │
  │                       (100.64.0.0/10 subnet)                            │
  │                                                                         │
  │   ┌─────────────────┐         ┌─────────────────┐                       │
  │   │     PHANTOM     │         │      AEGIS      │                       │
  │   │  100.78.x.x     │◄───────►│  100.94.x.x     │                       │
  │   │  (coffee shop)  │         │  (your house)   │                       │
  │   └─────────────────┘         └─────────────────┘                       │
  │           ▲                           ▲                                 │
  │           │                           │                                 │
  │           ▼                           ▼                                 │
  │   ┌─────────────────┐         ┌─────────────────┐                       │
  │   │    RYZEN-AI     │◄───────►│      NEXUS      │                       │
  │   │  100.83.x.x     │         │  100.124.x.x    │                       │
  │   └─────────────────┘         └─────────────────┘                       │
  │                                                                         │
  │   Every machine can reach every other machine by NAME.                  │
  │   "ssh aegis" works from ANYWHERE in the world.                         │
  └─────────────────────────────────────────────────────────────────────────┘
```

### Magic DNS: Names Instead of Numbers

Tailscale gives each machine a name. This is configured in `/etc/hosts` or via MagicDNS:

```bash
# Instead of remembering IP addresses:
ssh 100.94.123.45

# You just type:
ssh aegis
```

---

## Setting Up Remote Machines: SSH Deep Dive <a name="ssh-deep-dive"></a>

SSH (Secure Shell) lets you run commands on remote machines. It's the backbone of everything we do.

### How SSH Authentication Works

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         SSH KEY AUTHENTICATION                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   YOUR MACHINE                         REMOTE SERVER                        │
│   ┌─────────────────┐                 ┌─────────────────┐                   │
│   │                 │                 │                 │                   │
│   │  Private Key    │                 │  Public Key     │                   │
│   │  ~/.ssh/id_ed25519                │  ~/.ssh/authorized_keys             │
│   │  (NEVER SHARE)  │                 │  (OK to share)  │                   │
│   │                 │                 │                 │                   │
│   └────────┬────────┘                 └────────┬────────┘                   │
│            │                                   │                            │
│            │ 1. "I want to connect"            │                            │
│            ├──────────────────────────────────►│                            │
│            │                                   │                            │
│            │ 2. "Prove you have private key"   │                            │
│            │◄──────────────────────────────────┤                            │
│            │    (sends encrypted challenge)    │                            │
│            │                                   │                            │
│            │ 3. Signs challenge with priv key  │                            │
│            ├──────────────────────────────────►│                            │
│            │                                   │                            │
│            │ 4. Verifies with public key       │                            │
│            │    "You're legit, come in"        │                            │
│            │◄──────────────────────────────────┤                            │
│            │                                   │                            │
└─────────────────────────────────────────────────────────────────────────────┘
```

### The SSH Commands We Used

```bash
# 1. Generate a key pair (if you don't have one)
ssh-keygen -t ed25519 -C "your-email@example.com"

# 2. Copy your public key to a remote server
ssh-copy-id user@remote-host

# 3. Test the connection
ssh aegis "echo 'Hello from Aegis!'"

# 4. Run a command remotely
ssh ryzen-ai "ollama list"
```

### Real SSH Issues We Hit (And How We Fixed Them)

**Issue 1: Host Key Verification Failed**

```
$ ssh nexus "ollama list"
Host key verification failed.
```

**What happened:** First time connecting to a machine, SSH doesn't trust it yet.

**The fix:**
```bash
# Add the host's key to your known_hosts file
ssh-keyscan -H nexus >> ~/.ssh/known_hosts
```

**Why this matters:** SSH keeps a list of "known" servers to prevent man-in-the-middle attacks. First connection = unknown = blocked.

---

**Issue 2: Too Many Authentication Failures**

```
Received disconnect from 100.124.89.59 port 22:2: Too many authentication failures
```

**What happened:** SSH tried multiple keys, all failed, server kicked us out.

**The fix:**
```bash
# Specify exactly which key to use
ssh -i ~/.ssh/id_ed25519 user@host

# Or configure in ~/.ssh/config:
Host nexus
    HostName nexus
    User shifty
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
```

---

**Issue 3: Permission Denied (publickey)**

```
nexus@nexus: Permission denied (publickey,password,keyboard-interactive).
```

**What happened:** The remote machine doesn't have your public key in authorized_keys.

**The fix:**
```bash
# Copy your key to the remote machine
ssh-copy-id nexus

# Or manually append it:
cat ~/.ssh/id_ed25519.pub | ssh user@host "cat >> ~/.ssh/authorized_keys"
```

---

## Installing Ollama: Package Management Across OSes <a name="installing-ollama"></a>

Ollama is our "model manager" - it downloads, runs, and serves AI models.

### The Linux Install (Ryzen-AI)

```bash
# The official one-liner
curl -fsSL https://ollama.com/install.sh | sh
```

**Let's break this down:**

```
curl                    # Download tool (like wget)
  -f                    # Fail silently on HTTP errors
  -s                    # Silent mode (no progress bar)
  -S                    # Show errors even in silent mode
  -L                    # Follow redirects
  https://ollama.com/install.sh   # The install script URL
  |                     # Pipe: send output to next command
  sh                    # Run it as a shell script
```

**Why pipe to sh?** The script is downloaded and executed immediately. This is convenient but risky - you're trusting that URL completely. In production, you might:
```bash
# Safer approach: download, inspect, then run
curl -fsSL https://ollama.com/install.sh -o install.sh
cat install.sh  # Read it first!
chmod +x install.sh
./install.sh
```

### The macOS Install (Nexus)

macOS doesn't have a package manager by default. We had options:

```bash
# Option 1: Homebrew (if installed)
brew install ollama

# Option 2: Direct download (what we did)
curl -L https://ollama.com/download/Ollama-darwin.zip -o /tmp/Ollama.zip
unzip /tmp/Ollama.zip -d /Applications/
```

**The Error We Hit:**

```bash
$ curl https://ollama.com/install.sh | sh
This script is intended to run on Linux only.
```

**Lesson learned:** Always check what OS a script targets. The Ollama install script explicitly blocks non-Linux systems.

### Making Ollama Listen on Network

By default, Ollama only listens on `localhost` (127.0.0.1). Other machines can't reach it.

```bash
# Default: Only this machine can connect
ollama serve  # Listens on 127.0.0.1:11434

# What we need: Any machine on the network can connect
OLLAMA_HOST=0.0.0.0 ollama serve  # Listens on 0.0.0.0:11434
```

**The Difference:**

```
127.0.0.1 (localhost)           0.0.0.0 (all interfaces)
┌─────────────────────┐         ┌─────────────────────┐
│     THIS MACHINE    │         │     THIS MACHINE    │
│  ┌───────────────┐  │         │  ┌───────────────┐  │
│  │    Ollama     │  │         │  │    Ollama     │  │
│  │   :11434      │  │         │  │   :11434      │  │
│  └───────────────┘  │         │  └───────────────┘  │
│         ▲           │         │         ▲           │
│         │ only      │         │         │ ALL       │
│         │ local     │         │         │ interfaces│
└─────────────────────┘         └─────────┬───────────┘
                                          │
                                   ┌──────┴──────┐
                                   │ Other       │
                                   │ Machines    │
                                   │ Can Connect │
                                   └─────────────┘
```

---

## The One-Liner Philosophy: Why We Script This Way <a name="one-liner-philosophy"></a>

Throughout this project, you'll see commands like:

```bash
ssh ryzen-ai "OLLAMA_HOST=0.0.0.0 nohup ollama serve > /dev/null 2>&1 &"
```

This looks intimidating. Let's decode it piece by piece.

### Anatomy of a One-Liner

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         DISSECTING THE ONE-LINER                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│ ssh ryzen-ai "OLLAMA_HOST=0.0.0.0 nohup ollama serve > /dev/null 2>&1 &"    │
│ ─┬─ ───┬────  ────────┬────────── ──┬── ────┬───── ─────┬────── ─┬── ─┬─    │
│  │     │              │             │       │           │        │    │     │
│  │     │              │             │       │           │        │    └─ &  │
│  │     │              │             │       │           │        │    Run in│
│  │     │              │             │       │           │        │    back- │
│  │     │              │             │       │           │        │    ground│
│  │     │              │             │       │           │        │          │
│  │     │              │             │       │           │     2>&1          │
│  │     │              │             │       │           │     Redirect      │
│  │     │              │             │       │           │     stderr to     │
│  │     │              │             │       │           │     stdout        │
│  │     │              │             │       │           │                   │
│  │     │              │             │       │        > /dev/null            │
│  │     │              │             │       │        Discard output         │
│  │     │              │             │       │        (black hole)           │
│  │     │              │             │       │                               │
│  │     │              │             │    ollama serve                       │
│  │     │              │             │    The actual command                 │
│  │     │              │             │                                       │
│  │     │              │          nohup                                      │
│  │     │              │          "No hangup" - survives logout              │
│  │     │              │                                                     │
│  │     │           OLLAMA_HOST=0.0.0.0                                      │
│  │     │           Environment variable (just for this command)             │
│  │     │                                                                    │
│  │  ryzen-ai                                                                │
│  │  The remote host to connect to                                           │
│  │                                                                          │
│ ssh                                                                         │
│ Secure Shell - run command on remote machine                                │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Why One-Liners?

**1. Remote Execution**
When you SSH into a machine, you're opening an interactive session. But for automation, you want to fire-and-forget:

```bash
# Interactive (you have to wait, type, logout)
ssh ryzen-ai
ollama pull llama3.2:3b
exit

# One-liner (fire and forget)
ssh ryzen-ai "ollama pull llama3.2:3b"
```

**2. Background Processes**
Some commands need to keep running after you disconnect:

```bash
# This dies when you log out:
ssh ryzen-ai "ollama serve"

# This survives:
ssh ryzen-ai "nohup ollama serve > /dev/null 2>&1 &"
```

**3. Chaining Commands**

```bash
# Run multiple commands, stop if any fails (&&)
ssh aegis "cd /app && git pull && ./restart.sh"

# Run multiple commands, ignore failures (;)
ssh aegis "pkill ollama; sleep 2; ollama serve"
```

### Common One-Liner Patterns

```bash
# Pattern: Check then Act
command1 && command2      # Only run command2 if command1 succeeds
command1 || command2      # Only run command2 if command1 fails

# Pattern: Try with Fallback
curl http://server:8000 2>/dev/null || echo "Server down"

# Pattern: Background with Logging
nohup ./script.sh > /var/log/script.log 2>&1 &

# Pattern: Loop Until Success
while ! curl -s http://localhost:8000/health; do sleep 1; done
```

---

## Model Pulling: What's Actually Happening <a name="model-pulling"></a>

When you run `ollama pull llama3.2:3b`, a lot happens behind the scenes.

### The Model Registry

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        HOW MODEL PULLING WORKS                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   YOU                      OLLAMA.COM                   YOUR MACHINE        │
│   ┌───┐                    ┌──────────┐                 ┌──────────────┐    │
│   │   │ ollama pull        │  Model   │                 │   ~/.ollama/ │    │
│   │   │ llama3.2:3b        │ Registry │                 │   models/    │    │
│   │   │ ─────────────────► │          │                 │              │    │
│   │   │                    │          │                 │              │    │
│   │   │ 1. Fetch manifest  │ manifest │                 │              │    │
│   │   │ ◄───────────────── │ (JSON)   │                 │              │    │
│   │   │                    │          │                 │              │    │
│   │   │ 2. Request layers  │ blob     │ 3. Download     │              │    │
│   │   │ ─────────────────► │ storage  │ ─────────────►  │ model.gguf   │    │
│   │   │                    │          │ (2GB file)      │              │    │
│   └───┘                    └──────────┘                 └──────────────┘    │
│                                                                             │
│   The "manifest" tells Ollama:                                              │
│   - What layers (files) make up the model                                   │
│   - SHA256 hashes to verify downloads                                       │
│   - Model configuration (context size, etc.)                                │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Model Naming: Tags Explained

```bash
ollama pull llama3.2:3b
           ─────┬─ ─┬─
                │   │
                │   └── Tag: The variant (size, quantization)
                │
                └────── Name: The model family

# Examples:
llama3.2:3b        # Llama 3.2, 3 billion parameters
llama3.2:latest    # Llama 3.2, default/latest version
qwen2.5-coder:7b   # Qwen 2.5 Coder, 7 billion parameters
phi3:14b           # Phi-3, 14 billion parameters
```

### What We Pulled for Each Machine

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      MODEL DISTRIBUTION STRATEGY                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   AEGIS (GPU Speed King)                                                    │
│   └── llama-3.1-8b via llama.cpp                                            │
│       └── Why: GPU-accelerated, fastest inference                           │
│                                                                             │
│   RYZEN-AI (RAM Monster - 128GB)                                            │
│   ├── llama3.2:3b (2.0 GB)      - Fast routing/triage                       │
│   ├── qwen2.5-coder:7b (4.7 GB) - Code generation specialist                │
│   ├── codellama:7b (3.8 GB)     - Code explanation                          │
│   ├── phi3:14b (7.9 GB)         - Validation/reasoning                      │
│   ├── bge-m3 (1.2 GB)           - Embeddings (semantic search)              │
│   └── nomic-embed-text (274 MB) - Lightweight embeddings                    │
│       │                                                                     │
│       └── Why: Lots of RAM = can switch between models quickly              │
│           128GB can hold ALL of these simultaneously!                       │
│                                                                             │
│   NEXUS (Backup Mac)                                                        │
│   └── llama3.1:8b (4.9 GB)                                                  │
│       └── Why: Capable backup when orchestrating from Phantom               │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### The Parallel Download Trick

We downloaded multiple models simultaneously:

```bash
# These run in parallel (& puts them in background)
ssh ryzen-ai "ollama pull codellama:7b" &
ssh ryzen-ai "ollama pull bge-m3" &
echo "Pulling both models..."
```

**Why parallel?** Network is the bottleneck, not CPU. Downloading two files at once = twice as fast (roughly).

---

## The Orchestrator: Traffic Cop for AI <a name="the-orchestrator"></a>

The orchestrator (`main.py`) is the brain of the operation. It decides WHERE to send each request.

### How It Works

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         ORCHESTRATOR FLOW                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   User Request                                                              │
│   "Help me debug this Python code with patient data"                        │
│        │                                                                    │
│        ▼                                                                    │
│   ┌────────────────────────────────────────────────┐                        │
│   │           SENSITIVITY ANALYZER                 │                        │
│   │                                                │                        │
│   │   Scans for:                                   │                        │
│   │   - SSN patterns (XXX-XX-XXXX)                │                        │
│   │   - Names (NER detection)                      │                        │
│   │   - Medical terms (ICD codes, diagnoses)       │                        │
│   │   - IP addresses, device IDs                   │                        │
│   │                                                │                        │
│   │   Result: TIER 1 - LOCAL ONLY                 │                        │
│   └─────────────────────┬──────────────────────────┘                        │
│                         │                                                   │
│                         ▼                                                   │
│   ┌────────────────────────────────────────────────┐                        │
│   │            TASK TYPE DETECTOR                  │                        │
│   │                                                │                        │
│   │   Keywords found: "debug", "code", "Python"   │                        │
│   │   Task type: CODE                              │                        │
│   └─────────────────────┬──────────────────────────┘                        │
│                         │                                                   │
│                         ▼                                                   │
│   ┌────────────────────────────────────────────────┐                        │
│   │           BACKEND SELECTOR                     │                        │
│   │                                                │                        │
│   │   Tier 1 + Code task =                         │                        │
│   │   Preferred: ryzen-ai (has qwen2.5-coder)     │                        │
│   │   Fallback:  aegis, nexus                      │                        │
│   │                                                │                        │
│   │   Check health... ryzen-ai is ONLINE          │                        │
│   │   Selected: ryzen-ai with qwen2.5-coder:7b    │                        │
│   └─────────────────────┬──────────────────────────┘                        │
│                         │                                                   │
│                         ▼                                                   │
│   ┌────────────────────────────────────────────────┐                        │
│   │         FORWARD TO RYZEN-AI                    │                        │
│   │                                                │                        │
│   │   POST http://ryzen-ai:11434/api/chat         │                        │
│   │   {                                            │                        │
│   │     "model": "qwen2.5-coder:7b",              │                        │
│   │     "messages": [...]                          │                        │
│   │   }                                            │                        │
│   └────────────────────────────────────────────────┘                        │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Key Code Sections Explained

**Backend Configuration (lines 88-126 of main.py)**

```python
BACKEND_CONFIG = {
    "aegis": {
        "name": "Aegis (RTX 4080 Super)",
        "tailscale_hostname": "aegis",        # How to reach it
        "api_type": "llama.cpp",              # What API it speaks
        "port": 8080,                         # What port to connect to
        "default_model": "llama-3.1-8b",
        "capabilities": ["fast-inference", "large-context", "general"],
        "typical_speed": "70-90 tok/s",
        "priority": 1,                        # Try this first
    },
    # ... more backends
}
```

**Health Checking (lines 173-218)**

The orchestrator constantly pings each backend to see if it's alive:

```python
async def check_backend_health(backend_id: str) -> BackendStatus:
    """Check if a backend is responsive"""
    url = f"http://{config['tailscale_hostname']}:{config['port']}"

    try:
        start = time.time()
        async with httpx.AsyncClient(timeout=5.0) as client:
            if config["api_type"] == "llama.cpp":
                response = await client.get(f"{url}/health")
            else:
                response = await client.get(f"{url}/api/tags")

        latency = (time.time() - start) * 1000
        return BackendStatus(status="online", latency_ms=latency)
    except:
        return BackendStatus(status="offline")
```

**The Routing Decision (lines 253-332)**

```python
def select_backend(request):
    # Step 1: SECURITY FIRST - Analyze sensitivity
    sensitivity = analyze_request_sensitivity(request.messages)

    # Step 2: Check if user requested specific backend
    if request.preferred_backend:
        # Validate it's appropriate for sensitivity level
        ...

    # Step 3: Detect task type from content
    if "code" in content or "debug" in content:
        task_type = "code"
    elif "validate" in content:
        task_type = "validation"

    # Step 4: Select based on sensitivity + task
    if sensitivity['route'] == 'local':
        if task_type == 'code':
            preferred_order = ['ryzen-ai', 'aegis', 'nexus']
        else:
            preferred_order = ['aegis', 'ryzen-ai', 'nexus']

    # Step 5: Find first available backend
    for backend_id in preferred_order:
        if backend_is_online(backend_id):
            return backend_id
```

### How It All Flows Across 5 Machines

Here's the complete picture of what happens when you send a request:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│              COMPLETE REQUEST FLOW ACROSS THE MESH                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   PHANTOM (Your Laptop - Dell XPS 9345)                                     │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │ You type: curl http://nexus:8000/v1/chat/completions -d '{...}'     │   │
│   └──────────────────────────────┬──────────────────────────────────────┘   │
│                                  │                                          │
│                                  │ 1. Request travels over Tailscale VPN    │
│                                  │    (encrypted, authenticated)            │
│                                  ▼                                          │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │ NEXUS (Mac Mini M4 Pro) - THE ORCHESTRATOR                          │   │
│   │                                                                     │   │
│   │  2. FastAPI receives request on port 8000                           │   │
│   │     │                                                               │   │
│   │     ▼                                                               │   │
│   │  3. analyze_request_sensitivity() scans for PHI/PII                 │   │
│   │     - Regex patterns for SSN, phone, email                          │   │
│   │     - NER for names, medical terms                                  │   │
│   │     - Returns: tier1_entities, tier2_entities, route                │   │
│   │     │                                                               │   │
│   │     ▼                                                               │   │
│   │  4. select_backend() decides where to route                         │   │
│   │     - Checks backend_status{} (refreshed every 30s)                 │   │
│   │     - Picks best available based on sensitivity + task              │   │
│   │     │                                                               │   │
│   │     ▼                                                               │   │
│   │  5. Decision: Route to RYZEN-AI (code task, tier 1)                 │   │
│   └─────────────────────────────┬───────────────────────────────────────┘   │
│                                 │                                           │
│                                 │ 6. HTTP POST to http://ryzen-ai:11434     │
│                                 │    (another Tailscale hop)                │
│                                 ▼                                           │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │ RYZEN-AI (Linux, 128GB RAM) - MULTI-MODEL SPECIALIST                │   │
│   │                                                                     │   │
│   │  7. Ollama receives POST /api/chat                                  │   │
│   │     - Loads qwen2.5-coder:7b into RAM (if not already)              │   │
│   │     - Runs inference on CPU (no GPU here)                           │   │
│   │     - Generates response token by token                             │   │
│   │     │                                                               │   │
│   │     ▼                                                               │   │
│   │  8. Returns JSON response to Nexus                                  │   │
│   └─────────────────────────────┬───────────────────────────────────────┘   │
│                                 │                                           │
│                                 ▼                                           │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │ NEXUS - Receives response, adds metadata                            │   │
│   │                                                                     │   │
│   │  9. Optionally: Validate response with phi3:14b                     │   │
│   │ 10. Add orchestration metadata (backend, latency, etc.)             │   │
│   │ 11. Return to Phantom                                               │   │
│   └─────────────────────────────┬───────────────────────────────────────┘   │
│                                 │                                           │
│                                 ▼                                           │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │ PHANTOM - Receives final response                                   │   │
│   │                                                                     │   │
│   │ 12. Display to user                                                 │   │
│   │     {                                                               │   │
│   │       "choices": [{"message": {"content": "Here's the fix..."}}],  │   │
│   │       "orchestration": {                                            │   │
│   │         "backend": "ryzen-ai",                                      │   │
│   │         "model": "qwen2.5-coder:7b",                                │   │
│   │         "latency_ms": 2340                                          │   │
│   │       }                                                             │   │
│   │     }                                                               │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│   TOTAL HOPS: Phantom → Nexus → Ryzen-AI → Nexus → Phantom                  │
│   ALL TRAFFIC: Encrypted via Tailscale WireGuard tunnels                    │
│   SENSITIVE DATA: Never left the mesh, never touched the internet           │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### What About AEGIS?

AEGIS (Windows, RTX 4080) is the speed king. When the orchestrator picks it:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    AEGIS GPU INFERENCE PATH                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Request from Nexus                                                        │
│        │                                                                    │
│        ▼                                                                    │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │ AEGIS (Windows 11, RTX 4080 Super 16GB VRAM)                        │   │
│   │                                                                     │   │
│   │  llama-server (llama.cpp) running on port 8080                      │   │
│   │     │                                                               │   │
│   │     ▼                                                               │   │
│   │  CUDA accelerated inference:                                        │   │
│   │  - Model weights loaded in GPU VRAM                                 │   │
│   │  - Matrix multiplications on CUDA cores                             │   │
│   │  - 70-90 tokens/second (6-10x faster than CPU!)                     │   │
│   │                                                                     │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│   GPU vs CPU (same model):                                                  │
│   ┌────────────────────────────────────────────────────────────────────┐    │
│   │  Aegis (GPU):   ████████████████████████████████████████ 80 tok/s  │    │
│   │  Ryzen-AI (CPU): █████ 10 tok/s                                    │    │
│   └────────────────────────────────────────────────────────────────────┘    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Cybersecurity Best Practices in Our Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    SECURITY LAYERS IN THE PIPELINE                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   LAYER 1: NETWORK SECURITY (Tailscale)                                     │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │ ✓ WireGuard encryption (modern, audited crypto)                     │   │
│   │ ✓ Mutual authentication (both ends verify each other)               │   │
│   │ ✓ No exposed ports to internet (mesh is private)                    │   │
│   │ ✓ NAT traversal without port forwarding                             │   │
│   │ ✓ Per-device access controls (ACLs)                                 │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│   LAYER 2: SSH SECURITY                                                     │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │ ✓ Key-based authentication (no passwords to brute-force)            │   │
│   │ ✓ Ed25519 keys (modern, fast, secure)                               │   │
│   │ ✓ known_hosts verification (prevents MITM)                          │   │
│   │ ✓ Host-specific key configuration                                   │   │
│   │ ✗ TODO: Certificate-based SSH (even better)                         │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│   LAYER 3: DATA CLASSIFICATION (Shay's 3-Tier)                              │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │ ✓ Automatic PHI/PII detection before routing                        │   │
│   │ ✓ Sensitive data NEVER leaves local infrastructure                  │   │
│   │ ✓ Audit logs use anonymized versions                                │   │
│   │ ✓ Tier-based routing enforced in code                               │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│   LAYER 4: DEFENSE IN DEPTH                                                 │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │ ✓ Firewalls on each machine (tailscale interface trusted)           │   │
│   │ ✓ Ollama binds to specific interfaces                               │   │
│   │ ✓ No cloud APIs configured (can't leak even if misconfigured)       │   │
│   │ ✓ Principle of least privilege (each machine has specific role)     │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│   LAYER 5: AUDIT & MONITORING                                               │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │ ✓ Request logging with sensitivity classification                   │   │
│   │ ✓ Backend health checks every 30 seconds                            │   │
│   │ ✓ Latency tracking for performance monitoring                       │   │
│   │ ✗ TODO: Centralized log aggregation (ELK stack)                     │   │
│   │ ✗ TODO: Alerting on anomalies                                       │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### The Zero-Trust Principles We Follow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    ZERO-TRUST IN PRACTICE                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   PRINCIPLE 1: "Never trust, always verify"                                 │
│   ────────────────────────────────────────                                  │
│   - Every request is analyzed for sensitivity                               │
│   - Backend selection is FORCED by classification                           │
│   - User can't override tier 1 routing to cloud                             │
│                                                                             │
│   Code example:                                                             │
│   ```python                                                                 │
│   if sensitivity['route'] == 'local':                                       │
│       if request.preferred_backend not in ['aegis', 'ryzen-ai', 'nexus']:   │
│           logger.warning("Sensitive data, ignoring cloud preference")       │
│           # FORCE local routing - user preference overridden                │
│   ```                                                                       │
│                                                                             │
│   PRINCIPLE 2: "Assume breach"                                              │
│   ─────────────────────────────                                             │
│   - Even if an attacker gets on the network, they can't read traffic        │
│   - Tailscale traffic is end-to-end encrypted                               │
│   - No plaintext secrets in config files                                    │
│                                                                             │
│   PRINCIPLE 3: "Least privilege"                                            │
│   ──────────────────────────────                                            │
│   - Aegis only runs inference, no orchestration logic                       │
│   - Ryzen-AI only runs Ollama, no SSH outbound                              │
│   - Each machine does ONE thing well                                        │
│                                                                             │
│   PRINCIPLE 4: "Verify explicitly"                                          │
│   ─────────────────────────────────                                         │
│   - Health checks verify backends are alive                                 │
│   - SSH key verification prevents impersonation                             │
│   - Model SHA256 hashes verify download integrity                           │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### What Could Go Wrong? (Threat Modeling)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         THREAT MODEL                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   THREAT: Attacker compromises Phantom laptop                               │
│   IMPACT: Could send requests through the mesh                              │
│   MITIGATION: Tailscale device approval, can revoke device instantly        │
│                                                                             │
│   THREAT: Malicious prompt injection                                        │
│   IMPACT: LLM could be tricked into revealing info                          │
│   MITIGATION: System prompts, output filtering (future work)                │
│                                                                             │
│   THREAT: Ollama vulnerability                                              │
│   IMPACT: Remote code execution on inference nodes                          │
│   MITIGATION: Keep Ollama updated, firewall limits exposure                 │
│                                                                             │
│   THREAT: Insider threat (malicious admin)                                  │
│   IMPACT: Could exfiltrate data or modify routing                           │
│   MITIGATION: Audit logs, separation of duties, code review                 │
│                                                                             │
│   THREAT: Model poisoning                                                   │
│   IMPACT: Backdoored model produces malicious output                        │
│   MITIGATION: Use only verified models from Ollama registry                 │
│               SHA256 verification of downloads                              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Troubleshooting War Stories <a name="troubleshooting"></a>

Real issues we encountered and how we solved them.

### Story 1: The Shell Glob Monster

**The error:**
```bash
$ curl http://localhost:8000/backends?refresh=true
zsh: no matches found: http://localhost:8000/backends?refresh=true
```

**What happened:** Zsh (the Mac shell) treats `?` as a glob pattern (wildcard). It tried to find files matching that pattern.

**The fix:**
```bash
# Quote the URL
curl 'http://localhost:8000/backends?refresh=true'

# Or escape the special character
curl http://localhost:8000/backends\?refresh=true
```

**Lesson:** Always quote URLs in shell commands.

---

### Story 2: The Orphaned Port

**The error:**
```bash
$ ollama serve
Error: listen tcp 127.0.0.1:11434: bind: address already in use
```

**What happened:** A previous Ollama process was still running, holding the port.

**The fix:**
```bash
# Find what's using the port
lsof -i :11434

# Kill it
pkill ollama

# Or more forcefully
kill -9 $(lsof -t -i :11434)
```

---

### Story 3: The Disappearing Process

**The problem:** Started Ollama via SSH, but it died when SSH session ended.

**What happened:** Child processes die when parent (SSH session) exits.

**The fix:**
```bash
# Use nohup (no hangup)
nohup ollama serve &

# Or use screen/tmux for persistent sessions
screen -S ollama
ollama serve
# Ctrl+A, D to detach
```

---

### Story 4: The Firewall Blocker

**The error:**
```bash
$ curl http://ryzen-ai:11434/api/tags
curl: (7) Failed to connect to ryzen-ai port 11434: Connection refused
```

**What happened:** Ryzen-AI's firewall was blocking incoming connections on port 11434.

**The fix:**
```bash
# On Ryzen-AI (Linux with firewalld)
sudo firewall-cmd --add-port=11434/tcp --permanent
sudo firewall-cmd --reload

# For Tailscale specifically (trust the VPN)
sudo firewall-cmd --zone=trusted --add-interface=tailscale0 --permanent
sudo firewall-cmd --reload
```

---

## For Your Capstone Presentation <a name="capstone-notes"></a>

### The Elevator Pitch (30 seconds)

> "We built a distributed AI system that automatically routes sensitive data to local hardware and keeps it from ever touching the cloud. It's like a smart mail room that knows which packages are confidential and keeps them in-house."

### Key Talking Points

1. **Zero-Trust Security**
   - Never trust, always verify
   - Sensitive data stays local by design
   - HIPAA-compliant architecture

2. **Distributed Computing**
   - Different machines for different strengths
   - GPU for speed, RAM for versatility
   - Mesh network for connectivity

3. **Practical DevOps**
   - SSH for remote management
   - One-liners for automation
   - Health monitoring for reliability

### Demo Script

```
1. Show the orchestrator status page
   curl localhost:8000/backends

2. Send a sensitive request
   curl -X POST localhost:8000/v1/chat/completions \
     -d '{"messages":[{"role":"user","content":"Patient John Smith SSN 123-45-6789"}]}'

   Point out: Routed to LOCAL backend

3. Send a general request
   curl -X POST localhost:8000/v1/chat/completions \
     -d '{"messages":[{"role":"user","content":"What is Python?"}]}'

   Point out: Could route anywhere (but still local in our setup)

4. Show multi-model routing
   curl -X POST localhost:8000/v1/chat/completions \
     -d '{"messages":[{"role":"user","content":"Debug this code..."}], "task_type":"code"}'

   Point out: Automatically selected qwen2.5-coder
```

### Questions Your Teammates Might Ask

**Q: Why not just use ChatGPT?**
A: Data leaves your control. For healthcare, finance, government - that's often illegal or against policy.

**Q: Is running your own AI expensive?**
A: Initial hardware cost, yes. But no per-token fees. For high-volume use, it pays for itself.

**Q: How fast is it compared to cloud?**
A: Aegis with RTX 4080 Super: 70-90 tokens/second. ChatGPT: ~50-80 tokens/second. Comparable!

**Q: What if a machine goes down?**
A: The orchestrator automatically fails over to the next available backend. That's the "mesh" in action.

---

## Appendix: Quick Reference

### Essential Commands

```bash
# Check all backend status
curl 'http://localhost:8000/backends?refresh=true'

# List models on a remote machine
ssh ryzen-ai "ollama list"

# Pull a model remotely
ssh ryzen-ai "ollama pull modelname"

# Start Ollama on network interface
OLLAMA_HOST=0.0.0.0 ollama serve

# Check what's running on a port
lsof -i :11434

# Test if a machine is reachable
curl -s http://aegis:8080/health
```

### Port Reference

| Service      | Port  | Machine   |
|--------------|-------|-----------|
| Orchestrator | 8000  | Nexus     |
| llama.cpp    | 8080  | Aegis     |
| Ollama       | 11434 | Ryzen-AI  |
| Ollama       | 11434 | Nexus     |

### File Locations

| File                     | Purpose                              |
|--------------------------|--------------------------------------|
| `~/.ssh/id_ed25519`      | Your private SSH key                 |
| `~/.ssh/known_hosts`     | Trusted remote servers               |
| `~/.ssh/config`          | SSH shortcuts and settings           |
| `~/.ollama/models/`      | Downloaded AI models                 |
| `/var/log/ollama.log`    | Ollama service logs (Linux)          |

---

*This document covers the technical implementation of the Zero-Trust Hybrid AI Pipeline. For the theoretical background on 3-tier sensitivity routing, see Shay's documentation. For Presidio integration and UI components, see Javier's docs.*
