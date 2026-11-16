---
name: prod-check
description: >-
  Use to inspect production health, logs, metrics, configuration, database
  reads, provider state, or live verification in read-only mode.
metadata:
  migration: ceos
  source_sha: c8cc13bd3852409be93097ee823e9cd35e512b73
  status: adapted
  integration: autonomous-read-only
---

# Production Check

Default to R0/read-only inspection. State exactly which production surfaces,
time window, environment and evidence were inspected. Distinguish observed
health from missing telemetry and from a hypothesis. Never turn an inspection
into deploy, restart, queue mutation, provider submit, secret read or database
write.

If a write or privileged action is required to prove the requested condition,
stop with `BLOCKED`, name the missing authorization/evidence and leave the
system unchanged. This Skill does not require CEOS CLI, hooks or a particular
provider/model route.
