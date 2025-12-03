"""
sensitive_routing.py

Zero-Trust Hybrid AI Pipeline - Sensitive Data Router

Based on contributions from:
- Sheniese Aracena-Baez (Shay): 4-tier routing architecture, HIPAA focus
- Javier Acosta: Presidio integration, Streamlit UI patterns

This module provides intelligent routing for AI queries based on data sensitivity:

4-Tier Classification System:
- Tier 0 (PROTECTED)   → Keyword match (patient, diagnosis, vitals) → LOCAL ONLY
- Tier 1 (HIGH RISK)   → Presidio: SSN, names, credentials → LOCAL ONLY
- Tier 2 (MEDIUM RISK) → Presidio: IPs, device IDs → ANONYMIZE → Cloud Allowed
- Tier 3 (CLEAR)       → Nothing detected → ANY backend

HIPAA Compliance Notes:
- PHI (Protected Health Information) ALWAYS routes to Tier 0 or Tier 1
- No PHI ever transmitted to cloud services
- Anonymized data in Tier 2 has all identifiers replaced with placeholders
- Audit logging uses anonymized versions only

Integration with Zero-Trust Pipeline:
- Tier 0/1 → Route to Aegis (llama.cpp, port 8080) or Ryzen-AI (Ollama, port 11434)
- Tier 2   → Anonymize, then route to local OR cloud (configurable)
- Tier 3   → Route to fastest available (local preferred, cloud optional)

Known Limitations:
- Tier 0 uses hardcoded keyword set (TIER0_PROTECTED_KEYWORDS)
- Future: Replace with Presidio custom recognizers for domain-specific context
"""

from enum import Enum
from typing import List, Dict, Any, Optional, Tuple
from dataclasses import dataclass
import re
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("sensitive_routing")

# ============================================================================
# ROUTING OUTCOMES
# ============================================================================

class Route(str, Enum):
    """Routing decisions for incoming queries."""
    LOCAL = "local"                    # Tier 1: High risk, local only
    ANONYMIZE_CLOUD = "anonymize_cloud" # Tier 2: Medium risk, anonymize first
    CLOUD = "cloud"                    # Tier 3: Safe, cloud allowed


class Backend(str, Enum):
    """Available inference backends."""
    AEGIS = "aegis"           # RTX 4080 Super, llama.cpp, port 8080
    RYZEN_AI = "ryzen-ai"  # 128GB RAM, Ollama, port 11434
    AWS_BEDROCK = "aws-bedrock" # Cloud Claude 3.5
    NEXUS = "nexus"           # Mac Mini M4 Pro, backup


@dataclass
class RoutingDecision:
    """Complete routing decision with metadata."""
    route: Route
    backend: Backend
    original_text: str
    payload_text: str  # Anonymized if Tier 2
    tier1_high_entities: List[Dict]
    tier2_medium_entities: List[Dict]
    confidence: float
    tier0_protected: bool
    tier3_clear: bool
    audit_safe_text: str  # Always anonymized for logging


# ============================================================================
# PRESIDIO INTEGRATION
# ============================================================================

# Lazy loading to avoid import errors if presidio not installed
_analyzer = None
_anonymizer = None

def get_analyzer():
    """Lazy load Presidio AnalyzerEngine."""
    global _analyzer
    if _analyzer is None:
        try:
            from presidio_analyzer import AnalyzerEngine
            _analyzer = AnalyzerEngine()
            logger.info("Presidio AnalyzerEngine initialized")
        except ImportError:
            logger.warning("Presidio not installed, using fallback regex detection")
            _analyzer = "fallback"
    return _analyzer

def get_anonymizer():
    """Lazy load Presidio AnonymizerEngine."""
    global _anonymizer
    if _anonymizer is None:
        try:
            from presidio_anonymizer import AnonymizerEngine
            _anonymizer = AnonymizerEngine()
            logger.info("Presidio AnonymizerEngine initialized")
        except ImportError:
            logger.warning("Presidio not installed, using fallback anonymization")
            _anonymizer = "fallback"
    return _anonymizer


# ============================================================================
# SENSITIVITY TIERS (Shay's contribution - enhanced)
# ============================================================================

