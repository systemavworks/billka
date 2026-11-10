#!/usr/bin/env bash
set -euo pipefail
echo "Deploy Billka pendiente."
echo "No desplegar junto a Komanda sin revisar:"
echo "  - puertos"
echo "  - volumen Postgres"
echo "  - backups"
echo "  - secretos"
echo "  - frontera SIF"
exit 1
