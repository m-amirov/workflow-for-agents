# Git main-first workflow

- Start and finish all repository work in `main` whenever branch protection and project policy permit.
- Do not create feature/fix branches by default. Use a temporary branch only when required by PR/review rules, an isolated worktree, or parallel development.
- After all mandatory checks, merge all task changes into `main`; verify the exact final `origin/main` SHA.
- Return to `main`; delete only this task's fully integrated temporary branches, locally and remotely, after verifying no unique commits or uncommitted work remain.
- Never delete others' branches or worktrees, never force-delete unmerged work, never bypass CI/reviews/branch protection.
- If integration/cleanup is blocked, keep the branch and PR intact and report `BLOCKED`, the reason, and the remaining action.
- Use the `git-workflow` Skill when Git operations, branches, PRs, or cleanup are involved.
