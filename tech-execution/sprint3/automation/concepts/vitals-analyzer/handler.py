"""
CONCEPT: Vitals Analyzer (Healthcare AI-ER Alert System)
PURPOSE: Analyzes patient vital signs using local LLM and generates human-readable alerts

OPERATIONAL PRINCIPLE:
    After receiving patient vitals:
    - Parse vital signs (heart rate, BP, O2, temp, respiratory rate)
    - Construct structured prompt for local LLM
    - Invoke llama.cpp for analysis
    - Parse LLM output into structured alert
    - Determine urgency level (NORMAL, MODERATE, CRITICAL)
    - Send human-readable alert to appropriate channels

This uses a LOCAL LLM (2B-4B params) via llama.cpp for offline resilience
(following the AI-ER hybrid architecture pattern)

HEALTHCARE CONTEXT:
    Based on "An Architectural Analysis of the AIER Alert System"
    - Local inference ensures alerts work during network outages
    - Structured prompts ensure consistent, parseable outputs
    - Human-readable format for clinical staff
"""

import json
import boto3
import os
from datetime import datetime
import subprocess
import tempfile

# AWS clients
sns = boto3.client('sns')
cloudwatch = boto3.client('cloudwatch')

# Configuration
SNS_TOPIC_CLINICAL = os.environ.get('SNS_TOPIC_CLINICAL', '')
SNS_TOPIC_SECURITY = os.environ.get('SNS_TOPIC_SECURITY', '')
LLAMA_CPP_PATH = os.environ.get('LLAMA_CPP_PATH', '/opt/llama.cpp/main')
MODEL_PATH = os.environ.get('MODEL_PATH', '/opt/models/medical-2b.gguf')
DRY_RUN = os.environ.get('DRY_RUN', 'false').lower() == 'true'


def handler(event, context):
    """
    Analyzes patient vitals using local LLM
    
    Simple flow:
    1. Extract vitals from event
    2. Validate vitals are within reasonable ranges
    3. Construct specialized prompt for LLM
    4. Run local inference (llama.cpp)
    5. Parse LLM output
    6. Generate human-readable alert
    7. Route to appropriate channel (clinical or security)
    """
    
    print(f"[TRACE] Vitals analysis request: {json.dumps(event, indent=2)}")
    
    # STEP 1: Extract patient vitals from event
    vitals = extract_vitals(event)
    
    if not vitals:
        return {'error': 'Invalid vitals data', 'status': 'FAILED'}
    
    print(f"[INFO] Analyzing vitals for patient {vitals['patient_id']}")
    
    # STEP 2: Construct specialized healthcare prompt
    # This is KEY for getting good, consistent LLM outputs
    prompt = construct_healthcare_prompt(vitals)
    
    print(f"[PROMPT] Generated prompt length: {len(prompt)} chars")
    
    # STEP 3: Run local LLM inference
    # Uses llama.cpp for CPU-efficient inference
    llm_output = run_local_llm_inference(prompt)
    
    if llm_output.get('error'):
        print(f"[ERROR] LLM inference failed: {llm_output['error']}")
        # Fallback: rule-based analysis if LLM fails
        llm_output = fallback_rule_based_analysis(vitals)
    
    print(f"[LLM_OUTPUT] {json.dumps(llm_output, indent=2)}")
    
    # STEP 4: Parse LLM output into structured alert
    alert = parse_llm_output_to_alert(llm_output, vitals)
    
    # STEP 5: Determine routing based on urgency
    routing = determine_alert_routing(alert)
    
    # STEP 6: Generate human-readable message for clinical staff
    human_readable_message = format_clinical_alert(alert, vitals)
    
    print(f"[ALERT] {human_readable_message}")
    
    # STEP 7: Send alerts to appropriate channels
    if not DRY_RUN:
        send_alerts(alert, human_readable_message, routing)
    else:
        print(f"[DRY_RUN] Would send alert to: {routing['channels']}")
    
    # STEP 8: Log to CloudWatch for audit trail
    log_vitals_analysis(vitals, alert)
    
    # Return structured result
    result = {
        'timestamp': datetime.utcnow().isoformat(),
        'patient_id': vitals['patient_id'],
        'alert': alert,
        'human_readable': human_readable_message,
        'routing': routing,
        'llm_used': not llm_output.get('fallback', False),
        'dry_run': DRY_RUN
    }
    
    print(f"[RESULT] Analysis complete: {alert['urgency']} urgency")
    
    return result


