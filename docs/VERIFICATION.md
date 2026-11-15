# Проверки Foundation: факты и ограничения

## Проверенная версия

- **Дата:** 2026-11-15.
- **Исходный SHA:** `1ad4766365f1b61d7e92edb49faa0c25a5aa5442`.
- **GitHub Actions:** [run #43709191000](https://github.com/m-amirov/workflow-for-agents/actions/runs/43709191000).
- **Результат:** SUCCESS; обе CI jobs завершились успешно.

## Что реально выполнено

| Gate | Среда | Статус | Доказательство |
| --- | --- | --- | --- |
| Skill frontmatter, имена, каталог, локальные ссылки и структура eval cases | Python 3.11, Ubuntu | PASS | `Validate Skills / Python` |
| Регрессионные тесты валидатора | Python 3.11, Ubuntu | PASS | `Run validator regressions` |
| Project-scope install/sync: dry-run, manifest fingerprint, idempotency, local edits, add/update/remove, unmanaged files, collisions | PowerShell 7, Windows | PASS | `Smoke test ... (PowerShell 7)` |
| То же на Windows PowerShell 5.1 | Windows PowerShell 5.1 | PASS | `Smoke test ... (Windows PowerShell 5.1)` |
| User-scope installation/sync в `~/.agents/skills` | Обе Windows-среды, временный профиль CI | PASS | Тот же smoke test |

## Что ещё не выполнено

- **NOT RUN:** реальный запуск Codex CLI с discovery выбранных Skills, позитивными/негативными заданиями и проверкой принятия `AGENTS.md`.
- **NOT RUN:** интеграция с реальной пользовательской Windows-машиной; CI запускается в независимом Windows runner.
- **NOT RUN:** проверка обновления при параллельном изменении файлов в момент копирования и восстановления после аварийного отключения. Скрипты не обеспечивают транзакцию всей операции.
- **NOT RUN:** проверка main-first поведения на реальном защищённом репозитории/PR и безопасной очистки рабочих веток.
- **NOT RUN:** интеграции с Claude/Gemini/локальными моделями.

## Вывод

**Foundation частично реализован и технически проверен, но НЕ закрыт.** Для закрытия необходимо доказать, что Codex действительно видит установленные Skills и вызывает их на релевантных задачах, не вызывает на нерелевантных и соблюдает глобальную main-first инструкцию. При невозможности провести эту проверку результат остаётся `BLOCKED / NOT RUN`, не `PASS`.

После дальнейших изменений этот отчёт относится только к указанному исходному SHA. Для новых SHA смотреть соответствующие GitHub Actions runs.
