"""Structural contract checks for the Stage 10 read-only global preflight."""
from __future__ import annotations

from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
PREflight = ROOT / "scripts" / "global-preflight.ps1"
SKILL_UTILS = ROOT / "scripts" / "SkillUtils.ps1"
MIGRATION = ROOT / "docs" / "migrations" / "2026-11-16-stage-10-global-skills-preflight.md"


CEOS_MIGRATED = {
    "audit", "audit-repair-loop", "ceos-continue", "fix", "verification",
    "release", "visual-qa", "video-production", "romance-narrative",
    "narrative-dialogue-editor", "narrative-continuity-engine",
    "reader-experience-review", "production-art", "prod-check", "incident-analysis",
}


class GlobalPreflightContractTests(unittest.TestCase):
    def test_entrypoint_is_read_only_and_has_required_parameters(self) -> None:
        content = PREflight.read_text(encoding="utf-8")
        for parameter in ("$Set", "$All", "$OutputFormat", "$HomePath"):
            self.assertIn(parameter, content)
        self.assertIn("Get-PreflightManifestInspection", content)
        self.assertIn("Get-PreflightLegacyManifestInspection", content)
        self.assertIn("InstallOrSyncInvoked = $false", content)
        self.assertNotRegex(content, r"&\s+\$?(?:install|sync)\b")
        self.assertNotIn("Remove-Item", content)
        self.assertNotIn("Write-Manifest", content)

    def test_all_fail_closed_states_are_serialized(self) -> None:
        content = PREflight.read_text(encoding="utf-8")
        states_match = re.search(r"States = @\((.*?)\)", content, re.DOTALL)
        self.assertIsNotNone(states_match)
        states = set(re.findall(r"'([A-Z_]+)'", states_match.group(1)))
        self.assertEqual(
            states,
            {
                "NOT_INSTALLED", "CURRENT", "UPDATE_AVAILABLE", "USER_MODIFIED",
                "LEGACY_CEOS_MANAGED", "UNMANAGED_COLLISION", "OWNERSHIP_UNVERIFIED",
                "INVALID_MANIFEST", "UNSAFE_PATH",
            },
        )

    def test_migrated_set_and_source_sha_remain_bound(self) -> None:
        content = SKILL_UTILS.read_text(encoding="utf-8")
        for name in CEOS_MIGRATED:
            self.assertIn(f"'{name}'", content)
        self.assertIn("c8cc13bd3852409be93097ee823e9cd35e512b73", PREflight.read_text(encoding="utf-8"))

    def test_report_documents_real_home_boundary_and_migration_plan(self) -> None:
        content = MIGRATION.read_text(encoding="utf-8")
        for phrase in (
            "8b8b3894b3fc67e3ae5da41e014bb9f9cf65337a",
            "c8cc13bd3852409be93097ee823e9cd35e512b73",
            "ownership migration",
            "OWNERSHIP_UNVERIFIED",
            "Backup-backed migration plan",
            "16 сценариев",
        ):
            self.assertIn(phrase, content)


if __name__ == "__main__":
    unittest.main()
