---
name: character-consistency-qa
description: >-
  Use to independently audit whether existing game character images preserve
  identity across front/side/back views, expressions, poses, costumes and CGs.
  Compare real pixels to a locked canonical reference, verify provenance and
  report drift without falsely treating file hashes or similarity scores as
  artistic proof. Not for initial character design or generic UI QA.
---

# Character Consistency QA — independent visual identity gate

Run this on **existing real character image files** after character-design has
produced its canonical pack, and whenever variants are changed or newly
integrated. This is a verifier, not the creator/generator. Follow
[production-art](../production-art/SKILL.md) for asset provenance and
[visual-qa](../../design/visual-qa/SKILL.md) for actual gameplay pixels.

## Inputs and separation of responsibilities

- Approved Character Bible revision, character ID, master reference **bytes
  and SHA-256**, art direction, allowed variants, candidate images and
  scene-to-asset mapping. Compare against the exact same pinned master.
- Inspect actual source images and a side-by-side contact sheet; never accept
  prompts, thumbnails, filenames or model responses in place of image bytes.
- Distinguish **source-art identity** from **runtime rendering**; a valid source
  can still be miscropped, distorted, missing, or paired with the wrong
  character in Ludory.

## Audit workflow

1. **Bind the snapshot.** Record project commit, card revision/hash, canonical
   master SHA-256 and each candidate path/hash. Check the source is currently
   approved and identify any intentionally revised canon.
2. **Mechanical checks.** Confirm every required view/expression exists and
   is a real decodable image; verify hash, dimensions, opacity/alpha needs,
   duplicate candidates, labels vs expected viewpoints, actual source/license
   record and any project asset-manifest links. Reuse
   [create-game-assets raster QA](../production-art/references/gamedev-create-game-assets/UPSTREAM.md)
   for technical image checks and preview sheets. A machine-check PASS proves
   **only** mechanical properties.
3. **Face and body.** Compare actual images to the original master:
   face shape, eye color/spacing, nose/jaw, hairline, distinctive marks,
   head-to-body proportions and silhouette. Compare front to 3/4 to side;
   in back view inspect only observable hairstyle, outfit and anatomy.
4. **Variants.** Verify expression changes do not become a new person;
   clothing variants retain identity and explicit story-state rationale;
   lighting and perspective changes are judged against their declared
   allowances, not arbitrarily normalized away. Confirm consistent base
   outfit seams, palette, accessory placement and left/right orientation.
5. **Multi-image continuity.** Inspect contact sheet grouped by character,
   view, emotion and costume, then individual originals at full resolution.
   Catch swapped/duplicated views, mirrored asymmetrical marks, anatomical
   changes, inconsistent body scale, crop cutting critical detail, fake alpha,
   artifacts and contradictory expression labels.
6. **Independent visual observation.** Use a genuinely available image-capable
   reviewer if independent review is required; document exactly which pixels,
   review conditions and output were observed. If not available, mark
   ARTISTIC_NOT_RUN or LOCAL_REVIEW_ONLY; do not fabricate a reviewer result.
   Human visual judgment is distinct from embedding/similarity scores.
7. **Report actionable findings.** Use
   [the report contract](references/report-contract.md), including every
   candidate and exact evidence. Assign severity and explicit remediation
   from the original canonical master, not a chain of drifted derivatives.
   Repeat the relevant review after rework against the same reference.
8. **Runtime handoff.** After artistic checks, run visual-qa in the real
   browser/game on desktop and portrait mobile, inspecting actual displayed
   images, scene mapping, scaling, crop and readability. A source-art PASS
   cannot promote runtime/platform status to PASS.

## Severity and decisions

- **P0 / FAIL_IDENTITY:** wrong person, swapped character, conflicting canon,
  or severe facial/body identity change. Reject affected candidate.
- **P1 / REWORK:** visible face, proportions, hairline, marks, costume, view or
  expression drift against locked invariants. Reject affected candidate.
- **P2 / NOTE:** minor artifacts or stylistic differences within allowable
  variation. May pass only if no required P0/P1 remains and evidence exists.
- **EVIDENCE_GAP / BLOCKED:** missing file, inaccessible real pixels, unknown
  reference, unsupported tool or unknown reviewer provenance. Never PASS.

Never collapse ratings into an invented percentage like "97% same person".
Hashes and image embeddings may detect duplication or point to differences,
but cannot verify appearance, artistic quality or legal rights alone.

## Required report outcome

Emit a source-bound report with separate:
- **MECHANICAL:** PASS / FAIL / BLOCKED (bytes, hashes, sizes, completeness).
- **ARTISTIC:** PASS / REWORK / BLOCKED / NOT_RUN (observed identity).
- **RUNTIME:** PASS / FAIL / BLOCKED / NOT_RUN (actual browser pixels).
- **RIGHTS:** VERIFIED_BY_AUTHORIZED_REVIEW / BLOCKED / NOT_RUN; never derive
  ownership or license approval from an AI-generated image or its hash.

Overall CANDIDATE_ACCEPTED_FOR_INTEGRATION requires current mechanical PASS
and observed artistic PASS with no unresolved P0/P1. It **does not** imply
release permission. Missing independent review requested by the project is
BLOCKED even if local inspection appears satisfactory.

This skill does not grant upload, public release, platform moderation,
automatic regeneration or a license declaration.
