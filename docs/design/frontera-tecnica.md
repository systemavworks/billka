# La frontera, técnicamente

**Estado**: borrador de diseño · **Fecha**: 2026-11-10 · **Ámbito**: Etapas C→F · **Decisión marco**:
ADR [`B0012`](../adr/B0012-billka-verifica-no-emite.md)

Este documento responde a una sola pregunta: **cómo se construye el tramo autónomo → frontera → despacho**
para que un tercero pueda comprobarlo sin pedirnos permiso. No decide el mercado (eso es el roadmap) ni el
calendario. Decide los bytes.

---

## 1. Siete errores del diseño ingenuo (y su corrección)

Un diseño razonable de oído comete estos siete errores. Cada uno rompe una propiedad distinta del producto,
y los siete son baratos de evitar **antes** de escribir código y carísimos después.

| # | Error | Por qué rompe el producto | Corrección |
|---|---|---|---|
| 1 | La constancia incluye `sellado_en` **dentro** de lo hasheado | `verificar` no puede recomputar el hash sin conocer la hora del sellado → necesita nuestra BD → auto-referencia y adiós a la independencia | Separar **contenido** (determinista, hasheable) de **sobre** (tiempos, firma, ancla). El tiempo nunca entra en la huella del contenido |
| 2 | Un solo hash por fichero | Un `.xlsx` re-guardado por Excel cambia de bytes **sin cambiar de datos**: el verificador gritaría manipulación donde solo hubo «guardar» | Dos huellas por fichero: `bytes_sha256` (inmutabilidad del archivo) y `contenido_sha256` (inmutabilidad de los datos) |
| 3 | «Billka firma la constancia» como prueba de anterioridad | Nuestra firma dice *quién* la emitió, no *cuándo*. Podemos firmar hoy un documento de hace un mes | La anterioridad solo la da la **TSA** (RFC 3161). La firma de Billka autentica; no fecha |
| 4 | Ancla diaria = un token sobre la raíz de Merkle | Sin la **prueba de inclusión**, el verificador no puede demostrar que *su* constancia está en ese árbol: acaba llamándonos | El `audit_path` de Merkle viaja **dentro** de la constancia. O más simple para el piloto: **un sello TSA por constancia** |
| 5 | El cruce lee y normaliza «los PDFs mal escaneados» del autónomo | Un PDF escaneado exige OCR: no determinista, costoso, y convierte un hallazgo en un error del programa | El PDF se sella como **documento entregado** y cuenta como `no_interpretable`. No se extraen datos de él |
| 6 | Clave del cruce = NIF emisor + número + fecha | Una fecha mal tecleada deja de ser un `discrepante` y se convierte en **dos ausencias**, que es justo lo que el asesor no necesita | Clave = `(nif_emisor, numero)`. La fecha es **campo comparado**; solo desambigua si hay colisión de número, y entonces se marca `ambiguo` |
| 7 | El despacho sube los documentos a Billka | Nos convierte en custodios de facturación ajena: RGPD, coste de almacenamiento y una responsabilidad que no queremos | El cómputo pesado es **local** (CLI/agente). A la nube solo suben huellas y contadores |

---

## 2. Los artefactos

Un lote es una carpeta. Nada más. Se puede copiar a un pendrive y sigue siendo verificable.

```
lote-2026-11-<cliente>/
├── manifest.json                 # contenido declarado + huellas (determinista)
├── ficheros/
│   ├── entrada/2026-11-facturas.xlsx
│   ├── entrada/ticket-014.pdf
│   └── salida/2026-11-sif-export.csv
├── canonico/                     # derivado, regenerable, hasheado
│   ├── entrada.ndjson
│   └── salida.ndjson
└── constancias/
    ├── constancia-entrada.json
    └── constancia-salida.json
```

### 2.1 `manifest.json` (v1)

