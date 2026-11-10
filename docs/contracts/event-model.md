# Modelo de eventos

Billka publica eventos de dominio de los que dependen otras piezas (web, operaciones, futura
convergencia con Komanda). Este documento fija qué se publica, cuándo y con qué propiedades.
Los schemas están en `contracts/`; esto es la parte que un schema no puede expresar.

> **Aviso (ADR `B0012`, 10-nov-2026).** Los cinco eventos descritos aquí pertenecen al modelo
> anterior, en el que Billka emitía facturas. Billka **no emite**: la sustitución por el modelo de
> constancias (`lote.recibido`, `lote.sellado`, `cruce.realizado`, `ancla.publicada`,
> `constancia.emitida`) está planificada en la Etapa C. Mientras tanto, este documento describe lo
> que hay en `contracts/`, no lo que el producto será.

## Sobre

Se usa CloudEvents 1.0 en modo *structured* (`application/cloudevents+json` cuando viaje por
HTTP; hoy no viaja por ningún sitio todavía, ver "Estado").

| Campo | Regla |
|---|---|
| `specversion` | `"1.0"`, constante |
| `id` | UUIDv7 del emisor. **Clave de idempotencia**: `outbox.event_id UNIQUE` |
| `source` | quién lo emite: `billka/core`, `billka/worker/chain`, `billka/worker/sign` |
| `type` | `<entidad>.<acción>` en minúsculas (`invoice.issued`) |
| `schemaversion` | entero, versión mayor del payload |
| `time` | `occurred_at` (cuándo ocurrió), **no** cuándo se publicó |
| `tenantid` | UUID del tenant; sin él el consumidor no puede aplicar RLS |
| `subject` | entidad afectada: `invoice/<uuid>` |
| `datacontenttype` | `application/json` |
| `data` | payload, validado contra `events/<type>/v<N>.schema.json` |

El sobre y el payload se validan **por separado**: `envelope.schema.json` no conoce ningún
`data` concreto, y el schema del evento describe solo `data`. Añadir un evento nuevo no toca
el sobre; cambiar el sobre no obliga a tocar 5 schemas.

`additionalProperties: false` en el sobre: un campo nuevo es una decisión, no un accidente.

## Cuándo se publica cada evento

| Evento | Se publica cuando | No se publica cuando |
|---|---|---|
| `invoice.issued` | la factura queda registrada con número asignado y huella calculada | el número está reservado pero la transacción no ha confirmado |
| `invoice.cancelled` | se emite la rectificativa que anula (VeriFactu no borra: se añade) | alguien hace `DELETE` (no existe el borrado) |
| `chain.anchored` | un tramo de la cadena queda sellado en un testigo externo | el anclaje falla (eso es un `alert`, no un evento de dominio) |
| `sign.es.completed` | SIGN ES responde, con éxito **o** con error | la petición no llega a salir (fallo de red previo: reintento) |
| `cotejo.aeat.done` | termina un cotejo bajo demanda, incluido `unavailable` | no se ha pedido ningún cotejo |

Regla que atraviesa todo: **los fallos también se publican** (`status: failed`,
`result: unavailable`). Un flujo de eventos que solo existe cuando todo va bien es un registro
que miente por omisión, y en facturación eso es exactamente lo que no se puede hacer.

## Propiedades de entrega

- **Entrega**: *at-least-once* desde un patrón outbox. No hay exactly-once: no existe.
- **Consumidores**: idempotentes por `id`. Recibir dos veces el mismo `invoice.issued` debe ser
  inocuo (insertar con `ON CONFLICT (event_id) DO NOTHING`).
- **Orden**: no hay orden global. El orden relevante es el de la cadena, que se deriva de
  `chain.anchored` (`head_huella`), no del orden de llegada.
- **Dinero**: siempre céntimos enteros (`*_cents`). Ni `float`, ni `decimal` serializado como
  string, ni euros con decimales.
- **Reintentos**: los publica el outbox, no el código de negocio. Un evento no se publica dos
  veces por reintentar la petición HTTP.

## Estado

Los 5 contratos existen y validan (`check.py --draft` en verde) pero **ninguno está congelado**
y **ningún productor ni consumidor está implementado**: `core/` no tiene endpoints y no hay
broker. Este documento describe la intención congelable, no un sistema en marcha.

