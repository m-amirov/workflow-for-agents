"""Static regression coverage for the source-bound Stage 8 Skill migration."""
from __future__ import annotations

import json
from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
SOURCE_SHA = "c8cc13bd3852409be93097ee823e9cd35e512b73"
SKILLS = {
    "audit", "audit-repair-loop", "ceos-continue", "fix", "verification",
    "release", "visual-qa", "video-production", "romance-narrative",
    "narrative-dialogue-editor", "narrative-continuity-engine",
    "reader-experience-review", "production-art", "prod-check", "incident-analysis",
}
DESCRIPTION_TRIGGERS = {
    "audit": "audit",
    "audit-repair-loop": "audit",
    "ceos-continue": "explicit CEOS",
    "fix": "bug",
    "verification": "verify",
    "release": "release",
    "visual-qa": "visual",
    "video-production": "video",
    "romance-narrative": "romance",
    "narrative-dialogue-editor": "dialogue",
    "narrative-continuity-engine": "continuity",
    "reader-experience-review": "reader",
    "production-art": "art",
    "prod-check": "production",
    "incident-analysis": "incident",
}


def skill_path(name: str) -> Path:
    matches = list((ROOT / "skills").rglob(name + "/SKILL.md"))
    if len(matches) != 1:
        raise AssertionError(f"expected one Skill path for {name}, got {matches}")
    return matches[0]


class Stage8MigrationTests(unittest.TestCase):
    def test_all_fifteen_skills_have_source_bound_metadata_and_trigger_descriptions(self) -> None:
        for name in SKILLS:
            content = skill_path(name).read_text(encoding="utf-8")
            self.assertIn(f"name: {name}", content)
            self.assertIn(f"source_sha: {SOURCE_SHA}", content)
            self.assertIn("migration: ceos", content)
            frontmatter = content.split("---", 2)[1]
            description = re.search(r"^description:.*?(?=^metadata:|^---$)", frontmatter, re.MULTILINE | re.DOTALL)
            self.assertIsNotNone(description, name)
            self.assertIn(DESCRIPTION_TRIGGERS[name].lower(), description.group(0).lower(), name)

    def test_autonomous_skills_do_not_require_ceos_cli_or_legacy_routes(self) -> None:
        autonomous = SKILLS - {"ceos-continue"}
        for name in autonomous:
            content = skill_path(name).read_text(encoding="utf-8").lower()
            self.assertNotIn("required ceos cli", content, name)
            self.assertNotIn("chatgpt-web/", content, name)
            self.assertNotRegex(content, r"\bceos\s+(context|run|checkpoint|resume)\b.*required", name)

    def test_ceos_continue_is_explicit_and_fail_closed(self) -> None:
        content = skill_path("ceos-continue").read_text(encoding="utf-8")
        self.assertIn("explicitly", content.lower())
        self.assertIn("ordinary", content.lower())
        self.assertIn("BLOCKED", content)
        self.assertIn("persisted run state", content.lower())

    def test_production_art_preserves_real_asset_and_acceptance_boundaries(self) -> None:
        content = skill_path("production-art").read_text(encoding="utf-8").lower()
        for phrase in ("source-bound", "provenance", "sha-256", "asset-to-scene", "mechanical", "artistic", "platform", "blocked", "placeholder"):
            self.assertIn(phrase, content)

    def test_eval_suite_covers_exactly_the_fifteen_skills(self) -> None:
        suite = json.loads((ROOT / "evals" / "cases" / "ceos-migrated.json").read_text(encoding="utf-8"))
        self.assertEqual(SOURCE_SHA, suite["source_sha"])
        self.assertEqual(SKILLS, {case["skill"] for case in suite["scenarios"]})
        self.assertTrue(all(case["status"] in {"prepared", "executed", "blocked", "not-run"} for case in suite["scenarios"]))

    def test_migration_report_lists_all_fifteen_and_exact_source(self) -> None:
        report = (ROOT / "docs" / "migrations" / "2026-11-16-stage-8-ceos-skills-migration.md").read_text(encoding="utf-8")
        self.assertIn(SOURCE_SHA, report)
        for name in SKILLS:
            self.assertIn(f"`{name}`", report)


if __name__ == "__main__":
    unittest.main()
