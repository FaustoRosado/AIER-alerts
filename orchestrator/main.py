#!/usr/bin/env python3
"""
Zero-Trust Hybrid AI Pipeline - Orchestrator Service
=====================================================

This service runs on your command center (Mac Mini M4 Pro - Nexus)
and intelligently routes inference requests to the appropriate backend
based on:
1. DATA SENSITIVITY (PHI/PII detection) - Shay's 4-tier classification
2. Task type and model requirements
3. Current system load and availability

SECURITY MODEL (Zero-Trust 4-Tier Classification):
- Tier 0 (PROTECTED): Keyword match (patient, diagnosis, vitals) → LOCAL ONLY
- Tier 1 (HIGH RISK): Presidio: SSN, names, credentials → LOCAL ONLY
- Tier 2 (MEDIUM RISK): Presidio: IPs, device IDs → Anonymize → Cloud allowed
- Tier 3 (CLEAR): Nothing detected → ANY backend

HIPAA COMPLIANCE:
- PHI never leaves local infrastructure (Tier 0 and Tier 1)
- All audit logs use anonymized versions
- Supports offline operation during outages
- Note: Tier 0 uses hardcoded keyword set (known limitation)

Architecture:
    Nexus (Orchestrator + Command Center)
           │
           ├──► Aegis (RTX 4080 Super) - Fast primary inference
           │         └── llama.cpp + Llama 3.1 8B @ 70-90 tok/s
           │
           ├──► Ryzen-AI (Ryzen AI 395 + 128GB) - Multi-model
           │         ├── Qwen2.5-Coder-7B (code)
           │         ├── Phi-3-14B (validation)
           │         └── BGE-M3 (embeddings)
           │
           └──► Kali-Nexus (Security scanning)
                     └── Trivy, Checkov, Nuclei

Contributors:
- Shifty: Infrastructure, orchestration, hardware setup
- Sheniese (Shay): 4-tier classification, HIPAA compliance, sensitivity analysis
- Javier: Presidio integration, Streamlit UI, AWS Bedrock

The orchestrator exposes an OpenAI-compatible API, so any tool that works with
OpenAI (Cursor, Continue, LangChain, etc.) can use your distributed AI mesh
by simply pointing to http://localhost:8000/v1
"""

import asyncio
import json
import time
import logging
from datetime import datetime
from typing import Optional, Literal, Dict, Any
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import httpx

# Import the sensitive routing module (Shay's contribution)
try:
    from sensitive_routing import (
        analyze_and_route,
        analyze_and_route_dict,
        Route,
        Backend,
        RoutingDecision,
        is_safe_for_cloud,
        requires_local_only,
        get_safe_payload,
    )
    SENSITIVE_ROUTING_AVAILABLE = True
except ImportError:
    SENSITIVE_ROUTING_AVAILABLE = False
    logging.warning("sensitive_routing module not available, using basic routing")

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("orchestrator")

# ============================================================================
# Configuration - Adjust these to match your Tailscale machine names
# ============================================================================

BACKEND_CONFIG = {
    "aegis": {
        "name": "Aegis (RTX 4080 Super)",
        "tailscale_hostname": "aegis",
        "api_type": "llama.cpp",  # llama-server with OpenAI-compatible API
        "port": 8080,
        "default_model": "llama-3.1-8b",
        "capabilities": ["fast-inference", "large-context", "general"],
        "max_context": 8192,
        "typical_speed": "70-90 tok/s",
        "priority": 1,
    },
    "ryzen-ai": {
        "name": "Ryzen-AI (Ryzen AI 395)",
        "tailscale_hostname": "ryzen-ai",
        "api_type": "ollama",
        "port": 11434,
        "models": {
            "code": "qwen2.5-coder:7b",
            "validation": "phi3:14b", 
            "explanation": "codellama:7b",
            "embedding": "bge-m3",
            "general": "llama3.2:3b",
        },
        "capabilities": ["multi-model", "validation", "embedding", "code"],
        "typical_speed": "8-15 tok/s",
        "priority": 2,
    },
    "nexus": {
        "name": "Nexus (Mac Mini M4 Pro 48GB)",
        "tailscale_hostname": "nexus",
        "api_type": "ollama",  # Or MLX server if configured
        "port": 11434,
        "default_model": "llama3.1:8b",
        "capabilities": ["general", "macos-native"],
        "typical_speed": "35-50 tok/s",
        "priority": 3,  # Backup for when you're orchestrating from Phantom
    },
}

