"""Offline regressions for first-party gameplay design/playtesting/content QA.

These tests do not simulate real players, verify visual pixels or run a game.
"""
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
SKILLS = ("gameplay-design", "gameplay-playtesting", "game-content-qa")
SCRIPT = ROOT / "scripts/game_content_qa.py"
EVALS = ROOT / "evals/cases/gameplay-gaps/scenarios.json"

spec = importlib.util.spec_from_file_location("game_content_qa", SCRIPT)
assert spec and spec.loader
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class GameplaySkillsContracts(unittest.TestCase):
    def test_named_skills_in_catalog_and_foundation_activation(self):
        catalog = (ROOT / "docs/SKILL_CATALOG.md").read_text(encoding="utf-8")
        foundation = json.loads((ROOT / "evals/cases/foundation.json").read_text(encoding="utf-8"))
        for name in SKILLS:
            path = ROOT / "skills/domain" / name / "SKILL.md"
            skill = path.read_text(encoding="utf-8")
            self.assertTrue(skill.startswith("---\nname: " + name + "\n"))
            self.assertIn(f"| {name} |", catalog)
            matches = [c for c in foundation["cases"] if c["skill"] == name]
            self.assertEqual(1, len(matches), name)
            for variant in ("positive", "negative"):
                self.assertTrue(matches[0][variant]["prompt"].strip())
                self.assertTrue(matches[0][variant]["expected_behavior"].strip())
            self.assertTrue(matches[0]["prohibited_behavior"])

    def test_cross_skill_boundaries_and_no_fabricated_human_sessions(self):
        design = (ROOT / "skills/domain/gameplay-design/SKILL.md").read_text(encoding="utf-8")
        players = (ROOT / "skills/domain/gameplay-playtesting/SKILL.md").read_text(encoding="utf-8")
        content = (ROOT / "skills/domain/game-content-qa/SKILL.md").read_text(encoding="utf-8")
        self.assertIn("game-docs", design)
        self.assertIn("prototype-fast", design)
        self.assertIn("DESIGN_SPECIFIED", design)
        self.assertIn("PLAYTEST_NOT_RUN", players)
        self.assertIn("HUMAN_PLAYTEST", players)
        self.assertIn("SESSION_OBSERVED", players)
        self.assertIn("BASELINE_BLOCKED", content)
        self.assertIn("INTENTIONALLY_CUT", content)
        self.assertIn("source", content)
        self.assertIn("package", content)
        self.assertIn("G4", (ROOT / "playbooks/game-production.md").read_text(encoding="utf-8"))

    def test_prepared_positive_negative_evals_and_no_execution_claims(self):
        suite = json.loads(EVALS.read_text(encoding="utf-8"))
        self.assertEqual(1, suite["schema"])
        self.assertEqual("NOT_RUN", suite["execution"])
        self.assertEqual({f"GAME-{n:02d}" for n in range(1, 13)}, {c["id"] for c in suite["scenarios"]})
        self.assertEqual(set(SKILLS), {c["skill"] for c in suite["scenarios"]})
        for case in suite["scenarios"]:
            self.assertIn(case["type"], {"positive", "negative"})
            self.assertTrue(case["prompt"].strip())
            self.assertTrue(case["expected"].strip())
            self.assertTrue(case["prohibited"].strip())


