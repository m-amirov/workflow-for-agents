"""Stage 9A static/synthetic checks; not Codex activation evidence."""
from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SKILL = ROOT / "skills/operations/logging-standard/SKILL.md"
REF = SKILL.parent / "references/contracts-and-evals.md"
SUITE = ROOT / "evals/cases/logging-standard/scenarios.json"


def load_validator():
    spec = importlib.util.spec_from_file_location("logging_validator", ROOT / "scripts/validate.py")
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class LoggingStandardTests(unittest.TestCase):
    def test_autonomous_contract_and_trigger(self):
        content = SKILL.read_text(encoding="utf-8")
        self.assertIn("name: logging-standard", content)
        self.assertIn("No CEOS CLI", content)
        self.assertIn("theoretical", content)
        self.assertIn("[incident-analysis]", content)

    def test_key_contracts_present(self):
        content = SKILL.read_text(encoding="utf-8")
        for term in ("trace_id", "request_id", "duration_ms", "error_type",
                     "retry", "fallback", "EVIDENCE_GAP", "non-idempotent",
                     "cookie", "password", "sensitive", "PARTIAL/BLOCKED"):
            with self.subTest(term=term):
                self.assertIn(term, content)

    def test_example_is_synthetic_and_correlated(self):
        reference = REF.read_text(encoding="utf-8")
        records = [json.loads(line) for line in reference.splitlines() if line.startswith('{"event":')]
        self.assertEqual(4, len(records))
        self.assertEqual({"demo-trace"}, {record["trace_id"] for record in records})
        self.assertEqual(2, records[1]["attempt"])
        self.assertEqual("success_degraded", records[-1]["status"])
        self.assertIn("invented", reference)

    def test_suite_has_positive_negative_prepared_status(self):
        data = json.loads(SUITE.read_text(encoding="utf-8"))
        self.assertEqual("logging-standard", data["skill"])
        self.assertEqual({f"LS-{i:02d}" for i in range(1, 11)},
                         {case["id"] for case in data["scenarios"]})
        self.assertEqual(10, len(data["scenarios"]))
        self.assertEqual(6, sum(case["expected_activation"] for case in data["scenarios"]))
        self.assertTrue(all(case["status"] == "prepared" and case["result"] == "NOT RUN"
                            for case in data["scenarios"]))

    def test_validator_accepts_suite(self):
        errors, count = load_validator().validate_logging_standard_evals(ROOT)
        self.assertEqual([], errors)
        self.assertEqual(10, count)

    def test_validator_blocks_duplicate_and_false_pass(self):
        validator = load_validator()
        data = json.loads(SUITE.read_text(encoding="utf-8"))
        data["scenarios"][1]["id"] = "LS-01"
        data["scenarios"][0]["result"] = "PASS"
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "evals/cases/logging-standard"
            path.mkdir(parents=True)
            (path / "scenarios.json").write_text(json.dumps(data), encoding="utf-8")
            errors, _ = validator.validate_logging_standard_evals(Path(folder))
        self.assertTrue(any("duplicate" in e for e in errors))
        self.assertTrue(any("missing LS-02" in e for e in errors))
        self.assertTrue(any("inconsistent execution/result" in e for e in errors))


if __name__ == "__main__":
    unittest.main()
