# HOW THE 4-TIER CLASSIFICATION WORKS

## Understanding the Routing Logic

When a query comes into the orchestrator, it goes through a pipeline that decides where to process it. The goal is simple: keep sensitive data local, let safe data go anywhere.

### The Pipeline

```
User Query -> Presidio Analysis -> Tier Classification -> Routing Decision -> Backend Selection
```

Each step builds on the previous one.

---

## Step 1: Presidio Scans the Text

Presidio is Microsoft's open-source PII detection library. It uses trained ML models to recognize patterns in text. When we pass it a string, it returns a list of detected entities with confidence scores.

```python
from presidio_analyzer import AnalyzerEngine

analyzer = AnalyzerEngine()
results = analyzer.analyze(text="Patient Maria Garcia, SSN 987-65-4321", language='en')

# Returns something like:
# [
#   {"entity_type": "PERSON", "start": 8, "end": 20, "score": 0.85},
#   {"entity_type": "US_SSN", "start": 26, "end": 37, "score": 0.95}
# ]
```

Presidio does not know anything about our tier system. It just finds entities and tells us what they are. The intelligence comes in the next step.

---

## Step 2: We Classify Entities into Tiers

This is where our code takes over. We have two Python sets that define which entity types belong to which risk level:

```python
# High-risk entities - if Presidio finds any of these, route LOCAL
TIER1_HIGH_ENTITIES = {
    "PERSON",              # Names
    "US_SSN",              # Social Security Numbers
    "EMAIL_ADDRESS",       # Email addresses
    "PHONE_NUMBER",        # Phone numbers
    "CREDIT_CARD",         # Credit card numbers
    "US_DRIVER_LICENSE",   # Driver's license
    "PASSPORT",            # Passport numbers
    "PASSWORD",            # Passwords
    "API_KEY",             # API keys
    "SECRET_KEY",          # Secret keys
    # ... about 30 more entity types
}

# Medium-risk entities - can be anonymized before cloud
TIER2_MEDIUM_ENTITIES = {
    "IP_ADDRESS",          # IP addresses
    "MAC_ADDRESS",         # MAC addresses
    "DEVICE_ID",           # Device identifiers
    "HOSTNAME",            # Hostnames
    "URL",                 # URLs
    "EMPLOYEE_ID",         # Employee IDs
    # ... about 10 more entity types
}
```

The classification function loops through Presidio results and sorts them:

```python
def _classify_entities(presidio_results):
    tier1_high = []
    tier2_medium = []

    for entity in presidio_results:
        if entity["entity_type"] in TIER1_HIGH_ENTITIES:
            tier1_high.append(entity)
        elif entity["entity_type"] in TIER2_MEDIUM_ENTITIES:
            tier2_medium.append(entity)

    return tier1_high, tier2_medium
```

If Presidio finds a PERSON entity, it goes in the tier1_high list. If it finds an IP_ADDRESS, it goes in tier2_medium.

---

## Step 3: Keyword Scanning for Protected Context

Here is where we have a limitation to be honest about.

Presidio is great at finding specific data patterns like SSNs and credit cards. But it does not understand context. The phrase "the patient's vitals look stable" contains no identifiable entities, but it is clearly medical data that should stay local.

To handle this, we have a keyword scanner:

```python
TIER0_PROTECTED_KEYWORDS = {
    "patient", "diagnosis", "prognosis", "treatment", "prescription",
    "medication", "dosage", "symptoms", "medical history", "allergies",
    "blood pressure", "heart rate", "temperature", "vitals", "bmi",
    "hipaa", "phi", "protected health", "medical record", "ehr", "emr",
    # ... more healthcare terms
}

def _detect_tier0_protected(text: str) -> bool:
    text_lower = text.lower()
    for keyword in TIER0_PROTECTED_KEYWORDS:
        if keyword in text_lower:
            return True
    return False
```

**This is a hardcoded Python set, which is a known limitation.** It works for healthcare (HIPAA) because that is what we built this for, but if you wanted to protect financial data (PCI-DSS), legal data (attorney-client privilege), or education data (FERPA), you would have to manually add more keyword sets.

A better approach would be to use Presidio custom recognizers to train domain-specific context detection, or use a small text classifier model. That is future work for this project.

---

## Step 4: The Routing Decision

Now we have all the information we need. The routing logic is straightforward:

```python
def determine_route(tier0_protected, tier1_high, tier2_medium):

    if tier1_high:
        # Found SSN, name, credential, etc.
        # This data NEVER leaves local infrastructure
        return "local"

    elif tier0_protected:
        # Medical context detected via keywords
        # Conservative approach: treat as high risk
        return "local"

    elif tier2_medium:
        # Found IPs, device IDs, etc.
        # Can go to cloud IF we anonymize first
        return "anonymize_cloud"

    else:
        # Nothing sensitive detected
        # Safe to process anywhere
        return "any"
```

The order matters. We check tier1 first because specific identifiable data always beats general context.

---

