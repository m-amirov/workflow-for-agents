---
name: verification
description: >-
  Use to independently verify implementation or acceptance claims with
  project-native checks and evidence before calling a result complete.
metadata:
  migration: ceos
  source_sha: c8cc13bd3852409be93097ee823e9cd35e512b73
  status: adapted
  integration: autonomous
  overlaps: regression-testing, release-verification, browser-qa
---

# Verification

Treat the claim as a hypothesis. Map every acceptance criterion to the
strongest safe, project-native evidence available, run the checks against the
actual current source/HEAD, and report exactly one overall verdict:
`PASS`, `FAIL` or `BLOCKED`.

Keep functional behavior, runtime presentation, authored content/cue
correctness, release artifacts and external-service availability as separate
gates. A narrow green check cannot promote an untested broader claim. Missing,
stale, inaccessible or text-only evidence is `BLOCKED`; an executed failing
check is `FAIL`. Visual claims require current runtime pixels and their bytes,
hash, dimensions, commit, viewport and state/cue; source inspection alone is
not visual proof.

`regression-testing` owns the focused guard after a repair. `release` and
`release-verification` own release-gate orchestration. This Skill is the
independent evidence-to-verdict layer and does not require CEOS/Web/model
routing.
