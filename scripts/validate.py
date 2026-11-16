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
SHA_RE = re.compile(r"^[0-9a-f]{40}$")
FRONTMATTER_RE = re.compile(r"\A---\s*\n(?P<meta>.*?)\n---\s*\n", re.DOTALL)
LINK_RE = re.compile(r"(?<!!)\[[^\]]+\]\(([^)]+)\)")
FIELD_RE = re.compile(r"^(name|description):\s*(.*?)\s*$", re.MULTILINE)
KNOWLEDGE_FIELD_RE = re.compile(r"^([a-z][a-z0-9_]*):\s*(.*?)\s*$", re.MULTILINE)
IMPLEMENTED_RE = re.compile(
    r"^\|\s*[^|]+\|\s*([a-z0-9-]+)\s*\|[^|]*\|\s*implemented\s*\|\s*$",
    re.MULTILINE,
)
KNOWLEDGE_PATTERN_REQUIRED_FIELDS = (
    "title", "status", "source_repository", "source_sha", "reuse_scope",
    "source_verification", "ci_verification", "cross_project_verification",
)
KNOWLEDGE_PATTERN_REQUIRED_SECTIONS = (
    "Контекст", "Механизм", "Алгоритм", "Ограничения и антипримеры",
    "Источники", "Проверка повторного применения",
)
KNOWLEDGE_STATUSES = {"VERIFIED", "PARTIAL", "UNKNOWN"}
KNOWLEDGE_VERIFICATION_STATUSES = {
    "SOURCE_REVIEWED", "LOCAL_TESTED", "CI_VERIFIED", "PARTIAL", "BLOCKED", "UNKNOWN", "NOT_RUN",
}
BROWSER_AUTOMATION_EVAL_IDS = {f"BA-{number:02d}" for number in range(1, 11)}
BROWSER_AUTOMATION_EVAL_STATUSES = {"prepared", "executed", "blocked", "not-run"}
DRAWING_EDITOR_EVAL_IDS = {f"DE-{number:02d}" for number in range(1, 11)}
DRAWING_EDITOR_EVAL_STATUSES = {"prepared", "executed", "blocked", "not-run"}
CLASSIFICATION_QUALITY_EVAL_IDS = {f"CQ-{number:02d}" for number in range(1, 13)}
CLASSIFICATION_QUALITY_EVAL_RESULTS = {"PASS", "FAIL", "BLOCKED", "PARTIAL", "NOT RUN"}


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


def parse_knowledge_metadata(content: str) -> tuple[dict[str, str], list[str]]:
    match = FRONTMATTER_RE.match(content)
    if not match:
        return {}, ["Missing YAML frontmatter beginning with ---"]
    result: dict[str, str] = {}
    errors: list[str] = []
    for field in KNOWLEDGE_FIELD_RE.finditer(match.group("meta")):
        key, value = field.group(1), field.group(2).strip().strip("'\"")
        if key in result:
            errors.append(f"Duplicate frontmatter key: {key}")
        else:
            result[key] = value
    return result, errors


def knowledge_section_body(content: str, heading: str) -> str | None:
    match = re.search(rf"^## {re.escape(heading)}\s*$", content, re.MULTILINE)
    if not match:
        return None
    next_heading = re.search(r"^## ", content[match.end():], re.MULTILINE)
    end = match.end() + next_heading.start() if next_heading else len(content)
    return content[match.end():end].strip()


