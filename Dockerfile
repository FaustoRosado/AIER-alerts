# AI/ER Capstone Project - Dockerfile
# Sprint 2: Containerized Deployment for Demonstration
#
# This Dockerfile creates a containerized version of the AI/ER system
# that can be easily deployed and demonstrated without local setup

FROM python:3.11-slim

# Metadata
LABEL maintainer="AI/ER Capstone Team"
LABEL version="2.0.0-sprint2"
LABEL description="Local LLM Emergency Response System for Cybersecurity Education"

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV FLASK_APP=src/llm_server/app.py
ENV FLASK_ENV=production
ENV PORT=5000

# Create application user for security
RUN groupadd -r aier && useradd -r -g aier aier

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better Docker layer caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY src/ ./src/
COPY scripts/ ./scripts/
COPY demo.html ./
COPY demo-assets/ ./demo-assets/

# Create necessary directories
RUN mkdir -p logs models llama.cpp

# Clone and build llama.cpp (for demo purposes)
RUN git clone https://github.com/ggerganov/llama.cpp.git && \
    cd llama.cpp && \
    cmake -B build && \
    cmake --build build --config Release -j$(nproc) && \
    cd .. && \
    chown -R aier:aier /app

# Create demo model placeholder
RUN echo "Demo model placeholder - replace with real model for production" > models/README.md

# Create startup script
RUN echo '#!/bin/bash\n\
# AI/ER Container Startup Script\n\
echo "🚀 Starting AI/ER Container..."\n\
echo "📊 Container Info:"\n\
echo "  - Hostname: $(hostname)"\n\
echo "  - User: $(whoami)"\n\
echo "  - Python: $(python3 --version)"\n\
echo "  - Flask: $(python3 -c \"import flask; print(flask.__version__)\")"\n\
echo ""\n\
echo "🌐 Access points:"\n\
echo "  - Web Interface: http://localhost:5000"\n\
echo "  - Health Check: http://localhost:5000/health"\n\
echo "  - Demo Interface: http://localhost:5000/demo.html"\n\
echo ""\n\
echo "🔧 Features available:"\n\
echo "  - Local LLM integration (when model available)"\n\
echo "  - Interactive demo interface"\n\
echo "  - Security-first architecture"\n\
echo "  - Comprehensive logging"\n\
echo ""\n\
# Start Flask application\n\
cd /app\n\
exec python3 src/llm_server/app.py' > /app/start.sh && \
chmod +x /app/start.sh

# Create health check script
RUN echo '#!/bin/bash\n\
# Health check for AI/ER container\n\
curl -s --max-time 5 http://localhost:5000/health || exit 1\n\
echo "Container is healthy"' > /app/healthcheck.sh && \
chmod +x /app/healthcheck.sh

# Switch to non-root user for security
USER aier

# Expose port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /app/healthcheck.sh

# Start command
CMD ["/app/start.sh"]