# Tier 1 HIGH (HIGH RISK): NEVER send raw text to cloud
# These trigger immediate local-only routing
TIER1_HIGH_ENTITIES = {
    # === HIPAA Identifiers (18 Safe Harbor identifiers) ===
    "PERSON",              # Names
    "EMAIL_ADDRESS",       # Email
    "PHONE_NUMBER",        # Phone/Fax
    "US_SSN",              # SSN (Social Security Number)
    "SSN",                 # Alias
    "DATE_TIME",           # DOB, admission/discharge dates
    "LOCATION",            # Geographic data smaller than state
    "ADDRESS",             # Street address
    "ZIP_CODE",            # Zip codes (first 3 digits of small populations)
    
    # === Additional Medical Identifiers ===
    "MEDICAL_LICENSE",     # Medical license numbers
    "US_DRIVER_LICENSE",   # Driver's license
    "DRIVERS_LICENSE",     # Alias
    "PASSPORT",            # Passport number
    "US_PASSPORT",         # Alias
    "US_BANK_NUMBER",      # Account numbers
    "CREDIT_CARD",         # Credit card
    "IBAN_CODE",           # International bank
    "BANK_ACCOUNT",        # Bank account
    "ROUTING_NUMBER",      # Routing number
    
    # === Credentials & Secrets ===
    "PASSWORD",            # Passwords
    "USERNAME",            # Usernames (in auth context)
    "AUTH_TOKEN",          # Authentication tokens
    "API_KEY",             # API keys
    "SECRET_KEY",          # Secret keys
    "PRIVATE_KEY",         # Private keys
    "ACCESS_TOKEN",        # Access tokens
    "AWS_ACCESS_KEY",      # AWS credentials
    "AZURE_KEY",           # Azure credentials
    "GCP_KEY",             # GCP credentials
    
    # === Healthcare Specific ===
    "NRP",                 # Nationality/Religion/Political (sensitive)
    "MEDICAL_RECORD",      # MRN (Medical Record Number)
    "HEALTH_PLAN_ID",      # Health plan beneficiary number
    "DEVICE_IDENTIFIER",   # Medical device identifiers
    "BIOMETRIC",           # Biometric identifiers
    "GENETIC_DATA",        # Genetic information
}

# Tier 2 MEDIUM (MEDIUM RISK): Allowed after anonymization
# Can be sent to cloud if identifiers are replaced
TIER2_MEDIUM_ENTITIES = {
    "IP_ADDRESS",          # IP addresses
    "MAC_ADDRESS",         # MAC addresses
    "DEVICE_ID",           # Device identifiers (non-medical)
    "HOSTNAME",            # Hostnames
    "URL",                 # URLs (may contain IDs)
    "EMPLOYEE_ID",         # Employee IDs
    "VENDOR_ID",           # Vendor IDs
    "PROJECT_CODE",        # Project codes
    "TICKET_ID",           # Ticket/case IDs
    "DOMAIN_NAME",         # Domain names
    "FILE_PATH",           # File paths
}

# Tier 0 PROTECTED: Healthcare keywords that elevate to local-only even without detected entities
# NOTE: This is a hardcoded Python set - known limitation. Future: use Presidio custom recognizers.
TIER0_PROTECTED_KEYWORDS = {
    # Medical terms
    "patient", "diagnosis", "prognosis", "treatment", "prescription",
    "medication", "dosage", "symptoms", "medical history", "allergies",
    "blood pressure", "heart rate", "temperature", "vitals", "bmi",
    "lab results", "test results", "imaging", "x-ray", "mri", "ct scan",
    
    # Healthcare context
    "hipaa", "phi", "protected health", "medical record", "ehr", "emr",
    "healthcare", "clinic", "hospital", "physician", "nurse", "doctor",
    "insurance", "claim", "billing code", "icd-10", "cpt code",
    
    # Specific identifiers mentioned
    "ssn", "social security", "date of birth", "dob", "mrn",
    "policy number", "member id", "subscriber id",
}

# Confidence thresholds (tunable based on risk tolerance)
MIN_CONFIDENCE_TIER1 = 0.50  # Lower threshold = more conservative (safer)
MIN_CONFIDENCE_TIER2 = 0.70  # Higher threshold = fewer false positives


