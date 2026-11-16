---
name: logging-standard
description: >-
  Use when designing, changing, reviewing or debugging production logging:
  structured events, trace/request correlation, retries, fallback, error
  ownership, latency and privacy-safe diagnostic context. Not for unrelated
  prose/CSS edits or a theoretical logging question.
metadata:
  stage: "9A"
  integration: autonomous
  status: implemented
---

# Logging Standard

Enable reconstruction of significant operations without logging each internal
function. The project's existing observability conventions and data policy
take precedence. No CEOS CLI, specific provider, model, hooks or agent runtime
is required.

## Activate when

The user requests logging design, an event schema, a correlation repair, log
privacy review, retry/fallback observability or diagnosis of missing logs.
Do not activate for unrelated content, styling, generic code review or a
purely theoretical explanation. For actual incident reconstruction see
[incident-analysis](../incident-analysis/SKILL.md); for a code fix use
root-cause-debugging and regression-testing. Never assume an external log
sink or production credentials are available.

## Procedure

1. Inspect the real code and log conventions. Identify operation boundaries,
   specific diagnostic questions, data sensitivity, retention rules and current
   evidence. Do not propose a replacement observability stack by default.
2. Pick the minimum useful lifecycle events: accepted/started, consequential
   stage, external dependency failure, retry/fallback, and terminal outcome.
   Prefer stable machine-readable event names and avoid per-function noise.
3. Include fields only where operationally useful: event, stage, status,
   trace_id/request_id, component, provider, attempt, duration_ms, error_type,
   reason_code. Preserve existing schema; these are not mandatory universal
   columns for every single record.
4. Propagate the same correlation ID over all stages of one operation, queue
   handoffs and retries. Introduce separate span/job IDs when needed; do not
   regenerate the root trace ID at each stage. Distinct operations must not
   share one correlation ID accidentally.
5. Record failures at the boundary that owns the outcome. Log retry number,
   bounded error category, fallback decision and whether final success was
   degraded. Do not log the same propagated exception as ERROR in each layer.
   An expected validation rejection normally is not a production ERROR.
6. Distinguish a safe retry from an unknown external side-effect result. A
   timeout does NOT prove that a payment, submission or other non-idempotent
   action failed. Logging must not cause an automatic repeated side effect.
7. Minimize sensitive data. Exclude tokens, API keys, passwords, cookies,
   authorization headers, private keys, .env contents, full request/response
   bodies, documents and raw prompts. Treat names, email, phone, IP, free
   text and customer identifiers as sensitive unless a project policy allows
   a minimum necessary form. Redact or omit by default; hashing alone does
   not always anonymize. Never print or copy real secrets into tests/reports.
8. For diagnosis, sort observed events by trace and time, find the last
   confirmed successful stage and first failure, then inspect retries,
   fallback and terminal receipt. Label missing stages as EVIDENCE_GAP and
   distinguish demonstrated cause from hypothesis or secondary symptom.
9. Implement the smallest compatible change, with sanitized tests for
   continuity, error/fallback paths, duplicate exception and sensitive fields.
   Preserve unrelated application behavior and local modifications.

## Acceptance

A scoped PASS needs observed or fixture-backed event sequences, correct
correlation propagation, error/retry/fallback visibility, adequate signal,
and privacy-negative coverage for tested fields. Synthetic checks cannot
prove live emission, production retention, sink access or privacy of unknown
payloads. Missing runtime proof is PARTIAL/BLOCKED; never invent log entries,
reviewer observations or production acceptance.

Do not turn on global DEBUG, change deployment/retention, send logs to an
external service or copy customer data without explicit authorization.

See [diagnostic examples and test boundaries](references/contracts-and-evals.md).
