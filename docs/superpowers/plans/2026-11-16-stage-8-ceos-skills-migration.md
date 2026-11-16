# Stage 8 — CEOS Skills Migration Implementation Plan

> **For agentic workers:** This plan is executed natively in the current repository and is derived from the user acceptance contract and the read-only source checkout.

**Goal:** Перенести 15 CEOS Skills в архитектуру `workflow-for-agents`, сохранить их полезные контракты без обязательного CEOS/Web/model routing, и добавить безопасный именованный user-scope install/sync набор `ceos-migrated`.

**Architecture:** Мигрированные Skills живут в существующих категориях `skills/` и устанавливаются теми же плоскими manifest-механизмами, что и остальные Skills. CEOS CLI, hooks, agents, Web и ImageGen остаются необязательными capability paths; отсутствие capability даёт `BLOCKED`/`NOT RUN`, а не фиктивный PASS. Legacy CEOS ownership обнаруживается до записи и возвращается как конкретный migration plan.

**Tech Stack:** Markdown Skills/frontmatter, PowerShell 5.1/7 installer and smoke tests, Python stdlib validator/unittest, JSON eval fixtures, GitHub Actions.

**Spec:** User request `Stage 8 — Global Skills Migration from CEOS`; source SHA `c8cc13bd3852409be93097ee823e9cd35e512b73`.

## Global Constraints

- Работать только в `workflow-for-agents`, source CEOS читать read-only.
- Не изменять реальные `~/.agents/skills`, `~/.codex`, CEOS hooks/CLI/agents или существующие проекты.
- Не перезаписывать unmanaged/CEOS-managed Skills и не использовать `-Force` по умолчанию.
- Не делать CEOS CLI, Web High, старые model routes, ImageGen или receipts обязательными для автономных Skills.
- Сохранять `PASS`/`FAIL`/`BLOCKED`/`NOT RUN` раздельно и проверять точный SHA/manifest bytes.
- Работать в `main`; push только после обязательных локальных gates и без force-push.

## Review Focus

- `ceos-continue` не должен активироваться обычным «продолжи» как CEOS recovery; test: explicit CEOS opt-in and missing state.
- `audit-repair-loop` должен оставаться bounded и остановиться без прогресса; test: cycle limit and no-CEOS path.
- `production-art` не должен создавать фиктивные изображения или receipts; test: missing generator/reference evidence is `BLOCKED`.
- `verification`/`release`/`visual-qa` не должны объявлять общий PASS по узкому зелёному чеку; test: missing gate/pixels is `BLOCKED`.
- user install/sync должен сохранять unmanaged, legacy CEOS-managed и локально изменённые файлы; test: disposable HOME collision and idempotent repeat.

## Execution Slices

### Slice 1 — Source-bound inventory and adapted Skills

- Create the 15 target `SKILL.md` files with source SHA metadata, adapted descriptions, autonomy/CEOS dependency declarations, and explicit overlap relationships.
- Preserve source contracts for audit, bounded repair loop, CEOS-only continuation, fix, verification, release, visual QA, video, narrative, art and incident work.
- Adapt source agent definitions where present without CEOS-branded mandatory routes.
- Add a migration matrix/report with exact source file, dependencies, overlaps, autonomy and status.
- Add all 15 positive/negative activation cases to the eval fixture and static regression tests.

### Slice 2 — Safe user-scope set installation

- Add `ceos-migrated` selection to `install.ps1` and `sync.ps1`.
- Add a disposable `-HomePath` test seam without changing default user scope.
- Detect legacy CEOS installation manifests and produce a non-mutating conflict/migration message before writes.
- Extend PowerShell smoke to install/sync all 15 in a disposable HOME, verify SHA manifest, idempotency, local-edit protection, hooks/config preservation and legacy collision refusal.

### Slice 3 — Documentation and eval evidence

- Update catalog, roadmap, scripts README, Codex integration README and root README with exact source SHA, set commands, autonomy classes and honest runtime status.
- Add a Codex CLI eval report with available scenarios and `BLOCKED_EXTERNAL` for transport failures; do not invent activation evidence.
- Record final verification/CI status only after running commands on the final commit.

### Slice 4 — Final gates and publication

- Run validator, Python unittest, PowerShell 7/5.1 smoke, disposable install/sync, secret/privacy scan, `git diff --check`, and available CLI evals.
- Inspect changed files and status labels; commit on `main`, push without force, verify exact `origin/main` SHA and GitHub Actions result.
- Report any unrun/blocked gates explicitly and leave real user-global migration as a separate, approval-gated next action.

## Definition of Done

- All 15 source Skills have adapted target files and a source-bound matrix.
- Autonomous Skills do not require CEOS CLI/Web/model routes; CEOS-only behavior is explicit.
- `ceos-migrated` dry-run/install/sync are safe, idempotent, manifest-hashed and protected against unmanaged/legacy/local changes.
- Required local checks and available CI/evals have fresh evidence; missing external transport remains `BLOCKED_EXTERNAL`.
- Final changes are present on `origin/main`; no unrelated projects or real user settings were changed.
