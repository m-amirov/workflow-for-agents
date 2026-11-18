---
name: game-content-qa
description: >-
  Use to reconcile approved design and acceptance IDs against implemented
  levels, scenes, choices, routes, mechanics, media and shipped game packages.
  Detect omissions, unreachable content, stale evidence and silent scope cuts.
  Not for GDD writing, artistic image review, human playtesting or native
  unit tests.
---

# Game Content QA — promised content versus observed game

Activate when accepting [Game Production G4/G6](../../../playbooks/game-production.md),
auditing content completeness, or investigating missing choices, images,
characters, levels, scenes and endings.

## Ownership and exclusions

- [game-docs](../../gamedev/workflows/game-docs/SKILL.md) owns editing the GDD.
  Audit the **approved versioned requirements**, not a newly regenerated
  list of only the currently implemented features.
- [narrative-continuity-engine](../narrative-continuity-engine/SKILL.md)
  and native narrative/level graph tests own reachability.
  [visual-qa](../../design/visual-qa/SKILL.md) owns browser pixels;
  [production-art](../production-art/SKILL.md) and
  [character-consistency-qa](../character-consistency-qa/SKILL.md)
  own art provenance and identity; [release-verification](../../testing/release-verification/SKILL.md)
  owns release gates. A file inventory substitutes for none of these.

## Audit workflow

1. Identify approved acceptance matrix, scope revision, current game HEAD,
   actual runtime entrypoints and platforms. Missing baseline means
   BASELINE_BLOCKED; do not shrink requirements to make a build pass.
2. Prepare a requirement-by-requirement ledger with stable IDs,
   MUST/OPTIONAL/CUT priority, expected locations, scenes/assets and platform
   variants. Record original scope and all explicit cut decisions.
3. Walk actual content registry, executable graph, asset-to-scene mapping,
   localization references and game actions. Find missing files, swapped or
   duplicated assets, broken conditions, unreachable choices/endings,
   placeholders and unshipped promised functionality.
4. Compare production build archives, not just development source. For
   portrait/desktop variants, check the intended real files and selection.
   Detect choices, fonts, portraits or CGs that vanish after export. Capture
   actual archive content and platform-specific receipts.
5. Report VERIFIED / MISSING / UNREACHABLE / BLOCKED /
   INTENTIONALLY_CUT per requirement, linked to exact source and evidence.
   Missing MUST, silent cuts and unreachable committed endings are FAIL.
   Intentional cuts require an explicit approved change reference.
6. Execute project-native reachability, save/back, asset load, browser and
   package tests where applicable. Keep actual command, output/exit code,
   source SHA, screenshots/graph traces and defect reproduction.
7. Re-audit after fixes; tests on an earlier SHA do not prove current build.
   Route missing UX comprehension to gameplay-playtesting, graph bugs to
   native narrative/level owners, pixel defects to visual-qa, rights to
   project-native rights review. Content complete cannot imply G6/G7 PASS.

## Offline helper is NOT an engine

Use [manifest contract](references/coverage-contract.md) and optional
[read-only structural checker](../../../scripts/game_content_qa.py) for
file/reference hygiene when the game has no stronger native checker.

~~~powershell
python scripts/game_content_qa.py --project C:\work\new-game --manifest artifacts/content-coverage.json --json
~~~

Exit 0 proves structural consistency of declared rows, paths and hashes
only; it cannot prove that a claimed runtime test executed, a player used a
choice, a platform package was accepted, an asset looked correct, or a cut
was actually approved. Exit 1 indicates invalid/blocked requirement records.
Prefer native game/SDK checks and independent current runtime evidence.

No G4 CONTENT_COMPLETE_PASS without source-bound **observed runtime**
and actual target package/parity checks when required. A green synthetic
manifest or generic CI is insufficient.
