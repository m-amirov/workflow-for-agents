# Instructions for agents working in Workflow for Agents

This repository is a curated knowledge and skills library, not an application.

## Work order
1. Read README.md, docs/ARCHITECTURE.md, docs/ROADMAP.md and relevant local files.
2. Inspect existing material before adding instructions or changing conventions.
3. Keep **rules**, **skills**, **knowledge**, **playbooks**, **prompts**, **agents**, and **project references** distinct.
4. Prefer a focused change; do not invent a new framework or dependency without a concrete need.
5. Label status as implemented / draft / planned. Do not silently promote a plan into a verified capability.
6. Capture root causes and evidence; distinguish tested observations from hypotheses.
7. Never claim tests passed unless the commands actually ran, and record relevant commands, environment, and outcomes.
8. Preserve explicit user-approved project decisions. Do not alter unrelated projects.
9. Never commit passwords, API keys, access tokens, cookies, private files, or unredacted logs.
10. Review relevant changed files, references, and status labels before finishing.
11. Always use a **main-first** Git workflow: do not create side branches by default. If a temporary branch or worktree is required, integrate its verified task changes into `main` and safely delete only task-owned fully integrated branches. Return to `main` and report its exact SHA. Preserve unmerged or third-party work; do not bypass CI/reviews/branch protection. See `skills/development/git-workflow/SKILL.md`.

## Rules hierarchy
- Repository-specific operating instructions: this AGENTS.md.
- Policy details: rules/*.md.
- Workflow procedure: playbooks/*.md.
- Task-specific skill: a matching skills/**/SKILL.md.
- Project facts: the current project's own repository is authoritative.

Do not ingest the entire library into context by default. Discover by catalog and load only applicable material.

## Branch completion gate
For every change, verify it exists in `origin/main`. If the required integration is blocked by branch protection, conflicts, missing permissions or checks, preserve the branch and report `BLOCKED`; do not claim completion or force-delete. Report the final main SHA and status of task-owned temporary branches.

## Quality gates
When changing a skill: check metadata, trigger quality, relative paths, linked scripts and test cases. When changing an integration: state which platforms/environments were actually tested. A successful commit is not proof that functionality was verified.

## Completion response
Briefly report what changed, file paths, actual checks (or “not run”), known limitations, and next action.
