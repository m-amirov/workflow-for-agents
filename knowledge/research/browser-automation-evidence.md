# Browser automation Skill — source-bound evidence

## Scope

This is the implementation evidence for central `browser-automation`, not a claim that Twork or another external platform accepted an action. The Skill transfers only the reusable safety contract: identity-bound lease, durable reservation before a side effect, no blind retry, and independent receipt.

## Source

- **Repository:** `m-amirov/task-playwright-desktop`
- **Exact SHA:** `196f99b4583555ee1b0b170115d6c613e77ce705`
- **Source verification:** `SOURCE_REVIEWED`
- **CI verification:** `NOT_RUN` — authenticated GitHub Actions API returned zero runs for the exact SHA.
- **Local verification:** `LOCAL_TESTED` — Stage 2 ran 73 selected deterministic offline tests plus syntax and algorithm-lock checks in an isolated detached clone. Full `npm run gate:source`, real browser, credentials, production session and external side effects were not run.

## Evidence-to-invariant mapping

| Invariant in Skill | Source contract | Regression evidence |
| --- | --- | --- |
| Lease binds task, page and frame; stale callback stops | [TaskRunLease](https://github.com/m-amirov/task-playwright-desktop/blob/196f99b4583555ee1b0b170115d6c613e77ce705/src/core/task-run-lease.js) | [lease tests](https://github.com/m-amirov/task-playwright-desktop/blob/196f99b4583555ee1b0b170115d6c613e77ce705/tests/nitro-task-run-lease.test.js) |
| Reservation persists before one external effect | [NativeSubmissionFence](https://github.com/m-amirov/task-playwright-desktop/blob/196f99b4583555ee1b0b170115d6c613e77ce705/src/core/native-submission-confirmation.js) | [fence/receipt tests](https://github.com/m-amirov/task-playwright-desktop/blob/196f99b4583555ee1b0b170115d6c613e77ce705/tests/native-submission-confirmation.test.js) |
| Timeout and click error are not proof of failure; no retry | `attemptNativeSubmission` in the same source | [timeout and restart cases](https://github.com/m-amirov/task-playwright-desktop/blob/196f99b4583555ee1b0b170115d6c613e77ce705/tests/native-submission-confirmation.test.js) |
| Receipt must be identity-bound and independent | `probeNativeSubmissionEvidence` in the same source | [receipt identity tests](https://github.com/m-amirov/task-playwright-desktop/blob/196f99b4583555ee1b0b170115d6c613e77ce705/tests/nitro-submission-receipt.test.js) |

The central [Stage 2 report](stage-2-evidence.md) records commands, environment and limitations. The Skill's own synthetic contract checks are [tests/test_browser_automation_contract.py](../../tests/test_browser_automation_contract.py); they are a cross-project application of the invariants, not copied Twork fixtures.

## Stage 3 verification

- `python -m unittest discover -s tests -p test_browser_automation_contract.py -v` — PASS, six deterministic tests covering BA-03…BA-09.
- `python scripts/validate.py` — PASS; it validates all ten required scenarios in [evals/cases/browser-automation/scenarios.json](../../evals/cases/browser-automation/scenarios.json), in addition to Skill metadata and links.
- Isolated project install/sync — PASS for project-scope dry-run, manifest/sourceVersion, repeat install, dry-run update, update and local-edit protection. The source update was a disposable copy, not a modification of the central Skill.
- Real Codex CLI `0.167.2` in a disposable read-only project — BA-01 PASS: it read installed `browser-automation` and its reference, selected the Skill and separated local execution, receipt and platform acceptance. BA-02 PASS: for read-only Locator research it did not read the Skill, run commands or call tools. BA-10 PASS: for a theoretical Locator question it did not read the Skill or run commands. Full transcript summary: [Codex eval result](../../evals/results/2026-11-15-browser-automation-codex-cli.md).

No browser, production session, credentials, external URL or side effect was used in these tests.
