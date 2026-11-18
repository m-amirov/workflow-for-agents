---
name: production-art
description: >-
  Use to plan, generate, integrate and verify source-bound production image
  assets, visual canon, asset manifests and runtime scene-to-art mapping.
metadata:
  migration: ceos
  source_sha: c8cc13bd3852409be93097ee823e9cd35e512b73
  status: adapted
  integration: autonomous-with-optional-capabilities
  overlaps: visual-qa, visual-audit, browser-qa
---

# Production Art

This Skill preserves the source-bound art contract without requiring a
particular model, subagent, Web route, ImageGen service or CEOS engine.

## Contract

1. Lock product scope and invariants: story/gameplay topology, state schema,
   canon, mechanics, release scope and accepted staging constraints.
2. Inventory every required use site in an asset manifest: family, subject or
   location, state/expression/variant, dimensions/aspect ratio, transparency,
   status and runtime mapping.
3. Establish canon and write a source-bound brief with provenance before any new generation.
   Record exact source HEAD and SHA-256 for references, authored cue/action,
   forbidden props, continuity rules and desktop/portrait framing.
4. Use a real authorized image generator only when the actual invoking context
   exposes it and the user has authorized the action. If unavailable, return
   `BLOCKED`; do not create placeholders, describe imaginary pixels or invent a
   generation receipt/model route.
5. For every actual output, persist the original bytes as a real image, record
   dimensions and SHA-256, and verify decodability/alpha/cropping as applicable
   before the next candidate. A chat preview or filename is not a file.
6. Integrate only actual project-owned files, update the asset-to-scene manifest
   and runtime mapping, and protect unrelated assets.
7. Run fresh runtime visual QA for each affected cue/viewport class. Verify
   the event before/after the cue, observed asset source/hash, preload/fallback
   behavior and dialogue-safe framing.

## Acceptance separation

Keep these gates independent and label each one:

- `mechanical`: files, bytes, SHA-256, dimensions, manifest coverage and
  source-to-scene mapping;
- `artistic`: actual pixels, identity, style/canon, composition, action and
  continuity reviewed by an independent available reviewer;
- `platform/runtime`: current browser/runtime pixels, viewport selection,
  loading, crop, mobile/desktop behavior and platform requirements.

Mechanical PASS never promotes artistic or platform acceptance. Missing real
pixels, references, permission, runtime evidence or required reviewer is
`BLOCKED`, not PASS. A transport or quota failure is not an art defect and must
not trigger unbounded retries.

For visual novels, if the project contract requires dual-format CGs, require
distinct real portrait and desktop files with current dimensions/hashes and
separate runtime checks; do not stretch or crop one file into proof of both.
Use `visual-qa` after integration. No external upload, publication or paid
generation is authorized by this Skill.

## Game development library integration

For game-art families, sprite sheets, alpha/crop validation and asset QA, use the complementary [game-asset production reference](references/gamedev-create-game-assets/UPSTREAM.md) and its preserved scripts/templates. Keep source provenance, independent artistic review, asset-rights and runtime pixel gates separate; the reference does not authorize generation or publication.
