# tests

Estado: **sin tests reales** (los 5 ficheros que había eran `TODO` y se borraron los 2 `.kt`
que no compilaban, 10-nov-2026). `make test` falla a propósito mientras no haya ninguno:
sin rojo no hay verde.

`make test` ejecuta `scripts/test.sh`, que corre `./gradlew test` y **cuenta** los tests en los
XML de JUnit (`core/build/test-results/test/*.xml`). Si son 0, sale con 1 aunque Gradle haya
dicho `BUILD SUCCESSFUL`: `gradle test` sin tests devuelve 0 y ese verde es una mentira.


## Qué va aquí

| Ruta | Tipo | Se ejecuta con |
|---|---|---|
| `db/*.sql` | esquema, RLS y cadena contra PostgreSQL real | `tests/db/run.sh` |
| `integration/*.kt` | SIGN ES y cotejo AEAT contra el sandbox, marcados y sin red en CI | `cd core && ./gradlew test` |

## Arnés previsto (`tests/db/run.sh`)

El patrón ya probado en Komanda (`komanda/db/tests/run.sh`): se crea una BD limpia, se migra
como rol dueño (`billka_owner`) y se prueba como rol de aplicación (`billka_app`, sin
`BYPASSRLS`), fijando el tenant con `SELECT set_config('app.tenant_id', '<uuid>', true)`.

Mínimo exigible para cerrar la etapa C del roadmap (`billka_roadmap.html`):

1. `rls_test.sql` — un tenant no ve ni puede escribir filas de otro (fail-closed sin contexto).
2. `invoice_test.sql` — numeración correlativa por serie sin duplicados, y factura emitida inmutable.
3. `chain_test.sql` — cadena correcta; manipulación de una fila detectada por `verify_chain()`.

## Fixtures fiscales

Los vectores `entrada → huella / QR / XML` van en `core/src/test/resources/fixtures/` y
`fiscal-kit/src/test/resources/fixtures/` (hoy solo `.gitkeep`). Se escriben **antes** de la
implementación y deben dar el mismo resultado que Komanda (etapa D del roadmap).
