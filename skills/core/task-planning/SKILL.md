---
name: task-planning
description: >-
  Use for complex engineering tasks that need a concrete plan, acceptance
  criteria, risk analysis, and verification steps before implementation.
---

# Task Planning

## When to use

Use for multi-step changes, ambiguous scope, data migrations, integrations, or risky releases. Skip for trivial edits with a clear and immediate solution.

## Procedure

1. Examine actual repository state, requirements and prior decisions.
2. Define the objective and explicit non-goals.
3. Identify affected components based on real code, not assumed paths.
4. List constraints, dependencies, possible failure modes and rollback needs.
5. Split into independently verifiable steps; keep changes minimal.
6. Specify test commands or test categories and objective acceptance criteria.
7. Mark approval/dependencies only where truly necessary.

## Output

A concise plan with scope, execution order, deliverables, risk mitigations and release gates when relevant. Clearly distinguish verified context from hypotheses.

