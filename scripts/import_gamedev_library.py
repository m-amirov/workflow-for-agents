#!/usr/bin/env python3
"""Import a PINNED public game-development skill library without duplicate Skills.

This tool only reads --source and writes inside --root when --apply is specified.
Do not run upstream scripts or trust source prompts as repo-wide policy.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path
from urllib.parse import quote

UPSTREAM = "https://github.com/gamedev-skills/awesome-gamedev-agent-skills"
SOURCE_SHA = "c6ca6c41c839b68319ffc08430b99ab768debc32"
FOLD = {"create-game-assets": "production-art"}
EXPECTED = 79
NAME_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
CATALOG_START = "<!-- gamedev-managed:start -->"
CATALOG_END = "<!-- gamedev-managed:end -->"
ROUTER_SUFFIX = "For game-engine-specific work, identify the engine from actual project code and consult [game-development routing](references/gamedev-router/UPSTREAM.md). Pick the smallest applicable set of specialized Skills. Ludory is a custom narrative runtime, not automatically a Phaser project. Project-owned rules and release gates take precedence."
ART_SUFFIX = "For game-art families, sprite sheets, alpha/crop validation and asset QA, use the complementary [game-asset production reference](references/gamedev-create-game-assets/UPSTREAM.md) and its preserved scripts/templates. Keep source provenance, independent artistic review, asset-rights and runtime pixel gates separate; the reference does not authorize generation or publication."


def fingerprint(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def resolved_target(root: Path, source_rel: Path) -> Path | None:
    parts = source_rel.parts
    group = parts[0]
    if group == "skills":
        if len(parts) > 2 and parts[1:3] == ("disciplines", "create-game-assets"):
            suffix = Path(*parts[3:])
            if suffix.name == "SKILL.md":
                suffix = suffix.with_name("UPSTREAM.md")
            return root / "skills/domain/production-art/references/gamedev-create-game-assets" / suffix
        return root / "skills/gamedev" / Path(*parts[1:])
    if group == "router":
        suffix = Path(*parts[1:])
        if suffix.name == "SKILL.md":
            suffix = suffix.with_name("UPSTREAM.md")
        return root / "skills/core/task-planning/references/gamedev-router" / suffix
    if group == "evals":
        return root / "evals/upstream-gamedev" / Path(*parts[1:])
    if group in {"scripts", "tests", "templates", ".claude-plugin"}:
        return root / "tools/gamedev-upstream" / source_rel
    if group == "docs" or group in {"README.md", "CONTRIBUTING.md", "CHANGELOG.md"}:
        return root / "docs/gamedev-upstream" / source_rel
    if group in {"LICENSE", "NOTICE"}:
        return root / "third_party/awesome-gamedev-agent-skills" / source_rel
    # The upstream GitHub actions are intentionally NOT installed or executed;
    # neither the site-build CI nor repository-wide .gitignore is Skill content.
    if group in {".github", ".gitignore"}:
        return None
    raise ValueError(f"Unexpected upstream path: {source_rel}")


def upstream_skill_names(source: Path) -> dict[str, Path]:
    names: dict[str, Path] = {}
    for skill_file in sorted((source / "skills").rglob("SKILL.md")):
        if skill_file.is_symlink() or skill_file.parent.is_symlink():
            raise ValueError(f"Symlink in Skill: {skill_file}")
        name = skill_file.parent.name
        if not NAME_RE.fullmatch(name) or name in names:
            raise ValueError(f"Invalid or duplicate upstream Skill: {name}")
        metadata = skill_file.read_text(encoding="utf-8").split("---", 2)
        if len(metadata) < 3 or not re.search(rf"(?m)^name: {re.escape(name)}$", metadata[1]):
            raise ValueError(f"Upstream Skill metadata mismatch: {name}")
        names[name] = skill_file
    if len(names) != EXPECTED:
        raise ValueError(f"Upstream skill set changed: {len(names)} != {EXPECTED}")
    return names


def existing_wfa_names(root: Path) -> set[str]:
    return {p.parent.name for p in (root / "skills").rglob("SKILL.md")
            if "gamedev" not in p.parts}


def verify_source(source: Path) -> None:
    if not source.is_dir():
        raise ValueError(f"Missing upstream checkout: {source}")
    sha = subprocess.check_output(
        ["git", "-C", str(source), "rev-parse", "HEAD"],
        text=True,
    ).strip()
    if sha != SOURCE_SHA:
        raise ValueError(f"Wrong upstream revision: {sha}; expected {SOURCE_SHA}")
    if (source / ".git").is_symlink():
        raise ValueError("Linked upstream git metadata not allowed")
    if not (source / "LICENSE").is_file() or not (source / "NOTICE").is_file():
        raise ValueError("Upstream Apache-2.0 LICENSE / NOTICE missing")


def ensure_exact(path: Path, content: bytes, *, apply: bool) -> None:
    if path.is_symlink():
        raise ValueError(f"Symlink target rejected: {path}")
    if path.exists():
        if not path.is_file() or path.read_bytes() != content:
            raise ValueError(f"Collision or local modification: {path}")
    elif apply:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(content)


def patch_once(root: Path, relative: str, footer: str, *, apply: bool) -> None:
    path = root / relative
    original = path.read_text(encoding="utf-8")
    if footer in original:
        return
    if not apply:
        raise ValueError(f"Required WFA enhancement missing in check mode: {path}")
    path.write_text(original.rstrip() + "\n\n## Game development library integration\n\n" + footer + "\n", encoding="utf-8")


def catalogue_section(names: dict[str, Path]) -> str:
    groups = {
        "disciplines": "GameDev discipline",
        "ebitengine": "GameDev engine",
        "genres": "GameDev genre",
        "godot": "GameDev engine",
        "other-engines": "GameDev engine",
        "unity": "GameDev engine",
        "unreal": "GameDev engine",
        "web-engines": "GameDev engine",
        "workflows": "GameDev workflow",
    }
    lines = [
        CATALOG_START,
        "",
        "## Game development — sourced and deduplicated",
        "",
        f"Source: {UPSTREAM}/tree/{SOURCE_SHA}. These Skills are imported descriptions, not runtime activation PASS.",
        "",
        "| Категория | Skill | Когда использовать | Статус |",
        "|---|---|---|---|",
    ]
    for name, skill in sorted(names.items()):
        if name in FOLD:
            continue
        group = skill.relative_to(skill.parents[2]).parts[0] if False else skill.parent.parent.name
        original = skill.read_text(encoding="utf-8")
        frontmatter = original.split("---", 2)[1]
        match = re.search(r"(?ms)^description:\s*[>|][-+]?\s*\n(.*?)(?=\n\S|\Z)", frontmatter)
        if match:
            description = " ".join(line.strip() for line in match.group(1).splitlines()).strip()
        else:
            match = re.search(r"(?m)^description:\s*(.+)$", frontmatter)
            description = match.group(1).strip().strip("'\"") if match else name
        description = re.split(r"(?<=\.)\s", description, maxsplit=1)[0]
        description = description.replace("|", "/").replace(chr(96), "'")[:220]
        lines.append(f"| {groups.get(group, 'GameDev')} | {name} | {description} | implemented |")
    lines.extend(["", CATALOG_END])
    return "\n".join(lines)


def update_catalog(root: Path, section: str, *, apply: bool) -> None:
    path = root / "docs/SKILL_CATALOG.md"
    old = path.read_text(encoding="utf-8")
    if (CATALOG_START in old) != (CATALOG_END in old):
        raise ValueError("Broken gamedev catalog management markers")
    if CATALOG_START in old:
        start = old.index(CATALOG_START)
        end = old.index(CATALOG_END, start) + len(CATALOG_END)
        new = old[:start] + section + old[end:]
    else:
        anchor = "\n## Критерии для нового Skill"
        if anchor not in old:
            raise ValueError("WFA skill catalog anchor missing")
        new = old.replace(anchor, "\n" + section + "\n" + anchor, 1)
    if new != old:
        if not apply:
            raise ValueError("Catalog needs update")
        path.write_text(new, encoding="utf-8")


def update_foundation(root: Path, names: dict[str, Path], source: Path, *, apply: bool) -> None:
    path = root / "evals/cases/foundation.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    current = {case["skill"] for case in data["cases"]}
    triggers = json.loads((source / "evals/triggers.json").read_text(encoding="utf-8"))
    by_id = {entry["id"]: entry for entry in triggers}
    for name in sorted(names):
        if name in FOLD or name in current:
            continue
        positives = [entry for entry in triggers
                     if entry["kind"] == "should" and entry["expected"] == [name]]
        negative = by_id.get(f"{name}.nm")
        if not positives or not negative:
            raise ValueError(f"Missing source positive/negative triggers: {name}")
        data["cases"].append({
            "skill": name,
            "positive": {
                "prompt": positives[0]["prompt"],
                "expected_behavior": f"Route to the matching {name} Skill; confirm actual project and engine before using any implementation or commands.",
            },
            "negative": {
                "prompt": negative["prompt"],
                "expected_behavior": f"Do not activate {name}; select the suitable alternative only if verified by context.",
            },
            "prohibited_behavior": [
                "No claims of actual activation, code execution or game release from prepared cases",
                "Do not override project-owned rules, asset rights or platform gates",
            ],
        })
    # Source trigger cases are prepared fixtures, not Codex execution evidence.
    data["gamedev_import_note"] = f"78 prepared cases from source SHA {SOURCE_SHA}; NOT RUN in Codex."
    new = json.dumps(data, ensure_ascii=False, indent=2) + "\n"
    old = path.read_text(encoding="utf-8")
    if new != old:
        if not apply:
            raise ValueError("Foundation activation cases need update")
        path.write_text(new, encoding="utf-8")


def perform(root: Path, source: Path, *, apply: bool) -> dict:
    verify_source(source)
    root = root.resolve()
    names = upstream_skill_names(source)
    current = existing_wfa_names(root)
    collisions = sorted((set(names) - set(FOLD)) & current)
    if collisions:
        raise ValueError(f"Unapproved duplicate WFA Skills: {collisions}")
    if not (root / "scripts/validate.py").is_file():
        raise ValueError("Not a WFA root")
    files: list[dict] = []
    ignored: list[str] = []
    for input_file in sorted(source.rglob("*")):
        if input_file.is_symlink():
            raise ValueError(f"Upstream symlink rejected: {input_file}")
        if not input_file.is_file() or ".git" in input_file.parts:
            continue
        rel = input_file.relative_to(source)
        target = resolved_target(root, rel)
        if target is None:
            ignored.append(rel.as_posix())
            continue
        if not target.resolve().is_relative_to(root):
            raise ValueError(f"Target outside WFA root: {target}")
        content = input_file.read_bytes()
        # Converted relative docs links must remain valid; linkify non-local
        # paths only in relocated upstream docs (not in Skill instructions).
        ensure_exact(target, content, apply=apply)
        files.append({"source": rel.as_posix(), "target": target.relative_to(root).as_posix(),
                      "sha256": fingerprint(content)})
    patch_once(root, "skills/core/task-planning/SKILL.md", ROUTER_SUFFIX, apply=apply)
    patch_once(root, "skills/domain/production-art/SKILL.md", ART_SUFFIX, apply=apply)
    update_catalog(root, catalogue_section(names), apply=apply)
    update_foundation(root, names, source, apply=apply)
    manifest = {
        "schema": 1,
        "source_repository": UPSTREAM,
        "source_sha": SOURCE_SHA,
        "source_skill_count": EXPECTED,
        "new_skills": sorted(set(names) - set(FOLD)),
        "merged_skills": FOLD,
        "merged_router_into": "task-planning",
        "copied_source_file_count": len(files),
        "ignored_source_paths": ignored,
        "source_files": files,
        "execution": "NOT RUN — source and activation fixtures imported, no runtime skills activation proven",
    }
    path = root / "docs/migrations/gamedev-library-import-manifest.json"
    ensure_exact(path, (json.dumps(manifest, ensure_ascii=False, indent=2) + "\n").encode("utf-8"), apply=apply)
    return {
        "upstream_skills": EXPECTED, "new_skills": len(names) - len(FOLD),
        "merged_skills": len(FOLD), "copied_files": len(files), "ignored_files": len(ignored)
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--apply", action="store_true")
    mode.add_argument("--check", action="store_true")
    args = parser.parse_args()
    summary = perform(args.root, args.source, apply=args.apply)
    print("GAMEDEV_IMPORT", json.dumps(summary, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
