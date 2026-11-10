# Arquitectura de Billka

Estado del documento: **10-nov-2026**. Describe la arquitectura **prevista y decidida**, no la
implementada: hoy `core/` compila con 0 fuentes y la base de datos no tiene esquema. Cada
sección indica qué existe de verdad. Ver "Estado real" al final y `billka_roadmap.html`.

El posicionamiento está fijado en el ADR `B0012`: **Billka verifica el tránsito entre el cliente y
el despacho; no emite facturas**. Todo lo que en este documento hable de facturas debe leerse como
«registros y documentos que entran o salen», nunca como emisión propia.

## 1. Qué es Billka

Sello de la **frontera** entre el autónomo y su gestoría. Deja constancia verificable de cuatro
cosas y de nada más:

- **entrada**: huella del lote que el cliente entrega (CSV, Excel, PDF, XML), con fecha y autor;
- **salida**: huella de los registros que el SIF del despacho emitió o remitió;
- **cruce**: comparación campo a campo entre ambos lados, con estado por línea;
- **ancla**: hash raíz diario fijado por un tercero (RFC 3161), verificable sin nuestra base de datos.

No emite facturas ni registros de facturación, no remite nada a la AEAT, no lleva libros registro ni
declaraciones, no es colaborador social y no certifica cumplimiento. Un hash prueba integridad y
anterioridad; **nunca** veracidad ni exactitud fiscal.

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
| 8 | **La frontera es el producto** | Se sella y se cruza lo que entra y sale; no se emite nada (ADR `B0012`) |
| 9 | **Verificable sin nosotros** | La constancia se comprueba con un binario y un fichero, sin pedir permiso a nuestra BD |

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
- **Compartido**: solo `fiscal-kit` (huella canónica de lote, cadena, cruce, NIF, anclaje; lectura de
  XML de terceros). Librería versionada; cada consumidor pinnea su versión.
- **Komanda es el primer consumidor, no el dueño del diseño**: Billka funciona sin Komanda
  desplegado y Komanda no necesita a Billka para emitir.
- **Puertos**: Komanda 80/443 (prod) y 5432/1883 (dev); Billka 18080/13000/15433/8088/8443.
  Sin solapes.

## 4. Componentes

```
billka/
├── cli/               `billka sellar|verificar` (binario)   (0 fuentes; Etapa D)
├── core/              Ktor + dominio + workers            (vacío: 0 fuentes)
├── fiscal-kit/        dominio fiscal compartido            (vacío a propósito)
├── contracts/         envelope + 5 eventos (modelo viejo)  (draft; validan)
├── web/               Next.js 14                           (solo portada)
├── infra/docker/      compose real + Dockerfiles placeholder
└── tests/             0 tests (arnés por escribir)
```

La CLI no es un extra: es el mecanismo por el que un tercero comprueba una constancia **sin** nuestra
base de datos. Si solo se puede verificar llamando a la API, el producto es auto-referencia.

### 4.1 `core` (Ktor)

| Paquete previsto | Responsabilidad |
|---|---|
| `es.billka.core` | arranque Ktor, configuración, health, manejo de errores |
| `domain.tenant` | tenant, membership, resolución de contexto para RLS |
| `domain.lote` | lote de entrada: manifest, ficheros, huella canónica, autor |
| `domain.constancia` | entrada, salida y su emisión con firma |
| `domain.cruce` | emparejamiento por clave, estados por línea, informe |
| `domain.chain` | cadena de huellas, `verify_chain()`, anclajes |
| `worker` | outbox de eventos, anclaje periódico, envío de la copia al autónomo |

Dependencias que **no** están declaradas todavía y harán falta: Ktor server, Exposed o JDBC,
HikariCP, Flyway, driver PostgreSQL, JWT, logback, kotlinx-serialization.

### 4.2 `fiscal-kit` (librería)

Paquete `es.billka.fiscal`. Contenido previsto: `lote` (formato, manifest, normalización canónica y
SHA-256), `chain` (eslabones y verificación), `cruce` (clave compuesta y comparación al céntimo),
`anchor` (RFC 3161), `nif` (validación y territorios) y `verifactu.read` (leer XML de terceros,
**nunca generarlo**). **Nunca** incluye runtime, BD ni despliegue.

### 4.3 `contracts`

Sobre CloudEvents 1.0 (`envelope.schema.json`) + 5 eventos, cada uno con schema de `data`,
ejemplos válidos y ejemplos que **deben fallar**. Todos en `x-status: draft`; el modo estricto de
`contracts/check.py` falla mientras queden borradores. Inmutabilidad por sha256 en `LOCK.json`.

Los 5 eventos actuales describen **emisión de facturas** (`invoice.issued`, `invoice.cancelled`) y
pertenecen al modelo anterior a `B0012`. Se sustituyen en la Etapa C por el modelo de constancias:
`lote.recibido`, `lote.sellado`, `cruce.realizado`, `ancla.publicada`, `constancia.emitida`.

### 4.4 `web` (Next.js)

Portada y (pendiente) panel del despacho y **página pública de verificación de constancia**
(`/v/{codigo}`), que muestra qué se comprobó y con qué resultado, nunca «válido» ni «garantizado».
Consume la API por HTTP; no toca la BD. `output: "standalone"` porque va en contenedor.

### 4.5 `infra`

Compose con `:?` en secretos, healthcheck `pg_isready`, límites de memoria/CPU y
`depends_on: service_healthy`. Los dos Dockerfiles siguen siendo placeholders
(`sleep infinity`): no hay artefacto que meter en la imagen hasta la Etapa F.

