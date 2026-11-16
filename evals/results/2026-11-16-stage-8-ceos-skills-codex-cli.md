# Stage 8 CEOS Skills — Codex CLI eval report

Date: 2026-11-16 (Europe/Moscow)

Source SHA: `c8cc13bd3852409be93097ee823e9cd35e512b73`

Target checkout at probe: `bc34773d6e2a504949b06918e5ae4168ccfffd13` plus the
uncommitted Stage 8 changes. Real user-scope installation was not performed.

## Client and isolation

- Client: `codex-cli 0.167.2`.
- Command used once, read-only and ephemeral:

  ```powershell
  codex exec --ephemeral --ignore-user-config --sandbox read-only --skip-git-repo-check --json -C 'D:\HardWork\workflow-for-agents' "Audit this repository read-only. Do not edit files, do not run external side effects, and report whether you would activate the audit Skill versus a code-writing Skill; cite only observed repository evidence."
  ```

- No `install.ps1 -Scope user` was used for this probe. The target worktree was
  not granted write access by the CLI invocation.

## Results

| Scenario | Result | Evidence / limitation |
| --- | --- | --- |
| `audit`: read-only audit without product change | `BLOCKED_EXTERNAL` | Responses WebSocket returned HTTP 403 five times; Codex fell back to HTTP. A subsequent local tool read was rejected by the execution policy before a complete activation verdict. |
| `fix`: RED/GREEN bug repair | `NOT RUN` | External transport block; no mutation was attempted. |
| `verification`: independent result check | `NOT RUN` | External transport block. |
| `release`: missing gate must block | `NOT RUN` | External transport block. |
| `visual-qa`: real rendering evidence required | `NOT RUN` | No browser/runtime pixels were supplied or reviewed. |
| `incident-analysis`: causal log chain | `NOT RUN` | External transport block. |
| `romance-narrative`: editorial-only analysis | `NOT RUN` | External transport block. |
| `ceos-continue`: missing CEOS state | `NOT RUN` | No CEOS run/state was provided; the migrated Skill contract requires explicit opt-in and fail-closed behavior. |
| `production-art`: no ImageGen | `NOT RUN` | No generation call was made; the migrated contract requires `BLOCKED`, not placeholder output. |
| Irrelevant Skill non-activation | `NOT RUN` | The single transport-blocked turn cannot prove the complete negative matrix. |

The CLI output did show a preparatory message selecting `context-engineering`,
but it did not complete a source-bound Stage 8 Skill activation/evaluation and
must not be promoted to PASS.

## Local evidence that is separate from CLI activation

- `python scripts/validate.py`: PASS, including 15 CEOS migration eval cases.
- `python -m unittest discover -s tests -v`: run at final verification; report
  the fresh result in the completion response.
- PowerShell 7 and Windows PowerShell 5.1 disposable-home smoke: PASS for
  install/sync, SHA manifest, idempotency, local edits, unmanaged files and
  legacy CEOS collision protection.

## Stop line

Do not retry the CLI transport in this Stage 8 run. A future eval requires a
fresh isolated HOME/`CODEX_HOME`, real installation into that disposable scope,
stable transport and a new run-specific evidence record.