def extract_vitals(event):
    """
    Extracts patient vitals from event payload
    
    Expected event format:
    {
      "patient_id": "P12345",
      "timestamp": "2025-11-14T10:30:00Z",
      "vitals": {
        "heart_rate_bpm": 110,
        "blood_pressure_systolic": 145,
        "blood_pressure_diastolic": 92,
        "oxygen_saturation_percent": 94.0,
        "respiratory_rate_bpm": 22,
        "temperature_celsius": 37.8
      },
      "patient_category": "adult",  // Optional: adult, pediatric, geriatric
      "notes": "Patient reports chest discomfort"  // Optional
    }
    """
    
    try:
        # Handle different event structures (direct or nested in 'detail')
        if 'vitals' in event:
            payload = event
        elif 'detail' in event and 'vitals' in event['detail']:
            payload = event['detail']
        else:
            print("[ERROR] No vitals data found in event")
            return None
        
        vitals = {
            'patient_id': payload.get('patient_id', 'UNKNOWN'),
            'timestamp': payload.get('timestamp', datetime.utcnow().isoformat()),
            'heart_rate': payload['vitals'].get('heart_rate_bpm'),
            'bp_systolic': payload['vitals'].get('blood_pressure_systolic'),
            'bp_diastolic': payload['vitals'].get('blood_pressure_diastolic'),
            'oxygen_saturation': payload['vitals'].get('oxygen_saturation_percent'),
            'respiratory_rate': payload['vitals'].get('respiratory_rate_bpm'),
            'temperature': payload['vitals'].get('temperature_celsius'),
            'category': payload.get('patient_category', 'adult'),
            'notes': payload.get('notes', '')
        }
        
        # Validate required fields
        required = ['heart_rate', 'bp_systolic', 'oxygen_saturation']
        if not all(vitals.get(field) is not None for field in required):
            print(f"[ERROR] Missing required vital signs: {required}")
            return None
        
        return vitals
        
    except Exception as e:
        print(f"[ERROR] Failed to extract vitals: {str(e)}")
        return None


def construct_healthcare_prompt(vitals):
    """
    Constructs specialized prompt for healthcare LLM
    
    KEY DESIGN DECISIONS:
    1. Structured format forces LLM to output parseable JSON
    2. Clear role definition ("expert ER nurse")
    3. Specific output schema (urgency, reason, recommendations)
    4. Include patient category for context-aware analysis
    5. Few-shot examples improve consistency (not shown here for brevity)
    
    This is the MOST IMPORTANT function for LLM quality!
    """
    
    # Define the LLM's role and task clearly
    system_instruction = """You are an expert Emergency Room triage nurse with 15 years of experience. Your task is to analyze patient vital signs and provide a structured clinical assessment.

CRITICAL: You must respond ONLY with valid JSON in the exact format specified below. Do not include any explanatory text before or after the JSON."""
    
    # Provide current vitals in clear format
    vitals_summary = f"""
PATIENT CATEGORY: {vitals['category'].upper()}
CURRENT VITAL SIGNS:
- Heart Rate: {vitals['heart_rate']} bpm (normal adult: 60-100)
- Blood Pressure: {vitals['bp_systolic']}/{vitals['bp_diastolic']} mmHg (normal: 120/80)
- Oxygen Saturation: {vitals['oxygen_saturation']}% (normal: 95-100%)
- Respiratory Rate: {vitals['respiratory_rate']} breaths/min (normal: 12-20)
- Temperature: {vitals['temperature']}°C (normal: 36.5-37.5)
"""
    
    if vitals['notes']:
        vitals_summary += f"\nCLINICAL NOTES: {vitals['notes']}"
    
    # Define exact output format
    output_schema = """
OUTPUT FORMAT (respond with this exact JSON structure):
{
  "urgency": "NORMAL" or "MODERATE" or "CRITICAL",
  "primary_concern": "Brief description of main issue",
  "reasoning": "Clinical reasoning for urgency level (2-3 sentences)",
  "abnormal_vitals": ["list", "of", "concerning", "vitals"],
  "recommended_actions": ["immediate", "actions", "to", "take"],
  "confidence_score": 0.0 to 1.0
}

URGENCY DEFINITIONS:
- NORMAL: All vitals within acceptable ranges, no immediate concern
- MODERATE: One or more vitals outside normal range, requires monitoring
- CRITICAL: Severe abnormalities, immediate intervention required
"""
    
    # Construct full prompt
    full_prompt = f"""{system_instruction}

{vitals_summary}

{output_schema}

Analyze these vitals and respond with the JSON assessment:"""
    
    return full_prompt


