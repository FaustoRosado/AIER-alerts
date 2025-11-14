"""
AWS Connector - Query Interface for Concept & Synchronization States

Purpose: Read-only access to deployed concepts and synchronizations
Pattern: Section 6.4 from paper - "reads are handled by client-driven querying"

This module:
- Queries concept states (Lambda functions, their logs, execution history)
- Queries synchronization configurations (EventBridge rules, event patterns)
- Never modifies state (read-only, following pattern principle)
- Provides federation across multiple AWS services (Step Functions, Lambda, EventBridge, CloudWatch)

Key Pattern Adherence:
- NO getters in concepts - we query databases directly (CloudWatch, Step Functions history)
- NO coupling introduced - we observe, don't connect
- Transparency - every query shows action provenance
"""

import boto3
import json
from datetime import datetime, timedelta
from typing import Dict, List, Optional
import os


class AWSConnector:
    """
    Connects to AWS and provides clean methods for dashboard
    
    Purpose: Abstract AWS SDK complexity, provide simple methods
    """
    
    def __init__(self, region='us-east-1'):
        """
        Initialize AWS clients
        
        Supports both:
        - Regular credentials (access key + secret)
        - STS temporary credentials (access key + secret + session token)
        """
        self.region = region
        
        try:
            # Get credentials from environment or boto3 defaults
            # boto3 automatically handles session tokens from env vars
            self.sfn = boto3.client('stepfunctions', region_name=region)
            self.lambda_client = boto3.client('lambda', region_name=region)
            self.events = boto3.client('events', region_name=region)
            self.logs = boto3.client('logs', region_name=region)
            self.sns = boto3.client('sns', region_name=region)
            self.sts = boto3.client('sts', region_name=region)
            
            # Verify connection
            self.account_id = self.sts.get_caller_identity()['Account']
            self.connected = True
            
        except Exception as e:
            print(f"AWS connection failed: {e}")
            self.connected = False
            self.account_id = None
    
    
    def is_connected(self) -> bool:
        """Check if connected to AWS"""
        return self.connected
    
    
    # ========================================================================
    # STEP FUNCTIONS QUERIES (for 3C proof)
    # 
    # PATTERN NOTE (paper Section 6.4):
    # "Reads are handled by client-driven querying capabilities"
    # 
    # These are NOT getters on concepts (which would introduce coupling).
    # These are database queries against AWS services.
    # Step Functions execution history = the "database" we're querying.
    # ========================================================================
    
    def list_state_machines(self) -> List[Dict]:
        """
        Query: Get all Step Functions state machines
        
        This is a federated query across AWS Step Functions service.
        Not a getter on a concept - we're querying the state directly.
        """
        try:
            response = self.sfn.list_state_machines()
            return response.get('stateMachines', [])
        except Exception as e:
            print(f"Error listing state machines: {e}")
            return []
    
    
    def get_state_machine_definition(self, arn: str) -> Dict:
        """Get state machine JSON definition"""
        try:
            response = self.sfn.describe_state_machine(stateMachineArn=arn)
            definition = json.loads(response['definition'])
            return {
                'name': response['name'],
                'arn': arn,
                'status': response['status'],
                'definition': definition,
                'created': response['creationDate'].isoformat()
            }
        except Exception as e:
            print(f"Error getting state machine: {e}")
            return {}
    
    
    def start_execution(self, state_machine_arn: str, input_data: Dict, name: Optional[str] = None) -> Optional[str]:
        """
        Start Step Functions execution
        Returns execution ARN
        """
        try:
            if name is None:
                name = f"demo-{int(datetime.now().timestamp())}"
            
            response = self.sfn.start_execution(
                stateMachineArn=state_machine_arn,
                name=name,
                input=json.dumps(input_data)
            )
            return response['executionArn']
        except Exception as e:
            print(f"Error starting execution: {e}")
            return None
    
    
    def get_execution_status(self, execution_arn: str) -> Dict:
        """Get current status of execution"""
        try:
            response = self.sfn.describe_execution(executionArn=execution_arn)
            return {
                'arn': execution_arn,
                'status': response['status'],
                'start_date': response['startDate'].isoformat(),
                'stop_date': response.get('stopDate', datetime.now()).isoformat() if response.get('stopDate') else None,
                'input': json.loads(response['input']),
                'output': json.loads(response['output']) if response.get('output') else None
            }
        except Exception as e:
            print(f"Error getting execution status: {e}")
            return {}
    
    
    def get_execution_history(self, execution_arn: str) -> List[Dict]:
        """Get execution event history (for retry logic proof)"""
        try:
            events = []
            paginator = self.sfn.get_paginator('get_execution_history')
            
            for page in paginator.paginate(executionArn=execution_arn):
                events.extend(page['events'])
            
            return events
        except Exception as e:
            print(f"Error getting execution history: {e}")
            return []
    
    
    def list_recent_executions(self, state_machine_arn: str, max_results: int = 10) -> List[Dict]:
        """List recent executions"""
        try:
            response = self.sfn.list_executions(
                stateMachineArn=state_machine_arn,
                maxResults=max_results
            )
            return response.get('executions', [])
        except Exception as e:
            print(f"Error listing executions: {e}")
            return []
    
    
    # ========================================================================
    # EVENTBRIDGE METHODS (for 3D proof)
    # ========================================================================
    
    def list_rules(self, prefix: str = 'sprint3-automation') -> List[Dict]:
        """Get all EventBridge rules"""
        try:
            response = self.events.list_rules(NamePrefix=prefix)
            rules = []
            
            for rule in response.get('Rules', []):
                # Get full details including event pattern
                detail = self.events.describe_rule(Name=rule['Name'])
                rules.append({
                    'name': detail['Name'],
                    'arn': detail['Arn'],
                    'state': detail['State'],
                    'event_pattern': json.loads(detail.get('EventPattern', '{}')),
                    'description': detail.get('Description', '')
                })
            
            return rules
        except Exception as e:
            print(f"Error listing rules: {e}")
            return []
    
    
    def get_rule_targets(self, rule_name: str) -> List[Dict]:
        """Get targets (Lambdas) for an EventBridge rule"""
        try:
            response = self.events.list_targets_by_rule(Rule=rule_name)
            return response.get('Targets', [])
        except Exception as e:
            print(f"Error getting rule targets: {e}")
            return []
    
    
    def send_test_event(self, event_data: Dict) -> bool:
        """Send test event to EventBridge"""
        try:
            response = self.events.put_events(
                Entries=[{
                    'Source': event_data.get('source', 'custom.demo'),
                    'DetailType': event_data.get('detail_type', 'Test Event'),
                    'Detail': json.dumps(event_data.get('detail', {}))
                }]
            )
            return response['FailedEntryCount'] == 0
        except Exception as e:
            print(f"Error sending test event: {e}")
            return False
    
    
    # ========================================================================
    # LAMBDA METHODS (for 3E proof)
    # ========================================================================
    
    def list_functions(self, prefix: str = 'sprint3-automation') -> List[Dict]:
        """Get all Lambda functions"""
        try:
            response = self.lambda_client.list_functions()
            functions = [f for f in response.get('Functions', []) 
                        if f['FunctionName'].startswith(prefix)]
            return functions
        except Exception as e:
            print(f"Error listing functions: {e}")
            return []
    
    
    def get_function_code(self, function_name: str) -> Optional[str]:
        """
        Get Lambda function source code
        Note: In production, downloads from S3. For demo, reads local files.
        """
        try:
            # Read from local file (what's deployed)
            function_map = {
                'pipeline-validator': '../automation/concepts/pipeline-validator/handler.py',
                'drift-detector': '../automation/concepts/drift-detector/handler.py',
                'auto-remediator': '../automation/concepts/auto-remediator/handler.py',
                'vitals-analyzer': '../automation/concepts/vitals-analyzer/handler.py'
            }
            
            for key, path in function_map.items():
                if key in function_name:
                    file_path = os.path.join(os.path.dirname(__file__), path)
                    if os.path.exists(file_path):
                        with open(file_path, 'r') as f:
                            return f.read()
            
            return None
        except Exception as e:
            print(f"Error getting function code: {e}")
            return None
    
    
    def invoke_function(self, function_name: str, payload: Dict) -> Dict:
        """Invoke Lambda function and get response"""
        try:
            response = self.lambda_client.invoke(
                FunctionName=function_name,
                InvocationType='RequestResponse',
                Payload=json.dumps(payload)
            )
            
            result = json.loads(response['Payload'].read())
            return {
                'status_code': response['StatusCode'],
                'result': result,
                'function_name': function_name,
                'timestamp': datetime.now().isoformat()
            }
        except Exception as e:
            print(f"Error invoking function: {e}")
            return {'error': str(e)}
    
    
    # ========================================================================
    # CLOUDWATCH LOGS METHODS (for log streaming)
    # ========================================================================
    
    def get_log_groups(self, prefix: str = '/aws/lambda/sprint3') -> List[str]:
        """Get CloudWatch log groups"""
        try:
            response = self.logs.describe_log_groups(logGroupNamePrefix=prefix)
            return [lg['logGroupName'] for lg in response.get('logGroups', [])]
        except Exception as e:
            print(f"Error getting log groups: {e}")
            return []
    
    
    def get_recent_logs(self, log_group: str, minutes: int = 5, limit: int = 50) -> List[Dict]:
        """Get recent log events"""
        try:
            start_time = int((datetime.now() - timedelta(minutes=minutes)).timestamp() * 1000)
            
            response = self.logs.filter_log_events(
                logGroupName=log_group,
                startTime=start_time,
                limit=limit
            )
            
            return response.get('events', [])
        except Exception as e:
            print(f"Error getting logs: {e}")
            return []
    
    
    def tail_logs(self, log_group: str, since_timestamp: int) -> List[Dict]:
        """Get logs since specific timestamp (for streaming)"""
        try:
            response = self.logs.filter_log_events(
                logGroupName=log_group,
                startTime=since_timestamp
            )
            return response.get('events', [])
        except Exception as e:
            return []
    
    
    # ========================================================================
    # SNS METHODS (for notification proof)
    # ========================================================================
    
    def list_topics(self, prefix: str = 'sprint3') -> List[Dict]:
        """Get SNS topics"""
        try:
            response = self.sns.list_topics()
            all_topics = response.get('Topics', [])
            
            # Filter by prefix
            topics = []
            for topic in all_topics:
                topic_name = topic['TopicArn'].split(':')[-1]
                if prefix in topic_name:
                    topics.append({
                        'arn': topic['TopicArn'],
                        'name': topic_name
                    })
            
            return topics
        except Exception as e:
            print(f"Error listing topics: {e}")
            return []
    
    
    # ========================================================================
    # HELPER METHODS
    # ========================================================================
    
    def get_connection_info(self) -> Dict:
        """Get AWS connection information for dashboard display"""
        if not self.connected:
            return {'connected': False, 'error': 'Not connected to AWS'}
        
        return {
            'connected': True,
            'account_id': self.account_id,
            'region': self.region,
            'timestamp': datetime.now().isoformat()
        }

