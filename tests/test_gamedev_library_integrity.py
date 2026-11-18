"""Pinned, offline integrity and deduplication contracts for imported gamedev Skills."""
import hashlib
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "docs/migrations/gamedev-library-import-manifest.json"
SOURCE = "c6ca6c41c839b68319ffc08430b99ab768debc32"


class ImportedGamedevIntegrity(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
        cls.imports = cls.manifest["source_files"]

    def test_full_source_coverage_and_exact_dedup(self):
        m = self.manifest
        self.assertEqual(m["source_sha"], SOURCE)
        self.assertEqual(m["source_skill_count"], 79)
        self.assertEqual(len(m["new_skills"]), 78)
        self.assertEqual(m["merged_skills"], {"create-game-assets": "production-art"})
        self.assertEqual(m["merged_router_into"], "task-planning")
        self.assertEqual(m["copied_source_file_count"], 292)
        self.assertEqual(len(self.imports), 292)
        self.assertEqual(m["ignored_source_paths"], [
            ".github/workflows/ci.yml", ".github/workflows/pages.yml", ".gitignore"
        ])

    def test_all_copied_files_exist_and_match_bytes(self):
        targets = []
        for item in self.imports:
            path = ROOT / item["target"]
            self.assertTrue(path.is_relative_to(ROOT), item["target"])
            self.assertFalse(path.is_symlink(), item["target"])
            self.assertTrue(path.is_file(), item["target"])
            digest = hashlib.sha256(path.read_bytes()).hexdigest()
            self.assertEqual(digest, item["target_sha256"], item["target"])
            self.assertRegex(item["source_sha256"], r"^[0-9a-f]{64}$")
            targets.append(item["target"])
        self.assertEqual(len(targets), len(set(targets)), "two source files mapped to one destination")

    def test_107_unique_skill_names_and_one_art_owner(self):
        names = [path.parent.name for path in (ROOT / "skills").rglob("SKILL.md")]
        self.assertEqual(len(names), 107)
        self.assertEqual(len(names), len(set(names)))
        self.assertNotIn("create-game-assets", names)
        self.assertNotIn("router", names)
        self.assertIn("production-art", names)
        self.assertIn("task-planning", names)

    def test_router_and_art_content_is_preserved_as_references(self):
        path_to_source = {item["source"]: item["target"] for item in self.imports}
        self.assertEqual(path_to_source["router/SKILL.md"],
                         "skills/core/task-planning/references/gamedev-router/UPSTREAM.md")
        self.assertEqual(path_to_source["skills/disciplines/create-game-assets/SKILL.md"],
                         "skills/domain/production-art/references/gamedev-create-game-assets/UPSTREAM.md")
        for source in [
            "skills/disciplines/create-game-assets/scripts/asset_report.py",
            "skills/disciplines/create-game-assets/scripts/build_preview_sheet.py",
            "skills/genres/visual-novel/SKILL.md",
            "skills/disciplines/save-systems/SKILL.md",
        ]:
            self.assertIn(source, path_to_source)
            self.assertTrue((ROOT / path_to_source[source]).is_file())

    def test_upstream_license_and_notice_preserved(self):
        base = ROOT / "third_party/awesome-gamedev-agent-skills"
        self.assertIn("Apache License", (base / "LICENSE").read_text(encoding="utf-8"))
        self.assertIn("Abhishek Barali", (base / "NOTICE").read_text(encoding="utf-8"))
        self.assertIn("NOT RUN", self.manifest["execution"])

    def test_activation_cases_prepared_for_78_new_skills(self):
        catalog = (ROOT / "docs/SKILL_CATALOG.md").read_text(encoding="utf-8")
        cases = json.loads((ROOT / "evals/cases/foundation.json").read_text(encoding="utf-8"))
        existing = {item["skill"]: item for item in cases["cases"]}
        for name in self.manifest["new_skills"]:
            self.assertIn(name, existing)
            self.assertIn(f"| {name} |", catalog)
            case = existing[name]
            self.assertTrue(case["positive"]["prompt"])
            self.assertTrue(case["negative"]["prompt"])
        self.assertIn("NOT RUN", cases["gamedev_import_note"])


if __name__ == "__main__":
    unittest.main()
