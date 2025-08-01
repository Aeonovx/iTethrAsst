# Use Python 3.11 slim as base image
FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DEBIAN_FRONTEND=noninteractive \
    PIP_DEFAULT_TIMEOUT=100 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    TZ=UTC

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    ca-certificates \
    tzdata \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Ollama
RUN curl -fsSL https://ollama.ai/install.sh | sh

# Create necessary directories
RUN mkdir -p \
    ./documents \
    ./knowledge_base \
    ./logs \
    ./data

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python packages with optimizations
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r requirements.txt \
    --extra-index-url https://download.pytorch.org/whl/cpu

# Copy application files
COPY . .

# Make scripts executable
RUN chmod +x start.sh

# Set proper permissions
RUN chown -R nobody:nogroup /app && \
    chmod -R 755 /app

# Health check with proper timing
HEALTHCHECK --interval=30s --timeout=15s --start-period=180s --retries=5 \
    CMD curl -f http://localhost:${PORT:-7860}/health || exit 1

# Expose necessary ports
EXPOSE 7860 11434

# Set the user to non-root
USER nobody

# Set environment variables for Railway
ENV RAILWAY_ENVIRONMENT=production \
    GRADIO_SHARE=false \
    DEBUG=false \
    PORT=7860

# Start the application
CMD ["/bin/sh", "./start.sh"]