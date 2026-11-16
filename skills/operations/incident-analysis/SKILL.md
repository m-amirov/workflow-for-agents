---
name: incident-analysis
description: >-
  Use to reconstruct and diagnose a runtime incident from logs, traces,
  screenshots, browser state and correlated actions.
metadata:
  migration: ceos
  source_sha: c8cc13bd3852409be93097ee823e9cd35e512b73
  status: adapted
  integration: autonomous
  overlaps: root-cause-debugging, code-review
---

# Incident Analysis

Build a bounded timeline:

```text
symptom → preceding events → subsystem state → failure → recovery or terminal state
```

Correlate logs, traces, screenshots, stack traces, browser/runtime state, task
type and recent actions. Separate primary cause from secondary fallout and
unrelated noise. Record exact timestamps/timezone, evidence locations,
environment/source version, confidence and missing evidence. Label hypotheses
as hypotheses; do not claim a root cause from a single coincident log line.

This is diagnosis, not automatic deployment or repair. Use
`root-cause-debugging` when a code fix is requested, and preserve incident
artifacts without secrets or unredacted private logs.
