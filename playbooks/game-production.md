# Game Production Pipeline — G0–G7

**Purpose:** A reusable, evidence-gated workflow for developing **any new game** from
a brief through an inspected local release candidate and optionally a real
platform acceptance. Trigger for full game creation, not for ordinary bugfixes,
research-only answers or one-off GDD requests. It coordinates existing WFA Skills,
**not** a new engine, multiagent executor, background process or publishing tool.

**Sources of truth:** Game requirements, actual runtime, project AGENTS.md,
tests, asset declarations and platform policy in the **game repository**. WFA
provides process and verification discipline. A game using Ludory must use
its supported Studio/Core/Runtime/Connect/Release boundaries and native
[ludory-compatibility](../skills/core/task-planning/references/ludory-compatibility.md)
policy. The mere mention of Ludory/Phaser is not proof of game ownership.

## Input contract and initial decisions

Record the owner's brief in the game repository: genre, game fantasy, target
audience, primary player actions and feedback loop, targets, localizations,
accessibility, monetization default, expected duration, technical constraints,
explicit non-goals, budget/capabilities and release boundary. Distinguish
confirmed requirements from **assumptions**. Creative defaults can be delegated;
paid calls, publishing, rights claims, secret access, migration of existing
games and changes to global Codex/WFA/Ludory settings are **not implied**.

Read current game instructions and repo before choosing an engine. Use
[task-planning](../skills/core/task-planning/SKILL.md) to classify task risk,
scope and independent review. Select only relevant WFA Skills:
[game-docs](../skills/gamedev/workflows/game-docs/SKILL.md),
[prototype-fast](../skills/gamedev/workflows/prototype-fast/SKILL.md),
[production-art](../skills/domain/production-art/SKILL.md),
[character-design](../skills/domain/character-design/SKILL.md),
[character-consistency-qa](../skills/domain/character-consistency-qa/SKILL.md),
[browser-qa](../skills/testing/browser-qa/SKILL.md),
[visual-qa](../skills/design/visual-qa/SKILL.md),
[regression-testing](../skills/testing/regression-testing/SKILL.md),
[release-verification](../skills/testing/release-verification/SKILL.md)
plus confirmed engine/genre-specific Skills. A project-native Skill is
authoritative within its eligible scope. Never preload all 109 Skills.

## Stage and evidence matrix

| Gate | Exit contract (actual proof, not plan) | Required evidence kinds |
| --- | --- | --- |
| **G0 Concept** | Agreed brief, core loop, audience, targets, scope and explicit risks/exclusions | `game-brief` |
| **G1 Design** | Minimal GDD and coverage matrix of features, acceptance, tests, asset inventory and technical approach | `gdd`, `acceptance-matrix` |
| **G2 First playable** | Executable start → action → feedback → win/fail → retry; observed smoke and no fake key mechanic | `playable-smoke` |
| **G3 Vertical slice** | Polished representative gameplay segment with intended art, audio, UI and observable quality review | `vertical-slice-review` |
| **G4 Content complete** | Every committed level, scene, character, choice, ending and asset use site reconciled to design matrix; test reachability | `content-coverage` |
| **G5 Beta QA** | Current-source tests and representative real playtesting with defect triage; for browser targets, current browser/device evidence | `automated-tests`, `playtest-report`, and `browser-qa` for web/Yandex/VK |
| **G6 Local release candidate** | Exact-SHA source and package, complete build receipt, rights register, platform preflight and no unresolved P0/P1 | `candidate-package`, `build-receipt`, `rights-ledger`, `platform-preflight` |
| **G7 Platform acceptance** | Real host/portal acceptance where applicable and **separate authorized owner decision**; no simulation counted | `official-platform-acceptance`, `owner-authorization` |

Production can iterate within stages and revisit prior stages after a scope
change. A later PASS cannot bypass an earlier gate. Reusable records with
source hashes are evidence **pointers**, not authenticated proof of human/host
observation. Content-coverage requires a table of promised requirements →
actual code/data/use sites → evidence → status, including unreachable routes
and intentionally cut content. A missing promised feature is FAIL, not a
"completed scope" silently shrunk to match the build.

**G5:** automated bots can check reachability or simulation but cannot prove
players enjoyed a game; actual human feedback and observed play sessions must
be distinguished from expert review, proposed test scripts or AI guesses.
When human playtesting cannot happen, mark G5 BLOCKED, record constraints and
continue only work not dependent on that gate. Game UX/playtest metrics are
not a fabricated player analytics dataset.

**G6:** same exact source SHA as G5. Re-run QA when production code or shipped
media changed; re-inspect the final package (not only a development preview).
The rights ledger includes every shipped third-party or generated media item.
The WFA record cannot independently authenticate rights. Local ZIP PASS and
mock SDK behavior do not establish platform acceptance.