```json
{
  "formato": "billka.lote/1",
  "emisor":   { "nif": "12345678Z", "rol": "autonomo" },
  "receptor": { "nif": "B12345678", "rol": "despacho" },
  "periodo":  { "desde": "2026-11-01", "hasta": "2026-11-30" },
  "ficheros": [
    { "ruta": "entrada/2026-11-facturas.xlsx", "bytes": 18273,
      "bytes_sha256": "sha256:9f2c…", "contenido_sha256": "sha256:41ab…",
      "tipo": "excel", "interpretable": true },
    { "ruta": "entrada/ticket-014.pdf", "bytes": 88310,
      "bytes_sha256": "sha256:0c7e…", "tipo": "pdf", "interpretable": false }
  ]
}
```

Reglas duras:

- **No hay `sellado_en`, ni `lote_id` aleatorio, ni nada que varíe entre dos ejecuciones.**
  `lote_id = huella_lote`. Dos lotes idénticos son el mismo lote: idempotencia gratis.
- `huella_lote = sha256(JCS(manifest))` con **JCS = RFC 8785** (JSON canónico), no «ordenar claves a mano».
- `interpretable: false` es un dato, no un error: declara que ese fichero no alimenta el cruce.
- `verificar` **falla cerrado**: formato desconocido, campo obligatorio ausente o hash con prefijo
  de algoritmo que no implementamos → error, nunca «seguimos adelante a ver qué pasa».

### 2.2 `constancia-*.json` (v1)

Misma separación contenido / sobre:

```json
{
  "formato": "billka.constancia/1",
  "tipo": "entrada",
  "contenido": {
    "lote_id": "sha256:7d1a…",
    "huella_lote": "sha256:7d1a…",
    "huella_canonico": "sha256:41ab…"
  },
  "sobre": {
    "recibido_en": "2026-11-12T09:14:03Z",
    "emitida_por": { "nif": "B12345678", "rol": "despacho", "email_verificado": "…" },
    "firma": { "alg": "ed25519", "clave_id": "billka-2026-11", "valor": "base64…" },
    "ancla": { "estado": "pendiente", "tsa": null, "token": null }
  }
}
```

- `huella_constancia = sha256(JCS(contenido))`. **El sobre no entra**: si entrara, la hora y la firma
  formarían parte de lo hasheado y volveríamos al error 1.
- La **firma** cubre `JCS(contenido)` **más** `recibido_en`: autentica quién y cuándo declaró. No prueba
  anterioridad: eso es la TSA.
- La firma es **detached y opcional** en v1. Sin clave, la constancia sigue siendo verificable por hash;
  la firma solo añade «quién la emitió». Si no hay clave, el campo se omite y el verificador lo dice.
- `ancla.estado ∈ {pendiente, sellada, fallida}` y se muestra tal cual. Un ancla fallida publicada vale
  más que un silencio (ADR `B0011`).

## 3. Algoritmos

### 3.1 Normalización canónica de registros (`v1`)

| Campo | Regla | Ejemplo |
|---|---|---|
| importes | entero de **céntimos**, sin separador de miles, sin símbolo | `1.234,56 €` → `123456` |
| fechas | ISO-8601 `YYYY-MM-DD` | `24/11/2026` → `2026-11-24` |
| NIF | mayúsculas, sin guiones, sin espacios | `b-12345678` → `B12345678` |
| número de factura | **string**, `trim`, colapso de espacios, sin ceros perdidos | ` 2026/0042 ` → `2026/0042` |
| texto | Unicode **NFC**, sin BOM | — |
| saltos de línea | `LF` (un `CRLF` no cambia la huella de contenido) | — |
| orden | registros ordenados por `(nif_emisor, numero, fecha)` **antes** de hashear | — |

El NDJSON canónico guarda **un registro por línea**, con claves en orden fijo. Es lo que permite que
`verificar` señale *la fila* y no solo «el fichero cambió».

### 3.2 El cruce

1. Normalizar ambos lados a registros canónicos.
2. Detectar **duplicados en entrada** antes de emparejar (la misma factura entregada dos veces es un
   hallazgo, no un fallo del programa).
3. Indexar por `(nif_emisor, numero)`.
4. Si dos registros comparten clave, desambiguar por fecha+año; si sigue habiendo empate → `ambiguo`,
   **nunca** elegir uno al azar.
5. Comparar `base`, `cuota`, `total` (céntimos) y `fecha`.

Estados de línea:

