# Knowledge Assistant + Open WebUI + llama.cpp

A complete local RAG (Retrieval-Augmented Generation) stack with Knowledge Assistant, Open WebUI, PostgreSQL pgvector, and llama.cpp with Gemma 4 - no AWS Bedrock required!

<p align="center">
  <img src="https://img.shields.io/badge/Python-3.11-blue" alt="Python 3.11">
  <img src="https://img.shields.io/badge/Docker-Required-blue" alt="Docker Required">
  <img src="https://img.shields.io/badge/llama.cpp-Latest-green" alt="llama.cpp">
  <img src="https://img.shields.io/badge/Gemma_4-26B-green" alt="Gemma 4">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License">
</p>

## 🎯 Overview

This project integrates the **BAH Knowledge Assistant** framework with **llama.cpp** for high-performance local LLM inference using **Gemma 4**, **Open WebUI** for a modern chat interface, and **PostgreSQL with pgvector** for vector storage. Everything runs locally via Docker - no cloud dependencies, no API costs, complete privacy.

### Key Features

- ✅ **100% Local** - All data and models stay on your machine
- ✅ **Zero Cost** - No API fees, unlimited usage
- ✅ **Full Privacy** - No data sent to external services
- ✅ **Modern UI** - Beautiful chat interface via Open WebUI
- ✅ **RAG Ready** - Upload documents and query with AI
- ✅ **Gemma 4 Powered** - Latest Google Gemma 4 26B model
- ✅ **High Performance** - Optimized llama.cpp inference engine
- ✅ **Vector Search** - PostgreSQL with pgvector extension
- ✅ **OpenAI Compatible** - Standard API endpoints
- ✅ **GPU Accelerated** - Full CUDA/Metal support (CPU-optimized config included)
git st
## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Browser Interface                     │
│              http://localhost:3000                      │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                 Open WebUI                              │
│         Modern Chat + Document Upload                   │
└────────────┬──────────────────┬─────────────────────────┘
             │                  │
             │            ┌─────▼──────────────────────────┐
┌────────────▼─────────┐  │  llama.cpp Server (Gen)      │
│  KA Backend API      │◄─┤  - Gemma 4 26B Inference     │
│  - FastAPI           │  │  - OpenAI API Compatible     │
│  - LlamaIndex        │  │  - Port 11434                │
│  - OpenAI API        │  └─────────┬────────────────────┘
└────────────┬─────────┘            │
             │            ┌─────────▼────────────────────┐
             │            │  llama.cpp Server (Embed)    │
             │            │  - EmbeddingGemma 300M       │
             └───────────►│  - OpenAI API Compatible     │
                          │  - Port 11435                │
                          └─────────┬────────────────────┘
                                    │
                              ┌─────▼─────┐
                              │  GGUF     │
                              │  Models   │
                              └───────────┘
┌─────────────────────────────────────────────────────────┐
│          PostgreSQL + pgvector                          │
│       Vector Storage & Similarity Search                │
└─────────────────────────────────────────────────────────┘
```

## 📋 Prerequisites

1. **Docker Desktop** - Installed and running
2. **Git** - For cloning repositories
3. **Windows 10/11** with PowerShell
4. **24GB+ RAM** - For running Gemma 4 26B Q4_K_M model
5. **20GB+ free disk space** - For model storage

> **Note:** This setup runs **llama.cpp in a Docker container** with GGUF models mounted from your host machine. GPU acceleration is automatically enabled if available (CUDA/Metal).

### Download Gemma 4 Models

```powershell
# Create models directory
mkdir models
cd models

# Download Gemma 4 26B Instruct (Q4_K_M quantization - recommended)
# Option 1: Using Hugging Face CLI (recommended)
pip install huggingface-hub
huggingface-cli download ggml-org/gemma-4-26B-A4B-it-GGUF gemma-4-26B-A4B-it-Q4_K_M.gguf --local-dir . --local-dir-use-symlinks False

# Option 2: Manual download from Hugging Face
# Visit: https://huggingface.co/ggml-org/gemma-4-26B-A4B-it-GGUF
# Download: gemma-4-26B-A4B-it-Q4_K_M.gguf (~15.6 GB)
# Place in ./models directory

# Download EmbeddingGemma 300M (for RAG embeddings)
huggingface-cli download ggml-org/embeddinggemma-300M-qat-GGUF embeddinggemma-300M-qat-Q4_0.gguf --local-dir . --local-dir-use-symlinks False

# Verify model files
ls *.gguf
```

> **For detailed model setup instructions**, see [`docs/LLAMACPP_SETUP.md`](docs/LLAMACPP_SETUP.md)

## 🚀 Quick Start

### 1. Clone and Setup

```powershell
# Navigate to your workspace
cd c:\temp

