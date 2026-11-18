"""Offline boundaries for the pinned gamedev library importer (not runtime eval)."""
import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("import_gamedev_library", ROOT / "scripts/import_gamedev_library.py")
module = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = module
spec.loader.exec_module(module)


class GamedevImportTests(unittest.TestCase):
    def test_pinned_upstream_revision(self):
        self.assertEqual(len(module.SOURCE_SHA), 40)
        self.assertEqual(module.EXPECTED, 79)
        self.assertEqual(module.FOLD, {"create-game-assets": "production-art"})

    def test_relocated_skill_keeps_name_and_references(self):
        root = Path("/wfa")
        self.assertEqual(
            module.resolved_target(root, Path("skills/godot/godot-export/SKILL.md")),
            root / "skills/gamedev/godot/godot-export/SKILL.md",
        )
        self.assertEqual(
            module.resolved_target(root, Path("skills/godot/godot-export/references/presets-and-cli.md")),
            root / "skills/gamedev/godot/godot-export/references/presets-and-cli.md",
        )

    def test_duplicate_game_art_skill_is_folded_not_installed(self):
        root = Path("/wfa")
        self.assertEqual(
            module.resolved_target(root, Path("skills/disciplines/create-game-assets/SKILL.md")),
            root / "skills/domain/production-art/references/gamedev-create-game-assets/UPSTREAM.md",
        )
        self.assertEqual(
            module.resolved_target(root, Path("skills/disciplines/create-game-assets/scripts/asset_report.py")),
            root / "skills/domain/production-art/references/gamedev-create-game-assets/scripts/asset_report.py",
        )

    def test_router_is_reference_not_second_global_skill(self):
        root = Path("/wfa")
        self.assertEqual(
            module.resolved_target(root, Path("router/SKILL.md")),
            root / "skills/core/task-planning/references/gamedev-router/UPSTREAM.md",
        )

    def test_upstream_ci_and_gitignore_are_not_imported(self):
        root = Path("/wfa")
        self.assertIsNone(module.resolved_target(root, Path(".github/workflows/ci.yml")))
        self.assertIsNone(module.resolved_target(root, Path(".gitignore")))

    def test_md_links_follow_relocated_target_and_deduped_skill(self):
        root = Path("/wfa")
        old = Path("skills/disciplines/game-ui-ux/SKILL.md")
        target = module.resolved_target(root, old)
        content = (b"See [art](../create-game-assets/SKILL.md) "
                   b"and [local](references/layout-and-flow.md#testing).")
        fixed = module.relocated_markdown(content, old, target, root).decode()
        self.assertIn("gamedev-create-game-assets/UPSTREAM.md", fixed)
        self.assertIn("references/layout-and-flow.md#testing", fixed)
        self.assertNotIn("../create-game-assets/SKILL.md", fixed)

    def test_no_silent_overwrite_of_changed_existing_file(self):
        with tempfile.TemporaryDirectory() as directory:
            destination = Path(directory) / "SKILL.md"
            destination.write_bytes(b"user owned")
            with self.assertRaisesRegex(ValueError, "Collision or local modification"):
                module.ensure_exact(destination, b"upstream content", apply=True)
            self.assertEqual(destination.read_bytes(), b"user owned")

    def test_check_mode_is_read_only(self):
        with tempfile.TemporaryDirectory() as directory:
            destination = Path(directory) / "nested" / "SKILL.md"
            module.ensure_exact(destination, b"content", apply=False)
            self.assertFalse(destination.exists())
            self.assertFalse(destination.parent.exists())


if __name__ == "__main__":
    unittest.main()