# Task type to backend routing rules
ROUTING_RULES = {
    "code": ["ryzen-ai"],  # Code tasks use Qwen2.5-Coder specialist
    "validation": ["ryzen-ai"],  # Validation uses Phi-3 reasoning model
    "embedding": ["ryzen-ai"],  # Embeddings on multi-model node
    "fast": ["aegis"],  # Explicit fast inference request
    "general": ["aegis", "mac-mini", "ryzen-ai"],  # Fallback chain
}

# ============================================================================
# Data Models
# ============================================================================

class Message(BaseModel):
    role: Literal["system", "user", "assistant"]
    content: str

class ChatCompletionRequest(BaseModel):
    """OpenAI-compatible chat completion request"""
    model: str = "auto"  # "auto" = let orchestrator decide
    messages: list[Message]
    temperature: float = 0.7
    max_tokens: int = 2048
    stream: bool = False
    
    # Extended fields for orchestration control
    task_type: Optional[str] = None  # code, validation, embedding, fast, general
    require_validation: bool = False  # Run output through validation model
    preferred_backend: Optional[str] = None  # Force specific backend

class BackendStatus(BaseModel):
    name: str
    hostname: str
    status: Literal["online", "offline", "busy", "unknown"]
    last_check: datetime
    latency_ms: Optional[float] = None
    current_model: Optional[str] = None
    gpu_utilization: Optional[float] = None


class AnalyzeRequest(BaseModel):
    """Request model for the /analyze endpoint."""
    text: str = Field(..., description="Text to analyze for sensitive data")

# ============================================================================
# Backend Health Monitoring
# ============================================================================

backend_status: dict[str, BackendStatus] = {}

async def check_backend_health(backend_id: str) -> BackendStatus:
    """Check if a backend is responsive and get its current status"""
    config = BACKEND_CONFIG.get(backend_id)
    if not config:
        return BackendStatus(
            name=backend_id,
            hostname="unknown",
            status="unknown",
            last_check=datetime.now()
        )
    
    url = f"http://{config['tailscale_hostname']}:{config['port']}"
    
    try:
        start = time.time()
        async with httpx.AsyncClient(timeout=5.0) as client:
            if config["api_type"] == "llama.cpp":
                # llama-server health endpoint
                response = await client.get(f"{url}/health")
            else:
                # Ollama health endpoint
                response = await client.get(f"{url}/api/tags")
        
        latency = (time.time() - start) * 1000
        
        return BackendStatus(
            name=config["name"],
            hostname=config["tailscale_hostname"],
            status="online" if response.status_code == 200 else "busy",
            last_check=datetime.now(),
            latency_ms=round(latency, 2)
        )
    except Exception as e:
        return BackendStatus(
            name=config["name"],
            hostname=config["tailscale_hostname"],
            status="offline",
            last_check=datetime.now()
        )

async def refresh_all_backend_status():
    """Refresh status of all configured backends"""
    global backend_status
    tasks = [check_backend_health(bid) for bid in BACKEND_CONFIG.keys()]
    results = await asyncio.gather(*tasks)
    backend_status = {bid: status for bid, status in zip(BACKEND_CONFIG.keys(), results)}

# ============================================================================
# Inference Routing Logic (Integrated with Shay's 4-Tier Classification)
# ============================================================================

def analyze_request_sensitivity(messages: list) -> Dict[str, Any]:
    """
    Analyze request for sensitive data using Shay's 4-tier classification.

    Returns routing decision with:
    - route: local, anonymize_cloud, or cloud
    - tier0_protected: Whether protected context keywords detected
    - tier1_high_entities: High-risk entities (SSN, names, credentials)
    - tier2_medium_entities: Medium-risk entities (IPs, device IDs)
    - tier3_clear: Whether no sensitive data detected
    - audit_safe_text: Anonymized version for logging
    """
    if not SENSITIVE_ROUTING_AVAILABLE:
        # Fallback: assume local routing for safety
        return {
            "route": "local",
            "tier0_protected": False,
            "tier1_high_entities": [],
            "tier2_medium_entities": [],
            "tier3_clear": False,
            "audit_safe_text": "[sensitivity analysis unavailable]",
            "payload_text": " ".join(m.content for m in messages),
        }

    # Combine all message content for analysis
    full_text = " ".join(m.content for m in messages if m.content)

    # Use Shay's 4-tier classification system
    return analyze_and_route_dict(full_text, allow_cloud=False)