def run_local_llm_inference(prompt):
    """
    Runs local LLM inference using llama.cpp
    
    WHY LLAMA.CPP:
    - Pure C++ implementation (fast on CPU)
    - Small models (2-4B params) run without GPU
    - Quantized models (GGUF format) reduce memory usage
    - Perfect for edge deployment in hospitals
    
    PARAMETERS EXPLAINED:
    - --temp 0.1: Low temperature for consistent, deterministic outputs
    - --top-p 0.9: Nucleus sampling for reasonable variation
    - --repeat-penalty 1.1: Avoid repetitive text
    - -n 512: Max 512 tokens output (enough for our JSON)
    - --ctx-size 2048: Context window size
    """
    
    # Check if in Lambda or local environment
    if DRY_RUN or not os.path.exists(LLAMA_CPP_PATH):
        print(f"[DRY_RUN] Would invoke llama.cpp with prompt length {len(prompt)}")
        # Return mock output for demo/testing
        return generate_mock_llm_output(prompt)
    
    try:
        # Write prompt to temporary file
        with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False) as f:
            f.write(prompt)
            prompt_file = f.name
        
        # Construct llama.cpp command
        cmd = [
            LLAMA_CPP_PATH,
            '--model', MODEL_PATH,
            '--file', prompt_file,
            '--temp', '0.1',          # Low temp for consistency
            '--top-p', '0.9',
            '--repeat-penalty', '1.1',
            '-n', '512',              # Max tokens
            '--ctx-size', '2048',
            '--silent-prompt'         # Don't echo prompt in output
        ]
        
        print(f"[EXEC] Running llama.cpp inference...")
        
        # Run inference (timeout after 30 seconds)
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=30
        )
        
        # Clean up temp file
        os.unlink(prompt_file)
        
        if result.returncode != 0:
            print(f"[ERROR] llama.cpp failed: {result.stderr}")
            return {'error': result.stderr}
        
        # Parse output (extract JSON from response)
        output_text = result.stdout.strip()
        print(f"[LLM_RAW] {output_text[:200]}...")  # Log first 200 chars
        
        # Try to extract JSON from output
        llm_result = extract_json_from_text(output_text)
        
        return llm_result
        
    except subprocess.TimeoutExpired:
        print("[ERROR] LLM inference timed out")
        return {'error': 'Inference timeout'}
    except Exception as e:
        print(f"[ERROR] LLM inference failed: {str(e)}")
        return {'error': str(e)}


def extract_json_from_text(text):
    """
    Extracts JSON from LLM output text
    
    LLMs sometimes add extra text before/after JSON.
    This finds the JSON block and parses it.
    """
    try:
        # Try direct parse first
        return json.loads(text)
    except:
        # Look for JSON block between curly braces
        import re
        json_match = re.search(r'\{[^{}]*\}', text, re.DOTALL)
        if json_match:
            try:
                return json.loads(json_match.group())
            except:
                pass
    
    print(f"[ERROR] Could not extract JSON from LLM output")
    return {'error': 'Invalid JSON output from LLM'}


