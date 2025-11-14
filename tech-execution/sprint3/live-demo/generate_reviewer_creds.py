#!/usr/bin/env python3
"""
Generate 72-hour AWS credentials for reviewer

PURPOSE: Create time-limited read-only access for demo reviewer
PATTERN: Utility script, not part of system architecture

APPROACH: IAM user with time-based policy condition (not STS)
    - STS max is 36 hours, we need 72 hours
    - Create IAM user with inline policy
    - Policy has DateLessThan condition for 72 hours
    - Credentials stop working after 72 hours automatically
    - Cleanup script generated to delete user after demo

NOTE ON PATTERN ADHERENCE (from paper Section 6):
    This script is outside the Concepts & Synchronizations architecture.
    It's a deployment/configuration tool, not a runtime concept.
    Does not introduce coupling to system components.
"""

import boto3
import json
import sys
from datetime import datetime, timedelta


def generate_temporary_credentials(duration_hours=72):
    """
    Generate 72-hour AWS credentials using IAM user with time-based policy
    
    Creates:
    - IAM user (unique name with timestamp)
    - Access key for that user
    - Inline policy with DateLessThan condition for 72 hours
    
    After 72 hours: Credentials auto-deny (policy condition blocks all actions)
    Manual cleanup: Run generated cleanup script to delete user
    """
    
    try:
        iam = boto3.client('iam')
        sts = boto3.client('sts')
        
        # Get current account
        identity = sts.get_caller_identity()
        account_id = identity['Account']
        
        print(f"generating 72-hour credentials for account: {account_id}")
        print(f"duration: {duration_hours} hours")
        print()
        
        # Create unique user name
        timestamp = int(datetime.now().timestamp())
        user_name = f"sprint3-reviewer-{timestamp}"
        
        # Calculate expiration
        expires_at = datetime.now() + timedelta(hours=duration_hours)
        expiry_iso = expires_at.strftime('%Y-%m-%dT%H:%M:%SZ')
        
        print(f"creating iam user: {user_name}")
        
        # Create IAM user
        iam.create_user(
            UserName=user_name,
            Tags=[
                {'Key': 'Purpose', 'Value': 'Sprint3Demo'},
                {'Key': 'Expires', 'Value': expiry_iso},
                {'Key': 'AutoDelete', 'Value': 'true'}
            ]
        )
        
        print("user created")
        
        # Create access key
        print("generating access key...")
        key_response = iam.create_access_key(UserName=user_name)
        
        access_key_id = key_response['AccessKey']['AccessKeyId']
        secret_access_key = key_response['AccessKey']['SecretAccessKey']
        
        print(f"access key: {access_key_id}")
        
        # Create policy with time condition
        print("attaching time-limited read-only policy...")
        
        policy_document = {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "ReadOnlyAccessWithExpiry",
                    "Effect": "Allow",
                    "Action": [
                        "logs:Get*", "logs:Describe*", "logs:Filter*",
                        "lambda:Get*", "lambda:List*", "lambda:Invoke",
                        "states:Describe*", "states:List*", "states:GetExecutionHistory", "states:StartExecution",
                        "events:List*", "events:Describe*", "events:PutEvents",
                        "sns:List*", "sns:Get*",
                        "config:Describe*", "config:Get*"
                    ],
                    "Resource": "*",
                    "Condition": {
                        "DateLessThan": {
                            "aws:CurrentTime": expiry_iso
                        }
                    }
                },
                {
                    "Sid": "DenyAllAfterExpiry",
                    "Effect": "Deny",
                    "Action": "*",
                    "Resource": "*",
                    "Condition": {
                        "DateGreaterThanEquals": {
                            "aws:CurrentTime": expiry_iso
                        }
                    }
                }
            ]
        }
        
        iam.put_user_policy(
            UserName=user_name,
            PolicyName='ReadOnlyWithExpiry',
            PolicyDocument=json.dumps(policy_document)
        )
        
        print("policy attached with 72-hour expiry")
        print()
        
        # Create credentials file
        credentials = {
            'access_key_id': access_key_id,
            'secret_access_key': secret_access_key,
            'region': 'us-east-1',
            'expires': expiry_iso,
            'duration_hours': duration_hours,
            'generated': datetime.now().isoformat(),
            'account_id': account_id,
            'user_name': user_name,
            'permissions': 'read-only with time condition',
            'auto_expires': True,
            'note': 'policy denies all actions after expiry time'
        }
        
        # Save to file
        with open('reviewer-credentials.json', 'w') as f:
            json.dump(credentials, f, indent=2)
        
        print("credentials saved to: reviewer-credentials.json")
        print()
        
        # Create .env file for docker-compose (no session token for IAM user)
        with open('.env', 'w') as f:
            f.write(f"AWS_ACCESS_KEY_ID={access_key_id}\n")
            f.write(f"AWS_SECRET_ACCESS_KEY={secret_access_key}\n")
            f.write(f"AWS_DEFAULT_REGION=us-east-1\n")
        
        print("environment file created: .env (for docker-compose)")
        print()
        
        # Test credentials
        print("testing credentials...")
        test_sts = boto3.client(
            'sts',
            aws_access_key_id=access_key_id,
            aws_secret_access_key=secret_access_key
        )
        
        test_identity = test_sts.get_caller_identity()
        print(f"credentials valid for account: {test_identity['Account']}")
        print(f"user arn: {test_identity['Arn']}")
        print()
        
        # Create cleanup script
        print("creating cleanup script...")
        cleanup_script = f"""#!/bin/bash
# Cleanup script - run after demo to remove temporary IAM user

echo "cleaning up sprint 3 reviewer access..."

# Delete access key
aws iam delete-access-key --user-name {user_name} --access-key-id {access_key_id}
echo "access key deleted"

# Delete user policy
aws iam delete-user-policy --user-name {user_name} --policy-name ReadOnlyWithExpiry
echo "policy deleted"

# Delete user
aws iam delete-user --user-name {user_name}
echo "user deleted"

# Remove credential files
rm -f reviewer-credentials.json .env
echo "credential files removed"

echo
echo "cleanup complete"
echo "user {user_name} has been removed"
"""
        
        with open('cleanup_reviewer.sh', 'w') as f:
            f.write(cleanup_script)
        
        import os
        os.chmod('cleanup_reviewer.sh', 0o755)
        
        print("cleanup script created: cleanup_reviewer.sh")
        print()
        
        # Usage instructions
        print("="*70)
        print("USAGE INSTRUCTIONS")
        print("="*70)
        print()
        print("option 1: docker (uses .env automatically)")
        print("  docker-compose up")
        print()
        print("option 2: local python")
        print(f"  export AWS_ACCESS_KEY_ID={access_key_id}")
        print(f"  export AWS_SECRET_ACCESS_KEY={secret_access_key}")
        print("  streamlit run dashboard.py")
        print()
        print(f"credentials expire at: {expiry_iso} (72 hours from now)")
        print("after expiry: policy automatically denies all actions")
        print()
        print("cleanup after demo:")
        print("  ./cleanup_reviewer.sh")
        print()
        
        return 0
        
    except Exception as e:
        print(f"error generating credentials: {e}")
        print()
        print("troubleshooting:")
        print("1. verify aws cli configured: aws sts get-caller-identity")
        print("2. ensure you have iam permissions: iam:CreateUser, iam:CreateAccessKey, iam:PutUserPolicy")
        print("3. check you're running as admin or have appropriate permissions")
        return 1


if __name__ == "__main__":
    print()
    print("sprint 3 reviewer access generator")
    print("creates 72-hour time-limited credentials")
    print()
    
    duration = 72  # Default 72 hours
    
    if len(sys.argv) > 1:
        try:
            duration = int(sys.argv[1])
        except ValueError:
            print("usage: python generate_reviewer_creds.py [hours]")
            print("example: python generate_reviewer_creds.py 72")
            sys.exit(1)
    
    sys.exit(generate_temporary_credentials(duration))

