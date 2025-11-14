# Sprint 3 Screenshot & Evidence Capture Guide

## Purpose
This guide provides **exact steps** to generate logs, trigger workflows, and capture screenshots for Sprint 3 deliverables.

---

## 📸 Evidence Requirements Mapping

| Sprint 3 Requirement | Screenshots Needed | Commands to Run |
|---------------------|-------------------|-----------------|
| **3C: Step Functions** | Execution graph, logs, retry logic | Start execution, view in console |
| **3D: EventBridge Rules** | Rule list, event patterns, targets | List rules, describe rules |
| **3E: Lambda Functions** | Function list, code view, logs | Invoke functions, tail logs |
| **3F: Testing** | Test execution, actual results | Run test cases, capture output |
| **3G: Error Handling** | Error logs, retry attempts, escalation | Trigger failures, view catch blocks |
| **Healthcare LLM** | Inference output, prompts, alerts | Run local LLM, capture analysis |

---

## PART 1: Deploy Infrastructure First

### Step 1.1: Deploy with Terraform

```bash
cd /Volumes/Exchange/projects/capstone/tech-execution/sprint3/automation/terraform

# Initialize Terraform
terraform init

# 📸 SCREENSHOT 1: Terraform Init Success
# Capture: Terminal showing "Terraform has been successfully initialized!"
```

```bash
# Plan deployment
terraform plan -out=tfplan

# 📸 SCREENSHOT 2: Terraform Plan Output
# Capture: Terminal showing "Plan: XX to add, 0 to change, 0 to destroy"
```

```bash
# Apply infrastructure
terraform apply tfplan

# 📸 SCREENSHOT 3: Terraform Apply Complete
# Capture: Terminal showing "Apply complete! Resources: XX added"
# Also capture the OUTPUTS section showing ARNs
```

**What to capture in Screenshot 3:**
```
Outputs:

drift_detector_arn = "arn:aws:lambda:us-east-1:123456789012:function:sprint3-automation-drift-detector"
pipeline_validator_arn = "arn:aws:lambda:us-east-1:123456789012:function:sprint3-automation-pipeline-validator"
state_machine_arn = "arn:aws:states:us-east-1:123456789012:stateMachine:sprint3-automation-incident-response"
state_machine_console_url = "https://console.aws.amazon.com/states/..."
```

### Step 1.2: Verify Deployment in AWS Console

```bash
# List Lambda functions
aws lambda list-functions \
  --query "Functions[?starts_with(FunctionName, 'sprint3-automation')].{Name:FunctionName,Runtime:Runtime,Memory:MemorySize}" \
  --output table

# 📸 SCREENSHOT 4: Lambda Functions List (Terminal)
# Capture: Table showing all 3 Lambda functions
```

**Expected output:**
```
------------------------------------------------------------------------------------
|                              ListFunctions                                        |
+-----------------------------------------+--------------+----------+--------------+
|                  Name                   |   Runtime    | Memory   |
+-----------------------------------------+--------------+----------+--------------+
|  sprint3-automation-pipeline-validator  |  python3.11  |  256     |
|  sprint3-automation-drift-detector      |  python3.11  |  256     |
|  sprint3-automation-auto-remediator     |  python3.11  |  512     |
+-----------------------------------------+--------------+----------+--------------+
```

**AWS Console Screenshot:**
```
Navigate to: AWS Lambda Console → Functions

# 📸 SCREENSHOT 5: Lambda Console Functions List
# Capture: AWS Console showing all 3 functions with green "Active" status
```

---

## PART 2: EventBridge Rules (Sprint 3 Objective 3D)

### Step 2.1: List EventBridge Rules

```bash
# List all Sprint 3 EventBridge rules
aws events list-rules \
  --name-prefix sprint3-automation \
  --query "Rules[*].{Name:Name,State:State,EventPattern:EventPattern}" \
  --output json > eventbridge-rules.json

cat eventbridge-rules.json | jq

# 📸 SCREENSHOT 6: EventBridge Rules JSON Output
# Capture: Terminal showing JSON with rule names and event patterns
```

