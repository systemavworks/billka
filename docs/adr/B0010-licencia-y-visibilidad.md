# ADR B0010 · Licencia y visibilidad del repositorio

**Estado**: Propuesto — **bloquea el primer push** · **Fecha**: 2026-11-10

## Contexto

- `github.com/systemavworks/billka` es **público**, rama `main`, 1 commit: `README.md` de 8 B
  (literalmente `# billka`) y `LICENSE` de 1.211 B que es la **Unlicense** (dominio público,
  «for any purpose, commercial or non-commercial»).
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

**Pendiente.** Recomendación: **A**.

Mientras no se decida, el árbol queda **versionado en local y sin push**. El `LICENSE` local no
se toca. Secuencia exacta cuando se decida: `docs/runbook/primer-push.md`.

## Consecuencias

- `scripts/deploy.sh` sigue abortando con `exit 1`: no hay destino ni licencia de despliegue.
- El riesgo de pérdida de historial queda mitigado con el `git init` del 10-nov-2026;
  el de publicación accidental, con este ADR.
