# Проверки Foundation: факты и ограничения

## Проверенная версия и среда

- **Дата:** 2026-11-15.
- **Исходный baseline до этой приёмки:** `779e1560376dc3f10e20418fd271b42da376413e`.
- **Codex CLI:** `0.167.2`, Windows, PowerShell 7/Windows PowerShell 5.1.
- **Реальные Codex evals:** [eval report](../evals/results/2026-11-15-codex-cli-foundation.md).
- **Финальный SHA и CI run:** добавляются после commit/push этого изменения; старый run не переносится на новый SHA.

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

После commit/push нужно заменить pending-строку выше ссылкой на CI run, относящийся к точному новому SHA. Старые GitHub Actions runs не считаются доказательством нового кода.