class ContentCoverageChecker(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.commit = "a" * 40
        self.baseline = {
            "schemaVersion": 1, "gameId": "test-game", "revision": "approved-v1",
            "sourceSha": "b" * 40,
            "requirements": [
                {"id": "GP-001", "priority": "MUST", "description": "Loop",
                 "requiredEvidenceKinds": ["source", "runtime"], "cutDecision": None},
                {"id": "LV-002", "priority": "OPTIONAL", "description": "Bonus level",
                 "requiredEvidenceKinds": ["source", "runtime"], "cutDecision": None}
            ]
        }
        self.manifest = {
            "schemaVersion": 1, "gameId": "test-game", "gameSourceSha": self.commit,
            "baselineSha256": None,
            "rows": [
                {"id": "GP-001", "status": "VERIFIED", "sourceSha": self.commit, "evidence": []},
                {"id": "LV-002", "status": "OPTIONAL_MISSING", "sourceSha": self.commit, "evidence": []}
            ]
        }
        for kind in ("source", "runtime"):
            path = f"evidence/GP-001-{kind}.txt"
            absolute = self.root / path
            absolute.parent.mkdir(parents=True, exist_ok=True)
            absolute.write_text(f"test evidence: {kind}", encoding="utf-8")
            self.manifest["rows"][0]["evidence"].append({
                "kind": kind, "path": path, "sha256": module.sha256(absolute)
            })

    def check(self):
        data = json.dumps(self.baseline, ensure_ascii=False, sort_keys=True).encode()
        self.manifest["baselineSha256"] = hashlib.sha256(data).hexdigest()
        return module.inspect(self.baseline, self.manifest, self.root, self.manifest["baselineSha256"])

    def test_valid_record_does_not_prove_gameplay(self):
        result = self.check()
        self.assertEqual("STRUCTURAL_RECORD_COMPLETE", result["status"])
        self.assertEqual(2, result["verifiedEvidenceFiles"])
        self.assertFalse(result["runtimeObserved"])
        self.assertFalse(result["contentCompleteAttested"])
        self.assertFalse(result["releaseReady"])

    def test_missing_requirement_row_fails(self):
        self.manifest["rows"].pop(0)
        self.assertTrue(any("missing coverage row" in x for x in self.check()["errors"]))

    def test_duplicate_and_unknown_ids_fail(self):
        self.manifest["rows"].append(copy.deepcopy(self.manifest["rows"][0]))
        self.assertTrue(any("duplicate requirement id" in x for x in self.check()["errors"]))
        self.manifest["rows"][-1]["id"] = "XX-999"
        self.assertTrue(any("unknown requirement id" in x for x in self.check()["errors"]))

    def test_missing_must_cannot_be_reclassified_as_optional(self):
        self.manifest["rows"][0]["status"] = "OPTIONAL_MISSING"
        self.assertTrue(any("unmet MUST" in x for x in self.check()["errors"]))

    def test_missing_runtime_receipt_fails(self):
        self.manifest["rows"][0]["evidence"] = [self.manifest["rows"][0]["evidence"][0]]
        self.assertTrue(any("missing required evidence kind runtime" in x for x in self.check()["errors"]))

    def test_stale_game_sha_fails(self):
        self.manifest["rows"][0]["sourceSha"] = "c" * 40
        self.assertTrue(any("stale or mismatched" in x for x in self.check()["errors"]))

    def test_changed_file_sha_fails(self):
        (self.root / "evidence/GP-001-runtime.txt").write_text("changed", encoding="utf-8")
        self.assertTrue(any("SHA-256 mismatch" in x for x in self.check()["errors"]))

    def test_outside_path_and_symlink_are_rejected(self):
        entry = self.manifest["rows"][0]["evidence"][0]
        entry["path"] = "../outside.txt"
        self.assertTrue(any("missing/unsafe" in x for x in self.check()["errors"]))
        entry["path"] = "C:\\secret\\data"
        self.assertTrue(any("missing/unsafe" in x for x in self.check()["errors"]))
        link = self.root / "shortcut.txt"
        try:
            link.symlink_to(self.root / "evidence/GP-001-source.txt")
        except (OSError, NotImplementedError):
            return
        entry["path"] = "shortcut.txt"
        self.assertTrue(any("missing/unsafe" in x for x in self.check()["errors"]))

    def test_silent_cut_without_approved_baseline_fails(self):
        self.manifest["rows"][0]["status"] = "INTENTIONALLY_CUT"
        self.assertTrue(any("unmet MUST" in x or "cut without" in x for x in self.check()["errors"]))

    def test_cut_decision_reference_checked_but_not_authorized(self):
        self.baseline["requirements"][0]["priority"] = "CUT"
        doc = self.root / "approvals" / "cut.txt"
        doc.parent.mkdir()
        doc.write_text("example decision file, not authenticated", encoding="utf-8")
        self.baseline["requirements"][0]["cutDecision"] = {
            "path": "approvals/cut.txt", "sha256": module.sha256(doc)
        }
        self.manifest["rows"][0]["status"] = "INTENTIONALLY_CUT"
        self.manifest["rows"][0]["evidence"] = []
        self.assertEqual("STRUCTURAL_RECORD_COMPLETE", self.check()["status"])
        self.assertFalse(self.check()["cutAuthorizationAttested"])
        doc.write_text("tampered", encoding="utf-8")
        self.assertTrue(any("CUT decision hash mismatch" in x for x in self.check()["errors"]))

    def test_invalid_nested_types_fail_closed_without_traceback(self):
        mutations = [
            lambda x: x["requirements"][0].__setitem__("priority", []),
            lambda x: x["requirements"][0].__setitem__("requiredEvidenceKinds", [[]]),
            lambda x: x["requirements"][0].__setitem__("id", []),
        ]
        for modify in mutations:
            with self.subTest(modify=modify):
                b = copy.deepcopy(self.baseline)
                modify(b)
                digest = hashlib.sha256(json.dumps(b).encode()).hexdigest()
                self.assertEqual("INVALID", module.inspect(b, self.manifest, self.root, digest)["status"])

    def test_cli_is_read_only_and_rejects_incomplete(self):
        baseline_file = self.root / "docs/accepted-content-baseline.json"
        manifest_file = self.root / "artifacts/content-coverage.json"
        baseline_file.parent.mkdir()
        manifest_file.parent.mkdir()
        raw = json.dumps(self.baseline).encode()
        baseline_file.write_bytes(raw)
        self.manifest["baselineSha256"] = hashlib.sha256(raw).hexdigest()
        manifest_file.write_text(json.dumps(self.manifest), encoding="utf-8")
        command = [sys.executable, str(SCRIPT), "--project", str(self.root), "--json"]
        result = subprocess.run(command, text=True, capture_output=True)
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertFalse(json.loads(result.stdout)["contentCompleteAttested"])
        before = manifest_file.read_bytes()
        self.manifest["rows"][0]["status"] = "MISSING"
        manifest_file.write_text(json.dumps(self.manifest), encoding="utf-8")
        fail = subprocess.run(command, text=True, capture_output=True)
        self.assertEqual(1, fail.returncode)
        self.assertEqual(json.loads(self.manifest_json()), json.loads(manifest_file.read_text()))
        self.assertNotEqual(before, manifest_file.read_bytes())

    def manifest_json(self):
        return json.dumps(self.manifest)


if __name__ == "__main__":
    unittest.main()
