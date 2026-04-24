# Models Directory

This directory stores GGUF model files for llama.cpp inference.

## Quick Start

### Download Gemma 4 9B Model

```powershell
# Using the download script (recommended)
..\utils\download-models.ps1

# Or manually with Hugging Face CLI
huggingface-cli download ggml-org/gemma-4-9b-it-GGUF gemma-4-9b-it-Q4_K_M.gguf --local-dir . --local-dir-use-symlinks False
```

### Manual Download

1. Visit [ggml-org/gemma-4-9b-it-GGUF](https://huggingface.co/ggml-org/gemma-4-9b-it-GGUF)
2. Download your preferred quantization:
   - `gemma-4-9b-it-Q4_K_M.gguf` (~5.5 GB) - Recommended
   - `gemma-4-9b-it-Q5_K_M.gguf` (~6.5 GB) - Better quality
   - `gemma-4-9b-it-Q6_K.gguf` (~7.5 GB) - High quality
   - `gemma-4-9b-it-Q8_0.gguf` (~9.5 GB) - Highest quality
3. Place the downloaded file in this directory

## File Structure

After downloading, this directory should contain:

```
models/
├── .gitkeep
├── README.md
├── gemma-4-9b-it-Q4_K_M.gguf    # Generative model
└── (optional additional models)
```

## Important Notes

- **GGUF files are NOT tracked by git** - They are too large
- Model files are volume-mounted into the llama.cpp Docker container
- The default configuration expects `gemma-4-9b-it-Q4_K_M.gguf`
- To use a different model, update `docker-compose.local.yml`

## Quantization Guide

| Quantization | Size   | Quality | RAM    | Use Case                  |
|--------------|--------|---------|--------|---------------------------|
| Q4_K_M       | ~5.5GB | Good    | 8GB    | Best balance (recommended)|
| Q5_K_M       | ~6.5GB | Better  | 10GB   | Better quality            |
| Q6_K         | ~7.5GB | Best    | 12GB   | High quality              |
| Q8_0         | ~9.5GB | Highest | 14GB   | Maximum quality           |
| f16          | ~18GB  | Perfect | 24GB   | Development/testing       |

## Embedding Models

For embeddings, you can either:

1. **Use nomic-embed-text** (default) via Ollama or another service
2. **Download a Gemma-based embedding model** to this directory

Currently, the stack uses `nomic-embed-text-v2-moe` for embeddings.

## Additional Resources

- [llama.cpp Model Documentation](https://github.com/ggml-org/llama.cpp#obtaining-and-quantizing-models)
- [Gemma Documentation](https://ai.google.dev/gemma/docs/integrations/llamacpp)
- [GGUF Format](https://github.com/ggerganov/ggml/blob/master/docs/gguf.md)
- [Hugging Face GGML Organization](https://huggingface.co/ggml-org)

## Troubleshooting

**Model not found error?**
- Verify the file exists: `ls *.gguf`
- Check filename matches `docker-compose.local.yml`
- Ensure file downloaded completely

**Out of memory error?**
- Use a smaller quantization (e.g., Q4_K_M)
- Reduce `--ctx-size` in docker-compose
- Decrease `--n-gpu-layers`

For detailed setup instructions, see [`../docs/LLAMACPP_SETUP.md`](../docs/LLAMACPP_SETUP.md)