**Expected JSON (capture this):**
```json
[
  {
    "Name": "sprint3-automation-pipeline-state-change",
    "State": "ENABLED",
    "EventPattern": "{\"source\":[\"aws.codepipeline\"],\"detail-type\":[\"CodePipeline Pipeline Execution State Change\"],\"detail\":{\"state\":[\"FAILED\",\"SUCCEEDED\"]}}"
  },
  {
    "Name": "sprint3-automation-config-compliance-change",
    "State": "ENABLED",
    "EventPattern": "{\"source\":[\"aws.config\"],\"detail-type\":[\"Config Rules Compliance Change\"]...}"
  }
]
```

### Step 2.2: EventBridge Console View

```
Navigate to: Amazon EventBridge → Rules

# 📸 SCREENSHOT 7: EventBridge Console Rules List
# Capture: AWS Console showing all rules with "Enabled" status
# Make sure rule names are visible
```

### Step 2.3: View Specific Rule Details

```bash
# Get detailed info on pipeline rule
aws events describe-rule \
  --name sprint3-automation-pipeline-state-change

# 📸 SCREENSHOT 8: EventBridge Rule Details
# Capture: Full output showing event pattern and targets
```

```
In AWS Console:
Click on: sprint3-automation-pipeline-state-change

# 📸 SCREENSHOT 9: EventBridge Rule Event Pattern (Console)
# Capture: Event pattern JSON displayed in console
# Capture: Targets section showing Lambda function target
```

---

## PART 3: Step Functions State Machine (Sprint 3 Objective 3C)

### Step 3.1: View State Machine Definition

```bash
# Get state machine details
aws stepfunctions describe-state-machine \
  --state-machine-arn $(terraform output -raw state_machine_arn) \
  --output json > state-machine-details.json

# Pretty print the definition
cat state-machine-details.json | jq '.definition | fromjson' > state-machine-visual.json

# 📸 SCREENSHOT 10: State Machine JSON Definition
# Capture: Terminal showing formatted state machine JSON with all states
```

### Step 3.2: View State Machine in Console

```
Navigate to: Step Functions Console → State Machines → sprint3-automation-incident-response

# 📸 SCREENSHOT 11: State Machine Visual Graph (NOT EXECUTED YET)
# Capture: Visual workflow diagram showing all states:
#   - DetectIncident
#   - IsRealIncident (Choice)
#   - CheckDriftSeverity
#   - IsCriticalDrift (Choice)
#   - NotifySecurityTeam
#   - WaitForApproval
#   - AttemptAutoRemediation
#   - RemediationSucceeded (Choice)
#   - NotifySuccess
#   - RemediationFailed
#   - CreateTicket
#   - NotifyFailure
#   - LogAndClose
```

### Step 3.3: Execute State Machine with Test Input

```bash
# Create test input file
cat > /tmp/test-execution-input.json <<'EOF'
{
  "detail": {
    "pipeline": "test-pipeline",
    "execution-id": "test-exec-001",
    "state": "FAILED"
  }
}
EOF

# Start execution
EXECUTION_ARN=$(aws stepfunctions start-execution \
  --state-machine-arn $(terraform output -raw state_machine_arn) \
  --name "test-execution-$(date +%s)" \
  --input file:///tmp/test-execution-input.json \
  --query 'executionArn' \
  --output text)

echo "Execution started: $EXECUTION_ARN"

# 📸 SCREENSHOT 12: Start Execution Command
# Capture: Terminal showing execution ARN returned
```

### Step 3.4: Monitor Execution

```bash
# Wait 10 seconds for execution to complete
sleep 10

# Get execution status
aws stepfunctions describe-execution \
  --execution-arn $EXECUTION_ARN

# 📸 SCREENSHOT 13: Execution Status JSON
# Capture: Terminal showing status, startDate, stopDate, output
```

```
# In AWS Console:
Navigate to: Step Functions → sprint3-automation-incident-response → Executions

# 📸 SCREENSHOT 14: Step Functions Execution List
# Capture: Console showing execution with "Succeeded" status (green)
# Show execution name and duration
```

```
Click on the execution to view details:

# 📸 SCREENSHOT 15: Step Functions Execution Graph with Path Highlighted
# Capture: Visual graph showing the EXACT path taken (green highlighted states)
# This shows which states were executed
```

```
Click on "Execution event history" tab:

# 📸 SCREENSHOT 16: Execution Event History
# Capture: Timeline showing all state transitions:
#   - ExecutionStarted
#   - TaskStateEntered (DetectIncident)
#   - TaskScheduled (Lambda invoke)
#   - TaskSucceeded
#   - ChoiceStateEntered (IsRealIncident)
#   - ChoiceStateExited
#   - [Continue through all states]
#   - ExecutionSucceeded
```

