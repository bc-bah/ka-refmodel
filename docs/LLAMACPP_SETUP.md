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

Download Gemma 4 26B Instruct from Hugging Face:

```powershell
# Navigate to models directory
cd models

# Download using Hugging Face CLI (recommended)
huggingface-cli download ggml-org/gemma-4-26B-A4B-it-GGUF gemma-4-26B-A4B-it-Q4_K_M.gguf --local-dir . --local-dir-use-symlinks False
```

**Alternative: Manual Download**

1. Visit [ggml-org/gemma-4-26B-A4B-it-GGUF](https://huggingface.co/ggml-org/gemma-4-26B-A4B-it-GGUF)
2. Download `gemma-4-26B-A4B-it-Q4_K_M.gguf` (recommended quantization)
3. Place it in the `./models` directory

#### Embedding Model (Required)

Download EmbeddingGemma 300M for RAG embeddings:

```powershell
# Download using Hugging Face CLI (recommended)
huggingface-cli download ggml-org/embeddinggemma-300M-qat-GGUF embeddinggemma-300M-qat-Q4_0.gguf --local-dir . --local-dir-use-symlinks False
```

**Alternative: Manual Download**

1. Visit [ggml-org/embeddinggemma-300M-qat-GGUF](https://huggingface.co/ggml-org/embeddinggemma-300M-qat-GGUF)
2. Download `embeddinggemma-300M-qat-Q4_0.gguf`
3. Place it in the `./models` directory

### 3. Verify File Structure

Your directory should look like this:

```
ka-refmodel/
├── models/
│   ├── gemma-4-26B-A4B-it-Q4_K_M.gguf      # ~15.6 GB (Generative)
│   └── embeddinggemma-300M-qat-Q4_0.gguf   # ~260 MB (Embeddings)
├── docker-compose.local.yml
├── .env
└── ...
```

### 4. Configure Environment

Edit `.env` file to match your model files:

```env
LLAMACPP_BASE_URL=http://llama-cpp:8080
LLAMACPP_EMBED_URL=http://llama-cpp-embeddings:8080
DEFAULT_MODEL=gemma-4-26B-A4B-it-Q4_K_M
DEFAULT_EMBED_MODEL=embeddinggemma-300M-qat-Q4_0
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
  -m /models/gemma-4-26B-A4B-it-Q4_K_M.gguf
  --host 0.0.0.0
  --port 8080
  -c 8192
  -ngl 0           # CPU-only (change for GPU: 45 for ~24GB VRAM)
  -t 16            # CPU threads (adjust based on your CPU cores)
```

**Adjust GPU layers:**
- `-ngl 0`: CPU-only inference (current default)
- `-ngl 45`: Full GPU offload for ~24GB VRAM (26B model)
- `-ngl 25`: Partial offload for ~12GB VRAM
- Note: Docker GPU support requires CUDA-enabled llama.cpp image

### Context Size

Adjust context window size based on your needs:

```yaml
-c 8192    # Default: 8K tokens
-c 16384   # Extended: 16K tokens
-c 32768   # Large: 32K tokens (requires more RAM)
```

Note: Gemma 4 supports up to 262K context, but larger contexts require significantly more RAM.

### Multiple Models

To use multiple models, download them to the `./models` directory and switch by:

1. Stopping the stack: `.\utils\stop-stack.ps1`
2. Editing `docker-compose.local.yml` to change the `-m` model path
3. Restarting: `.\utils\start-stack.ps1`

**Current Setup:** Dual llama.cpp servers
- Port 11434: Generative model (gemma-4-26B-A4B-it)
- Port 11435: Embedding model (embeddinggemma-300M)

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

# Download the 26B model
huggingface-cli download ggml-org/gemma-4-26B-A4B-it-GGUF gemma-4-26B-A4B-it-Q4_K_M.gguf --local-dir ./models --local-dir-use-symlinks False
```

## Alternative Model Sources

### 1. Direct from llama.cpp

Use llama.cpp's `-hf` flag to download directly:

```bash
llama-cli -hf ggml-org/gemma-4-26B-A4B-it-GGUF --prompt "Hello!"
```

### 2. Other Gemma 4 Models

Explore available models:
- [ggml-org/gemma-4-26B-A4B-it-GGUF](https://huggingface.co/ggml-org/gemma-4-26B-A4B-it-GGUF) - 26B Instruct (current)
- [ggml-org/gemma-4-9b-it-GGUF](https://huggingface.co/ggml-org/gemma-4-9b-it-GGUF) - 9B Instruct (smaller, faster)
- [ggml-org/gemma-4-2b-it-GGUF](https://huggingface.co/ggml-org/gemma-4-2b-it-GGUF) - 2B Instruct (fastest)
- [ggml-org/embeddinggemma-300M-qat-GGUF](https://huggingface.co/ggml-org/embeddinggemma-300M-qat-GGUF) - Embeddings
- Search Hugging Face for more: [gemma-4 GGUF models](https://huggingface.co/models?search=gemma-4%20gguf)

## Performance Benchmarks

Expected performance with Gemma 4 26B Q4_K_M:

| Hardware | Tokens/sec | Configuration | Notes |
|----------|------------|---------------|-------|
| RTX 4090 24GB | 40-60 | GPU layers: 45 | Full model on GPU |
| RTX 4080 16GB | 20-30 | GPU layers: 25 | Partial offload |
| CPU (16+ cores) | 5-10 | CPU only | Current setup |
| CPU (32+ cores) | 10-15 | CPU only | High-end CPU |

**Note:** Current configuration is optimized for CPU-only inference. GPU support requires additional setup.

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
