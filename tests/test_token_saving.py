"""Static profile and advisory routing tests; no Codex execution."""
import importlib.util
from pathlib import Path
import tomllib
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("token_routing", ROOT / "scripts/task_routing.py")
router = importlib.util.module_from_spec(spec)
spec.loader.exec_module(router)


class TokenSavingTests(unittest.TestCase):
    def route(self, size="SMALL", risk="LOW", signals=()):
        return router.route_task("CHANGE", size, risk, signals, "LOCAL")

    def test_legacy_unchanged(self):
        self.assertNotIn("token_plan", self.route())
        self.assertEqual("NOT_PERFORMED", self.route()["model_selection"])

    def test_direct_and_bounded(self):
        for work, expected in {
            "TINY": "ROOT", "COMMAND": "DIRECT_TOOL", "COMPLEX": "ROOT",
            "BOUNDED_READ": "wfa_explorer", "BOUNDED_WRITE": "wfa_worker",
        }.items():
            with self.subTest(work=work):
                plan = router.token_plan(self.route(), work)
                self.assertEqual(expected, plan["recommended_profile"])
                self.assertEqual("NOT_MEASURED", plan["token_savings"])
                self.assertEqual("UNKNOWN", plan["effective_model"])

    def test_risk_and_review_gates(self):
        for route in (self.route(risk="HIGH"), self.route(risk="AUTO"),
                      self.route(size="MEDIUM"), self.route(signals=("payments",)),
                      self.route(signals=("architecture-change",))):
            with self.subTest(route=route):
                self.assertEqual("ROOT", router.token_plan(route, "BOUNDED_WRITE")["recommended_profile"])
                if route["reviewer"] == "REQUIRED":
                    self.assertEqual("wfa_reviewer", router.token_plan(route, "TINY")["independent_review_profile"])

    def test_invalid_work(self):
        with self.assertRaises(ValueError):
            router.token_plan(self.route(), "ANYTHING")

    def test_native_profiles(self):
        expected = {"wfa_explorer": ("gpt-5.6-luna", "low"),
                    "wfa_worker": ("gpt-5.6-luna", "low"),
                    "wfa_reviewer": ("gpt-5.6-sol", "medium")}
        for name, (model, effort) in expected.items():
            with self.subTest(name=name):
                with (ROOT / ".codex/agents" / (name + ".toml")).open("rb") as file:
                    config = tomllib.load(file)
                self.assertEqual(name, config["name"])
                self.assertEqual(model, config["model"])
                self.assertEqual(effort, config["model_reasoning_effort"])
                self.assertTrue(config["description"])
                self.assertTrue(config["developer_instructions"])


if __name__ == "__main__":
    unittest.main()
