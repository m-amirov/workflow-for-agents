"""Offline policy/regression tests for Stage 9B; not agent-execution evidence."""
from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
ROUTER = ROOT / "scripts/task_routing.py"
CASES = ROOT / "evals/cases/task-routing/scenarios.json"


def load(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


router = load("adaptive_task_router", ROUTER)
validator = load("task_routing_validator", ROOT / "scripts/validate.py")


class AdaptiveTaskRoutingTests(unittest.TestCase):
    def test_small_low_is_lean(self):
        r = router.route_task("FEATURE", "SMALL", "LOW", docs_impact="NONE")
        self.assertEqual("ROUTED", r["status"])
        self.assertEqual("NOT_REQUIRED", r["reviewer"])
        self.assertEqual("NOT_REQUIRED", r["architect"])
        self.assertEqual("NO_UPDATE_REQUIRED", r["documentation_action"])
        self.assertFalse(r["user_gate"])

    def test_high_risk_small_mandates_reviewer(self):
        r = router.route_task("FEATURE", "SMALL", "HIGH", docs_impact="LOCAL")
        self.assertEqual("REQUIRED", r["reviewer"])
        self.assertEqual("HIGH", r["risk"])
        self.assertEqual("UPDATE_IN_CHANGE", r["documentation_action"])

    def test_explicit_low_is_escalated_by_payment_evidence(self):
        r = router.route_task("BUGFIX", "SMALL", "LOW", ["payments"], "LOCAL")
        self.assertEqual("HIGH", r["risk"])
        self.assertTrue(r["risk_escalated"])
        self.assertEqual("REQUIRED", r["reviewer"])
        self.assertIn("REPRODUCE_ROOT_CAUSE_REGRESSION", r["quality_gates"])

    def test_size_does_not_change_risk(self):
        r = router.route_task("FEATURE", "LARGE", "LOW", docs_impact="SIGNIFICANT")
        self.assertEqual("LOW", r["risk"])
        self.assertEqual("RECOMMENDED", r["architect"])
        self.assertEqual("REQUIRED", r["reviewer"])
        self.assertEqual("CONSOLIDATE", r["documentation_action"])
        self.assertEqual("OPTIONAL", r["documentation_specialist"])

    def test_large_bugfix_does_not_force_architect_without_systemic_evidence(self):
        r = router.route_task("BUGFIX", "LARGE", "LOW", docs_impact="LOCAL")
        self.assertEqual("NOT_REQUIRED", r["architect"])
        self.assertEqual("REQUIRED", r["reviewer"])

    def test_systemic_bugfix_recommends_architect(self):
        r = router.route_task("BUGFIX", "MEDIUM", "AUTO", ["systemic-root-cause"], "LOCAL")
        self.assertEqual("MEDIUM", r["risk"])
        self.assertEqual("RECOMMENDED", r["architect"])

    def test_new_small_project_requires_design_and_review(self):
        r = router.route_task("NEW_PROJECT", "SMALL", "LOW", docs_impact="LOCAL")
        self.assertTrue(r["user_gate"])
        self.assertEqual("RECOMMENDED", r["architect"])
        self.assertEqual("REQUIRED", r["reviewer"])
        self.assertEqual("FINAL_CONSOLIDATION", r["documentation_action"])

    def test_destructive_write_requires_decision_not_automatic_execution(self):
        r = router.route_task("CHANGE", "SMALL", "LOW", ["production-write"], "LOCAL")
        self.assertTrue(r["user_gate"])
        self.assertEqual("HIGH", r["risk"])
        self.assertEqual("NOT_PERFORMED", r["execution"])

    def test_unknown_risk_fails_closed_for_shortcut(self):
        r = router.route_task("REFACTOR", "SMALL", "AUTO", docs_impact="UNKNOWN")
        self.assertEqual("NEEDS_RISK_ASSESSMENT", r["status"])
        self.assertEqual("UNASSESSED", r["risk"])
        self.assertEqual("REQUIRED", r["reviewer"])
        self.assertEqual("ASSESS_BEFORE_ACCEPTANCE", r["documentation_action"])
        self.assertFalse(r["completion_allowed"])

    def test_doc_impact_unknown_never_infers_docs_not_needed(self):
        r = router.route_task("FEATURE", "SMALL", "LOW")
        self.assertEqual("ASSESS_BEFORE_ACCEPTANCE", r["documentation_action"])

    def test_invalid_signal_or_string_is_rejected(self):
        with self.assertRaises(ValueError):
            router.route_task("FEATURE", "SMALL", "LOW", ["make-everything-safe"])
        with self.assertRaises(ValueError):
            router.route_task("FEATURE", "SMALL", "LOW", "payments")

    def test_invalid_metadata_fails_closed(self):
        for value in ("SECURITY", "", None):
            with self.subTest(value=value), self.assertRaises(ValueError):
                router.route_task("FEATURE", "SMALL", value)

    def test_attempt_gate_protects_external_failure_budget(self):
        r = router.attempt_gate("developer", 1, "EXTERNAL_BLOCKER")
        self.assertEqual("BLOCKED_EXTERNAL", r["status"])
        self.assertEqual(1, r["used_failures"])

    def test_attempt_gate_after_two_failures_requires_decision(self):
        self.assertEqual("NEW_EVIDENCE_REQUIRED", router.attempt_gate(
            "developer", 0, "FAILURE")["status"])
        self.assertEqual("USER_DECISION_REQUIRED", router.attempt_gate(
            "developer", 1, "FAILURE", new_evidence=True)["status"])
        self.assertEqual("USER_DECISION_REQUIRED", router.attempt_gate(
            "developer", 2, "INSPECT", new_evidence=True)["status"])

    def test_separate_attempt_budgets_and_no_duplicate_attempt(self):
        self.assertEqual(3, router.ATTEMPT_LIMITS["reviewer-changes-required"])
        self.assertEqual(3, router.ATTEMPT_LIMITS["bugfix-hypothesis"])
        self.assertEqual("NEW_EVIDENCE_REQUIRED", router.attempt_gate(
            "bugfix-hypothesis", 1, "INSPECT", new_evidence=False)["status"])
        self.assertEqual("ATTEMPT_AVAILABLE", router.attempt_gate(
            "bugfix-hypothesis", 1, "INSPECT", new_evidence=True)["status"])
        self.assertEqual("USER_DECISION_REQUIRED", router.attempt_gate(
            "reviewer-changes-required", 2, "FAILURE", new_evidence=True)["status"])

    def test_success_resets_counter_but_not_history(self):
        self.assertEqual({"status": "RESET", "used_failures": 0, "limit": 2},
                         router.attempt_gate("developer", 1, "SUCCESS"))

    def test_no_model_selection_or_runtime_claim(self):
        r = router.route_task("FEATURE", "MEDIUM", "MEDIUM", docs_impact="LOCAL")
        self.assertEqual("NOT_PERFORMED", r["model_selection"])
        self.assertEqual("NOT_VERIFIED", r["release_readiness"])
        self.assertFalse(r["completion_allowed"])

    def test_cli_json_is_read_only_and_routed(self):
        cmd = [sys.executable, str(ROUTER), "--type", "BUGFIX", "--size", "SMALL",
               "--risk", "HIGH", "--signal", "authorization", "--docs-impact", "LOCAL"]
        proc = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, check=True)
        data = json.loads(proc.stdout)
        self.assertEqual("REQUIRED", data["reviewer"])
        self.assertEqual("HIGH", data["risk"])

    def test_eval_suite_contains_12_unique_scenarios(self):
        suite = json.loads(CASES.read_text(encoding="utf-8"))
        self.assertEqual({f"TR-{i:02d}" for i in range(1, 13)},
                         {case["id"] for case in suite["scenarios"]})
        self.assertEqual(12, len(suite["scenarios"]))
        self.assertTrue(all(c["status"] == "prepared" and c["result"] == "NOT RUN"
                            for c in suite["scenarios"]))

    def test_structural_validation_accepts_suite(self):
        errors, count = validator.validate_task_routing_evals(ROOT)
        self.assertEqual([], errors)
        self.assertEqual(12, count)

    def test_expected_route_outputs_for_scenarios(self):
        suite = json.loads(CASES.read_text(encoding="utf-8"))
        for case in suite["scenarios"]:
            if not case["should_route"]:
                continue
            with self.subTest(case=case["id"]):
                route = router.route_task(**case["input"])
                for key, value in case["expected"].items():
                    self.assertEqual(value, route[key])

    def test_external_evals_are_not_fabricated_pass(self):
        suite = json.loads(CASES.read_text(encoding="utf-8"))
        self.assertTrue(all(case["status"] == "prepared" and case["result"] == "NOT RUN"
                            for case in suite["scenarios"]))


if __name__ == "__main__":
    unittest.main()
