# ADR B0012 · Billka verifica el tránsito, no emite facturas

**Estado**: Aceptado (parte dispositiva) · **Fecha**: 2026-11-10 · **Cierre empírico**: Etapa H,
22–31 dic 2026

## Contexto

Billka nació en el repositorio como «capa de integridad y cotejo» (ADR `B0001`), pero el andamiaje
lo contradecía: `V2__invoice.sql`, el contrato `invoice.issued`, la secuencia «reservar número →
calcular huella → insertar factura» en `ARCHITECTURE.md` §5 y un `POST /invoices` previsto. Eso no
es una capa de integridad: **es un SIF**.

El Informador VERI*FACTU de la AEAT (consultas de nov-2026) cierra la discusión con cuatro
respuestas que conviene citar literalmente antes de decidir:

1. Si el empresario delega la expedición material en un tercero —una gestoría—, es **el tercero
   quien, si utiliza un SIF**, debe generar y, en su caso, remitir el registro: la gestoría que
   emite facturas de sus clientes con software **es SIF** y está sujeta al RRSIF.
2. La delegación **no exime** al obligado a expedir facturas de su responsabilidad sobre ese
   cumplimiento: **ambos lados** del contrato necesitan prueba, y con intereses opuestos.
3. Si los datos recibidos **se reutilizan** para obtener «otros productos derivados», se considera
   facturación con SIF. Casi todo despacho que recibe un Excel y lo lleva a sus libros registro ya
   es SIF de hecho.
4. Usar **cualquier SIF** que produzca facturas obliga a que **toda** la facturación del cliente sea
   informática (unicidad de facturación; solo MiFacturae queda al margen).

De (1) y (4) se sigue un argumento económico, no moral: **si Billka emitiera, cada cliente quedaría
obligado a enrutar el 100 % de su facturación por Billka** y el titular de Billka pasaría a ser
proveedor de SIF —con las obligaciones de la Orden HAC/1177/2024, la declaración responsable y la
unicidad— además de competir frontalmente con Komanda, que es el producto de emisión que ya existe
en la caja.

De (2) y (3) se sigue dónde está el hueco que nadie cubre: **la frontera**. El SIF solo ve su salida;
la AEAT solo ve lo remitido; el asesor solo ve lo que le llega. El punto en el que el autónomo
entrega sus facturas al despacho no tiene SIF, ni QR, ni registro, ni custodia.

Y una respuesta adicional degrada un producto anterior de este repositorio: la AEAT ya permite al
destinatario **verificar la existencia de una factura por su QR** en su sede. Por tanto el cotejo
«¿consta esta factura?» (ADR `B0005`) **no es vendible**: es un servicio público gratuito. Entra en
Billka como una fuente más del cruce, nunca como producto.

## Decisión

### 1. Billka es el sello de la frontera

Cuatro constancias encadenadas, no un sello genérico:

| # | Constancia | Contenido | Qué resuelve |
|---|---|---|---|
| ① | **Entrada** | Huella del lote entregado (CSV/Excel/PDF/XML), fecha y quién lo entregó | «yo te pasé esa factura y no la has metido» |
| ② | **Salida** | Huella de los registros que el SIF del despacho emitió o remitió, con fecha y responsable | coherencia entre lo emitido y lo conservado |
| ③ | **Cruce** | Comparación campo a campo (NIF, fecha, número, base, cuota, total) con estado por línea: coincide / ausente en entrada / ausente en salida / discrepante | lo que ninguna parte puede fabricar sola |
| ④ | **Ancla** | Hash raíz diario fijado por un tercero (RFC 3161) y publicable fuera de nuestra infraestructura | «¿cómo sé que no lo generaste ayer?» |

### 2. Cinco prohibiciones

Ninguna función nueva entra en Billka si cruza estas líneas. No son «principios orientativos»:

1. **No emite** facturas, registros de facturación ni XML Veri*Factu propio.
2. **No remite** nada a la AEAT ni presenta modelos por cuenta de terceros (ADR `B0007`).
3. **No produce** libros registro, contabilidad, 303, 111 ni declaraciones: no elabora «productos
   derivados» en el sentido del Informador.
4. **No certifica ni garantiza**: no es entidad acreditada; **atesta hechos técnicos reproducibles**.
5. **No vende «¿consta en la AEAT?»** como servicio: la AEAT ya lo da gratis por QR.

### 3. Límite técnico que se publica

Un hash prueba **integridad** y, con sello de tiempo externo, **anterioridad**. **Nunca** prueba
veracidad ni exactitud fiscal: el hash de una factura inventada es un hash perfecto. Para acercarse
a «real» hace falta una fuente independiente (banco, TPV, albarán, stock, QR de la AEAT), y por eso
la unidad de producto es el **cruce de dos lados**, no el sello de uno.

