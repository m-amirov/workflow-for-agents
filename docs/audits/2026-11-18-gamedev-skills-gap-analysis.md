# Game Development Skills Gap Analysis — 2026-11-18

**Status:** SOURCE-BOUND STATIC AUDIT. Recommendations only; game code, skills, global installs and release gates were not changed or executed.

## Pinned evidence

| Repository | SHA | Scope |
|---|---|---|
| [awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/tree/c6ca6c41c839b68319ffc08430b99ab768debc32) | c6ca6c41c839b68319ffc08430b99ab768debc32 | 5 external Skills, router, evals |
| [workflow-for-agents](https://github.com/m-amirov/workflow-for-agents/tree/92e9f05d53acbd0f5c72661a5ae889ca9b22aed2) | 92e9f05d53acbd0f5c72661a5ae889ca9b22aed2 | WFA Skills / project profile |
| [ludory](https://github.com/m-amirov/ludory/tree/933c73b195eaf3bfffd12a31ab1cbadb27989eea) | 933c73b195eaf3bfffd12a31ab1cbadb27989eea | native narrative, runtime/storage, assets, tests |
| [kiss-at-the-edge-of-the-world-ludory](https://github.com/m-amirov/kiss-at-the-edge-of-the-world-ludory/tree/3ddd6fda1e90d6c713e34287455f9bdaced20da1) | 3ddd6fda1e90d6c713e34287455f9bdaced20da1 | current Studio-managed game and browser QA |

External Skills inspected: [visual-novel](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/c6ca6c41c839b68319ffc08430b99ab768debc32/skills/genres/visual-novel/SKILL.md), [dialogue-systems](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/c6ca6c41c839b68319ffc08430b99ab768debc32/skills/disciplines/dialogue-systems/SKILL.md), [create-game-assets](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/c6ca6c41c839b68319ffc08430b99ab768debc32/skills/disciplines/create-game-assets/SKILL.md), [game-ui-ux](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/c6ca6c41c839b68319ffc08430b99ab768debc32/skills/disciplines/game-ui-ux/SKILL.md), [save-systems](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/c6ca6c41c839b68319ffc08430b99ab768debc32/skills/disciplines/save-systems/SKILL.md).

**Terminology:** a gap can mean absent guidance, insufficient regression evidence, or a *candidate* product feature. The existence of code/test cases does not establish a runtime PASS; no undocumented absence or implementation defect is assumed.

## Evidence of existing coverage

- WFA already owns narrative continuity, romance, dialogue, blind reader review, source-bound production art, runtime visual QA, browser QA and regression testing:
  [continuity](../../skills/domain/narrative-continuity-engine/SKILL.md), [dialogue](../../skills/domain/narrative-dialogue-editor/SKILL.md), [production-art](../../skills/domain/production-art/SKILL.md), [visual-qa](../../skills/design/visual-qa/SKILL.md). Art passes are explicitly split into mechanical, artistic and platform acceptance; source, rights and asset fingerprints cannot be discarded.
- Ludory [N1 narrative graph](https://github.com/m-amirov/ludory/blob/933c73b195eaf3bfffd12a31ab1cbadb27989eea/packages/narrative/README.md) supports finite choices, predicates, relations, route locks, echoes, one-shot effects and structural ending reachability. It **explicitly excludes conditional reachability proof across runtime states**. The [runtime update](https://github.com/m-amirov/ludory/blob/933c73b195eaf3bfffd12a31ab1cbadb27989eea/packages/runtime-narrative/src/update.mjs) has session-local bounded Back and resets on reload. [Persistence](https://github.com/m-amirov/ludory/blob/933c73b195eaf3bfffd12a31ab1cbadb27989eea/packages/runtime/src/persistence.mjs) uses versioned checksummed records and fails closed for incompatible/corrupt records; [browser-storage](https://github.com/m-amirov/ludory/blob/933c73b195eaf3bfffd12a31ab1cbadb27989eea/packages/runtime/src/browser-storage.mjs) is a localStorage adapter, not a migration engine. The external save skill's temp-file/rename recipe does not directly apply.
- Ludory already has [image decoding/hash checks](https://github.com/m-amirov/ludory/blob/933c73b195eaf3bfffd12a31ab1cbadb27989eea/packages/ai/src/image-artifacts.mjs), [art-review](https://github.com/m-amirov/ludory/blob/933c73b195eaf3bfffd12a31ab1cbadb27989eea/packages/ai/src/art-review.mjs), rights gates and [narrative browser smoke](https://github.com/m-amirov/ludory/blob/933c73b195eaf3bfffd12a31ab1cbadb27989eea/packages/runtime-narrative/test/browser/smoke.mjs). Missing batch QA is a *candidate incremental step*, not a missing art system.
- Current playable authoring target is **game-studio/**, not the historical game/ slice. At the pinned game SHA, [game-studio/visuals/presentation.json](https://github.com/m-amirov/kiss-at-the-edge-of-the-world-ludory/blob/3ddd6fda1e90d6c713e34287455f9bdaced20da1/game-studio/visuals/presentation.json) has **60 media IDs, 179 mapped beats, 33 neutral entries**. [game-studio/narrative-assets.json](https://github.com/m-amirov/kiss-at-the-edge-of-the-world-ludory/blob/3ddd6fda1e90d6c713e34287455f9bdaced20da1/game-studio/narrative-assets.json) has **60 regular asset IDs** plus mobile/branding sections. These are JSON counts, **not evidence of verified image pixels or rights**.
- [game-studio/src/story.js](https://github.com/m-amirov/kiss-at-the-edge-of-the-world-ludory/blob/3ddd6fda1e90d6c713e34287455f9bdaced20da1/game-studio/src/story.js) has **164 authored choice beats and 7 ending beats**, counted in source. English strings currently fall back to Russian. [Reader pagination](https://github.com/m-amirov/kiss-at-the-edge-of-the-world-ludory/blob/3ddd6fda1e90d6c713e34287455f9bdaced20da1/game-studio/src/ui/reader-pagination.js) and local Back are implemented. The [game-specific browser QA](https://github.com/m-amirov/kiss-at-the-edge-of-the-world-ludory/blob/3ddd6fda1e90d6c713e34287455f9bdaced20da1/tests/m4-browser-qa.mjs) includes Save/Reload, selected routes, 320px and other viewports, font geometry and mobile CG switching. Its execution on this snapshot was NOT RUN by this audit.

## Five-way gap matrix

| External Skill | Current owner and implemented elements | Real improvement candidate | Priority / verdict |
|---|---|---|---|
| **visual-novel** | WFA continuity/reader/romance; native branches/endings, journal, save, Back and local pages | Condition-aware reachable paths and visible-choice proofs; optional skip-read/auto/text-speed contract needs owner decision | **P0 tests**, no bulk port |
| **dialogue-systems** | WFA dialogue editor and native author-owned JSON graph with RU/EN text | Branch-line localization ID consistency and executable response/payoff trace only where existing tests do not cover it. No new Ink/Yarn runtime | **P2 low incremental value** |
| **create-game-assets** | WFA production-art + visual-qa, Ludory hash/decode/art-review + rights | Source-bound *family* contact sheets, expected alpha/crop/scale checks and batch report aligned to live CG/portrait variants | **P1** incremental |
| **game-ui-ux** | visual-audit / visual-qa / browser-qa; reader menu, pagination, safe areas, responsive art mapping, screenshots | Focus-only path, longer translated lines, accessibility settings and untested viewports; avoid duplicating M4 QA | **P1** validation |
| **save-systems** | checksummed storage envelopes, incompatible/corrupt handling, one-shot state, Back reset by design | Old-save compatibility **policy**, recovery UX, storage-denied/quota/corruption fixtures; version migrations only for a real released-format requirement | **P0** policy/regression |

### P0: GDA-01 — route state-space and player-visible choices

Project-owned runner/fixture first; central WFA continuity skill should describe how to request and interpret evidence. Inspect existing N1 and Studio game tests before extending.

- Produce bounded witnesses with route, predicates, scene/beat and choice IDs for all *required* declared endings. At least seven ending IDs are in the current story; do not assume all are conditionally reachable until proven.
- Test route lock, unsatisfiable guard, no available choices, stale input, Back and one-shot re-entry. Separate structural reachability from actual predicate-satisfying paths.
- Cross-check DOM visibility against available options for representative conditional choices. Tests must be able to fail for an actually missing player choice.
- Gate: exact commit/fixture, reproducible trace, negative guard fixture and explicit BOUND_EXCEEDED / PARTIAL_COVERAGE; no unbounded brute force or false season-wide PASS.

### P0: GDA-02 — save compatibility/recovery contract

- Decide whether historical **unreleased** saves warrant migration; no automatic declaration of incompatibility as defect.
- Test same-version roundtrip, corrupted JSON, incompatible future envelope, storage unavailable/quota denial, safe restart and no double-applied effect.
- Version migration only with a real old-format saved fixture and owner-authorized compatibility requirement.
- Respect intentional session-local Back reset. Preserve original saves on failure and prove player-visible recovery.

### P1: GDA-03 — optional art-family QA

- Read-only report for chosen family: current game-studio source-to-media/beat map, original bytes/SHA, dimensions, decode, alpha where relevant, desktop/portrait variants and contact sheet.
- Native-resolution inspection and actual browser screenshot remain separate gates. Report can flag inconsistencies but cannot visually approve or license unseen assets.
- Negative fixtures: false alpha, changed SHA, missing/misrouted cue, wrong portrait aspect, unresolved rights. No rewriting existing images.

### P1: GDA-04 — reader and mobile UX acceptance

- Reuse current native journal, game-specific pagination/Back and existing M4 browser assertions.
- Add *only proven missing* checks for keyboard focus/order, 320/390/768/1440 viewport cases, touch, safe-area overflow and long localized text.
- Skip-read-only, auto-forward and text-speed are **optional product choices**, not confirmed bugs. EN fallback is not translated locale acceptance.
- Gate: actual screenshots, input traces and zero relevant console/geometry failures; NOT RUN if no usable browser.

### P2: GDA-05 — minimal game task routing

- Keep WFA task-planning/project profiles and Ludory-specific Skills as owners. A custom Ludory engine with an optional Phaser adapter must **not** be treated as a Phaser project merely because a package uses Phaser.
- Use request + project evidence for minimal routing: graph → continuity; voice/text → dialogue editor; CG/assets → production-art and rights; UI pixels → visual QA/browser QA; saves → runtime/release verification.
- Add positive, near-miss and negative routing evals before modifying any global Skill. Avoid loading all 79 external Skills.
- External [trigger evaluation](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/c6ca6c41c839b68319ffc08430b99ab768debc32/evals/RESULTS.md) is model-judged on descriptions; its router was excluded from scoring, and it is **not** Codex/WFA activation proof.

## Prepared fixtures — NOT RUN

| ID | Scenario | Expected ownership/stop condition |
|---|---|---|
| GD-01 | Claimed ending blocked by route lock | graph/state runner; trace or BOUNDED |
| GD-02 | Available runtime option missing as button | narrative runner + browser-qa |
| GD-03 | Choice → Back → replay | idempotent effects/state recovery |
| GD-04 | Save inside long beat → fresh reload | current beat versus reader page policy |
| GD-05 | Corrupt, future-version, quota-denied localStorage | no silent overwrite; clear player recovery |
| GD-06 | Released old save loads under newer version | only if actual old-format fixture exists |
| GD-07 | Character/light drift between related CG | provenance + independent art review |
| GD-08 | Fully opaque fake alpha where alpha required | mechanical reject |
| GD-09 | Desktop media works but mobile has wrong route cue | manifest/asset and real browser |
| GD-10 | 320px reader, long line and keyboard-only choice | layout/focus with real browser |
| GD-11 | EN switch while strings still RU fallback | localization gate NOT VERIFIED |
| GD-12 | Unrelated editorial request | negative: no game Skill or CEOS continuation |
| GD-13 | Ludory repo has optional Phaser adapter | negative: don't force Phaser engine |
| GD-14 | Neutral visual cue without licensed art | preserve neutral, no invented image |
| GD-15 | User requests release with only static checks | negative: require rights/platform/art/browser gates |

## Implementation boundaries and rollout

1. This document is **audit evidence only**. Do not change protected local project Skills, runtime behavior or global HOME based on this analysis.
2. First pilot GD-01/02 in an isolated current Studio fixture, reusing existing tests and proving one missing capability (pre-change RED if a defect is confirmed).
3. Freeze old-save compatibility requirements before introducing migrations. Preserve source records and current Back semantics.
4. Pilot art QA on one **existing** media family. New global WFA Skills are optional and require demonstrated trigger/quality advantage over production-art + visual-qa.
5. Re-run applicable unit/browser/platform/release gates on exact head after any subsequent implementation. Existing game is not declared release-ready.
6. Copying upstream code/text requires Apache-2.0 and NOTICE compliance; this report only analyzes and paraphrases with source links.

**Recommendation:** adopt selected test/QA methods, not 79 new installed Skills or a new engine. Confidence: HIGH for inspected source and static counts; candidate improvements are NOT VERIFIED until executed.
