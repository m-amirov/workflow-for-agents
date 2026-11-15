---
name: codebase-exploration
description: >-
  Use before implementing a change in an unfamiliar codebase to locate the
  actual entry points, data flow, contracts, tests, and correct change sites.
---
# Codebase Exploration

1. Inspect the current repository status, build scripts, documentation, and existing tests.
2. Trace the feature from user entry point through imports, calls, state, and side effects.
3. Identify authoritative contracts and implicit constraints via tests and call sites.
4. Inspect recent related changes when useful; prefer source evidence over remembered paths.
5. Map the smallest set of modules requiring changes, tests that can detect regression, and risks.
6. Report verified findings, exact paths, and unresolved questions; then implement if requested.

Do not assume folder names, architecture, framework versions, or interfaces before inspection. Do not refactor simply to understand the project. Respect existing user decisions, uncommitted changes, and main-first Git policy.

