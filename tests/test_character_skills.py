"""Offline regression coverage for the two first-party character-art Skills."""

import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SKILLS = ("character-design", "character-consistency-qa")


class CharacterArtSkillContracts(unittest.TestCase):
    def test_skill_names_and_positive_negative_activation(self):
        catalog = (ROOT / "docs/SKILL_CATALOG.md").read_text(encoding="utf-8")
        foundation = json.loads((ROOT / "evals/cases/foundation.json").read_text(encoding="utf-8"))
        for name in SKILLS:
            path = ROOT / "skills/domain" / name / "SKILL.md"
            body = path.read_text(encoding="utf-8")
            self.assertTrue(body.startswith("---\nname: " + name + "\n"), name)
            self.assertIn(f"| {name} |", catalog)
            cases = [case for case in foundation["cases"] if case["skill"] == name]
            self.assertEqual(len(cases), 1, name)
            for variant in ("positive", "negative"):
                self.assertTrue(cases[0][variant]["prompt"].strip())
                self.assertTrue(cases[0][variant]["expected_behavior"].strip())
            self.assertTrue(cases[0]["prohibited_behavior"])

    def test_character_bible_is_unapproved_example_not_fake_asset(self):
        path = ROOT / "skills/domain/character-design/references/character-bible.example.json"
        card = json.loads(path.read_text(encoding="utf-8"))
        self.assertEqual(card["status"], "DRAFT_NO_ASSETS")
        self.assertIsNone(card["canonicalReference"]["path"])
        self.assertIsNone(card["canonicalReference"]["sha256"])
        self.assertEqual(card["requiredViews"], ["front", "three-quarter", "side", "back"])
        self.assertEqual(card["artifacts"], [])
        self.assertIn("forbiddenDrift", card["identityLocks"])

    def test_report_is_not_fabricated_visual_pass(self):
        path = ROOT / "skills/domain/character-consistency-qa/references/report.example.json"
        report = json.loads(path.read_text(encoding="utf-8"))
        self.assertEqual(report["status"], "EXAMPLE_NOT_EXECUTED")
        self.assertEqual(report["overall"], "BLOCKED")
        self.assertFalse(report["reviewer"]["observedOriginalPixels"])
        self.assertEqual(report["gates"]["artistic"], "NOT_RUN")
        self.assertEqual(report["gates"]["runtime"], "NOT_RUN")

    def test_ten_prepared_scenarios_include_both_skills(self):
        suite = json.loads((ROOT / "evals/cases/character-art/scenarios.json").read_text(encoding="utf-8"))
        self.assertEqual(suite["schema"], 1)
        self.assertEqual(suite["status"], "prepared-not-executed")
        scenarios = suite["scenarios"]
        self.assertEqual({case["id"] for case in scenarios},
                         {f"CHAR-{number:02d}" for number in range(1, 11)})
        self.assertEqual({case["skill"] for case in scenarios}, set(SKILLS))
        for case in scenarios:
            for field in ("prompt", "expected", "prohibited"):
                self.assertTrue(case[field].strip(), (case["id"], field))

    def test_separate_art_and_runtime_acceptance(self):
        qa = (ROOT / "skills/domain/character-consistency-qa/SKILL.md").read_text(encoding="utf-8")
        design = (ROOT / "skills/domain/character-design/SKILL.md").read_text(encoding="utf-8")
        for gate in ("MECHANICAL", "ARTISTIC", "RUNTIME", "RIGHTS"):
            self.assertIn(gate, qa)
        self.assertIn("NOT_RUN", qa)
        self.assertIn("GENERATION_BLOCKED", design)
        self.assertIn("READY_FOR_CONSISTENCY_QA", design)


if __name__ == "__main__":
    unittest.main()
