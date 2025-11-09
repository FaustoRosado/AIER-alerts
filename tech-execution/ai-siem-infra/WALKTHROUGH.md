# Sprint 4 Walkthrough

## Prerequisites

- AWS CLI + credentials
- Terraform
- Proxmox access
- Tailscale account
- Splunk instance
- Git

## Task 1: Terraform

```bash
cd terraform
```

Create `main.tf`:
```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/sprint4/app-logs"
  retention_in_days = 7
}

resource "aws_iam_role" "lambda_role" {
  name = "sprint4-lambda-logs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
```

Deploy:
```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Screenshots: init output, plan, apply progress, apply complete, AWS console, state list

## Task 2: Tailscale Relay

Launch EC2:
```bash
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t2.micro \
  --key-name your-key \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=sprint4-tailscale}]'
```

SSH and install:
```bash
ssh -i key.pem ec2-user@<ip>
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --advertise-routes=10.0.0.0/16
tailscale status
```

Screenshots: EC2 instance, install output, status, routes, ping test

## Task 3: Proxmox GGUF

Create VM in Proxmox UI:
- VM ID: 200
- Name: sprint4-ai
- OS: Ubuntu 22.04
- Disk: 50GB, CPU: 4, RAM: 8GB

SSH and setup:
```bash
ssh user@<vm-ip>
sudo apt update && sudo apt install -y build-essential git cmake
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp && make
cd models
wget https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf
cd ..
./server -m models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf --port 8080
```

Test:
```bash
curl -X POST http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"test"}]}'
```

Screenshots: VM config, model file, server running, inference response

## Task 4: CloudWatch to Splunk

Configure Splunk HEC:
- Settings > Data Inputs > HTTP Event Collector
- Create token, save it

Create `lambda.py`:
```python
import base64, gzip, json, os, urllib.request

SPLUNK_URL = os.environ['SPLUNK_HEC_URL']
SPLUNK_TOKEN = os.environ['SPLUNK_HEC_TOKEN']

def lambda_handler(event, context):
    data = gzip.decompress(base64.b64decode(event['awslogs']['data']))
    logs = json.loads(data)
    
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
```

Deploy Lambda in AWS Console, add env vars.

Add permission:
```bash
aws lambda add-permission \
  --function-name cloudwatch-to-splunk \
  --statement-id cloudwatch-logs \
  --action lambda:InvokeFunction \
  --principal logs.amazonaws.com
```

Create subscription:
```bash
aws logs put-subscription-filter \
  --log-group-name /aws/sprint4/app-logs \
  --filter-name splunk-forwarder \
  --filter-pattern "" \
  --destination-arn arn:aws:lambda:REGION:ACCOUNT:function:cloudwatch-to-splunk
```

Test:
```bash
aws logs put-log-events \
  --log-group-name /aws/sprint4/app-logs \
  --log-stream-name test \
  --log-events timestamp=$(date +%s000),message="test"
```

Check Splunk:
```
index=main sourcetype=aws:cloudwatch earliest=-5m
```

Screenshots: HEC config, Lambda function, subscription filter, logs in Splunk, metrics

## Task 5: MCP Local AI

Setup:
```bash
mkdir -p mcp-server && cd mcp-server
npm init -y
npm install express axios
```

Create `server.js`:
```javascript
const express = require('express');
const axios = require('axios');
const app = express();
app.use(express.json());

const AI_URL = process.env.LOCAL_AI_URL || 'http://localhost:8080';

app.post('/mcp/tools', async (req, res) => {
  const { tool, params } = req.body;
  if (tool === 'query') {
    try {
      const response = await axios.post(`${AI_URL}/v1/chat/completions`, {
        messages: [{ role: 'user', content: params.prompt }]
      });
      res.json({ success: true, result: response.data.choices[0].message.content });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  } else {
    res.status(400).json({ success: false, error: 'Unknown tool' });
  }
});

app.get('/health', (req, res) => res.json({ status: 'ok' }));

app.listen(3000, () => console.log('MCP server on port 3000'));
```

Run:
```bash
node server.js
```

Test:
```bash
curl -X POST http://localhost:3000/mcp/tools \
  -H "Content-Type: application/json" \
  -d '{"tool":"query","params":{"prompt":"test"}}'
```

Screenshots: config, server running, test response, integration test

## Task 6: GitHub

```bash
cd /path/to/ai-siem-infra
git checkout -b sprint4-ai-siem-infra
git add .
git commit -m "Sprint 4: AI SIEM infrastructure"
git push origin sprint4-ai-siem-infra
```

Create PR on GitHub.

## Completion

- [ ] 28 screenshots captured
- [ ] All services running
- [ ] Tests passed
- [ ] STATUS.md updated
- [ ] Branch pushed
- [ ] PR created
