#!/bin/bash
# Validation script to verify everything is set up correctly

echo "sprint 3 setup validation"
echo "========================="
echo

# Check 1: Python
echo "[1/6] checking python..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo "  found: $PYTHON_VERSION"
else
    echo "  ERROR: python3 not found"
    echo "  install python 3.11+ from python.org"
    exit 1
fi

# Check 2: Docker (optional)
echo "[2/6] checking docker..."
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    echo "  found: $DOCKER_VERSION"
else
    echo "  not found (optional, can use python instead)"
fi

# Check 3: AWS CLI and credentials
echo "[3/6] checking aws credentials..."
if command -v aws &> /dev/null; then
    if aws sts get-caller-identity &> /dev/null; then
        ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
        echo "  found: account $ACCOUNT"
    else
        echo "  WARNING: aws cli installed but not configured"
        echo "  set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY"
    fi
else
    echo "  WARNING: aws cli not installed (optional)"
    echo "  credentials can be set via environment variables"
fi

# Check 4: Model file
echo "[4/6] checking phi-3 model..."
MODEL_PATH="/opt/models/Phi-3-mini-4k-instruct-q4.gguf"
if [ -f "$MODEL_PATH" ]; then
    MODEL_SIZE=$(du -h "$MODEL_PATH" | cut -f1)
    echo "  found: $MODEL_SIZE"
else
    echo "  not found at $MODEL_PATH"
    echo "  run: python3 download_model.py"
    echo "  this downloads 2.4gb file (one-time)"
fi

# Check 5: Python dependencies
echo "[5/6] checking python dependencies..."
python3 -c "import streamlit" 2>/dev/null && echo "  streamlit: installed" || echo "  streamlit: missing"
python3 -c "import boto3" 2>/dev/null && echo "  boto3: installed" || echo "  boto3: missing"
python3 -c "import llama_cpp" 2>/dev/null && echo "  llama-cpp-python: installed" || echo "  llama-cpp-python: missing"

MISSING_DEPS=$(python3 -c "
import sys
try:
    import streamlit, boto3, llama_cpp
    sys.exit(0)
except ImportError:
    sys.exit(1)
" 2>/dev/null)

if [ $? -eq 0 ]; then
    echo "  all dependencies installed"
else
    echo "  some dependencies missing"
    echo "  run: pip install -r requirements.txt"
fi

# Check 6: Terraform infrastructure
echo "[6/6] checking deployed infrastructure..."
if command -v aws &> /dev/null && aws sts get-caller-identity &> /dev/null; then
    LAMBDA_COUNT=$(aws lambda list-functions --query "length(Functions[?starts_with(FunctionName, 'sprint3-automation')])" --output text 2>/dev/null)
    
    if [ "$LAMBDA_COUNT" -gt 0 ]; then
        echo "  found $LAMBDA_COUNT lambda functions deployed"
    else
        echo "  no lambda functions found"
        echo "  run: cd ../automation/terraform && terraform apply"
    fi
else
    echo "  skipped (aws not configured)"
fi

echo
echo "========================="
echo "validation complete"
echo

# Final readiness check
READY=true

if ! command -v python3 &> /dev/null; then
    READY=false
fi

if ! python3 -c "import streamlit, boto3" &> /dev/null; then
    echo "action required: pip install -r requirements.txt"
    READY=false
fi

if [ ! -f "$MODEL_PATH" ]; then
    echo "action required: python3 download_model.py"
    READY=false
fi

if [ "$READY" = true ]; then
    echo "READY TO RUN"
    echo "execute: ./start.sh"
    echo "or: docker-compose up"
else
    echo "SETUP INCOMPLETE"
    echo "complete actions above then run ./start.sh"
fi

