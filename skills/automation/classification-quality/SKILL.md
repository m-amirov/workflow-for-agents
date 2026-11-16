---
name: classification-quality
description: >-
  Use when evaluating or fixing classifier errors, comparing models/prompts/rules on offline replay,
  measuring labeled quality, or designing a quality gate. Do not use for ML theory, CSS, documentation,
  JSON formatting, UI-only work, or browser automation without classification evaluation.
---
# Evidence-Gated Classification Quality

1. Define stable case IDs, answer type, independent label provenance, allowed normalization and project thresholds before scoring.
2. Treat absent, model-generated, confidence-derived, prior-prediction or unreviewed labels as `UNVERIFIED`; exclude them from accuracy.
3. Validate dataset uniqueness and require baseline/candidate to have identical IDs, task types and label digests. Label or corpus drift blocks comparison.
4. Compare by type: choice normalized option, labels defined set/order semantics, path full hierarchy, number finite contract, text explicit exact/semantic rule. Do not add fuzzy matching silently.
5. Report total, independently labeled, correct, incorrect, `UNVERIFIED`, invalid, accuracy on labeled cases and coverage separately. Partial labels are not full accuracy.
6. Count improved, regressed, unchanged-correct and unchanged-incorrect; inspect critical classes separately. A quality gate is `BLOCKED` when labels, coverage or project-defined thresholds are insufficient.
7. Default to synthetic/anonymized fixtures. Do not publish source prompts, production logs, credentials or reversible identifiers.

Read [references/contracts-and-evidence.md](references/contracts-and-evidence.md) for failure cases and source evidence. Use [regression-testing](../../testing/regression-testing/SKILL.md) after a reproduced defect and [root-cause-debugging](../../development/root-cause-debugging/SKILL.md) to locate it.
