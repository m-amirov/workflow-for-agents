# Каталог Agent Skills

**Статусы:** implemented = в репозитории есть рабочее описание SKILL.md; planned = запланировано, но пока не реализовано. **Implemented не означает validated:** фактическое выполнение сценариев и соответствие конкретному агенту необходимо проверять отдельно. Skills Stage 8 помечены `implemented` для адаптированного контракта; runtime activation и внешние platform gates остаются отдельными статусами в migration report.

| Категория | Skill | Когда использовать | Статус |
|---|---|---|---|
| Core | task-planning | Разложить техническую задачу на проверяемые шаги | implemented |
| Development | codebase-exploration | Найти правильное место изменения по коду | implemented |
| Development | root-cause-debugging | Ошибка, регрессия, нестабильное поведение | implemented |
| Testing | regression-testing | Защитить исправление от повторного сбоя | implemented |
| Development | code-review | Проверить код и архитектурные риски | implemented |
| Development | minimal-change | Внести локальное изменение без лишнего рефакторинга | implemented |
| Development | git-workflow | Main-first: работа в main, merge проверенного результата и очистка своих временных веток | implemented |
| Testing | release-verification | Проверить сборку и release gates | implemented |
| Design | visual-audit | Независимая оценка UI и визуальной целостности | implemented |
| Frontend | responsive-design | Адаптивность и геометрия экрана | planned |
| Design | interaction-design | Жесты, состояния и взаимодействия | planned |
| Frontend | accessibility-audit | Доступность UI | planned |
| Testing | browser-qa | Сценарии в реальном браузере | implemented |
| Domain | interactive-fiction | Ветвления, решения, переменные, концовки | planned |
| Domain | game-visual-integrity | Ассеты, шрифты, CG, изображения и экраны игры | planned |
| Domain | drawing-editor | Безопасные document/layer/history/pointer contracts для Canvas-редакторов | implemented |
| Automation | browser-automation | Stateful browser automation с lease, durable fence и independent receipt для внешних side effects | implemented |
| Automation | document-extraction | Поля и разметка документов/PDF | planned |
| Automation | classification-quality | Независимые labels, offline replay, baseline и fail-closed quality gates | implemented |
| Domain | seo-calculators | Полезные SEO-инструменты и калькуляторы | planned |
| Content | content-pipeline | Конвейер подготовки и проверки публикаций | planned |
| Development | audit | Read-only аудит с evidence и классификацией findings | implemented |
| Development | audit-repair-loop | Ограниченный audit → repair → verification → fresh re-audit | implemented |
| Development | ceos-continue | Только явно запрошенное продолжение CEOS run/checkpoint | implemented |
| Development | fix | Reproduce → root cause → minimal fix → regression → verification | implemented |
| Testing | verification | Независимая проверка acceptance claims | implemented |
| Testing | release | Release candidate gates и exact artifact evidence | implemented |
| Design | visual-qa | Runtime/browser visual evidence и viewport QA | implemented |
| Content | video-production | Gameplay evidence и отдельный promo trailer pipeline | implemented |
| Domain | romance-narrative | Romance-first concept и bounded editorial review | implemented |
| Domain | narrative-dialogue-editor | Voice, subtext, localization и branch-safe line editing | implemented |
| Domain | narrative-continuity-engine | Route-conditioned continuity и save/back evidence | implemented |
| Domain | reader-experience-review | Bounded blind-reader comprehension and payoff review | implemented |
| Domain | production-art | Source-bound art provenance, mapping and separate acceptance gates | implemented |
| Operations | prod-check | Read-only production inspection | implemented |
| Operations | incident-analysis | Incident timeline и causal evidence analysis | implemented |

## Критерии для нового Skill

- Задача повторяется хотя бы в нескольких сценариях или требует существенной воспроизводимой процедуры.
- Есть конкретные позитивные и негативные условия активации.
- Описано, что выполнять, чего не делать и как подтвердить завершение.
- Есть владелец области знаний / способ поддерживать актуальность.
- Поведение лучше оформить как Skill, а не как короткое глобальное правило, одноразовую заметку или длинную роль агента.

Начать с 8–10 базовых, затем добавлять специальные по фактической необходимости. Не считать эту таблицу перечнем готовых инструментов.
