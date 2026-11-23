# Interface Design — evidence-gated workflow

**Applies to:** new or substantially revised web/application UI. Small fixes can skip irrelevant phases. Project authority and [design rules](../rules/design.md) take precedence; WFA is advisory and does not authorize implementation, merging or release.

| Stage | Work | Matching Skill | Evidence/gate |
|---|---|---|---|
| UI-0 | Read local instructions, user job, approved decisions, runtime, breakpoints and SEO/accessibility constraints | [visual-audit](../skills/design/visual-audit/SKILL.md) when auditing | Scope and explicit approval boundaries |
| UI-1 | Compare live references, separating structure and appearance donors | [design-reference-research](../skills/design/design-reference-research/SKILL.md) | Observed URLs, measured states and unverified gaps |
| UI-2 | Adapt existing components before choosing external libraries | [ui-component-reuse](../skills/design/ui-component-reuse/SKILL.md) | License, dependency and state inventory |
| UI-3 | Propose at most one useful standout technique, with static/reduced-motion fallbacks | [signature-visual-treatment](../skills/design/signature-visual-treatment/SKILL.md) | Failure-mode and device evidence; optional |
| UI-4 | Compare 3–5 variants visually for unresolved decisions | [design-variant-selector](../skills/design/design-variant-selector/SKILL.md) | Preview state + owner choice; optional |
| UI-5 | Record approved tokens, shared components and focused drift tests | [design-system-governance](../skills/design/design-system-governance/SKILL.md) | One authority, rule-to-code coverage |
| UI-6 | Verify real responsive/accessibility/performance behavior | [visual-qa](../skills/design/visual-qa/SKILL.md), [browser-qa](../skills/testing/browser-qa/SKILL.md) | Exact commit, device/viewport, screenshots, interaction outcomes |

Stop on missing authorization, unverified reference, license incompatibility, project-local stop-lines or unmet release requirements. A `DESIGN.md`, static spec test, live screenshot, human approval, browser run and SEO/performance measurement are different evidence categories; never promote one to another.

**Game/Ludory boundary:** do not apply web-oriented `?select`, browser tokens, external components or generic animation patterns to native runtime UI without explicit project authorization and project-local `ludory-*` rules. No updates to game assets, persistence, frozen games or platform gates from this playbook.

Reference reading: [«Дизайн сайта без нейрослопа»](https://vibecoding.ru/build/dizain-saita-bez-neiroslopa). External examples are guidance, not verified as applicable to every WFA project.
