#!/bin/sh
# ============================================================
# GOLDEN IMAGE: Script simplificado sin procesamiento
# ============================================================
# Este script SOLO arranca el servidor OSRM.
# Los archivos .osrm ya están procesados y copiados en la imagen.
# ============================================================

set -e

OSRM_FILE="/data/colombia-latest.osrm"

echo "═══════════════════════════════════════════════════════════"
echo "🚀 OSRM Backend - Golden Image (Pre-procesado)"
echo "═══════════════════════════════════════════════════════════"

# Verificar que los archivos .osrm existan (crítico)
if [ ! -f "$OSRM_FILE" ]; then
    echo "❌ ERROR CRÍTICO: Archivos .osrm no encontrados en /data"
    echo "   La imagen Golden no contiene mapas pre-procesados."
    echo "   Verifica que 'COPY colombia-latest.osrm* /data/' funcionó."
    exit 1
fi

echo "✅ Archivos .osrm verificados en /data"
echo "📊 Cargando mapas en memoria (~30-60 segundos)..."
echo "🌐 Puerto: 5000 (interno)"
echo "🚶 Perfil: Peatones (walking)"
echo "🧮 Algoritmo: MLD (Multi-Level Dijkstra)"
echo "═══════════════════════════════════════════════════════════"

# Iniciar servidor OSRM (sin procesamiento previo)
exec osrm-routed --algorithm mld "$OSRM_FILE"