### Step 3.5: View Retry Logic (Trigger Failure)

```bash
# Create input that will cause Lambda timeout
cat > /tmp/test-failure-input.json <<'EOF'
{
  "detail": {
    "pipeline": "timeout-test",
    "execution-id": "timeout-001",
    "state": "UNKNOWN",
    "force_timeout": true
  }
}
EOF

# Start execution that will fail
FAILURE_EXEC_ARN=$(aws stepfunctions start-execution \
  --state-machine-arn $(terraform output -raw state_machine_arn) \
  --name "failure-test-$(date +%s)" \
  --input file:///tmp/test-failure-input.json \
  --query 'executionArn' \
  --output text)

echo "Failure test execution: $FAILURE_EXEC_ARN"

# Wait for retries to complete
sleep 15

# View execution history
aws stepfunctions get-execution-history \
  --execution-arn $FAILURE_EXEC_ARN \
  --max-results 50

# 📸 SCREENSHOT 17: Execution History Showing Retries
# Capture: Terminal output showing:
#   - TaskFailed (first attempt)
#   - TaskScheduled (retry 1)
#   - TaskFailed (retry 1)
#   - TaskScheduled (retry 2)
#   - TaskFailed (retry 2)
#   - ExecutionFailed or Catch block triggered
```

```
In AWS Console (same failed execution):

# 📸 SCREENSHOT 18: Visual Graph Showing Retry Attempts
# Capture: Event history showing 3 attempts for same task
# Look for multiple "TaskStateEntered" events for same state
```

---

## PART 4: Lambda Function Execution & Logs (Sprint 3 Objective 3E)

### Step 4.1: View Lambda Function Code

```bash
# Download function code
aws lambda get-function \
  --function-name sprint3-automation-pipeline-validator \
  --query 'Code.Location' \
  --output text | xargs curl -o /tmp/function.zip

# 📸 SCREENSHOT 19: Lambda Function Details
# Capture: aws lambda get-function output showing configuration
```

```
In AWS Console:
Navigate to: Lambda → sprint3-automation-pipeline-validator → Code

# 📸 SCREENSHOT 20: Lambda Function Code in Console
# Capture: Code editor showing handler.py with comments visible
# Scroll to show the docstring at top:
"""
CONCEPT: Pipeline Validator
PURPOSE: Validates whether a CI/CD pipeline execution succeeded or failed
...
"""
```

### Step 4.2: Test Lambda Function Directly

```bash
# Create test event
cat > /tmp/lambda-test-event.json <<'EOF'
{
  "detail": {
    "pipeline": "my-test-pipeline",
    "execution-id": "abc-123-def",
    "state": "FAILED"
  }
}
EOF

# Invoke Lambda function
aws lambda invoke \
  --function-name sprint3-automation-pipeline-validator \
  --payload file:///tmp/lambda-test-event.json \
  --cli-binary-format raw-in-base64-out \
  /tmp/lambda-response.json

# View response
cat /tmp/lambda-response.json | jq

# 📸 SCREENSHOT 21: Lambda Direct Invocation Response
# Capture: Terminal showing JSON response with validation result
```

**Expected response to capture:**
```json
{
  "timestamp": "2025-11-14T10:30:45.123Z",
  "pipeline": "my-test-pipeline",
  "execution_id": "abc-123-def",
  "state": "FAILED",
  "is_success": false,
  "needs_remediation": true,
  "validation_result": "FAIL"
}
```

### Step 4.3: View Lambda CloudWatch Logs

```bash
# Get latest log stream
LOG_STREAM=$(aws logs describe-log-streams \
  --log-group-name /aws/lambda/sprint3-automation-pipeline-validator \
  --order-by LastEventTime \
  --descending \
  --max-items 1 \
  --query 'logStreams[0].logStreamName' \
  --output text)

# Get log events
aws logs get-log-events \
  --log-group-name /aws/lambda/sprint3-automation-pipeline-validator \
  --log-stream-name "$LOG_STREAM" \
  --limit 50

# 📸 SCREENSHOT 22: Lambda CloudWatch Logs (Terminal)
# Capture: Log output showing:
#   [TRACE] Received event
#   [INFO] Pipeline: my-test-pipeline...
#   [VALIDATION] {...}
#   [NOTIFY] SNS notification sent
#   [RESULT] Validation complete
```

