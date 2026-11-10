#!/usr/bin/env bash
# Ejecuta los tests de JVM y FALLA si no se ha ejecutado ninguno.
#
# Motivo: `gradle test` con 0 tests termina con código 0 y da luz verde sin haber probado
# nada. Billka no tiene tests todavía, así que este script está en rojo a propósito: es el
# único sitio que puede decir "hay tests" o "no hay tests" sin mentir.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> ./gradlew test (core + fiscal-kit)"
(cd core && ./gradlew --no-daemon --console=plain test)

mapfile -t results < <(ls core/build/test-results/test/*.xml fiscal-kit/build/test-results/test/*.xml 2>/dev/null || true)

if [ "${#results[@]}" -eq 0 ]; then
  cat >&2 <<'EOF'
TEST_ROJO: no se ha ejecutado ningún test (0 ficheros de resultados).

No hay tests en el repositorio. Eso no es un fallo del script: es el estado real del
proyecto (ver tests/README.md). Este script seguirá fallando hasta que exista el primero.
EOF
  exit 1
fi

total=$(grep -ho 'tests="[0-9]*"' "${results[@]}" | sed 's/[^0-9]//g' | awk '{s+=$1} END {print s+0}')
failures=$(grep -ho 'failures="[0-9]*"' "${results[@]}" | sed 's/[^0-9]//g' | awk '{s+=$1} END {print s+0}')
errors=$(grep -ho 'errors="[0-9]*"' "${results[@]}" | sed 's/[^0-9]//g' | awk '{s+=$1} END {print s+0}')

if [ "$total" -eq 0 ]; then
  echo "TEST_ROJO: los ficheros de resultados existen pero declaran 0 tests." >&2
  exit 1
fi

echo "tests ejecutados: $total (fallos: $failures, errores: $errors)"

if [ "$failures" -ne 0 ] || [ "$errors" -ne 0 ]; then
  echo "TEST_ROJO: hay tests en rojo." >&2
  exit 1
fi

echo "TEST_OK $total"
