---
name: narrative-dialogue-editor
description: >-
  Use to edit bounded interactive-fiction dialogue for distinct voices,
  subtext, scene rhythm, localization and branch-sensitive line correctness.
metadata:
  migration: ceos
  source_sha: c8cc13bd3852409be93097ee823e9cd35e512b73
  status: adapted
  integration: autonomous-editorial
  overlaps: romance-narrative, narrative-continuity-engine
---

# Narrative Dialogue Editor

The project-owned canon, current script, routes, locales and voice profiles
are authoritative. Review three layers separately: surface text (voice,
register, cadence), subtext (wants, fears, withheld information) and dramatic
context (knowledge, power, trust, location, consent and response).

## Bounded procedure

1. Load only the requested scene, relevant voice profiles, adjacent continuity
   beats and affected RU/EN strings.
2. Record scene/cue/utterance IDs, speaker, route/locale, voice marker,
   emotional start, line function, response and route condition.
3. Detect voice leakage, flat exposition, syntax/localization drift, broken
   attribution, knowledge/consent contradictions and mobile-unreadable lines.
4. Propose minimum before/after edits with rationale. Preserve branching IDs,
   state effects, cue-to-art mapping and all locales; request scope expansion
   before changing semantics.
5. Reinspect dependent dialogue and run available project localization/dialogue
   tests. Mark unwritten outcomes `PLANNED` or `NOT_VERIFIED`, never accepted.

“Sounds AI-written” or “make it more romantic” is a preference, not a proven
defect. Do not rewrite a whole episode on speculative style grounds.
