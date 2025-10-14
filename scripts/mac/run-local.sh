#!/bin/bash
# AI/ER Capstone Project - Local Development Server Script for macOS
# Sprint 2: Local Development Server Management
#
# This script manages the local development server and provides
# monitoring capabilities for cybersecurity students

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

# Configuration
SERVER_PID=""
LOG_FILE="logs/llm_server.log"
HEALTH_CHECK_URL="http://localhost:5000/health"

# Cleanup function
cleanup() {
    if [[ -n "$SERVER_PID" && -d "/proc/$SERVER_PID" ]]; then
        log_info "Stopping server (PID: $SERVER_PID)..."
        kill -TERM "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
    fi
    exit 0
}

# Trap SIGINT and SIGTERM for graceful shutdown
trap cleanup SIGINT SIGTERM

# Check if server is running
check_server_status() {
    if curl -s --max-time 3 "$HEALTH_CHECK_URL" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Health check function
health_check() {
    if check_server_status; then
        local response
        response=$(curl -s --max-time 5 "$HEALTH_CHECK_URL" 2>/dev/null)
        if [[ $? -eq 0 && -n "$response" ]]; then
            log_success "Server health check: OK"
            echo "Response: $response"
            return 0
        fi
    fi

    log_error "Server health check: FAILED"
    return 1
}

# Monitor server function
monitor_server() {
    log_info "Monitoring server (Press Ctrl+C to stop)..."

    local last_requests=0
    local last_errors=0

    while true; do
        if ! check_server_status; then
            log_error "Server appears to be down!"
            return 1
        fi

        # Get server stats from logs (simplified)
        local current_requests
        current_requests=$(grep -c "API request processed" "$LOG_FILE" 2>/dev/null || echo "0")
        local current_errors
        current_errors=$(grep -c "ERROR" "$LOG_FILE" 2>/dev/null || echo "0")

        if [[ $current_requests -ne $last_requests ]]; then
            log_info "Total requests served: $current_requests"
            last_requests=$current_requests
        fi

        if [[ $current_errors -ne $last_errors ]]; then
            log_warning "Total errors logged: $current_errors"
            last_errors=$current_errors
        fi

        sleep 5
    done
}

# Start development server
start_server() {
    log_info "Starting AI/ER LLM development server..."

    # Check if already running
    if check_server_status; then
        log_warning "Server is already running!"
        health_check
        return 0
    fi

    # Activate virtual environment
    if [[ ! -d "venv" ]]; then
        log_error "Virtual environment not found. Run setup-local.sh first."
        exit 1
    fi

    source venv/bin/activate || error_exit "Failed to activate virtual environment"

    # Create logs directory
    mkdir -p logs

    # Start server in background
    nohup python3 src/llm_server/app.py > "$LOG_FILE" 2>&1 &
    SERVER_PID=$!

    log_info "Server started with PID: $SERVER_PID"
    log_info "Log file: $LOG_FILE"

    # Wait for server to start
    log_info "Waiting for server to start..."
    for i in {1..30}; do
        if check_server_status; then
            log_success "Server started successfully!"
            log_info "Access the interface at: http://localhost:5000"
            log_info ""
            log_info "Server Features:"
            log_info "• Local LLM integration with llama.cpp"
            log_info "• Security-first design with input validation"
            log_info "• Real-time token counting and validation"
            log_info "• Comprehensive logging for audit trails"
            log_info ""
            return 0
        fi
        sleep 1
    done

    log_error "Server failed to start within 30 seconds"
    if [[ -f "$LOG_FILE" ]]; then
        log_info "Last few log entries:"
        tail -10 "$LOG_FILE"
    fi
    return 1
}

# Stop server function
stop_server() {
    log_info "Stopping AI/ER LLM server..."

    if [[ -z "$SERVER_PID" ]]; then
        # Try to find the process
        SERVER_PID=$(pgrep -f "python3 src/llm_server/app.py" || echo "")
    fi

    if [[ -n "$SERVER_PID" ]]; then
        log_info "Stopping process PID: $SERVER_PID"
        kill -TERM "$SERVER_PID" 2>/dev/null || true

        # Wait for graceful shutdown
        for i in {1..10}; do
            if ! kill -0 "$SERVER_PID" 2>/dev/null; then
                log_success "Server stopped successfully"
                return 0
            fi
            sleep 1
        done

        # Force kill if necessary
        log_warning "Force killing server..."
        kill -9 "$SERVER_PID" 2>/dev/null || true
        log_success "Server force stopped"
    else
        log_warning "No server process found to stop"
    fi
}

# Show server status
show_status() {
    log_info "AI/ER LLM Server Status:"
    log_info ""

    if check_server_status; then
        log_success "✓ Server Status: RUNNING"
        health_check

        # Show resource usage
        if [[ -n "$SERVER_PID" ]]; then
            log_info "Process Information:"
            ps -p "$SERVER_PID" -o pid,ppid,pcpu,pmem,etime,comm || log_warning "Could not get process info"
        fi

        # Show recent log entries
        if [[ -f "$LOG_FILE" ]]; then
            log_info "Recent Log Entries:"
            tail -5 "$LOG_FILE"
        fi
    else
        log_error "✗ Server Status: STOPPED"

        # Check if log file exists
        if [[ -f "$LOG_FILE" ]]; then
            log_info "Last Log Entries:"
            tail -3 "$LOG_FILE"
        fi
    fi
}

# Main function
main() {
    local action="${1:-start}"

    case "$action" in
        "start")
            start_server
            ;;
        "stop")
            stop_server
            ;;
        "restart")
            stop_server
            sleep 2
            start_server
            ;;
        "status")
            show_status
            ;;
        "monitor")
            start_server
            monitor_server
            ;;
        "health")
            health_check
            ;;
        *)
            echo "Usage: $0 {start|stop|restart|status|monitor|health}"
            echo ""
            echo "Commands:"
            echo "  start   - Start the development server"
            echo "  stop    - Stop the development server"
            echo "  restart - Restart the development server"
            echo "  status  - Show server status and information"
            echo "  monitor - Start server and monitor its operation"
            echo "  health  - Perform health check on running server"
            echo ""
            echo "Examples:"
            echo "  $0 start    # Start development server"
            echo "  $0 status   # Check if server is running"
            echo "  $0 monitor  # Start and monitor server"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
