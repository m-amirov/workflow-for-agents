---
name: release-verification
description: >-
  Use before publishing, merging a release, or declaring a build production
  ready to verify exact commit artifacts, tests, CI, and required release gates.
---
# Release Verification

1. Identify target source SHA, dependency lock, target platforms, and required release gates.
2. Run actual build, static checks, unit/integration/e2e tests, and platform-specific checks required by the project.
3. Inspect the produced artifact content and hashes when reproducibility is required.
4. Confirm that relevant CI runs apply to the same commit and correct artifact, not an earlier green build.
5. Check critical user scenarios and visual/asset integrity where relevant.
6. Report gates individually as PASS, FAIL, SKIP, BLOCKED, or NOT RUN, with commands, links, and evidence.
7. Declare release ready only when every mandatory gate has passed.

Never bypass a gate or equate a planned test with an executed test. If target platform access is unavailable, report BLOCKED rather than a simulated PASS. Follow playbooks/release.md.

