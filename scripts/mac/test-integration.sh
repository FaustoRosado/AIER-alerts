#!/bin/bash
# AI/ER Capstone Project - Integration Testing Script for macOS
# Sprint 2: Automated Testing Suite
#
# This script runs comprehensive tests for the AI/ER system
# Demonstrates testing practices for cybersecurity applications

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
TEST_RESULTS="logs/test-results.log"
SERVER_PID=""
TEST_START_TIME=""
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

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

# Test result functions
test_start() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    TEST_START_TIME=$(date +%s)
    echo -e "\n${BLUE}[TEST]${NC} Running: $*"
}

test_pass() {
    PASSED_TESTS=$((PASSED_TESTS + 1))
    local duration=$(( $(date +%s) - TEST_START_TIME ))
    echo -e "${GREEN}[PASS]${NC} $* (Duration: ${duration}s)"
}

test_fail() {
    FAILED_TESTS=$((FAILED_TESTS + 1))
    local duration=$(( $(date +%s) - TEST_START_TIME ))
    echo -e "${RED}[FAIL]${NC} $* (Duration: ${duration}s)"
    echo "  Expected: $2"
    echo "  Actual: $3"
}

# Setup test environment
setup_test_env() {
    log_info "Setting up test environment..."

    # Create test directories
    mkdir -p logs test-results

    # Clean previous test results
    > "$TEST_RESULTS"

    # Activate virtual environment if it exists
    if [[ -d "venv" ]]; then
        source venv/bin/activate
    fi

    log_success "Test environment setup complete"
}

# Cleanup test environment
cleanup_test_env() {
    log_info "Cleaning up test environment..."

    # Stop any running servers
    if [[ -n "$SERVER_PID" ]]; then
        kill -TERM "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
    fi

    log_success "Test environment cleanup complete"
}

# Test 1: Environment Setup
test_environment_setup() {
    test_start "Environment Setup"

    # Check if required files exist
    local required_files=("src/llm_server/app.py" "requirements.txt" ".env")
    local all_exist=true

    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            test_fail "Environment Setup" "File $file exists" "File $file missing"
            all_exist=false
        fi
    done

    if [[ "$all_exist" == "true" ]]; then
        test_pass "Environment Setup"
        return 0
    fi

    return 1
}

# Test 2: Python Dependencies
test_python_dependencies() {
    test_start "Python Dependencies"

    # Test Flask import
    if python3 -c "import flask; print('Flask version:', flask.__version__)" >> "$TEST_RESULTS" 2>&1; then
        test_pass "Python Dependencies"
        return 0
    else
        test_fail "Python Dependencies" "Flask imports successfully" "Flask import failed"
        return 1
    fi
}

# Test 3: Llama.cpp Build
test_llama_cpp_build() {
    test_start "Llama.cpp Build"

    if [[ -f "llama.cpp/build/bin/llama-cli" ]]; then
        # Test if binary is executable
        if [[ -x "llama.cpp/build/bin/llama-cli" ]]; then
            test_pass "Llama.cpp Build"
            return 0
        else
            test_fail "Llama.cpp Build" "llama-cli is executable" "llama-cli is not executable"
            return 1
        fi
    else
        test_fail "Llama.cpp Build" "llama-cli binary exists" "llama-cli binary not found"
        return 1
    fi
}

# Test 4: Web Server Startup
test_web_server_startup() {
    test_start "Web Server Startup"

    # Start server in background for testing
    python3 src/llm_server/app.py &
    SERVER_PID=$!

    # Wait for server to start
    for i in {1..10}; do
        if curl -s --max-time 2 http://localhost:5000/ > /dev/null 2>&1; then
            test_pass "Web Server Startup"
            return 0
        fi
        sleep 1
    done

    test_fail "Web Server Startup" "Server starts within 10 seconds" "Server failed to start"
    return 1
}

# Test 5: API Health Check
test_api_health_check() {
    test_start "API Health Check"

    local response
    response=$(curl -s --max-time 5 http://localhost:5000/health 2>/dev/null)

    if [[ $? -eq 0 && -n "$response" ]]; then
        # Parse JSON response
        local status
        status=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin).get('status', 'unknown'))" 2>/dev/null)

        if [[ "$status" == "healthy" ]]; then
            test_pass "API Health Check"
            return 0
        else
            test_fail "API Health Check" "Status is 'healthy'" "Status is '$status'"
            return 1
        fi
    else
        test_fail "API Health Check" "Health endpoint responds" "Health endpoint failed"
        return 1
    fi
}

