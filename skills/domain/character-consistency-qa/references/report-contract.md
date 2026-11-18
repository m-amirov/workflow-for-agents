# Character consistency review report

Store a structured record **per exact project commit and reference revision**.
Keep image originals and review screenshots externally as real files; their
paths plus hashes are pointers, not proof of independent observation.

Required fields:

- project/repository SHA, character ID, card version and card SHA-256;
- canonical master path, SHA-256, dimensions and approval status;
- each candidate path, SHA-256, expected view/expression/costume,
  source/license and observed dimension;
- a line of evidence for each finding: candidate, invariant, observation,
  severity (P0/P1/P2), compare-to reference and remediation;
- reviewer provenance (reviewer ID/method, inspected original pixels,
  date/context), or explicit NOT_RUN / evidence gap;
- mechanical, artistic, runtime and rights gates separately;
- overall result: CANDIDATE_ACCEPTED_FOR_INTEGRATION, REWORK or BLOCKED;
- QA re-run after edits, pinning new candidate hashes and preserving original
  findings for traceability.

An illustrative report structure is
[report.example.json](report.example.json).
This example is **not** execution evidence.

## Adversarial cases to test

1. Front and side files contain different faces but same costume.
2. Distinct file names point to identical image bytes for multiple views.
3. Mirrored mole/scar appears on the wrong side, despite high similarity.
4. One expected neutral view is replaced with an attractive three-quarter shot.
5. Correct face with wrong proportions / palette / silhouette.
6. Valid costume variant is incorrectly rejected as forbidden change.
7. All images valid but game runtime crops off the head on a phone.
8. Missing ImageGen or visual reviewer and a tempting self-reported PASS.

Test both negatives (reject false identity and missing evidence) and positives
(permitted pose, expression and lighting differences remain admissible).
