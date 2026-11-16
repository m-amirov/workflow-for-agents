#!/usr/bin/env python3
"""Validate project profiles and report bounded instruction compatibility facts.

This is deliberately a declarative checker. It does not infer the meaning of
arbitrary AGENTS.md prose: only profile fields, explicit JSON constraints and
the optional ``workflow-for-agents: git=<mode>`` marker are interpreted.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import subprocess
from typing import Any


SHA_RE = re.compile(r"^[0-9a-f]{40}$")
PROFILE_FIELDS = {
    "schema", "id", "canonical_repository", "source_sha", "recommended_skills",
    "activation_conditions", "protected_local_skills", "compatibility_notes", "git_workflow",
    "release_authorization", "stop_lines", "release_gates", "installation_limits", "update_rule",
}
GIT_MODES = {"main-first-project-refined", "pr-only"}
KNOWN_CONSTRAINTS = {"direct_main_required", "prototype_authorized", "release_authorized"}
REQUIRED_PROFILE_IDS = {"ludory", "eskizno", "dachametr", "twork"}


def catalog_statuses(root: Path) -> dict[str, str]:
    catalog = (root / "docs" / "SKILL_CATALOG.md").read_text(encoding="utf-8")
    matches = re.findall(r"^\|\s*[^|]+\|\s*([a-z0-9-]+)\s*\|[^|]*\|\s*(implemented|planned)\s*\|\s*$", catalog, re.MULTILINE)
    return dict(matches)


def result(kind: str, identifier: str, message: str) -> dict[str, str]:
    return {"class": kind, "id": identifier, "message": message}


def validate_profile(root: Path, profile: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if not isinstance(profile, dict) or profile.get("schema") != 1:
        return ["profile schema must be 1"]
    missing = [field for field in PROFILE_FIELDS if field not in profile]
    if missing:
        errors.append("missing required field(s): " + ", ".join(sorted(missing)))
    if not re.fullmatch(r"[a-z0-9-]+", str(profile.get("id", ""))):
        errors.append("invalid profile id")
    if not re.fullmatch(r"https://github\.com/[^/\s]+/[^/\s/]+", str(profile.get("canonical_repository", ""))):
        errors.append("invalid canonical_repository")
    for field in ("source_sha", "source_evidence_sha"):
        value = profile.get(field)
        if value is not None and not SHA_RE.fullmatch(str(value)):
            errors.append(f"invalid {field}")
    statuses = catalog_statuses(root)
    selected = profile.get("recommended_skills")
    if not isinstance(selected, list) or not selected:
        errors.append("recommended_skills must be a non-empty list")
    else:
        if len(selected) != len(set(selected)):
            errors.append("recommended_skills contains duplicates")
        for name in selected:
            if statuses.get(name) is None:
                errors.append(f"unknown Skill: {name}")
            elif statuses[name] != "implemented":
                errors.append(f"Skill is not implemented: {name}")
    for field in ("activation_conditions", "protected_local_skills", "compatibility_notes", "stop_lines", "release_gates", "installation_limits"):
        if not isinstance(profile.get(field), list) or not profile[field]:
            errors.append(f"{field} must be a non-empty list")
    if profile.get("git_workflow") not in GIT_MODES:
        errors.append("invalid git_workflow")
    if not isinstance(profile.get("update_rule"), str) or not profile["update_rule"].strip():
        errors.append("missing update_rule")
    return errors


def validate_profiles(root: Path) -> tuple[list[str], int]:
    errors: list[str] = []
    profiles = sorted((root / "projects").glob("*/profile.json"))
    identifiers: set[str] = set()
    for path in profiles:
        try:
            profile = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, ValueError) as exc:
            errors.append(f"{path.relative_to(root)}: invalid JSON: {exc}")
            continue
        errors.extend(f"{path.relative_to(root)}: {issue}" for issue in validate_profile(root, profile))
        identifier = profile.get("id") if isinstance(profile, dict) else None
        if identifier in identifiers:
            errors.append(f"{path.relative_to(root)}: duplicate profile id {identifier}")
        identifiers.add(identifier)
        if path.parent.name != identifier:
            errors.append(f"{path.relative_to(root)}: id must equal parent directory")
    for identifier in sorted(REQUIRED_PROFILE_IDS - identifiers):
        errors.append(f"missing project profile {identifier}")
    return errors, len(profiles)


def read_head(project_root: Path) -> str | None:
    if not (project_root / ".git").exists():
        return None
    completed = subprocess.run(["git", "-C", str(project_root), "rev-parse", "HEAD"], capture_output=True, text=True, check=False)
    head = completed.stdout.strip()
    return head if completed.returncode == 0 and SHA_RE.fullmatch(head) else None


def explicit_git_mode(path: Path) -> str | None:
    try:
        text = path.read_text(encoding="utf-8")
    except OSError:
        return None
    match = re.search(r"^\s*workflow-for-agents:\s*git=(pr-only|direct-main)\s*$", text, re.MULTILINE)
    return match.group(1) if match else None


def manifest_is_valid(path: Path) -> bool:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return False
    return isinstance(value, dict) and value.get("schema") == 1 and value.get("source") == "workflow-for-agents" and isinstance(value.get("installed"), list)


def managed_skill_names(path: Path) -> set[str]:
    if not manifest_is_valid(path):
        return set()
    document = json.loads(path.read_text(encoding="utf-8"))
    return {
        item.get("name") for item in document["installed"]
        if isinstance(item, dict) and isinstance(item.get("name"), str)
    }


def check_profile(root: Path, profile: dict[str, Any], *, project_root: Path | None = None,
                  head_sha: str | None = None, constraints: dict[str, Any] | None = None,
                  instruction_files: list[Path] | None = None) -> list[dict[str, str]]:
    findings: list[dict[str, str]] = []
    constraints = constraints or {}
    instruction_files = instruction_files or []
    if constraints.keys() - KNOWN_CONSTRAINTS:
        findings.append(result("UNKNOWN", "constraints", "Unsupported explicit constraint key; no semantic inference was made."))
    workflow = profile["git_workflow"]
    if workflow == "pr-only":
        findings.append(result("PROJECT_REFINEMENT", "git-workflow", "Project PR-only policy refines central main-first; do not merge without its authorization."))
    else:
        findings.append(result("DUPLICATE", "git-workflow", "Project and central main-first policy are compatible."))
    if constraints.get("direct_main_required") and workflow == "pr-only":
        findings.append(result("HARD_CONFLICT", "direct-main", "Explicit direct-to-main requirement conflicts with the project PR-only policy."))
    if profile["release_gates"]:
        findings.append(result("PROJECT_REFINEMENT", "release-gates", "Central checks do not replace the project release gates listed by this profile."))
    if constraints.get("prototype_authorized") is False and "prototype-not-authorized" in profile["stop_lines"]:
        findings.append(result("REQUIRES_PROJECT_DECISION", "prototype-authorization", "Prototype remains unauthorized; do not create an application or deploy."))
    if constraints.get("release_authorized") is False:
        findings.append(result("REQUIRES_PROJECT_DECISION", "release-authorization", "Owner release authorization is absent."))
    if project_root is not None:
        actual_head = head_sha or read_head(project_root)
        if actual_head and actual_head != profile["source_sha"]:
            findings.append(result("STALE_EVIDENCE", "source-sha", "Profile source_sha differs from the checked project HEAD; re-review instructions and gates."))
        skills_root = project_root / ".agents" / "skills"
        manifest = skills_root / ".workflow-for-agents.manifest.json"
        managed_names = managed_skill_names(manifest)
        for name in profile["recommended_skills"]:
            if (skills_root / name).exists() and name not in managed_names:
                findings.append(result("REQUIRES_PROJECT_DECISION", "local-skill-collision", f"Existing project-local Skill {name!r} will not be overwritten automatically."))
        if manifest.exists() and not manifest_is_valid(manifest):
            findings.append(result("REQUIRES_PROJECT_DECISION", "manifest-integrity", "Existing manifest is invalid; install/sync must not write over it."))
    evidence_sha = profile.get("source_evidence_sha")
    if evidence_sha and evidence_sha != profile["source_sha"]:
        findings.append(result("STALE_EVIDENCE", "historical-evidence", "Source-bound evidence is historical and must not be presented as current-main evidence."))
    for path in instruction_files:
        mode = explicit_git_mode(path)
        if mode is None:
            findings.append(result("UNKNOWN", "instruction-parse", f"{path.name} has no supported explicit compatibility marker."))
        elif mode == "pr-only" and workflow == "pr-only":
            findings.append(result("DUPLICATE", "nested-git-workflow", f"{path.name} repeats the PR-only requirement."))
        elif mode == "direct-main" and workflow == "pr-only":
            findings.append(result("HARD_CONFLICT", "nested-git-workflow", f"{path.name} explicitly requires direct main against PR-only."))
        else:
            findings.append(result("PROJECT_REFINEMENT", "nested-git-workflow", f"{path.name} is compatible with the project workflow."))
    return findings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("validate", "check"))
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument("--profile")
    parser.add_argument("--project-root", type=Path)
    parser.add_argument("--constraints", type=Path)
    parser.add_argument("--global-agents", type=Path)
    parser.add_argument("--instruction", action="append", type=Path, default=[])
    args = parser.parse_args()
    root = args.root.resolve()
    if args.command == "validate":
        errors, count = validate_profiles(root)
        for error in errors:
            print(f"ERROR: {error}")
        print(f"Validated {count} project profile(s); {len(errors)} error(s)")
        return 1 if errors else 0
    if not args.profile:
        parser.error("check requires --profile")
    path = root / "projects" / args.profile / "profile.json"
    profile = json.loads(path.read_text(encoding="utf-8"))
    constraints = json.loads(args.constraints.read_text(encoding="utf-8")) if args.constraints else {}
    instructions = list(args.instruction)
    if args.global_agents:
        instructions.append(args.global_agents)
    findings = check_profile(root, profile, project_root=args.project_root, constraints=constraints, instruction_files=instructions)
    print(json.dumps({"profile": args.profile, "findings": findings}, ensure_ascii=False, indent=2))
    return 1 if any(item["class"] in {"HARD_CONFLICT", "REQUIRES_PROJECT_DECISION"} for item in findings) else 0


if __name__ == "__main__":
    raise SystemExit(main())