# ============================================================================
# FALLBACK REGEX PATTERNS (when Presidio not available)
# ============================================================================

FALLBACK_PATTERNS = {
    "US_SSN": r"\b\d{3}-\d{2}-\d{4}\b",
    "PHONE_NUMBER": r"\b(?:\+1[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b",
    "EMAIL_ADDRESS": r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b",
    "CREDIT_CARD": r"\b(?:\d{4}[-\s]?){3}\d{4}\b",
    "DATE_TIME": r"\b(?:DOB|Date of Birth|Born|Admitted|Discharged)[\s:]*\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b",
    "IP_ADDRESS": r"\b(?:\d{1,3}\.){3}\d{1,3}\b",
    "MEDICAL_RECORD": r"\b(?:MRN|Medical Record|Patient ID)[\s:#]*[A-Z0-9]+\b",
    "PERSON": r"\b(?:Mr\.|Mrs\.|Ms\.|Dr\.|Patient|Name)[\s:]+[A-Z][a-z]+(?:\s+[A-Z][a-z]+)+\b",
}


# ============================================================================
# CORE DETECTION FUNCTIONS
# ============================================================================

def _detect_with_presidio(text: str) -> List[Dict]:
    """Detect entities using Presidio."""
    analyzer = get_analyzer()
    
    if analyzer == "fallback":
        return _detect_with_regex(text)
    
    try:
        from presidio_analyzer import RecognizerResult
        results = analyzer.analyze(text=text, language="en")
        
        return [
            {
                "type": r.entity_type,
                "start": r.start,
                "end": r.end,
                "score": r.score,
                "text": text[r.start:r.end],
            }
            for r in results
        ]
    except Exception as e:
        logger.error(f"Presidio analysis failed: {e}, falling back to regex")
        return _detect_with_regex(text)


def _detect_with_regex(text: str) -> List[Dict]:
    """Fallback regex-based detection when Presidio unavailable."""
    results = []
    
    for entity_type, pattern in FALLBACK_PATTERNS.items():
        for match in re.finditer(pattern, text, re.IGNORECASE):
            results.append({
                "type": entity_type,
                "start": match.start(),
                "end": match.end(),
                "score": 0.85,  # Fixed confidence for regex matches
                "text": match.group(),
            })
    
    return results


def _detect_tier0_protected(text: str) -> bool:
    """Check for Tier 0 protected keywords that indicate sensitive context (e.g., healthcare)."""
    text_lower = text.lower()
    return any(keyword in text_lower for keyword in TIER0_PROTECTED_KEYWORDS)


def _classify_entities(
    results: List[Dict]
) -> Tuple[List[Dict], List[Dict]]:
    """
    Classify detected entities into Tier 1 High and Tier 2 Medium.

    Returns:
        Tuple of (tier1_high_entities, tier2_medium_entities)
    """
    tier1_high = []
    tier2_medium = []

    for r in results:
        entity_type = r["type"]
        score = r.get("score", 0.0)

        if entity_type in TIER1_HIGH_ENTITIES and score >= MIN_CONFIDENCE_TIER1:
            tier1_high.append(r)
        elif entity_type in TIER2_MEDIUM_ENTITIES and score >= MIN_CONFIDENCE_TIER2:
            tier2_medium.append(r)

    return tier1_high, tier2_medium


# ============================================================================
# ANONYMIZATION
# ============================================================================

def _anonymize_with_presidio(text: str, entities: List[Dict]) -> str:
    """Anonymize text using Presidio."""
    if not entities:
        return text
    
    anonymizer = get_anonymizer()
    
    if anonymizer == "fallback":
        return _anonymize_with_regex(text, entities)
    
    try:
        from presidio_analyzer import RecognizerResult
        
        # Convert our dict format back to RecognizerResult
        presidio_results = [
            RecognizerResult(
                entity_type=e["type"],
                start=e["start"],
                end=e["end"],
                score=e["score"],
            )
            for e in entities
        ]
        
        result = anonymizer.anonymize(
            text=text,
            analyzer_results=presidio_results,
        )
        return result.text
    except Exception as e:
        logger.error(f"Presidio anonymization failed: {e}, using regex fallback")
        return _anonymize_with_regex(text, entities)


