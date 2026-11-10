# VeriFactu · notas de diseño

Referencias principales:

- RD 1007/2023.
- Orden HAC/1177/2024.
- Calendario vigente según normativa aplicable.

Notas:

- Un QR propio no es cumplimiento VeriFactu.
- **Billka no emite registros de facturación** (ADR `B0012`): si algún día lo hiciera, tendría que
  aislarse y tratarse como frontera SIF, con las obligaciones del RRSIF y la unicidad de
  facturación. Por eso no lo hace.
- El XML de terceros se **lee** para el cruce; no se genera.
- Komanda permanece como integrador/gestor, no SIF.
