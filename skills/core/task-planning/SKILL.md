---
name: task-planning
description: >-
  Use for complex or risk-sensitive engineering tasks requiring scope,
  acceptance criteria, verification, task type/size/risk routing,
  proportionate independent review and documentation-freshness decisions.
  Skip full routing for trivial editorial or local reversible changes.
---

# Task Planning and Adaptive Routing

Use for multi-step changes, uncertain requirements, high-risk fixes, migrations,
integrations, or releases. Skip full routing for trivial spelling/CSS/text
changes unless they have a genuinely risky dependency.

1. Examine current repository instructions, source, acceptance criteria and
   prior decisions; do not invent project structure or infer permissions.
2. Freeze the objective, scope/non-goals, invariants, release boundaries and
   concrete verification evidence needed.
3. For substantial development classify **TYPE** (NEW_PROJECT/FEATURE/CHANGE/
   BUGFIX/REFACTOR), **SIZE** (SMALL/MEDIUM/LARGE) and **RISK**
   (LOW/MEDIUM/HIGH). Risk is independent of size; a SMALL authorization
   change may be HIGH risk.
4. Record the evidence supporting risk signals. User-specified TYPE and SIZE
   remain authoritative until a material contradiction is resolved with the
   user; explicit RISK is a minimum, never silently downgraded. Unknown
   risk is UNASSESSED, **not** LOW.
5. Apply [adaptive routing and retry rules](references/adaptive-routing.md).
   A LOW-risk SMALL task normally needs Developer and project-native checks,
   not an automatic Architect/Reviewer subagent. HIGH risk requires
   independent review even for SMALL work; a specialist is recommended for
   substantial architecture decisions, not every change.
6. Record documentation impact as NONE/LOCAL/SIGNIFICANT or UNKNOWN. Updating
   affected documentation and reporting necessary user actions are required
   for completion, but a separate Documentation agent is optional.
7. Use evidence-based retry limits, stopping on repeated failure, an external
   blocker, missing authorization or no material diagnostic progress.
   Never auto-upgrade model/reasoning or broaden scope to escape the limits.
8. Split the authorized work into minimal testable steps with concrete
   acceptance checks. Actual testing, reviewer availability and release
   gates remain separate from the routing recommendation.

For explicitly declared metadata, use the optional **read-only** classifier:

~~~powershell
python scripts/task_routing.py --type BUGFIX --size SMALL --risk HIGH --signal authorization --docs-impact LOCAL
~~~

The CLI returns an advisory JSON plan; it cannot inspect arbitrary prose,
launch agents, select models, run tests, authorize external writes or certify
a release. If the CLI is unavailable, follow the reference policy manually
without pretending it executed.

**Output:** concise scope, TYPE/SIZE/RISK with evidence, review and approval
gates, DOCS_IMPACT, focused steps, actual checks and remaining unknowns.

## Game development library integration

For game-engine-specific work, identify the engine from actual project code and consult [game-development routing](references/gamedev-router/UPSTREAM.md). Pick the smallest applicable set of specialized Skills. Ludory is a custom narrative runtime, not automatically a Phaser project. Project-owned rules and release gates take precedence.
