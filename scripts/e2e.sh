#!/usr/bin/env bash
# Prueba end-to-end (emitir → QR → cotejo → cadena): PENDIENTE y por tanto falla.
#
# Antes este script imprimía "E2E_SCAFFOLD_OK" y salía con 0 sin ejecutar ningún flujo. En un
# producto fiscal, un verde falso en E2E es el peor sitio donde puede aparecer.
set -euo pipefail
cat >&2 <<'EOF'
E2E_NO_IMPLEMENTADO

No hay flujo que recorrer: core no tiene endpoints, no hay esquema y fiscal-kit está vacío
(ver README de cada módulo). Este script fallará hasta que exista el primer flujo real, y
solo entonces devolverá 0.
EOF
exit 1

