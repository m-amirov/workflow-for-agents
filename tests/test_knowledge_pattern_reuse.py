"""Independent, stdlib-only reuse checks for the two pilot Knowledge patterns."""
from __future__ import annotations

from dataclasses import dataclass
from hashlib import sha256
from pathlib import PurePosixPath
import io
import unittest
import warnings
import zipfile


class ArtifactRejected(ValueError):
    """The independently constructed package does not satisfy its contract."""


def make_zip(members: list[tuple[str, bytes]]) -> bytes:
    stream = io.BytesIO()
    with warnings.catch_warnings():
        warnings.simplefilter("ignore", UserWarning)
        with zipfile.ZipFile(stream, "w", zipfile.ZIP_DEFLATED) as archive:
            for name, content in members:
                archive.writestr(name, content)
    return stream.getvalue()


def verify_package(raw: bytes, expected_names: set[str]) -> dict[str, object]:
    try:
        with zipfile.ZipFile(io.BytesIO(raw)) as archive:
            bad_member = archive.testzip()
            if bad_member:
                raise ArtifactRejected(f"crc_mismatch:{bad_member}")
            members = archive.infolist()
            names = [member.filename for member in members]
            normalized: list[str] = []
            for name in names:
                path = PurePosixPath(name)
                if name.startswith("/") or "\\" in name or ".." in path.parts or not name:
                    raise ArtifactRejected(f"unsafe_path:{name}")
                normalized.append(name.casefold())
            if len(normalized) != len(set(normalized)):
                raise ArtifactRejected("duplicate_or_case_collision")
            if set(names) != expected_names:
                raise ArtifactRejected("unexpected_member_set")
            return {
                "artifact_sha256": sha256(raw).hexdigest(),
                "member_sha256": {name: sha256(archive.read(name)).hexdigest() for name in names},
            }
    except zipfile.BadZipFile as error:
        raise ArtifactRejected("invalid_zip") from error


def verify_receipt(raw: bytes, receipt: dict[str, object]) -> None:
    current = verify_package(raw, set(receipt["member_sha256"]))
    if current["artifact_sha256"] != receipt["artifact_sha256"]:
        raise ArtifactRejected("artifact_sha_mismatch")
    if current["member_sha256"] != receipt["member_sha256"]:
        raise ArtifactRejected("member_sha_mismatch")


@dataclass(frozen=True)
class GateState:
    package: str
    rights: str
    external_release: str


def technical_gate(receipt: dict[str, object]) -> GateState:
    if not receipt["artifact_sha256"]:
        raise ArtifactRejected("missing_receipt")
    return GateState(package="PACKAGE_PASS", rights="BLOCKED", external_release="NOT_RUN")


def validate_research(document: dict[str, object]) -> str:
    observations = document.get("observations")
    required = document.get("required_metrics")
    proposed = document.get("proposed_gate")
    if not isinstance(observations, list) or not isinstance(required, list) or not isinstance(proposed, str):
        raise ValueError("invalid_document")
    indexed: dict[str, dict[str, object]] = {}
    for item in observations:
        if not isinstance(item, dict) or not isinstance(item.get("key"), str):
            raise ValueError("invalid_observation")
        key = item["key"]
        if key in indexed or "\ufffd" in key:
            raise ValueError("duplicate_or_corrupt_key")
        status = item.get("status")
        value = item.get("value")
        if status == "MEASURED":
            source = item.get("source")
            if not isinstance(value, (int, float)) or isinstance(value, bool):
                raise ValueError("measured_value_invalid")
            if not isinstance(source, str) or not source.startswith("https://") or "\ufffd" in source:
                raise ValueError("missing_or_corrupt_source")
        elif status == "UNKNOWN":
            if value is not None or not isinstance(item.get("reason"), str):
                raise ValueError("unknown_must_not_be_number")
        else:
            raise ValueError("invalid_status")
        indexed[key] = item
    if any(key not in indexed for key in required):
        raise ValueError("required_metric_missing")
    complete = all(indexed[key]["status"] == "MEASURED" for key in required)
    if proposed == "GO" and not complete:
        raise ValueError("go_without_complete_evidence")
    if not complete:
        return "BLOCKED"
    return proposed