## 5. Flujo de un lote (previsto, sin implementar)

```
autónomo ──entrega──► despacho
   │                     │   lote = manifest.json + ficheros (CSV/Excel/PDF/XML)
   ▼                     ▼
              POST /lotes ──► core
                              │ 1. contexto de tenant (JWT → tenantid)
                              │ 2. BEGIN
                              │ 3. normaliza y calcula SHA-256 por fichero + huella del manifest
                              │ 4. inserta lote + constancia_entrada + chain(prev_hash → hash)
                              │ 5. inserta evento en outbox
                              │ 6. COMMIT
                              ▼
                       worker outbox ──► lote.sellado (at-least-once)
                              │
                              ├─► envía la copia de la constancia al autónomo
                              ├─► ② constancia de salida (registros del SIF del despacho)
                              ├─► ③ cruce ──► cruce.realizado (coincide / ausente / discrepante)
                              └─► ④ ancla diaria ──► RFC 3161 ──► ancla.publicada
```

Propiedades que el diseño exige:

- La huella se calcula sobre los **bytes originales** más un `manifest.json` canónico. Si el manifest
  cambia, cambia la huella: por eso se sella junto al lote y no después.
- El evento se escribe en el outbox en la **misma** transacción: si falla el commit, no hay evento;
  si falla la publicación, el outbox reintenta.
- Una constancia emitida no se modifica ni se borra: la corrección es una **constancia nueva** que
  referencia la anterior (`reemplaza_a`).
- El cruce no arregla nada: **clasifica**. Un desajuste es un hallazgo, no un error del programa.
- Si la copia al autónomo no sale, la constancia queda marcada como incompleta.

## 6. Modelo de datos (4 migraciones decididas, 0 escritas)

| Migración | Contenido | Por qué antes que lo siguiente |
|---|---|---|
| `V1__tenancy.sql` | `pgcrypto`, `current_tenant_id()`, `enable_tenant_rls()`, `tenant`, `membership` con RLS forzado | Todo cuelga de `tenant_id`; meterlo después es refactor de todo |
| `V2__lote.sql` | `lote` (autor, receptor, periodo, huella), `lote_file` (nombre, tamaño, SHA-256), `constancia` (entrada/salida, `reemplaza_a`); inmutabilidad por trigger | Es el objeto del producto: contratos y tests se escriben contra sus columnas |
| `V3__chain_cruce.sql` | `chain_entry` (`seq`, `prev_hash`, `hash`), `verify_chain()`, `cruce`, `cruce_linea` (estado por línea) | La evidencia se apoya en el lote, no al revés |
| `V4__anchor.sql` | `anchor` (fecha, hash raíz, TSA, estado `pendiente`/`sellado`/`fallido`) y triggers no-update | Sin ancla externa no hay anterioridad demostrable |

Regla transversal: toda tabla con `tenant_id` llama a `enable_tenant_rls('tabla')`. Los tests de
esquema corren contra PostgreSQL real con dos roles (dueño de las tablas y usuario de aplicación
sin `BYPASSRLS`). El piloto de 2026 será de **un solo tenant**: RLS se implementa y se prueba, pero
no se abre registro multiempresa hasta 2027.

Regla transversal: toda tabla con `tenant_id` llama a `enable_tenant_rls('tabla')`. Los tests de
esquema corren contra PostgreSQL real con dos roles (dueño de las tablas y usuario de aplicación
sin `BYPASSRLS`).

## 7. Seguridad

- **Tenancy**: RLS forzado + `SET LOCAL app.tenant_id` por transacción. Sin contexto, cero filas.
- **Secretos**: `${VAR:?}` en compose, `.env.example` sin valores, `make dev` genera aleatorios
  de forma idempotente. Nunca una contraseña publicada en el repositorio.
- **Red**: solo Caddy publicado; BD y core en `127.0.0.1`.
- **Cadena de custodia**: append-only por trigger, no por convención de código.
- **Datos de terceros**: solo se guardan huellas y metadatos mínimos (nombre, tamaño, fecha, autor);
  el contenido original puede quedarse en poder del despacho. Minimización por diseño, no por
  política: lo que no se guarda no se filtra.

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
| `B0012` | **Billka verifica el tránsito; no emite**: cuatro constancias, cinco prohibiciones, vocabulario vinculante |

## 9. Estado real

| Pieza | Estado (10-nov-2026) |
|---|---|
| `core` | compila (`./gradlew build` verde), **0 fuentes**, sin Ktor |
| `cli` | no existe: `billka sellar` / `verificar` llegan en la Etapa D |
| `fiscal-kit` | vacío a propósito: espera vectores |
| `contracts` | envelope + 5 eventos del modelo anterior validan en borrador; estricto en rojo |
| migraciones | 0 |
| tests | 0 (`make test` rojo a propósito) |
| `web` | portada; sin auth, sin cliente HTTP |
| `infra` | compose válido y probado; Dockerfiles placeholder |
| datos | ninguna BD con esquema; backup y restore probados con una tabla de prueba |

Lo que este documento **no** puede afirmar todavía: rendimiento, capacidad, tiempos reales de
cruce o comportamiento de una TSA. No hay código que los produzca. Y tampoco puede afirmar que una
constancia privada tenga eficacia ante la AEAT: no la tiene por sí sola. Es prueba de hechos
técnicos reproducibles —integridad y anterioridad—, no de cumplimiento tributario.
