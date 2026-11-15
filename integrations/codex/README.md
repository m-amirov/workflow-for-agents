# Codex: точки подключения

## Глобальные инструкции и Skills

- Инструкции пользователя: `~/.codex/AGENTS.md`.
- Инструкции проекта: `AGENTS.md` в корне проекта и возможные инструкции в подпапках.
- Skills пользователя: `~/.agents/skills/<skill-name>/SKILL.md`.
- Skills проекта: `.agents/skills/<skill-name>/SKILL.md`.
- Конфигурация Codex CLI: `~/.codex/config.toml`.

Перепроверять актуальность путей по официальной документации после крупных обновлений Codex.

## Как подключать вручную до появления install.ps1

1. Клонировать этот центральный репозиторий.
2. Выбрать только нужные папки навыков.
3. Скопировать **содержимое папки конкретного Skill** в `~/.agents/skills/<skill-name>/` либо в `.agents/skills/<skill-name>/` нужного проекта. Не копировать весь `skills/` целиком: здесь есть группировка по категориям.
4. В проектном `AGENTS.md` добавить только небольшие проектные ограничения; не вставлять весь центральный план.
5. На тестовом запросе проверить, что Codex обнаруживает навык и использует его. Записать факт проверки, версию исходника и scope.

Windows PowerShell пример для одного локально клонированного навыка:

    $src = ".\skills\development\root-cause-debugging"
    $dst = Join-Path $HOME ".agents\skills\root-cause-debugging"
    if (Test-Path $dst) { throw "Папка уже существует; сравните изменения перед копированием" }
    New-Item -ItemType Directory -Path (Split-Path $dst -Parent) -Force | Out-Null
    Copy-Item -Path $src -Destination $dst -Recurse

Пример не является валидированной полной процедурой установки. Повторную синхронизацию пока выполнять вручную с проверкой конфликтов.

## Планируемый installer/sync

- `install.ps1`: scope (user/project), выбор навыков, список изменений, dry-run, защита от перезаписи, manifest.
- `sync.ps1`: сверка источника/версий, локальные изменения, отчёт о конфликтах, безопасное обновление.
- Спецификация: [scripts/README.md](../../scripts/README.md).

Документация: https://developers.openai.com/codex/skills и https://developers.openai.com/codex/guides/agents-md