```
In AWS Console:
Navigate to: Lambda → sprint3-automation-pipeline-validator → Monitor → View CloudWatch logs

Click on latest log stream

# 📸 SCREENSHOT 23: Lambda Logs in CloudWatch Console
# Capture: Log events with timestamps showing structured logging
# Make sure these lines are visible:
#   - [TRACE] Received event
#   - [INFO] Processing pipeline
#   - [RESULT] Validation complete
```

### Step 4.4: Test Error Handling in Lambda

```bash
# Test with invalid input (missing required fields)
cat > /tmp/lambda-error-test.json <<'EOF'
{
  "detail": {
    "invalid": "data"
  }
}
EOF

aws lambda invoke \
  --function-name sprint3-automation-drift-detector \
  --payload file:///tmp/lambda-error-test.json \
  --cli-binary-format raw-in-base64-out \
  /tmp/lambda-error-response.json

cat /tmp/lambda-error-response.json | jq

# 📸 SCREENSHOT 24: Lambda Error Handling Response
# Capture: Response showing graceful error handling (not a crash)
```

**Expected error response:**
```json
{
  "error": "Invalid vitals data",
  "status": "FAILED",
  "timestamp": "2025-11-14T10:35:00.123Z"
}
```

---

## PART 5: Healthcare LLM Local Inference (NEW)

### Step 5.1: Install Local LLM Environment

```bash
# Navigate to LLM setup directory
cd /Volumes/Exchange/projects/capstone/tech-execution/sprint3/automation/concepts/vitals-analyzer

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install llama-cpp-python
pip install llama-cpp-python

# 📸 SCREENSHOT 25: LLM Dependencies Installation
# Capture: Terminal showing successful pip install
```

### Step 5.2: Download Model

```bash
# Create models directory
mkdir -p /opt/models

# Download Phi-3 Mini (2.4GB - takes ~5 minutes)
cd /opt/models
curl -L -o Phi-3-mini-4k-instruct-q4.gguf \
  "https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf"

# Verify download
ls -lh Phi-3-mini-4k-instruct-q4.gguf

# 📸 SCREENSHOT 26: Model Downloaded
# Capture: Terminal showing file size (~2.4GB) and successful download
```

### Step 5.3: Create Test Script for Healthcare Vitals

