# Дорожная карта и критерии приёмки

## Status legend

- `[x]` — файл/документация создана; **это не означает**, что интеграция протестирована.
- `[ ]` — не реализовано или не проверено.
- Прогресс фиксировать только после осмотра репозитория и доказательств выполнения.

## Этап 1: Foundation

**Цель:** база становится пригодной для реального использования в Codex.

- [x] Создан репозиторий, README, архитектурный план, каталог и правила.
- [x] Добавлены начальные примеры Skills, включая main-first git-workflow.
- [ ] Протестировать git-workflow на реальном Codex-проекте, в том числе protected main, squash и ошибках merge (eval-кейсы пока только описаны).
- [x] Десять базовых Skills оформлены в `SKILL.md`.
- [x] Составлены позитивные и негативные eval-кейсы для 10 Skills, автоматизирована проверка их структуры.
- [x] Выполнить реальные positive/negative activation tests через Codex для `git-workflow` и `root-cause-debugging`; результаты и ограничения: [eval report](../evals/results/2026-11-15-codex-cli-foundation.md).
- [x] Реализован `scripts/install.ps1`: user/project scope, выбор Skills, dry-run, content fingerprint manifest, отказ от небезопасной перезаписи.
- [x] Проверена установка и синхронизация в `user` и `project` scope на Windows CI (PowerShell 7 и 5.1, временные каталоги/профиль runner).
- [x] Проверить подключение глобальных инструкций и реальную активацию Skills на пользовательской Windows-машине в Codex CLI 0.167.2; защищённый GitHub main отдельно не проверен.
- [x] Реализован `scripts/sync.ps1`: сверка SHA-256, добавление/обновление/удаление отслеживаемых файлов, защита локальных правок, dry-run, версии по содержимому.
- [x] Реализован валидатор `scripts/validate.py`: frontmatter, имена, каталог, внутренние Markdown-ссылки, структура eval-кейсов. Исполняемые ресурсы Skills следует проверять дополнительно по мере появления.
- [x] Добавлен CI на push в `main` и PR: Linux Python + Windows PowerShell 7/5.1. Результаты проверяются по конкретным workflow runs.
- [x] Сквозная приёмка: установить 2 Skills в user scope, подтвердить совпадение SHA и активировать их реальными positive/negative Codex CLI сценариями в отдельных временных репозиториях.

**Gate:** установка, синхронизация и реальный вызов Skills подтверждены в доступной локальной среде. Текущие результаты: [Отчёт о проверках](VERIFICATION.md) и [реальные Codex evals](../evals/results/2026-11-15-codex-cli-foundation.md).

## Этап 2: Knowledge

**Цель:** проверенный проектный опыт доступен для повторного применения.

- [x] Провести read-only инвентаризацию Ludory, Eskizno, Dachametr, Twork на exact remote SHA: [Stage 1 inventory](../knowledge/research/project-inventory.md).
- [x] Пилотно перенести два подтверждённых решения из Ludory и Dachametr с source SHA и CI evidence: [patterns](../knowledge/patterns/).
- [x] Уточнить безопасные локальные evidence Eskizno/Twork и независимо воспроизвести оба pilot pattern: [Stage 2 evidence](../knowledge/research/stage-2-evidence.md).
- [x] Реализовать и проверить первый специализированный Skill `browser-automation`: [source evidence](../knowledge/research/browser-automation-evidence.md), [Codex eval](../evals/results/2026-11-15-browser-automation-codex-cli.md).
- [x] Реализовать и проверить `drawing-editor` на source-bound контрактах Eskizno: [source evidence](../knowledge/research/drawing-editor-evidence.md), [Codex eval](../evals/results/2026-11-16-drawing-editor-codex-cli.md).
- [x] Реализовать `classification-quality` на offline replay контрактах Twork: [source evidence](../knowledge/research/classification-quality-evidence.md), [eval evidence](../evals/results/2026-11-16-classification-quality-codex-cli.md). Это не измерение качества Twork или внешняя platform acceptance.
- [ ] Заполнить `knowledge/incidents/` и `knowledge/decisions/` только после появления source-bound случаев; не создавать их ради полноты каталога.
- [ ] Добавить специализированные Skills по нескольким наиболее повторяемым задачам.
- [x] Подготовить [проектные профили подключения](../projects/) и минимальный выбор Skills через `install.ps1 -Profile`/`sync.ps1 -Profile`.
- [x] Добавить ограниченную [диагностику совместимости](../scripts/project_profiles.py): декларативные profile/constraint checks, без ложного семантического анализа произвольного `AGENTS.md`.
- [x] Проверить project-profile selection и конфликтные read-only сценарии реальным Codex CLI: [eval evidence](../evals/results/2026-11-16-project-profiles-codex-cli.md).
- [x] Добавить обязательный operational preflight для profile install/sync: canonical remote, exact source SHA, manifest/local-Skill protection и stop-line boundary до записи файлов. Пилотный rollout и фактические ограничения фиксируются отдельным evidence report.

