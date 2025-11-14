"""
CONCEPT: Auto Remediator
PURPOSE: Automatically fixes detected infrastructure drift by re-applying Terraform

OPERATIONAL PRINCIPLE:
    After drift is detected:
    - Receive drift details
    - Determine remediation action
    - Execute fix (terraform apply or AWS API call)
    - Verify fix succeeded

INPUTS: Drift detection result
OUTPUTS: Remediation result (success/failure)

This concept ACTS on drift but doesn't detect it (separation of concerns).
"""

import json
import boto3
import os
from datetime import datetime

# AWS clients
codebuild = boto3.client('codebuild')
sns = boto3.client('sns')
ssm = boto3.client('ssm')

# Configuration
TERRAFORM_PROJECT = os.environ.get('TERRAFORM_CODEBUILD_PROJECT', 'terraform-apply')
SNS_TOPIC = os.environ.get('SNS_TOPIC_ARN', '')
DRY_RUN = os.environ.get('DRY_RUN', 'true').lower() == 'true'


def handler(event, context):
    """
    Remediates infrastructure drift
    
    Simple decision tree:
    1. Receive drift info
    2. Determine fix action
    3. Execute fix (or dry-run)
    4. Report result
    """
    
    print(f"[TRACE] Remediation requested: {json.dumps(event, indent=2)}")
    
    # STEP 1: Extract drift information
    # This comes from the drift-detector concept
    drift_info = event if isinstance(event, dict) and 'resource_type' in event else event.get('detail', {})
    
    resource_type = drift_info.get('resource_type', 'unknown')
    resource_id = drift_info.get('resource_id', 'unknown')
    drift_severity = drift_info.get('drift_severity', 'MEDIUM')
    
    print(f"[INFO] Remediating {resource_type}/{resource_id} (severity: {drift_severity})")
    
    # STEP 2: Determine remediation strategy
    # Simple logic: critical resources get immediate fix, others get manual approval
    auto_fix_enabled = should_auto_fix(resource_type, drift_severity)
    
    # STEP 3: Create remediation plan
    remediation_plan = create_remediation_plan(drift_info, auto_fix_enabled)
    
    # STEP 4: Execute remediation (if auto-fix enabled)
    if auto_fix_enabled and not DRY_RUN:
        execution_result = execute_remediation(remediation_plan)
    else:
        execution_result = {
            'status': 'PENDING_APPROVAL',
            'reason': 'Auto-fix disabled or DRY_RUN mode',
            'action_required': 'Manual approval needed'
        }
    
    # STEP 5: Create structured result
    result = {
        'timestamp': datetime.utcnow().isoformat(),
        'resource_type': resource_type,
        'resource_id': resource_id,
        'drift_severity': drift_severity,
        'auto_fix_enabled': auto_fix_enabled,
        'remediation_plan': remediation_plan,
        'execution_result': execution_result,
        'dry_run_mode': DRY_RUN
    }
    
    # STEP 6: Log remediation attempt
    log_remediation(result)
    
    # STEP 7: Notify stakeholders
    notify_remediation(result)
    
    print(f"[RESULT] Remediation complete: {json.dumps(result, indent=2)}")
    
    return result


def should_auto_fix(resource_type, severity):
    """
    Decides if resource should be auto-fixed or needs manual approval
    
    Safety first approach:
    - LOW/MEDIUM severity: auto-fix OK
    - CRITICAL severity: manual approval (to avoid breaking production)
    
    This is configurable per resource type
    """
    # For this demo, we're conservative
    # In production, you'd have a whitelist of auto-fixable resource types
    
    safe_to_auto_fix = [
        'AWS::S3::Bucket',  # Can safely re-apply tags, encryption
        'AWS::EC2::SecurityGroup'  # Can revert unauthorized rule changes
    ]
    
    # Critical resources always need approval
    if severity == 'CRITICAL':
        print(f"[DECISION] Manual approval required for CRITICAL severity")
        return False
    
    # Check if resource type is in safe list
    if resource_type in safe_to_auto_fix:
        print(f"[DECISION] Auto-fix enabled for {resource_type}")
        return True
    
    print(f"[DECISION] Manual approval required for {resource_type}")
    return False


