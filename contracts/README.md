# Contratos de eventos

Estado: **borrador** (`x-status: draft`). Los 5 contratos existen, validan y tienen ejemplos
válidos e inválidos, pero **ninguno está congelado**: pueden cambiar hasta que el esquema de
`V1__tenancy.sql`…`V3__chain.sql` esté cerrado (Etapa C del roadmap).

```bash
python3 contracts/check.py            # estricto: hoy FALLA a propósito (todo es draft)
python3 contracts/check.py --draft    # verde: valida envelope + data + ejemplos
python3 contracts/check.py --lock     # congela los schemas released en LOCK.json
```

`make contracts` llama al modo estricto y `make contracts-draft` al modo borrador.

## Estructura

```
contracts/
├── envelope.schema.json          # sobre común (CloudEvents 1.0 + extensiones)
├── events/<type>/v<N>.schema.json    # schema de `data` (NO del evento completo)
├── events/<type>/v<N>.examples.json  # eventos completos que DEBEN validar
├── events/<type>/v<N>.invalid.json   # eventos completos que DEBEN fallar
└── LOCK.json                     # sha256 de los schemas released (inmutabilidad)
```

El schema de un evento describe **solo el contenido de `data`**; el sobre se valida aparte con
`envelope.schema.json`. Así una versión nueva del payload no obliga a duplicar el sobre.

## Sobre (envelope)

`specversion`, `id`, `source`, `type`, `schemaversion`, `time`, `tenantid`, `datacontenttype`,
`data` (obligatorios) y `subject` (opcional). `additionalProperties: false`: un campo nuevo en
el sobre es una decisión, no un accidente.

Se usa **`tenantid`** (sin guion bajo) para que el sobre sea *el mismo* que el de Komanda
(`komanda/contracts/envelope.schema.json`) salvo los campos que Billka no tiene
(`venueid`, `deviceid`, `deviceseq`, `mode`, `systemid`, `connectorid`). Cuando se aborde la convergencia
(un solo `contracts/`), la convergencia es borrar líneas, no renombrar campos en 5 schemas.

## Eventos

| Tipo | `data` describe |
|---|---|
| `invoice.issued` | factura emitida: serie+número, base/IVA/total en céntimos, `huella`, QR |
| `invoice.cancelled` | anulación por rectificativa (VeriFactu no borra), enlaza `rectifying_invoice_id` |
| `chain.anchored` | tramo de cadena sellado en un testigo externo (`head_huella`, `anchor_kind`) |
| `sign.es.completed` | firma en SIGN ES, incluido el fallo (`status: failed` + `error_code`) |
| `cotejo.aeat.done` | resultado del cotejo AEAT (`match`, `not_found`, `unavailable`…) |

Reglas de contenido:

- Dinero **siempre en céntimos** (`*_cents`, entero). Nunca `float`.
- Identificadores `uuid`; `huella` es SHA-256 hex de 64 caracteres.
- Los fallos de un proveedor externo **se publican** (`status: failed`, `result: unavailable`);
  un evento que solo existe cuando todo va bien es un registro que miente por omisión.

## Inmutabilidad

Un schema `released` está congelado por sha256 en `LOCK.json`. Cambiarlo rompe el check a
propósito: se publica `v2.schema.json` y ambos conviven mientras haya consumidores en v1.
