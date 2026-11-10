#!/usr/bin/env bash
# Restaura un dump custom (pg_dump -Fc) sobre la BD de Billka.
#
# DESTRUCTIVO: pg_restore corre con --clean --if-exists, así que borra los objetos que
# existan en la BD destino antes de recrearlos. Por eso exige dos confirmaciones:
#   1) el flag --si-borrar-todo
#   2) escribir el nombre de la base de datos (solo si hay TTY)
set -euo pipefail
cd "$(dirname "$0")/.."

COMPOSE=(docker compose --env-file .env -p billka -f infra/docker/docker-compose.yml)
FLAG="--si-borrar-todo"

uso() {
  cat >&2 <<EOF
Uso: $0 <dump> $FLAG

  <dump>  fichero creado por scripts/backup.sh (formato custom, magic PGDMP)

El flag es obligatorio porque la restauración borra los datos actuales de la BD.
EOF
  exit 1
}

[[ $# -eq 2 && "$2" == "$FLAG" ]] || uso
dump="$1"
[[ -f "$dump" ]] || { echo "ERROR no existe el fichero: $dump" >&2; exit 1; }

if [[ "$(head -c 5 "$dump")" != "PGDMP" ]]; then
  echo "ERROR $dump no es un dump custom de PostgreSQL (no empieza por PGDMP)." >&2
  echo "       Si es un .sql plano, aplícalo con psql; o genera backups con scripts/backup.sh." >&2
  exit 1
fi

[[ -f .env ]] || { echo "ERROR falta .env" >&2; exit 1; }
set -a
# shellcheck disable=SC1091
. ./.env
set +a
: "${POSTGRES_USER:?falta POSTGRES_USER}"
: "${POSTGRES_DB:?falta POSTGRES_DB}"

if [[ -t 0 ]]; then
  read -r -p "Se van a BORRAR los datos de '${POSTGRES_DB}'. Escribe el nombre de la BD: " respuesta
  [[ "$respuesta" == "$POSTGRES_DB" ]] || { echo "Cancelado: no coincide." >&2; exit 1; }
else
  echo "[aviso] sin TTY: se omite la confirmación interactiva (flag $FLAG presente)" >&2
fi

if [[ -z "$("${COMPOSE[@]}" ps -q db 2>/dev/null)" ]]; then
  echo "ERROR el contenedor billka_db no está creado; ejecuta make dev" >&2
  exit 1
fi

echo "==> restaurando $dump en $POSTGRES_DB"
# El dump entra por stdin (-T desactiva el TTY): pg_restore lee el fichero desde la entrada.
"${COMPOSE[@]}" exec -T db \
  pg_restore -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  --clean --if-exists --no-owner --no-privileges --exit-on-error --single-transaction < "$dump"

tablas=$("${COMPOSE[@]}" exec -T db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc \
  "select count(*) from information_schema.tables where table_schema = 'public'" | tr -d '[:space:]')

echo "RESTORE_OK $dump (tablas en public: ${tablas:-0})"

