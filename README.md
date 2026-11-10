# Billka

**Billka** es el sello de la **frontera** fiscal: verifica lo que el autónomo entrega a su gestoría,
lo que el SIF del despacho emite y el cruce entre ambos. Deja cuatro constancias —entrada, salida,
cruce y ancla diaria— con huellas SHA-256 y sello de tiempo de un tercero, y cualquiera puede
recomprobarlas con un comando, sin acceso a nuestra base de datos.

**Billka no emite.** No emite facturas ni registros de facturación, no remite nada a la AEAT, no
lleva libros registro ni presentaciones, no certifica cumplimiento y no vende el «¿consta en la
AEAT?» que la propia AEAT ya ofrece por QR. Un hash prueba que algo **no ha cambiado** y que
**existía**; no prueba que sea verdad. Decisión completa en el ADR `B0012`.

## Frontera con Komanda

Billka convive con Komanda en la misma caja, pero:

- Backends separados.
- Bases de datos PostgreSQL separadas.
- Contenedores Docker separados.
- Despliegues independientes.
- Dominio fiscal compartido mediante `fiscal-kit`.

## Principio legal/técnico

- Komanda no es SIF; Billka tampoco lo será **nunca** (ADR `B0012`).
- Una gestoría que emite facturas de sus clientes con software **es SIF** y está sujeta al RRSIF;
  delegar no exime al empresario. Ese es el hueco que Billka cubre: la entrega, no la emisión.
- Si Billka emitiera, obligaría a sus clientes a enrutar el 100 % de su facturación por Billka
  (unicidad de facturación) y convertiría al titular en proveedor de SIF. No se hace.
- El cotejo AEAT se plantea como utilidad puntual bajo demanda, dentro del cruce, nunca como
  producto: la AEAT ya permite verificar un QR gratis.
- La constancia atesta hechos técnicos reproducibles; no certifica, no garantiza y no tiene eficacia
  administrativa por sí sola.

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
| `cli/` | No existe: `billka sellar` y `billka verificar` llegan en la Etapa D |
| `fiscal-kit/` | Módulo vacío a propósito: sin vectores de prueba no se implementa (ver su README) |
| `web/` | Solo la portada Next.js; panel del despacho y `/v/{codigo}` son páginas pendientes |
| `contracts/` | 5 eventos con schema + ejemplos válidos e inválidos, todos en **draft** y aún del modelo «facturador» (se sustituyen en la Etapa C) |
| `core/src/main/resources/db/migration/` | **0 migraciones**: el esquema no existe todavía |
| `tests/` | **0 tests**. `make test` falla a propósito hasta que exista el primero |
| CI | `build` y contratos en borrador en verde; `tests` y contratos estrictos en rojo a propósito |

El 8-nov-2026 este repositorio tenía 106 ficheros `.kt` de dos líneas con `export {};`
(TypeScript dentro de Kotlin, no compilaban) y 10 migraciones SQL vacías. Todo eso se borró:
un árbol vacío dice la verdad, uno lleno de stubs no.

Orden de trabajo real en `billka_roadmap.html`, por etapas con criterio de salida: **A** higiene y
**B** no mentir (hechas), **C** formato de lote y `fiscal-kit` mínimo, **D** `billka sellar` /
`verificar` sin base de datos, **E** cruce entrada↔salida, **F** ancla RFC 3161 y página pública,
**G** piloto con un despacho, **H** cierre de `B0012` con datos. Calendario: **17-nov → 31-dic-2026**,
y hasta el 17-nov este repositorio no se toca (Komanda entrega el 16-nov).

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
| `ARCHITECTURE.md` | Arquitectura: componentes, flujo de un lote, modelo de datos V1–V4 (tenancy, lote, cadena+cruce, ancla), RLS y decisiones, con el estado real de cada pieza |
| `docs/adr/B0012-billka-verifica-no-emite.md` | **La decisión que ordena el producto**: cuatro constancias, cinco prohibiciones, vocabulario vinculante y criterio de reversión |
| `billka_roadmap.html` | Producto (qué es, qué no es, quién paga) y camino 17-nov → 31-dic-2026, etapa a etapa con criterio de salida |
| `billka_auditoria_2026-11-08.html` | Auditoría del scaffold previa al saneamiento. Histórico: sus cifras ya no describen el repositorio |
| `docs/adr/` | `B0001`–`B0012`, una decisión por ADR |
| `docs/contracts/` | Modelo de eventos, outbox y versionado de contratos |
| `docs/runbook/` | Backup verificado, restore ensayado, primer push |