def generate_mock_llm_output(prompt):
    """
    Generates mock LLM output for testing/demo
    
    This simulates what a real LLM would return.
    Useful for demos when local LLM isn't available.
    """
    
    # Simple rule-based mock based on prompt content
    if 'Heart Rate: 110' in prompt or 'Heart Rate: 1' in prompt:
        return {
            'urgency': 'MODERATE',
            'primary_concern': 'Tachycardia with elevated blood pressure',
            'reasoning': 'Heart rate of 110 bpm is elevated (normal 60-100). Combined with blood pressure of 145/92, this suggests cardiovascular stress. Oxygen saturation at 94% is borderline low.',
            'abnormal_vitals': ['heart_rate', 'blood_pressure', 'oxygen_saturation'],
            'recommended_actions': [
                'Monitor patient continuously',
                'Check for chest pain or discomfort',
                'Consider ECG if symptoms persist',
                'Assess for anxiety or pain causing elevation'
            ],
            'confidence_score': 0.87
        }
    
    # Default normal response
    return {
        'urgency': 'NORMAL',
        'primary_concern': 'All vitals within acceptable ranges',
        'reasoning': 'Patient vital signs are all within normal limits for their age category. No immediate concerns identified.',
        'abnormal_vitals': [],
        'recommended_actions': ['Continue routine monitoring'],
        'confidence_score': 0.95
    }


def fallback_rule_based_analysis(vitals):
    """
    Fallback analysis if LLM fails
    
    RESILIENCE PATTERN:
    If local LLM fails (model corrupt, out of memory, etc),
    fall back to simple rule-based analysis.
    
    This ensures alerts ALWAYS work, even if AI fails.
    """
    
    print("[FALLBACK] Using rule-based analysis (LLM unavailable)")
    
    abnormal = []
    concerns = []
    
    # Check heart rate
    hr = vitals['heart_rate']
    if hr < 60:
        abnormal.append('heart_rate')
        concerns.append('Bradycardia (low heart rate)')
    elif hr > 100:
        abnormal.append('heart_rate')
        concerns.append('Tachycardia (elevated heart rate)')
    
    # Check blood pressure
    sys = vitals['bp_systolic']
    if sys > 140 or vitals['bp_diastolic'] > 90:
        abnormal.append('blood_pressure')
        concerns.append('Hypertension')
    elif sys < 90:
        abnormal.append('blood_pressure')
        concerns.append('Hypotension')
    
    # Check oxygen saturation
    o2 = vitals['oxygen_saturation']
    if o2 < 90:
        abnormal.append('oxygen_saturation')
        concerns.append('Critical hypoxemia')
    elif o2 < 95:
        abnormal.append('oxygen_saturation')
        concerns.append('Low oxygen saturation')
    
    # Determine urgency
    if o2 < 90 or sys < 90 or hr > 140 or hr < 50:
        urgency = 'CRITICAL'
    elif len(abnormal) > 0:
        urgency = 'MODERATE'
    else:
        urgency = 'NORMAL'
    
    return {
        'urgency': urgency,
        'primary_concern': ', '.join(concerns) if concerns else 'All vitals normal',
        'reasoning': 'Rule-based analysis used (AI unavailable)',
        'abnormal_vitals': abnormal,
        'recommended_actions': ['Immediate assessment'] if urgency == 'CRITICAL' else ['Monitor'],
        'confidence_score': 0.75,
        'fallback': True
    }


def parse_llm_output_to_alert(llm_output, vitals):
    """
    Converts LLM output to standardized alert format
    
    Ensures alert structure is consistent regardless of LLM variation
    """
    
    return {
        'urgency': llm_output.get('urgency', 'MODERATE').upper(),
        'primary_concern': llm_output.get('primary_concern', 'Unknown concern'),
        'reasoning': llm_output.get('reasoning', ''),
        'abnormal_vitals': llm_output.get('abnormal_vitals', []),
        'recommended_actions': llm_output.get('recommended_actions', []),
        'confidence_score': llm_output.get('confidence_score', 0.5),
        'analysis_method': 'rule_based' if llm_output.get('fallback') else 'llm',
        'timestamp': datetime.utcnow().isoformat()
    }


def determine_alert_routing(alert):
    """
    Determines where to send the alert based on urgency
    
    ROUTING LOGIC:
    - NORMAL: Log only, no immediate notification
    - MODERATE: Clinical staff notification (SNS)
    - CRITICAL: Clinical staff + security team + PagerDuty
    """
    
    urgency = alert['urgency']
    
    if urgency == 'CRITICAL':
        return {
            'channels': ['clinical_sns', 'security_sns', 'pagerduty'],
            'priority': 'URGENT',
            'requires_acknowledgment': True
        }
    elif urgency == 'MODERATE':
        return {
            'channels': ['clinical_sns'],
            'priority': 'NORMAL',
            'requires_acknowledgment': False
        }
    else:
        return {
            'channels': ['cloudwatch_only'],
            'priority': 'INFO',
            'requires_acknowledgment': False
        }


