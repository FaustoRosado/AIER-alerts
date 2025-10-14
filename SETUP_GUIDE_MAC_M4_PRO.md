# AI/ER Capstone Project - Complete Setup Guide for Mac M4 Pro
# Sprint 2: Local Development Environment Setup
#
# This guide provides step-by-step instructions for setting up the complete AI/ER
# development environment on macOS with Apple Silicon (M4 Pro).
#
# Tested on: macOS Sonoma 14.x, Apple M4 Pro
# Last Updated: October 2025

## Prerequisites

Before starting, ensure you have:

### Required Software
- **macOS**: Sonoma 14.x or later
- **Terminal**: Built-in Terminal.app or iTerm2
- **Git**: For version control
- **Python 3.11+**: For the Flask application
- **Homebrew**: For package management

### Hardware Requirements
- **RAM**: 16GB+ recommended (8GB minimum for basic operation)
- **Storage**: 20GB+ free space for models and dependencies
- **Network**: Internet connection for initial setup

---

## Step 1: Clone the Repository

```bash
# Navigate to your development directory
cd ~/Projects  # or wherever you want to store the project

# Clone the repository
git clone https://github.com/FaustoRosado/AIER-alerts.git

# Navigate to the project directory
cd AIER-alerts

# Switch to the tech-architecture branch
git checkout tech-architecture

# Verify you're on the correct branch
git branch --show-current
# Expected output: tech-architecture
```

**Verification**: The command `git branch --show-current` should return `tech-architecture`.

---

## Step 2: Install Required Dependencies

### 2.1 Install Homebrew (if not already installed)

```bash
# Check if Homebrew is installed
which brew

# If not installed, run:
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Verify installation
brew --version
```

### 2.2 Install Required Packages

```bash
# Install Python 3 (if not already installed)
brew install python@3.12

# Install CMake (required for llama.cpp)
brew install cmake

# Install Git (if not already installed)
brew install git

# Install additional tools
brew install wget curl
```

**Verification**:
```bash
# Check Python version
python3 --version
# Expected: Python 3.12.x

# Check CMake version
cmake --version
# Expected: cmake version 3.x

# Check Git version
git --version
# Expected: git version 2.x
```

---

## Step 3: Set Up Python Environment

### 3.1 Create Virtual Environment

```bash
# Create Python virtual environment
python3 -m venv venv

# Activate the virtual environment
source venv/bin/activate

# Verify activation (you should see (venv) in your prompt)
which python3
# Expected: /path/to/project/venv/bin/python3
```

### 3.2 Install Python Dependencies

```bash
# Upgrade pip
pip install --upgrade pip

# Install project requirements
pip install -r requirements.txt

# Verify Flask installation
python3 -c "import flask; print('Flask version:', flask.__version__)"
# Expected: Flask version 2.3.x

# Verify Flask-CORS installation
python3 -c "import flask_cors; print('Flask-CORS version:', flask_cors.__version__)"
# Expected: Flask-CORS version 4.0.x
```

**Troubleshooting**:
- If you get permission errors, ensure you're in the activated virtual environment
- If packages fail to install, try: `pip install --user -r requirements.txt`

---

## Step 4: Build llama.cpp

### 4.1 Clone and Build

```bash
# Navigate back to project root (if not already there)
cd /path/to/AIER-alerts

# Clone llama.cpp (if not already present)
if [ ! -d "llama.cpp" ]; then
    git clone https://github.com/ggerganov/llama.cpp.git
fi

# Navigate to llama.cpp directory
cd llama.cpp

# Create build directory
mkdir -p build

# Configure build (using Apple Silicon optimizations)
cmake -B build -DCMAKE_BUILD_TYPE=Release

# Build llama.cpp (this may take 5-10 minutes)
cmake --build build --config Release -j$(sysctl -n hw.ncpu)

# Verify build
ls -la build/bin/llama-cli
# Expected: -rwxr-xr-x 1 user user llama-cli binary
```

**Build Time**: Approximately 5-10 minutes on M4 Pro
**CPU Usage**: Will use multiple cores during build

**Verification**:
```bash
# Test llama.cpp binary
./build/bin/llama-cli --help | head -5
# Expected: Usage: llama-cli [options]
```

### 4.2 Create Models Directory

```bash
# Navigate back to project root
cd /path/to/AIER-alerts

# Create models directory
mkdir -p models

# For demo purposes, create a placeholder
echo "Demo model placeholder - replace with real GGUF model for full functionality" > models/README.md
```

---

## Step 5: Test the Setup

### 5.1 Run Integration Tests

