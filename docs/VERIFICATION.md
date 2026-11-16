# Проверки Foundation: факты и ограничения

## Проверенная версия и среда

- **Дата:** 2026-11-15.
- **Исходный baseline до этой приёмки:** `779e1560376dc3f10e20418fd271b42da376413e`.
- **Codex CLI:** `0.167.2`, Windows, PowerShell 7/Windows PowerShell 5.1.
- **Реальные Codex evals:** [eval report](../evals/results/2026-11-15-codex-cli-foundation.md).
- **Проверенный code/evidence commit:** `02ea837c1137c0e5a0bd7a9b6926b2d59e6d5160`.
- **GitHub Actions:** [run #43720151759](https://github.com/m-amirov/workflow-for-agents/actions/runs/43720151759).
- **Результат:** SUCCESS; Python и обе Windows smoke jobs завершились успешно.

## Что реально выполнено

| Gate | Среда | Статус | Доказательство |
| --- | --- | --- | --- |
| Skill frontmatter, имена, каталог, локальные ссылки и структура eval cases | Python 3.11, Ubuntu | PASS | `Validate Skills / Python` |
| Регрессионные тесты валидатора | Python 3.11, Ubuntu | PASS | `Run validator regressions` |
| Project-scope install/sync: dry-run, manifest fingerprint, idempotency, local edits, add/update/remove, unmanaged files, collisions | PowerShell 7, Windows | PASS | `Smoke test ... (PowerShell 7)` |
| То же на Windows PowerShell 5.1 | Windows PowerShell 5.1 | PASS | `Smoke test ... (Windows PowerShell 5.1)` |
| User-scope installation/sync в `~/.agents/skills` | Реальный профиль + временный профиль | PASS | install/sync CLI и smoke |
| Manifest schema, source path, content version и target/source SHA | PowerShell 7/5.1 | PASS | regression assertions в `Smoke.ps1` |
| Положительный/отрицательный `git-workflow` activation | Реальный Codex CLI, временный Git repo | PASS | Fast-forward в `main`, SHA, удаление только task-owned веток; теория не меняла repo |
| Положительный/отрицательный `root-cause-debugging` activation | Реальный Codex CLI, временный Python repo | PASS | RED/GREEN с root cause `sketch`/`draft`; стилистический запрос не запускал диагностику |
| Глобальный main-first блок | Реальный `C:\Users\user\.codex\AGENTS.md` + Codex CLI | PASS в доступном локальном сценарии | Codex начал с `main`, перенёс task commit и безопасно очистил ветки |

## Аудит десяти Skills и интеграционных файлов

- `python scripts/validate.py` на текущем worktree: `Validated 10 skill(s), 33 internal link(s); 0 error(s)`.
- Все десять `SKILL.md` имеют frontmatter `name`/`description`, имя совпадает с каталогом и соответствует lowercase kebab-case; все десять покрыты positive/negative кейсом в `foundation.json`.
- Внутренние Markdown-ссылки разрешаются внутри репозитория; Skills не содержат исполняемых ресурсов или новых зависимостей, требующих отдельного runtime gate.
- Триггеры вручную сопоставлены с телами Skills. Пересечения `task-planning`/`codebase-exploration`/`minimal-change` и `root-cause-debugging`/`regression-testing` являются составными workflows, а не противоречиями; для нерелевантных запросов проверены два отрицательных Codex-кейса.
- `AGENTS.md`, `rules/`, `playbooks/`, `integrations/codex/` и `evals/` согласованы по main-first, evidence-before-claims и fail-closed статусам; старый CI evidence не перенесён на новый SHA.

## Что ещё не выполнено

- **NOT RUN:** защищённый GitHub `main`, обязательный PR/review, squash merge и удаление ветки на реальном GitHub remote.
- **NOT RUN:** проверка обновления при параллельном изменении файлов в момент копирования и восстановления после аварийного отключения. Скрипты не обеспечивают транзакцию всей операции.
- **NOT RUN:** интеграции с Claude/Gemini/локальными моделями.

## Вывод

**Foundation закрыт по доступным локальным release gates:** структура, install/sync, manifest integrity, реальная активация двух Skills и локальный main-first сценарий имеют наблюдаемое доказательство. Protected-main/PR/squash остаётся отдельным `NOT RUN`, а не выдуманным `PASS`.

Run #43720151759 относится к exact code/evidence commit выше; последующий документационный commit не меняет проверенные Skills и установщик. Старые GitHub Actions runs не считаются доказательством нового кода.

## Stage 8 — CEOS Skills migration (2026-11-16)

Источник: `codex-engineering-system` SHA
`c8cc13bd3852409be93097ee823e9cd35e512b73`; target baseline до изменений:
`bc34773d6e2a504949b06918e5ae4168ccfffd13`.

| Gate | Среда | Статус | Доказательство |
| --- | --- | --- | --- |
| 15 source-bound Skill files, trigger metadata and migration matrix | Python/static | PASS | `tests/test_stage8_migration.py`, migration report |
| Validator including 15 positive/negative eval cases | Python 3.13 local | PASS | `python scripts/validate.py` |
| Full Python unittest suite | Python 3.13 local | PASS (69/69) | `python -m unittest discover -s tests -v` |
| User/project install, SHA manifest, idempotency, local-edit protection and legacy collision | PowerShell 7, disposable HOME | PASS | `scripts/tests/Smoke.ps1` |
| То же | Windows PowerShell 5.1, disposable HOME | PASS | `scripts/tests/Smoke.ps1` |
| Codex CLI activation matrix | `codex-cli 0.167.2` | `BLOCKED_EXTERNAL` | WebSocket/HTTP 403; bounded probe in [Stage 8 eval report](../evals/results/2026-11-16-stage-8-ceos-skills-codex-cli.md) |
| Real user HOME migration / CEOS ownership replacement | User profile | `NOT RUN` | Requires separate explicit approval; no real settings changed |

Stage 8 is therefore not a full end-to-end activation PASS until the external
Codex transport and fresh isolated CLI evaluation are available.