def create_remediation_plan(drift_info, auto_fix_enabled):
    """
    Creates a plan for how to fix the drift
    
    Returns a simple dict describing:
    - What needs to be fixed
    - How it will be fixed
    - What the risk level is
    """
    resource_type = drift_info.get('resource_type')
    
    plan = {
        'action': 'terraform apply' if auto_fix_enabled else 'manual review',
        'target': drift_info.get('resource_id'),
        'risk_level': drift_info.get('drift_severity'),
        'estimated_duration': '5 minutes',
        'rollback_available': True
    }
    
    # Specific plans for different resource types
    if 'SecurityGroup' in resource_type:
        plan['description'] = 'Revert security group rules to Terraform state'
        plan['impact'] = 'May temporarily affect network connectivity'
    elif 'S3' in resource_type:
        plan['description'] = 'Re-apply bucket policy and encryption settings'
        plan['impact'] = 'No service interruption expected'
    else:
        plan['description'] = f'Re-apply Terraform configuration for {resource_type}'
        plan['impact'] = 'Impact varies by resource type'
    
    return plan


def execute_remediation(plan):
    """
    Executes the remediation plan
    
    For Terraform-managed resources:
    - Trigger CodeBuild project that runs 'terraform apply'
    - Pass specific resource target to minimize blast radius
    
    Returns execution status
    """
    try:
        print(f"[EXEC] Starting remediation: {plan['description']}")
        
        # Trigger Terraform apply via CodeBuild
        # In production, this would include resource targeting
        response = codebuild.start_build(
            projectName=TERRAFORM_PROJECT,
            environmentVariablesOverride=[
                {
                    'name': 'TF_TARGET',
                    'value': plan['target'],
                    'type': 'PLAINTEXT'
                },
                {
                    'name': 'TF_ACTION',
                    'value': 'apply',
                    'type': 'PLAINTEXT'
                }
            ]
        )
        
        build_id = response['build']['id']
        
        return {
            'status': 'IN_PROGRESS',
            'build_id': build_id,
            'action': 'terraform apply triggered',
            'monitor_url': f"https://console.aws.amazon.com/codesuite/codebuild/projects/{TERRAFORM_PROJECT}/build/{build_id}"
        }
        
    except Exception as e:
        print(f"[ERROR] Remediation execution failed: {str(e)}")
        return {
            'status': 'FAILED',
            'error': str(e),
            'action_required': 'Manual intervention needed'
        }


def log_remediation(result):
    """
    Logs remediation result for audit trail
    
    Every remediation attempt is logged with:
    - What was attempted
    - Why it was attempted
    - What the result was
    """
    try:
        log_entry = {
            'log_type': 'REMEDIATION',
            'resource': result['resource_id'],
            'severity': result['drift_severity'],
            'auto_fixed': result['auto_fix_enabled'],
            'status': result['execution_result'].get('status'),
            'timestamp': result['timestamp']
        }
        print(f"[REMEDIATION_LOG] {json.dumps(log_entry)}")
    except Exception as e:
        print(f"[ERROR] Logging failed: {str(e)}")


def notify_remediation(result):
    """
    Sends notification about remediation action
    
    Different notifications for:
    - Successful auto-fix
    - Failed auto-fix
    - Manual approval needed
    """
    if not SNS_TOPIC:
        print("[WARN] No SNS topic configured")
        return
    
    try:
        execution = result['execution_result']
        status = execution.get('status', 'UNKNOWN')
        
        if status == 'PENDING_APPROVAL':
            subject = f"Manual Approval Required: {result['resource_id']}"
            message = f"""
Drift Detection - Manual Approval Required

Resource: {result['resource_type']} / {result['resource_id']}
Severity: {result['drift_severity']}
Reason: Auto-fix not enabled for this resource type

Remediation Plan:
{json.dumps(result['remediation_plan'], indent=2)}

Action Required: Review and manually apply fix
"""
        else:
            subject = f"Auto-Remediation {status}: {result['resource_id']}"
            message = f"""
Automated Drift Remediation

Resource: {result['resource_type']} / {result['resource_id']}
Severity: {result['drift_severity']}
Status: {status}

Execution Details:
{json.dumps(execution, indent=2)}
"""
        
        sns.publish(
            TopicArn=SNS_TOPIC,
            Subject=subject,
            Message=message
        )
        print(f"[NOTIFY] SNS notification sent")
    except Exception as e:
        print(f"[ERROR] Notification failed: {str(e)}")


# Local testing
if __name__ == "__main__":
    # Example: drift detected in security group
    test_event = {
        "resource_type": "AWS::EC2::SecurityGroup",
        "resource_id": "sg-0123456789abcdef",
        "drift_severity": "HIGH",
        "is_drift": True,
        "requires_remediation": True
    }
    
    result = handler(test_event, None)
    print(f"\nTest Result: {json.dumps(result, indent=2)}")

