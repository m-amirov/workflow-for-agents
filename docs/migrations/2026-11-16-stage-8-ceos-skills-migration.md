# Stage 8 — CEOS Skills migration report

Статус отчёта: `implemented` для source-bound адаптации файлов и локальных
регрессий; runtime activation/real-user rollout не объявляются полным PASS без
свежего Codex evidence.

Источник: [codex-engineering-system](https://github.com/m-amirov/codex-engineering-system)

Точный source SHA: `c8cc13bd3852409be93097ee823e9cd35e512b73`.

Target на начало Stage 8: `bc34773d6e2a504949b06918e5ae4168ccfffd13`.

## Scope and decisions

- Source CEOS был прочитан в detached read-only checkout на точном SHA.
- `global/AGENTS.md`, CEOS hooks, `ceos` CLI, execution engine, Web delegation,
  старые model routes и CEOS agent ownership не копируются в target.
- Source contracts перенесены в target Skills, но обычные workflows автономны.
- `ceos-continue` — единственный Skill с CEOS-зависимой специальной функцией:
  он активируется только по явному CEOS run/checkpoint запросу и при отсутствии
  CLI/state возвращает `BLOCKED`.
- `production-art` допускает реальные host-native generation capabilities только
  при фактической доступности и авторизации; placeholder, synthetic receipt и
  fictitious model route запрещены.

## Full migration matrix

В колонке `Source file / SHA` сокращение `c8cc13b` — это только компактное
представление полного проверенного SHA
`c8cc13bd3852409be93097ee823e9cd35e512b73`, указанного в заголовке отчёта.

| Skill | Target file | Source file / SHA | Purpose | Dependencies | Existing overlap | Autonomous? | Adaptation | Transfer status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `audit` | `skills/development/audit/SKILL.md` | `skills/audit/SKILL.md` / `c8cc13b` | Read-only evidence-based audit | Repo instructions, local checks | `code-review`, `release-verification` | Да | Removed mandatory `ceos context`; locked scope and verdict classes retained | `implemented`, runtime eval prepared |
| `audit-repair-loop` | `skills/development/audit-repair-loop/SKILL.md` | `skills/audit-repair-loop/SKILL.md` / `c8cc13b` | Audit → confirmed defects → minimal repair → verify → fresh re-audit | Native tools/tests; optional explicit CEOS | `audit`, `root-cause-debugging`, `regression-testing` | Да | Prose bounded loop is default; max 3, one fallback, no fake receipts | `implemented`, runtime eval prepared |
| `ceos-continue` | `skills/development/ceos-continue/SKILL.md` | `skills/ceos-continue/SKILL.md` / `c8cc13b` | Explicit historical CEOS continuation | CEOS CLI + persisted run state for named CEOS path | none | Нет для CEOS path; обычное continue автономно | Removed implicit activation and automatic engine start; missing state is BLOCKED | `implemented`, CEOS-dependent function not locally executed |
| `fix` | `skills/development/fix/SKILL.md` | `skills/fix/SKILL.md` / `c8cc13b` | Reproduce, diagnose, minimal fix, regression, verify | Project tests/tools | `root-cause-debugging`, `regression-testing` | Да | Removed mandatory Web/CEOS context; contract retained | `implemented`, runtime eval prepared |
| `verification` | `skills/testing/verification/SKILL.md` | `skills/verification/SKILL.md` / `c8cc13b` | Independent acceptance verification | Project-native checks, current evidence | `regression-testing`, `release-verification`, `browser-qa` | Да | Explicit single verdict and fail-closed missing evidence | `implemented`, runtime eval prepared |
| `release` | `skills/testing/release/SKILL.md` | `skills/release/SKILL.md` / `c8cc13b` | Release candidate and gate verification | Project release commands, exact artifacts, CI | `release-verification`, `verification`, `git-workflow` | Да | No assumed manifest/CEOS commands; missing mandatory gate stays BLOCKED | `implemented`, runtime eval prepared |
| `visual-qa` | `skills/design/visual-qa/SKILL.md` | `skills/visual-qa/SKILL.md` / `c8cc13b` | Runtime/browser visual QA | Real browser/runtime and image evidence when claimed | `visual-audit`, `browser-qa` | Да, если runtime доступен | Removed required Web High; retained bytes/hash/dimensions/viewport/cue proof | `implemented`, runtime eval prepared |
| `video-production` | `skills/content/video-production/SKILL.md` | `skills/video-production/SKILL.md` / `c8cc13b` | Gameplay evidence and promo trailer production | Real runtime, `ffmpeg`/`ffprobe` if available; optional authorized editor | `release-verification`, visual QA | Да при реальных clips/tools | Separate evidence/promo modes; no fake footage or external publish | `implemented`, runtime eval prepared |
| `romance-narrative` | `skills/domain/romance-narrative/SKILL.md` | `skills/romance-narrative/SKILL.md` / `c8cc13b` | Romance concept and bounded editorial review | Author canon, script, routes, locales | `narrative-dialogue-editor`, `narrative-continuity-engine`, `reader-experience-review` | Да | Removed CEOS registration and fixed numeric romance rules; semantic evidence retained | `implemented`, runtime eval prepared |
| `narrative-dialogue-editor` | `skills/domain/narrative-dialogue-editor/SKILL.md` | `skills/narrative-dialogue-editor/SKILL.md` / `c8cc13b` | Voice, subtext, context and localization edit | Current script/canon/locales | `romance-narrative`, `narrative-continuity-engine` | Да | Bounded line edits, state/route preservation and no speculative season rewrite | `implemented`, runtime eval prepared |
| `narrative-continuity-engine` | `skills/domain/narrative-continuity-engine/SKILL.md` | `skills/narrative-continuity-engine/SKILL.md` / `c8cc13b` | Route-conditioned chronology, knowledge, state and save/back continuity | Executable graph/runtime evidence, project checks | `romance-narrative`, `regression-testing` | Removed Starter Kit/CEOS assumptions; partial coverage is explicit | `implemented`, runtime eval prepared |
| `reader-experience-review` | `skills/domain/reader-experience-review/SKILL.md` | `skills/reader-experience-review/SKILL.md` / `c8cc13b` | Bounded blind reader comprehension and payoff review | Player-visible text, optional independent reviewer | `romance-narrative`, dialogue editor | Да, but independent reader is optional | `NOT_VERIFIED` replaces invented reader/Web receipt | `implemented`, runtime eval prepared |
| `production-art` | `skills/domain/production-art/SKILL.md` | `skills/production-art/SKILL.md` / `c8cc13b` | Source-bound briefs, real assets, mapping and runtime acceptance | Real image files/tool authorization/runtime evidence | `visual-qa`, `visual-audit`, `browser-qa` | Да for existing-art/mechanical path; generation capability optional | Preserved provenance, bytes/SHA-256 and separate mechanical/artistic/platform gates; no model/subagent assumption | `implemented`, generation path BLOCKED when unavailable |
| `prod-check` | `skills/operations/prod-check/SKILL.md` | `skills/prod-check/SKILL.md` / `c8cc13b` | Safe production inspection | Authorized read-only telemetry/access | `release`, incident analysis | Да, read-only | Removed CEOS context and risk engine; write boundary retained | `implemented`, runtime eval prepared |
| `incident-analysis` | `skills/operations/incident-analysis/SKILL.md` | `skills/incident-analysis/SKILL.md` / `c8cc13b` | Timeline and causal root-cause analysis | Logs/traces/screenshots/runtime state | `root-cause-debugging`, `code-review` | Да | Removed CEOS context; confidence and missing evidence retained | `implemented`, runtime eval prepared |

All source rows are accounted for. `implemented` here means the adapted Skill
and its local contract exist and are validator-covered; it does not mean that
all 15 have real Codex CLI activation evidence or that external platform gates
passed.

## Agent definitions and source dependencies

The nine source `agents/openai.yaml` definitions were adapted under their
target Skill directories with neutral names and no CEOS model/route requirement:
`audit`, `audit-repair-loop`, `fix`, `incident-analysis`, `prod-check`,
`production-art`, `release`, `verification`, `visual-qa`. Narrative and video
source Skills had no separate source agent definition at this SHA.

Source policies were not copied as a second policy hierarchy. Relevant rules
are expressed in the target Skill and point to existing target Skills such as
`root-cause-debugging`, `regression-testing`, `release-verification`,
`visual-audit` and `browser-qa`.

## Source implementation inventory

At the exact source SHA, `src/ceos.mjs` declares the confirmed 15-name
`SKILL_NAMES` list. Its `installGlobal()` additionally merges CEOS global
instructions, copies custom CEOS agent TOML files, installs the 15 Skills,
merges CEOS runtime hooks for `SessionStart`/`UserPromptSubmit`/`SessionEnd`,
creates a CEOS installation manifest and runtime context, and supports a
force/backup path. `globalStatus()` checks that CEOS-owned instructions,
agents, Skills, hooks and runtime files still match their manifest.

`global/AGENTS.md` makes CEOS context/run/checkpoint, hooks, Web delegation,
model routing, native agents and producer routes part of its operating system.
`scripts/install-global.ps1` packages the source with `npm pack`, installs the
CLI globally, invokes `ceos install-global --force` and then configures hybrid
routing. `tests/global-install.test.mjs` covers those CEOS-specific behaviors.

These source mechanisms are intentionally not copied into `workflow-for-agents`:
the target installer copies only selected Skill directories and its own
SHA-256 manifest, does not edit `AGENTS.md`/hooks/agents/CLI, has no default
force path, and detects old CEOS ownership before writing. The source tests are
evidence for the inventory, not proof of target integration.

## Global install/sync migration boundary

The named set is:

```powershell
.\scripts\install.ps1 -Scope user -Set ceos-migrated -DryRun
.\scripts\install.ps1 -Scope user -Set ceos-migrated
.\scripts\sync.ps1 -Scope user -Set ceos-migrated -DryRun
.\scripts\sync.ps1 -Scope user -Set ceos-migrated
```

Default user destination remains `~/.agents/skills/`; tests use `-HomePath`
with a disposable home. The existing manifest keeps per-file SHA-256 and the
existing no-overwrite/idempotent/local-edit protections. Legacy CEOS ownership
at `~/.codex/ceos/installation.json` is read-only inspected. A selected-name
collision returns `BLOCKED` with the exact manifest and migration plan; no
backup, deletion, hook installation or overwrite is automatic. A separately
approved future migration must preserve the old files, create a verified
backup, compare hashes, obtain ownership approval, and only then rerun install.

## Runtime/eval status

Local static and disposable install/sync tests are the acceptance layer in this
repository. Codex CLI activation requires an available stable transport and is
recorded separately. The previously observed WebSocket/HTTP 403 is an external
transport blocker; bounded attempts only, no infinite retry. No real user HOME,
CEOS CLI/hooks, existing project or external publication was changed by Stage 8.
