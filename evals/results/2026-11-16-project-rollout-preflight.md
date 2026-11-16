# Stage 7 — profile rollout preflight and Eskizno pilot

**Date:** 2026-11-16  
**Central baseline:** `96c7d696a5a2ffde2d555d6c43223701f54f6ea6`  
**Status:** implementation and isolated rollout evidence; no source project was changed.

## Operational contract

`install.ps1 -Profile` and `sync.ps1 -Profile` now call the shared PowerShell
preflight before planning or writing files. It verifies a Git checkout with
`origin`, normalized canonical repository, exact `HEAD == source_sha`, strict
manifest shape, protected local Skills and unmanaged name collisions. A failed
check returns `BLOCKED` before an installation plan can write anything.

The preflight has an explicit operation boundary. `skill-install` is the only
operation accepted by the installers; asking the standalone preflight for
`prototype`, `merge` or `release` is `BLOCKED`. It therefore cannot convert a
profile installation into project authorization.

## Isolated regression checks

Environment: Windows, PowerShell 7 and Windows PowerShell 5.1, temporary Git
repositories and bare local remotes.

| Check | Result | Evidence |
| --- | --- | --- |
| Matching canonical remote and exact SHA | PASS | profile install dry-run and install completed |
| Wrong remote / no Git checkout | PASS | `BLOCKED` before target Skill directory appeared |
| Stale `HEAD` | PASS | `STALE_EVIDENCE` caused `BLOCKED` |
| Corrupt manifest | PASS | `BLOCKED` before planning |
| Existing managed Skill | PASS | repeat install reported `SKIP` |
| Unmanaged same-name Skill | PASS | `BLOCKED` when manifest was withheld |
| PR-only refinement / forced direct-main | PASS | normal refinement passed; explicit direct-main was `HARD_CONFLICT` |
| Prototype authorization | PASS | `-Operation prototype` was `BLOCKED` |
| Dry-run / failed preflight writes | PASS | no managed Skill appeared before permitted install |
| Local edit during sync | PASS | sync exited `1` and preserved the edit |

`scripts/tests/Smoke.ps1 -SkipUserScope` executed the regression fixture in
both engines. User-scope smoke is intentionally skipped locally because the
real user profile is not an isolated test home; CI covers that scope.

## Current read-only source checks

Remote `main` was queried immediately before the checks.

| Project | HEAD / profile source SHA | Preflight | Isolated dry-run |
| --- | --- | --- | --- |
| Ludory | `933c73b195eaf3bfffd12a31ab1cbadb27989eea` | PASS with stop-line refinement | PASS, no writes |
| Eskizno | `7e10b7db7c5b37ab3ed1e004ebf85234bd9faf15` | PASS with stop-line refinement | PASS, no writes before pilot |
| Dachametr | `c474c916095651aaa95079193a05af8f0d51558c` | PASS with PR-only and stop-line refinements | PASS, no writes |
| Twork | `00a54d4d1d532332aef085ef7868cc66d5695e87` | PASS with PR-only and stop-line refinements | PASS, no writes |

For Dachametr, `Prototype Authorization` remains **NOT AUTHORIZED**. For
Twork, this preflight did not start tasks, create production sessions, submit
answers, merge, release or deploy.

## Eskizno disposable pilot

Disposable clone exact HEAD:
`7e10b7db7c5b37ab3ed1e004ebf85234bd9faf15`.

- Root `AGENTS.md` and eight existing local Skills were inventoried first.
- The profile preflight and install dry-run passed; planned Skills were
  `drawing-editor`, `visual-audit`, `browser-qa`, `regression-testing`, and
  `root-cause-debugging`.
- Installation created five managed directories and a manifest. Every managed
  manifest SHA-256 matched its installed files; hashes of the four protected
  Eskizno local Skills remained unchanged.
- Repeat install reported five `SKIP`s. Profile sync dry-run reported up to
  date.
- A deliberate edit to the disposable `drawing-editor/SKILL.md` made sync
  exit `1`; the edited file stayed intact.

Only the disposable clone was modified. No Eskizno application, Canvas code,
lessons, tests, settings, branch or remote source repository changed.

## Codex CLI observations

Client: `codex-cli 0.167.2`, read-only sandbox, disposable Eskizno clone.

| Prompt | Result |
| --- | --- |
| Locked layer fix | PARTIAL: Codex selected `drawing-editor`, named locked-layer and gesture/history invariants, and made no changes. Its final answer says it did not read Skill files, so this is not proof of internal Skill-file loading. |
| Undo/redo after new action | PARTIAL: Codex selected `drawing-editor`, gave the expected `A → B → undo → C` redo-clearing check and kept device evidence separate; no commands or writes. |
| CSS-only, Canvas theory, no-device-evidence prompts | NOT RUN: the batch invocation was interrupted after the first successful response; no claim is made about non-activation. |

An initial CLI invocation received a Responses WebSocket `403` before a turn;
a retry with `--ignore-user-config` completed. CLI output is an observable
response, not a complete audit of hidden activation or every file read.

## Remaining release gates

- Real-project rollout remains **NOT AUTHORIZED** and was not attempted.
- Complete Codex positive/negative matrix when a stable CLI transport is
  available.
- Run GitHub Actions on the final central commit; that result is recorded only
  after the commit is pushed.

## Stage 7.1 freshness follow-up

The operational preflight now uses read-only `git ls-remote origin
refs/heads/main`. It reports `CURRENT`, `LOCAL_STALE`, `PROFILE_STALE`, or
`REMOTE_UNVERIFIED` and blocks rollout unless all three of target `HEAD`,
profile `source_sha`, and remote `main` agree. No fetch, pull, reset or
checkout is performed.

At the follow-up check, Ludory, Eskizno and Dachametr were `CURRENT`. Twork
remote `main` had advanced to `ad90501d307c42840eb2d727c31ae2355196e3be` while
the profile remains pinned at `00a54d4d1d532332aef085ef7868cc66d5695e87`;
the preflight returned `PROFILE_STALE` and blocked rollout. The older SHA
remains historical evidence, not current rollout authorization.

The available CSS-only Codex CLI run exited `0` and said `drawing-editor` was
not needed. This is an observable response only; it does not prove hidden
Skill-loading behaviour. The complete CLI matrix remains partial because the
transport previously returned WebSocket/HTTP `403` and batch runs were not
reliable.
