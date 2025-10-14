#!/bin/bash
# AI/ER Capstone Project - Docker Deployment Script for macOS
# Sprint 2: Containerized Deployment for Demonstration
#
# This script handles Docker deployment of the AI/ER system
# Designed for easy demonstration and production deployment

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

# Check Docker installation
check_docker() {
    log_info "Checking Docker installation..."

    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed."
        log_info "Please install Docker Desktop for Mac:"
        log_info "https://docs.docker.com/desktop/mac/install/"
        exit 1
    fi

    if ! docker info &> /dev/null; then
        log_error "Docker is not running. Please start Docker Desktop."
        exit 1
    fi

    log_success "Docker is installed and running"
}

# Build Docker image
build_image() {
    log_info "Building AI/ER Docker image..."

    local image_tag="aier-capstone:latest"

    # Build the image
    docker build -t "$image_tag" . || error_exit "Failed to build Docker image"

    # Verify image was created
    if docker images "$image_tag" | grep -q "$image_tag"; then
        log_success "Docker image built successfully: $image_tag"
    else
        error_exit "Failed to create Docker image"
    fi
}

# Run container
run_container() {
    log_info "Starting AI/ER container..."

    local container_name="aier-capstone-app"
    local image_tag="aier-capstone:latest"

    # Stop and remove existing container if it exists
    if docker ps -a | grep -q "$container_name"; then
        log_info "Removing existing container..."
        docker stop "$container_name" 2>/dev/null || true
        docker rm "$container_name" 2>/dev/null || true
    fi

    # Create necessary directories
    mkdir -p logs models

    # Run the container
    docker run -d \
        --name "$container_name" \
        -p 5000:5000 \
        -v "$(pwd)/logs:/app/logs" \
        -v "$(pwd)/models:/app/models:ro" \
        --restart unless-stopped \
        "$image_tag" || error_exit "Failed to start container"

    log_success "Container started successfully: $container_name"

    # Wait for container to be healthy
    log_info "Waiting for container to be ready..."
    for i in {1..30}; do
        if docker ps | grep -q "$container_name" && \
           curl -s --max-time 5 http://localhost:5000/health > /dev/null 2>&1; then
            log_success "Container is ready!"
            break
        fi
        sleep 2
    done

    if ! curl -s --max-time 5 http://localhost:5000/health > /dev/null 2>&1; then
        log_warning "Container may not be fully ready yet"
    fi
}

# Test deployment
test_deployment() {
    log_info "Testing deployment..."

    # Test health endpoint
    if curl -s --max-time 10 http://localhost:5000/health | grep -q "healthy"; then
        log_success "✓ Health check passed"
    else
        log_error "✗ Health check failed"
        return 1
    fi

    # Test main interface
    if curl -s --max-time 5 http://localhost:5000/ | grep -q "AI/ER"; then
        log_success "✓ Web interface accessible"
    else
        log_error "✗ Web interface not accessible"
        return 1
    fi

    # Test demo interface
    if curl -s --max-time 5 http://localhost:5000/demo.html | grep -q "DEMO MODE"; then
        log_success "✓ Demo interface accessible"
    else
        log_error "✗ Demo interface not accessible"
        return 1
    fi

    log_success "All deployment tests passed!"
}

# Show deployment status
show_status() {
    log_info "AI/ER Docker Deployment Status:"

    local container_name="aier-capstone-app"

    if docker ps | grep -q "$container_name"; then
        log_success "✓ Container Status: RUNNING"

        # Show container info
        docker ps --filter "name=$container_name" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

        # Show logs
        log_info "Recent container logs:"
        docker logs --tail 5 "$container_name"

    else
        log_error "✗ Container Status: STOPPED"

        if docker ps -a | grep -q "$container_name"; then
            log_info "Container exists but is stopped"
            docker ps -a --filter "name=$container_name" --format "table {{.Names}}\t{{.Status}}"
        else
            log_info "Container does not exist"
        fi
    fi

    # Show access information
    log_info ""
    log_info "🌐 Access Information:"
    log_info "  • Web Interface: http://localhost:5000"
    log_info "  • Demo Interface: http://localhost:5000/demo.html"
    log_info "  • Health Check: http://localhost:5000/health"
    log_info ""
    log_info "🐳 Docker Commands:"
    log_info "  • View logs: docker logs -f $container_name"
    log_info "  • Stop container: docker stop $container_name"
    log_info "  • Restart container: docker restart $container_name"
}

# Cleanup deployment
cleanup_deployment() {
    log_info "Cleaning up Docker deployment..."

    local container_name="aier-capstone-app"
    local image_tag="aier-capstone:latest"

    # Stop and remove container
    if docker ps -a | grep -q "$container_name"; then
        log_info "Stopping and removing container..."
        docker stop "$container_name" 2>/dev/null || true
        docker rm "$container_name" 2>/dev/null || true
    fi

    # Remove image (optional)
    if [[ "${1:-}" == "--remove-image" ]]; then
        if docker images | grep -q "$image_tag"; then
            log_info "Removing Docker image..."
            docker rmi "$image_tag" 2>/dev/null || true
        fi
    fi

    log_success "Cleanup completed"
}

# Main deployment function
deploy_docker() {
    log_info "🚀 Starting AI/ER Docker Deployment"

    check_docker
    build_image
    run_container
    test_deployment

    log_success "🎉 Docker deployment completed successfully!"
    log_info ""
    show_status
}

# Main function
main() {
    local action="${1:-deploy}"

    case "$action" in
        "deploy")
            deploy_docker
            ;;
        "build")
            check_docker
            build_image
            ;;
        "run")
            check_docker
            if ! docker images | grep -q "aier-capstone:latest"; then
                build_image
            fi
            run_container
            ;;
        "test")
            test_deployment
            ;;
        "status")
            show_status
            ;;
        "stop")
            cleanup_deployment
            ;;
        "clean")
            cleanup_deployment --remove-image
            ;;
        "logs")
            local container_name="aier-capstone-app"
            if docker ps | grep -q "$container_name"; then
                docker logs -f "$container_name"
            else
                log_error "Container is not running"
                exit 1
            fi
            ;;
        *)
            echo "Usage: $0 {deploy|build|run|test|status|stop|clean|logs}"
            echo ""
            echo "Commands:"
            echo "  deploy  - Build and run complete deployment"
            echo "  build   - Build Docker image only"
            echo "  run     - Run container (builds image if needed)"
            echo "  test    - Test deployment functionality"
            echo "  status  - Show deployment status"
            echo "  stop    - Stop and remove container"
            echo "  clean   - Stop container and remove image"
            echo "  logs    - Show container logs"
            echo ""
            echo "Examples:"
            echo "  $0 deploy   # Complete deployment"
            echo "  $0 status   # Check deployment status"
            echo "  $0 logs     # View container logs"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
