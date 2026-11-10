# Migraciones

**Fuente única de verdad:** `core/src/main/resources/db/migration/` (classpath → Flyway).
Este directorio se conserva como puntero: no añadir SQL aquí.

Estado: **0 migraciones**. Las 10 vacías (`V001__schema_base.sql` … `V010__anchors.sql`,
3 líneas de comentario cada una) se borraron el 10-nov-2026: daban la falsa sensación de
esquema definido. Hoy el esquema no existe, y eso es lo que hay que leer.

## Orden previsto

Etapa C de la hoja de ruta (`billka_roadmap.html`), la que toca ahora. El detalle técnico está
en `ARCHITECTURE.md` §6:

| Migración | Contenido | Por qué antes que la siguiente |
|---|---|---|
| `V1__tenancy.sql` | `pgcrypto`, `current_tenant_id()`, `enable_tenant_rls()`, `tenant`, `membership` (RLS forzado) | Todo lo demás lleva `tenant_id`: meter multi-tenancy después es refactor de todo el esquema |
| `V2__invoice.sql` | `invoice_series`, `invoice`, `invoice_line`; numeración atómica por serie; inmutabilidad de la factura emitida | Es el objeto fiscal; los contratos y los tests se escriben contra sus columnas |
| `V3__chain.sql` | cadena de huellas (`seq`, `prev_hash`, `hash`), disparadores no-update/no-delete, `verify_chain()`, tabla de anclajes | La evidencia de integridad se apoya en la factura, no al revés |

## Reglas

1. Nombrado Flyway: `V<n>__snake_case.sql`, `n` sin ceros a la izquierda (`V1__`, no `V001__`).
2. Una decisión por migración; si hay que cambiar algo ya aplicado, migración nueva.
3. Toda tabla con `tenant_id` activa RLS **forzado** (`CALL enable_tenant_rls('tabla')`).
4. Los tests de esquema viven en `tests/db/` y se ejecutan contra PostgreSQL real (`tests/README.md`).
