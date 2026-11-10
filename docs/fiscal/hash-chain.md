# Cadena de huellas

Patrón previsto:

`H_n = SHA-256(H_{n-1} || canonical_payload_n)`

Objetivo:

- Evidencia de integridad.
- Detección de manipulación.
- Auditoría reproducible.

La canonicalización fiscal debe cerrarse antes de producción.
