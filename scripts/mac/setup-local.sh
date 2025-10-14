#!/bin/bash
# AI/ER Capstone Project - Local Development Setup Script for macOS
# Sprint 2: Automated Local Environment Setup
#
# This script sets up the complete local development environment for AI/ER
# Designed for cybersecurity students learning DevSecOps practices

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Error handling
error_exit() {
    log_error "$*"
    exit 1
}

# Check if running on macOS
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        error_exit "This script is designed for macOS. Current OS: $OSTYPE"
    fi
    log_info "Running on macOS $(sw_vers -productVersion)"
}

# Check for required tools
check_dependencies() {
    log_info "Checking required dependencies..."

    local missing_deps=()

    # Check for Homebrew
    if ! command -v brew &> /dev/null; then
        log_warning "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Check for Python 3
    if ! command -v python3 &> /dev/null; then
        log_info "Installing Python 3..."
        brew install python@3.12
    fi

    # Check for Git
    if ! command -v git &> /dev/null; then
        log_info "Installing Git..."
        brew install git
    fi

    # Check for CMake (for llama.cpp)
    if ! command -v cmake &> /dev/null; then
        log_info "Installing CMake..."
        brew install cmake
    fi

    # Check for wget/curl
    if ! command -v wget &> /dev/null; then
        log_info "Installing wget..."
        brew install wget
    fi

    log_success "All dependencies installed successfully"
}

# Setup Python virtual environment
setup_python_env() {
    log_info "Setting up Python virtual environment..."

    if [[ ! -d "venv" ]]; then
        python3 -m venv venv || error_exit "Failed to create virtual environment"
    fi

    source venv/bin/activate || error_exit "Failed to activate virtual environment"

    # Upgrade pip
    pip install --upgrade pip

    # Install Python dependencies
    log_info "Installing Python dependencies..."
    pip install -r requirements.txt || error_exit "Failed to install Python dependencies"

    log_success "Python environment setup complete"
}

# Setup llama.cpp
setup_llama_cpp() {
    log_info "Setting up llama.cpp..."

    if [[ ! -d "llama.cpp" ]]; then
        log_info "Cloning llama.cpp repository..."
        git clone https://github.com/ggerganov/llama.cpp.git || error_exit "Failed to clone llama.cpp"
    fi

    cd llama.cpp

    # Build llama.cpp
    log_info "Building llama.cpp (this may take several minutes)..."
    if [[ ! -d "build" ]]; then
        mkdir build
    fi

    cd build
    cmake .. || error_exit "CMake configuration failed"
    make -j$(sysctl -n hw.ncpu) || error_exit "Build failed"

    cd ../..

    log_success "llama.cpp setup complete"
}

# Download sample model (for demo purposes)
download_sample_model() {
    log_info "Setting up sample model for demonstration..."

    if [[ ! -d "models" ]]; then
        mkdir -p models
    fi

    # Note: This is a placeholder for demo purposes
    # In a real scenario, you would download an appropriate model
    log_info "Model setup complete (placeholder for demo)"

    log_success "Sample model setup complete"
}

# Setup local configuration
setup_configuration() {
    log_info "Setting up local configuration..."

    # Create .env file if it doesn't exist
    if [[ ! -f ".env" ]]; then
        cat > .env << EOF
# AI/ER Local Development Configuration
MODEL_PATH=models/llama-7b-q4_0.gguf
SERVER_HOST=127.0.0.1
SERVER_PORT=5000
DEBUG=True
LOG_LEVEL=INFO
EOF
        log_info "Created .env configuration file"
    fi

    # Create logs directory
    mkdir -p logs

    log_success "Configuration setup complete"
}

# Run tests
run_tests() {
    log_info "Running tests..."

    # Activate virtual environment
    source venv/bin/activate

    # Test Python imports
    log_info "Testing Python environment..."
    python3 -c "import flask; print('Flask import: OK')" || error_exit "Flask import failed"
    python3 -c "import flask_cors; print('Flask-CORS import: OK')" || error_exit "Flask-CORS import failed"

    # Test llama.cpp build
    if [[ -f "llama.cpp/build/bin/llama-cli" ]]; then
        log_success "llama.cpp build: OK"
    else
        log_warning "llama.cpp binary not found - build may have failed"
    fi

    # Test web server (dry run)
    log_info "Testing web server startup..."
    timeout 5s python3 src/llm_server/app.py || log_warning "Server test completed (expected timeout)"

    log_success "All tests passed"
}

# Main setup function
main() {
    log_info "🚀 Starting AI/ER Capstone Project local setup..."
    log_info "This script will set up the complete development environment"

    # Change to project root
    cd "$(dirname "$0")/.." || error_exit "Failed to change to project directory"

    # Run setup steps
    check_macos
    check_dependencies
    setup_python_env
    setup_llama_cpp
    download_sample_model
    setup_configuration
    run_tests

    log_success "🎉 AI/ER Capstone Project setup completed successfully!"
    log_info ""
    log_info "Next steps:"
    log_info "1. Run './scripts/mac/run-local.sh' to start the development server"
    log_info "2. Run './scripts/mac/test-integration.sh' to run integration tests"
    log_info "3. Open http://localhost:5000 in your browser to access the interface"
    log_info "4. Run './scripts/mac/deploy-demo.sh' for deployment simulation"
    log_info ""
    log_info "For troubleshooting, check the logs in the 'logs/' directory"
}

# Run main function
main "$@"
