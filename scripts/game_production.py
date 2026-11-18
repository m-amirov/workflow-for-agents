#!/usr/bin/env python3
"""Read-only, offline game-production gate record checker.

Checks evidence bytes and record structure, not execution provenance,
game quality, owner authorization, SDK behavior or publication readiness.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import sys

GATE_KINDS = {
    "G0": ("game-brief",),
    "G1": ("gdd", "acceptance-matrix"),
    "G2": ("playable-smoke",),
    "G3": ("vertical-slice-review",),
    "G4": ("content-coverage",),
    "G5": ("automated-tests", "playtest-report"),
    "G6": ("candidate-package", "build-receipt", "rights-ledger", "platform-preflight"),
    "G7": ("official-platform-acceptance", "owner-authorization"),
}
RESULTS = {"NOT_RUN", "PASS", "FAIL", "BLOCKED"}
SHA256 = re.compile(r"^[0-9a-f]{64}$")
COMMIT = re.compile(r"^[0-9a-f]{40}$")
GAME_ID = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
WEB_TARGETS = {"web", "yandex-games", "vk-games"}


def _digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def _safe_file(root: Path, value: object) -> Path | None:
    """Reject absolute, parent, Windows separators, symlinks and escapes."""
    if not isinstance(value, str) or not value or "\\" in value or "\x00" in value:
        return None
    if value.startswith("/") or "//" in value or ":" in value or value.startswith("./"):
        return None
    relative = PurePosixPath(value)
    if any(part in {".", "..", ""} for part in value.split("/")) or relative.is_absolute():
        return None
    candidate = root
    for part in relative.parts:
        candidate = candidate / part
        if candidate.is_symlink():
            return None
    try:
        if not candidate.is_file() or not candidate.resolve(strict=True).is_relative_to(root.resolve(strict=True)):
            return None
    except (OSError, RuntimeError):
        return None
    return candidate


def _report(errors: list[str], passed: list[str], next_gate: str | None, verified: int) -> dict:
    return {
        "status": "INVALID" if errors else "STRUCTURAL_RECORD_VALID",
        "recordedPassGates": passed,
        "nextGate": next_gate,
        "verifiedEvidenceFiles": verified,
        "errors": errors,
        "executionAttested": False,
        "artisticAcceptanceAttested": False,
        "platformAcceptanceAttested": False,
        "releaseReady": False,
        "publicationAllowed": False,
    }


def inspect(record: object, root: Path) -> dict:
    """Deterministic inspection; never grants release authority."""
    issues: list[str] = []
    verified = 0
    passed: list[str] = []
    next_gate: str | None = None
    if not isinstance(record, dict):
        return _report(["record must be an object"], [], "G0", 0)
    if record.get("schemaVersion") != 1:
        issues.append("schemaVersion must equal 1")
    if set(record) != {"schemaVersion", "gameId", "engine", "targets", "gates"}:
        issues.append("unexpected or missing top-level fields")
    if not isinstance(record.get("gameId"), str) or not GAME_ID.fullmatch(record["gameId"]):
        issues.append("gameId must be lowercase kebab-case")
    if not isinstance(record.get("engine"), str) or not record["engine"].strip():
        issues.append("engine must be nonempty")
    targets = record.get("targets")
    if (not isinstance(targets, list) or not targets
            or any(not isinstance(t, str) or not t.strip() for t in targets)
            or len(set(targets)) != len(targets)):
        issues.append("targets must be a unique, nonempty string list")
        targets = []
    gates = record.get("gates")
    if not isinstance(gates, dict) or set(gates) != set(GATE_KINDS):
        return _report(issues + ["gates must contain exactly G0..G7"], [], "G0", 0)

    earlier_pass = True
    for name, mandatory in GATE_KINDS.items():
        item = gates[name]
        if not isinstance(item, dict):
            issues.append(f"{name}: must be an object")
            earlier_pass = False
            next_gate = next_gate or name
            continue
        if set(item) != {"status", "sourceSha", "evidence", "blockers"}:
            issues.append(f"{name}: unexpected or missing fields")
        status = item.get("status")
        if not isinstance(status, str) or status not in RESULTS:
            issues.append(f"{name}: invalid status")
            status = "BLOCKED"
        blockers = item.get("blockers")
        if not isinstance(blockers, list) or any(not isinstance(x, str) or not x.strip() for x in blockers):
            issues.append(f"{name}: blockers must be a list of nonempty strings")
            blockers = []
        if status in {"FAIL", "BLOCKED"} and not blockers:
            issues.append(f"{name}: {status} needs a concrete blocker")
        if status == "PASS" and blockers:
            issues.append(f"{name}: PASS cannot contain blockers")
        sha = item.get("sourceSha")
        if sha is not None and (not isinstance(sha, str) or not COMMIT.fullmatch(sha)):
            issues.append(f"{name}: invalid sourceSha")
        if status == "PASS" and not isinstance(sha, str):
            issues.append(f"{name}: PASS needs an exact sourceSha")
        evidence = item.get("evidence")
        if not isinstance(evidence, list) or len(evidence) > 100:
            issues.append(f"{name}: evidence must be an array of at most 100 items")
            evidence = []
        kinds: set[str] = set()
        paths: set[str] = set()
        for idx, entry in enumerate(evidence):
            label = f"{name}.evidence[{idx}]"
            if not isinstance(entry, dict) or set(entry) != {"kind", "path", "sha256"}:
                issues.append(f"{label}: expected kind/path/sha256")
                continue
            kind, path, digest = entry["kind"], entry["path"], entry["sha256"]
            if not isinstance(kind, str) or not kind.strip():
                issues.append(f"{label}: invalid kind")
            else:
                if kind in kinds:
                    issues.append(f"{label}: duplicate evidence kind {kind}")
                kinds.add(kind)
            if not isinstance(path, str) or path in paths:
                issues.append(f"{label}: invalid/duplicate path")
            else:
                paths.add(path)
            if not isinstance(digest, str) or not SHA256.fullmatch(digest):
                issues.append(f"{label}: invalid SHA-256")
            file = _safe_file(root, path)
            if file is None:
                issues.append(f"{label}: unsafe, absent or symlinked file")
            elif isinstance(digest, str) and SHA256.fullmatch(digest):
                try:
                    if _digest(file) != digest:
                        issues.append(f"{label}: file SHA-256 mismatch")
                    else:
                        verified += 1
                except OSError:
                    issues.append(f"{label}: file could not be read")
        if status == "PASS":
            required = set(mandatory)
            if name == "G5" and WEB_TARGETS.intersection(targets):
                required.add("browser-qa")
            for missing in sorted(required - kinds):
                issues.append(f"{name}: missing required evidence kind {missing}")
            if not earlier_pass:
                issues.append(f"{name}: previous gate has not passed")
            passed.append(name)
        else:
            earlier_pass = False
            if next_gate is None:
                next_gate = name

    if (isinstance(gates["G5"], dict) and isinstance(gates["G6"], dict)
            and gates["G5"].get("status") == "PASS" and gates["G6"].get("status") == "PASS"):
        if gates["G5"].get("sourceSha") != gates["G6"].get("sourceSha"):
            issues.append("G6: sourceSha differs from G5 QA sourceSha")
    if (isinstance(gates["G6"], dict) and isinstance(gates["G7"], dict)
            and gates["G6"].get("status") == "PASS" and gates["G7"].get("status") == "PASS"):
        if gates["G6"].get("sourceSha") != gates["G7"].get("sourceSha"):
            issues.append("G7: sourceSha differs from G6 candidate sourceSha")
    return _report(issues, passed, next_gate, verified)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, required=True, help="Existing game project root")
    parser.add_argument("--state", default="artifacts/game-production-state.json",
                        help="Relative state file under --project")
    parser.add_argument("--require-gate", choices=tuple(GATE_KINDS))
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    root = args.project.resolve()
    path = _safe_file(root, args.state)
    if path is None:
        report = _report(["missing or unsafe state file"], [], "G0", 0)
    else:
        try:
            report = inspect(json.loads(path.read_text(encoding="utf-8")), root)
        except (OSError, UnicodeError, ValueError):
            report = _report(["state file is unreadable or invalid JSON"], [], "G0", 0)
    if args.require_gate:
        report["requiredGate"] = args.require_gate
        report["recordCheckSatisfied"] = (
            report["status"] == "STRUCTURAL_RECORD_VALID"
            and args.require_gate in report["recordedPassGates"]
            and args.require_gate != "G7"
        )
    print(json.dumps(report, ensure_ascii=False, indent=2))
    if report["status"] == "INVALID":
        return 1
    if args.require_gate and not report["recordCheckSatisfied"]:
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
