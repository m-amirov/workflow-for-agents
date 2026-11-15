# Каталог Agent Skills

**Статусы:** implemented = в репозитории есть рабочее описание SKILL.md; planned = запланировано, но пока не реализовано. **Implemented не означает validated:** фактическое выполнение сценариев и соответствие конкретному агенту необходимо проверять отдельно.

| Категория | Skill | Когда использовать | Статус |
|---|---|---|---|
| Core | task-planning | Разложить техническую задачу на проверяемые шаги | implemented |
| Development | codebase-exploration | Найти правильное место изменения по коду | planned |
| Development | root-cause-debugging | Ошибка, регрессия, нестабильное поведение | implemented |
| Testing | regression-testing | Защитить исправление от повторного сбоя | implemented |
| Development | code-review | Проверить код и архитектурные риски | planned |
| Development | minimal-change | Внести локальное изменение без лишнего рефакторинга | planned |
| Development | git-workflow | Main-first: работа в main, merge проверенного результата и очистка своих временных веток | implemented |
| Testing | release-verification | Проверить сборку и release gates | planned |
| Design | visual-audit | Независимая оценка UI и визуальной целостности | implemented |
| Frontend | responsive-design | Адаптивность и геометрия экрана | planned |
| Design | interaction-design | Жесты, состояния и взаимодействия | planned |
| Frontend | accessibility-audit | Доступность UI | planned |
| Testing | browser-qa | Сценарии в реальном браузере | planned |
| Domain | interactive-fiction | Ветвления, решения, переменные, концовки | planned |
| Domain | game-visual-integrity | Ассеты, шрифты, CG, изображения и экраны игры | planned |
| Domain | drawing-editor | Холст, стилус, кисти, фигуры, слои | planned |
| Automation | browser-automation | Устойчивая UI-автоматизация | planned |
| Automation | document-extraction | Поля и разметка документов/PDF | planned |
| Automation | classification-quality | Аудит классификаторов и логов | planned |
| Domain | seo-calculators | Полезные SEO-инструменты и калькуляторы | planned |
| Content | content-pipeline | Конвейер подготовки и проверки публикаций | planned |

## Критерии для нового Skill

- Задача повторяется хотя бы в нескольких сценариях или требует существенной воспроизводимой процедуры.
- Есть конкретные позитивные и негативные условия активации.
- Описано, что выполнять, чего не делать и как подтвердить завершение.
- Есть владелец области знаний / способ поддерживать актуальность.
- Поведение лучше оформить как Skill, а не как короткое глобальное правило, одноразовую заметку или длинную роль агента.

Начать с 8–10 базовых, затем добавлять специальные по фактической необходимости. Не считать эту таблицу перечнем готовых инструментов.