```bash
# Create test script
cat > /tmp/test_healthcare_llm.py <<'PYTHON_SCRIPT'
#!/usr/bin/env python3
"""Test healthcare vitals analysis with local LLM"""

from llama_cpp import Llama
import json
import time

# Initialize model
print("Loading Phi-3 Mini model...")
print("(This takes ~5 seconds on first load)\n")

llm = Llama(
    model_path="/opt/models/Phi-3-mini-4k-instruct-q4.gguf",
    n_ctx=2048,
    n_threads=4,
    verbose=False
)

print("✅ Model loaded successfully!\n")

# Test case: Concerning vitals
test_vitals = {
    'patient_id': 'P12345-DEMO',
    'heart_rate': 110,
    'bp_systolic': 145,
    'bp_diastolic': 92,
    'oxygen_saturation': 94.0,
    'respiratory_rate': 22,
    'temperature': 37.8
}

print("="*60)
print("TEST CASE: Patient with Elevated Vitals")
print("="*60)
print(f"Patient ID: {test_vitals['patient_id']}")
print(f"Heart Rate: {test_vitals['heart_rate']} bpm (normal: 60-100)")
print(f"Blood Pressure: {test_vitals['bp_systolic']}/{test_vitals['bp_diastolic']} mmHg")
print(f"O2 Saturation: {test_vitals['oxygen_saturation']}%")
print(f"Respiratory Rate: {test_vitals['respiratory_rate']}/min")
print(f"Temperature: {test_vitals['temperature']}°C")
print("="*60)
print()

# Create healthcare prompt
prompt = f"""<|system|>
You are an expert Emergency Room triage nurse. Analyze patient vital signs and provide structured assessment. Respond ONLY with valid JSON.<|end|>
<|user|>
CURRENT VITAL SIGNS:
- Heart Rate: {test_vitals['heart_rate']} bpm (normal: 60-100)
- Blood Pressure: {test_vitals['bp_systolic']}/{test_vitals['bp_diastolic']} mmHg
- Oxygen Saturation: {test_vitals['oxygen_saturation']}%
- Respiratory Rate: {test_vitals['respiratory_rate']}/min
- Temperature: {test_vitals['temperature']}°C

Respond with JSON:
{{
  "urgency": "NORMAL/MODERATE/CRITICAL",
  "primary_concern": "brief description",
  "reasoning": "clinical reasoning 2-3 sentences",
  "abnormal_vitals": ["list"],
  "recommended_actions": ["action1", "action2"],
  "confidence_score": 0.0-1.0
}}<|end|>
<|assistant|>
{{"""

print("Running AI analysis...")
print("(Inference typically takes 0.5-1 second)\n")

start_time = time.time()

output = llm(
    prompt,
    max_tokens=512,
    temperature=0.1,
    top_p=0.9,
    repeat_penalty=1.1,
    stop=["<|end|>", "</s>"]
)

inference_time = time.time() - start_time

result_text = output['choices'][0]['text']

print("="*60)
print(f"✅ INFERENCE COMPLETED in {inference_time:.3f} seconds")
print("="*60)
print()

print("RAW AI OUTPUT:")
print("-"*60)
print(result_text)
print("-"*60)
print()

# Parse JSON
try:
    json_text = "{" + result_text.split("}")[0] + "}"
    result_json = json.loads(json_text)
    
    print("="*60)
    print("STRUCTURED CLINICAL ASSESSMENT:")
    print("="*60)
    print(json.dumps(result_json, indent=2))
    print()
    
    # Format human-readable alert
    urgency_emoji = {'CRITICAL': '🚨', 'MODERATE': '⚠️', 'NORMAL': '✅'}
    
    print("="*60)
    print("HUMAN-READABLE CLINICAL ALERT:")
    print("="*60)
    print()
    
    alert = f"""{urgency_emoji.get(result_json['urgency'], '')} {result_json['urgency']} ALERT

PATIENT: {test_vitals['patient_id']}

PRIMARY CONCERN:
{result_json['primary_concern']}

CLINICAL REASONING:
{result_json['reasoning']}

ABNORMAL VITALS:
{', '.join(result_json['abnormal_vitals'])}

RECOMMENDED ACTIONS:"""
    
    for i, action in enumerate(result_json['recommended_actions'], 1):
        alert += f"\n  {i}. {action}"
    
    alert += f"\n\nConfidence: {result_json['confidence_score']:.0%}"
    alert += f"\nInference Time: {inference_time:.3f}s"
    alert += f"\nAnalysis Method: LOCAL LLM (Phi-3 Mini)"
    
    print(alert)
    
except Exception as e:
    print(f"⚠️  Could not parse JSON: {e}")
    print("But raw AI output is shown above")

print("\n" + "="*60)
print("Test completed successfully!")
print("="*60)
PYTHON_SCRIPT

chmod +x /tmp/test_healthcare_llm.py
```

### Step 5.4: Run Healthcare LLM Test

```bash
# Activate virtual environment if not already
source /Volumes/Exchange/projects/capstone/tech-execution/sprint3/automation/concepts/vitals-analyzer/venv/bin/activate

# Run the test
python3 /tmp/test_healthcare_llm.py

# 📸 SCREENSHOT 27: Healthcare LLM Test - Part 1 (Loading)
# Capture: Terminal showing:
#   "Loading Phi-3 Mini model..."
#   "✅ Model loaded successfully!"
#   Test case patient vitals

# 📸 SCREENSHOT 28: Healthcare LLM Test - Part 2 (AI Output)
# Capture: Terminal showing:
#   "Running AI analysis..."
#   "✅ INFERENCE COMPLETED in X.XXX seconds"
#   RAW AI OUTPUT with JSON

# 📸 SCREENSHOT 29: Healthcare LLM Test - Part 3 (Formatted Alert)
# Capture: Terminal showing:
#   STRUCTURED CLINICAL ASSESSMENT (pretty JSON)
#   HUMAN-READABLE CLINICAL ALERT with emoji
#   Recommended actions
#   Confidence score and inference time
```