# Clone this repository (if not already cloned)
git clone <your-repo-url> ka-refmodel
cd ka-refmodel
```

### 2. Start the Stack

```powershell
# One command to start everything
.\utils\start-stack.ps1
```

The script will:
- ✓ Check Docker is running
- ✓ Verify Ollama is available
- ✓ Build and start all containers
- ✓ Wait for services to be ready

### 3. Access Open WebUI

Open your browser to: **http://localhost:3000**

1. Create your admin account (first user is automatically admin)
2. Start chatting with your local models
3. Upload documents for RAG-powered Q&A

## ⚙️ Configuration

<details>
<summary><b>Port Configuration</b> (click to expand)</summary>

**PostgreSQL Port: 5433** (instead of default 5432)

This setup uses port **5433** for PostgreSQL to avoid conflicts with local PostgreSQL installations that commonly use the default port 5432. This is especially helpful when you're running PostgreSQL on your local machine for other projects.

**To change the PostgreSQL port:**

1. Edit `docker-compose.local.yml` (or `docker-compose.yml`)
2. Update the ports mapping:
   ```yaml
   ports:
     - "YOUR_PORT:5432"  # Change YOUR_PORT to any available port
   ```
3. Restart the stack: `.\utils\stop-stack.ps1` then `.\utils\start-stack.ps1`

**Database connection string:**
- **From containers:** `postgresql://ka_user:ka_password@postgres:5432/knowledge_assistant`
- **From host machine:** `postgresql://ka_user:ka_password@localhost:5433/knowledge_assistant`

</details>

<details>
<summary><b>llama.cpp Configuration</b> (click to expand)</summary>

This setup runs **llama.cpp in a Docker container** with GGUF models volume-mounted from your host machine. This approach:

✅ **High Performance** - Optimized C++ inference engine  
✅ **GPU Accelerated** - Full CUDA/Metal support  
✅ **Low Memory** - Efficient quantized models (GGUF format)  
✅ **Easy Model Management** - Simple file-based model switching  
✅ **OpenAI Compatible** - Standard API endpoints

The Docker container runs llama.cpp server on port `11434` and loads models from `./models` directory.

**Verify llama.cpp configuration:**
```powershell
# Check model files exist
ls ./models

# After starting the stack, test the API
curl http://localhost:11434/v1/models
```

**For detailed configuration options**, see [`docs/LLAMACPP_SETUP.md`](docs/LLAMACPP_SETUP.md)

</details>

<details>
<summary><b>📁 Project Structure</b> (click to expand)</summary>

```
ka-refmodel/
├── docs/                           # 📚 Documentation
│   ├── LLAMACPP_SETUP.md          # llama.cpp & Gemma 4 setup guide
│   ├── DOCKER_SETUP.md            # Complete Docker guide
│   ├── QUICK_REFERENCE.md         # Command cheat sheet
│   └── SETUP_COMPLETE.md          # Detailed setup information
│
├── utils/                          # 🛠️ Utility Scripts
│   ├── start-stack.ps1            # Start Docker stack
│   ├── stop-stack.ps1             # Stop Docker stack
│   ├── view-logs.ps1              # View container logs
│   ├── test-api.ps1               # API health check
│   └── download-models.ps1        # Download Gemma 4 models
│
├── models/                         # 🤖 GGUF Model Files
│   ├── gemma-4-26B-A4B-it-Q4_K_M.gguf       # Generative model (15.6 GB)
│   ├── embeddinggemma-300M-qat-Q4_0.gguf    # Embedding model (260 MB)
│   └── README.md                            # Model setup instructions
│
├── Knowledge-Assistant/            # 📦 KA Framework (submodule)
│   ├── src/
│   │   └── knowledge_assistant/
│   │       └── llamaindex/
│   │           └── local/
│   │               └── models/      # Model providers
│   └── pyproject.toml
│
├── docker-compose.local.yml        # Docker stack config (llama.cpp)
├── Dockerfile.ka-backend           # KA Backend container
├── ka_api_server.py                # FastAPI backend server (OpenAI-compatible)
├── demo_ollama.py                  # Python integration demo (legacy)
├── init-db.sql                     # PostgreSQL setup
├── .env.example                    # Environment template
├── .gitignore                      # Git ignore rules
└── README.md                       # This file

```

</details>

## 🔧 Usage

### Start the Stack

```powershell
.\utils\start-stack.ps1
```

### Stop the Stack

```powershell
.\utils\stop-stack.ps1
```

### View Logs

```powershell
# All services
.\utils\view-logs.ps1

# Specific service
.\utils\view-logs.ps1 open-webui
.\utils\view-logs.ps1 ka-backend
.\utils\view-logs.ps1 postgres
```

