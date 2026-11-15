"""Synthetic, offline contract checks backing browser-automation evals BA-03..BA-09."""
from __future__ import annotations

from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from threading import Lock
import unittest


@dataclass(frozen=True)
class Identity:
    task: str
    page: str
    frame: str


class DurableReservations:
    def __init__(self, *, writable: bool = True) -> None:
        self.writable = writable
        self._items: set[Identity] = set()
        self._lock = Lock()

    def reserve(self, identity: Identity) -> bool:
        with self._lock:
            if not self.writable:
                raise OSError("durable_store_unavailable")
            if identity in self._items:
                return False
            self._items.add(identity)
            return True

    def release_after_receipt(self, identity: Identity, receipt_identity: Identity | None) -> bool:
        with self._lock:
            if receipt_identity != identity or identity not in self._items:
                return False
            self._items.remove(identity)
            return True

    def contains(self, identity: Identity) -> bool:
        with self._lock:
            return identity in self._items


class SyntheticAutomation:
    def __init__(self, store: DurableReservations, current: Identity) -> None:
        self.store = store
        self.current = current
        self.effects = 0

    def attempt(self, identity: Identity, *, outcome: str = "unknown") -> str:
        if identity != self.current:
            return "blocked_stale"
        try:
            if not self.store.reserve(identity):
                return "blocked_reserved"
        except OSError:
            return "blocked_persist_failed"
        self.effects += 1
        return "confirmed" if outcome == "confirmed" else "unknown"

    def receive_receipt(self, identity: Identity, receipt_identity: Identity | None) -> str:
        return "confirmed" if self.store.release_after_receipt(identity, receipt_identity) else "unknown"


class BrowserAutomationContractTests(unittest.TestCase):
    def setUp(self) -> None:
        self.identity = Identity("task-a", "page-a", "frame-a")
        self.store = DurableReservations()
        self.runner = SyntheticAutomation(self.store, self.identity)

    def test_ba03_stale_callback_is_blocked_before_effect(self) -> None:
        stale = Identity("task-a", "page-b", "frame-b")
        self.assertEqual(self.runner.attempt(stale), "blocked_stale")
        self.assertEqual(self.runner.effects, 0)

    def test_ba04_ba06_restart_or_timeout_keeps_reservation_without_retry(self) -> None:
        self.assertEqual(self.runner.attempt(self.identity), "unknown")
        restored = SyntheticAutomation(self.store, self.identity)
        self.assertEqual(restored.attempt(self.identity), "blocked_reserved")
        self.assertEqual(restored.effects, 0)
        self.assertTrue(self.store.contains(self.identity))

    def test_ba05_failed_reservation_blocks_effect(self) -> None:
        runner = SyntheticAutomation(DurableReservations(writable=False), self.identity)
        self.assertEqual(runner.attempt(self.identity), "blocked_persist_failed")
        self.assertEqual(runner.effects, 0)

    def test_ba07_matching_independent_receipt_retires_only_its_reservation(self) -> None:
        self.assertEqual(self.runner.attempt(self.identity), "unknown")
        self.assertEqual(self.runner.receive_receipt(self.identity, self.identity), "confirmed")
        self.assertFalse(self.store.contains(self.identity))

    def test_ba08_missing_or_mismatched_receipt_keeps_fence(self) -> None:
        self.assertEqual(self.runner.attempt(self.identity), "unknown")
        other = Identity("task-b", "page-b", "frame-b")
        self.assertEqual(self.runner.receive_receipt(self.identity, None), "unknown")
        self.assertEqual(self.runner.receive_receipt(self.identity, other), "unknown")
        self.assertTrue(self.store.contains(self.identity))

    def test_ba09_concurrent_attempts_issue_one_effect(self) -> None:
        with ThreadPoolExecutor(max_workers=2) as pool:
            outcomes = list(pool.map(lambda _: self.runner.attempt(self.identity), range(2)))
        self.assertCountEqual(outcomes, ["unknown", "blocked_reserved"])
        self.assertEqual(self.runner.effects, 1)


if __name__ == "__main__":
    unittest.main()
