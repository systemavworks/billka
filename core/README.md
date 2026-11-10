# core · backend Billka

Estado: **vacío a propósito** (10-nov-2026).

Este directorio contenía 84 ficheros `.kt` de dos líneas (`// TODO` + `export {};`, que es
TypeScript dentro de Kotlin y no compila). Se borraron: un árbol sin ficheros es honesto,
84 ficheros con sintaxis rota no (`billka_auditoria_2026-11-08.html`).

## Qué habrá aquí

| Paquete | Contenido previsto |
|---|---|
| `es.billka.core` | `Application.kt` (Ktor), configuración, health |
| `es.billka.core.domain.tenant` | tenant, membership, RLS |
| `es.billka.core.domain.invoice` | factura, líneas, numeración por serie |
| `es.billka.core.domain.chain` | cadena de huellas y anclajes |
| `es.billka.core.domain.fiscal` | adaptadores a `fiscal-kit`: VeriFactu, SIGN ES, cotejo AEAT |
| `es.billka.core.worker` | outbox, anclaje, firma |

El orden de implementación no es libre: ver «Hoja de ruta» en `billka_roadmap.html` y
`ARCHITECTURE.md` (etapa C esquema → D vectores → E `fiscal-kit` → F contratos + Ktor → G web →
H infra). Este directorio no se toca hasta la etapa F.

## Comandos

```bash
cd core && ./gradlew build   # compila (hoy: 0 fuentes, no hay servidor que arrancar)
cd core && ./gradlew test    # 0 tests todavía: `make test` en la raíz falla a propósito
```

`src/main/resources/application.conf` y `logback.xml` siguen siendo marcadores `TODO`:
no hay servidor que configurar hasta la etapa F del roadmap.
