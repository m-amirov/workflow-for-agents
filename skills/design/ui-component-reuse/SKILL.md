---
name: ui-component-reuse
description: >-
  Use when selecting, adapting or introducing reusable UI components from a
  project or external library; do not activate for content-only or backend tasks.
---

# UI Component Reuse

## Procedure
1. Inventory project-owned components, styling utilities and dependency constraints. Prefer existing accessible, maintained components and approved tokens.
2. Define required behaviors and states: keyboard, touch, hover/focus, loading, error, disabled, reduced motion and responsive layout.
3. If considering an external component (e.g. React Bits or 21st.dev), inspect its **actual code, version, dependency tree and license**. Record source/attribution requirements; reject unverified ownership, inaccessible interactions, incompatible SSR or unbounded bundle cost.
4. Adapt the smallest component surface to project semantics and tokens; avoid global CSS leakage, unnecessary dependencies and wholesale copying of demo layouts.
5. Verify runtime behavior, accessibility and viewport states; record evidence and resource/performance impact. Run project-native tests and focused regression tests.

## Output
Component inventory; source/version/license; choice rationale; changed paths; tested states and **NOT RUN** gaps. Do not call a copied component production-ready because it renders.

## Boundaries
Project-owned UI and local `AGENTS.md` take precedence. Do not install new packages without implementation authorization.

Related: [UI design policy](../../../rules/design.md), [interface design process](../../../playbooks/interface-design.md).
