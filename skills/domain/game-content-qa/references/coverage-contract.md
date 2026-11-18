# Coverage ledger contract

For each approved requirement use stable ID, priority MUST / OPTIONAL /
CUT, observable outcome, scope revision and source, relevant content
scene/level/route, expected assets and locale/device/target variants,
implementation location, observed test and source/packaged evidence.
Findings: VERIFIED / MISSING / UNREACHABLE / BLOCKED / INTENTIONALLY_CUT.
Retain outstanding MUST items and original acceptance decisions.

The [coverage.example.json](coverage.example.json) is NOT_RUN and contains
no fabricated media or browser evidence. The project GDD and its acceptance
matrix remain authoritative.

## Adversarial checks

- Promised 12 levels; shipped 10 → FAIL for two unimplemented MUST rows.
- Four endings exist in source, but one unreachable → UNREACHABLE.
- CG in source but missing in mobile ZIP → G6 package parity FAIL.
- Choice node exists but UI does not expose it → FAIL.
- Author silently deletes an inconvenient feature ID → reject against
  previously approved baseline; require explicit scope change.
- QA evidence for older SHA → stale, rerun native checks.
- Duplicate IDs / traversal / symlinks / changed hash → invalid.
- Valid coverage JSON without actual game observations → structural-only,
  never G4 PASS.
- Approved cosmetic costume change is not the same as a missing character.
- CUT row with merely a local note → decision *file exists*, but its
  authentic owner approval is still externally unverified.

No arbitrary percentage of "game completeness" and no automatic release
authorization from an aggregate count.
