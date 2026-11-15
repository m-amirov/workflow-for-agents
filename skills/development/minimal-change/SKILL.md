---
name: minimal-change
description: >-
  Use for small bug fixes, enhancements, and maintenance changes where
  preserving working behavior and limiting blast radius are essential.
---
# Minimal Change

1. Establish the exact behavior to change, what must stay unchanged, and available evidence.
2. Trace affected call paths and locate the smallest cohesive edit.
3. Prefer local code changes and existing abstractions; do not introduce dependencies by default.
4. Preserve published interfaces, data formats, approved UI assets, and backward compatibility.
5. Add focused coverage for the changed contract, including an edge case if justified.
6. Check the diff for unrelated formatting, generated files, accidental refactors, and data loss.
7. Run relevant checks and state exact results plus remaining risks.

When a broader refactor is strictly necessary, explain why a smaller fix is incorrect and separate unrelated cleanup into a future task. Never silence failures or weaken tests to produce PASS.

