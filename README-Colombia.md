# OSRM Backend - Servidor de Rutas Peatonales Colombia

[![OSRM](https://img.shields.io/badge/OSRM-v6.0.0-blue.svg)](https://github.com/Project-OSRM/osrm-backend)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com/)
[![Walking](https://img.shields.io/badge/Perfil-Peatones-green.svg)](https://github.com/Project-OSRM/osrm-backend/blob/master/profiles/foot.lua)

Servidor de rutas optimizado para **peatones en Colombia** usando datos de OpenStreetMap.

## 🚀 Configuración Rápida

### Prerrequisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop) instalado
- Archivo `colombia-latest.osm.pbf`
- 2GB RAM libre, 5GB espacio disco

### Comandos de Configuración

```bash
# 0. Descargar datos de Colombia
wget http://download.geofabrik.de/south-america/colombia-latest.osm.pbf

# 1. Procesar datos (5-10 min)
docker run -t -v "${PWD}:/data" ghcr.io/project-osrm/osrm-backend osrm-extract -p /opt/foot.lua /data/colombia-latest.osm.pbf

# 2. Particionar (1-2 min)
docker run -t -v "${PWD}:/data" ghcr.io/project-osrm/osrm-backend osrm-partition /data/colombia-latest.osrm

# 3. Personalizar (30 seg)
docker run -t -v "${PWD}:/data" ghcr.io/project-osrm/osrm-backend osrm-customize /data/colombia-latest.osrm

# 4. Iniciar servidor
docker run -t -i -p 5002:5000 -v "${PWD}:/data" ghcr.io/project-osrm/osrm-backend osrm-routed --algorithm mld /data/colombia-latest.osrm
```

**⏱️ Tiempo total:** ~8-15 minutos

## 🚶 Uso del Servidor

**URL del servidor:** `http://localhost:5002`

### Ejemplos de Consultas

```bash
# Punto más cercano
curl "http://localhost:5002/nearest/v1/walking/-74.0721,4.7110"

# Ruta básica
curl "http://localhost:5002/route/v1/walking/-74.1770,4.6423;-74.0922,4.6369"

# Ruta con geometría
curl "http://localhost:5002/route/v1/walking/-74.1770,4.6423;-74.0922,4.6369?geometries=geojson"

# Matriz de distancias
curl "http://localhost:5002/table/v1/walking/-74.0721,4.7110;-74.0836,4.6361;-74.0922,4.6369"
```

## 📍 Coordenadas Principales Colombia

| Ciudad       | Coordenadas (lng, lat) |
| ------------ | ---------------------- |
| Bogotá       | `-74.0721, 4.7110`     |
| Medellín     | `-75.5636, 6.2518`     |
| Cali         | `-76.5225, 3.4516`     |
| Barranquilla | `-74.7813, 10.9639`    |
| Cartagena    | `-75.5144, 10.3910`    |

## 📏 Unidades de Medida

- **Distancia**: Metros (m) → dividir ÷ 1000 para km
- **Duración**: Segundos (s) → dividir ÷ 3600 para horas
- **Coordenadas**: Grados decimales [longitud, latitud]

### Conversión JavaScript

```javascript
// Metros a kilómetros
const km = meters / 1000;

// Segundos a horas y minutos
const hours = Math.floor(seconds / 3600);
const minutes = Math.floor((seconds % 3600) / 60);

// Velocidad promedio
const avgSpeed = meters / 1000 / (seconds / 3600); // km/h
```

## 🚨 Solución de Problemas

| Error                       | Solución                                 |
| --------------------------- | ---------------------------------------- |
| "No route found"            | Verificar coordenadas dentro de Colombia |
| "Docker daemon not running" | Iniciar Docker Desktop                   |
| Puerto ocupado              | Cambiar puerto: `-p 5003:5000`           |
| Archivos faltantes          | Ejecutar pasos 1-3 de configuración      |

## 📚 API Endpoints Completos

### 1. 🛣️ Route (Rutas)

Calcula la ruta óptima entre puntos.

**Formato:** `GET /route/v1/walking/{coordinates}`

```bash
# Ruta básica
curl "http://localhost:5002/route/v1/walking/-74.1770,4.6423;-74.0922,4.6369"

# Con instrucciones paso a paso
curl "http://localhost:5002/route/v1/walking/-74.1770,4.6423;-74.0922,4.6369?steps=true"

# Con geometría GeoJSON
curl "http://localhost:5002/route/v1/walking/-74.1770,4.6423;-74.0922,4.6369?geometries=geojson"

# Con rutas alternativas
curl "http://localhost:5002/route/v1/walking/-74.1770,4.6423;-74.0922,4.6369?alternatives=true"

# Combinando parámetros
curl "http://localhost:5002/route/v1/walking/-74.1770,4.6423;-74.0922,4.6369?steps=true&geometries=geojson&alternatives=true"

# Múltiples puntos (waypoints)
curl "http://localhost:5002/route/v1/walking/-74.1770,4.6423;-74.1000,4.6500;-74.0922,4.6369"
```

**Parámetros disponibles:**

| Parámetro           | Descripción              | Valores                       | Ejemplo                   |
| ------------------- | ------------------------ | ----------------------------- | ------------------------- |
| `steps`             | Instrucciones detalladas | `true`, `false`               | `?steps=true`             |
| `geometries`        | Formato geometría        | `polyline`, `geojson`         | `?geometries=geojson`     |
| `alternatives`      | Rutas alternativas       | `true`, `false`               | `?alternatives=true`      |
| `overview`          | Nivel detalle geometría  | `full`, `simplified`, `false` | `?overview=simplified`    |
| `continue_straight` | Forzar línea recta       | `true`, `false`               | `?continue_straight=true` |

### 2. 📍 Nearest (Punto más cercano)

Encuentra el punto más cercano en la red peatonal.

**Formato:** `GET /nearest/v1/walking/{coordinate}`

```bash
# Punto más cercano básico
curl "http://localhost:5002/nearest/v1/walking/-74.0721,4.7110"

# Múltiples puntos cercanos
curl "http://localhost:5002/nearest/v1/walking/-74.0721,4.7110?number=5"

# Diferentes ciudades
curl "http://localhost:5002/nearest/v1/walking/-75.5636,6.2518" # Medellín
curl "http://localhost:5002/nearest/v1/walking/-76.5225,3.4516" # Cali
```

**Parámetros disponibles:**

| Parámetro | Descripción            | Valores | Ejemplo     |
| --------- | ---------------------- | ------- | ----------- |
| `number`  | Cantidad de resultados | 1-100   | `?number=5` |

### 3. 📊 Table (Matriz de distancias)

Calcula matriz de distancias/duraciones entre múltiples puntos.

**Formato:** `GET /table/v1/walking/{coordinates}`

```bash
# Matriz básica (todos con todos)
curl "http://localhost:5002/table/v1/walking/-74.0721,4.7110;-74.0836,4.6361;-74.0922,4.6369"

# Solo distancias
curl "http://localhost:5002/table/v1/walking/-74.0721,4.7110;-74.0836,4.6361?annotations=distance"

# Solo duraciones
curl "http://localhost:5002/table/v1/walking/-74.0721,4.7110;-74.0836,4.6361?annotations=duration"

# Distancias y duraciones
curl "http://localhost:5002/table/v1/walking/-74.0721,4.7110;-74.0836,4.6361?annotations=distance,duration"

# Orígenes y destinos específicos
curl "http://localhost:5002/table/v1/walking/-74.0721,4.7110;-74.0836,4.6361;-74.0922,4.6369?sources=0,1&destinations=2"
```

**Parámetros disponibles:**

| Parámetro      | Descripción            | Valores                | Ejemplo                          |
| -------------- | ---------------------- | ---------------------- | -------------------------------- |
| `sources`      | Índices puntos origen  | `0,1,2...`             | `?sources=0,1`                   |
| `destinations` | Índices puntos destino | `0,1,2...`             | `?destinations=2,3`              |
| `annotations`  | Tipo de datos          | `duration`, `distance` | `?annotations=distance,duration` |

### 4. 🧭 Match (Map Matching)

Ajusta una secuencia de coordenadas GPS a la red peatonal.

**Formato:** `GET /match/v1/walking/{coordinates}`

```bash
# Map matching básico
curl "http://localhost:5002/match/v1/walking/-74.1770,4.6423;-74.1750,4.6430;-74.1730,4.6440;-74.0922,4.6369"

# Con timestamps
curl "http://localhost:5002/match/v1/walking/-74.1770,4.6423;-74.1750,4.6430?timestamps=1609459200;1609459260"

# Con pasos detallados
curl "http://localhost:5002/match/v1/walking/-74.1770,4.6423;-74.1750,4.6430?steps=true&geometries=geojson"
```

**Parámetros disponibles:**

| Parámetro    | Descripción              | Valores                   | Ejemplo                             |
| ------------ | ------------------------ | ------------------------- | ----------------------------------- |
| `steps`      | Instrucciones detalladas | `true`, `false`           | `?steps=true`                       |
| `geometries` | Formato geometría        | `polyline`, `geojson`     | `?geometries=geojson`               |
| `timestamps` | Marcas temporales        | Unix timestamps           | `?timestamps=1609459200;1609459260` |
| `radiuses`   | Radio búsqueda (metros)  | Números separados por `;` | `?radiuses=10;20;30`                |

### 5. 🚶‍♂️ Trip (Problema del Viajero)

Resuelve el problema del viajero visitante (TSP) para puntos dados.

**Formato:** `GET /trip/v1/walking/{coordinates}`

```bash
# Trip básico (ruta óptima visitando todos los puntos)
curl "http://localhost:5002/trip/v1/walking/-74.0721,4.7110;-74.0836,4.6361;-74.0922,4.6369;-74.1000,4.6500"

# Trip con regreso al origen
curl "http://localhost:5002/trip/v1/walking/-74.0721,4.7110;-74.0836,4.6361;-74.0922,4.6369?roundtrip=true"

# Definir punto de inicio y fin
curl "http://localhost:5002/trip/v1/walking/-74.0721,4.7110;-74.0836,4.6361;-74.0922,4.6369?source=first&destination=last"

# Con pasos detallados
curl "http://localhost:5002/trip/v1/walking/-74.0721,4.7110;-74.0836,4.6361;-74.0922,4.6369?steps=true&geometries=geojson"
```

**Parámetros disponibles:**

| Parámetro     | Descripción              | Valores               | Ejemplo               |
| ------------- | ------------------------ | --------------------- | --------------------- |
| `roundtrip`   | Regresar al origen       | `true`, `false`       | `?roundtrip=true`     |
| `source`      | Punto de inicio          | `first`, `any`        | `?source=first`       |
| `destination` | Punto final              | `last`, `any`         | `?destination=last`   |
| `steps`       | Instrucciones detalladas | `true`, `false`       | `?steps=true`         |
| `geometries`  | Formato geometría        | `polyline`, `geojson` | `?geometries=geojson` |

### 6. 🗺️ Tile (Tiles de vector)

Obtiene tiles de vector para visualización de mapas.

**Formato:** `GET /tile/v1/walking/tile({x},{y},{z}).mvt`

```bash
# Tile de vector específico
curl "http://localhost:5002/tile/v1/walking/tile(1171,1566,12).mvt"

# Diferentes niveles de zoom
curl "http://localhost:5002/tile/v1/walking/tile(585,783,11).mvt"  # Zoom 11
curl "http://localhost:5002/tile/v1/walking/tile(2342,3132,13).mvt" # Zoom 13
```

## 🔧 Formatos de Respuesta

### Geometrías

```bash
# Polyline (por defecto) - más compacto
curl "http://localhost:5002/route/v1/walking/-74.1770,4.6423;-74.0922,4.6369"

# GeoJSON - más legible, compatible con mapas web
curl "http://localhost:5002/route/v1/walking/-74.1770,4.6423;-74.0922,4.6369?geometries=geojson"
```

### Respuesta típica Route

```json
{
  "code": "Ok",
  "routes": [
    {
      "distance": 8234.5,        // metros
      "duration": 5940.4,        // segundos (~1.65 horas)
      "weight": 5940.4,
      "legs": [
        {
          "distance": 8234.5,
          "duration": 5940.4,
          "steps": [...],          // si steps=true
          "summary": ""
        }
      ],
      "geometry": "..."           // polyline o geojson
    }
  ],
  "waypoints": [
    {
      "location": [-74.177, 4.6423],
      "name": "Calle 63",
      "distance": 12.5
    }
  ]
}
```

## 📝 Ejemplos de Uso Común

### Planificación de Rutas Turísticas

```bash
# Ruta turística en Bogotá (Centro Histórico)
curl "http://localhost:5002/trip/v1/walking/-74.0721,4.7110;-74.0836,4.6361;-74.0922,4.6369;-74.0700,4.5980?roundtrip=true&steps=true"
```

### Análisis de Accesibilidad

```bash
# Matriz de tiempos entre puntos importantes
curl "http://localhost:5002/table/v1/walking/-74.0721,4.7110;-74.0836,4.6361;-74.0922,4.6369?annotations=duration"
```

### Seguimiento GPS

```bash
# Ajustar track GPS a red peatonal
curl "http://localhost:5002/match/v1/walking/-74.1770,4.6423;-74.1765,4.6425;-74.1760,4.6428?steps=true"
```

---

**🇨🇴 Datos: OpenStreetMap Colombia** | **📖 Docs**: [OSRM HTTP API](https://github.com/Project-OSRM/osrm-backend/blob/master/docs/http.md)
