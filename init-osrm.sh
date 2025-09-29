#!/bin/sh
set -e

DATA_FILE="/data/colombia-latest.osm.pbf"
OSRM_FILE="/data/colombia-latest.osrm"

echo "🚀 Iniciando configuración OSRM Colombia..."

# Verificar si el archivo PBF existe
if [ ! -f "$DATA_FILE" ]; then
    echo "📥 Descargando datos de Colombia..."
    wget -O "$DATA_FILE" http://download.geofabrik.de/south-america/colombia-latest.osm.pbf
    echo "✅ Descarga completada"
fi

# Verificar si ya están procesados los datos
if [ ! -f "$OSRM_FILE" ]; then
    echo "🔄 Procesando datos (5-10 min)..."
    osrm-extract -p /opt/foot.lua "$DATA_FILE"
    echo "✅ Extracción completada"
    
    echo "🔧 Particionando datos (1-2 min)..."
    osrm-partition "$OSRM_FILE"
    echo "✅ Partición completada"
    
    echo "⚙️ Personalizando datos (30 seg)..."
    osrm-customize "$OSRM_FILE"
    echo "✅ Personalización completada"
else
    echo "✅ Datos ya procesados, saltando pasos de preparación"
fi

echo "🌐 Iniciando servidor OSRM en puerto 5000..."
echo "📍 URL disponible: http://localhost:5002"
echo "🚶 Perfil: Peatones (walking)"

# Iniciar servidor
exec osrm-routed --algorithm mld "$OSRM_FILE"
