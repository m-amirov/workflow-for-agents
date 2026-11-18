#!/usr/bin/env python3
"""Read-only structural coverage ledger checker, NOT a runtime/content acceptance certifier."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import re

ID = re.compile(r"^[A-Z][A-Z0-9]*(?:-[A-Z0-9]+)+$")
SHA = re.compile(r"^[0-9a-f]{40}$")
DIGEST = re.compile(r"^[0-9a-f]{64}$")
PRIORITIES = {"MUST", "OPTIONAL", "CUT"}
STATUSES = {"VERIFIED", "MISSING", "UNREACHABLE", "BLOCKED", "OPTIONAL_MISSING", "INTENTIONALLY_CUT"}
KINDS = {"source", "runtime", "graph", "visual", "package"}


def safe_file(root: Path, value: object) -> Path | None:
    if not isinstance(value, str) or not value or "\\" in value or ":" in value:
        return None
    parts = value.split("/")
    if value.startswith("/") or any(p in {"", ".", ".."} for p in parts):
        return None
    rel = PurePosixPath(value)
    if rel.is_absolute():
        return None
    target = root
    for part in rel.parts:
        target = target / part
        if target.is_symlink():
            return None
    try:
        if target.is_file() and target.resolve(strict=True).is_relative_to(root.resolve(strict=True)):
            return target
    except (OSError, RuntimeError):
        pass
    return None


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def inspect(baseline: object, manifest: object, root: Path, baseline_digest: str) -> dict:
    errors: list[str] = []
    verified_files = 0
    if not isinstance(baseline, dict) or not isinstance(manifest, dict):
        return report(["baseline and manifest must be JSON objects"], 0)
    if set(baseline) != {"schemaVersion", "gameId", "revision", "sourceSha", "requirements"}:
        errors.append("invalid baseline keys")
    if set(manifest) != {"schemaVersion", "gameId", "gameSourceSha", "baselineSha256", "rows"}:
        errors.append("invalid manifest keys")
    if baseline.get("schemaVersion") != 1 or manifest.get("schemaVersion") != 1:
        errors.append("schemaVersion must be 1")
    if not isinstance(baseline.get("gameId"), str) or not baseline["gameId"]:
        errors.append("invalid baseline gameId")
    if manifest.get("gameId") != baseline.get("gameId"):
        errors.append("gameId mismatch")
    if not isinstance(baseline.get("revision"), str) or not baseline["revision"].strip():
        errors.append("baseline revision required")
    if not isinstance(baseline.get("sourceSha"), str) or not SHA.fullmatch(baseline["sourceSha"]):
        errors.append("invalid baseline sourceSha")
    source_sha = manifest.get("gameSourceSha")
    if not isinstance(source_sha, str) or not SHA.fullmatch(source_sha):
        errors.append("invalid gameSourceSha")
    if manifest.get("baselineSha256") != baseline_digest:
        errors.append("baseline SHA-256 mismatch")

    expected: dict[str, dict] = {}
    requirements = baseline.get("requirements")
    if not isinstance(requirements, list) or not requirements or len(requirements) > 5000:
        errors.append("baseline requirements must be a nonempty list <=5000")
        requirements = []
    for index, row in enumerate(requirements):
        prefix = f"baseline[{index}]"
        if not isinstance(row, dict) or set(row) != {"id", "priority", "description", "requiredEvidenceKinds", "cutDecision"}:
            errors.append(f"{prefix}: invalid fields")
            continue
        key = row["id"]
        if not isinstance(key, str) or not ID.fullmatch(key) or key in expected:
            errors.append(f"{prefix}: invalid or duplicate requirement id")
            continue
        expected[key] = row
        if not isinstance(row["priority"], str) or row["priority"] not in PRIORITIES:
            errors.append(f"{prefix}: invalid priority")
        if not isinstance(row["description"], str) or not row["description"].strip():
            errors.append(f"{prefix}: missing description")
        kinds = row["requiredEvidenceKinds"]
        if (not isinstance(kinds, list) or not kinds or
                any(not isinstance(x, str) or x not in KINDS for x in kinds) or
                len(set(kinds)) != len(kinds)):
            errors.append(f"{prefix}: invalid requiredEvidenceKinds")
        if row["priority"] == "CUT":
            decision = row["cutDecision"]
            if not isinstance(decision, dict) or set(decision) != {"path", "sha256"}:
                errors.append(f"{prefix}: CUT requires decision path and hash")
            else:
                file = safe_file(root, decision["path"])
                if file is None or not isinstance(decision["sha256"], str) or not DIGEST.fullmatch(decision["sha256"]):
                    errors.append(f"{prefix}: CUT decision missing or unsafe")
                elif sha256(file) != decision["sha256"]:
                    errors.append(f"{prefix}: CUT decision hash mismatch")
        elif row["cutDecision"] is not None:
            errors.append(f"{prefix}: non-CUT cannot carry cutDecision")

    rows = manifest.get("rows")
    if not isinstance(rows, list) or len(rows) > 5000:
        errors.append("rows must be a list <=5000")
        rows = []
    seen: set[str] = set()
    for index, item in enumerate(rows):
        prefix = f"rows[{index}]"
        if not isinstance(item, dict) or set(item) != {"id", "status", "sourceSha", "evidence"}:
            errors.append(f"{prefix}: invalid fields")
            continue
        key = item["id"]
        if not isinstance(key, str) or key not in expected:
            errors.append(f"{prefix}: unknown requirement id")
            continue
        if key in seen:
            errors.append(f"{prefix}: duplicate requirement id {key}")
            continue
        seen.add(key)
        requirement = expected[key]
        status = item["status"]
        if not isinstance(status, str) or status not in STATUSES:
            errors.append(f"{prefix}: invalid status")
            continue
        if item["sourceSha"] != source_sha:
            errors.append(f"{prefix}: stale or mismatched game sourceSha")
        priority = requirement["priority"]
        if priority == "MUST" and status != "VERIFIED":
            errors.append(f"{prefix}: unmet MUST requirement {key} ({status})")
        if priority == "CUT" and status != "INTENTIONALLY_CUT":
            errors.append(f"{prefix}: CUT row must be INTENTIONALLY_CUT")
        if priority != "CUT" and status == "INTENTIONALLY_CUT":
            errors.append(f"{prefix}: cut without approved baseline decision")
        if priority != "OPTIONAL" and status == "OPTIONAL_MISSING":
            errors.append(f"{prefix}: OPTIONAL_MISSING on non-optional requirement")
        if priority == "OPTIONAL" and status in {"MISSING", "UNREACHABLE", "BLOCKED"}:
            errors.append(f"{prefix}: unresolved optional item must say OPTIONAL_MISSING or VERIFIED")
        evidence = item["evidence"]
        if not isinstance(evidence, list) or len(evidence) > 200:
            errors.append(f"{prefix}: evidence must be list <=200")
            continue
        found_kinds: set[str] = set()
        paths: set[str] = set()
        for number, source in enumerate(evidence):
            label = f"{prefix}.evidence[{number}]"
            if not isinstance(source, dict) or set(source) != {"kind", "path", "sha256"}:
                errors.append(f"{label}: invalid fields")
                continue
            kind, path, digest = source["kind"], source["path"], source["sha256"]
            if not isinstance(kind, str) or kind not in KINDS:
                errors.append(f"{label}: invalid kind")
            else:
                found_kinds.add(kind)
            if not isinstance(path, str) or path in paths:
                errors.append(f"{label}: invalid/duplicate path")
            else:
                paths.add(path)
            file = safe_file(root, path)
            if file is None or not isinstance(digest, str) or not DIGEST.fullmatch(digest):
                errors.append(f"{label}: missing/unsafe file or hash")
            else:
                try:
                    if sha256(file) != digest:
                        errors.append(f"{label}: file SHA-256 mismatch")
                    else:
                        verified_files += 1
                except OSError:
                    errors.append(f"{label}: unreadable file")
        if status == "VERIFIED":
            needed = {x for x in requirement["requiredEvidenceKinds"] if isinstance(x, str) and x in KINDS} if isinstance(requirement["requiredEvidenceKinds"], list) else set()
            for kind in sorted(needed - found_kinds):
                errors.append(f"{prefix}: missing required evidence kind {kind}")
        if status == "INTENTIONALLY_CUT" and evidence:
            errors.append(f"{prefix}: cut row must not claim implementation evidence")
    for missing in sorted(set(expected) - seen):
        errors.append(f"missing coverage row for approved requirement {missing}")
    return report(errors, verified_files)


def report(errors: list[str], verified_files: int) -> dict:
    return {
        "status": "INVALID" if errors else "STRUCTURAL_RECORD_COMPLETE",
        "errors": errors, "verifiedEvidenceFiles": verified_files,
        "runtimeObserved": False, "contentCompleteAttested": False,
        "cutAuthorizationAttested": False, "releaseReady": False
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, required=True)
    parser.add_argument("--baseline", default="docs/accepted-content-baseline.json")
    parser.add_argument("--manifest", default="artifacts/content-coverage.json")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    root = args.project.resolve()
    baseline_file = safe_file(root, args.baseline)
    manifest_file = safe_file(root, args.manifest)
    if baseline_file is None or manifest_file is None:
        result = report(["missing or unsafe baseline / manifest"], 0)
    else:
        try:
            baseline_bytes = baseline_file.read_bytes()
            baseline = json.loads(baseline_bytes.decode("utf-8"))
            manifest = json.loads(manifest_file.read_text(encoding="utf-8"))
            result = inspect(baseline, manifest, root, hashlib.sha256(baseline_bytes).hexdigest())
        except (OSError, UnicodeError, ValueError):
            result = report(["invalid or unreadable baseline / manifest"], 0)
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 1 if result["status"] == "INVALID" else 0


if __name__ == "__main__":
    raise SystemExit(main())
