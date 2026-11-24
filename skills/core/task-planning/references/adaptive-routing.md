# Adaptive Task Routing — decision policy (Stage 9B)

## Intent and precedence

Classify tasks only after inspecting the user's goal, project-owned AGENTS,
existing behavior and relevant evidence. This is an advisory design policy,
not a new orchestration framework or an automatic natural-language classifier.
Prefer the lowest-overhead adequate work plan.

- TYPE: NEW_PROJECT, FEATURE, CHANGE, BUGFIX, REFACTOR.
- SIZE: SMALL (local/reversible), MEDIUM (multiple dependencies or significant
  acceptance), LARGE (subsystem, staged changes or substantial unknowns).
- RISK: LOW, MEDIUM, HIGH, or UNASSESSED until evaluated.
- DOCS_IMPACT: NONE, LOCAL, SIGNIFICANT, UNKNOWN.
- Explicit current user TYPE and SIZE take precedence over task metadata
  and agent inference. If factually contradictory, surface a question/decision
  rather than silently relabeling.
- Explicit user RISK is the minimum. Source-confirmed indicators can increase
  it, never silently decrease it. HIGH includes credentials, permissions,
  payments, destructive writes, concurrency, critical production and breaking
  public APIs. Risk must never be inferred only from SIZE.
- Without sufficient evidence to assess RISK, return UNASSESSED and require
  assessment before any low-risk shortcut.

## Minimal routing matrix

| Context | Architect/planning | Developer | Independent Reviewer |
| --- | --- | --- | --- |
| SMALL / LOW feature/change/refactor/bugfix | No separate Architect | Yes | Not automatically required |
| MEDIUM or LARGE | Architecture specialist when material | Yes | Required at relevant final gate |
| SMALL / HIGH | Architecture specialist only if architecture affected | Yes | Required |
| NEW_PROJECT / any size | Initial architecture decision and owner gate | Yes | Required final gate |
| LARGE BUGFIX / no systemic architecture issue | Not automatically | Yes | Required |

An independent review may be an actual independent agent/person if available,
not the implementing agent's self-approval. If the mandatory reviewer cannot
run, stop release/final review verdict as BLOCKED/NOT_VERIFIED; do not invent
one. Run project-native tests even when a Reviewer is not required.

A NEW_PROJECT requires a sufficiently clear product brief and a user decision
after architecture proposal before irreversible implementation. Any
architecture-changing, destructive, production-write or breaking-API decision
also requires the relevant project/owner authorization, regardless of size.
Routing never grants permission to merge, deploy, submit, modify real user
files or bypass project-specific PR policy.

## Bug versus behavior change

BUGFIX restores an existing observable expectation: reproduce the mismatch,
find root cause, add regression, verify. CHANGE deliberately modifies that
expectation. REFACTOR preserves external behavior. If this distinction is
material but unresolved, ask for one bounded clarification before mutation.

## Documentation freshness

Developer assesses documentation impact on every meaningful code change:
- NONE: no changed public/operational contract; record rationale briefly.
- LOCAL: update affected setup, config, API or .env.example in the same change.
- SIGNIFICANT: consolidate architecture/user-facing contract and optionally
  use a documentation specialist, but require genuine evidence.
- UNKNOWN: not a completion verdict; inspect the diff and decide.

A specialist agent is optional; **docs freshness is not**. Report
KEY_CHANGES, DOCS_IMPACT, USER_ACTION_REQUIRED and specific USER_ACTIONS
when an action is truly needed. Do not include secret values.

## Anti-loop and cost gates

Maintain **separate** counters within the actual task; the CLI does not store
them. Two failed Developer attempts require a user decision before another
attempt. Three failed bugfix hypotheses or three consecutive Reviewer
CHANGES_REQUIRED outcomes require a new direction/decision. A repeated
identical attempt without new evidence is not allowed, even before the limit.
An external transport failure/403, credentials blocker, or missing capability
does not consume an implementation failure slot.

No automatic model escalation, uncontrolled new subagents, broad refactors or changes to
accepted scope. Exception: explicitly enabled WFA token-saving mode may
delegate the initial bounded LOW-risk subtask to a Luna profile and use
the independent Sol reviewer when required. No retry or model escalation
is authorized by that mode. The optional probe `--token-work` recommends
a route from explicitly assessed metadata; it does not enable or execute it. A user-approved extra attempt must have a materially distinct
plan and bounded scope; the CLI does not issue user authorization. Stop when
no evidence of progress remains.

## Deterministic optional policy probe

From the central workflow-for-agents checkout only:

~~~powershell
python scripts/task_routing.py --type FEATURE --size SMALL --risk LOW --docs-impact NONE
python scripts/task_routing.py --type BUGFIX --size SMALL --risk LOW --signal payments --docs-impact LOCAL
python scripts/task_routing.py --type REFACTOR --size MEDIUM --risk AUTO --docs-impact UNKNOWN
~~~

The last example yields UNASSESSED without supported risk indicators and
requires assessment. The middle one escalates LOW to HIGH based on explicit
evidence; the caller is responsible for the provenance of the signal.
No invocation modifies any project, invokes Codex, installs Skills or claims
actual quality gates are passed.

[Stage 9B eval cases](../../../../evals/cases/task-routing/scenarios.json)
cover both activation boundaries and deterministic route outputs. Prepared
scenarios and static tests are not real Codex activation evidence.
