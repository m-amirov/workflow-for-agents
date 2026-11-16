---
name: ceos-continue
description: >-
  Use for explicit CEOS run or checkpoint recovery requests; ordinary continue
  requests use the normal project workflow.
  The user must explicitly name a CEOS run, CEOS checkpoint recovery,
  or CEOS workflow continuation; ordinary continue requests use normal project workflow.
metadata:
  migration: ceos
  source_sha: c8cc13bd3852409be93097ee823e9cd35e512b73
  status: adapted
  integration: CEOS-dependent for its named continuation function
  trigger: explicit-only
---

# CEOS Continue

This is an explicit CEOS compatibility adapter, not a general continuation
workflow. A normal continue, next-step or fix-tests request must not activate
CEOS recovery automatically.

## Explicit CEOS path

1. Confirm that the user named the CEOS run/checkpoint and intended recovery.
2. Read project instructions, the actual worktree and the persisted run state.
3. If the CEOS CLI is absent, the run state is absent/stale, or the required
   lease/evidence cannot be verified, report `BLOCKED` with the exact missing
   capability. Do not infer progress from chat history or create replacement
   IDs/receipts.
4. Perform only the returned bounded action with real host tools, preserve
   dirty files, and record real artifacts. Release any real lease on success or
   error when the CEOS workflow requires it.

## Ordinary path

For ordinary development, use the repository's normal instructions, tests and
`git-workflow`. A missing CEOS binary must not block normal work. No CEOS CLI,
hook, execution engine, model route, Web route or ImageGen capability is
installed or started by this Skill.

## Hard boundary

Never claim a CEOS continuation, image generation, independent acceptance or
release PASS without the actual persisted state and evidence. A failed or
missing external capability remains `BLOCKED`.
