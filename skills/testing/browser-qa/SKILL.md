---
name: browser-qa
description: >-
  Use to verify UI behavior in a real browser, including interactions, viewport
  geometry, overflow, touch behavior, navigation, and visual regressions.
---
# Browser QA

1. Read actual acceptance criteria, target browser/device list, and approved visual references.
2. Exercise representative successful, failure, and boundary user paths in a real browser when available.
3. Check keyboard and touch interaction where applicable; verify loading, disabled, error and empty states.
4. Inspect actual element geometry, scrolling, clipping, viewport resize, and orientation changes.
5. Use recorded screenshots, reproducible steps, and precise viewport dimensions for any finding.
6. Compare before/after to ensure no unintended changes to typography, colors, images, or behavior.
7. Report checked browsers/viewports and PASS/FAIL/SKIP/NOT RUN individually.

If only source code or screenshots are available, explicitly label the result as static or screenshot-only. Do not claim actual browser testing.

