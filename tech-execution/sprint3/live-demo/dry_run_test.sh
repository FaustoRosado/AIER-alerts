#!/bin/bash
# Dry run test - validates setup without requiring AWS credentials

set -e

echo "sprint 3 dry run validation"
echo "============================"
echo
echo "this tests the system WITHOUT aws credentials"
echo "validates: code structure, llm integration, dependencies"
echo

# Check Python
echo "[1/5] checking python..."
if ! command -v python3 &> /dev/null; then
    echo "  ERROR: python3 not found"
    exit 1
fi
echo "  found: $(python3 --version)"

# Check dependencies
echo "[2/5] checking dependencies..."
python3 -c "import streamlit" 2>/dev/null || {
    echo "  installing streamlit..."
    pip install streamlit
}
python3 -c "import boto3" 2>/dev/null || {
    echo "  installing boto3..."
    pip install boto3  
}
echo "  all dependencies available"

# Check model (optional for dry run)
echo "[3/5] checking phi-3 model..."
if [ -f "/opt/models/Phi-3-mini-4k-instruct-q4.gguf" ]; then
    echo "  found model"
else
    echo "  model not found (will use rule-based fallback)"
fi

# Test LLM standalone
echo "[4/5] testing llm runner..."
python3 -c "
from utils.llm_runner import LLMRunner
llm = LLMRunner()
print(f'  llm status: {\"ready\" if llm.is_ready() else \"fallback mode\"}')
"

# Validate code structure
echo "[5/5] validating code structure..."
python3 << 'PYTHON'
import os
import sys

# Check required files
required_files = [
    'dashboard.py',
    'aws/connector.py',
    'utils/llm_runner.py',
    'requirements.txt',
    'Dockerfile',
    'docker-compose.yml'
]

missing = []
for f in required_files:
    if not os.path.exists(f):
        missing.append(f)

if missing:
    print(f"  ERROR: missing files: {missing}")
    sys.exit(1)
else:
    print("  all required files present")
PYTHON

echo
echo "============================"
echo "dry run validation: PASS"
echo "============================"
echo
echo "system structure is valid"
echo "ready for aws deployment testing"
echo
echo "next steps:"
echo "1. deploy infrastructure: cd ../automation/terraform && terraform apply"
echo "2. generate credentials: python generate_reviewer_creds.py"
echo "3. run dashboard: docker-compose up"

