# Logging Standard — synthetic diagnostics

The following JSONL is invented. No record comes from customer data or a
running product. Fields are examples, not a required universal schema.

~~~jsonl
{"event":"job_started","stage":"ingress","status":"started","trace_id":"demo-trace","job_id":"synthetic"}
{"event":"api_retry","stage":"fetch","status":"retry","trace_id":"demo-trace","provider":"service-a","attempt":2,"error_type":"Timeout","duration_ms":1200}
{"event":"api_fallback","stage":"fetch","status":"degraded","trace_id":"demo-trace","provider":"service-b","reason_code":"primary_timeout"}
{"event":"job_completed","stage":"result","status":"success_degraded","trace_id":"demo-trace","duration_ms":2210}
~~~

Observations: one trace across stages; retry has a reason and attempt;
fallback has a reason; final success explicitly records degradation.

## Anti-examples

- A new trace ID on each retry makes incident reconstruction unreliable.
- Five ERROR messages for the same propagated exception create noise.
- A lone "completed" record hides whether the primary provider failed.
- Full payload, cookie, password, key or customer document in a log is an
  unsafe shortcut; use a constrained identifier or safe metadata instead.
- An unverified timeout must not trigger a second irreversible side effect.
- Artificial JSONL is not evidence of actual production logging.

## Safe assessment

Inspect source and synthetic fixtures without invoking production sessions.
Document what is directly observed versus inferred. Propose one minimal
instrumentation change; run available source tests and privacy-negative tests.
Do not claim whole-product observability from a synthetic unit test.

[Evaluation cases](../../../../evals/cases/logging-standard/scenarios.json):
LS-01..LS-06 are relevant logging tasks and LS-07..LS-10 are unrelated
negative activation prompts. All start at prepared / NOT RUN. Structural
validation cannot prove actual Codex activation.
