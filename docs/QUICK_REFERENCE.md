# Knowledge Assistant Quick Reference

## 🚀 Quick Start Commands

### Start Docker Stack
```powershell
.\utils\start-stack.ps1
```
**Access**: http://localhost:3000

### Stop Docker Stack
```powershell
.\utils\stop-stack.ps1
```

### Test API
```powershell
.\utils\test-api.ps1
```

### View Logs
```powershell
.\utils\view-logs.ps1              # All services
.\utils\view-logs.ps1 open-webui   # Specific service
```

## 📍 Service URLs

| Service | URL | Purpose |
|---------|-----|---------|
| **Open WebUI** | http://localhost:3000 | Chat interface |
| **KA API** | http://localhost:8000 | Backend API |
| **API Docs** | http://localhost:8000/docs | Interactive docs |
| **PostgreSQL** | localhost:5432 | Vector DB |
| **Ollama** | http://localhost:11434 | LLM server |

## 🔑 Default Credentials

### PostgreSQL
- **Host**: localhost
- **Port**: 5432
- **Database**: knowledge_assistant
- **User**: ka_user
- **Password**: ka_password

### First Time Setup
1. Open http://localhost:3000
2. Create admin account (first user = admin)
3. No other credentials needed!

## 🛠️ Common Tasks

### Restart a Service
```powershell
docker-compose -f docker-compose.local.yml restart ka-backend
```

### View Container Status
```powershell
docker-compose -f docker-compose.local.yml ps
```

### Access Container Shell
```powershell
docker exec -it ka-backend /bin/bash
docker exec -it ka-postgres /bin/bash
```

### Connect to PostgreSQL
```powershell
docker exec -it ka-postgres psql -U ka_user -d knowledge_assistant
```

### Test Ollama Connection
```powershell
curl http://localhost:11434/api/tags
```

### Test KA Backend
```powershell
curl http://localhost:8000/health
```

## 📚 Using RAG in Open WebUI

### Upload Documents
1. Open WebUI → Settings → Documents
2. Upload files (PDF, TXT, DOCX, etc.)
3. Wait for processing

### Chat with Documents
1. In chat, type `#` to see documents
2. Select document(s)
3. Ask questions
4. Get AI-powered answers with citations

## 🔄 Development Workflow

### Modify KA Backend Code
```powershell
# 1. Edit files in Knowledge-Assistant/
# 2. Rebuild container
docker-compose -f docker-compose.local.yml up -d --build ka-backend
# 3. View logs
docker-compose -f docker-compose.local.yml logs -f ka-backend
```

### Test Python Code Locally
```powershell
# Activate virtual environment
.\.venv\Scripts\Activate.ps1

# Run demo
python demo_ollama.py

# Use Knowledge Assistant
python
>>> from knowledge_assistant.llamaindex.local.models.ollama import OllamaLlmProvider
>>> provider = OllamaLlmProvider()
>>> llm = provider.get_generative_model("qwen3:30b")
>>> response = llm.complete("Hello!")
>>> print(response.text)
```

## 🗄️ Data Management

### Backup Database
```powershell
docker exec ka-postgres pg_dump -U ka_user knowledge_assistant > backup.sql
```

### Restore Database
```powershell
cat backup.sql | docker exec -i ka-postgres psql -U ka_user -d knowledge_assistant
```

### Reset Everything (⚠️ Deletes all data)
```powershell
docker-compose -f docker-compose.local.yml down -v
.\start-stack.ps1
```

## 🔧 Troubleshooting

### Containers Won't Start
```powershell
# Check Docker is running
docker info

# Check logs
docker-compose -f docker-compose.local.yml logs

# Force rebuild
docker-compose -f docker-compose.local.yml up -d --build --force-recreate
```

### Ollama Connection Failed
```powershell
# Check Ollama is running
ollama list

# Test connection
curl http://localhost:11434/api/tags

# From container
docker exec ka-backend curl http://host.docker.internal:11434/api/tags
```

### Port Already in Use
```powershell
# Find process using port
netstat -ano | findstr :3000

# Change port in docker-compose.local.yml
```

### Database Issues
```powershell
# Restart database
docker-compose -f docker-compose.local.yml restart postgres

# Check database health
docker exec ka-postgres pg_isready -U ka_user
```

## 📊 Available Models

### List Ollama Models
```powershell
ollama list
```

### Pull New Model
```powershell
ollama pull llama3.1:8b
ollama pull mistral:7b
```

### Change Default Model
Edit `.env` file:
```env
DEFAULT_MODEL=llama3.1:8b
```
Then restart:
```powershell
docker-compose -f docker-compose.local.yml restart ka-backend
```

## 🌐 API Examples

### Chat Completion
```powershell
curl -X POST http://localhost:8000/v1/chat/completions `
  -H "Content-Type: application/json" `
  -d '{
    "model": "qwen3:30b",
    "messages": [{"role": "user", "content": "What is RAG?"}]
  }'
```

### Generate Embeddings
```powershell
curl -X POST http://localhost:8000/v1/embeddings `
  -H "Content-Type: application/json" `
  -d '{
    "model": "nomic-embed-text-v2-moe",
    "input": "Hello world"
  }'
```

### List Available Models
```powershell
curl http://localhost:8000/v1/models
```

## 📖 Documentation

- **Full Docker Setup**: [DOCKER_SETUP.md](DOCKER_SETUP.md)
- **Main Setup Guide**: [README.md](README.md)
- **Open WebUI Docs**: https://docs.openwebui.com
- **LlamaIndex Docs**: https://docs.llamaindex.ai
- **Ollama Docs**: https://ollama.ai/docs

## 🆘 Getting Help

1. Check logs: `.\view-logs.ps1`
2. Review [DOCKER_SETUP.md](DOCKER_SETUP.md) troubleshooting section
3. Check service health: `docker-compose -f docker-compose.local.yml ps`
4. Test connections individually (Ollama, DB, API)

---

**Tip**: Keep this file open in a separate window for quick reference! 📌
