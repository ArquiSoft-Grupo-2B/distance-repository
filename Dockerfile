# ============================================================
# GOLDEN IMAGE STRATEGY: Imagen pesada (~2GB) pero arranque rápido (<60s)
# ============================================================
# Esta estrategia pre-procesa los mapas de Colombia y los embebe en la imagen.
# Ventajas: Sin delay en arranque, pods auto-escalables instantáneamente
# Desventajas: Imagen pesada, actualizar mapas requiere rebuild completo
# ============================================================

FROM ghcr.io/project-osrm/osrm-backend:latest

WORKDIR /data

# Instalamos curl para healthchecks de Kubernetes
RUN apk add --no-cache curl

# Copiamos SOLO los archivos .osrm* procesados (~2GB)
# IMPORTANTE: Estos archivos deben existir localmente (generados con docker-compose)
COPY colombia-latest.osrm* /data/

# Script simplificado: Solo arranca el servidor (sin procesamiento)
COPY init-osrm.sh /init-osrm.sh
RUN chmod +x /init-osrm.sh

# Puerto interno de OSRM
EXPOSE 5000

# Healthcheck para Docker (opcional, Kubernetes usa sus propios probes)
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:5000/nearest/v1/walking/-74.0721,4.7110 || exit 1

# Arranca servidor (sin procesamiento, mapas ya en /data)
ENTRYPOINT ["/bin/sh", "/init-osrm.sh"]