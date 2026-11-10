# Threat model Billka

Riesgos principales:

- Mezcla de datos entre tenants.
- Confusión Komanda/Billka en responsabilidad SIF.
- Secretos SIGN ES filtrados.
- Manipulación de facturas o cadena.
- Root comprometido en caja única.
- Backups sin cifrar.

Mitigaciones:

- RLS.
- Backends y BD separados.
- Secretos separados.
- Hardening.
- Backups off-box.
- Monitorización.
- Logs sin datos sensibles.
