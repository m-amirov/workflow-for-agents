# Browser automation — реальные Codex CLI evals

Дата: 2026-11-15. Среда: Windows, PowerShell, `codex-cli 0.167.2`; disposable Git project в `%TEMP%`. Новый Skill устанавливался только в `.agents/skills/browser-automation` этого проекта. Codex запускался с `--sandbox read-only --ephemeral`; production browser, credentials, external URL и side effect не использовались.

## Установка и sync

Источник Skill был изолированным временным copy центрального `skills/automation/browser-automation`, а target — disposable project.

| Проверка | Статус | Наблюдение |
| --- | --- | --- |
| Project install dry-run | PASS | Вывел `INSTALL`; target не создан |
| Install / manifest | PASS | Созданы `SKILL.md` и manifest с `sourceRelative: skills/automation/browser-automation` и SHA-256 `sourceVersion` |
| Repeat install | PASS | `SKIP browser-automation`, `No changes` |
| Sync dry-run после source update | PASS | Вывел `UPDATE`, installed file не изменился |
| Sync update | PASS | Обновил managed `SKILL.md` |
| Local-edit protection | PASS | Sync остановился; marker локальной правки остался в target |

## Real activation

### BA-01 — positive

Prompt требовал спроектировать безопасный submit handler с reload и потенциальным external side effect, но запрещал browser, network, credentials и file mutations.

Codex прочитал установленный `.agents/skills/browser-automation/SKILL.md`, затем `references/lifecycle-and-evidence.md`; в ответе явно назвал `browser-automation`. Он потребовал identity, lease, durable reservation, один effect, `UNKNOWN` при timeout/reload/crash и identity-bound independent receipt. Local execution, receipt и platform acceptance были отдельно обозначены как `DESIGN_ONLY / NOT RUN`, `NOT OBSERVED` и `NOT RUN`. В JSONL не было browser/network action или file modification.

### BA-02 — read-only research

Prompt просил найти официальную документацию Playwright о Locator API и перечислить критерии выбора locator, без изменения файлов, browser automation или side effect. Codex дал только исследовательский ответ. JSONL не содержит `browser-automation`, `command_execution` или tool call. Это подтверждает, что Skill не был выбран для read-only research.

### BA-10 — theoretical question

Prompt просил только теоретически объяснить разницу между `page.locator()` и `page.getByRole()` без запуска браузера или изменения файлов. Codex дал текстовое объяснение; JSONL не содержит `browser-automation` и `command_execution`. Это подтверждает, что Skill не был выбран для обычного теоретического вопроса.

## Synthetic lifecycle evals

[tests/test_browser_automation_contract.py](../../tests/test_browser_automation_contract.py) выполнил BA-03…BA-09 на fake identity, temporary in-memory durable store и deterministic concurrent workers:

- stale task/page/frame callback блокируется до effect;
- restart/timeout после reservation оставляет fence и запрещает retry;
- ошибка durable write блокирует effect;
- только matching receipt освобождает reservation;
- missing/mismatched receipt сохраняет fence;
- два worker выполняют ровно один effect.

Это доказательство поведения тестового контракта и корректного применения Skill, не platform acceptance.

## Ограничения

- Это не real submission и не подтверждение Twork/Klecks или иной внешней платформы.
- Real device/browser navigation и actual durable browser store не запускались.
- Codex transport использовал HTTP fallback после WebSocket warning; eval завершился с exit `0` и не затронул проектные файлы.
