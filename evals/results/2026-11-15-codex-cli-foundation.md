# Реальные Codex CLI evals Foundation

Дата: 2026-11-15. Среда: Windows, `codex-cli 0.167.2`, PowerShell 7, Windows PowerShell 5.1. Центральный репозиторий на момент evals: `779e1560376dc3f10e20418fd271b42da376413e`; проверялись Skills без изменений их содержимого.

## Установка и обнаружение

Команды:

```powershell
.\scripts\install.ps1 -Scope user -Skills git-workflow,root-cause-debugging -DryRun
.\scripts\install.ps1 -Scope user -Skills git-workflow,root-cause-debugging
.\scripts\install.ps1 -Scope user -Skills git-workflow,root-cause-debugging
```

Результат: `DryRun` не создал файлов; первая установка создала два каталога и manifest; повторная установка вывела `SKIP` и `No changes`. Существующий пользовательский `verification-before-completion` не изменялся.

Manifest зафиксировал `schema: 1`, `sourceRelative`, SHA-256 каждого файла и content-derived `sourceVersion`. SHA-256 источника и установленных файлов совпали:

| Skill | Source/installed `SKILL.md` SHA-256 |
| --- | --- |
| `git-workflow` | `7efcd727b234fba6a986cb172ef247424645a80785665e2018c53f378766dbff` |
| `root-cause-debugging` | `4779e527088f6a8cf2185c627858f06fc90f021800c21678940b7071d4e03d01` |

Project-scope install/sync и user-scope smoke выполнены отдельным скриптом в свежем временном профиле; обе оболочки вернули `PASS`. Проверены dry-run, idempotency, local edit protection, update/add/remove, collision, unmanaged files, manifest schema/version/hash и сохранность user-owned файла.

## Positive/negative activation

### `git-workflow`

Positive prompt: в disposable repo task-owned `eval/git-workflow` уже содержала проверенный commit; безопасно перенести его в `main`, проверить exact SHA и удалить только полностью интегрированную ветку.

Наблюдаемое доказательство из JSONL Codex:

- Codex прочитал `C:\Users\user\.agents\skills\git-workflow\SKILL.md`.
- Начал с чистого `main`, проверил `status`, `branch -vv`, `worktree`, local `origin` и refs.
- После повторного `git fetch --prune origin` выполнил `git merge --ff-only eval/git-workflow` и `git push origin main` в локальный disposable bare remote.
- Проверил ancestry/diff/SHA, удалил remote-ветку через `git push origin --delete eval/git-workflow` и локальную через `git branch -d eval/git-workflow`.
- Финал: `HEAD`, `main`, `origin/main` = `705277b7babc9f5ce2e134048bd7b15339cdb774`; `git branch -a` оставил только `main` и `origin/main`; CLI exit `0`.

Первый `fetch` получил реальный sandbox `Permission denied` на отсутствующий `.git/FETCH_HEAD`; Codex остановился, локализовал проблему и повторил штатную команду после разрешения записи. Это сохранено как `environment`-ограничение, не скрыто как PASS без проверки.

Negative prompt: теоретически объяснить разницу `git fetch` и `git pull` без изменений. Codex дал текстовый ответ, не выполнил `command_execution`, не изменил refs/файлы и явно указал отсутствие runtime-проверок.

### `root-cause-debugging`

Positive prompt: в disposable Python repo воспроизводится исчезновение сохранённого эскиза после reload; исследовать и исправить.

Наблюдаемое доказательство:

- Codex прочитал установленный `root-cause-debugging` и связанный TDD/verification workflow.
- RED: `test_saved_sketch_survives_reload` падал с `'garden plan' != None`.
- Root cause: `save_sketch()` писал JSON-ключ `sketch`, а `load_sketch()` читал ошибочный `draft`.
- Fix: одна строка в `sketch_store.py`, test `test_sketch_store.py` сохранён как regression guard.
- После fix focused unittest и `unittest discover` через явный Python 3.13 завершились `OK`/exit `0`; `git diff --check` exit `0`.
- Команда `python` внутри Codex sandbox была недоступна, а launcher Python 3.14 получил `Access Denied`; это зафиксировано как tooling gap, не выдано за успешный тест.

Negative prompt: предложить нейтральные варианты заголовка страницы. Codex вернул только варианты текста, не запускал команды, не читал `root-cause-debugging` и явно указал, что диагностика не требовалась.

## Глобальные инструкции

В реальном `C:\Users\user\.codex\AGENTS.md` сохранены исходные пользовательские правила и добавлен отдельный блок main-first. Положительный Git eval подтвердил поведение на доступном локальном сценарии: старт на `main`, перенос task commit в `main`, доказанная очистка только task-owned веток, возврат/финал на `main`.

## Ограничения

- Не запускались protected GitHub `main`, PR/review, squash merge и удаление ветки на реальном GitHub remote.
- Активация остальных восьми Skills из `foundation.json` не запускалась; их структурная валидность проверена отдельно.
- Интеграции Claude/Gemini/других локальных агентов не проверялись.
- Предупреждения Codex о дублированной конфигурации hooks и fallback WebSocket→HTTP относятся к окружению клиента; они не изменяли репозиторий.
