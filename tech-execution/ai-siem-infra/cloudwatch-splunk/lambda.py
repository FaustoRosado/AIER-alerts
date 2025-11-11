import base64
import gzip
import json
import os
import urllib.request

# Splunk HEC configuration from environment
SPLUNK_URL = os.environ['SPLUNK_HEC_URL']
SPLUNK_TOKEN = os.environ['SPLUNK_HEC_TOKEN']

def lambda_handler(event, context):
    # Decode CloudWatch log data
    data = gzip.decompress(base64.b64decode(event['awslogs']['data']))
    logs = json.loads(data)
    
    # Forward each log event to Splunk
    for log in logs['logEvents']:
        payload = {
            'event': log['message'],
            'time': log['timestamp'] / 1000,
            'source': logs['logGroup']
        }
        req = urllib.request.Request(
            SPLUNK_URL,
            data=json.dumps(payload).encode(),
            headers={'Authorization': f'Splunk {SPLUNK_TOKEN}'}
        )
        urllib.request.urlopen(req)
    
    return {'statusCode': 200}

