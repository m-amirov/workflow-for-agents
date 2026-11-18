"""Offline Game Production Pipeline verification. No actual game/agent execution."""
from __future__ import annotations

import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/game_production.py"
TEMPLATE = ROOT / "templates/game-production-state.example.json"
PLAYBOOK = ROOT / "playbooks/game-production.md"
EVALS = ROOT / "evals/cases/game-production/scenarios.json"
spec = importlib.util.spec_from_file_location("game_production", SCRIPT)
assert spec and spec.loader
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


class GameProductionGateTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.record = json.loads(TEMPLATE.read_text(encoding="utf-8"))
        self.sha = "a" * 40

    def _pass(self, stage: str, source_sha: str | None = None):
        gate = self.record["gates"][stage]
        gate["status"] = "PASS"
        gate["sourceSha"] = source_sha or self.sha
        kinds = set(mod.GATE_KINDS[stage])
        if stage == "G5" and mod.WEB_TARGETS.intersection(self.record["targets"]):
            kinds.add("browser-qa")
        for kind in sorted(kinds):
            path = f"proof/{stage}/{kind}.txt"
            absolute = self.root / path
            absolute.parent.mkdir(parents=True, exist_ok=True)
            data = (stage + ":" + kind).encode()
            absolute.write_bytes(data)
            gate["evidence"].append({
                "kind": kind, "path": path, "sha256": hashlib.sha256(data).hexdigest()
            })
        return gate

    def _pass_to(self, stage: str):
        for name in mod.GATE_KINDS:
            self._pass(name)
            if name == stage:
                break

    def _inspect(self):
        return mod.inspect(self.record, self.root)

    def test_blank_example_is_valid_record_but_not_completion(self):
        self.assertEqual("STRUCTURAL_RECORD_VALID", self._inspect()["status"])
        self.assertEqual([], self._inspect()["recordedPassGates"])
        self.assertEqual("G0", self._inspect()["nextGate"])
        self.assertFalse(self._inspect()["releaseReady"])
        self.assertFalse(self._inspect()["publicationAllowed"])

    def test_g0_then_g1_advances_by_existing_hashed_evidence(self):
        self._pass_to("G1")
        r = self._inspect()
        self.assertEqual([], r["errors"])
        self.assertEqual(["G0", "G1"], r["recordedPassGates"])
        self.assertEqual("G2", r["nextGate"])
        self.assertEqual(3, r["verifiedEvidenceFiles"])

    def test_missing_g1_acceptance_matrix_fails(self):
        self._pass_to("G1")
        self.record["gates"]["G1"]["evidence"].pop()
        r = self._inspect()
        self.assertIn("G1: missing required evidence kind gdd", r["errors"])

    def test_cannot_skip_gates(self):
        self._pass("G4")
        self.assertIn("G4: previous gate has not passed", self._inspect()["errors"])

    def test_browser_evidence_required_for_yandex(self):
        self._pass_to("G5")
        self.record["gates"]["G5"]["evidence"] = [
            e for e in self.record["gates"]["G5"]["evidence"] if e["kind"] != "browser-qa"
        ]
        self.assertIn("G5: missing required evidence kind browser-qa", self._inspect()["errors"])

    def test_native_game_does_not_require_web_browser_receipt(self):
        self.record["targets"] = ["desktop"]
        self._pass_to("G5")
        self.assertEqual([], self._inspect()["errors"])

    def test_release_qa_must_match_same_source_sha(self):
        self._pass_to("G6")
        self.record["gates"]["G6"]["sourceSha"] = "b" * 40
        self.assertIn("G6: sourceSha differs from G5 QA sourceSha", self._inspect()["errors"])

    def test_changed_file_invalidates_old_receipt(self):
        self._pass("G0")
        file = self.root / self.record["gates"]["G0"]["evidence"][0]["path"]
        file.write_text("new", encoding="utf-8")
        self.assertTrue(any("SHA-256 mismatch" in e for e in self._inspect()["errors"]))

    def test_symlink_and_escape_are_rejected(self):
        self._pass("G0")
        gate = self.record["gates"]["G0"]
        gate["evidence"][0]["path"] = "../outside.txt"
        self.assertTrue(any("unsafe" in e for e in self._inspect()["errors"]))
        gate["evidence"][0]["path"] = "C:\\private\\s.txt"
        self.assertTrue(any("unsafe" in e for e in self._inspect()["errors"]))
        forbidden = self.root / "proof" / "link"
        try:
            forbidden.symlink_to(self.root / "proof" / "G0", target_is_directory=True)
        except (OSError, NotImplementedError):
            return
        gate["evidence"][0]["path"] = "proof/link/game-brief.txt"
        self.assertTrue(any("unsafe" in e for e in self._inspect()["errors"]))

    def test_duplicate_kind_or_path_cannot_pass(self):
        gate = self._pass("G0")
        gate["evidence"].append(copy.deepcopy(gate["evidence"][0]))
        errors = self._inspect()["errors"]
        self.assertTrue(any("duplicate evidence kind" in e for e in errors))
        self.assertTrue(any("duplicate path" in e for e in errors))

    def test_blocked_gate_requires_explicit_reason(self):
        self.record["gates"]["G0"]["status"] = "BLOCKED"
        self.assertTrue(any("needs a concrete blocker" in e for e in self._inspect()["errors"]))

    def test_invalid_shapes_fail_closed_not_crash(self):
        for mutation in [
            lambda state: state["gates"].__setitem__("G5", []),
            lambda state: state["gates"]["G0"].__setitem__("status", []),
            lambda state: state["targets"].__setitem__(0, []),
            lambda state: state.__setitem__("gates", []),
        ]:
            with self.subTest(mutation=mutation):
                state = copy.deepcopy(self.record)
                mutation(state)
                self.assertEqual("INVALID", mod.inspect(state, self.root)["status"])

    def test_g7_cannot_be_self_attested_by_local_checker(self):
        self._pass_to("G7")
        self.assertEqual("STRUCTURAL_RECORD_VALID", self._inspect()["status"])
        self.assertFalse(self._inspect()["platformAcceptanceAttested"])
        self.assertFalse(self._inspect()["publicationAllowed"])
        state_path = self.root / "artifacts/game-production-state.json"
        state_path.parent.mkdir()
        state_path.write_text(json.dumps(self.record), encoding="utf-8")
        run = subprocess.run([sys.executable, str(SCRIPT), "--project", str(self.root),
                              "--require-gate", "G7", "--json"],
                             capture_output=True, text=True)
        self.assertEqual(2, run.returncode)
        self.assertFalse(json.loads(run.stdout)["recordCheckSatisfied"])

    def test_cli_readonly_and_exit_codes(self):
        state_path = self.root / "artifacts/game-production-state.json"
        state_path.parent.mkdir()
        state_path.write_text(json.dumps(self.record), encoding="utf-8")
        before = state_path.read_bytes()
        base = [sys.executable, str(SCRIPT), "--project", str(self.root), "--json"]
        ok = subprocess.run(base, capture_output=True, text=True)
        required = subprocess.run(base + ["--require-gate", "G0"], capture_output=True, text=True)
        self.assertEqual(0, ok.returncode)
        self.assertEqual(2, required.returncode)
        self.assertFalse(json.loads(ok.stdout)["executionAttested"])
        self.assertEqual(before, state_path.read_bytes())

    def test_playbook_scope_and_prepared_evals(self):
        text = PLAYBOOK.read_text(encoding="utf-8")
        for gate in mod.GATE_KINDS:
            self.assertIn(gate, text)
        for term in ("Ludory", "RELEASE_CANDIDATE_LOCAL", "PROJECT_STATUS.md",
                     "rights", "playtest", "source SHA", "Codex"):
            self.assertIn(term.lower(), text.lower())
        suite = json.loads(EVALS.read_text(encoding="utf-8"))
        self.assertEqual(suite["execution"], "NOT_RUN")
        self.assertEqual(len(suite["scenarios"]), 8)
        self.assertEqual({x["id"] for x in suite["scenarios"]},
                         {f"GP-{n:02d}" for n in range(1, 9)})


if __name__ == "__main__":
    unittest.main()
