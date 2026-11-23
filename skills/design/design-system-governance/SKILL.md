---
name: design-system-governance
description: >-
  Use when establishing, extending or preventing drift of an approved UI design
  system and its spec tests; do not replace visual inspection with static checks.
---

# Design System Governance

## Procedure
1. Inspect existing `DESIGN.md` or equivalent, code tokens, components, project instructions, approved screenshots and exceptions. **Never create competing sources of truth**.
2. Record semantic rules in the existing authority: text roles (family/size/line-height/weight/color), grids, spaces, surfaces, radii, breakpoints, states and mobile adaptations. Separate proposed measurements from approved values.
3. Map each approved token to real shared code values and reusable components. State exceptions explicitly; don't invent global redesigns while fixing one view.
4. Add **targeted spec tests** preventing known regressions (e.g. a forbidden font or token bypass), including a negative fixture where reasonable. A test of CSS strings cannot certify the rendered layout.
5. Provide a small reference/sample view using **real** project components where proportionate; verify desktop/mobile visual renders and keyboard/mobile interactions using [visual-qa](../visual-qa/SKILL.md) or [browser-qa](../../testing/browser-qa/SKILL.md).
6. Report authority location, token/code mappings, test coverage scope, screenshots and missing evidence. New variants require owner approval before becoming defaults.

## Boundaries
Preserve app-specific architecture and Ludory's native UI/art/release constraints; no automatic release or dependency changes. Use [visual-audit](../visual-audit/SKILL.md) for critique, not as a substitute for governance.

Related: [UI design policy](../../../rules/design.md), [interface design process](../../../playbooks/interface-design.md).
