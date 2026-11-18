---
name: gameplay-playtesting
description: >-
  Use to plan, observe and analyze actual player playtest sessions for
  comprehension, onboarding, controls, pacing, challenge and motivation.
  Separates genuine human observations from bots/simulated users and produces
  reproducible findings and retest decisions. Not for native regression tests,
  profiling, browser automation or narrative-only editorial review.
---

# Gameplay Playtesting — observation before claims

Activate when a playable build exists and questions concern player-observed
usability, learning, pacing, choices or difficulty at
[Game Production G3/G5](../../../playbooks/game-production.md).

## Owners and non-overlap

- [browser-qa](../../testing/browser-qa/SKILL.md) and
  [regression-testing](../../testing/regression-testing/SKILL.md) prove
  **technical behavior**, not comprehension. A bot run is not a human session.
- [reader-experience-review](../reader-experience-review/SKILL.md) owns
  narrative-only editorial cold-read analysis; human gameplay needs real
  player interactions and participant observations.
- [gameplay-design](../gameplay-design/SKILL.md) owns loop hypotheses and
  [game-content-qa](../game-content-qa/SKILL.md) owns committed content coverage.
  This Skill owns genuine session protocol and findings, not code changes
  or unapproved analytics instrumentation.

## Protocol

1. Pin game source SHA, actual playable build/package and hash, environment,
   locale, device/input, accessibility conditions, session type/date. If no
   runnable build exists, prepare a protocol but report PLAYTEST_NOT_RUN.
2. Derive a few falsifiable questions from actual gameplay acceptance IDs:
   understands first goal, discovers controls, notices consequences,
   understands retry, resolves a specific progression bottleneck. Define
   specific tasks and stopping/assistance rules. Avoid universal fun scores.
3. Select participants matching target audience when feasible; record
   sample count and bias, moderated/unmoderated mode and consent. Record only
   necessary anonymous data. No unapproved recordings/telemetry/uploads.
4. Observe before diagnosing. For each participant keep pseudonymous ID,
   current build, timestamp/state, actions, errors, pauses, retries,
   completion and help given. Capture actual quotes only if truly recorded.
   A scripted test is labeled AUTOMATED_SCENARIO, never HUMAN_PLAYTEST.
5. Separate CONFIRMED_OBSERVATION, INTERPRETATION, HYPOTHESIS and EVIDENCE_GAP.
   Note reproducible symptom and plausible mechanism separately. A small,
   convenience sample cannot establish population-wide retention.
6. Prioritize P0/P1/P2 and link finding → acceptance ID → observed session →
   evidence → bounded proposed fix/retest. Design changes require normal
   authorization; do not rewrite the game on a speculative preference.
7. Retest on a newly pinned build using actual new sessions. Code-level green
   regression may establish technical correctness but cannot automatically
   close a human-comprehension or enjoyment finding.
8. Deliver [session report](references/playtest-report.md), defects, limits,
   acceptance implications and responsible workflow. G5 still requires
   project-native regression, browser/performance and release checks.

## Status and boundaries

PROTOCOL_READY: questions and session design exist; no live test.
SESSION_OBSERVED: at least one actual consented player session with
source-bound evidence; no general claim of fun.
PLAYTEST_FINDINGS_REVIEWED: observations classified with evidence and limits.
BLOCKED/NOT_RUN: absent build/players/consent or inaccessible evidence.
Synthetic player personas, fake quotes or AI-simulated sessions never count
toward human evidence. No external outreach, tracking or paid sessions are
authorized by this Skill.
