---
name: narrative-continuity-engine
description: >-
  Use to audit route-conditioned time, location, knowledge, inventory, promises,
  consent, endings and save-state continuity in interactive fiction.
metadata:
  migration: ceos
  source_sha: c8cc13bd3852409be93097ee823e9cd35e512b73
  status: adapted
  integration: autonomous-editorial
  overlaps: romance-narrative, regression-testing
---

# Narrative Continuity Engine

Start from one authoritative game HEAD and canon revision. Independently load
authored scene data and the executable route graph; manuscript-only inference
is not runtime proof. Track chronology/location/presence, knowledge provenance,
promises and boundaries, choices/flags/inventory, payoffs and save/Back
one-shot behavior.

Run project-local graph/ending/guard/effect/locale/save checks when opted in,
then focused semantic checks over affected paths. Confirm a failure in
production data or runtime before changing code. A model checker can prove
declared edge/reachability/state constraints but not emotional meaning or
dialogue appropriateness.

Report exact scene/cue/route/state, observed versus expected condition and
proof path as `CONFIRMED_DEFECT`, `EDITORIAL_RISK`, `EVIDENCE_GAP`,
`PARTIAL_COVERAGE` or `PASS_SCOPED_CONTINUITY`. A planned ledger, zero counter
or one happy path cannot prove full-season/all-route PASS.
