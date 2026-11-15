# Knowledge Stage 2 — воспроизводимые evidence и независимое применение patterns

Проверено 2026-11-15 в Windows / PowerShell, без изменений исходных репозиториев. Для каждого source SHA создан чистый detached clone в `%TEMP%\workflow-for-agents-knowledge-stage2-20261115`; проверки выполнялись только в нём. Среда: Node `v22.21.0`, npm `10.9.4`, Python `3.13.5`.

## Легенда evidence

- `SOURCE_REVIEWED` — exact SHA, исходный контракт и тесты прочитаны.
- `LOCAL_TESTED` — названная команда прошла в изолированном clone на exact SHA.
- `CI_VERIFIED` — есть успешный GitHub Actions run именно на source SHA.
- `NOT_RUN` — соответствующая проверка не выполнялась; это не отрицательный результат.

`LOCAL_TESTED` не означает подтверждение GitHub CI, настоящего стилуса, browser production session, внешней платформы, прав или release decision.

## Eskizno

| Поле | Факт |
| --- | --- |
| Repository / exact source SHA | `m-amirov/eskizno` / `7e10b7db7c5b37ab3ed1e004ebf85234bd9faf15` |
| Current remote | `git ls-remote` вернул тот же `HEAD` и `refs/heads/main` |
| Source / CI verification | `SOURCE_REVIEWED` / `NOT_RUN`: авторизованный `gh api repos/m-amirov/eskizno/actions/runs?head_sha=…` вернул `total_count: 0` |
| Dependency step | `npm ci --ignore-scripts --no-audit --no-fund` — PASS; npm выдал `EBADENGINE` для `jsdom@31.0.0`, так как текущий Node `22.21.0` ниже его `22.22.2` minimum |
| Offline checks | `npm run test:unit -- src/editor/model.test.ts src/editor/history.test.ts src/editor/events.test.ts` — PASS, 3 files / 25 tests; `npm run typecheck` — PASS |

Подтверждены только ESK-01/02/03: immutable/no-op защита модели, history с очисткой redo и подавление `pointercancel`. Статус этих cards повышен до `LOCAL_TESTED` в [inventory](project-inventory.md). Проверки не доказывают real Pointer Events на устройстве, pressure/tilt, IndexedDB persistence или browser e2e; ESK-04 остаётся `UNKNOWN`.

## Twork

| Поле | Факт |
| --- | --- |
| Repository / exact source SHA | `m-amirov/task-playwright-desktop` / `196f99b4583555ee1b0b170115d6c613e77ce705` |
| Current remote | `git ls-remote` вернул тот же `HEAD` и `refs/heads/main` |
| Source / CI verification | `SOURCE_REVIEWED` / `NOT_RUN`: авторизованный `gh api repos/m-amirov/task-playwright-desktop/actions/runs?head_sha=…` вернул `total_count: 0` |
| Safety review | `package.json`, `AGENTS.md`, targeted sources/tests и `scripts/check.mjs` прочитаны до запуска; tests используют fake DOM/VM, synthetic data и temporary files, без `start`, Electron, Playwright browser, production URL, credentials или реальных submit |
| Dependency step | `npm ci --ignore-scripts --no-audit --no-fund` — PASS; npm показал только deprecation warnings transitive packages |
| Offline tests | `node --test tests/auto-submit-fence-0.4.171.test.js tests/nitro-task-run-lease.test.js tests/nitro-submission-receipt.test.js tests/native-submission-confirmation.test.js tests/replay-harness-0.4.172.test.js tests/replay-baseline.test.js tests/robot-call-classification-v2.test.js tests/robot-call-classification-decision.test.js` — PASS, 73 tests |
| Static/source gate subset | `npm run check` — PASS: `Syntax OK: 450 files`; `Algorithm Lock 1.6.108: PASS (38 files)` |

Повышены до `LOCAL_TESTED` TWR-01 (fence/no retry), TWR-02 (independent labels/replay), TWR-03 (task lease) и TWR-04 (positive/negative classification regressions). Это не подтверждает реальное нажатие Complete, принятие ответа Twork/Klecks или platform quality; ни `npm test`, ни `npm run gate:source` не запускались, потому что необходима была только безопасная targeted offline выборка, а их `pretest` выполняет дополнительный cleanup.

## Независимое повторное применение patterns

Команда: `python -m unittest discover -s tests -p test_knowledge_pattern_reuse.py -v`.

