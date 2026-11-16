# Drawing editor — реальные Codex CLI evals

Дата: 2026-11-16. Среда: Windows, PowerShell, `codex-cli 0.167.2`; disposable Git project в `%TEMP%`. Skill установлен только в `.agents/skills/drawing-editor`. Codex запускался с `--sandbox read-only --ephemeral`; browser, device, IndexedDB, credentials, network side effect и пользовательские документы не использовались.

## Установка и sync

Временная source copy Skill и disposable project использовались вместо центрального репозитория и user scope.

| Проверка | Статус | Наблюдение |
| --- | --- | --- |
| Project install dry-run | PASS | `INSTALL`, target отсутствует после dry-run |
| Install / manifest | PASS | `sourceRelative: skills/domain/drawing-editor`, SHA-256 `sourceVersion` |
| Repeat install | PASS | `SKIP drawing-editor`, `No changes` |
| Sync dry-run / update | PASS | `UPDATE` показан без записи, затем managed Skill обновлён |
| Local-edit protection | PASS | Sync остановился на локальной правке; marker в target сохранён |

## Real activation

### DE-01 — positive

Prompt требовал спроектировать безопасное исправление Canvas editor для locked layer, `pointercancel` и immutable undo/redo без файлов, сети или browser. Codex прочитал установленный `drawing-editor`, явно назвал его основным Skill и выдал document action с no-op validation, единый gesture owner, cancel/lost ownership без commit, idempotent completion, undo/redo branching и failed/unknown save contract. Он отдельно отметил, что не доказаны Canvas rendering, browser Pointer Events, IndexedDB и stylus/device behavior. Команды Codex были read-only; проектные файлы не изменялись.

### DE-02 / DE-10 — negative

DE-02 спросил только о `CanvasRenderingContext2D.beginPath()`, DE-10 — о минимальном CSS diff статической страницы. В обоих JSONL нет `command_execution` и чтения `drawing-editor`; Codex не запускал browser и не менял файлы. Это подтверждает неактивацию для теории Canvas и обычного CSS.

## Synthetic contract

[tests/test_drawing_editor_contract.py](../../tests/test_drawing_editor_contract.py) — PASS, семь deterministic checks:

- DE-03 locked layer no-op;
- DE-04 invalid/missing/duplicate action preserves snapshot;
- DE-05 undo restores prior document;
- DE-06 new accepted branch clears redo;
- DE-07 cancel has no commit;
- DE-08 repeated completion commits once;
- DE-09 failed in-memory save retains the prior persisted snapshot.

These are independent model contracts, not Canvas, Pointer Event or IndexedDB tests.

## Limits

- Eskizno exact-SHA CI remains `NOT_RUN`; source evidence is local unit/type evidence.
- No Canvas pixel rendering, browser E2E, real pointer capture/cancel, tablet/stylus pressure/tilt, touch/mobile, IndexedDB or crash recovery was run.
- The initial CLI attempt before `git init` was rejected by Codex's trusted-directory precondition before it processed the prompt; the reported three evals ran after the disposable project was initialized as Git.