```bash
# Activate virtual environment (if not already active)
source venv/bin/activate

# Run the integration test suite
./scripts/mac/test-integration.sh run

# Expected output: All tests should pass
# If any tests fail, check the troubleshooting section below
```

**Expected Test Results**:
- Environment Setup: PASSED
- Python Dependencies: PASSED
- Llama.cpp Build: PASSED
- Web Server Startup: PASSED
- API Health Check: PASSED
- Input Validation: PASSED

### 5.2 Start Development Server

```bash
# Start the development server
./scripts/mac/run-local.sh start

# Check server status
./scripts/mac/run-local.sh status

# Monitor server (in a new terminal tab)
./scripts/mac/run-local.sh monitor
```

**Access Points**:
- Web Interface: http://localhost:5000
- Health Check: http://localhost:5000/health
- Demo Interface: http://localhost:5000/demo.html

---

## Step 6: Run Interactive Demo

### 6.1 Create Demo Assets

```bash
# Run demo simulation (creates all demo files)
./scripts/mac/deploy-demo.sh

# Verify demo assets were created
ls -la demo-assets/
# Expected: Multiple demo files and logs
```

### 6.2 Run Interactive Demo

```bash
# Start the interactive demo
./demo-assets/run-demo.sh

# Or open the demo interface in browser
open http://localhost:5000/demo.html
```

**Demo Features**:
- Interactive chat simulation
- Architecture visualization
- Security features demonstration
- No real LLM required for demo

---

## Troubleshooting Common Issues

### Issue 1: Python Virtual Environment Not Activating

```bash
# Check if venv directory exists
ls -la venv/

# Recreate if missing
rm -rf venv
python3 -m venv venv
source venv/bin/activate
```

### Issue 2: CMake Build Fails

```bash
# Clean build directory and rebuild
cd llama.cpp
rm -rf build
mkdir build
cmake -B build
cmake --build build --config Release

# Check for Apple Silicon compatibility
uname -m
# Expected: arm64 (for M4 Pro)
```

### Issue 3: Port 5000 Already in Use

```bash
# Check what's using port 5000
lsof -i :5000

# Stop the conflicting service or use different port
export SERVER_PORT=5001
./scripts/mac/run-local.sh start
```

### Issue 4: Permission Errors

```bash
# Fix script permissions
chmod +x scripts/mac/*.sh

# Fix directory permissions (if needed)
sudo chown -R $(whoami) .
```

### Issue 5: Memory Issues During Build

```bash
# Check available memory
memory_pressure

# Close other applications if memory is low
# The build process requires ~2-4GB of RAM
```

---

## Verification Checklist

- [ ] Repository cloned successfully
- [ ] On tech-architecture branch
- [ ] Python virtual environment created and activated
- [ ] Dependencies installed (Flask, Flask-CORS)
- [ ] llama.cpp built successfully
- [ ] Integration tests pass
- [ ] Development server starts
- [ ] Web interface accessible at http://localhost:5000
- [ ] Demo interface works at http://localhost:5000/demo.html

---

## Performance Notes for M4 Pro

### Expected Performance
- **Build Time**: 5-8 minutes for llama.cpp
- **Memory Usage**: 2-4GB during build, 1-2GB runtime
- **CPU Usage**: Moderate during build, low during runtime
- **Storage**: ~5GB total for project and dependencies

### Optimization Tips
- Use all CPU cores during build: `-j$(sysctl -n hw.ncpu)`
- Close unnecessary applications during setup
- Use SSD storage for faster builds
- Consider external display for monitoring multiple terminals

---

## Next Steps After Setup

1. **Explore the Interface**: Open http://localhost:5000 in your browser
2. **Run Integration Tests**: `./scripts/mac/test-integration.sh run`
3. **Try Demo Mode**: `./scripts/mac/deploy-demo.sh` then `./demo-assets/run-demo.sh`
4. **Review Documentation**: Read README.md for detailed feature explanations
5. **Test AWS Deployment**: If AWS credentials available, try `./scripts/mac/deploy-aws.sh plan`

---

## Support and Documentation

- **Project README**: Comprehensive documentation in README.md
- **Setup Scripts**: All scripts in scripts/mac/ directory
- **Team Documentation**: SPRINT2_TEAM_CONTRIBUTIONS.md
- **Deployment Evidence**: DEPLOYMENT_EVIDENCE.md

For issues during setup, check the troubleshooting section above or refer to the detailed documentation in README.md.

**Setup Time Estimate**: 15-25 minutes on M4 Pro
**Success Rate**: Tested and verified on multiple macOS systems