### Test the API

```powershell
.\utils\test-api.ps1
```

## 🌐 Service URLs

| Service | URL | Purpose |
|---------|-----|---------|
| **Open WebUI** | http://localhost:3000 | Main chat interface |
| **API Docs** | http://localhost:8000/docs | Interactive API documentation |
| **Health Check** | http://localhost:8000/health | Backend health status |
| **PostgreSQL** | localhost:5433 | Vector database (port 5433 to avoid conflicts) |
| **llama.cpp (Gen)** | http://localhost:11434 | Generative model (Gemma 4 26B) |
| **llama.cpp (Embed)** | http://localhost:11435 | Embedding model (EmbeddingGemma 300M) |

## 📚 Documentation

| Document | Description |
|----------|-------------|
| **[docs/LLAMACPP_SETUP.md](docs/LLAMACPP_SETUP.md)** | llama.cpp and Gemma 4 setup guide |
| **[docs/DOCKER_SETUP.md](docs/DOCKER_SETUP.md)** | Complete Docker setup guide |
| **[docs/QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md)** | Command reference |
| **[docs/SETUP_COMPLETE.md](docs/SETUP_COMPLETE.md)** | Detailed setup information |
| **[models/README.md](models/README.md)** | Model download and configuration guide |

## 🔌 API Integration

<details>
<summary><b>Python Example</b> (click to expand)</summary>

```python
import httpx

# llama.cpp base URLs
gen_url = "http://localhost:11434"
embed_url = "http://localhost:11435"

# Chat completion
async with httpx.AsyncClient() as client:
    response = await client.post(
        f"{gen_url}/v1/chat/completions",
        json={
            "model": "gemma-4-26B-A4B-it-Q4_K_M",
            "messages": [
                {"role": "user", "content": "Explain RAG in one sentence"}
            ],
            "stream": False
        }
    )
    result = response.json()
    print(result["choices"][0]["message"]["content"])

# Generate embeddings
async with httpx.AsyncClient() as client:
    response = await client.post(
        f"{embed_url}/v1/embeddings",
        json={
            "model": "embeddinggemma-300M-qat-Q4_0",
            "input": "Knowledge Assistant"
        }
    )
    result = response.json()
    print(f"Embedding dimensions: {len(result['data'][0]['embedding'])}")
```

</details>

<details>
<summary><b>cURL Example</b> (click to expand)</summary>

```bash
# Health check
curl http://localhost:8000/health

# List models
curl http://localhost:8000/v1/models

# Chat completion
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma-4-26B-A4B-it-Q4_K_M",
    "messages": [{"role": "user", "content": "Hello!"}],
    "stream": false
  }'
```

</details>

## 🎓 RAG with Open WebUI

### Upload Documents

1. Open http://localhost:3000
2. Go to Settings → Documents
3. Upload your files (PDF, TXT, DOCX, etc.)
4. Wait for automatic processing

### Query Documents

1. Start a new chat
2. Type `#` to see available documents
3. Select document(s) to include in context
4. Ask your questions
5. Get AI-powered answers with source citations

## 🔧 Configuration

### Environment Variables

Edit `.env` file (created from `.env.example`):

```env
# llama.cpp settings
LLAMACPP_BASE_URL=http://llama-cpp:8080
LLAMACPP_EMBED_URL=http://llama-cpp-embeddings:8080
DEFAULT_MODEL=gemma-4-26B-A4B-it-Q4_K_M
DEFAULT_EMBED_MODEL=embeddinggemma-300M-qat-Q4_0
MODELS_PATH=./models

# Database
POSTGRES_DB=knowledge_assistant
POSTGRES_USER=ka_user
POSTGRES_PASSWORD=ka_password

# Features
ENABLE_RAG_WEB_SEARCH=true
ENABLE_IMAGE_GENERATION=false
```

### Change Default Model

1. Download a different GGUF model to `./models/` directory
2. Edit `docker-compose.local.yml` to update the `--model` path
3. Restart: `.\utils\stop-stack.ps1` then `.\utils\start-stack.ps1`

See [`docs/LLAMACPP_SETUP.md`](docs/LLAMACPP_SETUP.md) for available models and quantization options.

<details>
<summary><b>🐛 Troubleshooting</b> (click to expand)</summary>

### Docker Won't Start

```powershell
# Check Docker is running
docker info

# If not, start Docker Desktop
```

### llama.cpp Connection Failed

```powershell
# Check llama.cpp container is running
docker ps | Select-String llamacpp

# View logs
docker logs ka-llamacpp

# Test connection
curl http://localhost:11434/v1/models
```

