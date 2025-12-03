# Zero-Trust Hybrid AI Pipeline - Orchestrator Dockerfile
# ======================================================

FROM python:3.11-slim

LABEL maintainer="Zero-Trust Hybrid AI Pipeline"
LABEL description="Intelligent routing service for distributed AI inference"

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first (for better caching)
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Download spacy model for Presidio
RUN python -m spacy download en_core_web_sm

# Copy application code
COPY main.py .
COPY sensitive_routing.py .

# Create non-root user for security
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# Environment variables
ENV PYTHONUNBUFFERED=1
ENV HOST=0.0.0.0
ENV PORT=8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Expose port
EXPOSE 8000

# Run the orchestrator
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
