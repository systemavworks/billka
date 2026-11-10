# Runbook · primer push de Billka

**Estado: ejecutado el 10-nov-2026.** `origin/main` = `3fd574b`. Se hizo en dos commits: primero
`LICENSE` propietario (`019070c`) y después el árbol completo (`3fd574b`), para que el historial
deje constancia del cambio de licencia. El remoto tenía 3 commits previos
(`34f5741` inicial con Unlicense, `6d246e5` LICENSE, `400ad79` logo).

Lo que sigue se conserva como registro de cómo se hizo, no como tarea pendiente.

## 0. Requisito (resuelto a medias)

ADR B0010: **licencia propietaria ya publicada**; la **visibilidad** del repositorio sigue
abierta. Si se decide privado: GitHub → Settings → General → Danger Zone → *Change repository
visibility*. Si se queda público, conviene revisar que no haya nada que no deba serlo.

## 1. Alinear con el remoto (tiene 1 commit: `README.md` + `LICENSE`)

```bash
cd ~/Desarrollo/saas_proyectos/billka
git fetch origin
git log --oneline origin/main          # confirmar qué hay publicado
git reset --mixed origin/main          # partir del remoto sin duplicar historia ni perder ficheros
git status                             # todo el árbol debe aparecer como "sin seguimiento"/modificado
```

`--mixed` mueve `HEAD` pero **no toca el árbol de trabajo**: no se pierde nada local.

## 2. Resolver la licencia ANTES de subir

- **Opción A (recomendada, privada):** GitHub → Settings → General → Danger Zone →
  *Change repository visibility* → Private. Después commitear el `LICENSE` propietario.
- **Opción B (pública, propietaria):** commitear el `LICENSE` local en un commit propio
  (`licencia: propietaria`) **antes** de añadir el árbol, para que el historial quede explícito.
- **Opción C (dominio público):** sustituir el `LICENSE` local por la Unlicense.

## 3. Commit y push

```bash
git add -A
git commit -m "scaffold: árbol Billka saneado (sin lógica fiscal)"
git push -u origin main
```

## 4. Verificar

```bash
git log --oneline -3
git status                             # limpio
python3 contracts/check.py --draft     # contratos en modo borrador
make build                             # compila (0 fuentes todavía)
```

A partir de aquí, `make contracts` (sin `--draft`) debe empezar a ponerse verde solo cuando los
contratos se congelen, y `make test` cuando exista el primer test real.
