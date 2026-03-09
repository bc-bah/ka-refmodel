# Knowledge Assistant + Open WebUI + Ollama

A complete local RAG (Retrieval-Augmented Generation) stack with Knowledge Assistant, Open WebUI, PostgreSQL pgvector, and Ollama - no AWS Bedrock required!

<img src="https://img.shields.io/badge/Python-3.11-blue" alt="Python 3.11">
<img src="https://img.shields.io/badge/Docker-Required-blue" alt="Docker Required">
<img src="https://img.shields.io/badge/Ollama-0.17+-green" alt="Ollama">
<img src="https://img.shields.io/badge/License-MIT-green" alt="License">

## 🎯 Overview

This project integrates the **BAH Knowledge Assistant** framework with **Ollama** for local LLM inference, **Open WebUI** for a modern chat interface, and **PostgreSQL with pgvector** for vector storage. Everything runs locally via Docker - no cloud dependencies, no API costs, complete privacy.

### Key Features

- ✅ **100% Local** - All data and models stay on your machine
- ✅ **Zero Cost** - No API fees, unlimited usage
- ✅ **Full Privacy** - No data sent to external services
- ✅ **Modern UI** - Beautiful chat interface via Open WebUI
- ✅ **RAG Ready** - Upload documents and query with AI
- ✅ **Multi-Model** - Use any Ollama model
- ✅ **Vector Search** - PostgreSQL with pgvector extension
- ✅ **OpenAI Compatible** - Standard API endpoints

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
┌────────────▼─────────┐  ┌────▼──────────────────────────┐
│  KA Backend API      │  │     Ollama (Host Machine)    │
│  - FastAPI           │◄─┤  - Local LLM Inference       │
│  - LlamaIndex        │  │  - Multiple Models           │
│  - OpenAI API        │  │                              │
└────────────┬─────────┘  └──────────────────────────────┘
             │
┌────────────▼─────────────────────────────────────────────┐
│          PostgreSQL + pgvector                          │
│       Vector Storage & Similarity Search                │
└─────────────────────────────────────────────────────────┘
```

## 📋 Prerequisites

1. **Docker Desktop** - Installed and running
2. **Ollama** - Installed with at least one model
3. **Git** - For cloning repositories
4. **Windows 10/11** with PowerShell

### Install Ollama Models

```powershell
# Install a generative model (choose one or more)
ollama pull qwen3:30b
ollama pull llama3.1:8b
ollama pull mistral:7b

# Install an embedding model
ollama pull nomic-embed-text-v2-moe

# Verify installation
ollama list
```

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

## 📁 Project Structure

```
ka-refmodel/
├── docs/                           # 📚 Documentation
│   ├── DOCKER_SETUP.md            # Complete Docker guide
│   ├── QUICK_REFERENCE.md         # Command cheat sheet
│   └── SETUP_COMPLETE.md          # Detailed setup information
│
├── utils/                          # 🛠️ Utility Scripts
│   ├── start-stack.ps1            # Start Docker stack
│   ├── stop-stack.ps1             # Stop Docker stack
│   ├── view-logs.ps1              # View container logs
│   └── test-api.ps1               # API health check
│
├── Knowledge-Assistant/            # 📦 KA Framework (submodule)
│   ├── src/
│   │   └── knowledge_assistant/
│   │       └── llamaindex/
│   │           └── local/
│   │               └── models/
│   │                   └── ollama.py    # ← Ollama integration
│   └── pyproject.toml
│
├── docker-compose.local.yml        # Docker stack config
├── Dockerfile.ka-backend           # KA Backend container
├── ka_api_server.py                # FastAPI backend server
├── demo_ollama.py                  # Python integration demo
├── init-db.sql                     # PostgreSQL setup
├── .env.example                    # Environment template
├── .gitignore                      # Git ignore rules
└── README.md                       # This file

