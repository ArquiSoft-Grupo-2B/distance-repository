# Makefile para OSRM Colombia
.PHONY: help up down logs clean setup test

# Variables
COMPOSE_FILE = docker-compose.yml
SERVICE_NAME = osrm-colombia

help: ## Mostrar ayuda
	@echo "🇨🇴 OSRM Colombia - Comandos disponibles:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

up: ## Iniciar servidor OSRM (docker-compose up)
	@echo "🚀 Iniciando servidor OSRM Colombia..."
	docker-compose -f $(COMPOSE_FILE) up -d
	@echo "✅ Servidor iniciado en http://localhost:5002"

down: ## Detener servidor OSRM
	@echo "🛑 Deteniendo servidor OSRM..."
	docker-compose -f $(COMPOSE_FILE) down

logs: ## Ver logs del servidor
	docker-compose -f $(COMPOSE_FILE) logs -f $(SERVICE_NAME)

clean: ## Limpiar datos procesados (mantiene .osm.pbf)
	@echo "🧹 Limpiando archivos procesados..."
	rm -f colombia-latest.osrm*
	@echo "✅ Archivos .osrm* eliminados"

setup: ## Descargar datos y preparar todo
	@echo "📥 Descargando datos de Colombia si no existen..."
	@if [ ! -f "colombia-latest.osm.pbf" ]; then \
		wget http://download.geofabrik.de/south-america/colombia-latest.osm.pbf; \
	fi
	@echo "✅ Setup completado"

test: ## Probar conexión al servidor
	@echo "🧪 Probando servidor OSRM..."
	@curl -s "http://localhost:5002/nearest/v1/walking/-74.0721,4.7110" | jq '.code' || echo "❌ Servidor no disponible"

restart: down up ## Reiniciar servidor

status: ## Ver estado del contenedor
	docker-compose -f $(COMPOSE_FILE) ps
