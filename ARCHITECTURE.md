# Arquitectura de Billka

Estado del documento: **10-nov-2026**. Describe la arquitectura **prevista y decidida**, no la
implementada: hoy `core/` compila con 0 fuentes y la base de datos no tiene esquema. Cada
sección indica qué existe de verdad. Ver "Estado real" al final y `billka_roadmap.html`.

## 1. Qué es Billka

Capa de **integridad y cotejo fiscal** que convive con el sistema de facturación que el cliente
ya tiene:

- encadena cada registro con una huella SHA-256 (append-only, sin `UPDATE` ni `DELETE`);
- sella tramos de la cadena con un anclaje periódico verificable;
- coteja facturas contra la AEAT **bajo demanda y de forma puntual** (no scraping masivo);
- opcionalmente firma/emite a través de SIGN ES cuando el cliente lo tiene contratado.

No es un SIF propietario que sustituya al del cliente, no es un colaborador social y no
sustituye a VeriFactu. Un QR propio no equivale a cumplimiento VeriFactu.

## 2. Principios que ordenan el diseño

| # | Principio | Consecuencia práctica |
|---|---|---|
| 1 | **El esquema manda** | Los datos de una factura emitida son inmutables en la BD (triggers), no solo en el código |
| 2 | **Multi-tenant fail-closed** | Toda tabla con `tenant_id` lleva RLS **forzado**; sin contexto de tenant no se ve nada |
| 3 | **Evidencia antes que interfaz** | La cadena y la huella se prueban con vectores antes de pintar una pantalla |
| 4 | **Sin vectores no hay implementación** | `fiscal-kit` no se escribe hasta tener `entrada → huella/QR/XML` |
| 5 | **Nada dice OK sin hacerlo** | Scripts y CI fallan cuando no han probado nada (ADR B0011) |
| 6 | **Los fallos se publican** | Un cotejo `unavailable` o una firma `failed` son eventos de dominio, no silencios |
| 7 | **Dinero en céntimos** | Columnas `*_cents` enteras. Nunca coma flotante |

## 3. Contexto: Billka junto a Komanda en la misma caja

```
┌─────────────────────── caja (Hetzner) ────────────────────────┐
│                                                               │
│  ┌──────────── Komanda ────────────┐   ┌────── Billka ───────┐│
│  │ compose project: komanda        │   │ project: billka     ││
│  │ core (Ktor) + web (Next)        │   │ core (Ktor) + web   ││
│  │ postgres: komanda_pgdata        │   │ postgres:           ││
│  │ caddy: 80/443                   │   │   billka_pgdata     ││
│  │                                 │   │ caddy: 8088/8443    ││
│  └─────────────────────────────────┘   └─────────────────────┘│
│            │                                       │          │
│            └────────── fiscal-kit (librería) ───────┘          │
│                        semver, sin runtime                     │
└───────────────────────────────────────────────────────────────┘
```

Reglas de la frontera (ADR `B0002`; ADR 0009 canónico vive en Komanda, `B0009` es el puntero):

- **Runtime, base de datos y despliegue separados.** Un fallo de Billka no tumba Komanda.
- **Nada de red interna compartida**: se hablan por HTTP con contrato, nunca por tabla.
- **Compartido**: solo `fiscal-kit` (huella/QR/XML, SIGN ES, cotejo, NIF, cadena). Librería
  versionada; cada consumidor pinnea su versión.
- **Puertos**: Komanda 80/443 (prod) y 5432/1883 (dev); Billka 18080/13000/15433/8088/8443.
  Sin solapes.

## 4. Componentes

```
billka/
├── core/              Ktor + dominio + workers            (vacío: 0 fuentes)
├── fiscal-kit/        dominio fiscal compartido            (vacío a propósito)
├── contracts/         envelope + 5 eventos (JSON Schema)   (draft; validan)
├── web/               Next.js 14                           (solo portada)
├── infra/docker/      compose real + Dockerfiles placeholder
└── tests/             0 tests (arnés por escribir)
```

### 4.1 `core` (Ktor)

| Paquete previsto | Responsabilidad |
|---|---|
| `es.billka.core` | arranque Ktor, configuración, health, manejo de errores |
| `domain.tenant` | tenant, membership, resolución de contexto para RLS |
| `domain.invoice` | factura, líneas, numeración atómica por serie, inmutabilidad |
| `domain.chain` | cadena de huellas, `verify_chain()`, anclajes |
| `domain.fiscal` | adaptadores a `fiscal-kit` (VeriFactu, SIGN ES, cotejo) |
| `worker` | outbox de eventos, anclaje periódico, firma |

Dependencias que **no** están declaradas todavía y harán falta: Ktor server, Exposed o JDBC,
HikariCP, Flyway, driver PostgreSQL, JWT, logback, kotlinx-serialization.

### 4.2 `fiscal-kit` (librería)

Paquete `es.billka.fiscal`. Contenido previsto: `verifactu` (huella, QR, XML), `sign` (SIGN ES),
`cotejo` (AEAT bajo demanda), `nif` (validación y territorios), `hash` (cadena y anclajes),
`models`. **Nunca** incluye runtime, BD ni despliegue.

### 4.3 `contracts`

