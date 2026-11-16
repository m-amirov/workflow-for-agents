# Codex: точки подключения

## Глобальные инструкции и Skills

- Инструкции пользователя: `~/.codex/AGENTS.md`.
- Инструкции проекта: `AGENTS.md` в корне проекта и возможные инструкции в подпапках.
- Skills пользователя: `~/.agents/skills/<skill-name>/SKILL.md`.
- Skills проекта: `.agents/skills/<skill-name>/SKILL.md`.
- Конфигурация Codex CLI: `~/.codex/config.toml`.

Перепроверять актуальность путей по официальной документации после крупных обновлений Codex.

## Main-first для задач Codex

Только наличие Skill не делает правило постоянным: чтобы оно действовало во всех задачах, перенесите правило из [AGENTS.md](../../AGENTS.md) в применимый глобальный или проектный `AGENTS.md` Codex. Установите [git-workflow](../../skills/development/git-workflow/SKILL.md) отдельно. Если protected `main` требует PR, временная ветка используется до merge и очищается только после доказанной интеграции. Установщик уже работает с выбранными Skills, но **не редактирует глобальный `AGENTS.md` автоматически**. Постоянное правило для других репозиториев требуется добавить в соответствующие инструкции отдельно.

## Установка из клонированного workflow-for-agents

Для глобальных Skills Codex (установка в `~/.agents/skills/`):

```powershell
.\scripts\install.ps1 -Scope user -Skills git-workflow,root-cause-debugging -DryRun
.\scripts\install.ps1 -Scope user -Skills git-workflow,root-cause-debugging
```

Для Stage 8 весь адаптированный набор выбирается явно:

```powershell
.\scripts\install.ps1 -Scope user -Set ceos-migrated -DryRun
.\scripts\install.ps1 -Scope user -Set ceos-migrated
```

Набор содержит 15 Skills из CEOS source SHA
`c8cc13bd3852409be93097ee823e9cd35e512b73`. Он не устанавливает CEOS CLI,
hooks, agents, model routes или глобальные инструкции. При обнаружении старого
CEOS ownership установка возвращает `BLOCKED` с конкретным migration plan и
ничего не перезаписывает.

Для проектной установки:

```powershell
.\scripts\install.ps1 -Scope project -ProjectPath 'C:\work\eskizno' -Skills browser-qa,visual-audit
```

Для известных проектов можно выбрать только профильный набор. Это по-прежнему требует явного вызова и сначала поддерживает dry-run. Profile install/sync обязательно выполняет operational preflight (canonical `origin`, exact `HEAD`/`source_sha`, manifest, local-Skill collision и policy); `BLOCKED` останавливает процесс до записи:

```powershell
.\scripts\profile-preflight.ps1 -Profile eskizno -ProjectPath 'C:\work\eskizno'
.\scripts\install.ps1 -Scope project -ProjectPath 'C:\work\eskizno' -Profile eskizno -DryRun
.\scripts\install.ps1 -Scope project -ProjectPath 'C:\work\eskizno' -Profile eskizno
```

Декларативный Python checker не читает приватный `~/.codex/AGENTS.md` по умолчанию. Его можно явно передать через `--global-agents <path>`; произвольный текст не считается семантически понятным. Он интерпретирует только profile fields, JSON constraints и добровольный marker `workflow-for-agents: git=pr-only|direct-main`, поэтому неизвестные формулировки возвращаются как `UNKNOWN`. Operational preflight не делает семантических выводов из произвольного `AGENTS.md`: он проверяет только безопасные install-boundary facts и не выдаёт Skills за разрешение prototype, merge или release.

## Матрица совместимости