def select_backend(request: "ChatCompletionRequest") -> tuple[str, dict, Dict[str, Any]]:
    """
    Intelligently select the best backend for a given request.
    
    This function implements the Zero-Trust routing logic:
    1. First, analyze for sensitive data (Shay's 4-tier classification)
    2. If sensitive, ALWAYS route local (no exceptions)
    3. If safe, consider task type and backend availability

    Returns:
        Tuple of (backend_id, backend_config, sensitivity_analysis)
    """
    # Step 1: Analyze sensitivity (SECURITY FIRST)
    sensitivity = analyze_request_sensitivity(request.messages)

    # Compute tier3_clear for logging
    tier3_clear = (not sensitivity['tier0_protected'] and
                   len(sensitivity['tier1_high_entities']) == 0 and
                   len(sensitivity['tier2_medium_entities']) == 0)

    # Log with anonymized version only
    logger.info(f"Request analysis: route={sensitivity['route']}, "
                f"tier0_protected={sensitivity['tier0_protected']}, "
                f"tier1_high={len(sensitivity['tier1_high_entities'])}, "
                f"tier2_medium={len(sensitivity['tier2_medium_entities'])}, "
                f"tier3_clear={tier3_clear}")
    
    # Step 2: If user explicitly requested a backend, validate it
    if request.preferred_backend:
        if request.preferred_backend in BACKEND_CONFIG:
            status = backend_status.get(request.preferred_backend)
            if status and status.status == "online":
                # For sensitive data, only allow local backends
                if sensitivity['route'] == 'local':
                    if request.preferred_backend not in ['aegis', 'ryzen-ai', 'nexus']:
                        logger.warning(f"Sensitive data detected, ignoring cloud backend preference")
                    else:
                        return request.preferred_backend, BACKEND_CONFIG[request.preferred_backend], sensitivity
                else:
                    return request.preferred_backend, BACKEND_CONFIG[request.preferred_backend], sensitivity
    
    # Step 3: Determine task type
    task_type = request.task_type
    if not task_type:
        content = " ".join(m.content.lower() for m in request.messages)
        if any(kw in content for kw in ["code", "function", "implement", "debug", "refactor"]):
            task_type = "code"
        elif any(kw in content for kw in ["review", "validate", "check", "verify"]):
            task_type = "validation"
        elif any(kw in content for kw in ["embed", "vector", "similarity"]):
            task_type = "embedding"
        else:
            task_type = "general"
    
    # Step 4: Select backend based on sensitivity AND task type
    if sensitivity['route'] == 'local' or sensitivity['tier0_protected']:
        # TIER 0/1: Protected or high risk - must use local backend
        # For code tasks, prefer Ryzen-AI (specialized models)
        # For general tasks, prefer Aegis (fastest)
        if task_type in ['code', 'validation', 'embedding']:
            preferred_order = ['ryzen-ai', 'aegis', 'nexus']
        else:
            preferred_order = ['aegis', 'ryzen-ai', 'nexus']
    else:
        # TIER 2/3: Can use any backend (but still prefer local)
        candidates = ROUTING_RULES.get(task_type, ROUTING_RULES["general"])
        preferred_order = candidates
    
    # Step 5: Find first available backend
    for backend_id in preferred_order:
        if backend_id not in BACKEND_CONFIG:
            continue
        status = backend_status.get(backend_id)
        if status and status.status == "online":
            return backend_id, BACKEND_CONFIG[backend_id], sensitivity
    
    # Step 6: No backends available
    raise HTTPException(
        status_code=503,
        detail={
            "error": "No backends available",
            "message": "All inference backends are offline. Check Tailscale connectivity.",
            "checked_backends": list(BACKEND_CONFIG.keys()),
            "sensitivity_route": sensitivity['route'],
        }
    )


