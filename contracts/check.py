#!/usr/bin/env python3
"""Verificador de contratos de eventos de Billka (CI + local).

Reglas
  1. Todo schema es JSON Schema 2020-12 válido.
  2. Los `$id` son únicos y terminan exactamente en la ruta relativa del fichero.
  3. Cada evento de `v<N>.examples.json` valida contra el sobre (`envelope.schema.json`)
     Y contra el schema de datos de su tipo; `type` y `schemaversion` coinciden con la carpeta.
  4. Cada evento de `v<N>.invalid.json` debe FALLAR: un "inválido" que se acepta demuestra
     que el schema no comprueba nada.
  5. Inmutabilidad: un schema con `"x-status": "released"` está congelado; su sha256 debe
     coincidir con `contracts/LOCK.json`. Para cambiarlo se crea `v<N+1>`, nunca se edita.
  6. Modo estricto (por defecto): todo schema debe estar `released` y registrado en LOCK.
     Un contrato en `draft` todavía puede cambiar, así que no vale para bloquear un merge.

Uso
  python3 contracts/check.py            # estricto (hoy FALLA a propósito: todo es draft)
  python3 contracts/check.py --draft    # valida lo que hay y avisa de los borradores
  python3 contracts/check.py --lock     # registra en LOCK.json los schemas released nuevos

Requiere: pip install -r requirements-dev.txt  (jsonschema)
"""
from __future__ import annotations

import hashlib
import json
import sys
from datetime import datetime
from pathlib import Path

try:
    from jsonschema import Draft202012Validator, FormatChecker
except ImportError:  # pragma: no cover - mensaje para humanos, no traza
    print("ERROR falta jsonschema: pip install -r requirements-dev.txt")
    raise SystemExit(2)

ROOT = Path(__file__).resolve().parent
ID_BASE = "https://billka.es/contracts/"
LOCK = ROOT / "LOCK.json"
ENVELOPE = ROOT / "envelope.schema.json"


