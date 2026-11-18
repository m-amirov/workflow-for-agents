# Canonical view and expression contract

## Minimum turnaround

For the same **character ID, card revision and master SHA-256**, produce:
front full-body, three-quarter full-body, side full-body and back full-body.
Use a neutral pose, level baseline, unchanged body proportions and base outfit.
Each view must have a stable label and an individually inspectable original
image; a combined sheet is optional, not a substitute for originals.

- **Front:** unobscured face, visible body silhouette, distinct marks.
- **Three-quarter:** bridge between front and profile, identifiable eyes/nose.
- **Side:** true profile, hairline, nose, jaw and body volume.
- **Back:** rear hair silhouette, clothing seams and proportions. Do not invent
  facial-consistency evidence for a hidden face.

## Expressions

Default reference set: neutral, happy, sad, angry, afraid and surprised. Use
only the emotions needed by the actual game, but include a neutral baseline.
Preserve face topology, eye placement/shape, nose, hairline, marks and camera
geometry; intentional mouth, brow, eyelid and cheek changes are allowed.

## Production settings

Before generation, fix portrait/landscape use cases, resolution, transparent
background policy, baseline/pivot, light direction, palette, framing and
compression. Keep originals unmodified and record separately every cropped or
compressed derivative with its own hash and parent ID. Never treat the same
image duplicated under four view names as four valid views.

## Asset matrix and review

For each planned file record character ID, canonical revision and SHA, view,
expression, costume, scene/use-site, dimensions, alpha expectation, rights
evidence, image origin, status and source hash. Inspect full-size originals,
then native-scale game previews. For new viewpoints prioritize independent
visual inspection against the master and adjacent views; mechanical checks
alone cannot prove recognizable identity.
