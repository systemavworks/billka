# Runbook · primer push de Billka

El árbol está versionado en local desde el 10-nov-2026 (`git init -b main`, remoto `origin`
configurado), pero **no se ha hecho push**: el primer push es irreversible porque el remoto ya
tiene un commit con la **Unlicense** (dominio público). Ver `docs/adr/B0010-licencia-y-visibilidad.md`.

## 0. Requisito

ADR B0010 decidido: licencia definitiva + visibilidad del repositorio.

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
