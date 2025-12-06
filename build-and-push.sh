#!/bin/bash
# ============================================================
# Build & Push Golden Image to GCP Artifact Registry
# ============================================================
# Este script construye la imagen Golden con mapas pre-procesados
# y la sube a tu Artifact Registry en GCP.
# ============================================================

set -e

# Configuración GCP
PROJECT_ID="turnkey-cyclist-480023-j5"
REGION="us-central1"
REPO_NAME="runpath-repo"
IMAGE_NAME="distance-repository"
TAG="${1:-latest}"  # Tag (default: latest)

FULL_IMAGE="$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME:$TAG"

echo "═══════════════════════════════════════════════════════════"
echo "🏗️  Building Golden Image for OSRM Backend"
echo "═══════════════════════════════════════════════════════════"
echo "📦 Image: $FULL_IMAGE"
echo "💾 Tamaño esperado: ~2GB (con mapas pre-procesados)"
echo "═══════════════════════════════════════════════════════════"

# Verificar que existan los archivos .osrm
if [ ! -f "colombia-latest.osrm" ]; then
    echo "❌ ERROR: Archivos .osrm no encontrados"
    echo ""
    echo "Debes generar los archivos primero con:"
    echo "  docker-compose up -d"
    echo "  (Espera 15 minutos a que procese los mapas)"
    echo "  docker-compose down"
    echo ""
    exit 1
fi

echo "✅ Archivos .osrm encontrados"
echo ""

# Autenticar con GCP (si es necesario)
echo "🔐 Configurando autenticación GCP..."
gcloud auth configure-docker $REGION-docker.pkg.dev --quiet

# Build de la imagen
echo ""
echo "🔨 Construyendo imagen Docker..."
echo "   (Esto puede tardar 5-10 minutos debido al tamaño de los mapas)"
echo ""
docker build \
  --platform linux/amd64 \
  --tag "$FULL_IMAGE" \
  --tag "$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME:latest" \
  .

echo ""
echo "✅ Imagen construida exitosamente"
echo ""

# Verificar tamaño de la imagen
IMAGE_SIZE=$(docker images "$FULL_IMAGE" --format "{{.Size}}")
echo "📊 Tamaño de la imagen: $IMAGE_SIZE"
echo ""

# Push al registry
echo "☁️  Subiendo imagen a Artifact Registry..."
echo "   (Esto puede tardar 10-15 minutos dependiendo de tu conexión)"
echo ""
docker push "$FULL_IMAGE"

# Si el tag no es 'latest', también pushear latest
if [ "$TAG" != "latest" ]; then
    docker push "$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME:latest"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✅ Imagen Golden subida exitosamente"
echo "═══════════════════════════════════════════════════════════"
echo "📦 Imagen: $FULL_IMAGE"
echo "📊 Tamaño: $IMAGE_SIZE"
echo ""
echo "🚀 Siguiente paso: Desplegar en GKE"
echo "   kubectl apply -f k8s/"
echo "═══════════════════════════════════════════════════════════"