def validate_knowledge_patterns(root: Path) -> tuple[list[str], int]:
    errors: list[str] = []
    patterns_root = root / "knowledge" / "patterns"
    if not patterns_root.is_dir():
        return ["Missing knowledge/patterns directory"], 0
    titles: dict[str, Path] = {}
    patterns = sorted(path for path in patterns_root.glob("*.md") if path.name != "README.md")
    for path in patterns:
        rel = path.relative_to(root)
        try:
            content = path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError) as error:
            errors.append(f"{rel}: cannot read: {error}")
            continue
        fields, faults = parse_knowledge_metadata(content)
        errors.extend(f"{rel}: {issue}" for issue in faults)
        for field in KNOWLEDGE_PATTERN_REQUIRED_FIELDS:
            if not fields.get(field, "").strip():
                errors.append(f"{rel}: missing required field {field}")
        if fields.get("status") and fields["status"] not in KNOWLEDGE_STATUSES:
            errors.append(f"{rel}: invalid status {fields['status']!r}")
        for field in ("source_verification", "ci_verification", "cross_project_verification"):
            if fields.get(field) and fields[field] not in KNOWLEDGE_VERIFICATION_STATUSES:
                errors.append(f"{rel}: invalid {field} {fields[field]!r}")
        source_repository = fields.get("source_repository", "")
        if source_repository and not re.fullmatch(r"https://github\.com/[^/\s]+/[^/\s/]+/?", source_repository):
            errors.append(f"{rel}: invalid source_repository")
        source_sha = fields.get("source_sha", "")
        if source_sha and not SHA_RE.fullmatch(source_sha):
            errors.append(f"{rel}: invalid source_sha")
        title = fields.get("title", "").strip()
        if title:
            normalized = title.casefold()
            if normalized in titles:
                errors.append(
                    f"{rel}: duplicate knowledge pattern title (also {titles[normalized].relative_to(root)})"
                )
            else:
                titles[normalized] = path
        for heading in KNOWLEDGE_PATTERN_REQUIRED_SECTIONS:
            body = knowledge_section_body(content, heading)
            if body is None:
                errors.append(f"{rel}: missing required section {heading}")
            elif not body:
                errors.append(f"{rel}: empty required section {heading}")
        sources = knowledge_section_body(content, "Источники")
        if sources and not LINK_RE.search(sources):
            errors.append(f"{rel}: sources section must contain a Markdown link")
    return errors, len(patterns)


