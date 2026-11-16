---
name: audit
description: >-
  Use for a read-only audit of an existing software project, quality review,
  regression-risk assessment, readiness check, or evidence-based defect discovery.
metadata:
  migration: ceos
  source_sha: c8cc13bd3852409be93097ee823e9cd35e512b73
  status: adapted
  integration: autonomous
  overlaps: code-review, release-verification
---

# Audit

Audit the requested surface without changing product behavior. This is the
autonomous adaptation of the CEOS audit contract; a CEOS CLI, hooks, Web route
or model route is never a prerequisite.

## Procedure

1. Freeze the target, in-scope/out-of-scope surfaces, acceptance contract and
   read-only mutation boundary from the user request and project instructions.
2. Inspect the actual worktree, architecture, relevant tests, configuration and
   current runtime evidence. Preserve dirty and untracked user files.
3. Run only safe, relevant local checks. Use a real browser/runtime or external
   reviewer only when it is available; otherwise report the evidence gap.
4. Classify each finding as `CONFIRMED_DEFECT`, `EVIDENCE_GAP`,
   `OUT_OF_SCOPE_OBSERVATION`, `INFRASTRUCTURE_DEFECT` or `EDITORIAL_RISK`.
5. Report findings first, then evidence, limitations and one verdict for the
   locked target. Do not turn an audit into a broad refactor.

## Relationship to existing Skills

`code-review` reviews a patch/HEAD; `audit` reviews the requested current
surface and may be read-only. `release-verification` owns release gates;
`audit` may identify a release risk but does not declare release readiness.

## Completion

Use `PASS` only for the scoped audit contract with fresh evidence. Missing
essential evidence is `BLOCKED`; an observed defect is `FAIL` or a finding,
not a reason to invent a green result.
