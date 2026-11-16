# Stage 11 — Transactional Global Skills Rollout Readiness

## Scope and evidence

Stage 10's read-only real-HOME snapshot found 29 implemented Skills,
two CURRENT (git-workflow, root-cause-debugging) and 27 NOT_INSTALLED.
The 15 directories in \`~/.codex/skills/\` were classified
OWNERSHIP_UNVERIFIED and are out of the WFA install target.
A fresh preflight is required immediately before any real change.

Only the central \`workflow-for-agents\` repository is changed by this stage.
The assistant cannot access the user's Windows drive or real HOME through
GitHub operations. **No user machine installation, backup or migration is
claimed.** User approved a future backup-backed installation; this stage
implements the guarded procedure and tests it in disposable HOME.

## Implementation contract

- New \`scripts/InstallTransaction.ps1\`: stage full source snapshots, hashes,
  preserve previous manifest, prepare/journal, add-only rename to target,
  verify manifest, and rollback on caught failures.
- \`install.ps1 -Recover\`: explicitly recover interrupted staging or
  multi-Skill commits. Never overwrite user-modified newly installed files.
- User installation to real HOME requires an external \`-BackupPath\` outside
  both selected HOME and WFA Skills tree. Backup holds original manifest,
  existing managed Skills and checked hashes. No legacy owner transfer.
- \`sync.ps1\` and \`global-preflight.ps1\` detect pending install transactions;
  separate sync/install journals are not interchangeable.
- Fault injection limited to a marked disposable HOME under system TEMP.
- Existing projects, \`AGENTS.md\`, hooks and \`~/.codex/skills/\` untouched.

## Release gates

Source code and regression coverage: implemented. Exact CI results and
final SHA must be supplied from a completed GitHub Actions run, not inferred.

User HOME preflight/backup/install/postflight: NOT RUN.
Actual model activation and overlapping Skill selection: NOT RUN.
Multi-directory writes cannot be fully atomic against process/power loss or
noncooperating concurrent writers. Recovery is fail-closed.

Local rollout sequence documented in
[scripts/README.md](../../scripts/README.md).
