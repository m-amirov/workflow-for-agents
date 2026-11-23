---
name: signature-visual-treatment
description: >-
  Use when a user-approved screen needs one deliberate standout visual effect
  or motion treatment; do not add effects to routine pages by default.
---

# Signature Visual Treatment

## Procedure
1. Name the single visual idea and the **meaning/user task** it supports. If decorative motion adds no value, prefer the static treatment.
2. Check project design tokens, target devices, supported browsers and performance/SEO constraints before selecting SVG/CSS/Canvas/WebGPU/etc.
3. Implement a complete static state first. Keep content and primary actions usable with unsupported APIs, disabled JS where applicable, failed initialization or unavailable GPU.
4. Add animation only if authorized. Respect `prefers-reduced-motion`, focus, contrast, and visibility-based pause. Avoid layout shifts and large startup costs.
5. Test ordinary mode, unsupported/disabled effects, initialization failure, reduced motion and relevant phone/desktop viewports. Measure performance when feasible; don't infer smoothness from screenshots.
6. Report fallback behavior and actual tested browsers/devices. Revert/simplify effects that hurt the task or declared performance budgets.

## Boundaries
Not a mandate to add WebGPU, animation libraries or a second accent to every section. Project runtime and native render owners win (including Ludory).

Related: [UI design policy](../../../rules/design.md), [visual-qa](../visual-qa/SKILL.md).