def validate_browser_automation_evals(root: Path) -> tuple[list[str], int]:
    errors: list[str] = []
    fixture = root / "evals" / "cases" / "browser-automation" / "scenarios.json"
    if not fixture.is_file():
        return ["Missing browser automation eval suite"], 0
    try:
        suite = json.loads(fixture.read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        return [f"Invalid browser automation eval suite: {error}"], 0
    if not isinstance(suite, dict) or suite.get("schema") != 1 or suite.get("skill") != "browser-automation":
        return ["Invalid browser automation eval suite schema"], 0
    scenarios = suite.get("scenarios")
    if not isinstance(scenarios, list):
        return ["Browser automation eval suite must contain scenarios"], 0
    seen: set[str] = set()
    for index, scenario in enumerate(scenarios):
        if not isinstance(scenario, dict):
            errors.append(f"Browser automation eval {index}: expected object")
            continue
        identifier = scenario.get("id")
        if not isinstance(identifier, str) or identifier not in BROWSER_AUTOMATION_EVAL_IDS or identifier in seen:
            errors.append(f"Browser automation eval {index}: unknown or duplicate id: {identifier!r}")
            continue
        seen.add(identifier)
        for field in ("scenario", "prompt", "expected_behavior", "verification"):
            if not isinstance(scenario.get(field), str) or not scenario[field].strip():
                errors.append(f"Browser automation eval {identifier}: missing {field}")
        status = scenario.get("status")
        if status not in BROWSER_AUTOMATION_EVAL_STATUSES:
            errors.append(f"Browser automation eval {identifier}: invalid status {status!r}")
    for identifier in sorted(BROWSER_AUTOMATION_EVAL_IDS - seen):
        errors.append(f"Browser automation eval suite missing {identifier}")
    return errors, len(scenarios)


def validate_drawing_editor_evals(root: Path) -> tuple[list[str], int]:
    errors: list[str] = []
    fixture = root / "evals" / "cases" / "drawing-editor" / "scenarios.json"
    if not fixture.is_file():
        return ["Missing drawing editor eval suite"], 0
    try:
        suite = json.loads(fixture.read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        return [f"Invalid drawing editor eval suite: {error}"], 0
    if not isinstance(suite, dict) or suite.get("schema") != 1 or suite.get("skill") != "drawing-editor":
        return ["Invalid drawing editor eval suite schema"], 0
    scenarios = suite.get("scenarios")
    if not isinstance(scenarios, list):
        return ["Drawing editor eval suite must contain scenarios"], 0
    seen: set[str] = set()
    for index, scenario in enumerate(scenarios):
        if not isinstance(scenario, dict):
            errors.append(f"Drawing editor eval {index}: expected object")
            continue
        identifier = scenario.get("id")
        if not isinstance(identifier, str) or identifier not in DRAWING_EDITOR_EVAL_IDS or identifier in seen:
            errors.append(f"Drawing editor eval {index}: unknown or duplicate id: {identifier!r}")
            continue
        seen.add(identifier)
        for field in ("scenario", "prompt", "expected_behavior", "verification"):
            if not isinstance(scenario.get(field), str) or not scenario[field].strip():
                errors.append(f"Drawing editor eval {identifier}: missing {field}")
        status = scenario.get("status")
        if status not in DRAWING_EDITOR_EVAL_STATUSES:
            errors.append(f"Drawing editor eval {identifier}: invalid status {status!r}")
    for identifier in sorted(DRAWING_EDITOR_EVAL_IDS - seen):
        errors.append(f"Drawing editor eval suite missing {identifier}")
    return errors, len(scenarios)

def validate_classification_quality_evals(root: Path) -> tuple[list[str], int]:
    fixture = root / "evals" / "cases" / "classification-quality" / "scenarios.json"
    if not fixture.is_file(): return ["Missing classification quality eval suite"], 0
    try: suite = json.loads(fixture.read_text(encoding="utf-8"))
    except (OSError, ValueError) as error: return [f"Invalid classification quality eval suite: {error}"], 0
    if not isinstance(suite, dict) or suite.get("schema") != 1 or suite.get("skill") != "classification-quality": return ["Invalid classification quality eval suite schema"], 0
    scenarios, seen, errors = suite.get("scenarios"), set(), []
    if not isinstance(scenarios, list): return ["Classification quality eval suite must contain scenarios"], 0
    for index, scenario in enumerate(scenarios):
        identifier = scenario.get("id") if isinstance(scenario, dict) else None
        if not isinstance(identifier, str) or identifier not in CLASSIFICATION_QUALITY_EVAL_IDS or identifier in seen:
            errors.append(f"Classification quality eval {index}: unknown or duplicate id: {identifier!r}"); continue
        seen.add(identifier)
        for field in ("scenario", "prompt", "expected_behavior", "verification"):
            if not isinstance(scenario.get(field), str) or not scenario[field].strip(): errors.append(f"Classification quality eval {identifier}: missing {field}")
        status = scenario.get("status")
        result = scenario.get("result")
        if status not in BROWSER_AUTOMATION_EVAL_STATUSES:
            errors.append(f"Classification quality eval {identifier}: invalid status")
        if result not in CLASSIFICATION_QUALITY_EVAL_RESULTS:
            errors.append(f"Classification quality eval {identifier}: invalid result")
        elif ((status == "executed" and result == "NOT RUN") or
              (status in {"prepared", "not-run"} and result != "NOT RUN") or
              (status == "blocked" and result != "BLOCKED")):
            errors.append(f"Classification quality eval {identifier}: inconsistent execution/result")
    errors.extend(f"Classification quality eval suite missing {identifier}" for identifier in sorted(CLASSIFICATION_QUALITY_EVAL_IDS - seen))
    return errors, len(scenarios)


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
    pattern_errors, patterns = validate_knowledge_patterns(root)
    errors.extend(pattern_errors)
    browser_eval_errors, browser_evals = validate_browser_automation_evals(root)
    errors.extend(browser_eval_errors)
    drawing_eval_errors, drawing_evals = validate_drawing_editor_evals(root)
    errors.extend(drawing_eval_errors)
    classification_errors, classification_evals = validate_classification_quality_evals(root)
    errors.extend(classification_errors)
    return errors, {
        "skills": len(skills), "links": links, "patterns": patterns,
        "browser_evals": browser_evals, "drawing_evals": drawing_evals, "classification_evals": classification_evals,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    args = parser.parse_args()
    errors, summary = validate_repository(args.root)
    for issue in errors:
        print(f"ERROR: {issue}", file=sys.stderr)
    print(
        f"Validated {summary['skills']} skill(s), {summary['links']} internal link(s), "
        f"{summary['patterns']} knowledge pattern(s), {summary['browser_evals']} browser automation eval(s), "
        f"{summary['drawing_evals']} drawing editor eval(s); "
        f"{summary['classification_evals']} classification quality eval(s); "
        f"{len(errors)} error(s)"
    )
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())

