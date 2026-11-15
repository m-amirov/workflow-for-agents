---
name: regression-testing
description: >-
  Use after fixing a bug or changing behavior to create focused tests
  that fail on the original defect and pass with the corrected behavior.
---

# Regression Testing

1. Extract the smallest input and environment that reproduces the defect.
2. Determine the intended contract and select the appropriate test level.
3. Prefer a test that fails against the pre-fix implementation.
4. Implement deterministic assertions for the actual wrong behavior.
5. Cover a nearby negative or boundary case where relevant.
6. Run the new test, surrounding tests and any required integration checks.
7. Report exact commands and outcomes; identify environmental skips.

Avoid snapshots that merely freeze a known bug, mocks that bypass the affected path, or tests which cannot detect a recurrence. If pre-fix red cannot be verified, say so.