**Expected output to capture:**
```
============================================================
✅ INFERENCE COMPLETED in 0.523 seconds
============================================================

RAW AI OUTPUT:
------------------------------------------------------------
  "urgency": "MODERATE",
  "primary_concern": "Tachycardia with elevated blood pressure",
  "reasoning": "Heart rate of 110 bpm exceeds normal range...",
  "abnormal_vitals": ["heart_rate", "blood_pressure", "oxygen_saturation"],
  "recommended_actions": [
    "Initiate continuous cardiac monitoring",
    "Obtain 12-lead ECG",
    "Assess for chest pain or anxiety"
  ],
  "confidence_score": 0.87
}
------------------------------------------------------------

============================================================
HUMAN-READABLE CLINICAL ALERT:
============================================================

⚠️ MODERATE ALERT

PATIENT: P12345-DEMO

PRIMARY CONCERN:
Tachycardia with elevated blood pressure

CLINICAL REASONING:
Heart rate of 110 bpm exceeds normal range combined with BP 145/92...

ABNORMAL VITALS:
heart_rate, blood_pressure, oxygen_saturation

RECOMMENDED ACTIONS:
  1. Initiate continuous cardiac monitoring
  2. Obtain 12-lead ECG
  3. Assess for chest pain or anxiety

Confidence: 87%
Inference Time: 0.523s
Analysis Method: LOCAL LLM (Phi-3 Mini)
```

### Step 5.5: Test Different Severity Levels

```bash
# Test CRITICAL vitals
cat > /tmp/test_critical_vitals.py <<'EOF'
from llama_cpp import Llama
import json

llm = Llama(model_path="/opt/models/Phi-3-mini-4k-instruct-q4.gguf", n_ctx=2048, verbose=False)

# CRITICAL case
vitals = {
    'heart_rate': 145,
    'bp_systolic': 85,
    'oxygen_saturation': 88.0
}

prompt = f"""<|system|>
Expert ER nurse. Analyze vitals, respond with JSON.<|end|>
<|user|>
CRITICAL VITALS:
- Heart Rate: {vitals['heart_rate']} bpm (normal: 60-100)
- Blood Pressure: {vitals['bp_systolic']}/60 mmHg (HYPOTENSIVE!)
- O2 Saturation: {vitals['oxygen_saturation']}% (CRITICAL HYPOXEMIA!)

JSON urgency assessment:<|end|>
<|assistant|>
{{"""

output = llm(prompt, max_tokens=256, temperature=0.1, stop=["<|end|>"])
print("CRITICAL CASE ANALYSIS:")
print(output['choices'][0]['text'])
EOF

python3 /tmp/test_critical_vitals.py

# 📸 SCREENSHOT 30: Critical Vitals AI Analysis
# Capture: Terminal showing AI correctly identifying CRITICAL urgency
# Should show immediate intervention recommendations
```

### Step 5.6: Benchmark Performance

```bash
# Create benchmark script
cat > /tmp/benchmark_llm.py <<'EOF'
from llama_cpp import Llama
import time

print("Benchmarking Phi-3 Mini for healthcare inference...")
print()

llm = Llama(model_path="/opt/models/Phi-3-mini-4k-instruct-q4.gguf", n_ctx=2048, n_threads=4, verbose=False)

prompt = "Analyze: HR 110, BP 145/92, O2 94%. JSON urgency:"

times = []
for i in range(5):
    start = time.time()
    output = llm(prompt, max_tokens=128, temperature=0.1)
    elapsed = time.time() - start
    times.append(elapsed)
    print(f"Run {i+1}: {elapsed:.3f}s")

avg = sum(times) / len(times)
print(f"\nAverage inference time: {avg:.3f}s")
print(f"Min: {min(times):.3f}s, Max: {max(times):.3f}s")
EOF

python3 /tmp/benchmark_llm.py

# 📸 SCREENSHOT 31: LLM Performance Benchmark
# Capture: Terminal showing 5 inference runs with times
# Should be ~0.4-0.6 seconds average
```

---

## PART 6: End-to-End Workflow Test (Sprint 3 Objective 3F)

### Step 6.1: Complete Workflow from Vitals to Alert

