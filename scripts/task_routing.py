#!/usr/bin/env python3
"""Read-only, deterministic engineering task-routing policy for explicit metadata.

No natural-language inference, effective model selection, agent spawning or project writes.
"""
from __future__ import annotations

import argparse
import json

TYPES = ("NEW_PROJECT", "FEATURE", "CHANGE", "BUGFIX", "REFACTOR")
SIZES = ("SMALL", "MEDIUM", "LARGE")
RISKS = ("AUTO", "LOW", "MEDIUM", "HIGH")
DOC_IMPACTS = ("UNKNOWN", "NONE", "LOCAL", "SIGNIFICANT")
RISK_RANK = {"LOW": 0, "MEDIUM": 1, "HIGH": 2}

# These indicators are explicit task metadata assessed against actual source
# context. They are not keyword rules for arbitrary user prose.
SIGNAL_RISK = {
    "authentication": "HIGH",
    "authorization": "HIGH",
    "credentials": "HIGH",
    "payments": "HIGH",
    "destructive-operation": "HIGH",
    "destructive-migration": "HIGH",
    "concurrency": "HIGH",
    "public-api-breaking": "HIGH",
    "critical-production": "HIGH",
    "production-write": "HIGH",
    "architecture-change": "MEDIUM",
    "external-integration": "MEDIUM",
    "persistent-schema": "MEDIUM",
    "deployment-configuration": "MEDIUM",
    "wide-regression-surface": "MEDIUM",
    "systemic-root-cause": "MEDIUM",
}
ARCHITECTURE_SIGNALS = {
    "architecture-change", "systemic-root-cause", "public-api-breaking",
    "concurrency", "destructive-migration",
}
DECISION_SIGNALS = {
    "architecture-change", "destructive-operation", "destructive-migration",
    "production-write", "public-api-breaking",
}
ATTEMPT_LIMITS = {
    "developer": 2,
    "bugfix-hypothesis": 3,
    "reviewer-changes-required": 3,
}


def _required_enum(name: str, value: str, allowed: tuple[str, ...]) -> None:
    if not isinstance(value, str) or value not in allowed:
        raise ValueError(f"{name} must be one of {', '.join(allowed)}")


def route_task(
    task_type: str,
    size: str,
    risk: str = "AUTO",
    signals: tuple[str, ...] | list[str] = (),
    docs_impact: str = "UNKNOWN",
) -> dict[str, object]:
    """Return advisory gates, not evidence that any agent/test has run."""
    _required_enum("task_type", task_type, TYPES)
    _required_enum("size", size, SIZES)
    _required_enum("risk", risk, RISKS)
    _required_enum("docs_impact", docs_impact, DOC_IMPACTS)
    if isinstance(signals, (str, bytes)):
        raise ValueError("signals must be a collection, not a string")
    signals = tuple(signals)
    if any(not isinstance(signal, str) or signal not in SIGNAL_RISK for signal in signals):
        raise ValueError("signals must contain only recognized evidence-backed indicators")
    unique_signals = sorted(set(signals))
    strongest = max(
        (SIGNAL_RISK[signal] for signal in unique_signals),
        key=lambda item: RISK_RANK[item],
        default=None,
    )
    declared = None if risk == "AUTO" else risk
    if declared is None and strongest is None:
        effective_risk = "UNASSESSED"
    else:
        effective_risk = max(
            (item for item in (declared, strongest) if item is not None),
            key=lambda item: RISK_RANK[item],
        )
    escalated = declared is not None and RISK_RANK.get(effective_risk, 0) > RISK_RANK[declared]

    architect = (
        task_type == "NEW_PROJECT"
        or (size == "LARGE" and task_type in {"FEATURE", "CHANGE", "REFACTOR"})
        or bool(set(unique_signals) & ARCHITECTURE_SIGNALS)
    )
    reviewer = (
        task_type == "NEW_PROJECT"
        or size in {"MEDIUM", "LARGE"}
        or effective_risk in {"HIGH", "UNASSESSED"}
    )
    user_gate = task_type == "NEW_PROJECT" or bool(set(unique_signals) & DECISION_SIGNALS)
    if task_type == "NEW_PROJECT":
        documentation = "FINAL_CONSOLIDATION"
    elif docs_impact == "SIGNIFICANT":
        documentation = "CONSOLIDATE"
    elif docs_impact == "LOCAL":
        documentation = "UPDATE_IN_CHANGE"
    elif docs_impact == "NONE":
        documentation = "NO_UPDATE_REQUIRED"
    else:
        documentation = "ASSESS_BEFORE_ACCEPTANCE"

    gates = ["PROJECT_NATIVE_VERIFICATION", "DOCUMENTATION_FRESHNESS"]
    if task_type == "BUGFIX":
        gates.append("REPRODUCE_ROOT_CAUSE_REGRESSION")
    if reviewer:
        gates.append("INDEPENDENT_REVIEW")
    if user_gate:
        gates.append("USER_DECISION")
    if effective_risk == "UNASSESSED":
        gates.append("RISK_ASSESSMENT")

    return {
        "status": "NEEDS_RISK_ASSESSMENT" if effective_risk == "UNASSESSED" else "ROUTED",
        "task_type": task_type,
        "size": size,
        "risk": effective_risk,
        "declared_risk": risk,
        "risk_escalated": escalated,
        "signals": unique_signals,
        "architect": "RECOMMENDED" if architect else "NOT_REQUIRED",
        "developer": "REQUIRED",
        "reviewer": "REQUIRED" if reviewer else "NOT_REQUIRED",
        "user_gate": user_gate,
        "docs_impact": docs_impact,
        "documentation_action": documentation,
        "documentation_specialist": "OPTIONAL" if documentation != "NO_UPDATE_REQUIRED" else "NOT_REQUIRED",
        "quality_gates": gates,
        "attempt_limits": dict(ATTEMPT_LIMITS),
        "model_selection": "NOT_PERFORMED",
        "execution": "NOT_PERFORMED",
        "release_readiness": "NOT_VERIFIED",
        "completion_allowed": False,
    }