| Проект | Central Skills | Project refinement / stop-line | Результат checker |
| --- | --- | --- | --- |
| [Ludory](../../projects/ludory/) | exploration, regression, release, git, browser QA | Frozen games, asset rights и platform acceptance остаются отдельными gates | `PROJECT_REFINEMENT` / `DUPLICATE` |
| [Eskizno](../../projects/eskizno/) | drawing editor, visual audit, browser QA, regression, debugging | Локальные frontend/curriculum/TDD Skills; Canvas/stylus/IndexedDB требуют отдельных evidence | `PROJECT_REFINEMENT` |
| [Dachametr](../../projects/dachametr/) | exploration, regression, release, visual audit | PR-only; Market Gate BLOCKED и prototype не авторизован | `PROJECT_REFINEMENT`, без authorisation — `REQUIRES_PROJECT_DECISION` |
| [Twork](../../projects/twork/) | browser automation, classification quality, debugging, regression, release | PR-only/exact-head/squash authorization; no real task, Complete или production session | `PROJECT_REFINEMENT`; historical evidence — `STALE_EVIDENCE` |

`HARD_CONFLICT` означает две явно заданные несовместимые команды (например, `direct_main_required` против PR-only). `REQUIRES_PROJECT_DECISION` означает коллизию local Skill, невалидный manifest или отсутствующую авторизацию. Central PASS никогда не закрывает project release gate.

Для обновления из новой версии центрального репозитория:

```powershell
.\scripts\sync.ps1 -Scope user -DryRun
.\scripts\sync.ps1 -Scope user
```

Установщик сохраняет manifest с хешами файлов и версией содержимого Skill. `sync.ps1` отказывается затирать локальные изменения и чужие файлы. Подробности — [скрипты](../../scripts/README.md).

## Постоянная инструкция main-first

Установка папки `git-workflow` сама по себе не гарантирует его вызов на каждой задаче. Содержимое [готового фрагмента](AGENTS.main-first.md) нужно включить в глобальный `~/.codex/AGENTS.md` или проектный `AGENTS.md`, сохранив существующие инструкции. **Этот файл сейчас не меняется установщиком.**

В проекте с защитой `main` выполняйте обычный PR и обязательные проверки; удаление временной ветки — только после подтверждённого merge.

## Проверка

1. Убедиться, что нужные `SKILL.md` реально находятся в целевом каталоге.
2. Запустить Codex и проверить обнаружение навыка.
3. Пройти положительный и отрицательный кейс из `evals/cases/ceos-migrated.json`.
4. Записать версию клиента, точный SHA источника, результат и ограничения.

До реальных проверок не объявлять интеграционную приёмку PASS.

Проверки Stage 8 для CEOS-dependent `ceos-continue`, ImageGen/Web и внешнего
transport остаются `BLOCKED`/`NOT RUN`, если соответствующая capability реально
не доступна. Обычное «продолжи» не должно запускать CEOS recovery.

## Фактическая локальная приёмка 2026-11-15

- `codex-cli 0.167.2` обнаружил и прочитал установленный `git-workflow` из `~/.agents/skills/git-workflow/SKILL.md` в положительном Git-сценарии.
- `root-cause-debugging` был обнаружен и прочитан в положительном bug-сценарии; Codex воспроизвёл RED, назвал причину, внёс минимальный fix и получил GREEN.
- Отрицательные теоретический Git-запрос и стилистический запрос не запускали команды и не читали соответствующий Skill.
- User-scope установлены `git-workflow` и `root-cause-debugging`; SHA исходных и установленных `SKILL.md` совпали, повторная установка дала `SKIP`.
- Глобальный `C:\Users\user\.codex\AGENTS.md` сохранён и дополнен отдельным блоком main-first; исходные пользовательские инструкции не переписывались.
- Полная процедура, команды, временные репозитории и ограничения: [eval report](../../evals/results/2026-11-15-codex-cli-foundation.md).

Эти результаты подтверждают локальную интеграцию с Codex CLI. Они не заменяют проверку защищённого GitHub `main`, PR/review, squash merge или интеграции других агентов.

Документация: https://developers.openai.com/codex/skills и https://developers.openai.com/codex/guides/agents-md
