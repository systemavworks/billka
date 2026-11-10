# fiscal-kit · dominio fiscal compartido (Billka ↔ Komanda)

Paquete Kotlin: **`es.billka.fiscal`** (renombrado desde `es.billka.fiskal` el 10-nov-2026:
el módulo es `fiscal-kit`, los docs `docs/fiscal/` y el core `domain/fiscal`; la `k` era una
errata del generador — ver `billka_auditoria_2026-11-08.html`).

Estado: **vacío a propósito**. Los 22 stubs `.kt` que había (dos líneas, `export {};`) no
compilaban y se borraron. Ver `../core/README.md`.

## Qué se comparte (y qué no)

Según ADR 0009 canónico de Komanda (`komanda/docs/adr/0009-…`, decisión 4):

- **Sí**: adaptador SIGN ES, cliente de cotejo AEAT, *builder* de XML Veri*Factu,
  huella/encadenamiento, validadores NIF/territorio, *rate limiting*.
- **No**: runtime, base de datos ni despliegue. `fiscal-kit` es librería **versionada con semver**
  y cada consumidor pinnea su versión.

## API prevista

| Paquete | Contenido |
|---|---|
| `es.billka.fiscal.verifactu` | huella, QR, XML (`HuellaCalculator`, `QrGenerator`, `XmlBuilder`) |
| `es.billka.fiscal.sign` | SIGN ES (fiskaly): alta de organización, firma, estado |
| `es.billka.fiscal.cotejo` | cotejo AEAT bajo demanda (sin scraping masivo) |
| `es.billka.fiscal.nif` | validación de NIF y territorios (común, País Vasco, Navarra) |
| `es.billka.fiscal.hash` | cadena SHA-256 y anclajes |
| `es.billka.fiscal.models` | `Invoice`, `InvoiceType`, `TaxRate`, `FiscalPeriod` |

## Regla de trabajo

**Sin vectores de prueba no se escribe implementación.** La etapa D del roadmap
(`billka_roadmap.html`) son los fixtures `entrada → huella / QR / XML`; la etapa E es esta
librería en verde contra ellos. Sin vectores, dos implementaciones «correctas» divergen y la
AEAT rechaza.

## Comandos

```bash
cd fiscal-kit && gradle build          # build standalone (sin wrapper propio; el canónico es core/)
cd core && ./gradlew :fiscal-kit:test  # vía el wrapper del proyecto que lo consume
```
