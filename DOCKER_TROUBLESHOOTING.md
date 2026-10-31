# Z-Image Docker - Guia de Troubleshooting

## 🔴 Problema Atual: Docker Desktop Não Responde

O Docker Desktop no seu sistema está com problemas críticos:
- Comandos docker ficam travados (timeout)
- Filesystem read-only
- Build falha no export

### Causa Provável
- Docker Desktop corrompido ou com recursos esgotados
- 6+ containers rodando consumindo muita RAM
- Cache do Docker cheio/corrompido

## ✅ SOLUÇÃO 1: Reiniciar Manualmente o Docker (RECOMENDADO)

### Passo a Passo

1. **Fechar TUDO do Docker**
   ```powershell
   # No PowerShell como Administrador
   Stop-Process -Name "Docker Desktop" -Force
   Get-Process docker* | Stop-Process -Force
   ```

2. **Limpar dados temporários**
   ```powershell
   # Limpar AppData (opcional mas recomendado)
   Remove-Item "$env:LOCALAPPDATA\Docker\*" -Recurse -Force -ErrorAction SilentlyContinue
   ```

3. **Reiniciar o computador**
   - Sim, reiniciar o PC resolve muitos problemas do Docker
   - Depois de reiniciar, abra Docker Desktop

4. **Abrir Docker Desktop**
   - Clique no ícone do Docker Desktop
   - Espere até o ícone ficar VERDE (não apenas amarelo)
   - Pode levar 2-3 minutos

5. **Testar se está funcionando**
   ```powershell
   docker ps
   docker images
   ```
   
   Se responder em menos de 2 segundos = OK!

6. **Construir a imagem Z-Image**
   ```powershell
   cd C:\Users\USER\Z-Image
   docker build -t z-image:latest -f Dockerfile .
   ```
   
   Tempo esperado: 5-10 minutos

7. **Iniciar o container**
   ```powershell
   docker run -d --name zimage-server -p 8002:8002 -v zimage-models:/cache z-image:latest
   ```

8. **Verificar logs (primeira vez baixa ~12GB)**
   ```powershell
   docker logs -f zimage-server
   ```

## ✅ SOLUÇÃO 2: Docker Compose (Mais Simples)

Depois de reiniciar o Docker:

```powershell
cd C:\Users\USER\Z-Image
docker-compose up -d
docker-compose logs -f
```

## ✅ SOLUÇÃO 3: Rodar SEM Docker (Mais Rápido)

Se o Docker continuar com problemas, use Python direto:

```powershell
cd C:\Users\USER\Z-Image

# Criar ambiente virtual
python -m venv venv
.\venv\Scripts\Activate.ps1

# Instalar dependências (demora ~5 min)
pip install torch transformers diffusers safetensors pillow fastapi uvicorn python-multipart loguru accelerate

# Rodar API
python docker_api.py
```

Acesse: http://localhost:8002/docs

## 🔧 SOLUÇÃO 4: Liberar Recursos Docker

Se você tem muitos containers rodando:

```powershell
# Ver o que está rodando
docker ps

# Parar containers não essenciais
docker stop questmate-dockhand      # AI Companion (opcional)
docker stop qwen2-vl-server-cpu     # Image Analysis (opcional)
docker stop photocraft-web          # Image Editor (opcional)

# Isso libera ~5-7GB de RAM
```

## 🧹 SOLUÇÃO 5: Limpeza Completa Docker

⚠️ **ATENÇÃO**: Isso remove TUDO do Docker!

```powershell
# Parar tudo
docker stop $(docker ps -aq)

# Remover containers
docker rm $(docker ps -aq)

# Remover imagens não usadas
docker image prune -a -f

# Remover volumes não usados
docker volume prune -f

# Remover networks não usadas
docker network prune -f

# Limpar cache de build
docker builder prune -a -f
```

Depois disso, reinicie o Docker Desktop.

## 📝 Checklist de Diagnóstico

Execute estes comandos e veja onde falha:

```powershell
# 1. Docker está instalado?
docker --version

# 2. Docker responde? (deve responder em <2s)
Measure-Command { docker ps }

# 3. Tem espaço em disco? (precisa >20GB)
Get-PSDrive C | Select-Object Used,Free

# 4. Tem RAM disponível? (precisa >4GB)
Get-CimInstance Win32_OperatingSystem | Select-Object FreePhysicalMemory

# 5. Docker Desktop está rodando?
Get-Process "Docker Desktop" -ErrorAction SilentlyContinue
```

## 🎯 Arquivos Criados para Z-Image

| Arquivo | Descrição |
|---------|-----------|
| `Dockerfile` | Imagem Docker completa |
| `docker-compose.yml` | Orquestração Docker |
| `docker_api.py` | API FastAPI com src/ |
| `docker_api_simple.py` | API standalone (sem src/) |
| `build-zimage-complete.ps1` | Script automatizado |
| `DOCKER_GUIDE.md` | Guia de uso |
| `RUN_WITHOUT_DOCKER.md` | Alternativa sem Docker |

## 💡 Recomendação Final

**Para desenvolvimento local:** Use SOLUÇÃO 3 (sem Docker)
- Mais rápido
- Mais fácil debug
- Menos overhead

**Para produção/deploy:** Use Docker
- Isolamento
- Reprodutível
- Portável

## 🚀 Quando o Z-Image Estiver Rodando

### Testar API

```powershell
# Health check
curl http://localhost:8002/health

# Info do modelo
curl http://localhost:8002/info

# Gerar imagem
curl -X POST http://localhost:8002/generate `
  -H "Content-Type: application/json" `
  -d '{"prompt":"a beautiful cat","num_inference_steps":8}'
```

### Integrar com QuestMate RPG

```javascript
// Frontend: Gerar avatar de personagem
const response = await fetch('http://localhost:8002/generate', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify({
    prompt: `fantasy RPG character, ${race} ${archetype}, ${description}`,
    num_inference_steps: 8
  })
});

const data = await response.json();
// data.image_url contém a imagem gerada
```

## 📊 Recursos Necessários

| Componente | CPU | GPU | RAM | Disco |
|------------|-----|-----|-----|-------|
| **Build** | 4+ cores | N/A | 8GB | 20GB |
| **Runtime (CPU)** | 4+ cores | N/A | 12GB | 25GB |
| **Runtime (GPU)** | 2+ cores | 8GB VRAM | 8GB | 25GB |

## 🔗 Links Úteis

- Modelo: https://huggingface.co/Tongyi-MAI/Z-Image-Turbo
- Paper: https://arxiv.org/abs/2501.18774
- Docker Docs: https://docs.docker.com/

---

**Última atualização:** 2026-10-19  
**Status:** Docker Desktop com problemas - use alternativa sem Docker

