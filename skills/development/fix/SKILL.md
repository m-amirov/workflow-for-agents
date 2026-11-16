---
name: fix
description: >-
  Use to reproduce, diagnose, repair, and verify a reproducible software bug,
  failing test, hang, regression, or incorrect runtime behavior.
metadata:
  migration: ceos
  source_sha: c8cc13bd3852409be93097ee823e9cd35e512b73
  status: adapted
  integration: autonomous
  overlaps: root-cause-debugging, regression-testing
---

# Fix

Required shape:

```text
reproduce → diagnose → minimal repair → regression coverage → verification
```

Read the actual failure and worktree first. Prove the expected versus observed
behavior, isolate a minimal reproduction when feasible, trace the real data and
execution path, and distinguish facts from hypotheses. Apply the smallest
systemic repair, preserve unrelated changes, add a regression guard, and run
the relevant checks. A plausible explanation is not a fix; a failed check is
not a PASS.

For difficult defects, use `root-cause-debugging` as the detailed investigation
method and `regression-testing` as the test contract. Web/CEOS delegation is
optional and never replaces local reproduction, tests or real evidence.