def select_backend_legacy(request: "ChatCompletionRequest") -> tuple[str, dict]:
    """
    Legacy backend selection (without sensitivity analysis).
    Kept for backwards compatibility.
    """
    backend_id, config, _ = select_backend(request)
    return backend_id, config


async def call_llama_cpp(url: str, messages: list[Message], **kwargs) -> dict:
    """Call a llama.cpp server (OpenAI-compatible API)"""
    async with httpx.AsyncClient(timeout=120.0) as client:
        response = await client.post(
            f"{url}/v1/chat/completions",
            json={
                "messages": [m.model_dump() for m in messages],
                "temperature": kwargs.get("temperature", 0.7),
                "max_tokens": kwargs.get("max_tokens", 2048),
            }
        )
        response.raise_for_status()
        return response.json()

async def call_ollama(url: str, model: str, messages: list[Message], **kwargs) -> dict:
    """Call an Ollama server"""
    async with httpx.AsyncClient(timeout=120.0) as client:
        response = await client.post(
            f"{url}/api/chat",
            json={
                "model": model,
                "messages": [m.model_dump() for m in messages],
                "stream": False,
                "options": {
                    "temperature": kwargs.get("temperature", 0.7),
                    "num_predict": kwargs.get("max_tokens", 2048),
                }
            }
        )
        response.raise_for_status()
        data = response.json()
        
        # Convert Ollama response to OpenAI format
        return {
            "id": f"ollama-{int(time.time())}",
            "object": "chat.completion",
            "created": int(time.time()),
            "model": model,
            "choices": [{
                "index": 0,
                "message": {
                    "role": "assistant",
                    "content": data.get("message", {}).get("content", "")
                },
                "finish_reason": "stop"
            }],
            "usage": {
                "prompt_tokens": data.get("prompt_eval_count", 0),
                "completion_tokens": data.get("eval_count", 0),
                "total_tokens": data.get("prompt_eval_count", 0) + data.get("eval_count", 0)
            }
        }

async def validate_response(
    original_messages: list[Message],
    response_content: str,
    validation_backend: str = "ryzen-ai"
) -> dict:
    """
    Run the response through a validation model to check for issues.
    
    This implements the "expensive generation, cheap validation" pattern:
    fast inference on Aegis, thorough validation on Ryzen-AI's Phi-3.
    """
    config = BACKEND_CONFIG[validation_backend]
    url = f"http://{config['tailscale_hostname']}:{config['port']}"
    
    validation_prompt = f"""You are a response validator. Review this AI response for quality issues.

ORIGINAL REQUEST:
{original_messages[-1].content if original_messages else 'N/A'}

AI RESPONSE:
{response_content}

Check for:
1. Factual accuracy - Are there any hallucinated facts or incorrect statements?
2. Completeness - Does the response fully address the request?
3. Security issues - If code, are there any security vulnerabilities?
4. Logical consistency - Are there any contradictions or logical errors?

Respond with ONLY a JSON object:
{{"valid": true/false, "confidence": 0.0-1.0, "issues": ["issue1", "issue2"], "severity": "none/low/medium/high"}}"""

    validation_messages = [Message(role="user", content=validation_prompt)]
    
    try:
        result = await call_ollama(
            url,
            config["models"]["validation"],
            validation_messages,
            temperature=0.1,  # Low temp for consistent validation
            max_tokens=500
        )
        
        # Parse validation result
        content = result["choices"][0]["message"]["content"]
        # Try to extract JSON from response
        try:
            # Handle potential markdown code blocks
            if "```json" in content:
                content = content.split("```json")[1].split("```")[0]
            elif "```" in content:
                content = content.split("```")[1].split("```")[0]
            
            validation_result = json.loads(content.strip())
            return validation_result
        except json.JSONDecodeError:
            return {"valid": True, "confidence": 0.5, "issues": ["Could not parse validation"], "severity": "low"}
            
    except Exception as e:
        # Don't fail the whole request if validation fails
        return {"valid": True, "confidence": 0.0, "issues": [f"Validation error: {str(e)}"], "severity": "unknown"}

