"""
Knowledge Assistant API Server with OpenAI-compatible endpoints.

This FastAPI server integrates Knowledge Assistant with Ollama and pgvector,
providing OpenAI-compatible API endpoints for use with Open WebUI.
"""

import os
from typing import List, Optional, Dict, Any
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from knowledge_assistant.llamaindex.local.models.ollama import OllamaLlmProvider


# Configuration from environment variables
OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
DEFAULT_MODEL = os.getenv("DEFAULT_MODEL", "qwen3:30b")
DEFAULT_EMBED_MODEL = os.getenv("DEFAULT_EMBED_MODEL", "nomic-embed-text-v2-moe")


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


# Global provider instance
llm_provider: Optional[OllamaLlmProvider] = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initialize and cleanup resources."""
    global llm_provider
    
    # Startup
    print(f"Initializing Ollama provider at {OLLAMA_BASE_URL}")
    llm_provider = OllamaLlmProvider(base_url=OLLAMA_BASE_URL, request_timeout=300.0)
    print("Knowledge Assistant API Server started successfully!")
    
    yield
    
    # Shutdown
    print("Shutting down Knowledge Assistant API Server...")


# Create FastAPI app
app = FastAPI(
    title="Knowledge Assistant API",
    description="OpenAI-compatible API for Knowledge Assistant with Ollama",
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
    return {"status": "healthy", "ollama_url": OLLAMA_BASE_URL}


@app.get("/v1/models", response_model=ModelsResponse)
async def list_models():
    """List available models (OpenAI-compatible)."""
    import time
    import httpx
    
    try:
        # Get models from Ollama
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{OLLAMA_BASE_URL}/api/tags")
            response.raise_for_status()
            ollama_models = response.json()
        
        models = [
            ModelInfo(id=model["name"], created=int(time.time()))
            for model in ollama_models.get("models", [])
        ]
        
        return ModelsResponse(data=models)
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list models: {str(e)}")


@app.post("/v1/chat/completions", response_model=ChatCompletionResponse)
async def chat_completion(request: ChatCompletionRequest):
    """Chat completion endpoint (OpenAI-compatible)."""
    import time
    import uuid
    
    if not llm_provider:
        raise HTTPException(status_code=500, detail="LLM provider not initialized")
    
    try:
        # Get the generative model
        llm = llm_provider.get_generative_model(request.model)
        
        # Convert messages to prompt
        prompt = "\n".join([
            f"{msg.role}: {msg.content}" for msg in request.messages
        ])
        
        # Generate response
        if request.stream:
            # TODO: Implement streaming
            raise HTTPException(status_code=501, detail="Streaming not yet implemented")
        else:
            response = llm.complete(prompt)
            
            return ChatCompletionResponse(
                id=f"chatcmpl-{uuid.uuid4().hex[:8]}",
                created=int(time.time()),
                model=request.model,
                choices=[
                    ChatCompletionChoice(
                        index=0,
                        message=Message(role="assistant", content=response.text),
                        finish_reason="stop"
                    )
                ],
                usage={
                    "prompt_tokens": 0,  # TODO: Calculate actual tokens
                    "completion_tokens": 0,
                    "total_tokens": 0
                }
            )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Chat completion failed: {str(e)}")


@app.post("/v1/embeddings", response_model=EmbeddingResponse)
async def create_embeddings(request: EmbeddingRequest):
    """Create embeddings (OpenAI-compatible)."""
    if not llm_provider:
        raise HTTPException(status_code=500, detail="LLM provider not initialized")
    
    try:
        # Get the embedding model
        embed_model = llm_provider.get_embed_model(request.model)
        
        # Handle single string or list of strings
        texts = [request.input] if isinstance(request.input, str) else request.input
        
        # Generate embeddings
        embeddings_data = []
        for idx, text in enumerate(texts):
            embedding = embed_model.get_text_embedding(text)
            embeddings_data.append(
                EmbeddingData(
                    embedding=embedding,
                    index=idx
                )
            )
        
        return EmbeddingResponse(
            data=embeddings_data,
            model=request.model,
            usage={
                "prompt_tokens": sum(len(text.split()) for text in texts),
                "total_tokens": sum(len(text.split()) for text in texts)
            }
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Embedding creation failed: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    
    port = int(os.getenv("PORT", "8000"))
    host = os.getenv("HOST", "0.0.0.0")
    
    print(f"Starting Knowledge Assistant API Server on {host}:{port}")
    print(f"Ollama URL: {OLLAMA_BASE_URL}")
    print(f"Default Model: {DEFAULT_MODEL}")
    print(f"Default Embed Model: {DEFAULT_EMBED_MODEL}")
    
    uvicorn.run(app, host=host, port=port)
