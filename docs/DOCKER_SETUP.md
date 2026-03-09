# Knowledge Assistant + Open WebUI Docker Stack

Complete local RAG (Retrieval-Augmented Generation) stack with Knowledge Assistant, Open WebUI, pgvector PostgreSQL, and Ollama.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Your Local Machine                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐                    ┌─────────────────┐   │
│  │   Ollama     │◄───────────────────┤  Open WebUI     │   │
│  │ (Port 11434) │                    │  (Port 3000)    │   │
│  └──────▲───────┘                    └────────┬────────┘   │
│         │                                     │              │
│         │                                     │              │
│  ┌──────┴───────────────────────────────────▼────────────┐ │
│  │          Docker Network (ka-network)                  │ │
│  │                                                        │ │
│  │  ┌─────────────────┐       ┌────────────────────┐   │ │
│  │  │  KA Backend API │◄──────┤  PostgreSQL +      │   │ │
│  │  │  (Port 8000)    │       │  pgvector          │   │ │
│  │  │                 │       │  (Port 5433→5432)  │   │ │
│  │  │  - LlamaIndex   │       │                    │   │ │
│  │  │  - Ollama Prov. │       │  Vector Storage    │   │ │
│  │  │  - FastAPI      │       │  for RAG           │   │ │
│  │  └─────────────────┘       └────────────────────┘   │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Components

### 1. **Ollama** (Host)
- Local LLM inference engine
- Runs on host machine (not in Docker)
- Provides models like `qwen3:30b`, `llama3.1`, etc.
- Port: 11434

### 2. **Knowledge Assistant Backend** (Docker)
- FastAPI server with OpenAI-compatible API
- Integrates LlamaIndex with Ollama
- Provides `/v1/chat/completions` and `/v1/embeddings` endpoints
- Port: 8000

### 3. **PostgreSQL + pgvector** (Docker)
- Vector database for RAG
- Stores document embeddings
- Fast similarity search with pgvector extension
- Port: 5433 (host) → 5432 (container)

### 4. **Open WebUI** (Docker)
- Modern, user-friendly chat interface
- RAG capabilities built-in
- Multi-model support
- Document upload and management
- Port: 3000

## Prerequisites

1. **Docker Desktop** installed and running
2. **Ollama** installed with models:
   ```powershell
   # Check Ollama is running
   ollama list
   
   # Pull recommended models (if not already installed)
   ollama pull qwen3:30b          # LLM (or any model you prefer)
   ollama pull nomic-embed-text-v2-moe  # Embeddings
   ```
3. **Git** (to clone Knowledge Assistant)
4. **Python 3.11** virtual environment activated

## Quick Start

### 1. Start the Stack

```powershell
# Navigate to project directory
cd c:\temp\ka-refmodel

# Start everything
.\utils\start-stack.ps1
```

The script will:
- Check Docker and Ollama are running
- Create `.env` file if needed
- Build and start all containers
- Wait for services to be ready
- Display access URLs

### 2. Access Open WebUI

1. Open your browser to **http://localhost:3000**
2. Create an admin account (first user is automatically admin)
3. Start chatting!

## Manual Docker Commands

If you prefer manual control:

```powershell
# Start stack
docker-compose -f docker-compose.local.yml up -d --build

# Stop stack
docker-compose -f docker-compose.local.yml down

# View logs
docker-compose -f docker-compose.local.yml logs -f

# View logs for specific service
docker-compose -f docker-compose.local.yml logs -f open-webui
docker-compose -f docker-compose.local.yml logs -f ka-backend
docker-compose -f docker-compose.local.yml logs -f postgres

# Restart a service
docker-compose -f docker-compose.local.yml restart ka-backend

# Rebuild a service
docker-compose -f docker-compose.local.yml up -d --build ka-backend

# Check service health
docker-compose -f docker-compose.local.yml ps
```

## Using the RAG Features

### Upload Documents to Open WebUI

1. Open http://localhost:3000
2. Click on your user icon → **Settings** → **Documents**
3. Upload your documents (PDF, TXT, DOCX, etc.)
4. Documents are automatically processed and embedded

### Using RAG in Chat

1. Start a new chat
2. Use the `#` command to reference documents:
   - Type `#` to see available documents
   - Select document(s) to include in context
3. Ask questions about your documents
4. The system will retrieve relevant chunks and generate answers

## Configuration

### Environment Variables

Edit `.env` file to customize:

```env
# Ollama Configuration
OLLAMA_BASE_URL=http://host.docker.internal:11434
DEFAULT_MODEL=qwen3:30b
DEFAULT_EMBED_MODEL=nomic-embed-text-v2-moe

# PostgreSQL
POSTGRES_DB=knowledge_assistant
POSTGRES_USER=ka_user
POSTGRES_PASSWORD=ka_password

# Open WebUI Features
ENABLE_RAG_WEB_SEARCH=true
ENABLE_IMAGE_GENERATION=false
```

### Changing Models

Edit `docker-compose.local.yml` to change default models:

```yaml
ka-backend:
  environment:
    DEFAULT_MODEL: llama3.1:8b        # Change LLM
    DEFAULT_EMBED_MODEL: nomic-embed-text  # Change embedding model
```

Then restart:
```powershell
docker-compose -f docker-compose.local.yml restart ka-backend
```

## Accessing Services