def load(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def make_format_checker() -> FormatChecker:
    """FormatChecker con `date-time` verificado de verdad.

    `jsonschema` solo comprueba `date-time` si está instalado el paquete opcional
    `rfc3339-validator`; si falta, el formato se ignora EN SILENCIO y un schema que dice
    `format: date-time` acepta "mañana". Aquí se valida con la biblioteca estándar
    (RFC 3339 = ISO 8601 con offset obligatorio) y sin dependencias extra.
    """
    checker = FormatChecker()

    @checker.checks("date-time", raises=(ValueError, TypeError))
    def _is_rfc3339(value):
        if not isinstance(value, str):
            return True
        moment = datetime.fromisoformat(value[:-1] + "+00:00" if value.endswith("Z") else value)
        if moment.tzinfo is None:
            raise ValueError("falta el offset de zona horaria (Z o ±hh:mm)")
        return True

    return checker


def check_id(schema: dict, path: Path, seen: dict, errors: list) -> None:
    sid = schema.get("$id")
    rel = path.relative_to(ROOT).as_posix()
    if not sid:
        errors.append(f"{rel}: falta $id")
        return
    expected = ID_BASE + rel
    if sid != expected:
        errors.append(f"{rel}: $id debe ser {expected} (es {sid})")
    if sid in seen:
        errors.append(f"{rel}: $id duplicado; ya lo usa {seen[sid]}")
    seen[sid] = rel


def main() -> int:
    do_lock = "--lock" in sys.argv
    do_draft = "--draft" in sys.argv
    errors: list = []
    warnings: list = []
    fmt = make_format_checker()

    if not ENVELOPE.exists():
        print(f"ERROR falta {ENVELOPE.relative_to(ROOT)}")
        return 1
    envelope = load(ENVELOPE)
    Draft202012Validator.check_schema(envelope)
    envelope_v = Draft202012Validator(envelope, format_checker=fmt)

    seen_ids: dict = {}
    check_id(envelope, ENVELOPE, seen_ids, errors)

    lock = load(LOCK) if LOCK.exists() else {}
    new_lock = dict(lock)
    drafts: list = []

    for schema_path in sorted((ROOT / "events").glob("*/v*.schema.json")):
        rel = schema_path.relative_to(ROOT).as_posix()
        etype = schema_path.parent.name
        try:
            version = int(schema_path.name.split(".")[0][1:])
        except ValueError:
            errors.append(f"{rel}: nombre fuera de convención (v<N>.schema.json)")
            continue
        schema = load(schema_path)
        try:
            Draft202012Validator.check_schema(schema)
        except Exception as exc:  # noqa: BLE001
            errors.append(f"{rel}: schema inválido: {exc}")
            continue
        check_id(schema, schema_path, seen_ids, errors)
        data_v = Draft202012Validator(schema, format_checker=fmt)

        def full_errors(evt: dict) -> list:
            out = [f"envelope: {e.message}" for e in envelope_v.iter_errors(evt)]
            if evt.get("type") != etype:
                out.append(f"type '{evt.get('type')}' no coincide con la carpeta '{etype}'")
            if evt.get("schemaversion") != version:
                out.append(f"schemaversion {evt.get('schemaversion')} no coincide con v{version}")
            data = evt.get("data")
            if isinstance(data, dict):
                out += [f"data: {e.message}" for e in data_v.iter_errors(data)]
            return out

        base = schema_path.name.replace(".schema.json", "")
        ex_path = schema_path.with_name(f"{base}.examples.json")
        inv_path = schema_path.with_name(f"{base}.invalid.json")
        for companion in (ex_path, inv_path):
            if not companion.exists():
                errors.append(
                    f"{rel}: falta {companion.name} "
                    "(sin ejemplos no hay forma de notar que el schema se ha roto)"
                )

        if ex_path.exists():
            examples = load(ex_path)
            if not isinstance(examples, list) or not examples:
                errors.append(f"{ex_path.relative_to(ROOT).as_posix()}: debe ser una lista con al menos 1 evento")
            else:
                for i, evt in enumerate(examples):
                    for msg in full_errors(evt):
                        errors.append(f"{ex_path.relative_to(ROOT).as_posix()}[{i}] debía ser válido: {msg}")

        if inv_path.exists():
            invalids = load(inv_path)
            if not isinstance(invalids, list) or not invalids:
                errors.append(f"{inv_path.relative_to(ROOT).as_posix()}: debe ser una lista con al menos 1 evento")
            else:
                for i, evt in enumerate(invalids):
                    if not full_errors(evt):
                        errors.append(f"{inv_path.relative_to(ROOT).as_posix()}[{i}] debía FALLAR y se aceptó")

        status = schema.get("x-status")
        if status == "released":
            digest = sha(schema_path)
            if rel not in lock:
                if do_lock:
                    new_lock[rel] = digest
                else:
                    errors.append(
                        f"{rel}: released sin registrar en LOCK.json "
                        "(ejecuta: python3 contracts/check.py --lock)"
                    )
            elif lock[rel] != digest:
                errors.append(f"{rel}: schema released MODIFICADO; crea v{version + 1} en vez de editarlo")
        else:
            drafts.append(rel)
            if status not in (None, "draft"):
                errors.append(f"{rel}: x-status desconocido '{status}' (usa draft o released)")

    for folder in sorted(p for p in (ROOT / "events").iterdir() if p.is_dir()):
        if not list(folder.glob("v*.schema.json")):
            errors.append(f"events/{folder.name}: carpeta sin ningún v<N>.schema.json")

    for rel in lock:
        if not (ROOT / rel).exists():
            errors.append(f"{rel}: figura en LOCK.json pero el fichero no existe")

    if drafts:
        message = f"{len(drafts)} contrato(s) en estado draft: " + ", ".join(drafts)
        if do_draft:
            warnings.append(message)
        else:
            errors.append(
                message + " — usa --draft para validarlos; --lock no congela borradores"
            )

    if do_lock and drafts:
        errors.append("no se puede congelar con contratos en draft: cambia x-status a released primero")

    if do_lock and not errors:
        LOCK.write_text(json.dumps(dict(sorted(new_lock.items())), indent=2) + "\n", encoding="utf-8")
        print(f"LOCK.json actualizado ({len(new_lock)} schemas released)")

    for warning in warnings:
        print(f"AVISO {warning}")
    if errors:
        for error in errors:
            print(f"ERROR {error}")
        return 1

    print("CONTRATOS OK (draft)" if drafts else "CONTRATOS OK")
    return 0

if __name__ == "__main__":
    sys.exit(main())
