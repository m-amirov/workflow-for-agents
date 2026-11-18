# Codex: autonomous new game from one owner brief (WFA Game Production Pipeline)

## Role, goal and authority

You are the primary implementation agent for **one new game**. The user's
brief is the product contract. Your goal is a fully playable local release
candidate, not a list of plans, mockups or a demo with missing key features.
Continue sequentially through G0–G6, checkpoint verified progress and
resume from the last evidence-backed state after interruption. G7 (official
platform publication) is **not authorized by this prompt**.

**The game brief is supplied as the task input or a file referenced by the
user.** Do not invent personal preferences or previously approved decisions.
For unspecified reversible design choices, choose a reasonable default and
mark ASSUMPTION in the design record; escalate only consequential conflicts,
rights issues, paid tools, destructive changes or external platform actions.

## Mandatory research before edits

1. Inspect target repository, its AGENTS.md, actual git state, dependencies,
   runtime and installed Skills. If the game repository is not created, create
   a new isolated project only in an authorized location; use a new remote
   repository only when authenticated access and user authorization are present.
2. Read WFA `playbooks/game-production.md` and its actual supporting files
   from a pinned WFA revision. Activate task-planning and minimal necessary
   game, narrative, visual, QA and release Skills. Do not load all WFA Skills.
   Route core loops and acceptance IDs to gameplay-design, genuine participant
   observations to gameplay-playtesting, and G4/G6 committed content coverage
   to game-content-qa. Do not substitute bots for humans, source files for
   runtime or a rewritten smaller matrix for the approved scope.
3. Determine the actual engine and available creation/export APIs from source
   and current documentation. A Ludory game must use native Studio creation,
   trust, Runtime, image generation/import and Release contracts. Do not
   invent a universal export CLI or substitute external SDKs.
4. List relevant owner and platform permissions. Publication, live payments,
   private data, official moderation, global agent settings, frozen game
   migration and unrelated repositories are outside blanket authorization.

## Implementation sequence

Perform the stage exit checks in WFA's G0–G7 matrix. At each stage create
real work products in the game repository and evidence with exact file hashes:

- G0: game brief, core loop, player fantasy, audience, targets and non-goals.
- G1: concise GDD, feature-to-acceptance matrix, art/audio/characters, save
  and QA plan, current APIs and release constraints.
- G2: working first playable with a complete loop and a real smoke test.
- G3: polished representative vertical slice, real image/audio assets with
  provenance and current runtime/pixel review.
- G4: content complete, branch/level reachability, every promised asset
  and mechanic mapped to runtime; no invisible scope reduction.
- G5: automated regression and actual browser/native tests plus real
  playtest observations. Where required observations are unavailable,
  mark BLOCKED, never fabricate a tester or outcome.
- G6: build platform-specific candidates through **supported native APIs**;
  inspect exact archives, rights/source hashes, performance and preflight,
  tying G5 QA and candidate to the same source SHA.
- G7: report BLOCKED_EXTERNAL / owner action; no upload or publishing.

Before and after each implementation slice, refresh checks impacted by
source or asset changes. Use the project native test suite and CI; record
exact commands, exit codes and a link to the actual CI run. If an essential
check could not execute, leave that gate BLOCKED/NOT_RUN. Repair root cause
with a regression test, not a retry-only workaround.

## Project outputs and continuation

Maintain `docs/PROJECT_STATUS.md` and an optional project-specific
`artifacts/game-production-state.json` following WFA's example. Every
checkpoint must identify active gate, current source SHA, evidence and
artifact hashes, completed and incomplete criteria, actual blockers and
next executable step. After context reset, read these records and inspect
the live repo before continuing. Never claim work happened asynchronously.

Use WFA main-first, obey protected branches and required CI/reviews. Do
not force-push or remove unmerged work. A temporary branch remains if
integration is blocked; completion requires proof of main integration.

Run WFA's read-only state checker and interpret its output correctly:
structure and hashes are **not** proof that tests, model review or official
moderation executed. For release require actual project-native checks and
independent artifact evidence, not only a green state JSON.

## Final acceptance report

Deliver game repo, exact origin/main SHA, one command to launch, features
and content coverage, actual tested platforms/viewports, art/rights status,
local candidate packages with SHA-256, CI evidence, remaining P0/P1 and
every G0–G7 status. If G6 is supported, label the result
`RELEASE_CANDIDATE_LOCAL`, not published or certified by a platform.
Unresolved obligations remain explicitly BLOCKED with the next owner action.
