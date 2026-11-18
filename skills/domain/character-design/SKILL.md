---
name: character-design
description: >-
  Use when designing or producing a recurring game character's visual identity:
  Character Bible, master reference, turnaround views, expression sheet, costume
  variants and canonical image references. Do not use for prose-only character
  writing or independent acceptance of already generated art.
---

# Character Design — canonical game character production

Use this skill to **define and produce** a character reference pack, not to
certify that the generated pixels are consistent. Use
[production-art](../production-art/SKILL.md) for general art/provenance rules and
[character-consistency-qa](../character-consistency-qa/SKILL.md) for independent
identity review. These skills do not replace the project's engine, source art
rights gate, or official platform approval.

## Scope and routing

- **Activate:** new recurring character, locked appearance for a visual novel,
  multiple views, expression/pose/costume variants, or an identity-preserving edit.
- **Do not activate:** dialogue personality alone, story/route structure alone,
  generic environments/UI, Roblox rigs or unrelated 3D animation setup.
- **Inputs:** approved game art direction, narrative role and physical facts,
  engine/display constraints, scene/use-site inventory, rights policy, available
  generator/editing tools and permission to create assets.
- **Output:** versioned character card plus **real source images** and their
  exact references. A Markdown prompt or contact sheet alone is not an asset.

## Canonical workflow

1. **Inspect before creating.** Read existing Story Bible, art direction,
   project-owned assets, WFA profile and asset manifest. Distinguish already
   approved canon from suggestions. Do not redesign a frozen cast implicitly.
2. **Lock observable identity.** Create a card using
   [the template](references/character-bible.example.json). Record stable ID,
   character name, approximate age, silhouette, head/body proportions, face
   structure, skin/hair/eye colors, distinctive marks and stable hairline.
   Describe positive and negative visual anchors, not only adjectives. Record
   narrative personality separately from pixel-verifiable features.
3. **Separate invariants from permitted variation.** Define base outfit and
   canonical palette; enumerate permitted clothing, expressions, poses, lighting
   and timeline states. Make explicit what may change (e.g. wet hair, coat)
   without silently changing identity. A deliberate canonical change requires
   a new revision and a migration note for dependent assets.
4. **Produce a canonical master.** Use a real, authorized image tool and save the
   original full-resolution bytes. Choose a neutral, well-lit master/reference
   with an unobstructed face and relevant full-body proportions. Confirm visual
   direction before generating a large batch. If the generator is unavailable
   or unauthorized, mark GENERATION_BLOCKED and stop at the brief; never fake an
   image, receipt, or approval.
5. **Produce a turnaround from that same master, not from prompt-only memory.**
   Follow [the view specification](references/turnaround-and-expression-spec.md):
   front, three-quarter, side and back full-body neutral views; consistent
   scale, anatomy, costume and pose family. Preserve actual individual source
   frames if generating a sheet. A grid with swapped or duplicated views is
   not a valid turnaround. Back-view face identity is inferred only through
   supporting hairstyle/body/outfit evidence, never asserted from invisible
   facial pixels.
6. **Make expressions and costumes.** Derive neutral plus game-required emotions
   from the canonical face. Use separately identified costume families and
   story-state variants. Lock identity across crops, poses and camera directions;
   permit lighting differences only when declared.
7. **Register originals and derivations.** Record actual relative paths,
   SHA-256, pixel dimensions, alpha requirements, generation/edit provenance,
   licenses and a reference lineage from the approved master to every
   derivative. Reuse the project asset manifest and the image checks in
   [create-game-assets](../production-art/references/gamedev-create-game-assets/UPSTREAM.md);
   do not create a competing WFA-wide asset database.
8. **Handoff for independent review.** Feed the current card revision, master,
   candidate set and use-site map into character-consistency-qa. Reject/rework
   candidates with identity drift **from the canonical master**, rather than
   repeatedly editing a drifting derivative. Integrate only approved images,
   then run the existing production-art and visual-qa runtime checks.

## Reference discipline

- One **stable character ID** across story, art and game references; no silent
  replacement of the canonical master or reuse of IDs for a new person.
- The approved reference and its hash are the identity anchor. Text descriptions
  and model seeds are supplemental; seeds alone do not prove identity.
- Explicitly name each view and expression; check that each real file matches
  its label. Do not call an image file an approved multi-angle sheet without
  visual inspection.
- Portrait, CG and sprite crops must be checked at real game scale. Preserve
  uncropped originals; do not use destructive face upscaling as source truth.
- Character identity checks are **not** inferred from CLIP/perceptual similarity
  or numeric model confidence alone. Different pose, mood and lighting may be
  valid. Art review is a separate evidence gate.

## Acceptance and blockers

- READY_FOR_CONSISTENCY_QA requires a real approved master, current versioned
  card, named required views, readable image files, real dimensions/hashes and
  source/license declarations. This is **not** artistic PASS.
- Missing generator capability, permissions or real reference pixels yields
  BLOCKED; missing mandatory view yields INCOMPLETE; conflicting project canon
  yields NEEDS_PROJECT_DECISION.
- Do not declare an asset RELEASE_READY without separate mechanical, artistic,
  runtime, platform and rights checks. Never manufacture missing image evidence.