def _anonymize_with_regex(text: str, entities: List[Dict]) -> str:
    """Fallback regex-based anonymization."""
    # Sort by start position descending to replace from end to start
    sorted_entities = sorted(entities, key=lambda x: x["start"], reverse=True)
    
    result = text
    for entity in sorted_entities:
        placeholder = f"<{entity['type']}>"
        result = result[:entity["start"]] + placeholder + result[entity["end"]:]
    
    return result


def anonymize_for_audit(text: str) -> str:
    """
    Create fully anonymized version for audit logs.
    ALL detected entities are replaced, regardless of tier.
    """
    results = _detect_with_presidio(text)
    return _anonymize_with_presidio(text, results) if results else text


# ============================================================================
# BACKEND SELECTION
# ============================================================================

def _select_backend(route: Route, task_type: str = "general") -> Backend:
    """
    Select the appropriate backend based on route and task type.
    
    Args:
        route: The routing decision (LOCAL, ANONYMIZE_CLOUD, CLOUD)
        task_type: Type of task (general, code, validation, embedding)
    
    Returns:
        The selected backend
    """
    if route == Route.LOCAL:
        # Always use local infrastructure
        if task_type in ["code", "validation", "embedding"]:
            return Backend.RYZEN_AI  # Multi-model specialist
        else:
            return Backend.AEGIS  # Fastest for general queries
    
    elif route == Route.ANONYMIZE_CLOUD:
        # Prefer local, but cloud allowed after anonymization
        # For now, still route to local (safer default)
        return Backend.AEGIS
    
    else:  # Route.CLOUD
        # Safe data - can use cloud if available, otherwise local
        # Default to local (faster, no network dependency)
        return Backend.AEGIS


# ============================================================================
# MAIN ROUTING FUNCTION (Shay's design - enhanced)
# ============================================================================

def analyze_and_route(
    text: str,
    task_type: str = "general",
    allow_cloud: bool = False,
) -> RoutingDecision:
    """
    Analyze input text and determine routing decision.

    This is the main entry point for the 4-tier routing system.

    Args:
        text: The user's input text/query
        task_type: Type of task (general, code, validation, embedding)
        allow_cloud: Whether cloud routing is allowed (default: False for safety)

    Returns:
        RoutingDecision with full metadata

    Example:
        >>> result = analyze_and_route("Patient John Smith, SSN 123-45-6789")
        >>> result.route
        Route.LOCAL
        >>> result.backend
        Backend.AEGIS
        >>> result.tier0_protected
        True
    """

    # 1. Detect entities with Presidio (or fallback)
    results = _detect_with_presidio(text)

    # 2. Classify into tiers
    tier1_high, tier2_medium = _classify_entities(results)

    # 3. Check for Tier 0 protected keywords (elevates to local-only)
    tier0_protected = _detect_tier0_protected(text)

    # 4. Determine route
    if tier1_high:
        # TIER 1 HIGH: High risk - LOCAL ONLY, no exceptions
        route = Route.LOCAL
        payload = text  # Raw text stays local
        confidence = max(e["score"] for e in tier1_high)

    elif tier0_protected:
        # TIER 0 PROTECTED: Keywords detected but no entities
        # Conservative approach: treat as high risk
        route = Route.LOCAL
        payload = text
        confidence = 0.7  # Keyword-based confidence

    elif tier2_medium:
        # TIER 2 MEDIUM: Medium risk - Anonymize if cloud needed
        if allow_cloud:
            route = Route.ANONYMIZE_CLOUD
            payload = _anonymize_with_presidio(text, tier2_medium)
        else:
            route = Route.LOCAL
            payload = text
        confidence = max(e["score"] for e in tier2_medium)

    else:
        # TIER 3 CLEAR: Safe - Cloud allowed
        if allow_cloud:
            route = Route.CLOUD
        else:
            route = Route.LOCAL
        payload = text
        confidence = 1.0  # High confidence it's safe

    # 5. Compute tier3_clear
    tier3_clear = (not tier0_protected and
                   len(tier1_high) == 0 and
                   len(tier2_medium) == 0)

    # 6. Select backend
    backend = _select_backend(route, task_type)

    # 7. Create audit-safe version (always anonymized)
    audit_safe = anonymize_for_audit(text)

    # 8. Build response
    return RoutingDecision(
        route=route,
        backend=backend,
        original_text=text,
        payload_text=payload,
        tier1_high_entities=tier1_high,
        tier2_medium_entities=tier2_medium,
        confidence=confidence,
        tier0_protected=tier0_protected,
        tier3_clear=tier3_clear,
        audit_safe_text=audit_safe,
    )


