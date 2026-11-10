# ADR B0009 · Billka convive en la misma caja (puntero al canónico)

Estado: **sustituido por el canónico** · Fecha: 2026-11-08 · Actualizado: 2026-11-10

Billka **no mantiene copia propia** de este ADR: dos redacciones del mismo número divergen en
silencio (hallazgo de la auditoría del 8-nov-2026). La única versión válida es:

> `komanda/docs/adr/0009-billka-producto-paralelo-caja-unica.md`

Ahí están las 6 decisiones (proyecto Docker propio, dos Postgres, frontera SIF, `fiscal-kit`
semver pinneado, secuencia Komanda-primero, disparadores de separación física), el riesgo
aceptado y sus mitigaciones. Lo que sigue se conserva solo como resumen de la decisión; si hay
conflicto, gana el canónico.

## Contexto

Komanda es un SaaS de gestión para hostelería, TPV-agnóstico, con integración, ERP/SGA, integridad y Security Hub. Su frontera legal/técnica es clara: Komanda no es SIF; integra información del TPV/SIF del cliente.

Billka nace como producto paralelo para empresas y autónomos de España, orientado a:

- Cotejo/verificación de facturas contra AEAT.
- Generación de QR fiscales cuando aplique.
- Emisión opcional vía SIGN ES u otro proveedor declarado.
- Evidencia criptográfica y trazabilidad.

## Decisión

Billka puede compartir hardware con Komanda, pero no runtime ni datos.

| Eje | Decisión | Motivo |
|---|---|---|
| Runtime | Docker Compose separado: `-p billka` | Un deploy/crash de Billka no toca Komanda |
| Backend | Servicio propio `billka-core` | Aislamiento de responsabilidad |
| Datos | PostgreSQL propio `billka-db` | Sin RLS cruzado ni mezcla RGPD |
| Fiscal | `fiscal-kit` versionado | Se comparte dominio, no runtime |
| Emisión | Billka C-2 vive aislada | Protege la frontera “Komanda no es SIF” |
| Secuencia | Komanda primero; Billka después | Cero riesgo al deadline de Komanda |
| Infra | Misma caja inicialmente | coste bajo y operación simple |

## Frontera fiscal

Si Billka emite registros de facturación, esa parte debe tratarse como software/proceso fiscal declarado o integrarse con proveedor especializado.

Billka no debe contaminar a Komanda con responsabilidad de SIF.

## Datos

- Una BD para Komanda.
- Una BD para Billka.
- Backups separados.
- PITR desde el primer piloto.
- Región UE.

## Recursos

La caja inicial puede ser suficiente para pilotos si el consumo se mantiene bajo.

Disparadores de separación:

- Disco PostgreSQL > 70 %.
- CPU PostgreSQL sostenida > 60 %.
- Entrada de clientes de pago.
- Necesidad de HA.
- Incidente de seguridad o aislamiento insuficiente.

## Riesgo aceptado

Una sola caja implica kernel, disco y root compartidos. Se mitiga con:

- Hardening.
- Backups off-box.
- Límites por contenedor.
- Monitorización.
- Usuarios y secretos separados.
- Sin credenciales cruzadas.

## Consecuencias

- Billka puede crecer sin refactor profundo.
- Komanda mantiene su narrativa y frontera.
- El dominio fiscal se reutiliza mediante librería versionada.
- La separación física futura será operativa, no arquitectónica.
