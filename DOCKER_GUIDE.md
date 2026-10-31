# Z-Image Docker Guide

## 🎨 O que é Z-Image?

**Z-Image** é um modelo de geração de imagens AI de última geração com **6 bilhões de parâmetros**.

### Capacidades:
- ✅ **Geração fotorealística** de alta qualidade
- ✅ **Texto bilíngue** (Inglês e Chinês)
- ✅ **Geração criativa** em múltiplos estilos
- ✅ **Rápido**: sub-segundo em GPUs H800, 8 passos de inferência
- ✅ **Eficiente**: Roda em 16GB VRAM

### Variantes:
1. **Z-Image-Turbo** (padrão neste Docker) - 8 steps, ultra-rápido
2. **Z-Image** - 50 steps, mais criativo
3. **Z-Image-Edit** - Edição de imagens

---

## 🚀 Quick Start

### 1. Build da Imagem Docker

```powershell
cd C:\Users\USER\Z-Image
.\build-zimage.ps1
```

Ou com start automático:
```powershell
.\build-zimage.ps1 -Start
```

### 2. Iniciar o Servidor

```powershell
docker-compose up -d
```

### 3. Aguardar Download do Modelo

Na primeira vez, o modelo será baixado (~12 GB). Isso leva 10-30 minutos dependendo da conexão.

Monitorar:
```powershell
docker logs zimage-server -f
```

### 4. Testar a API

```powershell
curl http://localhost:8002/health
```

---

## 📡 API Endpoints

### Health Check
```bash
GET http://localhost:8002/health
```

### Model Info
```bash
GET http://localhost:8002/info
```

### Generate Image
```bash
POST http://localhost:8002/generate

Params:
- prompt (required): Text description
- width (optional): 512-2048, default 1024
- height (optional): 512-2048, default 1024
- num_inference_steps (optional): 4-50, default 8
- guidance_scale (optional): 0.0 for Turbo
- seed (optional): For reproducibility
```

### Generate Batch
```bash
POST http://localhost:8002/generate-batch

Params:
- prompts: List of text prompts (max 10)
- width, height, num_inference_steps, seed
```

---

## 🧪 Testes

### Via curl (PowerShell)

```powershell
# Health check
curl http://localhost:8002/health

# Generate image
curl -X POST "http://localhost:8002/generate" `
  -F "prompt=A beautiful sunset over mountains" `
  -F "width=1024" `
  -F "height=1024" `
  -o generated.png
```

### Via Python

```python
import requests

# Generate image
response = requests.post(
    "http://localhost:8002/generate",
    data={
        "prompt": "A futuristic cityscape at night with neon lights",
        "width": 1024,
        "height": 1024,
        "seed": 42
    }
)

if response.status_code == 200:
    with open("output.png", "wb") as f:
        f.write(response.content)
    print("Image saved!")
else:
    print(f"Error: {response.status_code}")
```

### Via Browser

Abra: **http://localhost:8002/docs**

Interface Swagger interativa para testar todos os endpoints!

---

## 🎨 Exemplos de Prompts

### Fotorealístico
```
A professional portrait of a young woman with long brown hair, 
wearing a white shirt, soft natural lighting, shallow depth of field, 
photorealistic, 8K resolution
```

### Artístico
```
Oil painting of a serene lake surrounded by autumn trees, 
golden hour lighting, impressionist style, vibrant colors
```

### Fantasia
```
Epic fantasy castle on a floating island in the clouds, 
dramatic lighting, magical atmosphere, highly detailed, 
concept art style
```

### Sci-Fi
```
Futuristic cyberpunk city at night, neon signs in Chinese and English, 
flying cars, rain-soaked streets reflecting lights, cinematic composition
```

---

## 🔧 Configuração

### Variáveis de Ambiente

Edite `docker-compose.yml`:

```yaml
environment:
  - MODEL_NAME=Tongyi-MAI/Z-Image-Turbo  # ou Z-Image
  - CACHE_DIR=/cache
  - PORT=8002
  - ZIMAGE_ATTENTION=_native_flash  # ou _flash_3 com GPU H100
```

