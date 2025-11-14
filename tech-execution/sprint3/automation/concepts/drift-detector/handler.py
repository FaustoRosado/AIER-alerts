"""
CONCEPT: Drift Detector
PURPOSE: Detects when AWS infrastructure has drifted from Terraform state
         (someone made manual changes in AWS Console)

OPERATIONAL PRINCIPLE:
    After AWS Config detects a change:
    - Compare current state vs Terraform state
    - If difference found → drift detected
    - Return structured result for remediation

INPUTS: AWS Config compliance change event
OUTPUTS: Drift detection result with resource details

This concept is independent - it only detects drift, doesn't fix it.
Remediation is handled by a different concept (separation of concerns).
"""

import json
import boto3
import os
from datetime import datetime

# AWS clients
config = boto3.client('config')
s3 = boto3.client('s3')

# Configuration
TERRAFORM_STATE_BUCKET = os.environ.get('TERRAFORM_STATE_BUCKET', '')
TERRAFORM_STATE_KEY = os.environ.get('TERRAFORM_STATE_KEY', 'terraform.tfstate')


def handler(event, context):
    """
    Detects infrastructure drift from IaC definitions
    
    Simple flow:
    1. Get resource that changed (from Config event)
    2. Check if it's managed by Terraform
    3. Compare actual vs expected configuration
    4. Report drift if found
    """
    
    print(f"[TRACE] Config event received: {json.dumps(event, indent=2)}")
    
    # STEP 1: Extract resource information from Config event
    config_item = event.get('detail', {}).get('configurationItem', {})
    resource_type = config_item.get('resourceType', 'unknown')
    resource_id = config_item.get('resourceId', 'unknown')
    resource_arn = config_item.get('ARN', 'unknown')
    compliance_type = event.get('detail', {}).get('newEvaluationResult', {}).get('complianceType', 'UNKNOWN')
    
    print(f"[INFO] Resource: {resource_type}/{resource_id}, Compliance: {compliance_type}")
    
    # STEP 2: Check if resource is managed by Terraform
    # Simple heuristic: check if resource has terraform tags
    tags = config_item.get('tags', {})
    is_terraform_managed = 'terraform' in str(tags).lower() or 'iac' in str(tags).lower()
    
    # STEP 3: Determine if this is drift
    # Drift = non-compliant resource that should be managed by IaC
    is_drift = (compliance_type == 'NON_COMPLIANT') and is_terraform_managed
    
    # STEP 4: Create structured result
    result = {
        'timestamp': datetime.utcnow().isoformat(),
        'resource_type': resource_type,
        'resource_id': resource_id,
        'resource_arn': resource_arn,
        'compliance_type': compliance_type,
        'is_terraform_managed': is_terraform_managed,
        'is_drift': is_drift,
        'drift_severity': calculate_severity(resource_type, compliance_type),
        'requires_remediation': is_drift
    }
    
    # STEP 5: Log detection result (transparency)
    log_drift(result)
    
    # STEP 6: If drift detected, get details for remediation
    if is_drift:
        result['drift_details'] = get_drift_details(resource_type, resource_id, config_item)
    
    print(f"[RESULT] Drift detection complete: {json.dumps(result, indent=2)}")
    
    return result


def calculate_severity(resource_type, compliance_type):
    """
    Determines how severe the drift is based on resource type
    
    Why this matters:
    - Security group drift = CRITICAL (security impact)
    - Tag drift = LOW (cosmetic)
    - IAM drift = CRITICAL (access control)
    
    This helps prioritize remediation
    """
    if compliance_type == 'COMPLIANT':
        return 'NONE'
    
    # Critical resources that affect security
    critical_resources = [
        'AWS::EC2::SecurityGroup',
        'AWS::IAM::Role',
        'AWS::IAM::Policy',
        'AWS::KMS::Key',
        'AWS::S3::BucketPolicy'
    ]
    
    if resource_type in critical_resources:
        return 'CRITICAL'
    
    # Important resources that affect functionality
    important_resources = [
        'AWS::EC2::Instance',
        'AWS::RDS::DBInstance',
        'AWS::Lambda::Function'
    ]
    
    if resource_type in important_resources:
        return 'HIGH'
    
    return 'MEDIUM'


def get_drift_details(resource_type, resource_id, config_item):
    """
    Extracts specific details about what drifted
    
    Returns a simple dict showing:
    - What changed
    - Current value
    - Expected value (from Terraform)
    """
    details = {
        'changed_properties': [],
        'resource_configuration': config_item.get('configuration', {})
    }
    
    # For demo purposes, we note what properties exist
    # In production, you'd compare against Terraform state in S3
    if config_item.get('configurationItemDiff'):
        details['changed_properties'] = list(config_item['configurationItemDiff'].keys())
    
    return details


def log_drift(result):
    """
    Logs drift detection to CloudWatch
    
    Format is JSON for easy parsing and alerting
    """
    try:
        log_entry = {
            'log_type': 'DRIFT_DETECTION',
            'severity': result['drift_severity'],
            'resource': result['resource_id'],
            'drift_detected': result['is_drift'],
            'timestamp': result['timestamp']
        }
        print(f"[DRIFT_LOG] {json.dumps(log_entry)}")
    except Exception as e:
        print(f"[ERROR] Logging failed: {str(e)}")


# Local testing
if __name__ == "__main__":
    # Example: Security group was modified manually in console
    test_event = {
        "detail": {
            "configurationItem": {
                "resourceType": "AWS::EC2::SecurityGroup",
                "resourceId": "sg-0123456789abcdef",
                "ARN": "arn:aws:ec2:us-east-1:123456789012:security-group/sg-0123456789abcdef",
                "tags": {"terraform": "true", "environment": "production"}
            },
            "newEvaluationResult": {
                "complianceType": "NON_COMPLIANT"
            }
        }
    }
    
    result = handler(test_event, None)
    print(f"\nTest Result: {json.dumps(result, indent=2)}")

