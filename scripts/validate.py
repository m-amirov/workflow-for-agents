#!/usr/bin/env python3
"""Static validation of Workflow for Agents skills and local Markdown references."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import sys
from urllib.parse import unquote

NAME_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
FRONTMATTER_RE = re.compile(r"\A---\s*\n(?P<meta>.*?)\n---\s*\n", re.DOTALL)
LINK_RE = re.compile(r"(?<!!)\[[^\]]+\]\(([^)]+)\)")
FIELD_RE = re.compile(r"^(name|description):\s*(.*?)\s*$", re.MULTILINE)
IMPLEMENTED_RE = re.compile(
    r"^\|\s*[^|]+\|\s*([a-z0-9-]+)\s*\|[^|]*\|\s*implemented\s*\|\s*$",
    re.MULTILINE,
)


def parse_frontmatter(content: str) -> tuple[dict[str, str], list[str]]:
    match = FRONTMATTER_RE.match(content)
    if not match:
        return {}, ["Missing YAML frontmatter beginning with ---"]
    meta = match.group("meta")
    fields = list(FIELD_RE.finditer(meta))
    result: dict[str, str] = {}
    errors: list[str] = []
    for index, field in enumerate(fields):
        key, raw = field.group(1), field.group(2).strip()
        if key in result:
            errors.append(f"Duplicate frontmatter key: {key}")
            continue
        if raw in (">", ">-", "|", "|-"):
            end = fields[index + 1].start() if index + 1 < len(fields) else len(meta)
            lines = meta[field.end():end].splitlines()
            text = " ".join(line.strip() for line in lines if line.startswith((" ", "\t"))).strip()
        else:
            text = raw.strip("'\"")
        result[key] = text
    return result, errors


def validate_repository(root: Path) -> tuple[list[str], dict[str, int]]:
    root = root.resolve()
    errors: list[str] = []
    skills_root = root / "skills"
    if not skills_root.is_dir():
        return ["Missing skills directory"], {"skills": 0, "links": 0}
    names: dict[str, Path] = {}
    skills = sorted(skills_root.rglob("SKILL.md"))
    for path in skills:
        try:
            content = path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError) as error:
            errors.append(f"{path.relative_to(root)}: cannot read: {error}")
            continue
        fields, faults = parse_frontmatter(content)
        rel = path.relative_to(root)
        errors.extend(f"{rel}: {issue}" for issue in faults)
        name = fields.get("name", "")
        description = fields.get("description", "")
        if not NAME_RE.fullmatch(name) or len(name) > 64:
            errors.append(f"{rel}: invalid name {name!r}")
        if name != path.parent.name:
            errors.append(f"{rel}: name must equal directory {path.parent.name!r}")
        if name in names:
            errors.append(f"{rel}: duplicate skill name (also {names[name].relative_to(root)})")
        names[name] = path
        if not description or len(description) > 1024:
            errors.append(f"{rel}: description must contain 1–1024 characters")

    links = 0
    for md in sorted(root.rglob("*.md")):
        if any(part in {".git", ".venv", "node_modules"} for part in md.parts):
            continue
        try:
            content = md.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError) as error:
            errors.append(f"{md.relative_to(root)}: cannot read: {error}")
            continue
        for match in LINK_RE.finditer(content):
            destination = match.group(1).strip().split(maxsplit=1)[0].strip("<>")
            if not destination or destination.startswith(("#", "/", "mailto:")):
                continue
            if re.match(r"^[a-z][a-z0-9+.-]*:", destination, re.IGNORECASE):
                continue
            destination = unquote(destination.split("#", 1)[0].split("?", 1)[0])
            if not destination:
                continue
            links += 1
            target = (md.parent / destination).resolve()
            if not target.is_relative_to(root) or not target.exists():
                errors.append(f"{md.relative_to(root)}: broken relative link: {match.group(1)}")

    catalog_path = root / "docs" / "SKILL_CATALOG.md"
    if not catalog_path.is_file():
        errors.append("Missing docs/SKILL_CATALOG.md")
    else:
        catalog = catalog_path.read_text(encoding="utf-8")
        implemented = set(IMPLEMENTED_RE.findall(catalog))
        for name in sorted(implemented - names.keys()):
            errors.append(f"Catalog marks {name!r} implemented but SKILL.md is missing")
        for name in sorted(names.keys() - implemented):
            errors.append(f"SKILL.md for {name!r} exists but catalog is not marked implemented")


    fixture = root / "evals" / "cases" / "foundation.json"
    if not fixture.is_file():
        errors.append("Missing foundation eval fixture")
    else:
        try:
            suite = json.loads(fixture.read_text(encoding="utf-8"))
        except (OSError, ValueError) as exc:
            errors.append(f"Invalid foundation eval fixture: {exc}")
        else:
            if not isinstance(suite, dict) or suite.get("schema") != 1 or not isinstance(suite.get("cases"), list):
                errors.append("Invalid foundation eval fixture schema")
            else:
                covered: set[str] = set()
                for index, case in enumerate(suite["cases"]):
                    if not isinstance(case, dict):
                        errors.append(f"Eval case {index}: expected object")
                        continue
                    name = case.get("skill")
                    if not isinstance(name, str) or name not in names or name in covered:
                        errors.append(f"Eval case {index}: unknown or duplicate skill: {name!r}")
                        continue
                    covered.add(name)
                    for variant in ("positive", "negative"):
                        value = case.get(variant)
                        if not isinstance(value, dict) or any(
                            not isinstance(value.get(field), str) or not value[field].strip()
                            for field in ("prompt", "expected_behavior")
                        ):
                            errors.append(f"Eval case {index}: missing {variant} prompt/expected_behavior")
                    prohibited = case.get("prohibited_behavior")
                    if not isinstance(prohibited, list) or not prohibited or any(
                        not isinstance(item, str) or not item.strip() for item in prohibited
                    ):
                        errors.append(f"Eval case {index}: missing prohibited behavior")
                for name in sorted(set(names) - covered):
                    errors.append(f"No foundation eval case for {name}")
    return errors, {"skills": len(skills), "links": links}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    args = parser.parse_args()
    errors, summary = validate_repository(args.root)
    for issue in errors:
        print(f"ERROR: {issue}", file=sys.stderr)
    print(f"Validated {summary['skills']} skill(s), {summary['links']} internal link(s); {len(errors)} error(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())

