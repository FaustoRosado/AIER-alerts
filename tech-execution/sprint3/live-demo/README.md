# sprint 3 live demo

interactive visualization of "concepts & synchronizations" architecture pattern with real aws infrastructure

following: "what you see is what it does" (meng & jackson, acm sigplan 2025)

## quick start

### option 1: docker (recommended)

```bash
git clone -b sprint3-v2 https://github.com/FaustoRosado/AIER-alerts.git
cd AIER-alerts/tech-execution/sprint3/live-demo
docker-compose up
```

browser opens at http://localhost:8501

### option 2: local python

```bash
git clone -b sprint3-v2 https://github.com/FaustoRosado/AIER-alerts.git
cd AIER-alerts/tech-execution/sprint3/live-demo

pip install -r requirements.txt
python download_model.py

# set aws credentials
export AWS_ACCESS_KEY_ID="your_key"
export AWS_SECRET_ACCESS_KEY="your_secret"

streamlit run dashboard.py
```

## what it proves

| objective | proof |
|-----------|-------|
| 3C step functions | json definition, live execution graph, streaming logs, retry logic demo |
| 3D eventbridge | json patterns, rule targets, integration testing |
| 3E lambda code | full source code, live logs, error handling |
| 3F testing | 5 test cases, expected vs actual, execution logs |
| 3G error handling | triggerable failures, retry demonstrations, escalation workflow |

## features

- real step functions executions (not screenshots)
- live cloudwatch logs streaming
- eventbridge rules tested on-demand
- lambda functions with source code
- healthcare vitals analyzed by local phi-3 llm
- error scenarios with interactive triggers
- retry logic with countdown timers

## requirements

**system**:
- docker (for option 1) or python 3.11+ (for option 2)
- 4gb ram minimum (for phi-3 model)
- internet connection (for model download, first time only)

**aws**:
- deployed infrastructure (run terraform apply in automation/terraform/)
- read-only credentials (provided in reviewer-credentials.json)
- credentials expire after 72 hours

## dashboard tabs

1. **overview**: system status and quick actions
2. **healthcare alert**: enter vitals, watch local llm analyze
3. **step functions**: view executions, trigger workflows, see retry logic
4. **eventbridge rules**: view patterns, test rules, see integration
5. **lambda functions**: view code, invoke functions, see logs
6. **test suite**: run 5 test cases, compare results, view evidence
7. **error handling**: trigger failures, watch retries, see escalation

## time needed

- first run: 5 minutes (model download)
- subsequent runs: 30 seconds
- demo walkthrough: 5-10 minutes

## troubleshooting

**dashboard won't start**:
```bash
docker-compose down
docker-compose up --build
```

**model not downloading**:
```bash
python download_model.py
# or manually download from:
# https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf
```

**aws not connecting**:
```bash
# verify credentials
aws sts get-caller-identity

# check expiration
cat reviewer-credentials.json | grep expires
```

## verification

dashboard shows real data from aws. verify by:
- logging into aws console with provided credentials
- comparing step functions executions in console vs dashboard
- checking cloudwatch logs match dashboard logs
- confirming lambda functions exist

all proof is real, not mocked.

## files

- `dashboard.py` - main streamlit application
- `aws/connector.py` - aws sdk wrapper
- `utils/llm_runner.py` - local llm inference
- `requirements.txt` - python dependencies
- `Dockerfile` - container configuration
- `docker-compose.yml` - one-command deployment
- `download_model.py` - phi-3 model downloader

## branch

sprint3-v2

