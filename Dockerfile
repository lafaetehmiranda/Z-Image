# =============================================================================
# Z-Image Docker Image - Text-to-Image Generation
# =============================================================================
# Model: Z-Image-Turbo (6B parameters, 8 steps, sub-second on H800)
# Capabilities: Photorealistic images, bilingual text (EN/CN), creative generation
# =============================================================================

FROM python:3.10-slim

ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1000 zimage && \
    mkdir -p /app /models /cache && \
    chown -R zimage:zimage /app /models /cache

WORKDIR /app

# Upgrade pip
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# Copy project files
COPY --chown=zimage:zimage pyproject.toml .
COPY --chown=zimage:zimage src/ ./src/
COPY --chown=zimage:zimage inference.py .
COPY --chown=zimage:zimage batch_inference.py .

# Install FastAPI and core dependencies first (no model download yet)
RUN pip install --no-cache-dir \
    fastapi==0.115.6 \
    uvicorn[standard]==0.34.0 \
    python-multipart==0.0.20 \
    torch>=2.5.0 \
    transformers>=4.51.0 \
    safetensors \
    loguru \
    pillow \
    accelerate \
    huggingface_hub>=0.25.0

# Copy API server
COPY --chown=zimage:zimage docker_api.py .

# Environment variables
ENV MODEL_NAME=Tongyi-MAI/Z-Image-Turbo
ENV CACHE_DIR=/cache
ENV HF_HOME=/cache
ENV TORCH_HOME=/cache
ENV ZIMAGE_ATTENTION=_native_flash

# Switch to non-root user
USER zimage

# Expose port
EXPOSE 8002

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:8002/health || exit 1

# Run the API server
CMD ["python3", "docker_api.py"]