**G7:** optional *scope* for games not intended for publication. In that case,
leave G7 BLOCKED, explicitly note `PUBLICATION_NOT_AUTHORIZED`, and finish
with `RELEASE_CANDIDATE_LOCAL` only. Do not mark a nonperformed G7 as PASS or
declare a marketplace release. In projects that require actual official
moderation, only genuine official results and owner authorization can close it.

## Vertical execution loop

Inside each gate, work in small, independently testable units (one mechanic,
level, episode, UI flow, or coherent asset family):

1. Inspect active game HEAD, governing AGENTS.md, current acceptance matrix and
   previous evidence; do not restart completed work based on vague memory.
2. Choose the smallest relevant Skills and verify the engine API and source
   ownership. Preserve existing canon, accepted art direction and game state.
3. Implement a complete gameplay path, not a disconnected screenshot/mockup.
   Use actual original media or explicit BLOCKED, never fictitious assets.
4. Test normal/error/boundary cases; run real gameplay, browser and pixel QA as
   relevant, against the changed code/scene/asset and required viewports.
5. Record independent review, P0/P1/P2, defects and root-cause regression
   coverage. Use [audit-repair-loop](../skills/development/audit-repair-loop/SKILL.md)
   with bounded iterations; follow
   [attempt budgets](../skills/core/task-planning/references/adaptive-routing.md).
6. Update current project status, machine-readable evidence, GDD and contract
   mapping. Do not promote an old test's PASS after new source modifications.
7. Use [main-first workflow](../skills/development/git-workflow/SKILL.md).
   Respect branch protection and reviews; prove changes reached origin/main.

If blocked by quota, permissions, missing tool, rights or project ownership,
record the precise blocker and pause the affected operation; continue other
independent authorized tasks if safe. Do not endlessly retry a failed upload
or silently replace the required process with a different engine.

## Durable handoff / context recovery

Each game owns a concise `docs/PROJECT_STATUS.md` updated after meaningful
verified work, containing: objective, active G-gate, decisions, latest game
commit and artifact SHA, completed implementation, actual check commands and
outcomes, defects/blockers, intended next step and current WFA/Ludory binding.
Store authoritative project assets and proof where they belong, not in WFA.

A companion optional `artifacts/game-production-state.json` has the
[example contract](../templates/game-production-state.example.json): one
object per G0–G7 with `status`, `sourceSha`, `blockers`, and real
`evidence` references (`kind`, project-relative `path`, `sha256`).
The record is tracked/updated according to the game project's policy and
may be outside the release archive. Never embed secret keys or user data.

Read-only contract checker:

~~~powershell
python path/to/wfa/scripts/game_production.py --project C:\work\new-game --json
python path/to/wfa/scripts/game_production.py --project C:\work\new-game --require-gate G4 --json
~~~

This script checks **only** schema, required evidence kinds, file hashes,
unsafe paths, stage order and G5/G6/G7 source SHA consistency. It does not
execute tests, view pixels, authenticate evidence provenance or certify rights.
Exit 0 without `--require-gate` = structurally valid state, not game PASS;
with `--require-gate` = structurally recorded completion, not actual test PASS.
Exit 1 = invalid record; exit 2 = requested gate not recorded. G7 cannot
return verified completion from this self-declared local JSON. The CLI
always sets `releaseReady:false` and `publicationAllowed:false`.
Use actual engine-native CI and external gate evidence before making claims.

After context interruption, read PROJECT_STATUS.md and the record; inspect
real repo HEAD, source/evidence hashes, and incomplete gates; then continue
the next unblocked unit. A narrative checkpoint is not a verified CI receipt.

## Native/project policy: Ludory

New Studio projects only when independently verified and authorized. Studio
component trust, image generation handoffs, local and visual art acceptance,
asset rights, saves/back semantics, dual-platform exports and release checks
are owned by Ludory. The global WFA pipeline **must not** create alternate
SDKs or bypass a missing native export contract. Frozen/legacy games remain
read-only until separately authorized. Do not interpret the optional Phaser
adapter as blanket permission to use Phaser engine Skills.

Yandex/VK real SDK, physical-device evidence and moderation are external
unless actually performed; a simulated SDK smoke test is labeled SIMULATED.
Do not assert platform readiness from a local build or manually edited report.

## Handoff fields

Report game repo URL, final main SHA, play instructions, feature coverage,
narrative/level reachability, current assets and provenance, user-visible
QA findings, build ZIP/native artifacts and their hashes, gate-by-gate outcome,
real CI runs, release constraints, and next owner-only action. Use
`RELEASE_CANDIDATE_LOCAL` when G6 has genuine local evidence but G7 is
unverified. Do not publish or authorize payment, official moderation, live
IAP or platform actions without separate owner approval.

See [Codex instruction](../prompts/codex/game-production.md) and
[release](release.md). This playbook is methodology: real autonomous
Codex end-to-end execution remains to be demonstrated separately.
