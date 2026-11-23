---
name: design-variant-selector
description: >-
  Use when the owner wants an in-page side-by-side or switchable trial of UI
  directions (e.g. ?select); do not activate for finalized design or analytics A/B tests.
---

# Design Variant Selector

## Procedure
1. Confirm which **unapproved** decisions require comparison. Present 3–5 meaningfully distinct, accessible options within existing project constraints; don't churn approved components.
2. If authorized to implement, choose an isolated dev/preview selector. A `?select` panel is an **optional convention**, not a new product contract; detect routing/query parameter conflicts first.
3. Changing an option updates the live page and a stable, shareable URL while preserving unrelated query/hash state. Unknown values fall back to defaults. Provide reset and a link with panels hidden.
4. Keep global tokens synchronized across affected elements; ensure the selector never obscures content on mobile and does not modify business data or analytics.
5. Prevent preview state from creating SEO duplicates: canonical points to the base indexable URL, variants do not enter sitemap, and preview indexing policy follows project requirements. Do not silently deploy preview controls.
6. Verify refresh, back/forward, direct URL, small screens, invalid options and removal of the `select` switch. Get explicit owner approval before changing the project's default design.

## Output
Options/changes, preview links if they exist, chosen state if approved, test evidence and unverified cases. Selection is **not** a production A/B experiment or conversion proof.

Related: [UI design policy](../../../rules/design.md), [interface design process](../../../playbooks/interface-design.md).
