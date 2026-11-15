---
name: code-review
description: >-
  Use to independently review a pull request, patch, or implementation for
  correctness, regressions, security, maintainability, and test evidence.
---
# Code Review

1. Identify target base and exact head SHA; inspect the actual diff and relevant surrounding code.
2. Check behavioral requirements, affected callers, failure paths, security, data integrity, and compatibility.
3. Review test changes and whether coverage detects the defect or new behavior.
4. Verify cited CI/test evidence applies to the exact head; missing results are NOT RUN.
5. For UI changes, inspect real screenshots/rendering and approved visual constraints when available.
6. Return only actionable findings, ordered by severity, each with precise file/line context, reproduction and recommended correction.
7. State whether blocking findings exist and which checks were not performed.

Do not infer a successful review from the author's claims. Do not merge or delete branches without the workflow's required gates and safe integration into main.

