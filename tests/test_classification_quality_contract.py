"""Independent synthetic contracts backing classification-quality CQ-03..CQ-11."""
from __future__ import annotations
from dataclasses import dataclass
import unittest

TRUSTED = {"expert", "review"}

@dataclass(frozen=True)
class Case:
    id: str
    prediction: object
    label: object | None = None
    source: str | None = None
    partial: bool = False
    private: str | None = None

def grade(cases: list[Case]) -> dict:
    seen: set[str] = set(); rows = []
    for case in cases:
        if case.id in seen: raise ValueError("duplicate_id")
        seen.add(case.id)
        verified = case.source in TRUSTED and case.label is not None and not case.partial
        rows.append((case.id, "correct" if verified and case.prediction == case.label else "incorrect" if verified else "UNVERIFIED"))
    labeled = [row for row in rows if row[1] != "UNVERIFIED"]
    return {"rows": rows, "labeled": len(labeled), "correct": sum(x[1] == "correct" for x in labeled),
            "accuracy": sum(x[1] == "correct" for x in labeled) / len(labeled) if labeled else None,
            "coverage": len(labeled) / len(rows) if rows else None}

def compare(before: list[Case], after: list[Case]) -> dict:
    def unique_index(cases: list[Case]) -> dict[str, Case]:
        indexed: dict[str, Case] = {}
        for case in cases:
            if case.id in indexed:
                raise ValueError("duplicate_id")
            indexed[case.id] = case
        return indexed

    old, new = unique_index(before), unique_index(after)
    if set(old) != set(new): raise ValueError("dataset_mismatch")
    improved = regressed = 0
    for identity, prior in old.items():
        current = new[identity]
        if (prior.label, prior.source, prior.partial) != (current.label, current.source, current.partial): raise ValueError("ground_truth_mismatch")
        if prior.source not in TRUSTED or prior.label is None or prior.partial: continue
        improved += prior.prediction != prior.label and current.prediction == current.label
        regressed += prior.prediction == prior.label and current.prediction != current.label
    return {"improved": improved, "regressed": regressed}

def quality_gate(result: dict, comparison: dict, *, minimum_verified: int,
                 minimum_coverage: float, maximum_regressions: int) -> str:
    """Synthetic project-defined gate; thresholds are supplied by the caller."""
    if result["labeled"] < minimum_verified or result["coverage"] < minimum_coverage:
        return "BLOCKED"
    if comparison["regressed"] > maximum_regressions:
        return "FAIL"
    return "PASS"

class ClassificationQualityContractTests(unittest.TestCase):
    def test_cq03_cq04_unverified_or_self_label_is_excluded(self):
        result = grade([Case("a", "yes"), Case("b", "yes", "yes", "model")])
        self.assertEqual(result["labeled"], 0); self.assertIsNone(result["accuracy"])
    def test_cq05_duplicate_ids_fail_closed(self):
        with self.assertRaisesRegex(ValueError, "duplicate_id"): grade([Case("a", "x"), Case("a", "x")])
    def test_cq06_changed_verified_label_blocks_comparison(self):
        base = [Case("a", "x", "x", "expert")]
        with self.assertRaisesRegex(ValueError, "ground_truth_mismatch"): compare(base, [Case("a", "x", "y", "expert")])

    def test_cq07_different_case_ids_block_comparison(self):
        base = [Case("a", "x", "x", "expert")]
        with self.assertRaisesRegex(ValueError, "dataset_mismatch"): compare(base, [])

    def test_compare_blocks_duplicate_baseline_id_before_indexing(self):
        with self.assertRaisesRegex(ValueError, "duplicate_id"):
            compare([Case("a", "x"), Case("a", "y")], [Case("a", "x")])

    def test_compare_blocks_duplicate_candidate_id_before_indexing(self):
        with self.assertRaisesRegex(ValueError, "duplicate_id"):
            compare([Case("a", "x")], [Case("a", "x"), Case("a", "y")])

    def test_compare_accepts_matching_unique_dataset(self):
        cases = [Case("a", "x", "x", "expert")]
        self.assertEqual(compare(cases, cases), {"improved": 0, "regressed": 0})
    def test_cq08_counts_improvement_and_regression(self):
        before = [Case("a", "x", "y", "expert"), Case("b", "y", "y", "expert")]
        self.assertEqual(compare(before, [Case("a", "y", "y", "expert"), Case("b", "x", "y", "expert")]), {"improved": 1, "regressed": 1})
    def test_cq09_partial_label_is_not_full_accuracy(self):
        self.assertEqual(grade([Case("a", ["root", "leaf"], ["root"], "review", True)])["labeled"], 0)
    def test_cq10_no_verified_labels_blocks_gate(self):
        result = grade([Case("a", "x")])
        self.assertEqual(quality_gate(result, {"regressed": 0}, minimum_verified=1,
                                      minimum_coverage=0.5, maximum_regressions=0), "BLOCKED")

    def test_cq10_insufficient_verified_labels_blocks_gate(self):
        result = grade([Case("a", "x", "x", "expert"), Case("b", "x")])
        self.assertEqual(quality_gate(result, {"regressed": 0}, minimum_verified=2,
                                      minimum_coverage=0.5, maximum_regressions=0), "BLOCKED")

    def test_cq10_insufficient_coverage_blocks_gate(self):
        result = grade([Case("a", "x", "x", "expert"), Case("b", "x"), Case("c", "x")])
        self.assertEqual(quality_gate(result, {"regressed": 0}, minimum_verified=1,
                                      minimum_coverage=0.5, maximum_regressions=0), "BLOCKED")

    def test_cq10_excess_regressions_fail_gate(self):
        result = grade([Case("a", "x", "x", "expert"), Case("b", "y", "y", "expert")])
        self.assertEqual(quality_gate(result, {"regressed": 1}, minimum_verified=2,
                                      minimum_coverage=1.0, maximum_regressions=0), "FAIL")

    def test_cq10_sufficient_evidence_and_thresholds_pass_gate(self):
        result = grade([Case("a", "x", "x", "expert"), Case("b", "y", "y", "expert")])
        self.assertEqual(quality_gate(result, {"regressed": 0}, minimum_verified=2,
                                      minimum_coverage=1.0, maximum_regressions=0), "PASS")
    def test_cq11_public_report_excludes_private_content(self):
        result = grade([Case("a", "x", "x", "expert", private="personal request")])
        self.assertNotIn("personal request", repr({k: v for k, v in result.items() if k != "rows"}))