# Test 6: API Generate Endpoint
test_api_generate_endpoint() {
    test_start "API Generate Endpoint"

    local payload='{"prompt": "Test prompt for cybersecurity", "context": "test context"}'
    local response
    response=$(curl -s --max-time 10 \
        -X POST \
        -H "Content-Type: application/json" \
        -d "$payload" \
        http://localhost:5000/api/generate 2>/dev/null)

    if [[ $? -eq 0 && -n "$response" ]]; then
        # Check if response contains expected fields
        local success
        success=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin).get('success', False))" 2>/dev/null)

        if [[ "$success" == "true" ]]; then
            test_pass "API Generate Endpoint"
            return 0
        else
            test_fail "API Generate Endpoint" "Success is true" "Success is false"
            return 1
        fi
    else
        test_fail "API Generate Endpoint" "Generate endpoint responds" "Generate endpoint failed"
        return 1
    fi
}

# Test 7: Input Validation
test_input_validation() {
    test_start "Input Validation"

    # Test with empty prompt
    local response
    response=$(curl -s --max-time 5 \
        -X POST \
        -H "Content-Type: application/json" \
        -d '{"prompt": ""}' \
        http://localhost:5000/api/generate 2>/dev/null)

    if [[ $? -eq 0 ]]; then
        local success
        success=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin).get('success', True))" 2>/dev/null)

        if [[ "$success" == "false" ]]; then
            test_pass "Input Validation"
            return 0
        else
            test_fail "Input Validation" "Empty prompt rejected" "Empty prompt accepted"
            return 1
        fi
    else
        test_fail "Input Validation" "Validation endpoint responds" "Validation endpoint failed"
        return 1
    fi
}

# Test 8: Security Headers
test_security_headers() {
    test_start "Security Headers"

    local headers
    headers=$(curl -s --max-time 5 \
        -I \
        http://localhost:5000/ 2>/dev/null | grep -E "(X-Content-Type-Options|X-Frame-Options|X-XSS-Protection)" || echo "")

    if [[ -n "$headers" ]]; then
        test_pass "Security Headers"
        return 0
    else
        test_fail "Security Headers" "Security headers present" "Security headers missing"
        return 1
    fi
}

# Test 9: Static File Serving
test_static_file_serving() {
    test_start "Static File Serving"

    # Test if CSS file is served
    if curl -s --max-time 5 http://localhost:5000/static/css/styles.css > /dev/null 2>&1; then
        test_pass "Static File Serving"
        return 0
    else
        test_fail "Static File Serving" "CSS file served" "CSS file not accessible"
        return 1
    fi
}

# Test 10: Frontend Interface
test_frontend_interface() {
    test_start "Frontend Interface"

    # Test if main page loads
    local response
    response=$(curl -s --max-time 5 http://localhost:5000/ 2>/dev/null)

    if [[ $? -eq 0 && -n "$response" ]]; then
        # Check for key HTML elements
        if echo "$response" | grep -q "AI/ER" && echo "$response" | grep -q "Local LLM"; then
            test_pass "Frontend Interface"
            return 0
        else
            test_fail "Frontend Interface" "Expected content present" "Expected content missing"
            return 1
        fi
    else
        test_fail "Frontend Interface" "Main page loads" "Main page failed to load"
        return 1
    fi
}

# Run all tests
run_all_tests() {
    log_info "🧪 Starting AI/ER Integration Test Suite"
    log_info "This test suite validates the complete system functionality"

    # Setup
    setup_test_env

    # Run individual tests
    test_environment_setup
    test_python_dependencies
    test_llama_cpp_build
    test_web_server_startup
    test_api_health_check
    test_api_generate_endpoint
    test_input_validation
    test_security_headers
    test_static_file_serving
    test_frontend_interface

    # Cleanup
    cleanup_test_env

    # Show results
    show_test_results
}

# Show test results
show_test_results() {
    log_info ""
    log_info "📊 Test Results Summary"
    log_info "═══════════════════════════════════════"

    echo -e "Total Tests:  $TOTAL_TESTS"
    echo -e "Passed:       ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Failed:       ${RED}$FAILED_TESTS${NC}"

    if [[ $FAILED_TESTS -eq 0 ]]; then
        log_success "🎉 All tests passed! System is ready for use."
        return 0
    else
        log_error "❌ $FAILED_TESTS test(s) failed. Please check the logs."
        log_info "Log file: $TEST_RESULTS"
        return 1
    fi
}

# Main function
main() {
    local action="${1:-run}"

    case "$action" in
        "run")
            run_all_tests
            ;;
        "setup")
            setup_test_env
            ;;
        "cleanup")
            cleanup_test_env
            ;;
        "health")
            if [[ -n "$SERVER_PID" ]]; then
                health_check
            else
                log_error "No server PID found"
                exit 1
            fi
            ;;
        *)
            echo "Usage: $0 {run|setup|cleanup|health}"
            echo ""
            echo "Commands:"
            echo "  run     - Run all integration tests"
            echo "  setup   - Setup test environment only"
            echo "  cleanup - Cleanup test environment only"
            echo "  health  - Check server health"
            echo ""
            echo "Examples:"
            echo "  $0 run      # Run complete test suite"
            echo "  $0 health   # Check if server is healthy"
            exit 1
            ;;
    esac
}

# Trap for cleanup on script exit
trap cleanup_test_env EXIT

# Run main function
main "$@"
