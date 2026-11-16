# Установка, обновление и проверка Skills

**Статус:** скрипты существуют и проверяются в GitHub Actions. Не путать Windows smoke-тест с проверкой фактической активации Skills в Codex.

## Требования

- PowerShell 7 или Windows PowerShell 5.1; Windows smoke-тесты находятся в `scripts/tests/Smoke.ps1`.
- Клонированная локальная копия workflow-for-agents.
- Для user scope — доступ на запись в `~/.agents/skills/`; для project scope — доступ в выбранный проект.
- Python 3.11+ требуется **только** для валидатора и Python-тестов.

## Установка

Из корня клонированного репозитория:

```powershell
.\scripts\install.ps1 -Scope user -Skills git-workflow,root-cause-debugging -DryRun
.\scripts\install.ps1 -Scope user -Skills git-workflow,root-cause-debugging
```

Для Stage 8 можно явно выбрать весь source-bound набор из 15 адаптированных
Skills. Сначала выполняйте dry-run:

```powershell
.\scripts\install.ps1 -Scope user -Set ceos-migrated -DryRun
.\scripts\install.ps1 -Scope user -Set ceos-migrated
.\scripts\sync.ps1 -Scope user -Set ceos-migrated -DryRun
.\scripts\sync.ps1 -Scope user -Set ceos-migrated
```

`-Set ceos-migrated` не устанавливает CEOS CLI, hooks, agents или глобальный
`AGENTS.md`. Если в `~/.codex/ceos/installation.json` обнаружен старый CEOS
owner для выбранного имени, команда останавливается до записи и печатает путь,
конфликт и migration plan. `-Force` отсутствует намеренно: unmanaged и
CEOS-managed файлы не перезаписываются.

Для disposable HOME в smoke/regression тестах используйте только явный
`-HomePath <temp-directory>`; без него user scope остаётся обычным `~/.agents/skills/`.

Проектная установка:

```powershell
.\scripts\install.ps1 -Scope project -ProjectPath 'C:\work\eskizno' -Skills browser-qa,visual-audit
```

Либо явно выбрать минимальный набор из проверенного профиля (не устанавливает все Skills):

```powershell
.\scripts\install.ps1 -Scope project -ProjectPath 'C:\work\eskizno' -Profile eskizno -DryRun
.\scripts\install.ps1 -Scope project -ProjectPath 'C:\work\eskizno' -Profile eskizno
.\scripts\sync.ps1 -Scope project -ProjectPath 'C:\work\eskizno' -Profile eskizno -DryRun
```

`-Profile` доступен только в project scope и нельзя совмещать с `-Skills`/`-All`. Перед **каждой** profile-install и profile-sync установщик выполняет read-only preflight: проверяет Git checkout и `origin`, exact `HEAD` против `source_sha`, целостность manifest, защищённые local Skills, коллизии имён и декларативное Git-policy уточнение. Несовпавший remote, stale SHA, отсутствующий Git checkout, повреждённый manifest или неменеджируемая коллизия дают `BLOCKED` **до записи файлов**. `-DryRun` выполняет тот же preflight, но не записывает Skills.

Для отдельной диагностики и проверки operation boundary используйте PowerShell-обёртку; `skill-install` не авторизует prototype, merge или release:

```powershell
.\scripts\profile-preflight.ps1 -Profile eskizno -ProjectPath 'C:\work\eskizno'
.\scripts\profile-preflight.ps1 -Profile dachametr -ProjectPath 'C:\work\dachametr' -Operation prototype
```

Python checker `scripts/project_profiles.py check` остаётся декларативной диагностикой для profile/AGENTS constraints; он не является заменой operational preflight установщика. Установщик по-прежнему не редактирует `AGENTS.md` и не заменяет local Skills.

`-All` устанавливает все реализованные Skills; по умолчанию нужно указать `-Skills` или `-All`, чтобы избежать случайной массовой установки.

Установщик:
- записывает навыки в **плоский** каталог `<destination>/<name>/SKILL.md`;
- создаёт `.workflow-for-agents.manifest.json` с именами, sourceRelative, версиями содержимого и SHA-256 отслеживаемых файлов;
- проверяет при чтении manifest схему, безопасные sourceRelative, наличие файлов и соответствие `sourceVersion` фактическим SHA-256; при несовпадении останавливается до записи;
- при повторной установке идентичного Skill не изменяет его;
- не перезаписывает существующий неменеджируемый каталог;
- отказывается продолжать, если управляемый Skill изменён локально или требует синхронизации.
- named set `ceos-migrated` выбирает ровно 15 Skills, перенесённых из CEOS на source SHA `c8cc13bd3852409be93097ee823e9cd35e512b73`;
- legacy CEOS manifest проверяется read-only и не удаляет backup, hooks, CLI или старый ownership.

**Версия** — детерминированный SHA-256 fingerprint списка путей/хешей Skill, а не commit SHA Git. Источник берётся из текущих локальных файлов.

## Синхронизация

После обновления локальной копии центрального репозитория:

```powershell
.\scripts\sync.ps1 -Scope user -DryRun
.\scripts\sync.ps1 -Scope user
```

Можно указать `-Skills git-workflow` для выборочного обновления или `-Scope project -ProjectPath 'C:\work\eskizno'`. Если `-Skills` отсутствует, синхронизируются все зарегистрированные навыки.

Механизм:
- сравнивает сохранённые SHA-256, файлы в целевом каталоге и текущий источник;
- обновляет, добавляет и удаляет только **отслеживаемые** файлы;
- сохраняет сторонние файлы без конфликтов;
- при локальном изменении/удалении управляемого файла или коллизии нового исходного файла с локальным **останавливается до записи**;
- выполняет `-DryRun` без изменения файлов.

**Ограничение:** запись набора файлов пока не является транзакцией на уровне всей файловой системы. В случае аварийного прерывания проверить файлы и манифест, не применять принудительное обновление.

## Валидация

```powershell
python scripts/validate.py
python -m unittest discover -s tests -v
.\scripts\tests\Smoke.ps1
```

Проверяются имена, frontmatter, каталог, локальные ссылки и структура eval-кейсов. Тесты установки/sync используют временные проектные каталоги и проверяют конфликтные ситуации. `foundation.yml` запускает Python на Ubuntu и smoke-тесты на Windows PowerShell 7 и 5.1.

Smoke запускается в disposable HOME и проверяет user/project scope, 15-entry
set, manifest SHA-256, idempotency, локальные изменения, безопасный sync и
collision со старым CEOS-managed Skill. Реальные пользовательские настройки
автоматическими тестами не изменяются.

## Ограничения интеграции

Скрипты не редактируют `AGENTS.md` пользователя или проектов. Чтобы Codex соблюдал `main-first` всегда, инструкцию нужно добавить отдельно: [интеграция Codex](../integrations/codex/README.md).

Реальная активация навыков в Codex и пользовательская установка на рабочей машине — отдельные acceptance gates.