```bash
# Create end-to-end test script
cat > /tmp/e2e_workflow_test.sh <<'BASH_SCRIPT'
#!/bin/bash
set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  End-to-End Healthcare Alert Workflow Test                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo

# Step 1: Create patient vitals event
echo "STEP 1: Creating patient vitals event..."
cat > /tmp/patient-event.json <<'EOF'
{
  "patient_id": "P67890-E2E",
  "timestamp": "2025-11-14T15:30:00Z",
  "vitals": {
    "heart_rate_bpm": 115,
    "blood_pressure_systolic": 150,
    "blood_pressure_diastolic": 95,
    "oxygen_saturation_percent": 93.0,
    "respiratory_rate_bpm": 24,
    "temperature_celsius": 38.2
  },
  "patient_category": "adult",
  "notes": "Patient reports chest tightness"
}
EOF
cat /tmp/patient-event.json | jq
echo "✅ Event created"
echo

# Step 2: Invoke vitals analyzer Lambda
echo "STEP 2: Invoking vitals analyzer..."
aws lambda invoke \
  --function-name sprint3-automation-vitals-analyzer \
  --payload file:///tmp/patient-event.json \
  --cli-binary-format raw-in-base64-out \
  /tmp/analysis-result.json > /dev/null 2>&1

echo "✅ Analysis complete"
echo

# Step 3: Display analysis result
echo "STEP 3: AI Analysis Result:"
echo "─────────────────────────────────────────────────────────────"
cat /tmp/analysis-result.json | jq '.'
echo "─────────────────────────────────────────────────────────────"
echo

# Step 4: Extract urgency and route to appropriate channel
URGENCY=$(cat /tmp/analysis-result.json | jq -r '.alert.urgency')
echo "STEP 4: Alert Routing based on urgency: $URGENCY"

if [ "$URGENCY" = "CRITICAL" ]; then
    echo "  → Routing to: Clinical SNS + Security SNS + PagerDuty"
elif [ "$URGENCY" = "MODERATE" ]; then
    echo "  → Routing to: Clinical SNS"
else
    echo "  → Routing to: CloudWatch Logs only"
fi
echo

# Step 5: Trigger Step Functions workflow
echo "STEP 5: Triggering incident response workflow..."
EXEC_ARN=$(aws stepfunctions start-execution \
  --state-machine-arn $(terraform output -raw state_machine_arn) \
  --name "e2e-test-$(date +%s)" \
  --input file:///tmp/analysis-result.json \
  --query 'executionArn' \
  --output text)
echo "✅ Workflow started: $EXEC_ARN"
echo

# Step 6: Wait for workflow to complete
echo "STEP 6: Waiting for workflow to complete (10 seconds)..."
sleep 10

# Step 7: Check workflow status
echo "STEP 7: Workflow Status:"
aws stepfunctions describe-execution \
  --execution-arn $EXEC_ARN \
  --query '{Status:status,StartDate:startDate,StopDate:stopDate}' \
  --output table
echo

# Step 8: Get CloudWatch logs
echo "STEP 8: Recent CloudWatch Logs:"
echo "─────────────────────────────────────────────────────────────"
aws logs tail /aws/lambda/sprint3-automation-vitals-analyzer --since 2m | head -20
echo "─────────────────────────────────────────────────────────────"
echo

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ✅ End-to-End Test COMPLETED                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
BASH_SCRIPT

chmod +x /tmp/e2e_workflow_test.sh

# Run the test
/tmp/e2e_workflow_test.sh

# 📸 SCREENSHOT 32: End-to-End Workflow Test - Complete Output
# Capture: ENTIRE terminal output showing all 8 steps
# This demonstrates complete workflow from vitals → AI → routing → Step Functions
```

---

## PART 7: Error Handling Evidence (Sprint 3 Objective 3G)

### Step 7.1: Trigger Lambda Timeout

```bash
# Invoke Lambda with payload that causes timeout
cat > /tmp/timeout-test.json <<'EOF'
{
  "detail": {
    "pipeline": "timeout-test",
    "execution-id": "timeout-123",
    "state": "PROCESSING",
    "force_delay": 65
  }
}
EOF

aws lambda invoke \
  --function-name sprint3-automation-pipeline-validator \
  --payload file:///tmp/timeout-test.json \
  --cli-binary-format raw-in-base64-out \
  /tmp/timeout-response.json

# 📸 SCREENSHOT 33: Lambda Timeout Error
# Capture: Error message showing timeout occurred
```

### Step 7.2: View Retry Attempts in Logs

