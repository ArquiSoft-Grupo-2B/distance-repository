# 🚀 Deploy OSRM Distance Repository en GKE

## 📋 Requisitos Previos

### 1. Archivos `.osrm*` Generados Localmente

```powershell
# Generar mapas pre-procesados (solo la primera vez)
docker-compose up -d

# Esperar 15 minutos mientras procesa los mapas
# Puedes ver logs con: docker-compose logs -f

# Una vez completado, detener:
docker-compose down
```

### 2. Construir y Subir Imagen Golden

```powershell
# Desde el directorio distance-repository/

# Opción A: PowerShell (Windows)
.\build-and-push.ps1

# Opción B: Con tag específico
.\build-and-push.ps1 -Tag "v1.0.0"

# Opción C: Bash (Linux/Mac)
chmod +x build-and-push.sh
./build-and-push.sh
```

**Tiempos esperados:**
- **Build**: 5-10 minutos (copia ~2GB de mapas)
- **Push**: 10-15 minutos (sube a Artifact Registry)

---

## 🌐 Deploy en GKE

### Paso 1: Verificar Cluster GKE

```bash
# Configurar kubectl para tu cluster
gcloud container clusters get-credentials runpath-cluster \
  --region us-central1 \
  --project turnkey-cyclist-480023-j5

# Verificar nodos (IMPORTANTE: Necesitas nodos con ≥4GB RAM)
kubectl get nodes -o wide
```

### Paso 2: Aplicar Manifiestos

```bash
# Desde distance-repository/k8s/

# Aplicar deployment y service
kubectl apply -f distance_deployment.yaml
kubectl apply -f distance_service.yaml
```

### Paso 3: Monitorear Despliegue

```bash
# Ver estado de pods (ESPERA 2-3 minutos)
kubectl get pods -l app=distance-app -w

# Ver logs en tiempo real
kubectl logs -f deployment/distance-deployment

# Describir pod (útil si falla)
kubectl describe pod -l app=distance-app
```

**Estados Esperados:**
1. `Pending` → `ContainerCreating` (2-5 min: descarga imagen de 2GB)
2. `Running` pero `0/1 Ready` (60-90s: carga mapas en RAM)
3. `Running` y `1/1 Ready` ✅ (servidor listo)

---

## 🔍 Troubleshooting

### ❌ Pod se queda en `ImagePullBackOff`

**Causa:** No puede descargar la imagen.

```bash
# Verificar que la imagen existe
gcloud artifacts docker images list \
  us-central1-docker.pkg.dev/turnkey-cyclist-480023-j5/runpath-repo

# Verificar permisos del Service Account del cluster
```

**Solución:**
```bash
# Dar permisos al cluster para leer Artifact Registry
gcloud projects add-iam-policy-binding turnkey-cyclist-480023-j5 \
  --member=serviceAccount:PROJECT_NUMBER-compute@developer.gserviceaccount.com \
  --role=roles/artifactregistry.reader
```

### ❌ Pod en `CrashLoopBackOff` o `OOMKilled`

**Causa:** Nodo sin RAM suficiente.

```bash
# Ver recursos del nodo
kubectl top nodes

# Ver eventos del pod
kubectl describe pod -l app=distance-app | grep -A 10 Events
```

**Solución:**
```bash
# Opción A: Escalar nodos (si pool tiene autoscaling)
# Opción B: Aumentar tamaño de nodos (e2-standard-4 mínimo)
gcloud container clusters resize runpath-cluster \
  --node-pool default-pool \
  --num-nodes 3 \
  --region us-central1
```

### ❌ Pod `Running` pero `0/1 Ready` permanente

**Causa:** ReadinessProbe falla.

```bash
# Ver logs del contenedor
kubectl logs -l app=distance-app --tail=50

# Testear manualmente el endpoint
kubectl port-forward deployment/distance-deployment 5000:5000

# En otra terminal:
curl http://localhost:5000/nearest/v1/walking/-74.0721,4.7110
```

**Si el curl responde pero K8s dice Not Ready:**
→ Aumenta `initialDelaySeconds` en `readinessProbe` (edita `distance_deployment.yaml`)

---

## ✅ Verificación de Funcionamiento

### 1. Desde dentro del cluster

```bash
# Crear pod de prueba
kubectl run test-osrm --image=curlimages/curl --rm -it --restart=Never -- sh

# Dentro del pod:
curl http://distance-service:5000/nearest/v1/walking/-74.0721,4.7110
```

### 2. Port-forward para pruebas locales

```bash
# Exponer servicio localmente
kubectl port-forward service/distance-service 5002:5000

# Probar desde tu máquina
curl http://localhost:5002/route/v1/walking/-74.1770,4.6423;-74.0922,4.6369?geometries=geojson
```

### 3. Desde otros servicios (Service Discovery)

```yaml
# En otros deployments:
env:
  - name: OSRM_URL
    value: "http://distance-service:5000"  # DNS interno de K8s
```

---

## 📊 Monitoreo Continuo

```bash
# Ver recursos consumidos (requiere metrics-server)
kubectl top pods -l app=distance-app

# Ver logs de los últimos 10 minutos
kubectl logs -l app=distance-app --since=10m --tail=100

# Ver eventos del deployment
kubectl describe deployment distance-deployment
```

---

## 🔄 Actualizar Imagen

```powershell
# 1. Rebuild con nuevo tag
.\build-and-push.ps1 -Tag "v1.1.0"

# 2. Actualizar deployment
kubectl set image deployment/distance-deployment \
  distance-container=us-central1-docker.pkg.dev/turnkey-cyclist-480023-j5/runpath-repo/distance-repository:v1.1.0

# 3. Ver rollout
kubectl rollout status deployment/distance-deployment

# 4. Rollback si falla
kubectl rollout undo deployment/distance-deployment
```

---

## 🗑️ Limpiar Recursos

```bash
# Eliminar deployment y service
kubectl delete -f k8s/

# Verificar
kubectl get all -l app=distance-app
```

---

## 📈 Consideraciones de Reliability

**Configuración actual (ajustada por recursos limitados):**
- **1 réplica** (reducido de 2 por RAM insuficiente en nodos)
- **Recursos ajustados**: 1.5Gi RAM / 300m CPU (mínimo funcional)
- **ReadinessProbe**: Asegura que solo reciben tráfico pods listos
- **LivenessProbe**: Reinicia automáticamente pods que se cuelgan
- **Límites**: 2Gi RAM / 1 CPU (evita OOMKilled)

**Memoria requerida:**
- 1 pod × 2Gi = **2Gi mínimo** en un nodo
- Para 2 réplicas (HA): Nodos `e2-standard-4` (4 vCPU, 16GB RAM)

**Monitoreo:**
```bash
# Ver consumo real
kubectl top pod -l app=distance-app

# Si RAM > 1.8Gi: Riesgo de OOMKilled
# Solución: Escalar nodos o reducir carga
```

---

## 🎯 Endpoints Disponibles

Una vez desplegado, el servicio está disponible en:

```
http://distance-service:5000  # Dentro del cluster (DNS interno)
```

**Rutas principales:**
- `/nearest/v1/walking/{lon},{lat}` - Punto más cercano
- `/route/v1/walking/{coords}` - Calcular ruta
- `/table/v1/walking/{coords}` - Matriz de distancias

**Ejemplo desde otro pod:**
```bash
curl "http://distance-service:5000/route/v1/walking/-74.1770,4.6423;-74.0922,4.6369?geometries=geojson"
```
