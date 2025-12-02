#!/bin/bash
# ============================================================================
# Zero-Trust Hybrid AI Pipeline - Codespaces Setup Script
# ============================================================================
#
# This script runs automatically when a Codespace is created.
# It sets up the demo environment with minimal resource usage.
#
# ============================================================================

set -e

echo "============================================"
echo "Zero-Trust Hybrid AI Pipeline"
echo "Codespaces Environment Setup"
echo "============================================"
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ============================================================================
# Step 1: Wait for Docker to be ready
# ============================================================================

echo -e "${YELLOW}Step 1: Waiting for Docker...${NC}"
timeout 60 sh -c 'until docker info > /dev/null 2>&1; do sleep 1; done'
echo -e "${GREEN}✓ Docker is ready${NC}"
echo ""

# ============================================================================
# Step 2: Configure environment
# ============================================================================

echo -e "${YELLOW}Step 2: Configuring environment...${NC}"

# Create .env file for Docker Compose
cat > .env << EOF
# Codespaces demo configuration
COMPOSE_PROJECT_NAME=hybrid-ai-demo
AEGIS_URL=http://ollama-cpu:11434
RYZEN_AI_URL=http://ollama-cpu:11434
EOF

echo -e "${GREEN}✓ Environment configured${NC}"
echo ""

# ============================================================================
# Step 3: Start services
# ============================================================================

echo -e "${YELLOW}Step 3: Starting services...${NC}"

cd docker
docker compose --profile demo up -d
cd ..

echo -e "${GREEN}✓ Services started${NC}"
echo ""

# ============================================================================
# Step 4: Wait for Ollama to be ready
# ============================================================================

echo -e "${YELLOW}Step 4: Waiting for Ollama...${NC}"

max_attempts=60
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if curl -s http://localhost:11435/api/tags > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Ollama is ready${NC}"
        break
    fi
    attempt=$((attempt + 1))
    sleep 2
done

if [ $attempt -eq $max_attempts ]; then
    echo "Warning: Ollama may not be fully ready. Continuing anyway..."
fi
echo ""

# ============================================================================
# Step 5: Pull demo models
# ============================================================================

echo -e "${YELLOW}Step 5: Pulling demo models (this may take a few minutes)...${NC}"

# Pull minimal models for demo
docker exec ollama-cpu ollama pull tinyllama 2>/dev/null || true
docker exec ollama-cpu ollama pull nomic-embed-text 2>/dev/null || true

echo -e "${GREEN}✓ Demo models ready${NC}"
echo ""

# ============================================================================
# Step 6: Verify setup
# ============================================================================

echo -e "${YELLOW}Step 6: Verifying setup...${NC}"

# Test orchestrator
if curl -s http://localhost:8000/health | grep -q "healthy"; then
    echo -e "${GREEN}✓ Orchestrator is healthy${NC}"
else
    echo "Warning: Orchestrator health check failed"
fi

# Test Ollama
if curl -s http://localhost:11435/api/tags | grep -q "models"; then
    echo -e "${GREEN}✓ Ollama is responding${NC}"
else
    echo "Warning: Ollama health check failed"
fi

echo ""

# ============================================================================
# Done!
# ============================================================================

echo "============================================"
echo -e "${GREEN}Setup Complete!${NC}"
echo "============================================"
echo ""
echo "Available endpoints:"
echo "  • Orchestrator API: http://localhost:8000"
echo "  • API Docs:         http://localhost:8000/docs"
echo "  • Ollama Direct:    http://localhost:11435"
echo ""
echo "Quick test:"
echo '  curl http://localhost:8000/backends'
echo ""
echo "Send a chat request:"
echo '  curl -X POST http://localhost:8000/v1/chat/completions \'
echo '    -H "Content-Type: application/json" \'
echo '    -d '"'"'{"messages":[{"role":"user","content":"Hello!"}]}'"'"
echo ""
echo "View logs:"
echo '  docker compose -f docker/docker-compose.yml logs -f'
echo ""
echo "============================================"
echo "Ready for the demo! 🚀"
echo "============================================"