# ============================================================================
# FastAPI Application
# ============================================================================

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown logic"""
    # Start background task to periodically check backend health
    async def health_check_loop():
        while True:
            await refresh_all_backend_status()
            await asyncio.sleep(30)  # Check every 30 seconds
    
    task = asyncio.create_task(health_check_loop())
    
    # Initial health check
    await refresh_all_backend_status()
    print("🚀 Orchestrator started. Backend status:")
    for backend_id, status in backend_status.items():
        emoji = "✅" if status.status == "online" else "❌"
        print(f"   {emoji} {status.name}: {status.status}")
    
    yield
    
    task.cancel()

app = FastAPI(
    title="Zero-Trust Hybrid AI Orchestrator",
    description="Intelligent routing layer for distributed LLM inference",
    version="1.0.0",
    lifespan=lifespan
)

# Enable CORS for local development tools
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    """Orchestrator status and information"""
    return {
        "service": "Zero-Trust Hybrid AI Orchestrator",
        "version": "1.0.0",
        "backends": {
            bid: {
                "name": status.name,
                "status": status.status,
                "latency_ms": status.latency_ms
            }
            for bid, status in backend_status.items()
        },
        "endpoints": {
            "chat": "/v1/chat/completions",
            "health": "/health",
            "backends": "/backends"
        }
    }

@app.get("/health")
async def health():
    """Health check endpoint"""
    online_count = sum(1 for s in backend_status.values() if s.status == "online")
    return {
        "status": "healthy" if online_count > 0 else "degraded",
        "backends_online": online_count,
        "backends_total": len(BACKEND_CONFIG)
    }

@app.get("/backends")
async def list_backends(refresh: bool = False):
    """List all configured backends and their status"""
    if refresh:
        await refresh_all_backend_status()
    
    return {
        "backends": [
            {
                "id": bid,
                **status.model_dump(),
                "config": {
                    "api_type": BACKEND_CONFIG[bid]["api_type"],
                    "capabilities": BACKEND_CONFIG[bid]["capabilities"],
                    "typical_speed": BACKEND_CONFIG[bid].get("typical_speed", "unknown")
                }
            }
            for bid, status in backend_status.items()
        ]
    }


@app.post("/analyze")
async def analyze_text(request: AnalyzeRequest):
    """
    Analyze text for sensitive data - Demo mode with verbose output.
    Shows the complete 4-tier classification pipeline.

    This endpoint is designed for demos and debugging - it shows:
    - Raw Presidio detection results
    - 4-tier classification breakdown
    - Routing decision with explanation
    - Backend connectivity status
    - Anonymized audit-safe version
    """
    from sensitive_routing import analyze_and_route_dict, get_analyzer

    sensitivity = analyze_and_route_dict(request.text, allow_cloud=False)

    tier3_clear = (
        not sensitivity['tier0_protected'] and
        len(sensitivity['tier1_high_entities']) == 0 and
        len(sensitivity['tier2_medium_entities']) == 0
    )

    # Get raw Presidio results for demo purposes
    presidio_results = []
    try:
        analyzer = get_analyzer()
        if analyzer != "fallback":
            raw_results = analyzer.analyze(text=request.text, language='en')
            presidio_results = [
                {
                    "entity_type": r.entity_type,
                    "text": request.text[r.start:r.end],
                    "confidence": round(r.score, 3),
                    "position": f"{r.start}-{r.end}"
                }
                for r in raw_results
            ]
    except Exception as e:
        presidio_results = [{"error": str(e)}]

    # Check backend connectivity
    backend_connectivity = {}
    async with httpx.AsyncClient(timeout=2.0) as client:
        for name, config in BACKEND_CONFIG.items():
            try:
                url = config.get('url', f"http://{config['tailscale_hostname']}:{config['port']}")
                url = url.rstrip('/')
                if 'ollama' in config.get('api_type', '') or '11434' in str(config.get('port', '')):
                    health_url = f"{url}/api/tags"
                else:
                    health_url = f"{url}/health"
                resp = await client.get(health_url)
                backend_connectivity[name] = {
                    "status": "online",
                    "latency_ms": round(resp.elapsed.total_seconds() * 1000, 1),
                    "url": url
                }
            except Exception as e:
                backend_connectivity[name] = {
                    "status": "offline",
                    "error": str(type(e).__name__),
                    "url": config.get('url', f"http://{config['tailscale_hostname']}:{config['port']}")
                }

    # Generate human-readable routing reason
    if sensitivity['tier1_high_entities']:
        reason = f"LOCAL ONLY - Found {len(sensitivity['tier1_high_entities'])} high-risk entities (SSN, names, credentials)"
    elif sensitivity['tier0_protected']:
        reason = "LOCAL ONLY - Protected context detected (medical/healthcare keywords)"
    elif sensitivity['tier2_medium_entities']:
        reason = f"ANONYMIZE - Found {len(sensitivity['tier2_medium_entities'])} medium-risk entities (IPs, device IDs)"
    elif tier3_clear:
        reason = "ANY BACKEND - No sensitive data detected"
    else:
        reason = "LOCAL (default safe routing)"

    return {
        "input_preview": request.text[:80] + "..." if len(request.text) > 80 else request.text,
        "classification": {
            "tier0_protected": sensitivity['tier0_protected'],
            "tier1_high": len(sensitivity['tier1_high_entities']),
            "tier2_medium": len(sensitivity['tier2_medium_entities']),
            "tier3_clear": tier3_clear
        },
        "routing": {
            "decision": sensitivity['route'],
            "reason": reason
        },
        "presidio_detected": presidio_results,
        "entities": {
            "tier1_high": sensitivity['tier1_high_entities'],
            "tier2_medium": sensitivity['tier2_medium_entities']
        },
        "backends": backend_connectivity,
        "audit_safe_text": sensitivity.get('audit_safe_text', '[unavailable]')
    }


@app.post("/v1/chat/completions")
async def chat_completion(request: ChatCompletionRequest, background_tasks: BackgroundTasks):
    """
    OpenAI-compatible chat completion endpoint.
    
    This is the main entry point for inference requests. It:
    1. Analyzes the request to determine task type
    2. Selects the optimal backend based on task type and availability
    3. Routes the request to the selected backend
    4. Optionally validates the response through a second model
    5. Returns the result in OpenAI-compatible format
    """
    start_time = time.time()
    
    # Select appropriate backend
    backend_id, config, sensitivity = select_backend(request)
    url = f"http://{config['tailscale_hostname']}:{config['port']}"
    
    # Determine which model to use
    if config["api_type"] == "ollama":
        task_type = request.task_type or "general"
        model = config.get("models", {}).get(task_type, config.get("default_model", "llama3.2:3b"))
    else:
        model = config.get("default_model", "llama-3.1-8b")
    
    # Make the inference call
    try:
        if config["api_type"] == "llama.cpp":
            result = await call_llama_cpp(
                url, 
                request.messages,
                temperature=request.temperature,
                max_tokens=request.max_tokens
            )
        else:
            result = await call_ollama(
                url,
                model,
                request.messages,
                temperature=request.temperature,
                max_tokens=request.max_tokens
            )
    except httpx.HTTPError as e:
        raise HTTPException(
            status_code=502,
            detail=f"Backend '{backend_id}' request failed: {str(e)}"
        )
    
    # Optional validation pass
    validation_result = None
    if request.require_validation and backend_id != "ryzen-ai":
        response_content = result["choices"][0]["message"]["content"]
        validation_result = await validate_response(
            request.messages,
            response_content,
            "ryzen-ai"
        )
    
    # Add orchestration metadata to response
    result["orchestration"] = {
        "backend": backend_id,
        "backend_name": config["name"],
        "model": model,
        "latency_ms": round((time.time() - start_time) * 1000, 2),
        "validation": validation_result
    }
    
    return result

@app.post("/v1/embeddings")
async def create_embedding(texts: list[str]):
    """Create embeddings using Ryzen-AI's embedding model"""
    config = BACKEND_CONFIG["ryzen-ai"]
    url = f"http://{config['tailscale_hostname']}:{config['port']}"
    
    async with httpx.AsyncClient(timeout=60.0) as client:
        response = await client.post(
            f"{url}/api/embeddings",
            json={
                "model": config["models"]["embedding"],
                "prompt": texts[0] if len(texts) == 1 else texts
            }
        )
        response.raise_for_status()
        return response.json()

# ============================================================================
# CLI for testing
# ============================================================================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
