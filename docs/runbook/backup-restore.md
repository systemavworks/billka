# Backups y PITR

## Comandos

```bash
make backup                                  # pg_dump -Fc -> backups/billka_<fecha>.dump
make restore F=backups/billka_<fecha>.dump   # destructivo, pide confirmación
```

`scripts/backup.sh` no declara `BACKUP_OK` hasta que `pg_restore --list` puede leer el fichero:
un dump ilegible no es un backup. `scripts/restore.sh` exige el flag `--si-borrar-todo`, comprueba
el magic `PGDMP` (rechaza `.sql` planos) y, si hay terminal, hay que escribir el nombre de la BD.
El restore corre con `--clean --if-exists --single-transaction --exit-on-error`: o queda entero,
o no queda.

Los scripts pasan `--env-file .env` porque Compose busca `.env` junto al fichero compose
(`infra/docker/`), no en la raíz del repositorio.

## Mínimos desde primer piloto

- Backup diario.
- Copia fuera de la caja (un dump en el mismo disco no es un backup: es una copia del error).
- **Prueba de restore** periódica, no solo el backup. Un backup que nunca se restaura es una
  hipótesis.
- Registro `RESTORE_OK` con la fecha, el dump usado y el número de tablas restauradas (lo imprime
  `scripts/restore.sh`).
- Guardar el `sha256` del dump junto a la copia (`backup.sh` lo imprime) para detectar ficheros
  truncados en tránsito.
- WAL/PITR si el volumen y la criticidad lo justifican: con facturación emitida, un `pg_dump`
  diario deja hasta 24 h de pérdida, y esas 24 h son facturas con número asignado.

## Estado

Probado el 2026-11-10 contra el `billka_db` real: tabla de prueba → backup (1.620 B, legible por
`pg_restore`) → `DROP TABLE` → restore → dato recuperado. Los caminos de error también se
probaron: sin flag, con un `.sql` plano y con la BD parada; los tres fallan con mensaje explícito.

Pendiente: automatizar el backup (cron/systemd timer), copia fuera de la caja, retención y PITR.