| Estado | Significado |
|---|---|
| `coincide` | en ambos lados y todos los campos comparados cuadran |
| `ausente_en_salida` | el autónomo lo entregó y el SIF no lo tiene |
| `ausente_en_entrada` | el SIF lo emitió y no hay documento entregado |
| `discrepante` | existe en ambos, difiere algún campo (se listan campo y ambos valores) |
| `ambiguo` | clave repetida sin desambiguación posible |
| `duplicado_entrada` | el mismo documento entregado más de una vez |
| `no_interpretable` | fichero sellado (PDF, imagen) del que no se extraen datos |

Los cuatro primeros son el producto; los tres últimos son **datos técnicos** que evitan que el asesor lea
un «no sé». Criterio de salida de la Etapa E: **cero líneas sin estado**.

## 4. Modos de trabajo

Billka no necesita una sola forma de ejecutarse: necesita **cuatro**, y solo tres entran en 2026.

| Modo | Dónde corre | Qué datos toca | Etapa | Por qué |
|---|---|---|---|---|
| **M1 · CLI local** | máquina del despacho | **todos** (ficheros, canónico, cruce) | D | Es el núcleo verificable: `sellar`, `verificar`, `cruzar`. Sin red salvo la TSA |
| **M2 · Agente de carpeta** | máquina del despacho, en segundo plano | todos, **local** | D | Resuelve el fallo real del piloto: que nadie se acuerde de ejecutar un comando. Vigila `Billka/entrada/<cliente>/<mes>/` y sella al aparecer ficheros |
| **M3 · Nube mínima** | nuestra infra | solo **hashes y contadores** | F | Encola el sello TSA y sirve `/v/{codigo}`. Un Postgres diminuto, sin documentos |
| **M4 · Bandeja web del autónomo** | nuestra infra | documentos de terceros | fuera de 2026 | Nos convierte en custodios: RGPD y coste. Hoy el autónomo entrega por WhatsApp y eso funciona |

**M2 es la pieza que decide si el piloto se usa o no.** Una CLI que hay que recordar lanzar el día 5 de cada
mes se abandona en marzo. Un agente que sella lo que aparece en una carpeta, no.

## 5. Quién custodia qué

| Pieza | Custodio | Obligación |
|---|---|---|
| Registros de facturación — conservación durante **4 años** (art. 8.2.c RRSIF, que remite al art. 66 LGT) | **El obligado** (autónomo y despacho), en su SIF | RRSIF. Nunca Billka |
| Documentos entregados | **El despacho**, en su carpeta `lote/` | ninguna nuestra |
| Hashes, constancias, tokens TSA | Billka (copia) y el despacho (original) | servir `/v/{codigo}` y no perder el token |
| Prueba de anterioridad | **La TSA** | disponibilidad de su servicio |

Si Billka desapareciera mañana, el despacho conserva lote + constancias + tokens y `billka verificar` sigue
funcionando con el binario que ya tiene. Eso es lo que se vende; si no se cumple, no hay producto.

## 6. El ciclo mensual (quién hace qué)

| Cuándo | Quién | Qué ocurre | Qué fallo se detecta |
|---|---|---|---|
| días 1–5 | autónomo | deja sus ficheros en la carpeta o los manda | **nada entregado** ese mes |
| al aparecer | M2 (agente) | sella la entrada y escribe la constancia | fichero corrupto, lote vacío |
| días 5–18 | despacho | pasa los datos a su SIF como siempre | — |
| día 18 | despacho | exporta los registros del periodo a `salida/` | **el SIF no exporta** → no hay salida → no hay cruce (criterio de admisión del piloto) |
| día 18 | M1 | `billka cruzar` → informe | ausentes, discrepantes, duplicados |
| día 18–20 | asesor | revisa el informe y corrige donde toca | lo que el asesor decide no corregir queda **documentado** |
| fin de mes | M3 | ancla diaria y página pública | TSA caída → `pendiente` publicado |

**Lote corregido**: si el autónomo reenvía documentos, se sella un lote **nuevo** que referencia al anterior
(`reemplaza_a`). Nunca se reescribe una constancia emitida.

## 7. El ancla: dos diseños y una elección