| Pattern | Новый независимый сценарий | Результат | Boundary |
| --- | --- | --- | --- |
| [Evidence-gated artifact acceptance](../patterns/evidence-gated-artifact-acceptance.md) | Новый in-memory ZIP с `manifest.json` и `payload.txt`; receipt SHA/member SHA; отдельные fixtures с изменённым payload, extra file, `../` и case-collision | `LOCAL_TESTED`, 3 tests PASS | Механическая целостность не переводит rights из `BLOCKED` и external release из `NOT_RUN` |
| [Fail-closed research provenance](../patterns/fail-closed-research-provenance.md) | Абстрактные analytic signals с measured/unknown status, provenance и proposed gate | `LOCAL_TESTED`, 2 tests PASS | Нет внешнего исследования: fixture доказывает только обработку unknown/source/gate contract |

Fixtures находятся в [tests/test_knowledge_pattern_reuse.py](../../tests/test_knowledge_pattern_reuse.py); они не используют исходный код или fixtures Ludory/Dachametr.

## Статусы patterns

Обе existing entries остаются `VERIFIED`, но теперь их YAML явно разделяет: `source_verification: SOURCE_REVIEWED`, `ci_verification: CI_VERIFIED`, `cross_project_verification: LOCAL_TESTED`. Валидатор требует эти три поля и отвергает неизвестный evidence status; regression test добавлен в [tests/test_validate.py](../../tests/test_validate.py).

## Первый специализированный Skill: `browser-automation`

Выбран для следующего implementation packet, но **не реализован в Stage 2**. Это не общий Skill для Playwright/visual QA: он закрывает только stateful automation с потенциальным внешним side effect.

| Критерий | `browser-automation` | Альтернативы |
| --- | --- | --- |
| Evidence | TWR-01/03 `LOCAL_TESTED`; offline tests прямо проверяют fence, lease, restart, receipt и unknown outcome | `classification-quality` имеет хорошие offline fixtures, но пока один project/domain; `drawing-editor` не имеет device/persistence proof; `seo-calculators` пока docs/spec; `game-visual-integrity` нуждается во втором game scenario; `document-extraction` не имеет достаточного source contract |
| Повторяемость и риск | Submit/delete/payment-like actions и navigation races повторяются во многих browser automations; ошибочный retry опасен | Остальные либо более project-specific, либо не имеют достаточного independent evidence |
| Автоматическая проверка | Fake DOM/page, deterministic clock, temporary durable storage и receipt fixtures позволяют positive/negative evals без live accounts | Не требуется production browser session |
| Дублирование | Узкий safety lifecycle дополняет базовые `browser-qa`, `regression-testing` и `root-cause-debugging`, не заменяя их | Общий «как управлять браузером» Skill был бы дублированием |

### Технический контракт будущей реализации

- **Trigger:** реализация/изменение browser handler, task identity, navigation/reload recovery, retry logic или внешнего side effect.
- **Не trigger:** read-only browser research, visual audit, обычный unit refactor без browser state и теоретический вопрос о Playwright.
- **Входы:** exact task/page identity, allowed side effect, durable store path, independent receipt definition, cancellation/timeout semantics.
- **Алгоритм:** (1) inspect handler and source of task identity; (2) define fake/offline reproduction before code; (3) acquire lease and atomically persist reservation before effect; (4) perform at most one effect; (5) treat timeout/error as unknown, never auto-retry; (6) clear fence only on independently observed departure/receipt; (7) report local execution, receipt and platform acceptance as separate statuses.
- **Acceptance criteria:** positive fixture proves one effect and valid receipt release; negative fixtures prove stale identity, restart, timeout, write failure, ambiguous UI and duplicate retry are blocked; all tests use sanitized/offline data; no PASS claim for external platform without its own receipt.
- **Planned evals:** trigger/non-trigger selection, one-click fence, stale lease, receipt mismatch, unknown outcome, no live session policy.
- **Stop-lines:** credentials, production page/session, raw task/customer data, missing durable store semantics or undefined receipt require a project-specific decision; the Skill must not initiate real submissions.

## Remaining evidence gaps

- Successful CI runs at exact Eskizno and Twork SHAs are absent (`0` Actions runs), so `CI_VERIFIED` is unavailable for their cards.
- Eskizno real stylus/browser/IndexedDB behaviour and Twork external platform receipt/answer quality were intentionally not tested.
- No new project-specific pattern is imported from Eskizno/Twork until it has source, CI or a sufficiently independent evidence chain matching its claim.
