# Drawing editor Skill — source-bound evidence

## Scope

This evidence supports the central `drawing-editor` Skill's document, history and cancellation contracts. It does not assert Canvas pixel correctness, real browser Pointer Events, physical stylus behavior or IndexedDB persistence.

## Source

- **Repository:** `m-amirov/eskizno`
- **Exact SHA:** `7e10b7db7c5b37ab3ed1e004ebf85234bd9faf15`
- **Source verification:** `SOURCE_REVIEWED` — a clean detached checkout and current remote `main` both resolved to this SHA.
- **CI verification:** `NOT_RUN` — GitHub Actions returned zero workflow runs for this exact SHA in Stage 2.
- **Local verification:** `LOCAL_TESTED` — on 2026-11-16, isolated `apps/web` ran `npm run test:unit -- src/editor/model.test.ts src/editor/history.test.ts src/editor/events.test.ts` (3 files / 25 tests) and `npm run typecheck`; both passed. The source checkout remained clean.

## Evidence-to-contract mapping

| Skill invariant | Exact source | Local evidence |
| --- | --- | --- |
| Invalid actions preserve the document; updates are immutable | [model](https://github.com/m-amirov/eskizno/blob/7e10b7db7c5b37ab3ed1e004ebf85234bd9faf15/apps/web/src/editor/model.ts) | [model tests](https://github.com/m-amirov/eskizno/blob/7e10b7db7c5b37ab3ed1e004ebf85234bd9faf15/apps/web/src/editor/model.test.ts) |
| Locked layers reject paint/remove/reorder/transform | `applyAction` in the same model | locked-layer cases in the same tests |
| Undo/redo restores snapshots; branch clears redo; history is bounded | [history](https://github.com/m-amirov/eskizno/blob/7e10b7db7c5b37ab3ed1e004ebf85234bd9faf15/apps/web/src/editor/history.ts) | [history tests](https://github.com/m-amirov/eskizno/blob/7e10b7db7c5b37ab3ed1e004ebf85234bd9faf15/apps/web/src/editor/history.test.ts) |
| `pointercancel` cannot emit a committed-stroke event | [events](https://github.com/m-amirov/eskizno/blob/7e10b7db7c5b37ab3ed1e004ebf85234bd9faf15/apps/web/src/editor/events.ts) | [event tests](https://github.com/m-amirov/eskizno/blob/7e10b7db7c5b37ab3ed1e004ebf85234bd9faf15/apps/web/src/editor/events.test.ts) |

## Stage 4 independent application

[tests/test_drawing_editor_contract.py](../../tests/test_drawing_editor_contract.py) uses a new in-memory document, history, gesture and save contract. It is not Eskizno code or a copied fixture. `python -m unittest discover -s tests -p test_drawing_editor_contract.py -v` passed all seven DE-03…DE-09 checks. Real Codex CLI `0.167.2` selected the installed Skill for DE-01 and did not load it for DE-02/DE-10; details are in [the Stage 4 eval result](../../evals/results/2026-11-16-drawing-editor-codex-cli.md).

## Limits

- `persistence.ts` and an IndexedDB implementation were absent from this source; DE-09 tests only an abstract failed-write contract.
- No real Canvas rendering, device pointer event, pressure/tilt, touch, mobile browser or browser E2E verification was run.
- A local unit/type PASS is not GitHub CI or device acceptance.
