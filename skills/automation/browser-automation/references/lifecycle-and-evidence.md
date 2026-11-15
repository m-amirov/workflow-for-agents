# Lifecycle, failure modes and source evidence

## State contract

Keep the state model local to the project; do not introduce a framework merely to use this Skill. Its minimum invariant is:

| State | Meaning | Permitted transition |
| --- | --- | --- |
| `READY` | Current lease has no reservation | atomically persist `RESERVED` |
| `RESERVED` | Effect is fenced before execution | one serialized effect, or `UNKNOWN` on interruption |
| `UNKNOWN` | The effect may have reached the external system | only identity-bound independent receipt/reconciliation; no retry |
| `CONFIRMED` | Contract-defined receipt matches the reserved identity | retire that reservation |

Cancellation, expired lease, changed task/page/frame or durable-write failure block the effect before it is issued. A receipt for another identity cannot retire a reservation.

## Failure-mode test matrix

| Condition | Required assertion |
| --- | --- |
| Callback after task/page/frame replacement | no side effect |
| Durable reservation cannot be written | no side effect |
| Restart/crash after reservation | same identity cannot repeat the effect |
| Timeout/reload/network failure after effect | state remains `UNKNOWN`; no blind retry |
| Missing, ambiguous or mismatched receipt | fence remains active |
| Matching independent receipt | only matching reservation can transition to `CONFIRMED` |
| Concurrent workers | at most one effect for the identity |

## Source-bound evidence

The lifecycle is derived from Twork source at exact SHA [`196f99b4583555ee1b0b170115d6c613e77ce705`](https://github.com/m-amirov/task-playwright-desktop/tree/196f99b4583555ee1b0b170115d6c613e77ce705), reviewed and locally tested offline in Stage 2:

- [Durable reservation and receipt probing](https://github.com/m-amirov/task-playwright-desktop/blob/196f99b4583555ee1b0b170115d6c613e77ce705/src/core/native-submission-confirmation.js) and [its deterministic tests](https://github.com/m-amirov/task-playwright-desktop/blob/196f99b4583555ee1b0b170115d6c613e77ce705/tests/native-submission-confirmation.test.js).
- [Task/page/frame lease](https://github.com/m-amirov/task-playwright-desktop/blob/196f99b4583555ee1b0b170115d6c613e77ce705/src/core/task-run-lease.js) and [lease regression tests](https://github.com/m-amirov/task-playwright-desktop/blob/196f99b4583555ee1b0b170115d6c613e77ce705/tests/nitro-task-run-lease.test.js).
- [Receipt identity regressions](https://github.com/m-amirov/task-playwright-desktop/blob/196f99b4583555ee1b0b170115d6c613e77ce705/tests/nitro-submission-receipt.test.js) and the central [Stage 2 evidence](../../../../knowledge/research/stage-2-evidence.md).

Those tests are local/offline evidence only. They do not prove that an external platform accepted any answer or action.