### GPU Support

Para usar GPU NVIDIA, descomente no `docker-compose.yml`:

```yaml
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: 1
          capabilities: [gpu]
```

Então:
```powershell
docker-compose up -d --force-recreate
```

---

## 📊 Performance

### CPU (Padrão)
- **Tempo por imagem**: 60-120 segundos
- **RAM necessária**: 8GB+
- **Qualidade**: Excelente

### GPU (NVIDIA)
- **RTX 3090**: ~5-10 segundos
- **RTX 4090**: ~3-5 segundos
- **H100/H800**: < 1 segundo! ⚡
- **VRAM necessária**: 16GB+

---

## 🐳 Comandos Docker

### Start/Stop
```powershell
docker-compose up -d      # Start
docker-compose down       # Stop
docker-compose restart    # Restart
```

### Logs
```powershell
docker-compose logs -f    # Follow logs
docker logs zimage-server --tail 50  # Last 50 lines
```

### Status
```powershell
docker-compose ps
docker ps --filter "name=zimage"
```

### Cleanup
```powershell
# Remove container
docker-compose down

# Remove image também
docker-compose down --rmi all

# Remove volume (apaga modelo baixado!)
docker-compose down -v
```

---

## 💾 Armazenamento

### Volumes

O modelo é armazenado em:
```
Volume: zimage-models
Path: /cache dentro do container
Tamanho: ~12 GB
```

### Espaço Necessário

- **Imagem Docker**: ~8 GB
- **Modelo Z-Image-Turbo**: ~12 GB
- **Total**: ~20 GB

---

## 🔗 Integração com QuestMate

### Gerar Imagens de Personagens

```java
// No backend do QuestMate
@POST
@Path("/character/generate-avatar")
public Response generateAvatar(@QueryParam("description") String description) {
    try {
        // Chama Z-Image
        WebClient client = WebClient.create();
        
        FormData formData = new FormData();
        formData.append("prompt", description);
        formData.append("width", "1024");
        formData.append("height", "1024");
        formData.append("seed", String.valueOf(System.currentTimeMillis()));
        
        byte[] imageBytes = client.post()
            .uri("http://zimage-server:8002/generate")
            .body(BodyInserters.fromMultipartData(formData))
            .retrieve()
            .bodyToMono(byte[].class)
            .block();
        
        // Salvar e retornar URL
        String url = saveToStorage(imageBytes);
        return Response.ok(Map.of("imageUrl", url)).build();
        
    } catch (Exception e) {
        return Response.status(500).entity(e.getMessage()).build();
    }
}
```

### Frontend Integration

```typescript
// No frontend do QuestMate
async function generateCharacterArt(prompt: string): Promise<string> {
  const formData = new FormData();
  formData.append('prompt', prompt);
  formData.append('width', '1024');
  formData.append('height', '1024');
  
  const response = await fetch('http://localhost:8002/generate', {
    method: 'POST',
    body: formData
  });
  
  if (!response.ok) {
    throw new Error('Generation failed');
  }
  
  const blob = await response.blob();
  return URL.createObjectURL(blob);
}
```

---

## 🆘 Troubleshooting

### Container não inicia
```powershell
docker logs zimage-server
```

### Modelo não baixa
Verifique conexão com internet e espaço em disco.

### Out of Memory
- Reduza tamanho da imagem (512x512)
- Feche outros containers
- Aumente RAM do Docker Desktop

### Porta 8002 ocupada
Mude no `docker-compose.yml`:
```yaml
ports:
  - "8003:8002"  # usar 8003
```

---

## 📚 Recursos

- **Site Oficial**: https://tongyi-mai.github.io/Z-Image-blog/
- **Hugging Face**: https://huggingface.co/Tongyi-MAI/Z-Image-Turbo
- **Paper**: https://arxiv.org/abs/2511.22699
- **Gallery**: https://modelscope.cn/studios/Tongyi-MAI/Z-Image-Gallery/summary

---

**Pronto para gerar imagens incríveis! 🎨✨**
