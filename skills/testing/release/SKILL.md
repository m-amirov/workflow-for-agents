---
name: release
description: >-
  Use to prepare or verify a release candidate with project-native release
  gates, exact source/artifact evidence, and no unrequested product redesign.
metadata:
  migration: ceos
  source_sha: c8cc13bd3852409be93097ee823e9cd35e512b73
  status: adapted
  integration: autonomous
  overlaps: release-verification, verification, git-workflow
---

# Release

Lock the target commit, dependency inputs, platform scope and required gates.
Run the gates the project actually defines: repository provenance, lint/types,
unit/integration/E2E/browser, production build, runtime smoke, platform checks
and artifact validation as applicable. Inspect the final artifact and hashes
when reproducibility matters, and ensure CI evidence applies to the same exact
source/artifact.

Use `PASS` only when every mandatory gate passes. A missing mandatory gate,
unavailable platform/runtime, stale CI result, baseline mismatch or missing
artifact evidence is `BLOCKED`; an executed failed gate is `FAIL`. Do not
deploy, publish, merge or change release settings unless separately
authorized. `release-verification` provides the shared gate checklist; this
Skill adds release-candidate scope and provenance.
