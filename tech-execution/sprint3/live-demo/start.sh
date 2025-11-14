#!/bin/bash
# Quick start script for Sprint 3 demo

echo "sprint 3 live demo startup"
echo "=========================="
echo

# Check if Docker is running
if command -v docker &> /dev/null && docker info &> /dev/null; then
    echo "docker detected, using docker-compose..."
    docker-compose up
elif command -v python3 &> /dev/null; then
    echo "using local python..."
    
    # Check if model exists
    if [ ! -f "/opt/models/Phi-3-mini-4k-instruct-q4.gguf" ]; then
        echo "downloading phi-3 model (first time only, 2.4gb)..."
        python3 download_model.py
    fi
    
    # Check dependencies
    python3 -c "import streamlit" 2>/dev/null || {
        echo "installing dependencies..."
        pip install -r requirements.txt
    }
    
    # Check AWS credentials
    if [ -z "$AWS_ACCESS_KEY_ID" ]; then
        echo
        echo "warning: AWS credentials not set"
        echo "export AWS_ACCESS_KEY_ID=..."
        echo "export AWS_SECRET_ACCESS_KEY=..."
        echo
    fi
    
    # Run dashboard
    streamlit run dashboard.py
else
    echo "error: neither docker nor python3 found"
    echo "install docker or python 3.11+ to continue"
    exit 1
fi

