# Versionado de contratos

## Ciclo de vida

`x-status` en cada schema, en este orden y sin saltos:

1. **`draft`** — se puede romper sin avisar. Solo lo consume quien está escribiendo el código.
2. **`released`** — congelado por sha256 en `contracts/LOCK.json`. Cambiarlo rompe el check.
3. **`deprecated`** — sigue validando y sigue en `LOCK.json`; se anuncia la versión que lo
   sustituye. No se borra mientras haya consumidores.

```bash
python3 contracts/check.py --draft   # valida todo, avisa de lo que sigue en draft
python3 contracts/check.py           # exige released + hashes en LOCK.json
python3 contracts/check.py --lock    # recalcula LOCK.json (solo schemas released)
```

## Qué es un cambio incompatible

Cambio **compatible** (misma versión mayor, `v1`):

- añadir un campo **opcional** al payload;
- añadir un valor nuevo a un `enum` que el consumidor trate como abierto (documentarlo);
- relajar una restricción (subir un `maxLength`, ampliar un `pattern`) **solo** si el consumidor
  no dependía de ella; en la duda, no es compatible;
- aclarar una `description`.

Cambio **incompatible** (nueva versión mayor, `v2`):

- quitar o renombrar un campo, aunque esté vacío;
- volver opcional un campo obligatorio, o al contrario;
- cambiar el tipo (`integer` → `string`), la unidad (céntimos → euros) o el significado
  (`total_cents` pasa a incluir IVA);
- añadir un valor a un `enum` cerrado, o cerrar uno abierto;
- endurecer `additionalProperties: true` → `false` sin ventana de transición.

Cuando hay duda, se sube de versión. Una versión de más es barata; un `v1` reinterpretado en
producción es un incidente fiscal.

## Convivencia de versiones

- Ambas versiones **coexisten** en `contracts/events/<tipo>/` (`v1`, `v2`).
- El emisor decide qué versión manda: `schemaversion` en el sobre. Un consumidor que no conoce
  `schemaversion: 2` debe rechazar el evento, no adivinarlo.
- Solo se retira `v1` cuando no queda ningún consumidor; retirarlo no es borrar el fichero, es
  pasar a `deprecated` y, más tarde, moverlo a `contracts/archive/`.

## `LOCK.json`

Es un mapa plano `ruta → sha256`. Se recalcula con `--lock` **solo** para schemas `released`:

- un fichero modificado que no está en `LOCK.json` → error (nadie lo congeló);
- un hash que no coincide → error (se tocó un contrato congelado);
- una entrada en `LOCK.json` sin fichero → error (se borró un contrato congelado).

Ese es todo el mecanismo de inmutabilidad: no hay servidor de schemas, hay un hash. Es
suficiente porque el repositorio es la fuente de verdad.

## Relación con Komanda

Billka y Komanda mantienen contratos separados con sobres compatibles (`tenantid`, mismas
extensiones). La convergencia en un único `contracts/` está registrada en el ADR B0009 como
trabajo futuro (convergencia en un único `contracts/`); mientras tanto, un cambio en el sobre debe hacerse en los dos sitios o
en ninguno.

