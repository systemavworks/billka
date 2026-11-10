#!/usr/bin/env bash
# Datos de demostración: PENDIENTE y por tanto falla.
#
# Antes este script imprimía "SEED_SCAFFOLD_OK" y terminaba con 0 sin sembrar nada. Un guion
# que dice OK sin hacer su trabajo es peor que no tenerlo: hace creer que hay datos.
# Existirá cuando exista el esquema (migraciones de Etapa C) y datos demo reales.
set -euo pipefail
cat >&2 <<'EOF'
SEED_NO_IMPLEMENTADO

No hay nada que sembrar: la BD no tiene esquema (0 migraciones en
core/src/main/resources/db/migration/). Este script se implementará en la Etapa C, junto con
las migraciones, y fallará hasta entonces.
EOF
exit 1

