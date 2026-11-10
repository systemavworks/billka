#!/usr/bin/env bash
# Valida los contratos de eventos. Argumentos: --draft | --lock (ver contracts/check.py)
set -euo pipefail
cd "$(dirname "$0")/.."
exec python3 contracts/check.py "$@"

