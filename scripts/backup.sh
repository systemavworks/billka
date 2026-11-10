#!/usr/bin/env bash
# Backup lógico de la BD de Billka.
# Formato custom (-Fc): comprimido, restaurable con pg_restore y verificable con --list.
# Un `.sql` plano de pg_dump no se puede verificar sin aplicarlo, así que no se usa.
set -euo pipefail
cd "$(dirname "$0")/.."

COMPOSE=(docker compose --env-file .env -p billka -f infra/docker/docker-compose.yml)

if [[ ! -f .env ]]; then
  echo "ERROR falta .env; ejecuta make dev o copia .env.example" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1091
. ./.env
set +a

: "${POSTGRES_USER:?falta POSTGRES_USER}"
: "${POSTGRES_DB:?falta POSTGRES_DB}"

if [[ -z "$("${COMPOSE[@]}" ps -q db 2>/dev/null)" ]]; then
  echo "ERROR el contenedor billka_db no está creado; ejecuta make dev" >&2
  exit 1
fi

mkdir -p backups
stamp=$(date +%Y%m%d_%H%M%S)
out="backups/billka_${stamp}.dump"

"${COMPOSE[@]}" exec -T db pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc > "$out"

size=$(wc -c < "$out")
if [[ "$size" -lt 100 ]]; then
  echo "BACKUP_FALLIDO: el dump son $size bytes (¿BD vacía o parada?)" >&2
  rm -f "$out"
  exit 1
fi

# El dump debe ser legible por pg_restore: si no, no es un backup, es un fichero.
if ! "${COMPOSE[@]}" exec -T db pg_restore --list < "$out" > /dev/null; then
  echo "BACKUP_FALLIDO: pg_restore no puede leer $out" >&2
  exit 1
fi

echo "BACKUP_OK $out ($size bytes, sha256 $(sha256sum "$out" | cut -d' ' -f1))"
echo "Recordatorio: copia fuera de la caja y prueba un restore (docs/runbook/backup-restore.md)."

