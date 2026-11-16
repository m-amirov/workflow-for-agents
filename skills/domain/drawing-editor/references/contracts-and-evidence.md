# Contracts and source-bound evidence

## Minimum document and history contract

Keep this model inside the target project; this Skill does not prescribe a framework or data schema.

| Boundary | Required behavior |
| --- | --- |
| Document action | Validate input before transition; rejected input returns the same snapshot and does not create history/event records. |
| Immutable transition | A successful action creates an independent next snapshot; prior snapshots remain usable by undo/redo. |
| Layer lock | Drawing, removal, move and transform on a locked layer are rejected. |
| History | Accepted actions create one entry; undo/redo restores snapshots; accepted branch after undo clears redo. |
| Gesture | Exactly one active pointer/gesture; cancel or lost ownership discards pending work; completion is idempotent. |
| Persistence | Failed or unknown save preserves existing persisted data and surfaces an unsaved result. |

## Failure checks

- Target a locked, hidden, wrong-kind or missing layer: document identity and history must stay unchanged.
- Reject malformed geometry, bounds violation or duplicate stroke/action ID without mutation.
- After undo, commit a distinct action and assert redo is empty.
- Send `pointercancel`, then a stale `pointerup`; assert no committed stroke/event.
- Send duplicate completion for one pointer; assert exactly one commit.
- Simulate write failure without an actual browser store; assert no `saved` claim and the prior persisted snapshot remains intact.

## Source-bound evidence

The reusable contracts are derived from Eskizno at exact SHA [`7e10b7db7c5b37ab3ed1e004ebf85234bd9faf15`](https://github.com/m-amirov/eskizno/tree/7e10b7db7c5b37ab3ed1e004ebf85234bd9faf15):

- [`applyAction` document validation and immutable updates](https://github.com/m-amirov/eskizno/blob/7e10b7db7c5b37ab3ed1e004ebf85234bd9faf15/apps/web/src/editor/model.ts), with [model regressions](https://github.com/m-amirov/eskizno/blob/7e10b7db7c5b37ab3ed1e004ebf85234bd9faf15/apps/web/src/editor/model.test.ts).
- [Bounded undo/redo history](https://github.com/m-amirov/eskizno/blob/7e10b7db7c5b37ab3ed1e004ebf85234bd9faf15/apps/web/src/editor/history.ts), with [history regressions](https://github.com/m-amirov/eskizno/blob/7e10b7db7c5b37ab3ed1e004ebf85234bd9faf15/apps/web/src/editor/history.test.ts).
- [`pointercancel` event suppression](https://github.com/m-amirov/eskizno/blob/7e10b7db7c5b37ab3ed1e004ebf85234bd9faf15/apps/web/src/editor/events.ts), with [event regressions](https://github.com/m-amirov/eskizno/blob/7e10b7db7c5b37ab3ed1e004ebf85234bd9faf15/apps/web/src/editor/events.test.ts) and central [Stage 2 evidence](../../../../knowledge/research/stage-2-evidence.md).

These are local unit/type evidence only. The source has no confirmed persistence implementation or exact-SHA CI run; it does not prove rendering, IndexedDB, stylus pressure/tilt or device/browser behavior.