**Gate:** у каждого утверждения о причинах, исправлениях и результатах есть проверяемый источник; ни один проектный индекс не заменяет актуальные факты в исходном репозитории.

## Этап 3: Automation

**Цель:** база растёт управляемо, без потери качества.

- [ ] Автоматическая проверка схемы Skill и ссылок.
- [ ] Evals на корректную активацию/неактивацию и выполнение Skills.
- [ ] Кандидаты на новые knowledge entries из закрытых PR; не публиковать автоматически без проверки подтверждений.
- [ ] Адаптеры для Claude Code, Gemini CLI и локальных агентов.
- [ ] Версионирование и lockfile подключений отдельных проектов.
- [ ] Поиск по каталогу; семантический поиск только при реальной необходимости.

**Gate:** несколько агентов используют общий источник, при этом порядок применения правил прозрачен, обновления воспроизводимы, а существующие сценарии не регрессируют.

## Этап 8: Global Skills Migration from CEOS

**Статус:** `implemented` для source-bound адаптации, локальной валидации и
disposable install/sync regression; `PARTIAL` для реальной Codex activation и
внешних capability gates, пока соответствующие окружения не дадут свежие
evidence.

- [x] Учтены все 15 Skills source SHA `c8cc13bd3852409be93097ee823e9cd35e512b73`.
- [x] Убраны обязательные CEOS CLI/hooks, старые model routes и Web High из автономных путей.
- [x] `ceos-continue` ограничен явным CEOS run/checkpoint запросом и fail-closed при отсутствии state.
- [x] `audit-repair-loop` сохраняет bounded audit → repair → verify → fresh re-audit.
- [x] `production-art` сохраняет source-bound briefs, provenance, bytes/SHA-256, mapping и отдельные acceptance gates.
- [x] `install.ps1`/`sync.ps1` поддерживают `-Set ceos-migrated`, disposable `-HomePath`, legacy ownership collision plan и no-overwrite.
- [x] Добавлены 15 positive/negative eval cases, static regression и PS7/5.1 smoke.
- [ ] Реальная активация всех 15 Skills в Codex CLI — только после стабильного transport; WebSocket/HTTP 403 классифицируется `BLOCKED_EXTERNAL`.
- [ ] Реальный user HOME rollout — не выполнен; требует отдельного разрешения на backup/ownership migration конфликтующих CEOS-файлов.

Подробная матрица и границы: [Stage 8 migration report](migrations/2026-11-16-stage-8-ceos-skills-migration.md).

## Stage 9A: Logging Standard

**Статус:** implemented (Skill, synthetic fixtures, structural positive/negative evals); real Codex activation NOT RUN.

- [x] Автономный logging-standard: этапы, correlation IDs, retries/fallback, минимальный безопасный контекст.
- [x] Подготовлены LS-01…LS-10 (6 positive, 4 negative), без фиктивного PASS.
- [x] Схема evals проверяется валидатором; добавлены negative regression tests.
- [ ] Реальный Codex CLI positive/negative activation: NOT RUN, требует доступного transport.
- [ ] Реальная user-scope установка: NOT RUN, требует отдельно проверенного HOME и ownership.

