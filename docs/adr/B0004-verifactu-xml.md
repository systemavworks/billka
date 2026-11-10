# ADR B0004 · VeriFactu, XML, huella y QR

Estado: Propuesto

La lógica fiscal se encapsula en `fiscal-kit`. Ningún QR propio debe venderse como cumplimiento VeriFactu por sí mismo.

> **Revisado por `B0012` (10-nov-2026)**: `fiscal-kit` deja de generar XML ni QR Veri*Factu propio;
> solo **lee** XML de terceros para el cruce y calcula huellas de lote. El QR de la AEAT se usa como
> fuente, no como producto.

