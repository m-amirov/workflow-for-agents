---
name: gameplay-design
description: >-
  Use when designing or revising a game's core loop, player actions, game rules,
  failure and success feedback, teaching progression, agency and testable
  gameplay acceptance. Produces an engine-neutral behavioral contract. Not for
  GDD formatting, level geometry, narrative prose, balance formulas or building
  engine-specific code without an implementation request.
---

# Gameplay Design — playable rules, not an empty concept

Activate when asked what players actually do, how a loop works, whether
decisions have consequences, or for a new game's G0/G1/G2 gameplay contract.
Read [Game Production G0–G2](../../../playbooks/game-production.md)
and current project-native requirements before starting.

## Deliberate non-overlap

- [game-docs](../../gamedev/workflows/game-docs/SKILL.md) maintains GDD
  files and feature notes; this Skill provides mechanics, not a competing GDD.
- [prototype-fast](../../gamedev/workflows/prototype-fast/SKILL.md) builds
  a disposable experiment. [level-design](../../gamedev/disciplines/level-design/SKILL.md)
  owns spatial level layout and [game-feel](../../gamedev/disciplines/game-feel/SKILL.md)
  owns audiovisual feedback polish. Genre and engine Skills own actual code.
- [gameplay-playtesting](../gameplay-playtesting/SKILL.md) tests actual human
  player experience; [game-content-qa](../game-content-qa/SKILL.md) verifies
  committed implementation coverage. Design alone proves neither.

## Gameplay contract

1. Inspect the approved brief and real source: audience, genre, input,
   platform, session length, accessibility, saves and excluded features.
   Distinguish requirements, source facts and explicitly labeled ASSUMPTIONS.
2. Define the central **player verb** and intent. For each core action,
   document prerequisites, player input, system response, feedback, state
   transition, risk/cost, and the next meaningful opportunity.
3. Close the loop: start → learn objective → action → response → outcome →
   progression/retry. Specify win/loss, failure and softlock recovery,
   no action, invalid input and interruptions. A cosmetic choice with no
   visible payoff is not demonstrated agency.
4. Specify teaching and challenge escalation: introduce a mechanic at low
   cost, combine it with others and allow recovery. Difficulty suitability
   is a hypothesis until observed in actual player sessions.
5. Enumerate applicable boundaries: input spam, pause/reload, bad save,
   missing audio, touch/keyboard alternatives, orientation, low frame rate.
   Avoid imposing unrelated physics, networking or economy requirements.
6. Assign stable IDs and concrete acceptance observations: trigger,
   conditions, expected state and visible feedback, success/failure,
   observable test and owner. Split MUST/OPTIONAL/CUT with approved decisions.
   Do not silently delete unmet requirements.
7. Define a falsifiable first-playable experiment for prototype-fast or
   actual engine Skill. Route comprehension/fun questions to genuine
   gameplay-playtesting; technical checks to native tests.
8. Send accepted mechanics and IDs to game-docs for authoritative GDD
   maintenance and to game-content-qa for implementation reconciliation.
   Keep decisions and allowed changes versioned in the game project.

## Output and gate

Use the [core-loop contract](references/core-loop-contract.md), covering one
primary loop and essential supporting loops, state chart, acceptance IDs
and open hypotheses. DESIGN_SPECIFIED means the rules are written, not that a
game runs. FIRST_PLAYABLE_VERIFIED requires a real runnable build and test
evidence. If key requirements conflict, return NEEDS_DECISION instead of
inventing rules or declaring G2 PASS.
