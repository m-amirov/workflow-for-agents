# Patterns

Подтверждённые переиспользуемые подходы, условия применения, контрпримеры и ссылки на исходные доказательства. Процедуру с явным триггером лучше оформить как Skill.

Каждый pattern (кроме этого README) имеет YAML metadata: `title`, `status` (`VERIFIED`, `PARTIAL` или `UNKNOWN`), `source_repository`, exact `source_sha`, `reuse_scope` и три независимых слоя evidence: `source_verification`, `ci_verification`, `cross_project_verification`. Допустимые уровни последнего набора: `SOURCE_REVIEWED`, `LOCAL_TESTED`, `CI_VERIFIED`, `PARTIAL`, `BLOCKED`, `UNKNOWN`, `NOT_RUN`. Обязательные разделы: контекст, механизм, алгоритм, ограничения/антипримеры, источники и проверка повторного применения. Это проверяет `python scripts/validate.py`.