def analyze_and_route_dict(text: str, **kwargs) -> Dict[str, Any]:
    """
    Dictionary version of analyze_and_route for JSON serialization.

    Use this for API responses.
    """
    decision = analyze_and_route(text, **kwargs)

    return {
        "route": decision.route.value,
        "backend": decision.backend.value,
        "original_text": decision.original_text,
        "payload_text": decision.payload_text,
        "tier0_protected": decision.tier0_protected,
        "tier1_high_entities": decision.tier1_high_entities,
        "tier2_medium_entities": decision.tier2_medium_entities,
        "tier3_clear": decision.tier3_clear,
        "confidence": decision.confidence,
        "audit_safe_text": decision.audit_safe_text,
    }


# ============================================================================
# CONVENIENCE FUNCTIONS
# ============================================================================

def is_safe_for_cloud(text: str) -> bool:
    """Quick check if text is safe for cloud processing."""
    decision = analyze_and_route(text, allow_cloud=True)
    return decision.route == Route.CLOUD


def requires_local_only(text: str) -> bool:
    """Quick check if text requires local-only processing."""
    decision = analyze_and_route(text, allow_cloud=True)
    return decision.route == Route.LOCAL


def get_safe_payload(text: str) -> str:
    """Get anonymized version suitable for logging or cloud."""
    return anonymize_for_audit(text)


# ============================================================================
# TESTING
# ============================================================================

if __name__ == "__main__":
    # Test samples covering all 4 tiers
    samples = [
        # Tier 0: Protected context (keywords only, should route LOCAL)
        ("TIER 0 - Protected Context", "The patient's vitals look stable, blood pressure is improving."),
        ("TIER 0 - Protected Context", "Please review the diagnosis and treatment plan."),

        # Tier 1: High risk entities (should route LOCAL)
        ("TIER 1 - High Risk (SSN)", "Patient: Maria Garcia, DOB: 03/15/1962, SSN: 987-65-4321."),
        ("TIER 1 - High Risk (Phone)", "Call John Smith at 555-123-4567 regarding his prescription."),
        ("TIER 1 - High Risk (API Key)", "API_KEY=sk-1234567890abcdef, please don't share this."),

        # Tier 2: Medium risk (should route ANONYMIZE_CLOUD or LOCAL)
        ("TIER 2 - Medium Risk (IP)", "Server PROD-DB-01 is down, IP: 192.168.1.100, please investigate."),
        ("TIER 2 - Medium Risk (IDs)", "Check ticket ID TKT-2024-001 for employee EMP-5432."),

        # Tier 3: Clear (can route CLOUD)
        ("TIER 3 - Clear", "Explain the difference between symmetric and asymmetric encryption."),
        ("TIER 3 - Clear", "What are best practices for Kubernetes pod security?"),
        ("TIER 3 - Clear", "What is the square root of 144?"),
    ]

    print("=" * 70)
    print("ZERO-TRUST 4-TIER CLASSIFICATION TEST")
    print("=" * 70)

    for label, sample in samples:
        print(f"\n[{label}]")
        print(f"Input: {sample[:60]}...")
        result = analyze_and_route_dict(sample, allow_cloud=True)

        print(f"  Route: {result['route'].upper()}")
        print(f"  Backend: {result['backend']}")
        print(f"  Tier 0 Protected: {result['tier0_protected']}")
        print(f"  Tier 1 High: {len(result['tier1_high_entities'])} entities")
        print(f"  Tier 2 Medium: {len(result['tier2_medium_entities'])} entities")
        print(f"  Tier 3 Clear: {result['tier3_clear']}")

        if result['route'] == 'anonymize_cloud':
            print(f"  Payload: {result['payload_text'][:60]}...")

        print(f"  Audit Safe: {result['audit_safe_text'][:60]}...")

    print("\n" + "=" * 70)
    print("TEST COMPLETE")
    print("=" * 70)
