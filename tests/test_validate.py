"""Regression tests for the Skill and Markdown validator (stdlib only)."""
from __future__ import annotations

import importlib.util
from pathlib import Path
import shutil
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("skill_validator", ROOT / "scripts" / "validate.py")
assert SPEC is not None and SPEC.loader is not None
module = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(module)


class RepositoryValidationTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory(prefix="workflow-agents-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / "repo"
        shutil.copytree(
            ROOT,
            self.root,
            ignore=shutil.ignore_patterns(".git", "__pycache__", ".venv", "node_modules"),
        )

    def failures(self) -> list[str]:
        errors, _ = module.validate_repository(self.root)
        return errors

    def test_repository_is_valid(self) -> None:
        self.assertEqual([], self.failures())

    def test_detects_invalid_name(self) -> None:
        skill = self.root / "skills" / "core" / "task-planning" / "SKILL.md"
        skill.write_text(skill.read_text(encoding="utf-8").replace(
            "name: task-planning", "name: Invalid Name"
        ), encoding="utf-8")
        self.assertTrue(any("invalid name" in issue for issue in self.failures()))

    def test_detects_duplicate_name(self) -> None:
        original = self.root / "skills" / "core" / "task-planning"
        duplicate = self.root / "skills" / "testing" / "task-planning"
        shutil.copytree(original, duplicate)
        self.assertTrue(any("duplicate skill name" in issue for issue in self.failures()))

    def test_detects_broken_internal_link(self) -> None:
        new_doc = self.root / "broken.md"
        new_doc.write_text("[Broken link](docs/does-not-exist.md)\n", encoding="utf-8")
        self.assertTrue(any("broken relative link" in issue for issue in self.failures()))

    def test_detects_missing_catalog_entry(self) -> None:
        catalog = self.root / "docs" / "SKILL_CATALOG.md"
        catalog.write_text(
            catalog.read_text(encoding="utf-8").replace(
                "| Development | git-workflow | Main-first:",
                "| Development | git-workflow | Main-first:"
            ).replace("git-workflow | Main-first: работа в main, merge проверенного результата и очистка своих временных веток | implemented |",
                      "git-workflow | Main-first: работа в main, merge проверенного результата и очистка своих временных веток | planned |"),
            encoding="utf-8",
        )
        self.assertTrue(any("catalog is not marked implemented" in issue for issue in self.failures()))

    def test_detects_missing_description(self) -> None:
        skill = self.root / "skills" / "core" / "task-planning" / "SKILL.md"
        content = skill.read_text(encoding="utf-8")
        content = content.replace("description: >-", "description: ''\n  #")
        skill.write_text(content, encoding="utf-8")
        self.assertTrue(any("description must contain" in issue for issue in self.failures()))


if __name__ == "__main__":
    unittest.main()