| Diseño | Coste | Complejidad | Cuándo |
|---|---|---|---|
| **Un sello TSA por constancia** | céntimos por constancia | baja: sin estado global ni pruebas | **Elegido para el piloto (F)** |
| Merkle diario + un token por día | céntimos por día | media: hace falta `audit_path`, `tree_size` y publicar la raíz | solo si el volumen lo exige |

Si algún día se usa Merkle, la prueba de inclusión **viaja dentro de la constancia**: sin ella, verificar
exige llamarnos y la independencia se pierde (error 4).

Verificación offline del sello, sin nuestro software:

```bash
openssl ts -verify -in ancla.tsr -data imprint.bin -CAfile tsa.pem
```

**Límite que hay que decir en voz alta:** el ancla prueba **existencia**, no **ausencia**. Demuestra que un
hash existía el día D; no demuestra que no hubiera otras facturas ese día. No sirve para «probar que el
autónomo no ocultó nada» — para eso está el cruce, que compara dos lados.

**La cadena de hashes es control interno, no prueba externa.** Detecta manipulación en nuestra BD y da orden;
frente a un tercero no prueba nada por sí sola, porque no puede demostrar que no falta un eslabón.

## 8. Los 8 vectores de la Etapa C

Se escriben **antes** de la implementación y se congelan. Si un vector cambia, cambia el formato y hay
que versionarlo.

| # | Caso | Resultado esperado |
|---|---|---|
| 1 | lote mínimo válido (1 CSV, 3 facturas) | `huella_lote` congelada; `verificar` → `0` |
| 2 | dos lotes con los mismos datos en rutas distintas | `bytes_sha256` distinto, `huella_lote` **igual** → mismo lote |
| 3 | `.xlsx` re-guardado por Excel (solo metadatos) | `bytes_sha256` distinto, `contenido_sha256` igual → `verificar` `0` con aviso `REGUARDADO` |
| 4 | un dígito cambiado en una fila | `contenido_sha256` distinto → `verificar` `1`, con **fichero y línea** |
| 5 | fichero añadido al lote sin actualizar el manifest | `verificar` `1`: hay un fichero que el manifest no declara |
| 6 | manifest sin `bytes_sha256` | rechazo en seco (fail-closed) |
| 7 | `formato: "billka.lote/999"` | rechazo en seco (versión que no sabemos leer) |
| 8 | CSV con `CRLF` y con `LF` | misma `huella` de contenido (normalización `v1`) |

El vector 3 y el 4 juntos son el argumento de venta entero: **distingue «guardar» de «manipular»**.

## 9. Decisiones abiertas

| Decisión | Opciones | Cuándo | Coste de equivocarse |
|---|---|---|---|
| Ancla | sello por constancia **vs** Merkle diario | Etapa F | bajo: el formato ya lleva el campo; se puede empezar con lo simple |
| Firma del despacho | obligatoria en v1 **vs** opcional | Etapa D | medio: sin firma, el despacho puede negar haber recibido |
| Entrada | plantilla CSV obligatoria **vs** tolerante | Etapa C | alto: la tolerancia sin límite convierte el cruce en un OCR |
| TSA | FNMT, Camerfirma u otra | Etapa F | bajo (intercambiable), pero hay que medir el coste real por sello |
| Copia al autónomo | email con adjunto **vs** link de un solo uso | Etapa G | bajo |

## 10. Lo que este documento no decide

El precio y el calendario (eso es `billka_roadmap.html`), la elección de la TSA, el diseño del informe para
el asesor y el despliegue. Tampoco autoriza a implementar nada antes del 17-nov-2026: hasta entonces,
Komanda tiene prioridad sobre este documento.

## Referencias

- [`B0012`](../adr/B0012-billka-verifica-no-emite.md) — qué es y qué no es Billka (decisión marco).
- [`ARCHITECTURE.md`](../../ARCHITECTURE.md) §5 — flujo de un lote en el sistema completo.
- [`docs/fiscal/hash-chain.md`](../fiscal/hash-chain.md) — patrón de cadena heredado de Komanda.
- `komanda` `V4` (cadena + `chain_anchor`) y `V17` (sello diario) — mecanismo ya probado que se porta.
