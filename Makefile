.DEFAULT_GOAL := help
.PHONY: help dev down logs build test contracts contracts-draft seed backup restore e2e clean tree

COMPOSE := docker compose $(if $(wildcard .env),--env-file .env,) -p billka -f infra/docker/docker-compose.yml

help:
	@echo "Billka · comandos"
	@echo ""
	@echo "  make dev              Levanta el stack Docker (genera secretos en .env si faltan)"
	@echo "  make down             Para el stack Billka"
	@echo "  make logs             Logs del stack"
	@echo "  make build            Compila core + fiscal-kit (Gradle 8.10, JDK 21)"
	@echo "  make test             Tests JVM; ROJO si no hay ninguno (hoy: 0 tests)"
	@echo "  make contracts        Contratos EN ESTRICTO: exige schemas congelados (hoy en rojo)"
	@echo "  make contracts-draft  Valida los contratos en modo borrador (hoy en verde)"
	@echo "  make seed             Datos demo; pendiente hasta que exista esquema (hoy falla)"
	@echo "  make backup           pg_dump -Fc a backups/"
	@echo "  make restore F=...    Restaura un dump (operación destructiva, pide confirmación)"
	@echo "  make e2e              Flujo completo emisión→QR→cotejo→cadena (hoy falla)"
	@echo "  make tree             Árbol resumido"
	@echo "  make clean            Borra artefactos de build"

dev:
	@./scripts/dev.sh

down:
	@$(COMPOSE) down

logs:
	@$(COMPOSE) logs -f --tail=100

build:
	@cd core && ./gradlew --no-daemon --console=plain build

test:
	@./scripts/test.sh

contracts:
	@./scripts/check-contracts.sh

contracts-draft:
	@./scripts/check-contracts.sh --draft

seed:
	@./scripts/seed-demo.sh

backup:
	@./scripts/backup.sh

restore:
	@if [ -z "$(F)" ]; then echo "Uso: make restore F=backups/billka_YYYYMMDD_HHMMSS.dump"; exit 1; fi
	@./scripts/restore.sh "$(F)"

e2e:
	@./scripts/e2e.sh

tree:
	@find . -maxdepth 4 -type d \( -name .git -o -name node_modules -o -name build -o -name .gradle \) -prune -o -type d -print | sort

clean:
	@rm -rf core/build fiscal-kit/build web/.next web/node_modules/.cache