def attempt_gate(
    kind: str,
    used_failures: int,
    event: str = "INSPECT",
    new_evidence: bool = False,
) -> dict[str, object]:
    """Calculate retry gate from a caller-supplied counter; never authorize retries."""
    if kind not in ATTEMPT_LIMITS:
        raise ValueError("unknown attempt category")
    if isinstance(used_failures, bool) or not isinstance(used_failures, int) or used_failures < 0:
        raise ValueError("used_failures must be a nonnegative integer")
    _required_enum("event", event, ("INSPECT", "FAILURE", "SUCCESS", "EXTERNAL_BLOCKER"))
    limit = ATTEMPT_LIMITS[kind]
    if event == "SUCCESS":
        return {"status": "RESET", "used_failures": 0, "limit": limit}
    if event == "EXTERNAL_BLOCKER":
        return {"status": "BLOCKED_EXTERNAL", "used_failures": used_failures, "limit": limit}
    consumed = used_failures + (1 if event == "FAILURE" else 0)
    if consumed >= limit:
        status = "USER_DECISION_REQUIRED"
    elif consumed > 0 and not new_evidence:
        status = "NEW_EVIDENCE_REQUIRED"
    else:
        status = "ATTEMPT_AVAILABLE"
    return {"status": status, "used_failures": consumed, "limit": limit}


TOKEN_WORK = ("COMMAND", "TINY", "BOUNDED_READ", "BOUNDED_WRITE", "COMPLEX")

def token_plan(route: dict[str, object], work: str) -> dict[str, object]:
    """Opt-in advisory profile selection; no actual model or agent execution."""
    _required_enum("token_work", work, TOKEN_WORK)
    eligible = (
        route["status"] == "ROUTED" and route["risk"] == "LOW"
        and route["size"] == "SMALL" and not route["user_gate"]
        and route["architect"] == "NOT_REQUIRED"
        and route["reviewer"] == "NOT_REQUIRED"
    )
    profile = "ROOT"
    if eligible:
        if work == "BOUNDED_READ":
            profile = "wfa_explorer"
        elif work == "BOUNDED_WRITE":
            profile = "wfa_worker"
        elif work == "COMMAND":
            profile = "DIRECT_TOOL"
    return {
        "work": work,
        "recommended_profile": profile,
        "independent_review_profile": (
            "wfa_reviewer" if route["reviewer"] == "REQUIRED" else "NOT_REQUIRED"
        ),
        "requires_context_savings": profile in {"wfa_explorer", "wfa_worker"},
        "execution": "NOT_PERFORMED",
        "effective_model": "UNKNOWN",
        "token_savings": "NOT_MEASURED",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--type", dest="task_type", required=True, choices=TYPES)
    parser.add_argument("--size", required=True, choices=SIZES)
    parser.add_argument("--risk", default="AUTO", choices=RISKS)
    parser.add_argument("--signal", action="append", default=[], choices=sorted(SIGNAL_RISK))
    parser.add_argument("--docs-impact", default="UNKNOWN", choices=DOC_IMPACTS)
    parser.add_argument("--token-work", choices=TOKEN_WORK,
                        help="Opt-in advisory profile; bounded work must actually save root context")
    args = parser.parse_args()
    result = route_task(args.task_type, args.size, args.risk, args.signal,
                        args.docs_impact)
    if args.token_work:
        result["token_plan"] = token_plan(result, args.token_work)
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
