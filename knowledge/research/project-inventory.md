# Knowledge Stage 1 — инвентаризация проектных источников

Проверено 2026-11-15; уточнено Stage 2 в [evidence report](stage-2-evidence.md). Все источники исследованы только на чтение: remote `main` сначала сверялся через `git ls-remote`, затем изучался в отдельном временном clone. Локальные рабочие копии Ludory, Eskizno и Dachametr не использовались как current evidence: они не совпадают с чистым remote `main`.

Статусы evidence cards: `VERIFIED` — exact SHA, исходник, regression tests и успешный current CI доступны; `LOCAL_TESTED` — exact SHA и указанные команды прошли только в изолированном локальном clone; `PARTIAL` — код/тесты доступны, но часть доказательств отсутствует; `UNKNOWN` — есть план/политика, но отсутствует исполняемая реализация либо доказательство. `LOCAL_TESTED` не означает CI, physical-device или external-platform acceptance.

| Проект | Remote `main` SHA | Архитектура и gates | Current CI evidence |
| --- | --- | --- | --- |
| [Ludory](https://github.com/m-amirov/ludory) | `933c73b195eaf3bfffd12a31ab1cbadb27989eea` | Node 22+ ESM monorepo: Core/Runtime/Connect/Release/Studio; package, rights, browser/art, platform и release gates разделены | [Core checks #877](https://github.com/m-amirov/ludory/actions/runs/43605471895) — success |
| [Eskizno](https://github.com/m-amirov/eskizno) | `7e10b7db7c5b37ab3ed1e004ebf85234bd9faf15` | React/TypeScript/Canvas 2D E1.2; чистая модель документа, history и events; persistence/rendering ещё не реализованы | GitHub Actions API: 0 запусков на exact SHA; selected unit tests и typecheck прошли локально, см. Stage 2 evidence |
| [Dachametr](https://github.com/m-amirov/dachametr) | `c474c916095651aaa95079193a05af8f0d51558c` | docs-first калькулятор; Gate 1 market `BLOCKED`, prototype не авторизован; Python validators и независимые numerical fixtures | [Skills and docs quality #27](https://github.com/m-amirov/dachametr/actions/runs/43483153567) — success |
| [Twork](https://github.com/m-amirov/task-playwright-desktop) | `196f99b4583555ee1b0b170115d6c613e77ce705` | Node/Electron/Playwright; lease, submission fence, offline replay и algorithm lock; локальная автоматизация не равна platform acceptance | Авторизованный GitHub Actions API: 0 запусков на exact SHA; selected offline tests, syntax и algorithm lock прошли локально, см. Stage 2 evidence |

## Ludory

`AGENTS.md` сохраняет Core platform-neutral, замораживает старые игры, требует Node 22+ и запрещает превращать отсутствующее browser/device/platform evidence в PASS. Локальные Skills разделяют audit, asset rights, incident analysis, production art и visual QA. CI запускает `npm test`, `npm run check` и `examples/core-session.mjs`; отдельный browser workflow остаётся отдельным доказательством.

| Card | Подход и проблема | Механизм и доказательства | Reuse / regression check | Статус |
| --- | --- | --- | --- | --- |
| LUD-01 | Независимая проверка итогового archive вместо доверия сборщику | `archive.mjs` читает ZIP bytes, ограничивает paths/size/files, сверяет CRC/SHA и allowlist; `archive.test.mjs` покрывает truncation, collision, SDK и notice pairs; exact CI success | Пакетирование любого конечного файла; fixtures с traversal, duplicate и byte mutation | VERIFIED |
| LUD-02 | Пара redistributable font и notice не должна теряться при export | `font-notices.mjs`, exporter и tests требуют парность источника/архива; commit history `55d49fc` и `933c73b` показывает реальные регрессии CSS/TTF/notices | Только для лицензируемых пар с явным контрактом; проверять missing/extra notice | VERIFIED |
| LUD-03 | Browser smoke не заменяет platform/rights acceptance | `AGENTS.md`, release evidence и `runtime-browser.yml` разделяют локальный browser contract, art, rights и release gates | Общий evidence model; для current browser job нужен отдельный run/артефакт | PARTIAL |
| LUD-04 | Замороженный legacy game не должен быть неявной целью migration | Политика и Studio boundaries есть в `AGENTS.md`, но Stage 1 не наблюдал migration regression test на exact SHA | Project-scoped migration policy, не общий pattern | PARTIAL |

Ключевой переносимый вывод: сильнее всего подтверждён не конкретный формат ZIP, а разделение byte-level package evidence и независимых release gates. Он перенесён в [pattern](../patterns/evidence-gated-artifact-acceptance.md).

## Eskizno

`AGENTS.md` задаёт stylus-first Canvas 2D, честные ограничения автоматической оценки рисунка и local-only по умолчанию. Локальные Skills охватывают frontend, curriculum, SEO, TDD и verification. Current `apps/web` содержит E1.1 shell и E1.2 document model; `persistence.ts`, renderer и реальная stylus/device acceptance пока отсутствуют. CI workflow на remote SHA не найден, поэтому committed tests не считаются исполненными в этой инвентаризации.

| Card | Подход и проблема | Механизм и доказательства | Reuse / regression check | Статус |
| --- | --- | --- | --- | --- |
| ESK-01 | Не давать слою/документу изменяться от невалидной операции | `model.ts` использует pure `applyAction`; `model.test.ts` прошёл на exact SHA: locked layer, limits, invalid id и immutable result | Редакторы с пользовательскими документами; проверять no-op на invalid/locked action | LOCAL_TESTED |
| ESK-02 | История должна восстанавливать реальное состояние, а новый action очищает redo | `history.ts` и `history.test.ts` прошли на exact SHA; snapshots ограничены 80 | Редакторы, формы, графы; проверить undo/redo после каждого типа semantic action | LOCAL_TESTED |
| ESK-03 | `pointercancel` не является завершённым пользовательским действием | `events.ts` и `events.test.ts` прошли на exact SHA; `strokeCommitted` создаётся только для фактического изменения, cancel/undo подавлены | Pointer UI и учебная аналитика; проверить cancel, stale action и undo | LOCAL_TESTED |
| ESK-04 | Local-only IndexedDB persistence и asset migration | Описаны в E1 plan, но `persistence.ts` и тестов на неё в current source нет | Не переносить до реализации и device/browser proof | UNKNOWN |

Текущая модель и tests локально подтверждены, но не выбраны для нового pilot: нет CI на exact SHA и отсутствует подтверждение persistence/device behavior.

## Dachametr

`AGENTS.md` отделяет Gate 1 market, prototype authorization, formula, browser/device, SEO и production gates. Локальные Skills уже разделяют calculator engineering, research data integrity, visual QA и release readiness. Current `main` — документация и validators, не работающее приложение: это важно для границ каждого вывода.

| Card | Подход и проблема | Механизм и доказательства | Reuse / regression check | Статус |
| --- | --- | --- | --- | --- |
| DAC-01 | Не превращать unknown Wordstat/SERP data в нули и не повышать gate без provenance | `validate_research.py` требует source/date/period, strict UTF-8, связь с observation layer; tests покрывают missing provenance, false GO, U+FFFD и mismatched values; exact CI success | Исследования/аналитика; corrupt encoding, absent source, fake GO и unknown value должны fail | VERIFIED |
| DAC-02 | Будущий калькулятор должен иметь независимые decimal expected values | `test_prototype_spec.py` и 1,757-line fixture проверяют units, group-before-ceil, bounds, overflow и invalid zone | Только как specification contract; будущая app обязана отдельно реализовать и пройти browser/code gates | VERIFIED |
| DAC-03 | Ошибка одной зоны не должна давать частичный BOM как готовый результат | `plot-zones-materials-v0.md` и fixtures задают fail-closed rule, но production calculator отсутствует | Calculator UI после реализации; не считать spec проверкой приложения | PARTIAL |

Перенесён DAC-01: он не дублирует общий release-verification, потому что задаёт исполнимый контракт для наблюдений и неизвестных числовых состояний. См. [pattern](../patterns/fail-closed-research-provenance.md).

## Twork

`AGENTS.md` трактует task text, DOM, логи и seller pages как недоверенные данные. Он требует offline fixtures, reservation до Complete, один click при неизвестном исходе, независимый receipt для снятия fence и разделение local `ok`/platform correctness. Локальные Skills: log audit, Playwright regression и safe release. `TaskRunCoordinatorV2` прямо отмечен dormant; owner production handlers не следует выводить из него.

| Card | Подход и проблема | Механизм и доказательства | Reuse / regression check | Статус |
| --- | --- | --- | --- | --- |
| TWR-01 | Не повторять потенциально дошедший внешний side effect | `NativeSubmissionFence` atomically persists reservation до click; `attemptNativeSubmission` после click только наблюдает; offline tests прошли для restart, timeout, write failure и independent departure | Внешние submit/delete/payment-like actions; проверить crash before receipt и duplicate retry | LOCAL_TESTED |
| TWR-02 | Не оценивать prediction его собственным логом | offline `replay-harness.js` принимает только verified manual/expert/platform label, rejects duplicate IDs и anonymizes report; tests прошли для ungraded, changed labels и regressions | Любая classifier/LLM quality evaluation; require independent label and fail on corpus/label mismatch | LOCAL_TESTED |
| TWR-03 | Async callbacks не должны действовать на новый task | `TaskRunLease` связывает frame/page/signature/deadline; stale/expired run becomes non-current; offline lease tests прошли | Browser automation; проверить replacement frame, navigation, timeout и cancellation | LOCAL_TESTED |
| TWR-04 | Классификационные исправления должны иметь positive и negative regression cases | `robot-call-classification-v2.test.js` и decision tests прошли с fake VM/model responses и positive/negative cases | Не переносить конкретные taxonomy rules и user data | LOCAL_TESTED |

TWR-01 и TWR-02 — сильные будущие patterns/Skills, но не переносятся как `VERIFIED`: current CI receipt отсутствует, а local offline success не доказывает platform acceptance.

## Общие закономерности и границы

| Универсальный подход | Наблюдение | Граница |
| --- | --- | --- |
| Root cause + regression coverage | Каждый зрелый источник связывает исправление с конкретным test/fixture; Dachametr фиксирует U+FFFD root cause, Ludory/Twork — archive/submission regressions | Название коммита само по себе не доказательство; нужен current source и check |
| Evidence-based verification | Ludory и Dachametr отделяют mechanical checks от rights/platform/market decision | Локальный success не подтверждает внешний сервис, legal status или user outcome |
| Fail-closed unknown | Dachametr сохраняет unknown отдельно от zero; Twork оставляет unknown submission fenced | Не превращать absence of evidence в отрицательное или положительное утверждение |
| Защита пользовательских данных | Eskizno блокирует invalid/locked actions; Twork durable reservation предотвращает duplicate side effect | Persistence/device claims Eskizno ещё не доказаны |
| Воспроизводимость | Exact SHA, committed fixtures, deterministic validators и pinned CI jobs | Private raw data и authenticated external observations могут остаться evidence-only |
| UI evidence | Eskizno/Dachametr требуют browser/device proof, Ludory держит browser evidence отдельно | DOM/build/emulation не равны physical device или art/platform acceptance |

Проектно-специфичными остаются Ludory font allowlists, Eskizno уроки и Canvas UX, Dachametr Wordstat/расчётные нормы, Twork selectors/taxonomy и любые реальные task данные.

## Выбор pilot и отклонённые кандидаты

Выбраны два independent patterns из разных проектов: Ludory LUD-01 и Dachametr DAC-01. Для обоих доступны exact source SHA, source/tests и успешный GitHub Actions run именно на этом SHA. Они применимы вне исходного домена и не создают нового Skill: это короткие правила выбора/проверки, а не самостоятельный workflow.

Не выбраны Eskizno ESK-01–03 и Twork TWR-01–04: их исходники и regression tests существуют, но Stage 1 не получил current CI evidence; ESK-04 и DAC-03 имеют только план/specification, а не подтверждённую реализацию. Ludory LUD-02 полезен, но слишком близок к LUD-01 и частично product-specific.

## Кандидаты специализированных Skills

| Приоритет | Кандидат | Назначение и trigger | Источники / инструменты | Проверка и основание |
| --- | --- | --- | --- | --- |
| 1 | `browser-automation` | Изменение handler, navigation, retry, lease или external side effect | Twork TWR-01/TWR-03; Playwright, offline fixtures, Node tests | Fence/receipt/lease regressions; отдельный Skill оправдан узким safety workflow |
| 2 | `classification-quality` | Изменение классификатора, prompt/правил или quality threshold | Twork TWR-02/TWR-04; offline replay, anonymized reviewed corpus | Independent labels, baseline comparison, no raw customer data |
| 3 | `seo-calculators` | Market research или calculator formula/UI/release decision | Dachametr DAC-01–03; Python fixtures, browser and physical-device evidence | Provenance + decimal/golden cases + separate gates; объединяет повторяемую связку |
| 4 | `drawing-editor` | Canvas/Pointer/history/persistence implementation | Eskizno ESK-01–04; Vitest, Playwright, real stylus/device | Нужны completed persistence/rendering и device acceptance до реализации Skill |
| 5 | `game-visual-integrity` | Export game assets, visual/release proof или rights boundary | Ludory LUD-01–03; archive verifier, hashes, browser capture | Separate package/rights/art/platform receipts; нужен второй independent game example |
| 6 | `document-extraction` | PDF/document capture или structured extraction | Twork history includes PDF capture/recovery, но Stage 1 не изучал source contract достаточно глубоко | Отложен до sanitized fixtures и independent quality receipt |

Следующий этап Knowledge: получить или воспроизвести current safe CI evidence для Twork и Eskizno, затем провести вторую независимую повторную применимость pilot patterns. Только после этого решать, какой из Skill-кандидатов реализовывать первым.
