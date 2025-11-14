# sprint 3 resubmission - live demo system

## what this is

implementation of the "concepts & synchronizations" architectural pattern from "What You See Is What It Does" (Meng & Jackson, ACM SIGPLAN 2025) applied to devops automation and healthcare alerting.

**architecture** (following paper sections 2-6):
- concepts (section 2): independent lambda functions, each with single purpose, no inter-concept dependencies
- synchronizations (section 3): eventbridge rules mediating between concepts via events, not direct calls
- orchestration (section 6): step functions coordinating flows with explicit synchronizations
- transparency (section 6.6): complete provenance tracking via cloudwatch logs and execution history

**dashboard**: visualization layer (not part of architecture) making invisible structure visible per paper's title principle

## what it addresses

- **3C**: step functions state machine with live execution graphs and retry logic
- **3D**: eventbridge rules with json patterns and lambda integration
- **3E**: lambda remediation code with error handling and structured logging
- **3F**: automated testing with expected vs actual results from real aws
- **3G**: error paths and failure handling with live retry demonstrations

plus: healthcare ai-er alert system using local phi-3 llm for patient vitals analysis

## how to run

### option 1: docker (easiest)

```bash
git clone https://github.com/YOUR_REPO/capstone.git
cd capstone/tech-execution/sprint3/live-demo
docker-compose up
```

browser opens at `localhost:8501` showing live dashboard

### option 2: local python

```bash
git clone -b sprint3-v2 https://github.com/YOUR_REPO/capstone.git
cd capstone/tech-execution/sprint3/live-demo
pip install -r requirements.txt
streamlit run dashboard.py
```

### option 3: google colab (no install)

open: `Sprint3_Demo.ipynb` in repo, click "run all"

## what you'll see

- real step functions executions (not screenshots)
- live cloudwatch logs streaming
- eventbridge rules tested interactively
- lambda functions with full source code
- healthcare vitals analyzed by local llm in 0.5 seconds
- error scenarios triggerable with buttons
- retry logic with countdown timers

## credentials

72-hour read-only aws access (generated via `generate_reviewer_creds.py`, expires automatically)

## time needed

- setup: 5 minutes
- demo: 5 minutes
- full exploration: 20 minutes

## files

- `demo_guide.md` - complete walkthrough
- `automation/` - all lambda functions, step functions, eventbridge rules
- `terraform/` - infrastructure as code (deployed)

## proof

everything runs against real deployed aws infrastructure. no mocks, no simulations. you can verify by logging into aws console with provided credentials.

branch: `sprint3-v2`