## Example Classifications

### Query: "Patient Maria Garcia, SSN 987-65-4321, at IP 192.168.1.50"

**Presidio finds:**
- PERSON (Maria Garcia) -> goes to tier1_high
- US_SSN (987-65-4321) -> goes to tier1_high
- IP_ADDRESS (192.168.1.50) -> goes to tier2_medium

**Keyword scan:**
- "Patient" matches TIER0_PROTECTED_KEYWORDS -> tier0_protected = True

**Final classification:**
```
tier0_protected = True
tier1_high = 2 entities
tier2_medium = 1 entity
tier3_clear = False
```

**Routing decision:** LOCAL (because tier1_high has entities)

---

### Query: "The patient's vitals look stable today"

**Presidio finds:** nothing

**Keyword scan:**
- "patient" matches -> tier0_protected = True
- "vitals" matches -> tier0_protected = True

**Final classification:**
```
tier0_protected = True
tier1_high = 0 entities
tier2_medium = 0 entities
tier3_clear = False
```

**Routing decision:** LOCAL (because tier0_protected is True)

---

### Query: "Server at 192.168.1.100 needs a restart"

**Presidio finds:**
- IP_ADDRESS (192.168.1.100) -> goes to tier2_medium

**Keyword scan:** no matches

**Final classification:**
```
tier0_protected = False
tier1_high = 0 entities
tier2_medium = 1 entity
tier3_clear = False
```

**Routing decision:** ANONYMIZE_CLOUD (or LOCAL if cloud not enabled)

---

### Query: "What is the square root of 144?"

**Presidio finds:** nothing

**Keyword scan:** no matches

**Final classification:**
```
tier0_protected = False
tier1_high = 0 entities
tier2_medium = 0 entities
tier3_clear = True
```

**Routing decision:** ANY (safe for any backend)

---

## Quick Reference Chart

| Tier | Classification | What Triggers It | Routing |
|------|----------------|------------------|---------|
| tier0 | PROTECTED | Keyword match (patient, diagnosis, vitals, etc.) | LOCAL ONLY |
| tier1 | HIGH | Presidio finds SSN, name, credential, medical ID | LOCAL ONLY |
| tier2 | MEDIUM | Presidio finds IP, device ID, hostname | ANONYMIZE -> cloud ok |
| tier3 | CLEAR | Nothing triggers above | ANY backend |

---

## Known Limitations and Future Work

**Tier 0 is hardcoded.** The keyword-based context detection only works for healthcare right now. To support other regulated domains:

- Financial (PCI-DSS, SOX): Would need keywords like "account balance", "wire transfer", "cardholder data"
- Legal (Attorney-Client): Would need keywords like "privileged", "litigation hold", "settlement"
- Education (FERPA): Would need keywords like "student record", "transcript", "enrollment"

The better solution is to create Presidio custom recognizers for each domain:

```python
from presidio_analyzer import PatternRecognizer, Pattern

financial_recognizer = PatternRecognizer(
    supported_entity="FINANCIAL_CONTEXT",
    patterns=[
        Pattern("PCI terms", r"\b(cardholder|cvv|pci[\s-]?dss)\b", 0.7),
        Pattern("Banking", r"\b(wire transfer|ach|routing)\b", 0.6),
    ]
)

analyzer.registry.add_recognizer(financial_recognizer)
```

Then Presidio itself returns FINANCIAL_CONTEXT as an entity type, and our tier classification handles it like any other entity. No more hardcoded keyword sets.

This is on the roadmap but not implemented in the current release.

---

## Why This Matters for Security

The key insight is that we fail closed. If anything looks even slightly risky, we keep it local. The only way data reaches the cloud is if:

1. Presidio finds zero tier1 or tier2 entities
2. No protected context keywords match
3. Cloud routing is explicitly enabled

Three conditions must all be true. One failure anywhere in the chain means local processing. This is the zero-trust model in action.

---

## Testing the Classification

Use the `/analyze` endpoint to test classification:

```bash
# Tier 0 - Protected Context
curl -s -X POST http://localhost:8000/analyze \
  -H "Content-Type: application/json" \
  -d '{"text": "The patient vitals look stable today"}' | python3 -m json.tool

# Tier 1 - High Risk (SSN)
curl -s -X POST http://localhost:8000/analyze \
  -H "Content-Type: application/json" \
  -d '{"text": "SSN: 987-65-4321"}' | python3 -m json.tool

# Tier 2 - Medium Risk (IP)
curl -s -X POST http://localhost:8000/analyze \
  -H "Content-Type: application/json" \
  -d '{"text": "Server 192.168.1.100 needs restart"}' | python3 -m json.tool

# Tier 3 - Clear
curl -s -X POST http://localhost:8000/analyze \
  -H "Content-Type: application/json" \
  -d '{"text": "What is the square root of 144?"}' | python3 -m json.tool
```

The response shows the complete classification breakdown including raw Presidio results, tier assignments, and routing decision with explanation.
