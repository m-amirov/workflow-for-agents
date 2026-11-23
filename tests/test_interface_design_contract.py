"""Static contract coverage for the evidence-gated UI design workflow."""
from __future__ import annotations

import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
NAMES = {
    "design-reference-research",
    "ui-component-reuse",
    "signature-visual-treatment",
    "design-variant-selector",
    "design-system-governance",
}


class InterfaceDesignContractTests(unittest.TestCase):
    def test_new_skills_are_discoverable_and_scenarios_are_bipolar(self) -> None:
        catalog = (ROOT / "docs" / "SKILL_CATALOG.md").read_text(encoding="utf-8")
        foundation = json.loads((ROOT / "evals" / "cases" / "foundation.json").read_text(encoding="utf-8"))
        covered = {case["skill"] for case in foundation["cases"]}
        suite = json.loads((ROOT / "evals" / "cases" / "interface-design" / "scenarios.json").read_text(encoding="utf-8"))
        self.assertEqual("prepared", suite["status"])
        ids = [case["id"] for case in suite["scenarios"]]
        self.assertEqual(len(ids), len(set(ids)))
        for name in NAMES:
            path = ROOT / "skills" / "design" / name / "SKILL.md"
            body = path.read_text(encoding="utf-8")
            self.assertIn("name: " + name, body)
            self.assertIn(name + " |", catalog)
            self.assertIn(name, covered)
            cases = [case for case in suite["scenarios"] if case["skill"] == name]
            self.assertTrue({"positive", "negative"} <= {case["kind"] for case in cases})
            for case in cases:
                self.assertTrue(case["prompt"].strip())
                self.assertTrue(case["expected_behavior"].strip())

    def test_project_authority_and_real_visual_evidence_are_explicit(self) -> None:
        rules = (ROOT / "rules" / "design.md").read_text(encoding="utf-8")
        playbook = (ROOT / "playbooks" / "interface-design.md").read_text(encoding="utf-8")
        self.assertIn("DESIGN.md", rules)
        self.assertIn("Ludory", rules)
        self.assertIn("canonical", rules)
        self.assertIn("prefers-reduced-motion", rules)
        self.assertIn("visual-qa", playbook)
        self.assertIn("project-local", playbook)
        self.assertIn("owner", playbook)
        self.assertIn("NOT VERIFIED", (ROOT / "skills/design/design-reference-research/SKILL.md").read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