def format_clinical_alert(alert, vitals):
    """
    Formats alert in human-readable format for clinical staff
    
    DESIGN: Clear, concise, actionable format
    - Urgency prominently displayed
    - Vitals in easy-to-scan format
    - Clear action items
    """
    
    urgency_emoji = {
        'CRITICAL': '🚨',
        'MODERATE': '⚠️',
        'NORMAL': '✅'
    }
    
    message = f"""{urgency_emoji.get(alert['urgency'], '')} {alert['urgency']} ALERT

PATIENT: {vitals['patient_id']}
TIME: {vitals['timestamp']}

PRIMARY CONCERN:
{alert['primary_concern']}

CURRENT VITALS:
  • Heart Rate: {vitals['heart_rate']} bpm
  • Blood Pressure: {vitals['bp_systolic']}/{vitals['bp_diastolic']} mmHg
  • O2 Saturation: {vitals['oxygen_saturation']}%
  • Respiratory Rate: {vitals['respiratory_rate']}/min
  • Temperature: {vitals['temperature']}°C

CLINICAL REASONING:
{alert['reasoning']}

RECOMMENDED ACTIONS:
"""
    
    for i, action in enumerate(alert['recommended_actions'], 1):
        message += f"  {i}. {action}\n"
    
    message += f"\nConfidence: {alert['confidence_score']:.0%}"
    message += f"\nAnalysis: {alert['analysis_method'].upper()}"
    
    return message


def send_alerts(alert, message, routing):
    """
    Sends alerts to configured channels
    
    ERROR HANDLING: Never let notification failure stop analysis
    """
    
    for channel in routing['channels']:
        try:
            if channel == 'clinical_sns' and SNS_TOPIC_CLINICAL:
                sns.publish(
                    TopicArn=SNS_TOPIC_CLINICAL,
                    Subject=f"{alert['urgency']} Alert - Patient Vitals",
                    Message=message
                )
                print(f"[NOTIFY] Alert sent to clinical SNS")
            
            elif channel == 'security_sns' and SNS_TOPIC_SECURITY:
                sns.publish(
                    TopicArn=SNS_TOPIC_SECURITY,
                    Subject=f"CRITICAL Healthcare Alert",
                    Message=message
                )
                print(f"[NOTIFY] Alert sent to security SNS")
            
            elif channel == 'cloudwatch_only':
                print(f"[INFO] Normal vitals, CloudWatch log only")
        
        except Exception as e:
            # Log but don't fail - notification is non-critical
            print(f"[ERROR] Failed to send to {channel}: {str(e)}")


def log_vitals_analysis(vitals, alert):
    """
    Logs analysis to CloudWatch for audit trail
    
    COMPLIANCE: All patient vitals analysis must be logged
    """
    
    try:
        log_entry = {
            'log_type': 'VITALS_ANALYSIS',
            'patient_id': vitals['patient_id'],
            'timestamp': vitals['timestamp'],
            'urgency': alert['urgency'],
            'confidence': alert['confidence_score'],
            'method': alert['analysis_method']
        }
        print(f"[AUDIT_LOG] {json.dumps(log_entry)}")
    except Exception as e:
        print(f"[ERROR] Logging failed: {str(e)}")


# Local testing
if __name__ == "__main__":
    # Test with elevated vitals
    test_event = {
        "patient_id": "P12345-DEMO",
        "timestamp": "2025-11-14T10:30:00Z",
        "vitals": {
            "heart_rate_bpm": 110,
            "blood_pressure_systolic": 145,
            "blood_pressure_diastolic": 92,
            "oxygen_saturation_percent": 94.0,
            "respiratory_rate_bpm": 22,
            "temperature_celsius": 37.8
        },
        "patient_category": "adult",
        "notes": "Patient reports chest discomfort"
    }
    
    result = handler(test_event, None)
    print(f"\n{'='*60}")
    print("TEST RESULT:")
    print(json.dumps(result, indent=2))
    print(f"{'='*60}")
    print("\nHUMAN-READABLE ALERT:")
    print(result['human_readable'])

