# 🚀 Comandos de Deploy - Distance Repository

## Paso 1: Build & Push Imagen

```powershell
# Autenticar con GCP
gcloud auth login
gcloud config set project turnkey-cyclist-480023-j5
gcloud auth configure-docker us-central1-docker.pkg.dev

# Build & Push
.\build-and-push.ps1
```

## Paso 2: Deploy en GKE

```bash
# Configurar kubectl
gcloud container clusters get-credentials runpath-cluster --region us-central1 --project turnkey-cyclist-480023-j5

# Aplicar manifiestos
kubectl apply -f k8s/distance_deployment.yaml
kubectl apply -f k8s/distance_service.yaml

# Ver estado (espera 2-3 min)
kubectl get pods -l app=distance-app -w
```

## Paso 3: Verificar

```bash
# Estado y consumo
kubectl get pods -l app=distance-app
kubectl top pod -l app=distance-app

# Logs
kubectl logs -l app=distance-app --tail=50

# Test desde otro pod
kubectl run test-curl --image=curlimages/curl --rm -it --restart=Never -- curl -s http://distance-service:5000/nearest/v1/walking/-74.0721,4.7110
```

## ⚙️ Configuración Final

- **Réplicas:** 1 (ajustado por RAM limitada en nodos)
- **RAM:** 1.5Gi request / 2Gi limit
- **CPU:** 300m request / 1000m limit
- **Service:** `distance-service:5000` (ClusterIP)

## 📊 Monitoreo

```bash
# Ver recursos disponibles en cluster
kubectl top nodes

# Ver consumo del pod
kubectl top pod -l app=distance-app

# Si da OOMKilled, escalar nodos:
gcloud container clusters resize runpath-cluster --num-nodes=3 --region=us-central1
```
