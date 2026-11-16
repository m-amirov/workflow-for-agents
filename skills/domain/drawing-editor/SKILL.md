---
name: drawing-editor
description: >-
  Use when implementing or fixing a Canvas drawing editor's document model, layers,
  undo/redo, pointer/touch/stylus gesture lifecycle, or known save contract. Do not
  use for CSS, static galleries, Canvas theory, visual-only audits, image files, or read-only research.
---

# Safe Drawing Editor Changes

Use this Skill for changes that can alter a user's editable drawing. It complements [browser-qa](../../testing/browser-qa/SKILL.md) for real UI/device checks, [regression-testing](../../testing/regression-testing/SKILL.md) for a reproduced defect, and [browser-automation](../../automation/browser-automation/SKILL.md) for external browser side effects.

## Preserve the document first

1. Define the serializable document, action validation, layer identity/lock state, history boundary and save contract before changing a tool.
2. Make document commands immutable: an invalid ID, malformed action, duplicate ID, bounds violation or blocked layer is a no-op that preserves the prior snapshot.
3. Treat locked layers as read-only for drawing, move, transform and delete. Do not bypass the lock in a gesture handler.
4. Commit only accepted semantic actions. Keep in-progress pointer data separate from committed history and user events.
5. Implement one gesture owner: `pointerdown` starts it, matching updates extend it, matching `pointerup` may commit it once, and `pointercancel` or lost ownership discards it. A cancel is never a commit.
6. Store history as snapshots or equivalent reversible commands. Undo restores the actual prior document; redo restores the next one; a new accepted action after undo clears redo. Bound history deliberately.
7. If save fails or its result is unknown, retain the last known persisted document and report unsaved state. Never announce persistence until the project-defined store confirms it.

Read [references/contracts-and-evidence.md](references/contracts-and-evidence.md) for failure cases, source-bound evidence and what local tests do not prove.

## Verification and boundary

Use deterministic synthetic or project fixtures for locked/invalid actions, immutable snapshots, undo/redo branching, cancel, duplicate completion and failed save. Use sanitized data. Unit tests do not prove Canvas pixels, browser Pointer Events, real pressure/tilt, mobile behavior, IndexedDB or recovery after browser crash; label those checks separately as `NOT RUN` or `BLOCKED`.

## Completion gate

Show the action/gesture/save contract, focused regression results and the status of rendering, persistence and device evidence independently. Do not replace user data or add a persistence backend merely to satisfy this Skill.
