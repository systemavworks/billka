# Billka

**Billka** es la capa de integridad y cotejo fiscal que convive con el sistema de facturación que
el cliente ya tiene: encadena cada registro con una huella SHA-256, sella tramos de la cadena con
anclajes periódicos, ofrece un QR de verificación propio y coteja facturas contra la AEAT bajo
demanda. No lo sustituye, no lo copia y no lo lee si no hace falta.

No es un SIF, no es un colaborador social y no sustituye a VeriFactu. Un QR propio no equivale a
cumplimiento normativo.

## Frontera con Komanda

Billka convive con Komanda en la misma caja, pero:

- Backends separados.
- Bases de datos PostgreSQL separadas.
- Contenedores Docker separados.
- Despliegues independientes.
- Dominio fiscal compartido mediante `fiscal-kit`.

## Principio legal/técnico

- Komanda no es SIF.
- Billka C-2, si emite registros de facturación, debe vivir en su propio servicio y BD.
- Un QR propio no equivale a cumplimiento VeriFactu.
- La emisión fiscal real debe hacerse mediante software/proveedor declarado cuando aplique.
- El cotejo AEAT se plantea como cotejo puntual bajo demanda, no scraping masivo.

## Stack previsto

- Core: Kotlin + Ktor.
- Web: Next.js + TypeScript.
- DB: PostgreSQL 16.
- Infra: Docker Compose + Caddy.
- Contratos: JSON Schema 2020-12 + CloudEvents.
- Fiscal compartido: `fiscal-kit`.

## Arranque scaffold

```bash
cp .env.example .env
./scripts/dev.sh
```

## Estructura

- `core/` backend Billka.
- `web/` frontend Billka.
- `fiscal-kit/` librería fiscal compartida.
- `contracts/` contratos de eventos.
- `infra/` Docker, Caddy, monitoring.
- `docs/adr/` decisiones de arquitectura.
- `docs/fiscal/` documentación fiscal.
- `scripts/` automatización.
- `tests/` pruebas de integración y BD.

## Estado

Scaffold saneado el **2026-11-10**. Lo que hay y lo que no, sin adornos:

| Pieza | Estado real |
|---|---|
| `core/` | Compila con Gradle 8.10 + JDK 21 y **0 fuentes**: no hay servidor Ktor todavía |
| `fiscal-kit/` | Módulo vacío a propósito: sin vectores de prueba no se implementa (ver su README) |
| `web/` | Solo la portada Next.js; dashboard, emitir y verificar son páginas pendientes |
| `contracts/` | 5 eventos con schema + ejemplos válidos e inválidos, todos en **draft** |
| `core/src/main/resources/db/migration/` | **0 migraciones**: el esquema no existe todavía |
| `tests/` | **0 tests**. `make test` falla a propósito hasta que exista el primero |
| CI | `build` y contratos en borrador en verde; `tests` y contratos estrictos en rojo a propósito |

El 8-nov-2026 este repositorio tenía 106 ficheros `.kt` de dos líneas con `export {};`
(TypeScript dentro de Kotlin, no compilaban) y 10 migraciones SQL vacías. Todo eso se borró:
un árbol vacío dice la verdad, uno lleno de stubs no.

Orden de trabajo real en `billka_roadmap.html`, por etapas con criterio de salida: **A** higiene y
**B** no mentir (hechas), **C** esquema y tests, **D** vectores fiscales, **E** `fiscal-kit`,
**F** contratos y Ktor, **G** web, **H** infra. No se escribe lógica fiscal antes de los vectores.

## Comandos

```bash
make dev              # stack Docker; genera POSTGRES_PASSWORD y JWT_SECRET en .env si faltan
make build            # compila core + fiscal-kit
make test             # tests JVM; falla si no se ejecuta ninguno (hoy: 0)
make contracts-draft  # valida los contratos en modo borrador (hoy en verde)
make contracts        # contratos congelados: hoy en rojo a propósito
make tree             # árbol resumido
```

`make contracts` y `make test` están en rojo **a propósito**: son los dos únicos sitios donde
el repositorio puede mentir sobre su propio estado. Cuando se pongan verdes, será porque hay
contratos congelados y tests de verdad.

## Documentación

| Documento | Qué es |
|---|---|
| `ARCHITECTURE.md` | Arquitectura: componentes, flujo de una factura, modelo de datos V1–V3, RLS y decisiones, con el estado real de cada pieza |
| `billka_roadmap.html` | Presentación del producto (qué es y qué no es, para quién) y hoja de ruta por etapas con criterio de salida |
| `billka_auditoria_2026-11-08.html` | Auditoría del scaffold previa al saneamiento. Histórico: sus cifras ya no describen el repositorio |
| `docs/adr/` | `B0001`–`B0011`, una decisión por ADR |
| `docs/contracts/` | Modelo de eventos, outbox y versionado de contratos |
| `docs/runbook/` | Backup verificado, restore ensayado, primer push |

