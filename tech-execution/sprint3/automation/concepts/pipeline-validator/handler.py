"""
CONCEPT: Pipeline Validator
PURPOSE: Validates whether a CI/CD pipeline execution succeeded or failed
         and determines if remediation is needed

OPERATIONAL PRINCIPLE:
    After a pipeline completes:
    - If status = "SUCCEEDED" → log success, no action
    - If status = "FAILED" → analyze failure, trigger remediation

INPUTS: CodePipeline execution state change event
OUTPUTS: Validation result with remediation decision

This is a "concept" - an independent service with NO dependencies on other concepts.
It only knows about pipelines, not what happens after validation.
"""

import json
import boto3
import os
from datetime import datetime

# Initialize clients (AWS SDK)
cloudwatch = boto3.client('logs')
sns = boto3.client('sns')

# Environment variables (configuration)
LOG_GROUP = os.environ.get('LOG_GROUP', '/aws/lambda/pipeline-validator')
SNS_TOPIC = os.environ.get('SNS_TOPIC_ARN', '')


def handler(event, context):
    """
    Main entry point - validates pipeline execution
    
    Why this is simple:
    1. Extract event data
    2. Determine success or failure
    3. Log the decision
    4. Return structured result (for synchronizations to act on)
    """
    
    print(f"[TRACE] Received event: {json.dumps(event, indent=2)}")
    
    # STEP 1: Extract pipeline information from event
    # EventBridge delivers this in a standard format
    pipeline_name = event.get('detail', {}).get('pipeline', 'unknown')
    execution_id = event.get('detail', {}).get('execution-id', 'unknown')
    state = event.get('detail', {}).get('state', 'UNKNOWN')
    
    print(f"[INFO] Pipeline: {pipeline_name}, Execution: {execution_id}, State: {state}")
    
    # STEP 2: Make decision based on state
    # Simple boolean logic - easy to understand and test
    is_success = (state == 'SUCCEEDED')
    needs_remediation = (state == 'FAILED')
    
    # STEP 3: Create structured result
    # This follows the "structured output" pattern from the paper
    # Other services can reliably parse this JSON
    result = {
        'timestamp': datetime.utcnow().isoformat(),
        'pipeline': pipeline_name,
        'execution_id': execution_id,
        'state': state,
        'is_success': is_success,
        'needs_remediation': needs_remediation,
        'validation_result': 'PASS' if is_success else 'FAIL'
    }
    
    # STEP 4: Log decision (transparency)
    # Every decision is logged with full context
    log_validation(result)
    
    # STEP 5: Notify if failure (optional, could be handled by synchronization)
    if needs_remediation:
        notify_failure(result)
    
    print(f"[RESULT] Validation complete: {json.dumps(result, indent=2)}")
    
    # Return structured output for downstream synchronizations
    return result


def log_validation(result):
    """
    Logs validation decision to CloudWatch
    
    Why separate function:
    - Single Responsibility Principle
    - Easy to test independently
    - Can be modified without touching main logic
    """
    try:
        print(f"[LOG] Writing validation result to CloudWatch...")
        # In production, this would write to CloudWatch Logs
        # For demo, we print to stdout (which goes to CloudWatch anyway)
        print(f"[VALIDATION] {json.dumps(result)}")
    except Exception as e:
        # Never let logging errors break the main flow
        print(f"[ERROR] Logging failed: {str(e)}")


def notify_failure(result):
    """
    Sends SNS notification on pipeline failure
    
    Why SNS:
    - Decouples notification from validation logic
    - Multiple subscribers can listen (email, Lambda, etc)
    - Follows pub/sub pattern from the paper
    """
    if not SNS_TOPIC:
        print("[WARN] No SNS topic configured, skipping notification")
        return
    
    try:
        message = f"""
Pipeline Validation Failed

Pipeline: {result['pipeline']}
Execution: {result['execution_id']}
State: {result['state']}
Timestamp: {result['timestamp']}

This failure will trigger automated remediation.
        """
        
        sns.publish(
            TopicArn=SNS_TOPIC,
            Subject=f"Pipeline Failure: {result['pipeline']}",
            Message=message
        )
        print(f"[NOTIFY] SNS notification sent to {SNS_TOPIC}")
    except Exception as e:
        print(f"[ERROR] SNS notification failed: {str(e)}")


# For local testing
if __name__ == "__main__":
    # Example event from CodePipeline state change
    test_event = {
        "detail": {
            "pipeline": "my-devsecops-pipeline",
            "execution-id": "abc-123-def",
            "state": "FAILED"
        }
    }
    
    result = handler(test_event, None)
    print(f"\nTest Result: {json.dumps(result, indent=2)}")

