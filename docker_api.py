"""Z-Image FastAPI Server for Docker."""

import os
import io
import time
import warnings
from typing import Optional

warnings.filterwarnings("ignore")

import torch
from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.responses import StreamingResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image

# Import Z-Image utilities
import sys
sys.path.append('/app/src')
from utils import AttentionBackend, ensure_model_weights, load_from_local_dir, set_attention_backend
from zimage import generate

app = FastAPI(
    title="Z-Image API",
    description="Text-to-Image generation API powered by Z-Image-Turbo",
    version="1.0.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global model components (loaded once)
model_components = None
device = None
dtype = torch.bfloat16

def initialize_model():
    """Initialize the Z-Image model (called once at startup)."""
    global model_components, device
    
    print("🚀 Initializing Z-Image model...")
    
    # Device selection
    if torch.cuda.is_available():
        device = "cuda"
        print("✓ Using CUDA GPU")
    elif torch.backends.mps.is_available():
        device = "mps"
        print("✓ Using Apple Silicon (MPS)")
    else:
        device = "cpu"
        print("⚠️  Using CPU (will be slow!)")
    
    # Load model
    model_name = os.environ.get("MODEL_NAME", "Tongyi-MAI/Z-Image-Turbo")
    model_path = ensure_model_weights(f"ckpts/{model_name.split('/')[-1]}", verify=False)
    
    print(f"📥 Loading model from {model_path}...")
    model_components = load_from_local_dir(
        model_path,
        device=device,
        dtype=dtype,
        compile=False
    )
    
    # Set attention backend
    attn_backend = os.environ.get("ZIMAGE_ATTENTION", "_native_flash")
    AttentionBackend.print_available_backends()
    set_attention_backend(attn_backend)
    print(f"✓ Attention backend: {attn_backend}")
    
    print("✅ Model loaded successfully!")

@app.on_event("startup")
async def startup_event():
    """Initialize model on startup."""
    initialize_model()

@app.get("/health")
async def health_check():
    """Health check endpoint."""
    if model_components is None:
        raise HTTPException(status_code=503, detail="Model not loaded yet")
    return {"status": "healthy", "device": str(device), "model": "Z-Image-Turbo"}

@app.get("/info")
async def get_info():
    """Get model information."""
    return {
        "model": "Z-Image-Turbo",
        "description": "6B parameter text-to-image model with 8-step generation",
        "capabilities": [
            "Photorealistic image generation",
            "Bilingual text rendering (EN/CN)",
            "Creative stylistic generation",
            "Fast inference (sub-second on H800)"
        ],
        "device": str(device) if device else "not loaded",
        "default_resolution": "1024x1024",
        "default_steps": 8,
        "guidance_scale": 0.0
    }

@app.post("/generate")
async def generate_image(
    prompt: str = Form(..., description="Text prompt for image generation"),
    negative_prompt: Optional[str] = Form(None, description="Negative prompt (what to avoid)"),
    width: int = Form(1024, description="Image width (512-2048)"),
    height: int = Form(1024, description="Image height (512-2048)"),
    num_inference_steps: int = Form(8, description="Number of inference steps (4-50)"),
    guidance_scale: float = Form(0.0, description="Guidance scale (0.0 for Turbo)"),
    seed: Optional[int] = Form(None, description="Random seed for reproducibility"),
):
    """Generate an image from a text prompt."""
    
    if model_components is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    # Validate parameters
    if not prompt or len(prompt) < 3:
        raise HTTPException(status_code=400, detail="Prompt must be at least 3 characters")
    
    if not (512 <= width <= 2048) or not (512 <= height <= 2048):
        raise HTTPException(status_code=400, detail="Width and height must be between 512 and 2048")
    
    if not (1 <= num_inference_steps <= 50):
        raise HTTPException(status_code=400, detail="Steps must be between 1 and 50")
    
    try:
        print(f"📸 Generating image: '{prompt[:50]}...'")
        start_time = time.time()
        
        # Generate
        generator = torch.Generator(device).manual_seed(seed if seed is not None else int(time.time()))
        
        images = generate(
            prompt=prompt,
            negative_prompt=negative_prompt,
            **model_components,
            height=height,
            width=width,
            num_inference_steps=num_inference_steps,
            guidance_scale=guidance_scale,
            generator=generator,
        )
        
        end_time = time.time()
        generation_time = end_time - start_time
        
        print(f"✓ Generated in {generation_time:.2f}s")
        
        # Convert to bytes
        img_byte_arr = io.BytesIO()
        images[0].save(img_byte_arr, format='PNG')
        img_byte_arr.seek(0)
        
        return StreamingResponse(
            img_byte_arr,
            media_type="image/png",
            headers={
                "X-Generation-Time": str(generation_time),
                "X-Image-Width": str(width),
                "X-Image-Height": str(height),
                "X-Inference-Steps": str(num_inference_steps)
            }
        )
        
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Generation failed: {str(e)}")

@app.post("/generate-batch")
async def generate_batch(
    prompts: list[str] = Form(..., description="List of text prompts"),
    width: int = Form(1024),
    height: int = Form(1024),
    num_inference_steps: int = Form(8),
    seed: Optional[int] = Form(None),
):
    """Generate multiple images from multiple prompts."""
    
    if model_components is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    if not prompts or len(prompts) == 0:
        raise HTTPException(status_code=400, detail="At least one prompt required")
    
    if len(prompts) > 10:
        raise HTTPException(status_code=400, detail="Maximum 10 prompts per batch")
    
    try:
        results = []
        for idx, prompt in enumerate(prompts):
            print(f"📸 [{idx+1}/{len(prompts)}] Generating: '{prompt[:30]}...'")
            
            generator = torch.Generator(device).manual_seed(
                (seed if seed is not None else int(time.time())) + idx
            )
            
            images = generate(
                prompt=prompt,
                **model_components,
                height=height,
                width=width,
                num_inference_steps=num_inference_steps,
                guidance_scale=0.0,
                generator=generator,
            )
            
            # Convert to base64
            import base64
            img_byte_arr = io.BytesIO()
            images[0].save(img_byte_arr, format='PNG')
            img_byte_arr.seek(0)
            img_b64 = base64.b64encode(img_byte_arr.read()).decode()
            
            results.append({
                "prompt": prompt,
                "image": f"data:image/png;base64,{img_b64}"
            })
        
        return JSONResponse({"results": results})
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Batch generation failed: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8002))
    uvicorn.run(app, host="0.0.0.0", port=port)
