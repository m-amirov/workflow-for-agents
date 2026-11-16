# Classification quality — eval evidence

| Проверка | Статус | Факт |
| --- | --- | --- |
| CQ-03…CQ-11 synthetic contracts | PASS | `tests/test_classification_quality_contract.py`: 7 tests, synthetic data only. |
| CQ-01 positive Codex fix | PARTIAL | Codex selected the installed Skill, diagnosed substring bug and changed disposable `classifier.py`; its sandbox lacked `python`, so host ran GREEN. |
| CQ-02 negative activation | PASS | Read-only theoretical precision/recall prompt completed without file changes; CQ-12 remains NOT RUN. |
| Install | PASS | Isolated project install created managed Skill and manifest. Repeat/dry-run/sync/local-edit protection remain NOT RUN. |

No production classifier, Twork data, browser or API was used.

## RED/GREEN

Before Codex, `python -m unittest -v` in the disposable project failed: `classify("not good")` returned `positive` instead of independently reviewed synthetic `negative`. Codex applied the narrow negation guard while preserving the regression test. The same host command then passed (1 test). This is a local synthetic fix, not a measured quality increase or production evidence.
