#!/usr/bin/env bash
# Levanta el stack local. Genera secretos aleatorios la primera vez: nunca se arranca con
# una contraseña publicada en el repositorio.
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "[ok] .env creado desde .env.example"
fi

# Rellena POSTGRES_PASSWORD y JWT_SECRET si están vacíos.
python3 - <<'PY'
import re
import secrets
from pathlib import Path

env = Path(".env")
text = env.read_text()
generados = []
for clave in ("POSTGRES_PASSWORD", "JWT_SECRET"):
    patron = re.compile(rf"^{clave}=(.*)$", re.MULTILINE)
    match = patron.search(text)
    if match and not match.group(1).strip():
        text = patron.sub(f"{clave}={secrets.token_urlsafe(32)}", text, count=1)
        generados.append(clave)
if generados:
    env.write_text(text)
    print("[ok] secretos generados en .env:", ", ".join(generados))
PY

# Secreto vacío o de ejemplo => el stack no arranca (mejor fallar aquí que exponer la BD).
if grep -qE '^(POSTGRES_PASSWORD|JWT_SECRET)=(change-me.*)?$' .env; then
  echo "ERROR .env tiene un secreto vacío o de ejemplo. Edita .env y vuelve a intentarlo." >&2
  exit 1
fi

# --env-file: Compose busca `.env` junto al fichero compose (infra/docker/), no en la raíz.
# Sin este flag, `${JWT_SECRET:?...}` aborta siempre aunque .env esté bien.
docker compose --env-file .env -p billka -f infra/docker/docker-compose.yml up --build

