#!/usr/bin/env python3
"""Read-only Ludory/WFA Skill selection contract from PREVERIFIED inputs.

This advisory tool never edits repos, launches tools, authorizes operations,
verifies a Studio creation receipt or proves a Codex model activated a Skill.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent.parent
LUDORY_REPO = "https://github.com/m-amirov/ludory"
TASKS: dict[str, dict[str, object]] = {
    "narrative": {"native": "ludory-narrative-continuity", "global": ["narrative-continuity-engine", "visual-novel"]},
    "narrative-prose": {"native": "ludory-narrative-review", "global": ["narrative-dialogue-editor", "visual-novel"]},
    "art": {"native": "ludory-production-art", "global": ["production-art"]},
    "rights": {"native": "ludory-asset-rights", "global": ["production-art"]},
    "save": {"native": None, "global": ["save-systems", "visual-novel"]},
    "ui": {"native": "ludory-ui-design", "global": ["game-ui-ux", "browser-qa"]},
    "visual-qa": {"native": "ludory-visual-qa", "global": ["visual-qa", "browser-qa"]},
    "fix": {"native": "ludory-fix", "global": ["root-cause-debugging", "regression-testing"]},
    "release-vk-yandex": {"native": "ludory-verification", "global": ["release-verification"]},
    "engine": {"native": None, "global": ["codebase-exploration", "regression-testing"]},
}
MUTATING = {"art", "save", "fix", "release-vk-yandex", "ui", "engine", "narrative", "narrative-prose"}


def route(item: dict[str, Any]) -> dict[str, Any]:
    """Assumes verified_* fields are independently substantiated by caller."""
    kind = item.get("scope", "unknown")
    task = item.get("task", "engine")
    if task not in TASKS:
        return {"status": "EVIDENCE_GAP", "engine": "UNKNOWN", "native_owner": None, "advisory": [], "blocked": ["unrecognized-task"]}
    if kind == "independent-phaser":
        if item.get("engine_source_verified") is True and item.get("actual_engine") == "phaser":
            return {"status": "ROUTED", "engine": "PHASER", "native_owner": "phaser-core", "advisory": [], "blocked": []}
        return {"status": "EVIDENCE_GAP", "engine": "UNKNOWN", "native_owner": None, "advisory": [], "blocked": ["phaser-entrypoint-unverified"]}
    if kind == "unrelated":
        return {"status": "NO_LUDORY_ACTIVATION", "engine": "UNKNOWN", "native_owner": None, "advisory": [], "blocked": []}
    if kind not in {"framework", "new-studio", "frozen"}:
        return {"status": "EVIDENCE_GAP", "engine": "UNKNOWN", "native_owner": None, "advisory": [], "blocked": ["unknown-provenance"]}
    if item.get("source_verified") is not True:
        return {"status": "EVIDENCE_GAP", "engine": "UNKNOWN", "native_owner": None, "advisory": [], "blocked": ["project-not-source-verified"]}
    if kind == "framework" and item.get("canonical_repository") != LUDORY_REPO:
        return {"status": "EVIDENCE_GAP", "engine": "UNKNOWN", "native_owner": None, "advisory": [], "blocked": ["framework-repository-not-verified"]}
    if kind == "frozen":
        return {"status": "BLOCKED_FROZEN", "engine": "CUSTOM_LUDORY", "native_owner": None, "advisory": [], "blocked": ["read-only-frozen-game"]}
    if kind == "new-studio" and item.get("studio_creation_verified") is not True:
        return {"status": "EVIDENCE_GAP", "engine": "CUSTOM_LUDORY", "native_owner": None, "advisory": [], "blocked": ["studio-creation-unverified"]}
    if kind == "new-studio" and task in MUTATING and item.get("mutation_requested") is True and item.get("owner_authorized") is not True:
        return {"status": "BLOCKED_AUTHORIZATION", "engine": "CUSTOM_LUDORY", "native_owner": None, "advisory": [], "blocked": ["operation-not-authorized"]}
    native = TASKS[task]["native"] if kind == "new-studio" else None
    if kind == "framework":
        native = "AGENTS.md / actual Ludory package owner"
    advisory = list(TASKS[task]["global"])
    blocked = []
    if task == "art":
        blocked += ["no-auto-image-generation", "native-image-handoff-and-rights-required"]
    elif task == "save":
        blocked += ["native-persistence-contract", "no-unapproved-save-migration"]
    elif task == "release-vk-yandex":
        blocked += ["no-steam-or-itch-substitution", "owner-and-platform-release-gates"]
    elif task in {"narrative", "narrative-prose"}:
        blocked += ["native-narrative-and-review-precedence"]
    return {"status": "ROUTED", "engine": "CUSTOM_LUDORY", "native_owner": native,
            "advisory": advisory, "blocked": blocked}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, help="JSON with asserted, independently verified metadata")
    parser.add_argument("--cases", type=Path, help="run pinned deterministic offline cases")
    args = parser.parse_args()
    if bool(args.input) == bool(args.cases):
        parser.error("provide exactly one of --input and --cases")
    data = json.loads((args.cases or args.input).read_text(encoding="utf-8"))
    if args.input:
        print(json.dumps(route(data), ensure_ascii=False, indent=2))
        return 0
    if data.get("schema") != 1 or not isinstance(data.get("scenarios"), list):
        raise ValueError("invalid Ludory compatibility scenarios")
    count = 0
    for case in data["scenarios"]:
        got = route(case["input"])
        for key, expected in case["expected"].items():
            if got.get(key) != expected:
                raise AssertionError(f"{case['id']}: {key}: {got.get(key)!r} != {expected!r}")
        count += 1
    print(f"OFFLINE_POLICY_PASS: {count} cases; Codex activation NOT RUN")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
