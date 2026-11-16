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

## Антицели

Не запускать оркестрацию нескольких агентов, централизованную БД или сложный индексатор раньше, чем простая файловая библиотека покажет ограничения.

## Порядок ближайшей работы

1. Закрыть текущий CI на финальном SHA после публикации изменений в `main`.
2. При необходимости отдельно воспроизвести protected-main/PR/squash сценарий; он не является доказанным локальным PASS.
3. После закрытия Foundation начать Knowledge по [конкретному плану](KNOWLEDGE_PLAN.md), извлекая только подтверждённые решения и regression evidence.
