---
name: reader-experience-review
description: >-
  Use for a bounded blind-reader review of narrative comprehension, pacing,
  emotional engagement, romance payoff and route distinctiveness.
metadata:
  migration: ceos
  source_sha: c8cc13bd3852409be93097ee823e9cd35e512b73
  status: adapted
  integration: autonomous-editorial
  overlaps: romance-narrative, narrative-dialogue-editor
---

# Reader Experience Review

Lock episode/path/locale, exact HEAD and supplied player-visible text. In the
first pass, withhold Story Bible, author explanations and future spoilers. Ask
what the reader can actually identify: who is present, what changed, who knows
what, protagonist goal, choice cause and time/place.

Then review pacing, repeated exposition, choice interruption, earned surprise,
emotional credibility, consent and independent goals, and route differentiation
using actually reachable text/outcomes. Stress-test expected payoff from the
player-visible setup before comparing the author's promise ledger.

Classify findings as `CONFIRMED_DEFECT`, `COMPREHENSION_RISK`,
`EDITORIAL_PREFERENCE` or `EVIDENCE_GAP`, with route/locale/scene evidence.
An independent human or Web reviewer is desirable but not assumed; if absent,
record `NOT_VERIFIED` instead of inventing a blind-reader result. Do not claim
quantitative enjoyment, commercial success or release readiness.
