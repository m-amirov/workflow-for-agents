# Classification quality — eval evidence

`status` in the scenario fixture means that the scenario was run; `result` is its assessment. This report contains only synthetic, anonymized fixtures and disposable repositories.

| Checks | Execution | Result | Evidence |
| --- | --- | --- | --- |
| CQ-01: classifier fix | executed | PARTIAL | Codex selected the installed Skill, diagnosed the synthetic substring defect and changed disposable `classifier.py`; its sandbox could not run `python`, so the host ran GREEN. |
| CQ-02: ML theory | executed | PASS | Read-only theoretical precision/recall prompt completed without file changes. |
| CQ-03…CQ-11: contracts | executed | PASS | `tests/test_classification_quality_contract.py`, synthetic data only: independent labels, duplicate/label/corpus rejection, mixed deltas, partial labels, fail-closed gate and privacy. |
| CQ-12: CSS | executed | PASS | Real Codex CLI negative activation described below. |

No production classifier, Twork data, browser session or external API was used. These checks do not measure Twork accuracy.

## CQ-12 — real negative activation

- **Environment:** Windows, PowerShell; Codex CLI `0.167.2`; isolated Git fixture.
- **Prompt:** `В репозитории есть статическая страница. Пользователь просит только изменить padding в web/site.css с 8px на 12px. Не выполняй команды, не открывай браузер и не изменяй файлы: ответь кратко, какие именно изменения потребовались бы. Это не задача о классификации или оценке качества.`
- **Command:** `codex exec --ephemeral --sandbox read-only --json -C <isolated-project> -o <last-message> <prompt>`.
- **Observed result:** exit `0`; response proposed only the CSS replacement. JSONL had `0` `command_execution` events and no literal `classification-quality` mention. There is therefore no observable Skill read/activation in the CLI trace; silent internal context loading cannot be inferred from that trace.
- **Files:** `git diff --exit-code` for tracked fixture files was clean. Harness outputs and the deliberately installed project-scoped Skill remained untracked; no tracked HTML/CSS file changed.

## RED/GREEN for CQ-01

Before Codex, `python -m unittest -v` in the disposable project failed: `classify("not good")` returned `positive` instead of independently reviewed synthetic `negative`. Codex applied the narrow negation guard while preserving the regression test. The same host command then passed (1 test). This is a local synthetic fix, not a measured quality increase or production evidence.

## Project-scope install/sync

All checks used a fresh temporary source copy and target; no user/global Skills or global `AGENTS.md` were touched.

| Check | Result | Observation |
| --- | --- | --- |
| Install dry-run | PASS | Reported planned install; `.agents/skills` did not exist afterwards. |
| First install and manifest | PASS | Created `classification-quality` and schema-1 manifest with source path, SHA-256 file hashes and content version. |
| Repeat install | PASS | `SKIP classification-quality`; `No changes`. |
| Sync dry-run | PASS | Detected one controlled source update; wrote nothing. |
| Sync update | PASS | Updated that reference and refreshed manifest version. |
| Local-edit protection | PASS | A local `SKILL.md` modification made sync reject with `Local modification or deletion`. |
| User-file preservation | PASS | The local edit and a separate `user-note.txt` were still present after the rejected sync. |

## Limits

CQ-01 remains `PARTIAL`: the Codex sandbox did not itself run the Python test. CQ-12 proves non-activation only through observable CLI behavior, not an internal loader trace. Synthetic gates validate the contract, not real-world model quality or Twork platform acceptance.