Sobre CloudEvents 1.0 (`envelope.schema.json`) + 5 eventos, cada uno con schema de `data`,
ejemplos válidos y ejemplos que **deben fallar**. Todos en `x-status: draft`; el modo estricto de
`contracts/check.py` falla mientras queden borradores. Inmutabilidad por sha256 en `LOCK.json`.

### 4.4 `web` (Next.js)

Portada y (pendiente) dashboard, emisión y verificación pública de QR. Consume la API por HTTP;
no toca la BD. `output: "standalone"` porque va en contenedor.

### 4.5 `infra`

Compose con `:?` en secretos, healthcheck `pg_isready`, límites de memoria/CPU y
`depends_on: service_healthy`. Los dos Dockerfiles siguen siendo placeholders
(`sleep infinity`): no hay artefacto que meter en la imagen hasta la Etapa F.

## 5. Flujo de una factura (previsto, sin implementar)

```
cliente ──POST /invoices──► core
                            │ 1. contexto de tenant (JWT → tenantid)
                            │ 2. BEGIN
                            │ 3. reserva número en invoice_series (atómico)
                            │ 4. calcula huella SHA-256 (fiscal-kit)
                            │ 5. inserta invoice + líneas + chain(prev_hash → hash)
                            │ 6. inserta evento en outbox
                            │ 7. COMMIT
                            ▼
                     worker outbox ──► invoice.issued (at-least-once)
                            │
                            ├─► anclaje periódico ──► chain.anchored
                            ├─► SIGN ES (opcional) ─► sign.es.completed
                            └─► cotejo bajo demanda ─► cotejo.aeat.done
```

Propiedades que el diseño exige:

- La huella se calcula **dentro** de la transacción, con el número ya asignado. Fuera de ella,
  dos facturas pueden compartir número o huella.
- El evento se escribe en el outbox en la **misma** transacción: si falla el commit, no hay
  evento; si falla la publicación, el outbox reintenta.
- Una factura emitida no se modifica ni se borra: la anulación es una rectificativa
  (`invoice.cancelled`).

## 6. Modelo de datos (3 migraciones decididas, 0 escritas)

| Migración | Contenido | Por qué antes que lo siguiente |
|---|---|---|
| `V1__tenancy.sql` | `pgcrypto`, `current_tenant_id()`, `enable_tenant_rls()`, `tenant`, `membership` con RLS forzado | Todo cuelga de `tenant_id`; meterlo después es refactor de todo |
| `V2__invoice.sql` | `invoice_series`, `invoice`, `invoice_line`; numeración atómica; inmutabilidad | Es el objeto fiscal: contratos y tests se escriben contra sus columnas |
| `V3__chain.sql` | `chain_entry` (`seq`, `prev_hash`, `hash`), triggers no-update/no-delete, `verify_chain()`, `anchor` | La evidencia se apoya en la factura, no al revés |

Regla transversal: toda tabla con `tenant_id` llama a `enable_tenant_rls('tabla')`. Los tests de
esquema corren contra PostgreSQL real con dos roles (dueño de las tablas y usuario de aplicación
sin `BYPASSRLS`).

## 7. Seguridad

- **Tenancy**: RLS forzado + `SET LOCAL app.tenant_id` por transacción. Sin contexto, cero filas.
- **Secretos**: `${VAR:?}` en compose, `.env.example` sin valores, `make dev` genera aleatorios
  de forma idempotente. Nunca una contraseña publicada en el repositorio.
- **Red**: solo Caddy publicado; BD y core en `127.0.0.1`.
- **Cadena de custodia**: append-only por trigger, no por convención de código.
- **Datos de terceros**: cotejo AEAT puntual y bajo demanda; nada de scraping masivo.

## 8. Decisiones registradas

| ADR | Decisión |
|---|---|
| `B0001` | arquitectura general (Kotlin/Ktor + Next + PostgreSQL) |
| `B0002` | separación de Komanda (runtime, BD, despliegue) |
| `B0003` | integración SIGN ES |
| `B0004` | XML VeriFactu |
| `B0005` | cotejo AEAT puntual |
| `B0006` | multi-tenant con RLS |
| `B0007` | no colaborador social |
| `B0008` | territorios (común, País Vasco, Navarra) |
| `B0009` | puntero al ADR 0009 canónico de Komanda |
| `B0010` | licencia y visibilidad (propietaria publicada; visibilidad aún pública) |
| `B0011` | veracidad operativa: nada dice OK sin hacerlo |

## 9. Estado real

| Pieza | Estado (10-nov-2026) |
|---|---|
| `core` | compila (`./gradlew build` verde), **0 fuentes**, sin Ktor |
| `fiscal-kit` | vacío a propósito: espera vectores |
| `contracts` | envelope + 5 eventos validan en modo borrador; estricto en rojo |
| migraciones | 0 |
| tests | 0 (`make test` rojo a propósito) |
| `web` | portada; sin auth, sin cliente HTTP |
| `infra` | compose válido y probado; Dockerfiles placeholder |
| datos | ninguna BD con esquema; backup y restore probados con una tabla de prueba |

Lo que este documento **no** puede afirmar todavía: rendimiento, capacidad, tiempos reales de
cotejo o comportamiento de SIGN ES. No hay código que los produzca.
