# llama.cpp Setup Guide

This guide explains how to set up and configure llama.cpp with Gemma 4 models for the Knowledge Assistant stack.

## Overview

This project uses [llama.cpp](https://github.com/ggml-org/llama.cpp) as the LLM inference backend, running in a Docker container. Models are stored in GGUF format and mounted as a volume.

## Quick Start

### 1. Create Models Directory

```powershell
# Create the models directory in the project root
mkdir models
```

### 2. Download Gemma 4 Models

You'll need to download GGUF model files from Hugging Face. The recommended models are:

#### Generative Model (Required)

Download Gemma 4 9B Instruct from Hugging Face:

```powershell
# Navigate to models directory
cd models

# Download using Hugging Face CLI (recommended)
huggingface-cli download ggml-org/gemma-4-9b-it-GGUF gemma-4-9b-it-Q4_K_M.gguf --local-dir . --local-dir-use-symlinks False
```

**Alternative: Manual Download**

1. Visit [ggml-org/gemma-4-9b-it-GGUF](https://huggingface.co/ggml-org/gemma-4-9b-it-GGUF)
2. Download `gemma-4-9b-it-Q4_K_M.gguf` (recommended quantization)
3. Place it in the `./models` directory

#### Embedding Model (Optional)

For embedding generation, you can either:

**Option A:** Use nomic-embed-text (via Ollama or separate service)
- The current setup uses `nomic-embed-text-v2-moe` for embeddings
- You can keep using this via a separate Ollama installation or another embedding service

**Option B:** Use a Gemma-based embedding model
- Search Hugging Face for Gemma embedding models in GGUF format
- Download and configure similarly to the generative model

### 3. Verify File Structure

Your directory should look like this:

```
ka-refmodel/
├── models/
│   ├── gemma-4-9b-it-Q4_K_M.gguf    # ~5.5 GB
│   └── (optional embedding model.gguf)
├── docker-compose.local.yml
├── .env
└── ...
```

### 4. Configure Environment

Edit `.env` file to match your model files:

```env
LLAMACPP_BASE_URL=http://llama-cpp:8080
DEFAULT_MODEL=gemma-4-9b-it-Q4_K_M
DEFAULT_EMBED_MODEL=nomic-embed-text-v2-moe
MODELS_PATH=./models
```

### 5. Start the Stack

```powershell
.\utils\start-stack.ps1
```

## Model Quantization Options

Gemma 4 is available in multiple quantization levels. Choose based on your hardware:

| Quantization | File Size | Quality | RAM Required | Recommended For |
|--------------|-----------|---------|--------------|-----------------|
| `Q4_K_M`     | ~5.5 GB   | Good    | 8 GB         | Most users (balanced) |
| `Q5_K_M`     | ~6.5 GB   | Better  | 10 GB        | Better quality |
| `Q6_K`       | ~7.5 GB   | Best    | 12 GB        | Maximum quality |
| `Q8_0`       | ~9.5 GB   | Highest | 14 GB        | No compromise |
| `f16`        | ~18 GB    | Perfect | 24 GB        | Development/testing |

**Recommendation:** Start with `Q4_K_M` for the best balance of quality and performance.

## Advanced Configuration

### GPU Acceleration

The Docker Compose configuration includes GPU settings:

```yaml
command: >
  --server
  --host 0.0.0.0
  --port 8080
  --model /models/gemma-4-9b-it-Q4_K_M.gguf
  --ctx-size 8192
  --n-gpu-layers 35      # Adjust based on your GPU VRAM
  --threads 8            # Adjust based on your CPU cores
```

**Adjust GPU layers:**
- `--n-gpu-layers 35`: Full offload for ~8GB VRAM
- `--n-gpu-layers 20`: Partial offload for ~4GB VRAM
- `--n-gpu-layers 0`: CPU-only inference

### Context Size

Adjust context window size based on your needs:

```yaml
--ctx-size 8192    # Default: 8K tokens
--ctx-size 16384   # Extended: 16K tokens
--ctx-size 32768   # Large: 32K tokens (requires more RAM)
```

### Multiple Models

To use multiple models, download them to the `./models` directory and switch by:

1. Stopping the stack: `.\utils\stop-stack.ps1`
2. Editing `docker-compose.local.yml` to change the `--model` path
3. Restarting: `.\utils\start-stack.ps1`

## Troubleshooting

### Model Not Found

**Error:** `error loading model: failed to load model`

**Solution:**
1. Verify the model file exists: `ls ./models`
2. Check the filename matches exactly in `docker-compose.local.yml`
3. Ensure the file downloaded completely (check file size)

### Out of Memory

**Error:** `Failed to allocate memory`

**Solution:**
1. Use a smaller quantization (e.g., Q4_K_M instead of Q6_K)
2. Reduce `--ctx-size` to 4096 or 2048
3. Decrease `--n-gpu-layers` if using GPU

### Slow Inference

**Solution:**
1. Enable GPU acceleration (increase `--n-gpu-layers`)
2. Increase `--threads` to match your CPU core count
3. Use a smaller quantization for faster inference

### Container Won't Start

**Error:** `curl: (7) Failed to connect`

**Solution:**
1. Check Docker logs: `docker logs ka-llamacpp`
2. Verify the model path is correct
3. Ensure the models directory is mounted: `docker inspect ka-llamacpp`

## Using Hugging Face CLI

To download models efficiently, install the Hugging Face CLI:

```powershell
# Install Hugging Face CLI
pip install huggingface-hub

# Login (optional, for gated models)
huggingface-cli login

# Download a model
huggingface-cli download ggml-org/gemma-4-9b-it-GGUF gemma-4-9b-it-Q4_K_M.gguf --local-dir ./models --local-dir-use-symlinks False
```

## Alternative Model Sources

### 1. Direct from llama.cpp

Use llama.cpp's `-hf` flag to download directly:

```bash
llama-cli -hf ggml-org/gemma-4-9b-it-GGUF --prompt "Hello!"
```

### 2. Other Gemma 4 Models

Explore available models:
- [ggml-org/gemma-4-9b-it-GGUF](https://huggingface.co/ggml-org/gemma-4-9b-it-GGUF) - 9B Instruct
- [ggml-org/gemma-4-2b-it-GGUF](https://huggingface.co/ggml-org/gemma-4-2b-it-GGUF) - 2B Instruct (smaller)
- Search Hugging Face for more: [gemma-4 GGUF models](https://huggingface.co/models?search=gemma-4%20gguf)

## Performance Benchmarks

Expected performance with Gemma 4 9B Q4_K_M:

| Hardware | Tokens/sec | Configuration |
|----------|------------|---------------|
| RTX 3060 12GB | 40-50 | GPU layers: 35 |
| RTX 4070 12GB | 60-80 | GPU layers: 35 |
| RTX 4090 24GB | 100-120 | GPU layers: 35 |
| CPU (16 cores) | 10-15 | CPU only |

## Additional Resources

- [llama.cpp GitHub](https://github.com/ggml-org/llama.cpp)
- [Gemma Documentation](https://ai.google.dev/gemma/docs/integrations/llamacpp)
- [GGUF Format Specification](https://github.com/ggerganov/ggml/blob/master/docs/gguf.md)
- [Hugging Face GGML Organization](https://huggingface.co/ggml-org)

## Support

If you encounter issues:
1. Check the logs: `.\utils\view-logs.ps1 llama-cpp`
2. Review this documentation
3. Check the [llama.cpp issues](https://github.com/ggml-org/llama.cpp/issues)