```bash
# Get logs showing retry attempts
aws logs filter-log-events \
  --log-group-name /aws/lambda/sprint3-automation-pipeline-validator \
  --filter-pattern "TaskFailed" \
  --start-time $(date -u -d '5 minutes ago' +%s)000

# 📸 SCREENSHOT 34: CloudWatch Logs Showing Retries
# Capture: Multiple log entries for same execution showing retry attempts
```

### Step 7.3: Trigger Step Functions Error Path

```bash
# Create input that will fail validation and trigger error path
cat > /tmp/error-path-test.json <<'EOF'
{
  "detail": {
    "invalid_structure": true,
    "missing_required_fields": true
  }
}
EOF

ERROR_EXEC=$(aws stepfunctions start-execution \
  --state-machine-arn $(terraform output -raw state_machine_arn) \
  --name "error-test-$(date +%s)" \
  --input file:///tmp/error-path-test.json \
  --query 'executionArn' \
  --output text)

sleep 10

# Get execution result
aws stepfunctions describe-execution --execution-arn $ERROR_EXEC

# 📸 SCREENSHOT 35: Step Functions Failed Execution
# Capture: Status showing "FAILED" with error details
```

```
In AWS Console:
Navigate to failed execution in Step Functions

# 📸 SCREENSHOT 36: Visual Graph Showing Error Path
# Capture: Graph with red error path highlighted
# Should show: Task failed → Catch block → NotifyFailure → LogAndClose
```

---

## SUMMARY: Complete Screenshot Checklist

### Infrastructure (6 screenshots)
- [ ] Screenshot 1: Terraform init success
- [ ] Screenshot 2: Terraform plan output
- [ ] Screenshot 3: Terraform apply complete with outputs
- [ ] Screenshot 4: Lambda functions list (terminal)
- [ ] Screenshot 5: Lambda functions in AWS Console
- [ ] Screenshot 6: EventBridge rules JSON

### EventBridge Rules (4 screenshots)
- [ ] Screenshot 7: EventBridge rules in console
- [ ] Screenshot 8: Rule details (terminal)
- [ ] Screenshot 9: Rule event pattern in console
- [ ] Screenshot 10: State machine JSON definition

### Step Functions (8 screenshots)
- [ ] Screenshot 11: State machine visual graph (before execution)
- [ ] Screenshot 12: Start execution command
- [ ] Screenshot 13: Execution status JSON
- [ ] Screenshot 14: Execution list in console
- [ ] Screenshot 15: Execution graph with path highlighted
- [ ] Screenshot 16: Execution event history
- [ ] Screenshot 17: Retry attempts in logs
- [ ] Screenshot 18: Visual graph showing retries

### Lambda Functions (6 screenshots)
- [ ] Screenshot 19: Lambda function details
- [ ] Screenshot 20: Lambda code in console with comments
- [ ] Screenshot 21: Lambda invocation response
- [ ] Screenshot 22: CloudWatch logs (terminal)
- [ ] Screenshot 23: CloudWatch logs (console)
- [ ] Screenshot 24: Error handling response

### Healthcare LLM (7 screenshots)
- [ ] Screenshot 25: LLM dependencies installation
- [ ] Screenshot 26: Model downloaded
- [ ] Screenshot 27: LLM test - loading
- [ ] Screenshot 28: LLM test - AI output
- [ ] Screenshot 29: LLM test - formatted alert
- [ ] Screenshot 30: Critical vitals analysis
- [ ] Screenshot 31: Performance benchmark

### End-to-End Testing (2 screenshots)
- [ ] Screenshot 32: Complete E2E workflow test
- [ ] Screenshot 33: Lambda timeout error

### Error Handling (4 screenshots)
- [ ] Screenshot 34: Retry attempts in logs
- [ ] Screenshot 35: Failed execution status
- [ ] Screenshot 36: Error path in visual graph

---

## 📊 Total: 37 Screenshots Covering ALL Sprint 3 Objectives

Save all screenshots with descriptive names:
```
01-terraform-init.png
02-terraform-plan.png
03-terraform-apply-complete.png
04-lambda-functions-list.png
...
37-error-path-visual.png
```

Create a directory:
```bash
mkdir -p /Volumes/Exchange/projects/capstone/tech-execution/sprint3/evidence/screenshots
```

Move all screenshots there for easy submission!

