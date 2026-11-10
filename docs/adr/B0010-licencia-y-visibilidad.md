# ADR B0010 · Licencia y visibilidad del repositorio

**Estado**: Aceptado parcialmente — opción **B** ejecutada · **Fecha**: 2026-11-10

> **Actualización 10-nov-2026 (posterior a la redacción original de este ADR).** El push se
> ejecutó con el `LICENSE` propietario en su propio commit (`019070c`) y el árbol en `3fd574b`.
> La **visibilidad del repositorio sigue siendo pública**, así que el ADR no está cerrado: la
> recomendación A (privado) continúa disponible como palanca en GitHub, sin tocar el historial.

## Contexto

- `github.com/systemavworks/billka` es **público**, rama `main`. En la fecha de redacción tenía
  1 commit: `README.md` de 8 B (literalmente `# billka`) y `LICENSE` de 1.211 B que es la
  **Unlicense** (dominio público, «for any purpose, commercial or non-commercial»). Al ejecutar
  el push se comprobó que el remoto tenía **3 commits** (el inicial, `LICENSE` y el logo).
- El `LICENSE` de este árbol dice **propietaria, todos los derechos reservados**.
- Son incompatibles. El commit ya publicado con la dedicación al dominio público **sigue siendo
  público para siempre**: un push posterior no lo elimina del historial.

## Opciones

| Opción | Efecto | Reversibilidad |
|---|---|---|
| **A. Propietaria + repo privado** | Coherente con un producto que se vende | Alta: no hay nada que «despublicar» |
| B. Propietaria + repo público | El `LICENSE` local sustituye al remoto en su propio commit | Baja: el commit Unlicense queda en el historial |
| C. Asumir dominio público | Cualquiera puede explotarlo comercialmente | Nula |

## Decisión

**Opción B ejecutada el 10-nov-2026**, a instancias del titular del repositorio. Se asume la
consecuencia: el commit con la Unlicense (`34f5741`) permanece público y cualquiera puede
ampararse en él para el contenido **de ese commit** (un `README.md` de una línea). La
recomendación A (repositorio privado) sigue abierta y no requiere reescribir historial.

`scripts/deploy.sh` sigue abortando con `exit 1`: no hay destino de despliegue decidido.

## Consecuencias

- `scripts/deploy.sh` sigue abortando con `exit 1`: no hay destino ni licencia de despliegue.
- El riesgo de pérdida de historial quedó mitigado con el `git init` y el push del 10-nov-2026.
- Queda una decisión abierta y barata: pasar el repositorio a **privado**. No requiere reescribir
  historial ni tocar el `LICENSE`; es una casilla en GitHub.
- Si algún día se quiere licencia comercial, el `LICENSE` propietario ya está publicado y es la
  referencia vigente: los commits posteriores a `019070c` no están cubiertos por la Unlicense.