### 4. Requisitos de independencia (sin ellos el producto es auto-referencia)

- **Especificación pública** del formato de lote y de la constancia: cualquiera puede implementarlo.
- **CLI `billka verificar`** que **recomputa** la huella desde los ficheros originales del cliente,
  **sin consultar nuestra base de datos**. Si la necesitara, no sería verificable por un tercero.
- **Ancla en un tercero** (TSA RFC 3161 o publicación externa). Si la TSA no responde, el estado es
  `pendiente` y **se publica como tal** (ADR `B0011`).
- **Copia al autónomo**: la constancia de entrada se envía también al cliente del despacho al
  generarse. Falsificarla exige falsificar dos copias en manos distintas.

### 5. Komanda es el primer consumidor, no el dueño del diseño

`fiscal-kit` sigue compartido (ADR `B0002`): hash de lote, encadenado, normalización canónica,
validación de NIF y anclaje, con el mecanismo ya probado en Komanda (`V4` cadena +
`chain_anchor`, `V17` sello diario). Pero la dependencia es **opcional en ambos sentidos**: Billka
funciona sin Komanda desplegado y Komanda no necesita a Billka para emitir.

### 6. Vocabulario vinculante

| Prohibido | Obligatorio | Motivo |
|---|---|---|
| «sello de garantía» | **sello de integridad** / **constancia verificable** | «garantía» es promesa de resultado → responsabilidad civil |
| «certificamos» | **atestamos** | certificar es de entidades acreditadas |
| «queda constatado que es real» | **«coincide y no se ha alterado»** | lo primero es un juicio de veracidad |
| «válido a efectos fiscales» | **«comprobaciones realizadas: N de M»** | lo primero nos hace responsables del cumplimiento ajeno |

Aplica a README, web, contratos, correos y presentaciones. El ADR `B0011` ya obliga a que ningún
artefacto diga más de lo que hace; esto es su versión lingüística.

## Consecuencias

**Se retira del producto** (y del roadmap): emisión de facturas, `V2__invoice.sql`, `POST /invoices`,
el QR propio como argumento de cumplimiento y el cotejo AEAT como servicio de pago.

**Se sustituye**: los 5 contratos de evento (`invoice.issued`, `invoice.cancelled`,
`chain.anchored`, `sign.es.completed`, `cotejo.aeat.done`) por el modelo de constancias
(`lote.recibido`, `lote.sellado`, `cruce.realizado`, `ancla.publicada`, `constancia.emitida`),
en la Etapa C.

**Se mantiene sin cambios**: `B0002` (separación de Komanda), `B0006` (RLS; el piloto será de un
solo tenant), `B0007` (no colaborador social), `B0008` (territorios forales), `B0009` (puntero),
`B0010` (licencia), `B0011` (veracidad operativa).

**Quedan reinterpretados**:

- `B0003` (SIGN ES): ya no firma facturas; su función pasa a ser, si acaso, firma de constancias y
  sellado de tiempo. Sigue en *Propuesto*.
- `B0004` (XML VeriFactu): deja de ser una capacidad de emisión y pasa a ser **lectura** de XML de
  terceros para el cruce.
- `B0005` (cotejo AEAT): **degradado a utilidad**. Puntual, bajo demanda, dentro del cruce.

**Riesgos aceptados por escrito**

- **Responsabilidad civil** por un juicio técnico: se acota con el vocabulario del punto 6 y con la
  constancia de lo que **no** se comprobó.
- **Prórroga normativa**: el calendario de Veri*Factu ya se ha movido una vez y puede moverse otra.
  El producto no se apoya en la fecha: la constancia de entrega tiene valor hoy.
- **Absorción por un SIF** que añada «sello de entrega»: el hueco defendible es el despacho pequeño
  con dos o tres programas distintos y sin TI; la independencia es la ventaja.
- **La AEAT puede no valorar constancias privadas**: el comprador no es la AEAT, es el despacho, el
  perito y el comprador en una *due diligence*. No se promete eficacia administrativa.

## Criterio de reversión

Si el piloto de la Etapa G no termina con un despacho que **firme un precio**, Billka se declara
herramienta interna de Komanda y se dice sin drama. Coste hundido: dos semanas de trabajo, no dos
años de producto. El criterio numérico se escribe **antes** de mirar el resultado, para que la
decisión no se tome con el deseo.

## Referencias

- `docs/fiscal/cotejo-aeat.md` — qué se puede y qué no se puede cotejar contra la AEAT.
- `komanda/docs/adr/0007-doble-captura-qr-verifactu.md` — captura por QR y `match_status`.
- `komanda/docs/adr/0008-*`, `0009-*` — por qué Komanda no será SIF y por qué los runtimes van
  separados; el puntero local es `B0009`.
- `billka_roadmap.html` — traducción de este ADR a producto y a calendario.

