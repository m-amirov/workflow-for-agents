# Classification quality Skill — source-bound evidence

- **Source:** `m-amirov/task-playwright-desktop` at `196f99b4583555ee1b0b170115d6c613e77ce705`.
- **Source verification:** `SOURCE_REVIEWED`; current remote main has advanced to `1138bfb7`, so claims here apply only to the exact source SHA.
- **CI verification:** `NOT_RUN` — Stage 2 found zero Actions runs at this SHA.
- **Local verification:** `LOCAL_TESTED` — on 2026-11-16, isolated source ran the four requested offline test files: 41 PASS; checkout stayed clean.

The source contracts independent reviewed labels, anonymized offline replay, typed comparison, duplicate/dataset/ground-truth rejection, partial-vs-full separation and regression gates. [Synthetic central checks](../../tests/test_classification_quality_contract.py) independently cover CQ-03…CQ-11; no Twork data or taxonomy is copied.
