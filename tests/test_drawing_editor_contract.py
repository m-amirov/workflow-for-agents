"""Synthetic, offline contracts backing drawing-editor evals DE-03..DE-09."""
from __future__ import annotations

from dataclasses import dataclass, replace
import unittest


@dataclass(frozen=True)
class Layer:
    id: str
    locked: bool = False
    strokes: tuple[str, ...] = ()


@dataclass(frozen=True)
class Document:
    layers: tuple[Layer, ...]


def add_stroke(document: Document, layer_id: str, stroke_id: str) -> Document:
    if not layer_id or not stroke_id or any(stroke_id in layer.strokes for layer in document.layers):
        return document
    for index, layer in enumerate(document.layers):
        if layer.id != layer_id:
            continue
        if layer.locked:
            return document
        layers = list(document.layers)
        layers[index] = replace(layer, strokes=(*layer.strokes, stroke_id))
        return Document(tuple(layers))
    return document


@dataclass(frozen=True)
class History:
    past: tuple[Document, ...]
    present: Document
    future: tuple[Document, ...] = ()


def commit(history: History, next_document: Document) -> History:
    if next_document is history.present:
        return history
    return History((*history.past, history.present), next_document)


def undo(history: History) -> History:
    if not history.past:
        return history
    return History(history.past[:-1], history.past[-1], (history.present, *history.future))


@dataclass
class Gesture:
    active_pointer: int | None = None
    commits: int = 0

    def down(self, pointer_id: int) -> None:
        if self.active_pointer is None:
            self.active_pointer = pointer_id

    def cancel(self, pointer_id: int) -> bool:
        if self.active_pointer != pointer_id:
            return False
        self.active_pointer = None
        return True

    def up(self, pointer_id: int) -> bool:
        if self.active_pointer != pointer_id:
            return False
        self.active_pointer = None
        self.commits += 1
        return True


class MemorySave:
    def __init__(self, *, writable: bool, existing: Document) -> None:
        self.writable = writable
        self.saved = existing

    def save(self, document: Document) -> bool:
        if not self.writable:
            return False
        self.saved = document
        return True


class DrawingEditorContractTests(unittest.TestCase):
    def setUp(self) -> None:
        self.unlocked = Layer("ink")
        self.locked = Layer("reference", locked=True)
        self.document = Document((self.unlocked, self.locked))

    def test_de03_locked_layer_is_not_modified(self) -> None:
        self.assertIs(add_stroke(self.document, "reference", "stroke-1"), self.document)

    def test_de04_invalid_action_or_id_preserves_snapshot(self) -> None:
        self.assertIs(add_stroke(self.document, "missing", "stroke-1"), self.document)
        valid = add_stroke(self.document, "ink", "stroke-1")
        self.assertIs(add_stroke(valid, "ink", "stroke-1"), valid)
        self.assertEqual(self.document.layers[0].strokes, ())

    def test_de05_undo_restores_prior_document(self) -> None:
        painted = add_stroke(self.document, "ink", "stroke-1")
        undone = undo(commit(History((), self.document), painted))
        self.assertIs(undone.present, self.document)
        self.assertEqual(undone.future, (painted,))

    def test_de06_new_action_after_undo_clears_redo(self) -> None:
        first = add_stroke(self.document, "ink", "stroke-1")
        second = add_stroke(first, "ink", "stroke-2")
        undone = undo(commit(commit(History((), self.document), first), second))
        branched = commit(undone, add_stroke(undone.present, "ink", "stroke-3"))
        self.assertEqual(branched.future, ())
        self.assertEqual(branched.present.layers[0].strokes, ("stroke-1", "stroke-3"))

    def test_de07_pointercancel_never_commits(self) -> None:
        gesture = Gesture()
        gesture.down(7)
        self.assertTrue(gesture.cancel(7))
        self.assertEqual(gesture.commits, 0)
        self.assertFalse(gesture.up(7))

    def test_de08_repeated_pointerup_commits_once(self) -> None:
        gesture = Gesture()
        gesture.down(7)
        self.assertTrue(gesture.up(7))
        self.assertFalse(gesture.up(7))
        self.assertEqual(gesture.commits, 1)

    def test_de09_failed_save_preserves_prior_persisted_document(self) -> None:
        changed = add_stroke(self.document, "ink", "stroke-1")
        store = MemorySave(writable=False, existing=self.document)
        self.assertFalse(store.save(changed))
        self.assertIs(store.saved, self.document)


if __name__ == "__main__":
    unittest.main()
