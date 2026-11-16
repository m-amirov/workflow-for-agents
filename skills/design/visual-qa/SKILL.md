---
name: visual-qa
description: >-
  Use to verify rendered UI or game presentation with real browser/runtime
  visual evidence, including responsive, mobile, overflow and localization QA.
metadata:
  migration: ceos
  source_sha: c8cc13bd3852409be93097ee823e9cd35e512b73
  status: adapted
  integration: autonomous
  overlaps: visual-audit, browser-qa
---

# Visual QA

Read the acceptance contract and declared viewport/locale/input matrix. Run the
real browser/runtime when available and inspect current pixels for clipping,
overflow, overlap, unreadable text, wrong locale, touch/control defects,
console/page errors, runtime 404s and authored cue/asset mapping.

For each affected viewport, record screenshot bytes, SHA-256, dimensions,
current commit, URL/state/cue and observed asset/source hash. Check that the
primary action and text do not overlap, that the page reaches the viewport
edges without an unintended scroll chain, and that text is actually readable;
DOM geometry, OCR, a capture filename or source review is not pixel evidence.

If a browser/runtime or required screenshot is unavailable, return `BLOCKED` or
`EVIDENCE_GAP`, never visual PASS. Separate functional/browser checks from
visual acceptance. Use `visual-audit` for design critique and `browser-qa` for
interaction/path coverage; neither can substitute for missing current pixels.

When an independent Web reviewer is explicitly required but unavailable,
report `BLOCKED`. Otherwise use only an available bounded reviewer or clearly
label the result as local/runtime-only; never fabricate a reviewer receipt.
