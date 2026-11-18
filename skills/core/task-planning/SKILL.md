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

## Full new-game production routing

When the user requests an entire new game from concept to release candidate,
route into the [G0–G7 Game Production Pipeline](../../../playbooks/game-production.md)
rather than treating a prototype or GDD as a finished game. Preserve the
project's actual engine and native source/rights/release gates; this
routing does not itself run agents, produce assets or grant publication.

## Game development library integration

For game-engine-specific work, identify the real runtime owner from the loaded entrypoint and project instructions. Use the **WFA-adapted [game-development routing index](references/gamedev-router/WFA-ROUTING.md)** rather than the preserved upstream `UPSTREAM.md` paths. Pick the minimal Skills; 79 upstream capabilities were integrated as 78 new Skills plus an art reference, not permission to load all of them.

**Ludory compatibility stop-line:** before recommending an engine, project-local Skill, artwork, save migration or release operation, use [Ludory compatibility rules](references/ludory-compatibility.md). Ludory is a custom runtime, and the presence of an optional Phaser adapter does not authorize treating the framework as a Phaser game. Distinguish work in Ludory's framework repository from new Studio-created games and frozen legacy games. Follow actual `AGENTS.md` and project-native `ludory-*` ownership; global Skills are advisory and cannot override image-generation handoff, persistence semantics, asset rights or VK/Yandex release gates. When provenance, project ownership or permission is missing, stop and report an evidence gap.
