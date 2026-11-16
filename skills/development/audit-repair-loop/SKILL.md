---
name: audit-repair-loop
description: >-
  Use for a bounded audit, minimal repair of confirmed defects, verification,
  and fresh re-audit of a product artifact or engineering surface.
metadata:
  migration: ceos
  source_sha: c8cc13bd3852409be93097ee823e9cd35e512b73
  status: adapted
  integration: autonomous
  optional_integration: CEOS only when explicitly requested and available
  overlaps: audit, root-cause-debugging, regression-testing
---

# Audit Repair Loop

Run this bounded workflow without requiring a CEOS execution engine. A CEOS
run/checkpoint mode may be used only when explicitly requested and actually
available; never fabricate a run, receipt or persisted state.

## Contract

Freeze `target`, `in_scope`, `out_of_scope`, `acceptance_contract`,
`mutation_boundary` and stop conditions before collecting evidence. Keep
release/publication/store surfaces out of the target unless the user included
them.

```text
audit → confirmed defects → one minimal repair packet → repair → verification → fresh re-audit
```

1. Collect fresh native evidence and record its source/HEAD where relevant.
2. Confirm only defects supported by evidence. Separate uncertainty,
   intentional behavior and out-of-scope observations.
3. Build one remediation packet with evidence, expected outcome, invariants,
   non-goals and acceptance checks. Do not let the auditor mutate files.
4. Apply the smallest authorized repair, preserving unrelated worktree changes.
5. Run target-proportional checks, then collect fresh evidence and re-audit
   against the original contract, not the previous recommendation.

## Bounds and fallback

Default to at most three repair cycles. Stop on `PASS`, `FAIL`, `BLOCKED`,
`ESCALATE`, missing essential evidence, a permission boundary, or repeated no
progress. If an explicitly required Web reviewer is unavailable, return
`BLOCKED`; otherwise use at most one clearly recorded native fallback for that
review unit. Do not retry transports indefinitely or change models to obtain a
preferred answer.

## Relationship to existing Skills

Use `audit` for the audit phase, `root-cause-debugging` for an ambiguous
technical defect, and `regression-testing` for the regression guard. This Skill
owns the loop order and cycle bound, not a competing debugging algorithm.
