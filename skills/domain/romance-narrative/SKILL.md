---
name: romance-narrative
description: >-
  Use to design or audit romance-first interactive fiction and visual novels,
  including character, route, choice, emotional-beat and romance-focused review.
metadata:
  migration: ceos
  source_sha: c8cc13bd3852409be93097ee823e9cd35e512b73
  status: adapted
  integration: autonomous-editorial
  overlaps: narrative-dialogue-editor, narrative-continuity-engine, reader-experience-review
---

# Romance Narrative

Treat the current user brief, Story Bible, script, routes, locales and
author-approved canon as authoritative. Separate reusable engineering lessons
from old story canon. Do not impose romance rules on unrelated genres, fixed
route/word/date/kiss/conflict counts, synthetic chemistry scores or a mandatory
romance/mystery ratio.

## Concept and bounded review

For a new concept, summarize audience, emotional promise, setting boundaries,
protagonist agency, romantic dynamics, external stakes and excluded themes;
propose distinct premises rather than a reskinned old mystery. Obtain creative
approval before full-season drafting or product-file changes.

For existing material, review only the agreed scenes/routes. Map narrative
center, earned intimacy, character autonomy, route differentiation, choice
causality, pacing/subtext, consent/boundaries, continuity and ending
reachability. Use demonstrated actions and consequences, not affinity values or
declarations alone.

Classify findings as `CONFIRMED_DEFECT`, `EDITORIAL_RISK`,
`INTENTIONAL_CHOICE`, `EVIDENCE_GAP` or `OUT_OF_SCOPE`. Do not call reader
enjoyment proven by an editorial checklist. Preserve IDs, state effects,
locales and visual mappings unless explicit scope expansion is approved.

Use `narrative-dialogue-editor` for line-level work, `narrative-continuity-engine`
for executable state/route consistency and `reader-experience-review` for a
bounded blind-read perspective.