Идеи сопоставлены с [codex-multi-agent-dev](https://github.com/rustlung/codex-multi-agent-dev) на SHA 3c2e31016b62a052a4c2231891264ec12cf10f3f.
Текст Skill создан самостоятельно, без копирования runtime или инструкций агента.

## Stage 9B: Adaptive Task Routing

**Статус:** implemented для автономной routing policy и offline tests;
реальная Codex activation и subagent composition в хосте — NOT RUN.

- [x] Расширен существующий \`task-planning\`, без новых обязательных Skills.
- [x] Добавлена read-only policy CLI: TYPE/SIZE/RISK отдельно, evidence-backed
  risk signals, optional user override as minimum, UNASSESSED fail-closed.
- [x] Пропорциональные Architect/Reviewer gates, обязательная документационная
  свежесть и optional specialist, раздельные анти-loop budgets.
- [x] Выполнена проверка структурной схемы 12 TR-сценариев (9 routing + 3
  no-activation), добавлены offline policy regression cases.
- [ ] Host Codex positive/negative activation: NOT RUN. Маршрутизатор не
  запускает агентов и не объявляет модель или релиз подтверждёнными.
- [ ] Реальная установка в global HOME и существующие проекты: NOT RUN.

Идеи сопоставлены с [codex-multi-agent-dev](https://github.com/rustlung/codex-multi-agent-dev)
на SHA \`3c2e31016b62a052a4c2231891264ec12cf10f3f\`;
policy и Python реализация написаны самостоятельно.

## Stage 9C: Transactional Global Sync

**Статус:** реализованы staging, rollback и явное recovery;
локальная/CI проверка фиксируется по точному SHA отдельно.

- [x] Staged full Skill snapshots с сохранением unmanaged local files.
- [x] Backup manifest, transaction journal, sha256 verification до и после замены.
- [x] Автоматический rollback при обрабатываемой ошибке commit.
- [x] Pending state блокирует install и sync, включая DryRun.
- [x] Явный sync -Recover с защитой post-interruption user edits.
- [x] Failure-injection в disposable HOME для обоих PowerShell runtimes.
- [ ] Реальная пользовательская установка и синхронизация: NOT RUN.
- [ ] Настоящая atomicity при power loss/конкурентном writer: НЕ ГАРАНТИРУЕТСЯ.

## Антицели

Не запускать оркестрацию нескольких агентов, централизованную БД или сложный индексатор раньше, чем простая файловая библиотека покажет ограничения.

## Этап 10: Global Skills Compatibility Audit & Migration Preflight

**Статус:** `implemented` для автономного read-only preflight и disposable
regression fixtures; реальная миграция глобальных Skills — `NOT RUN` и требует
отдельного разрешения владельца. Последний source-bound CEOS SHA:
`c8cc13bd3852409be93097ee823e9cd35e512b73`.

- [x] Добавлен `scripts/global-preflight.ps1` поверх существующих
  `SkillUtils` manifest/SHA/legacy/pending-transaction механизмов.
- [x] Поддержаны `-Set ceos-migrated`, полный `-All`, `-OutputFormat Json` и
  явный disposable `-HomePath`; preflight не вызывает install/sync/recovery и
  не создаёт файлы в проверяемом HOME.
- [x] Инвентаризируются оба global Skills root, WFA manifest, legacy CEOS
  manifest, `SKILL.md` SHA, content fingerprints, source metadata и activation
  overlaps; неизвестное владение классифицируется fail-closed.
- [x] Добавлены 16 disposable сценариев: пустой/current/partial HOME, legacy
  CEOS, unmanaged/user-modified collisions, invalid/missing/traversal manifest,
  junction, pending transaction, повторяемость и пользовательские settings.
- [x] Добавлены отдельные PS7/PS5.1 CI smoke entrypoints.
- [x] Подготовлен backup-backed migration plan без исполнения ownership change.
- [ ] Отдельный просмотр отчёта владельцем и явное разрешение каждой реальной
  ownership migration; до этого не запускать install/sync на конфликтующих rows.
- [ ] GitHub Actions на финальном Stage 10 SHA — проверяется после публикации
  изменений в `origin/main`; реальный HOME gate фиксируется отдельным evidence.

Результат и ограничения: [Stage 10 global Skills preflight report](migrations/2026-11-16-stage-10-global-skills-preflight.md).

## Stage 11: Transactional Global Skills Installation

**Статус:** реализовано add-only transactional install и disposable regression
suite; реальная пользовательская установка/activation — NOT RUN в рамках
GitHub-исполнения и требует локального запуска на компьютере владельца.

- [x] \`install.ps1\` использует staging, snapshots/manifest SHA и journal,
  автоматический rollback для пойманных ошибок и explicit \`-Recover\`.
- [x] В real user HOME перед записью обязателен новый внешний
  \`-BackupPath\`; бэкап текущего manifest и managed Skills проверяется SHA-256.
- [x] Существующие WFA-managed Skills не перезаписываются; legacy CEOS и
  unmanaged files продолжают блокироваться до записи.
- [x] Pending install блокирует install/sync и preflight READY.
- [x] Добавлены fault-injection и реальный полный 29-Skill fixture на
  disposable HOME; PS7 и PS5.1 CI — отдельные acceptance gates.
- [ ] Реальный HOME backup, установка 27 Skills и повторный preflight — NOT RUN.
- [ ] Skill activation в Codex на пользовательском ПК — NOT RUN.

## Game Production Pipeline G0–G7 (2026-11-18)

**Статус:** implemented as reusable playbook, Codex prompt, example state contract, read-only offline record checker and offline tests. Actual independent Codex end-to-end game creation / platform acceptance: **NOT RUN**. Current game projects are unchanged.

- [x] Описан полный цикл G0–G7, single-brief вход и risk/authority boundaries.
- [x] Привязаны existing Skills и нативные Ludory runtime/art/rights/release stop-lines.
- [x] Добавлены evidence-kind матрица, source/candidate SHA reconciliation, safe file hash checks, stage-order validation и безусловный отказ выдавать platform/publication authority локальному отчёту.
- [x] Добавлены positive/negative offline contract tests и prepared Codex evaluation scenarios.
- [ ] Выполнить реальную автономную Codex активацию и сквозное создание новой игры с browser/runtime/art playtesting и platform-specific release candidate evidence.
- [ ] Пройти внешние реальные платформенные проверки G7 только с отдельным разрешением владельца; локальные симуляции не являются подтверждением.

**Первый пилот:** отдельная новая Studio-игра, без мутации frozen проектов и без изменения фреймворка Ludory ради прохождения gate.

## Game Production critical gameplay Skills (2026-11-18)

**Статус:** added three specialized reusable Skills, references, positive/negative routing evals and a read-only source-bound content-coverage checker. Offline CI and actual Codex/runtime evidence are separate gates.

- [x] gameplay-design: player action/response/feedback loop, state transitions, teaching, edge cases and stable acceptance IDs; game-docs and engine-specific owners remain authoritative.
- [x] gameplay-playtesting: explicit human-session protocol, consent/privacy boundaries, observation versus hypothesis, evidence-backed retest; no fake player feedback.
- [x] game-content-qa: approved baseline versus implementation/package completeness, MUST/OPTIONAL/CUT handling, stale source/evidence protection and external provenance caveats.
- [x] Integration into G0/G1/G2, G3/G5 and G4/G6 of existing game-production pipeline.
- [x] Prepared positive/negative eval matrix and offline structural/unit regression coverage.
- [ ] Real positive/negative Codex activation of all three new Skills — NOT RUN.
- [ ] Run first playable project with actual human playtests and native runtime/build content parity — NOT RUN.

## Порядок ближайшей работы

1. Закрыть текущий CI на финальном SHA после публикации изменений в `main`.
2. При необходимости отдельно воспроизвести protected-main/PR/squash сценарий; он не является доказанным локальным PASS.
3. После закрытия Foundation начать Knowledge по [конкретному плану](KNOWLEDGE_PLAN.md), извлекая только подтверждённые решения и regression evidence.
