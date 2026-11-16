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
    old, new = {c.id: c for c in before}, {c.id: c for c in after}
    if set(old) != set(new): raise ValueError("dataset_mismatch")
    improved = regressed = 0
    for identity, prior in old.items():
        current = new[identity]
        if (prior.label, prior.source, prior.partial) != (current.label, current.source, current.partial): raise ValueError("ground_truth_mismatch")
        if prior.source not in TRUSTED or prior.label is None or prior.partial: continue
        improved += prior.prediction != prior.label and current.prediction == current.label
        regressed += prior.prediction == prior.label and current.prediction != current.label
    return {"improved": improved, "regressed": regressed}

class ClassificationQualityContractTests(unittest.TestCase):
    def test_cq03_cq04_unverified_or_self_label_is_excluded(self):
        result = grade([Case("a", "yes"), Case("b", "yes", "yes", "model")])
        self.assertEqual(result["labeled"], 0); self.assertIsNone(result["accuracy"])
    def test_cq05_duplicate_ids_fail_closed(self):
        with self.assertRaisesRegex(ValueError, "duplicate_id"): grade([Case("a", "x"), Case("a", "x")])
    def test_cq06_cq07_comparison_rejects_label_or_dataset_drift(self):
        base = [Case("a", "x", "x", "expert")]
        with self.assertRaisesRegex(ValueError, "ground_truth_mismatch"): compare(base, [Case("a", "x", "y", "expert")])
        with self.assertRaisesRegex(ValueError, "dataset_mismatch"): compare(base, [])
    def test_cq08_counts_improvement_and_regression(self):
        before = [Case("a", "x", "y", "expert"), Case("b", "y", "y", "expert")]
        self.assertEqual(compare(before, [Case("a", "y", "y", "expert"), Case("b", "x", "y", "expert")]), {"improved": 1, "regressed": 1})
    def test_cq09_partial_label_is_not_full_accuracy(self):
        self.assertEqual(grade([Case("a", ["root", "leaf"], ["root"], "review", True)])["labeled"], 0)
    def test_cq10_no_verified_labels_cannot_pass_a_gate(self):
        result = grade([Case("a", "x")]); self.assertIsNone(result["accuracy"]); self.assertEqual(result["coverage"], 0)
    def test_cq11_public_report_excludes_private_content(self):
        result = grade([Case("a", "x", "x", "expert", private="personal request")])
        self.assertNotIn("personal request", repr({k: v for k, v in result.items() if k != "rows"}))
