"""Regression coverage for declarative project profiles and compatibility checks."""
from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import shutil
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("project_profiles", ROOT / "scripts" / "project_profiles.py")
assert SPEC is not None and SPEC.loader is not None
profiles = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(profiles)


class ProjectProfileTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory(prefix="workflow-profiles-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / "repo"
        shutil.copytree(ROOT, self.root, ignore=shutil.ignore_patterns(".git", "__pycache__"))

    def profile(self, name: str) -> Path:
        return self.root / "projects" / name / "profile.json"

    def load(self, name: str) -> dict:
        return json.loads(self.profile(name).read_text(encoding="utf-8"))

    def results(self, name: str, **kwargs: object) -> list[dict]:
        return profiles.check_profile(self.root, self.load(name), **kwargs)

    def test_all_committed_profiles_are_valid(self) -> None:
        errors, count = profiles.validate_profiles(self.root)
        self.assertEqual([], errors)
        self.assertEqual(4, count)

    def test_unknown_or_planned_skill_is_rejected(self) -> None:
        profile = self.load("dachametr")
        profile["recommended_skills"].append("does-not-exist")
        self.assertTrue(any("unknown Skill" in item for item in profiles.validate_profile(self.root, profile)))
        profile["recommended_skills"][-1] = "seo-calculators"
        self.assertTrue(any("not implemented" in item for item in profiles.validate_profile(self.root, profile)))

    def test_pr_only_profile_refines_main_first_but_direct_main_requirement_is_hard_conflict(self) -> None:
        results = self.results("dachametr")
        self.assertTrue(any(item["class"] == "PROJECT_REFINEMENT" and item["id"] == "git-workflow" for item in results))
        results = self.results("dachametr", constraints={"direct_main_required": True})
        self.assertTrue(any(item["class"] == "HARD_CONFLICT" for item in results))

    def test_missing_project_authorization_is_blocked(self) -> None:
        results = self.results("dachametr", constraints={"prototype_authorized": False})
        self.assertTrue(any(item["class"] == "REQUIRES_PROJECT_DECISION" and item["id"] == "prototype-authorization" for item in results))

    def test_stale_source_sha_is_reported(self) -> None:
        project = self.root / "fixture"
        project.mkdir()
        (project / ".git").mkdir()
        (project / "AGENTS.md").write_text("fixture", encoding="utf-8")
        results = self.results("eskizno", project_root=project, head_sha="f" * 40)
        self.assertTrue(any(item["class"] == "STALE_EVIDENCE" for item in results))

    def test_existing_local_skill_collision_requires_decision(self) -> None:
        project = self.root / "fixture"
        (project / ".agents" / "skills" / "drawing-editor").mkdir(parents=True)
        results = self.results("eskizno", project_root=project)
        self.assertTrue(any(item["class"] == "REQUIRES_PROJECT_DECISION" and item["id"] == "local-skill-collision" for item in results))

    def test_manifest_managed_skill_is_not_reported_as_local_collision(self) -> None:
        project = self.root / "fixture"
        skills = project / ".agents" / "skills"
        (skills / "drawing-editor").mkdir(parents=True)
        (skills / ".workflow-for-agents.manifest.json").write_text(json.dumps({
            "schema": 1, "source": "workflow-for-agents", "installed": [{"name": "drawing-editor"}],
        }), encoding="utf-8")
        results = self.results("eskizno", project_root=project)
        self.assertFalse(any(item["id"] == "local-skill-collision" and "drawing-editor" in item["message"] for item in results))

    def test_matching_declared_instruction_is_duplicate_and_nested_mismatch_is_hard_conflict(self) -> None:
        project = self.root / "fixture"
        nested = project / "packages" / "AGENTS.md"
        nested.parent.mkdir(parents=True)
        nested.write_text("workflow-for-agents: git=direct-main\n", encoding="utf-8")
        results = self.results("twork", instruction_files=[nested])
        self.assertTrue(any(item["class"] == "HARD_CONFLICT" and item["id"] == "nested-git-workflow" for item in results))
        nested.write_text("workflow-for-agents: git=pr-only\n", encoding="utf-8")
        results = self.results("twork", instruction_files=[nested])
        self.assertTrue(any(item["class"] == "DUPLICATE" and item["id"] == "nested-git-workflow" for item in results))

    def test_unstructured_instruction_is_unknown_not_a_claimed_conflict(self) -> None:
        instruction = self.root / "global-AGENTS.md"
        instruction.write_text("Always be careful with Git.", encoding="utf-8")
        results = self.results("ludory", instruction_files=[instruction])
        self.assertTrue(any(item["class"] == "UNKNOWN" and item["id"] == "instruction-parse" for item in results))

    def test_manifest_integrity_problem_requires_decision(self) -> None:
        project = self.root / "fixture"
        manifest = project / ".agents" / "skills" / ".workflow-for-agents.manifest.json"
        manifest.parent.mkdir(parents=True)
        manifest.write_text('{"schema": 9}', encoding="utf-8")
        results = self.results("ludory", project_root=project)
        self.assertTrue(any(item["class"] == "REQUIRES_PROJECT_DECISION" and item["id"] == "manifest-integrity" for item in results))


if __name__ == "__main__":
    unittest.main()
