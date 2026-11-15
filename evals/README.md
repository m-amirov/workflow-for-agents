# Evaluations

Цель: проверить, что Skill активируется тогда, когда нужен, **не** активируется на посторонний запрос и выполняет нужную процедуру.

Целевая структура: `evals/cases/<skill-name>/` и `evals/fixtures/`.

## Минимальные тесты Skill

1. **Positive trigger:** задача соответствует description; агент выбрал подходящий Skill.
2. **Negative trigger:** задача похожа поверхностно, но навык применять нельзя.
3. **Execution:** ожидаемые шаги выполнены, запрещённые действия отсутствуют.
4. **Evidence:** агент не придумывает PASS, указывает реальные проверки.
5. **Regression:** после обновления Skill проверяются прежние кейсы.

## Формат кейса (планируется)

- input: текст/фикстуры задачи.
- expected_behavior: что агент должен сделать.
- prohibited_behavior: что недопустимо.
- environment: необходимые инструменты, репозиторий, версии.
- check: автоматический или ручной способ оценки.
- provenance: откуда взят проверяемый сценарий.

В `evals/cases/foundation.json` сохранены 10 пар positive/negative prompts. Валидатор CI проверяет только структуру; реальные Codex CLI activation-evals выполнены для `git-workflow` и `root-cause-debugging`. Команды, наблюдаемые tool events и ограничения сохранены в [результате](results/2026-11-15-codex-cli-foundation.md). Для остальных восьми Skills activation остаётся `NOT RUN`.

