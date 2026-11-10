# Cotejo AEAT

El QR fiscal suele contener una URL de validación/cotejo con:

- NIF emisor.
- Número/serie.
- Fecha.
- Importe.

Uso previsto:

- Cotejo puntual.
- Bajo demanda.
- Sin scraping masivo.
- Sin prometer disponibilidad de API pública AEAT.

Jerarquía tras el ADR `B0012`: la AEAT ya permite al destinatario comprobar por QR que una factura
consta, así que este cotejo es **una fuente más del cruce**, nunca un servicio de pago ni el
producto. Lo que se vende es la constancia de la frontera (entrada, salida, cruce y ancla).
