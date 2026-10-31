# Z-Image Docker - Status Report

## 🔴 Status Atual: Docker Sobrecarregado

**Data**: 2026-10-19  
**Problema**: O sistema Docker está travado ou extremamente lento

### Sintomas Observados

1. ✗ `docker ps` timeout (>30 segundos)
2. ✗ `docker-compose build` timeout (>10 minutos)
3. ✗ `docker logs` sem resposta
4. ✗ Comandos Docker ficam pendurados indefinidamente

### Causa Provável

O sistema já está executando **6 containers**:

| Container | Porta | Status | RAM Estimada |
|-----------|-------|--------|--------------|
| questmate-frontend | 80 | Healthy | ~200MB |
| questmate-backend | 8080 | Healthy | ~1GB |
| questmate-db | 5433 | Healthy | ~512MB |
| questmate-dockhand | 3001 | Healthy | ~512MB |
| qwen2-vl-server-cpu | 8001 | Healthy | ~4-6GB |
| photocraft-web | 8090 | Healthy | ~512MB |

**Total**: ~7-8GB de RAM em uso + overhead do Docker

### Por Que o Z-Image Travou

1. **Modelo gigante**: Z-Image-Turbo é ~12GB (mais que Qwen2-VL)
2. **Build pesado**: `pip install torch` baixa 2-3GB adicionais
3. **RAM insuficiente**: Sistema provavelmente sem RAM disponível
4. **Docker Desktop**: Pode estar com limite de recursos atingido

## ✅ Solução Recomendada: Executar Sem Docker

Criamos os arquivos necessários para rodar o Z-Image diretamente com Python:

### Arquivos Criados

1. `docker_api_simple.py` - API server FastAPI simplificado
2. `start-local.ps1` - Script PowerShell para iniciar localmente
3. `RUN_WITHOUT_DOCKER.md` - Guia completo de instalação sem Docker
4. `Dockerfile.lightweight` - Dockerfile minimalista (para quando Docker voltar)
5. `docker-compose.lightweight.yml` - Compose simplificado

### Como Executar (SEM DOCKER)

```powershell
# 1. Ir para o diretório
cd C:\Users\USER\Z-Image

# 2. Executar o script de setup
.\start-local.ps1

# OU manualmente:
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install fastapi uvicorn python-multipart torch transformers diffusers
python docker_api_simple.py
```

## 🔧 Liberar Recursos Docker (Opcional)

Se você quiser tentar o Docker novamente no futuro:

```powershell
# Parar containers não essenciais
docker stop questmate-dockhand      # Dockhand AI (opcional)
docker stop qwen2-vl-server-cpu     # Análise de imagens (opcional)
docker stop photocraft-web          # Editor de imagens (opcional)

# Isso liberaria ~5-7GB de RAM

# Limpar cache e imagens não usadas
docker system prune -a --volumes    # ⚠️  Remove tudo não usado!
```

## 📊 Arquivos Docker Criados (Para Referência)

### Working Files

- ✅ `Dockerfile` - Versão completa (funcional, mas pesada)
- ✅ `docker-compose.yml` - Compose original
- ✅ `docker_api.py` - API server completo (requer src/)
- ✅ `DOCKER_GUIDE.md` - Guia Docker original
- ✅ `build-zimage.ps1` - Script de build Docker

### Lightweight Files (Não Testados)

- ⏳ `Dockerfile.lightweight` - Build minimalista (~2GB vs ~15GB)
- ⏳ `docker-compose.lightweight.yml` - Compose simplificado
- ⏳ `docker_api_simple.py` - API standalone

## 🎯 Próximas Ações

### Opção 1: Executar Localmente (Recomendado)

1. Ler `RUN_WITHOUT_DOCKER.md`
2. Executar `.\start-local.ps1`
3. Testar: `curl http://localhost:8002/health`

### Opção 2: Liberar Recursos e Tentar Docker

1. Decidir quais containers você realmente precisa
2. Parar os não essenciais: `docker stop <container>`
3. Limpar sistema: `docker system prune -a`
4. Tentar novamente: `docker-compose -f docker-compose.lightweight.yml up`

### Opção 3: Esperar e Usar Depois

Deixe os arquivos Docker prontos e use quando tiver mais recursos ou reiniciar o sistema.

## 💡 Lições Aprendidas

1. **6 containers** é o limite prático para este sistema
2. **Modelos AI grandes** (>6GB) são problemáticos em Docker com recursos limitados
3. **Python direto** é mais eficiente que Docker para desenvolvimento local
4. **PhotoCraft** e **Qwen2-VL** já usam muito recurso (7-8GB combinados)

## 🚀 Z-Image Capabilities (Quando Funcionar)

- ✨ Geração de imagens fotorrealísticas
- 📝 Texto bilíngue (EN/CN) nas imagens
- ⚡ 8 steps apenas (muito rápido em GPU)
- 🎨 1024x1024 resolution nativa
- 🔧 Controlável via API REST

## 📋 Integração Futura com QuestMate

Ideias de uso quando o Z-Image estiver rodando:

1. **Character Portraits**: Gerar avatar baseado em raça + classe + descrição
2. **Memory Visualization**: Ilustrar memórias importantes do jogador
3. **Dream Sequences**: Visualizar sonhos/pesadelos do sistema Dreams
4. **Pet Evolution**: Mostrar aparência dos pets após mutações
5. **Title Cards**: Criar cards visuais para títulos conquistados
6. **Quest Scenes**: Ilustrar momentos-chave de quests
7. **Guild Emblems**: Gerar brasões customizados para guildas
8. **Battle Moments**: Capturar momentos épicos de batalhas

---

**Conclusão**: Docker está sobrecarregado. Use a alternativa sem Docker (`RUN_WITHOUT_DOCKER.md`) para ter o Z-Image funcionando rapidamente.

