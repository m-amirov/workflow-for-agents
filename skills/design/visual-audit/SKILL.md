---
name: visual-audit
description: >-
  Use to evaluate an existing interface visually for hierarchy, spacing,
  typography, interaction consistency, responsive layout, and design quality
  without silently changing approved visual decisions.
---

# Visual Audit

## Input

Inspect screenshots, actual browser renders, project design rules, reference assets and target viewports.

## Procedure

1. Establish what the UI is supposed to do and which design choices are already approved.
2. Check spacing rhythm, typography, density, hierarchy and component states.
3. Check real rendering at mobile, tablet and desktop widths relevant to the product.
4. Inspect overflow, clipping, visual contrast, touch targets and image handling.
5. Identify generic/templated visual artifacts only when supported by concrete evidence.
6. Rank findings by user impact and give focused changes with expected effects.
7. After implementation, compare before/after renders and verify no approved colors or fonts changed unintentionally.

## Guardrails

Do not redesign the product from scratch when asked for an audit. Do not modify approved palette, fonts, media assets or interaction semantics without an explicit reason. If the browser was not used, label the review screenshot-only.