| Service | URL | Purpose |
|---------|-----|---------|
| Open WebUI | http://localhost:3000 | Main chat interface |
| KA Backend API | http://localhost:8000 | OpenAI-compatible API |
| API Documentation | http://localhost:8000/docs | Interactive API docs |
| PostgreSQL | localhost:5433 | Vector database (port 5433 to avoid conflicts) |
| Ollama | http://localhost:11434 | LLM inference (runs on host) |

## Testing the Setup

### 1. Test Ollama Connection

```powershell
# From host machine
curl http://localhost:11434/api/tags

# From inside ka-backend container
docker exec ka-backend curl http://host.docker.internal:11434/api/tags
```

### 2. Test KA Backend API

```powershell
# Health check
curl http://localhost:8000/health

# List models
curl http://localhost:8000/v1/models

# Chat completion
curl -X POST http://localhost:8000/v1/chat/completions `
  -H "Content-Type: application/json" `
  -d '{
    "model": "qwen3:30b",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

### 3. Test PostgreSQL + pgvector

```powershell
# Connect to database
docker exec -it ka-postgres psql -U ka_user -d knowledge_assistant

# Inside psql:
# Check pgvector extension
SELECT * FROM pg_extension WHERE extname = 'vector';

# Check tables
\dt

# Exit
\q
```

## Troubleshooting

### Ollama Connection Issues

**Problem**: KA Backend can't connect to Ollama

**Solution**:
```powershell
# Check Ollama is running
ollama list

# Test connection
curl http://localhost:11434/api/tags

# Check Docker can reach host
docker exec ka-backend curl http://host.docker.internal:11434/api/tags
```

### Container Won't Start

**Problem**: Container fails to start

**Solution**:
```powershell
# Check logs
docker-compose -f docker-compose.local.yml logs ka-backend

# Rebuild container
docker-compose -f docker-compose.local.yml up -d --build --force-recreate ka-backend
```

### Port Already in Use

**Problem**: Port 3000, 8000, or 5433 already in use

**Solution**:
```powershell
# Find what's using the port
netstat -ano | findstr :3000

# Kill the process or change port in docker-compose.local.yml
```

**Note**: PostgreSQL is configured to use port **5433** instead of the default 5432 to avoid conflicts with local PostgreSQL installations. If 5433 is also in use, edit the port mapping in `docker-compose.local.yml`.

### Database Connection Issues

**Problem**: Can't connect to PostgreSQL

**Solution**:
```powershell
# Check database is healthy
docker-compose -f docker-compose.local.yml ps

# Restart database
docker-compose -f docker-compose.local.yml restart postgres

# View database logs
docker-compose -f docker-compose.local.yml logs postgres
```

## Data Persistence

All data is stored in Docker volumes:

- `postgres_data`: PostgreSQL database and vector embeddings
- `open_webui_data`: Open WebUI settings, chat history, uploaded documents
- `ka_data`: Knowledge Assistant cache and temporary files

### Backup Data

```powershell
# Backup PostgreSQL database
docker exec ka-postgres pg_dump -U ka_user knowledge_assistant > backup.sql

# Backup volumes
docker run --rm -v postgres_data:/data -v c:/temp/backup:/backup alpine tar czf /backup/postgres_data.tar.gz -C /data .
```

### Reset Everything

```powershell
# Stop and remove all containers and volumes
docker-compose -f docker-compose.local.yml down -v

# Start fresh
.\start-stack.ps1
```

## Advanced Features

### Using pgvector for Custom RAG

The PostgreSQL database includes pgvector for custom vector storage:

```python
import psycopg2
from pgvector.psycopg2 import register_vector

# Connect
conn = psycopg2.connect(
    host="localhost",
    port=5433,  # Note: 5433 on host, 5432 inside container
    database="knowledge_assistant",
    user="ka_user",
    password="ka_password"
)
register_vector(conn)

# Search similar documents
cur = conn.cursor()
query_embedding = [0.1, 0.2, ...]  # Your 768-dim embedding
cur.execute("""
    SELECT * FROM search_similar_documents(%s::vector, 0.7, 10)
""", (query_embedding,))
results = cur.fetchall()
```

### Custom Knowledge Assistant Integration

You can use the Knowledge Assistant Python library directly:

```python
from knowledge_assistant.llamaindex.local.models.ollama import OllamaLlmProvider

# Initialize provider
provider = OllamaLlmProvider(base_url="http://localhost:11434")

# Get models
llm = provider.get_generative_model("qwen3:30b")
embed_model = provider.get_embed_model("nomic-embed-text-v2-moe")

# Use in your code
response = llm.complete("What is RAG?")
print(response.text)
```

## Next Steps

1. **Explore Open WebUI Features**:
   - Document upload and management
   - Multi-model conversations
   - Custom prompts and functions
   - Web search integration

2. **Integrate with LlamaIndex**:
   - Build custom query engines
   - Create ingestion pipelines
   - Implement advanced RAG patterns

3. **Scale Your Deployment**:
   - Add more Ollama models
   - Configure external S3 storage
   - Set up Redis for caching
   - Deploy to cloud (AWS, Azure, GCP)

## Support

- **Open WebUI Docs**: https://docs.openwebui.com
- **LlamaIndex Docs**: https://docs.llamaindex.ai
- **Ollama Docs**: https://ollama.ai/docs
- **pgvector Docs**: https://github.com/pgvector/pgvector

---

**Happy Building! 🚀**
