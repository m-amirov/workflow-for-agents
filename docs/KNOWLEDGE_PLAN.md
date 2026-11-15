# План этапа Knowledge

Foundation оставляет центральную базу в состоянии, пригодном для безопасного извлечения знаний. Следующий этап не должен копировать исходный код, все README или исторические статусы проектов. Цель — перенести только универсальные решения, алгоритмы, правила и повторяемые практики с точным источником и доказательством.

## Общий протокол извлечения

Для каждого кандидата:

1. Зафиксировать canonical repository, exact commit/PR и чистоту рабочего состояния; dirty checkout не считать доказательством текущего проекта.
2. Найти исходный контракт: код, тест, runbook, receipt, CI run или approved design; старый отчёт без current read-back — только гипотеза.
3. Сформулировать короткое reusable правило, границы применимости, антипример и ожидаемый regression check.
4. Проверить, что материал не содержит секретов, private data, невладельческого контента или необоснованных чисел.
5. Записать entry в `knowledge/` с `source`, `source_sha`, `evidence`, `status` и `reuse_scope`; специализированный Skill создавать только при повторяемом workflow.
6. Запустить validator и релевантные тесты, затем проверить, что проектный AGENTS не конфликтует с центральным правилом.

## Приоритетные кандидаты

| Проект | Что извлекать | Кандидат центрального знания/Skill | Что сначала доказать | Не переносить |
| --- | --- | --- | --- | --- |
| `m-amirov/ludory` | Разделение технических, правовых, визуальных, платформенных и release gates; source-bound assets; hash-bound receipts; preview/apply и `EXECUTED_UNVERIFIED` границы | `knowledge/patterns/evidence-gated-release.md`; позднее специализированный game asset/release Skill | exact source SHA, актуальные tests/CI и неизменённые frozen-game границы на чистом baseline | CEOS history, runtime code, project-specific asset IDs и неподтверждённые art/release PASS |
| `m-amirov/eskizno` | Доказуемые Canvas/Pointer Events/IndexedDB сценарии, mobile/tablet acceptance, сохранение работы и честные ограничения оценки рисунка | `knowledge/patterns/local-first-editor-state.md`; позднее `drawing-editor`/`browser-qa` Skill | current tests + Chromium evidence + physical stylus/device boundary; подтвердить, что данные остаются local-only | UI-копию, уроки целиком, Wordstat/SEO числа, claims о pressure/tilt без устройства |
| `m-amirov/dachametr` | Контракт объяснимых геометрических расчётов: единицы, формулы, границы, округление и независимые expected values; SEO `GO/NO-GO` fail-closed | `knowledge/patterns/explainable-calculator-contract.md`; позднее `calculator-engineering` Skill | чистый repo, `docs/quality-gates.md`, regression tests и подтверждённые research observations | неподтверждённый спрос, нормы, цены, SERP/Wordstat частотности и массовые SEO-страницы |
| `m-amirov/task-playwright-desktop` | Offline deterministic fixtures, task identity/lease, one-click submission fence, independent receipt, distinction local `ok` vs platform acceptance | `knowledge/patterns/independent-receipt-and-no-retry.md`; позднее `browser-automation`/`classification-quality` Skill | exact current source, `npm run gate:source`, sanitized fixtures и отсутствие real submissions | credentials, customer/seller data, production logs, broad automation claims и dormant architecture as current owner |

## Порядок работы

1. **Inventory:** для каждого проекта получить read-only baseline, список applicable AGENTS/skills, exact HEAD и актуальные test/release gates.
2. **Evidence cards:** составить по 2–4 кандидата на проект; каждый кандидат имеет один source contract и один reproducible check.
3. **Cross-project review:** объединить только совпадающие практики (evidence gates, root-cause + regression, fail-closed unknowns, local-vs-platform distinction); конфликтующие правила оставить project-scoped.
4. **Pilot:** добавить максимум по одной записи из двух проектов в `knowledge/`, прогнать validator и project-level checks.
5. **Specialized skills:** создавать только после повторного применения записи минимум в двух независимых сценариях или при чётком bounded workflow.

## Stop-lines

- Dirty/divergent checkout, missing exact source SHA или stale CI → `BLOCKED`, без импорта.
- Источник смешивает планы и фактические результаты → сохранить только проверенную часть.
- Не подтверждён спрос, права, platform receipt или physical-device behavior → `UNKNOWN/BLOCKED`, не `GO/PASS`.
- Нужна массовая миграция project docs/code → остановиться и подготовить отдельный approval-bound work packet.