```

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
| **PostgreSQL** | localhost:5432 | Vector database |
| **Ollama** | http://localhost:11434 | LLM inference server |

## 📚 Documentation

| Document | Description |
|----------|-------------|
| **[docs/DOCKER_SETUP.md](docs/DOCKER_SETUP.md)** | Complete Docker setup guide |
| **[docs/QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md)** | Command reference |
| **[docs/SETUP_COMPLETE.md](docs/SETUP_COMPLETE.md)** | Detailed setup information |
| **[demo_ollama.py](demo_ollama.py)** | Python usage examples |

## 🔌 API Integration

### Python Example

```python
from knowledge_assistant.llamaindex.local.models.ollama import OllamaLlmProvider

# Initialize Ollama provider
provider = OllamaLlmProvider(base_url="http://localhost:11434")

# Get models
llm = provider.get_generative_model("qwen3:30b")
embed_model = provider.get_embed_model("nomic-embed-text-v2-moe")

# Generate text
response = llm.complete("Explain RAG in one sentence")
print(response.text)

# Generate embeddings
embedding = embed_model.get_text_embedding("Knowledge Assistant")
print(f"Embedding dimensions: {len(embedding)}")
```

### cURL Example

```bash
# Health check
curl http://localhost:8000/health

# List models
curl http://localhost:8000/v1/models

# Chat completion
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3:30b",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

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
# Ollama settings
OLLAMA_BASE_URL=http://host.docker.internal:11434
DEFAULT_MODEL=qwen3:30b
DEFAULT_EMBED_MODEL=nomic-embed-text-v2-moe

# Database
POSTGRES_DB=knowledge_assistant
POSTGRES_USER=ka_user
POSTGRES_PASSWORD=ka_password

# Features
ENABLE_RAG_WEB_SEARCH=true
ENABLE_IMAGE_GENERATION=false
```

### Change Default Model

1. Edit `.env` file
2. Update `DEFAULT_MODEL=your-model-name`
3. Restart: `.\utils\stop-stack.ps1` then `.\utils\start-stack.ps1`

## 🐛 Troubleshooting

### Docker Won't Start

```powershell
# Check Docker is running
docker info

# If not, start Docker Desktop
```

### Ollama Connection Failed

```powershell
# Check Ollama is running
ollama list

# Test connection
curl http://localhost:11434/api/tags
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

## 🗄️ Data Management

### Backup Database

```powershell
docker exec ka-postgres pg_dump -U ka_user knowledge_assistant > backup.sql
```

### Reset Everything

```powershell
# Stop and remove all data (⚠️ Destructive)
docker-compose -f docker-compose.local.yml down -v

# Start fresh
.\utils\start-stack.ps1
```

## 🎯 Key Advantages

### vs AWS Bedrock
- 💰 **$0 cost** - No per-token charges
- 🔒 **Complete privacy** - Data never leaves your machine
- ⚡ **Faster** - No network latency
- 🌐 **Offline** - Works without internet

### vs Basic Ollama
- 🎨 **Modern UI** - Professional chat interface
- 📚 **RAG Built-in** - Document Q&A out of the box
- 🔍 **Vector Search** - Similarity search with pgvector
- 🔌 **API Ready** - OpenAI-compatible endpoints

### vs Cloud LLMs
- 🔓 **No Limits** - Unlimited usage
- 🎮 **Full Control** - Any model, any time
- 🏠 **Self-Hosted** - Complete infrastructure control
- 📊 **No Tracking** - Zero telemetry or monitoring

## 🤝 Contributing

This project integrates:
- **[Knowledge Assistant](https://github.boozallencsn.com/CTO-GenAI/Knowledge-Assistant)** - BAH's RAG framework
- **[Open WebUI](https://github.com/open-webui/open-webui)** - Modern chat interface
- **[Ollama](https://ollama.ai)** - Local LLM runtime
- **[pgvector](https://github.com/pgvector/pgvector)** - PostgreSQL vector extension

## 📝 License

This project follows the licenses of its constituent components. See individual repositories for details.

## 🆘 Support

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

*Last updated: 2026-03-03*
