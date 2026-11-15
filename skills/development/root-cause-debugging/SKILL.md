---
name: root-cause-debugging
description: >-
  Use to investigate a bug, failing test, regression, error log, or unexpected
  runtime behavior. Trace and fix the cause rather than masking symptoms.
---

# Root Cause Debugging

## Evidence first

Inspect all provided logs, screenshots, failing inputs and already performed diagnostics. Do not repeat successful checks without reason.

## Procedure

1. Describe expected versus observed behavior.
2. Isolate a minimal reproduction if feasible.
3. Trace the actual execution path and data transformations.
4. Test hypotheses and locate the root cause; label uncertain deductions.
5. Implement the smallest correct change, preserving unrelated behavior.
6. Add regression coverage when reasonable.
7. Run relevant tests and report exact results and omissions.

## Avoid

- Arbitrary retries without a reasoned transient-failure model.
- Suppressing errors or changing tests just to produce a green status.
- Refactoring unrelated modules.
- Treating an agent claim as evidence.

## Completion

Report root cause and supporting facts, changed paths, regression test, executed checks and remaining limitations. See `playbooks/bug-investigation.md`.

