# ============================================================
# Build & Push Golden Image to GCP Artifact Registry (PowerShell)
# ============================================================
# Script de PowerShell para Windows
# Construye y sube la imagen Golden a Artifact Registry
# ============================================================

param(
    [string]$Tag = "latest"
)

$ErrorActionPreference = "Stop"

# Configuración GCP
$PROJECT_ID = "turnkey-cyclist-480023-j5"
$REGION = "us-central1"
$REPO_NAME = "runpath-repo"
$IMAGE_NAME = "distance-repository"

$FULL_IMAGE = "$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/${IMAGE_NAME}:$Tag"
$LATEST_IMAGE = "$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/${IMAGE_NAME}:latest"

Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "Building Golden Image for OSRM Backend" -ForegroundColor Yellow
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "Image: $FULL_IMAGE" -ForegroundColor White
Write-Host "Tamano esperado: ~2GB (con mapas pre-procesados)" -ForegroundColor White
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""

# Verificar archivos .osrm
if (-not (Test-Path "colombia-latest.osrm")) {
    Write-Host "ERROR: Archivos .osrm no encontrados" -ForegroundColor Red
    Write-Host ""
    Write-Host "Debes generar los archivos primero con:" -ForegroundColor Yellow
    Write-Host "  docker-compose up -d" -ForegroundColor White
    Write-Host "  (Espera 15 minutos a que procese los mapas)" -ForegroundColor Gray
    Write-Host "  docker-compose down" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host "Archivos .osrm encontrados" -ForegroundColor Green
Write-Host ""

# Autenticar con GCP
Write-Host "Configurando autenticacion GCP..." -ForegroundColor Yellow
gcloud auth configure-docker "$REGION-docker.pkg.dev" --quiet

# Build de la imagen
Write-Host ""
Write-Host "Construyendo imagen Docker..." -ForegroundColor Yellow
Write-Host "   (Esto puede tardar 5-10 minutos debido al tamano de los mapas)" -ForegroundColor Gray
Write-Host ""

docker build `
  --platform linux/amd64 `
  --tag "$FULL_IMAGE" `
  --tag "$LATEST_IMAGE" `
  .

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR al construir la imagen" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Imagen construida exitosamente" -ForegroundColor Green
Write-Host ""

# Verificar tamaño
$imageInfo = docker images "$FULL_IMAGE" --format "{{.Size}}"
Write-Host "Tamano de la imagen: $imageInfo" -ForegroundColor Cyan
Write-Host ""

# Push al registry
Write-Host "Subiendo imagen a Artifact Registry..." -ForegroundColor Yellow
Write-Host "   (Esto puede tardar 10-15 minutos dependiendo de tu conexion)" -ForegroundColor Gray
Write-Host ""

docker push "$FULL_IMAGE"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR al subir la imagen con tag $Tag" -ForegroundColor Red
    exit 1
}

# Push latest si es necesario
if ($Tag -ne "latest") {
    docker push "$LATEST_IMAGE"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR al subir la imagen latest" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "Imagen Golden subida exitosamente" -ForegroundColor Green
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "Imagen: $FULL_IMAGE" -ForegroundColor White
Write-Host "Tamano: $imageInfo" -ForegroundColor White
Write-Host ""
Write-Host "Siguiente paso: Desplegar en GKE" -ForegroundColor Yellow
Write-Host "   kubectl apply -f k8s/" -ForegroundColor White
Write-Host "=============================================================" -ForegroundColor Cyan
