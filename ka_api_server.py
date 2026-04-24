"""
Knowledge Assistant API Server with OpenAI-compatible endpoints.

This FastAPI server integrates Knowledge Assistant with llama.cpp and pgvector,
providing OpenAI-compatible API endpoints for use with Open WebUI.
"""

import os
from typing import List, Optional, Dict, Any
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field
import httpx
import json


# Configuration from environment variables
LLAMACPP_BASE_URL = os.getenv("LLAMACPP_BASE_URL", "http://localhost:8080")
LLAMACPP_EMBED_URL = os.getenv("LLAMACPP_EMBED_URL", os.getenv("LLAMACPP_BASE_URL", "http://localhost:8080"))
DEFAULT_MODEL = os.getenv("DEFAULT_MODEL", "gemma-4-26B-A4B-it-Q4_K_M")
DEFAULT_EMBED_MODEL = os.getenv("DEFAULT_EMBED_MODEL", "embeddinggemma-300M-qat-Q4_0")


# Pydantic models for OpenAI-compatible API
class Message(BaseModel):
    role: str
    content: str


class ChatCompletionRequest(BaseModel):
    model: str
    messages: List[Message]
    temperature: Optional[float] = 0.7
    max_tokens: Optional[int] = None
    stream: Optional[bool] = False


class ChatCompletionChoice(BaseModel):
    index: int
    message: Message
    finish_reason: str


class ChatCompletionResponse(BaseModel):
    id: str
    object: str = "chat.completion"
    created: int
    model: str
    choices: List[ChatCompletionChoice]
    usage: Optional[Dict[str, int]] = None


class EmbeddingRequest(BaseModel):
    model: str
    input: str | List[str]


class EmbeddingData(BaseModel):
    object: str = "embedding"
    embedding: List[float]
    index: int


class EmbeddingResponse(BaseModel):
    object: str = "list"
    data: List[EmbeddingData]
    model: str
    usage: Optional[Dict[str, int]] = None


class ModelInfo(BaseModel):
    id: str
    object: str = "model"
    created: int = 0
    owned_by: str = "knowledge-assistant"


class ModelsResponse(BaseModel):
    object: str = "list"
    data: List[ModelInfo]


# Global HTTP client
http_client: Optional[httpx.AsyncClient] = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initialize and cleanup resources."""
    global http_client
    
    # Startup
    print(f"Initializing llama.cpp client at {LLAMACPP_BASE_URL}")
    print(f"Initializing llama.cpp embeddings client at {LLAMACPP_EMBED_URL}")
    http_client = httpx.AsyncClient(timeout=300.0)
    print("Knowledge Assistant API Server started successfully!")
    
    yield
    
    # Shutdown
    print("Shutting down Knowledge Assistant API Server...")
    if http_client:
        await http_client.aclose()


# Create FastAPI app
app = FastAPI(
    title="Knowledge Assistant API",
    description="OpenAI-compatible API for Knowledge Assistant with llama.cpp",
    version="0.1.0",
    lifespan=lifespan
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    """Root endpoint."""
    return {
        "message": "Knowledge Assistant API Server",
        "docs": "/docs",
        "openapi": "/openapi.json"
    }


@app.get("/health")
async def health():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "llamacpp_url": LLAMACPP_BASE_URL,
        "llamacpp_embed_url": LLAMACPP_EMBED_URL
    }


@app.get("/v1/models", response_model=ModelsResponse)
async def list_models():
    """List available models (OpenAI-compatible)."""
    import time
    
    if not http_client:
        raise HTTPException(status_code=500, detail="HTTP client not initialized")
    
    try:
        # Get models from llama.cpp (OpenAI-compatible endpoint)
        response = await http_client.get(f"{LLAMACPP_BASE_URL}/v1/models")
        response.raise_for_status()
        models_data = response.json()
        
        # llama.cpp returns OpenAI-compatible format
        if "data" in models_data:
            return ModelsResponse(data=[
                ModelInfo(id=model["id"], created=model.get("created", int(time.time())))
                for model in models_data["data"]
            ])
        
        # Fallback: return default model
        return ModelsResponse(data=[
            ModelInfo(id=DEFAULT_MODEL, created=int(time.time()))
        ])
    
    except Exception as e:
        # If llama.cpp doesn't support /v1/models, return default model
        import time
        return ModelsResponse(data=[
            ModelInfo(id=DEFAULT_MODEL, created=int(time.time()))
        ])


@app.post("/v1/chat/completions")
async def chat_completion(request: ChatCompletionRequest):
    """Chat completion endpoint (OpenAI-compatible)."""
    if not http_client:
        raise HTTPException(status_code=500, detail="HTTP client not initialized")
    
    try:
        # Forward request to llama.cpp's OpenAI-compatible endpoint
        payload = {
            "model": request.model,
            "messages": [{"role": msg.role, "content": msg.content} for msg in request.messages],
            "temperature": request.temperature,
            "stream": request.stream
        }
        
        if request.max_tokens:
            payload["max_tokens"] = request.max_tokens
        
        # Generate response
        if request.stream:
            # Streaming response
            async def generate_stream():
                async with http_client.stream(
                    "POST",
                    f"{LLAMACPP_BASE_URL}/v1/chat/completions",
                    json=payload,
                    timeout=None
                ) as response:
                    response.raise_for_status()
                    async for line in response.aiter_lines():
                        if line.strip():
                            yield f"{line}\n"
            
            return StreamingResponse(
                generate_stream(),
                media_type="text/event-stream"
            )
        else:
            response = await http_client.post(
                f"{LLAMACPP_BASE_URL}/v1/chat/completions",
                json=payload
            )
            response.raise_for_status()
            
            # Return the response from llama.cpp (already in OpenAI format)
            return response.json()
    
    except httpx.HTTPStatusError as e:
        raise HTTPException(status_code=e.response.status_code, detail=f"Chat completion failed: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Chat completion failed: {str(e)}")


@app.post("/v1/embeddings", response_model=EmbeddingResponse)
async def create_embeddings(request: EmbeddingRequest):
    """Create embeddings (OpenAI-compatible)."""
    if not http_client:
        raise HTTPException(status_code=500, detail="HTTP client not initialized")
    
    try:
        # Forward request to llama.cpp embeddings server
        payload = {
            "model": request.model,
            "input": request.input
        }
        
        # Use the dedicated embeddings endpoint
        response = await http_client.post(
            f"{LLAMACPP_EMBED_URL}/v1/embeddings",
            json=payload
        )
        response.raise_for_status()
        
        # Return the response from llama.cpp (already in OpenAI format)
        return response.json()
    
    except httpx.HTTPStatusError as e:
        raise HTTPException(status_code=e.response.status_code, detail=f"Embedding creation failed: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Embedding creation failed: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    
    port = int(os.getenv("PORT", "8000"))
    host = os.getenv("HOST", "0.0.0.0")
    
    print(f"Starting Knowledge Assistant API Server on {host}:{port}")
    print(f"llama.cpp URL: {LLAMACPP_BASE_URL}")
    print(f"llama.cpp Embeddings URL: {LLAMACPP_EMBED_URL}")
    print(f"Default Model: {DEFAULT_MODEL}")
    print(f"Default Embed Model: {DEFAULT_EMBED_MODEL}")
    
    uvicorn.run(app, host=host, port=port)
