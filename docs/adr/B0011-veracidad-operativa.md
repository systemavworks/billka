# ADR B0011 · Veracidad operativa: nada dice OK sin hacerlo

**Estado**: Aceptado · **Fecha**: 2026-11-10

## Contexto

La auditoría del 9-nov-2026 encontró que el repositorio **mentía sobre su propio estado**, no en
la documentación sino en el código que se ejecuta:

- 106 ficheros `.kt` de dos líneas que contenían `export {};` (TypeScript en un proyecto Kotlin,
  no compilaban) y 10 migraciones SQL vacías: un árbol profundamente vacío con número de
  ficheros de un producto grande.
- `scripts/seed-demo.sh` y `scripts/e2e.sh` imprimían `SEED_SCAFFOLD_OK` / `E2E_SCAFFOLD_OK` y
  salían con **0** sin sembrar ni probar nada.
- `scripts/backup.sh` declaraba `BACKUP_OK` sin verificar el fichero producido.
- `docker-compose.yml` usaba `${POSTGRES_PASSWORD:-change-me-now}`: no es un placeholder, es una
  **contraseña funcional**. El stack arrancaba con credenciales publicadas en el repositorio.
- Los dos workflows de `.github/workflows/` eran un `# TODO` de una línea: no había CI.
- `contracts/check.py` decía validar con `format: date-time` cuando `jsonschema` **ignora** ese
  formato si no está instalado el paquete opcional `rfc3339-validator`. Un schema que dice
  `date-time` aceptaba la cadena `"mañana"`.

En un producto fiscal no existe el daño menor: un E2E en verde que no prueba nada, un backup que
no se puede restaurar o una BD con contraseña conocida se descubren en la auditoría, no en el CI.

## Decisión

Regla única: **si un artefacto no hace su trabajo, falla o no existe**. Nunca dice OK.

1. Se borra todo lo que aparenta ser código y no lo es. Un árbol vacío dice la verdad.
2. Scripts pendientes (`seed-demo.sh`, `e2e.sh`) terminan con `exit 1` y explican por qué.
   `scripts/deploy.sh` sigue abortando: no hay destino ni licencia de despliegue.
3. `scripts/test.sh` cuenta los tests ejecutados en los XML de JUnit y falla si son **0**.
   `gradle test` sin tests devuelve 0: ese verde no se acepta.
4. Secretos: `${VAR:?mensaje}` en `docker-compose.yml` para `POSTGRES_PASSWORD` y `JWT_SECRET`.
   `.env.example` los deja **vacíos**; `make dev` genera valores aleatorios la primera vez.
5. `scripts/backup.sh` produce `pg_dump -Fc` y verifica con `pg_restore --list` que el fichero
   es legible antes de declarar `BACKUP_OK`. `scripts/restore.sh` exige `--si-borrar-todo`, el
   magic `PGDMP` y escribir el nombre de la BD; después informa de las tablas restauradas.
6. Contratos: `x-status: draft` es explícito; el modo estricto de `check.py` **falla** mientras
   queden borradores, y `--lock` no congela borradores. `date-time` se valida con la biblioteca
   estándar (RFC 3339 con offset obligatorio), sin depender de un paquete opcional.
7. CI real (`.github/workflows/ci.yml`, `contracts.yml`). `tests` y `contracts-frozen` están en
   rojo a propósito y está escrito en el workflow por qué.

## Consecuencias

- `make test`, `make contracts`, `make seed` y `make e2e` están **en rojo hoy**, y es correcto:
  el repositorio no tiene tests, no tiene contratos congelados y no tiene flujos que ejecutar.
- Cada rojo tiene un motivo escrito y una condición de salida objetiva. Un verde, en cambio,
  exige que alguien haya escrito el test, congelado el contrato o implementado el flujo.
- Coste asumido: el CI nace en rojo. Se acepta porque un CI verde que no prueba nada cuesta más
  caro el día que hay que demostrar algo ante la AEAT.
