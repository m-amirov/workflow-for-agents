"""Offline regression and source-bound guard tests for Ludory compatibility.

Do NOT equate these deterministic fixtures with actual Codex model activation.
"""
from __future__ import annotations

import importlib.util
import json
import re
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
script = ROOT / "scripts/ludory_compatibility.py"
spec = importlib.util.spec_from_file_location("ludory_compatibility", script)
mod = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = mod
spec.loader.exec_module(mod)
SCENARIOS = ROOT / "evals/cases/ludory-compatibility/scenarios.json"
PROFILE = ROOT / "projects/ludory/profile.json"
ROUTING = ROOT / "skills/core/task-planning/references/gamedev-router/WFA-ROUTING.md"
POLICY = ROOT / "skills/core/task-planning/references/ludory-compatibility.md"
TASK = ROOT / "skills/core/task-planning/SKILL.md"
LOCAL = {
    "ludory-asset-rights","ludory-audit","ludory-engineering-quality",
    "ludory-fix","ludory-incident-analysis","ludory-level-design",
    "ludory-narrative-continuity","ludory-narrative-review",
    "ludory-production-art","ludory-reader-experience","ludory-ui-design",
    "ludory-verification","ludory-visual-qa",
}


class LudoryCompatibilityGate(unittest.TestCase):
    def test_20_positive_negative_fixtures(self):
        cases = json.loads(SCENARIOS.read_text(encoding="utf-8"))
        self.assertEqual(cases["schema"], 1)
        self.assertEqual(len(cases["scenarios"]), 20)
        for case in cases["scenarios"]:
            with self.subTest(case=case["id"]):
                self.assertEqual(
                    {k: mod.route(case["input"]).get(k) for k in case["expected"]},
                    case["expected"],
                )
        self.assertEqual(len({c["id"] for c in cases["scenarios"]}), 20)

    def test_ludory_profile_preserves_all_13_project_local_skills(self):
        profile = json.loads(PROFILE.read_text(encoding="utf-8"))
        self.assertEqual(set(profile["protected_local_skills"]), LOCAL)
        self.assertEqual(profile["canonical_repository"], mod.LUDORY_REPO)
        self.assertEqual(profile["source_sha"], "933c73b195eaf3bfffd12a31ab1cbadb27989eea")
        self.assertIn("owner-required", profile["release_authorization"])

    def test_operational_router_uses_actual_imported_locations(self):
        text = ROUTING.read_text(encoding="utf-8")
        groups = [
            "disciplines","genres","workflows","godot","unity","unreal",
            "web-engines","other-engines","ebitengine",
        ]
        for group in groups:
            path = ROOT / "skills/gamedev" / group
            self.assertTrue(path.is_dir(), group)
            self.assertIn(f"skills/gamedev/{group}/", text)
        self.assertNotRegex(text, r"(?<!gamedev/)skills/(?:godot|unity|unreal|web-engines)/")
        self.assertNotIn("skills/godot/", TASK.read_text(encoding="utf-8"))

    def test_imported_router_remains_pinned_reference_only(self):
        upstream = ROOT / "skills/core/task-planning/references/gamedev-router/UPSTREAM.md"
        self.assertTrue(upstream.is_file())
        text = TASK.read_text(encoding="utf-8")
        self.assertIn("gamedev-router/WFA-ROUTING.md", text)
        self.assertIn("ludory-compatibility.md", text)
        self.assertIn("does not authorize treating the framework as a phaser game", text.lower())
        self.assertIn("UPSTREAM.md", ROUTING.read_text(encoding="utf-8"))

    def test_native_process_and_release_gates_are_not_overridden(self):
        text = POLICY.read_text(encoding="utf-8").lower()
        for phrase in ("ludory-production-art","ludory-asset-rights",
                       "ludory-narrative-review","native persistence",
                       "release", "vk", "yandex", "frozen", "phaser",
                       "owner", "not run"):
            self.assertIn(phrase, text)
        paths = [p for p in (ROOT / "skills/gamedev").rglob("SKILL.md")]
        self.assertEqual(len(paths), 78)
        self.assertEqual(len({p.parent.name for p in paths}), 78)

    def test_unknown_or_missing_owner_never_grants_mutation(self):
        for bad in [
            {"scope":"unknown","task":"art","mutation_requested":True},
            {"scope":"new-studio","task":"art","source_verified":True,"studio_creation_verified":False,"owner_authorized":True,"mutation_requested":True},
            {"scope":"new-studio","task":"art","source_verified":True,"studio_creation_verified":True,"owner_authorized":False,"mutation_requested":True},
            {"scope":"frozen","task":"save","source_verified":True,"owner_authorized":True,"mutation_requested":True},
        ]:
            with self.subTest(bad=bad):
                self.assertNotEqual(mod.route(bad)["status"],"ROUTED")


if __name__ == "__main__":
    unittest.main()