### Model Not Found

```powershell
# Verify model files exist
ls ./models/*.gguf

# Check containers can see the models
docker exec ka-llamacpp ls /models
docker exec ka-llamacpp-embeddings ls /models
```

### Port Already in Use

```powershell
# Find process using port
netstat -ano | findstr :3000

# Kill process or change port in docker-compose.local.yml
```

### View Container Status

```powershell
# Check all containers
docker ps

# Check specific service
docker logs ka-backend
docker logs ka-open-webui
docker logs ka-postgres
```

</details>

<details>
<summary><b>🗄️ Data Management</b> (click to expand)</summary>

### Backup Database

```powershell
docker exec ka-postgres pg_dump -U ka_user knowledge_assistant > backup.sql
```

### Clean Up Docker Resources

Remove old container images and free up disk space:

**Recommended Cleanup Workflow:**

```powershell
# 1. Stop the stack
.\utils\stop-stack.ps1
# or
docker-compose -f docker-compose.local.yml down

# 2. Remove containers and images (keeps volumes/data)
docker-compose -f docker-compose.local.yml down --rmi all

# 3. Remove dangling images
docker image prune -f

# 4. (Optional) Remove volumes if you want to start fresh
docker volume rm ka-refmodel_postgres_data
docker volume rm ka-refmodel_ka_data
docker volume rm ka-refmodel_open_webui_data

# 5. Verify cleanup
docker images
docker ps -a
docker volume ls
```

**Check Disk Usage:**

```powershell
# See all Docker disk usage
docker system df

# List project-related images
docker images --filter "reference=*ka-*"
docker images --filter "reference=*pgvector*"
docker images --filter "reference=*open-webui*"

# Or use PowerShell filtering
docker images | Select-String -Pattern "ka-|pgvector|open-webui"
```

**After cleanup, rebuild fresh:**

```powershell
.\utils\start-stack.ps1
```

### Reset Everything

```powershell
# Stop and remove all data (⚠️ Destructive)
docker-compose -f docker-compose.local.yml down -v

# Start fresh
.\utils\start-stack.ps1
```

> **Note**: The cleanup workflow removes images but preserves your data (volumes). "Reset Everything" removes both images and data.

</details>

<details>
<summary><b>🎯 Key Advantages</b> (click to expand)</summary>

### vs AWS Bedrock
- 💰 **$0 cost** - No per-token charges
- 🔒 **Complete privacy** - Data never leaves your machine
- ⚡ **Faster** - No network latency
- 🌐 **Offline** - Works without internet

### vs Ollama
- 🚀 **Higher Performance** - Optimized C++ inference engine
- 🎛️ **Fine-Grained Control** - GPU layers, context size, quantization
- 📦 **GGUF Native** - Direct model file usage, no conversion
- 🔧 **Production Ready** - Battle-tested llama.cpp engine

### vs Cloud LLMs
- 🔓 **No Limits** - Unlimited usage
- 🎮 **Full Control** - Any model, any time
- 🏠 **Self-Hosted** - Complete infrastructure control
- 📊 **No Tracking** - Zero telemetry or monitoring
- 🧠 **Gemma 4** - Latest Google open model

</details>

## 🤝 Contributing

This project integrates:
- **[Knowledge Assistant](https://github.boozallencsn.com/CTO-GenAI/Knowledge-Assistant)** - BAH's RAG framework
- **[Open WebUI](https://github.com/open-webui/open-webui)** - Modern chat interface
- **[llama.cpp](https://github.com/ggml-org/llama.cpp)** - High-performance LLM inference
- **[Gemma 4](https://ai.google.dev/gemma)** - Google's open language model
- **[pgvector](https://github.com/pgvector/pgvector)** - PostgreSQL vector extension

## 📝 License

This project follows the licenses of its constituent components. See individual repositories for details.

## 🆘 Support

- **llama.cpp Setup**: [docs/LLAMACPP_SETUP.md](docs/LLAMACPP_SETUP.md)
- **Quick Commands**: [docs/QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md)
- **Complete Setup Guide**: [docs/DOCKER_SETUP.md](docs/DOCKER_SETUP.md)
- **Setup Details**: [docs/SETUP_COMPLETE.md](docs/SETUP_COMPLETE.md)
- **Troubleshooting**: Check logs with `.\utils\view-logs.ps1`

## 🎉 What's Next?

1. **Try it now**: `.\utils\start-stack.ps1`
2. **Open**: http://localhost:3000
3. **Upload a document** and ask questions
4. **Build**: Integrate with your applications
5. **Learn More**: See documentation in [docs/](docs/) folder

---

**Built with ❤️ for local AI deployment**

*Last updated: 2026-04-24*