class EvidenceGatedArtifactAcceptanceReuseTests(unittest.TestCase):
    expected_names = {"manifest.json", "payload.txt"}

    def setUp(self) -> None:
        self.valid = make_zip([
            ("manifest.json", b'{"format":"independent-demo-v1"}'),
            ("payload.txt", b"verified payload\n"),
        ])
        self.receipt = verify_package(self.valid, self.expected_names)

    def test_valid_package_passes_without_promoting_other_gates(self) -> None:
        state = technical_gate(self.receipt)
        self.assertEqual(state.package, "PACKAGE_PASS")
        self.assertEqual(state.rights, "BLOCKED")
        self.assertEqual(state.external_release, "NOT_RUN")

    def test_changed_content_does_not_match_the_prior_receipt(self) -> None:
        changed = make_zip([
            ("manifest.json", b'{"format":"independent-demo-v1"}'),
            ("payload.txt", b"changed payload\n"),
        ])
        with self.assertRaisesRegex(ArtifactRejected, "artifact_sha_mismatch"):
            verify_receipt(changed, self.receipt)

    def test_unexpected_file_unsafe_path_and_case_collision_are_rejected(self) -> None:
        unexpected = make_zip([
            ("manifest.json", b"{}"), ("payload.txt", b"x"), ("notes.txt", b"extra"),
        ])
        traversal = make_zip([("manifest.json", b"{}"), ("../payload.txt", b"x")])
        collision = make_zip([("manifest.json", b"{}"), ("PAYLOAD.txt", b"x"), ("payload.txt", b"y")])
        for archive, reason in ((unexpected, "unexpected_member_set"), (traversal, "unsafe_path"),
                                (collision, "duplicate_or_case_collision")):
            with self.subTest(reason=reason), self.assertRaisesRegex(ArtifactRejected, reason):
                verify_package(archive, self.expected_names)


class FailClosedResearchProvenanceReuseTests(unittest.TestCase):
    def document(self, observations: list[dict[str, object]], proposed_gate: str = "GO") -> dict[str, object]:
        return {
            "required_metrics": ["signal_a", "signal_b"],
            "observations": observations,
            "proposed_gate": proposed_gate,
        }

    def test_missing_source_corruption_and_inconsistent_values_are_rejected(self) -> None:
        cases = [
            ([{"key": "signal_a", "status": "MEASURED", "value": 4},
              {"key": "signal_b", "status": "MEASURED", "value": 5,
               "source": "https://evidence.example/b"}], "missing_or_corrupt_source"),
            ([{"key": "signal_a", "status": "MEASURED", "value": 4,
               "source": "https://evidence.example/\ufffd"},
              {"key": "signal_b", "status": "MEASURED", "value": 5,
               "source": "https://evidence.example/b"}], "missing_or_corrupt_source"),
            ([{"key": "signal_a", "status": "MEASURED", "value": None,
               "source": "https://evidence.example/a"},
              {"key": "signal_b", "status": "MEASURED", "value": 5,
               "source": "https://evidence.example/b"}], "measured_value_invalid"),
        ]
        for observations, reason in cases:
            with self.subTest(reason=reason), self.assertRaisesRegex(ValueError, reason):
                validate_research(self.document(observations))

    def test_unknown_stays_blocked_and_cannot_authorize_go(self) -> None:
        observations = [
            {"key": "signal_a", "status": "MEASURED", "value": 4,
             "source": "https://evidence.example/a"},
            {"key": "signal_b", "status": "UNKNOWN", "value": None,
             "reason": "source unavailable"},
        ]
        self.assertEqual(validate_research(self.document(observations, "BLOCKED")), "BLOCKED")
        with self.assertRaisesRegex(ValueError, "go_without_complete_evidence"):
            validate_research(self.document(observations, "GO"))
        self.assertNotEqual(observations[1]["value"], 0)


if __name__ == "__main__":
    unittest.main()
