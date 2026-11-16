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

    def write_pattern(self, name: str, *, title: str = "Проверяемый паттерн",
                      source_sha: str = "a" * 40,
                      context: str = "Контекст описан.") -> Path:
        pattern = self.root / "knowledge" / "patterns" / name
        pattern.write_text(f"""---
title: {title}
status: VERIFIED
source_repository: https://github.com/example/source
source_sha: {source_sha}
reuse_scope: Тестовый сценарий
source_verification: SOURCE_REVIEWED
ci_verification: NOT_RUN
cross_project_verification: NOT_RUN
---

# {title}

## Контекст

{context}

## Механизм

Механизм описан.

## Алгоритм

1. Выполнить проверку.

## Ограничения и антипримеры

Не применять без источника.

## Источники

- [Исходный тест](https://github.com/example/source/blob/{source_sha}/test.md)

## Проверка повторного применения

Проверить ожидаемый отказ.
""", encoding="utf-8")
        return pattern

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

    def test_detects_missing_eval_coverage(self) -> None:
        fixture = self.root / "evals" / "cases" / "foundation.json"
        fixture.unlink()
        self.assertTrue(any("Missing foundation eval" in issue for issue in self.failures()))

    def test_detects_empty_eval_prompt(self) -> None:
        import json
        fixture = self.root / "evals" / "cases" / "foundation.json"
        data = json.loads(fixture.read_text(encoding="utf-8"))
        data["cases"][0]["positive"]["prompt"] = ""
        fixture.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
        self.assertTrue(any("missing positive" in issue for issue in self.failures()))

    def test_detects_missing_description(self) -> None:
        skill = self.root / "skills" / "core" / "task-planning" / "SKILL.md"
        content = skill.read_text(encoding="utf-8")
        content = content.replace("description: >-", "description: ''\n  #")
        skill.write_text(content, encoding="utf-8")
        self.assertTrue(any("description must contain" in issue for issue in self.failures()))

    def test_detects_knowledge_pattern_missing_source_sha(self) -> None:
        pattern = self.write_pattern("missing-source-sha.md")
        pattern.write_text(pattern.read_text(encoding="utf-8").replace(
            "source_sha: " + "a" * 40 + "\n", ""
        ), encoding="utf-8")
        self.assertTrue(any("missing required field source_sha" in issue
                            for issue in self.failures()))

    def test_detects_empty_knowledge_pattern_section(self) -> None:
        self.write_pattern("empty-section.md", context="")
        self.assertTrue(any("empty required section Контекст" in issue
                            for issue in self.failures()))

    def test_detects_duplicate_knowledge_pattern_title(self) -> None:
        self.write_pattern("first.md", title="Один заголовок")
        self.write_pattern("second.md", title="Один заголовок", source_sha="b" * 40)
        self.assertTrue(any("duplicate knowledge pattern title" in issue
                            for issue in self.failures()))

    def test_detects_invalid_knowledge_verification_status(self) -> None:
        pattern = self.write_pattern("invalid-verification-status.md")
        pattern.write_text(pattern.read_text(encoding="utf-8").replace(
            "ci_verification: NOT_RUN", "ci_verification: NEVER_CHECKED"
        ), encoding="utf-8")
        self.assertTrue(any("invalid ci_verification" in issue
                            for issue in self.failures()))

    def test_detects_missing_browser_automation_eval_suite(self) -> None:
        suite = self.root / "evals" / "cases" / "browser-automation" / "scenarios.json"
        suite.unlink()
        self.assertTrue(any("Missing browser automation eval suite" in issue
                            for issue in self.failures()))

    def test_detects_missing_required_browser_automation_case(self) -> None:
        import json
        suite = self.root / "evals" / "cases" / "browser-automation" / "scenarios.json"
        data = json.loads(suite.read_text(encoding="utf-8"))
        data["scenarios"] = [case for case in data["scenarios"] if case["id"] != "BA-09"]
        suite.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
        self.assertTrue(any("missing BA-09" in issue for issue in self.failures()))

    def test_detects_missing_drawing_editor_eval_suite(self) -> None:
        suite = self.root / "evals" / "cases" / "drawing-editor" / "scenarios.json"
        suite.unlink()
        self.assertTrue(any("Missing drawing editor eval suite" in issue
                            for issue in self.failures()))

    def test_detects_missing_required_drawing_editor_case(self) -> None:
        import json
        suite = self.root / "evals" / "cases" / "drawing-editor" / "scenarios.json"
        data = json.loads(suite.read_text(encoding="utf-8"))
        data["scenarios"] = [case for case in data["scenarios"] if case["id"] != "DE-09"]
        suite.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
        self.assertTrue(any("missing DE-09" in issue for issue in self.failures()))

    def test_detects_missing_classification_quality_eval_suite(self) -> None:
        suite = self.root / "evals" / "cases" / "classification-quality" / "scenarios.json"
        suite.unlink()
        self.assertTrue(any("Missing classification quality eval suite" in issue for issue in self.failures()))

    def test_detects_missing_required_project_profile(self) -> None:
        profile = self.root / "projects" / "twork" / "profile.json"
        profile.unlink()
        self.assertTrue(any("missing project profile twork" in issue for issue in self.failures()))

    def test_detects_inconsistent_classification_execution_and_result(self) -> None:
        import json
        suite = self.root / "evals" / "cases" / "classification-quality" / "scenarios.json"
        data = json.loads(suite.read_text(encoding="utf-8"))
        case = next(case for case in data["scenarios"] if case["id"] == "CQ-01")
        case["status"] = "not-run"
        case["result"] = "PASS"
        suite.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
        self.assertTrue(any("inconsistent execution/result" in issue for issue in self.failures()))

    def test_allows_blocked_classification_execution_with_blocked_result(self) -> None:
        import json
        suite = self.root / "evals" / "cases" / "classification-quality" / "scenarios.json"
        data = json.loads(suite.read_text(encoding="utf-8"))
        case = next(case for case in data["scenarios"] if case["id"] == "CQ-01")
        case["status"] = "blocked"
        case["result"] = "BLOCKED"
        suite.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
        self.assertEqual([], self.failures())


if __name__ == "__main__":
    unittest.main()

