"""
Z-Image API - Standalone version (no src/ dependency)
Minimal FastAPI server for image generation
"""

from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Optional
import os

app = FastAPI(
    title="Z-Image API",
    description="Text-to-Image Generation using Z-Image-Turbo",
    version="1.0.0"
)

class GenerateRequest(BaseModel):
    prompt: str
    negative_prompt: Optional[str] = ""
    num_inference_steps: Optional[int] = 8
    guidance_scale: Optional[float] = 3.5
    width: Optional[int] = 1024
    height: Optional[int] = 1024
    seed: Optional[int] = None

@app.get("/")
async def root():
    return {
        "service": "Z-Image API",
        "version": "1.0.0",
        "status": "running",
        "model": "Tongyi-MAI/Z-Image-Turbo",
        "endpoints": {
            "health": "/health",
            "info": "/info",
            "generate": "/generate",
            "docs": "/docs"
        }
    }

@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "service": "z-image-api",
        "model_loaded": False,  # Will be True when model is actually loaded
        "note": "This is a minimal API. Full model integration requires torch+transformers"
    }

@app.get("/info")
async def info():
    return {
        "model": {
            "name": "Z-Image-Turbo",
            "repo": "Tongyi-MAI/Z-Image-Turbo",
            "parameters": "6B",
            "architecture": "Diffusion Transformer",
            "capabilities": [
                "Photorealistic image generation",
                "Bilingual text rendering (EN/CN)",
                "Fast inference (8 steps)",
                "1024x1024 resolution"
            ]
        },
        "api": {
            "version": "1.0.0",
            "port": int(os.getenv("PORT", 8002))
        },
        "resources": {
            "model_size": "~12GB",
            "vram_required": "8GB+ (GPU) or 16GB+ RAM (CPU)",
            "recommended": "GPU with 16GB+ VRAM"
        }
    }

@app.post("/generate")
async def generate(request: GenerateRequest):
    """
    Generate image from text prompt
    
    NOTE: This minimal version returns a placeholder response.
    To enable actual generation, install: pip install torch transformers diffusers
    """
    
    # Check if torch is available
    try:
        import torch
        import transformers
        has_deps = True
    except ImportError:
        has_deps = False
    
    if not has_deps:
        raise HTTPException(
            status_code=501,
            detail={
                "error": "Model dependencies not installed",
                "message": "This is a minimal API deployment. Install torch and transformers to enable image generation.",
                "install_command": "pip install torch transformers diffusers safetensors accelerate",
                "docker_alternative": "Use the full Dockerfile instead of Dockerfile.simple"
            }
        )
    
    # If dependencies are available, return generation info
    return {
        "status": "success",
        "message": "Model dependencies found. Actual generation will be implemented here.",
        "request": {
            "prompt": request.prompt,
            "steps": request.num_inference_steps,
            "size": f"{request.width}x{request.height}"
        },
        "note": "Full implementation requires loading the 12GB model"
    }

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8002))
    print(f"""
==============================================
Z-Image API Server Starting...
==============================================
Port: {port}
Docs: http://localhost:{port}/docs
Health: http://localhost:{port}/health
==============================================
    """)
    uvicorn.run(app, host="0.0.0.0", port=port)
