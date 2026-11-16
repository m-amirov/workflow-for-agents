---
name: video-production
description: >-
  Use for gameplay recordings, platform evidence videos, promo trailers,
  cinematic showcases, or release-video validation from a real runtime.
metadata:
  migration: ceos
  source_sha: c8cc13bd3852409be93097ee823e9cd35e512b73
  status: adapted
  integration: autonomous
  optional_tools: ffmpeg, ffprobe, connected editor when actually available
---

# Video Production

Lock mode (`gameplay-evidence` or `promo-trailer`), platform/locale,
resolution/aspect ratio, duration/size limits and the output contract. Read
project-native requirements rather than assuming a platform rule.

## Gameplay evidence

Capture the real production runtime. Keep required locale/UI and genuine
choices/outcomes visible; remove OS/editor/debug chrome. Editing is allowed
only when it does not misrepresent gameplay. Validate the final MP4 itself:
dimensions, duration, codec/container, bytes, SHA-256, language and required
manual-review fields. A promotional edit, editor preview or project URL is not
gameplay evidence.

## Promo trailer

Cinematic pacing, title cards, licensed/owned music, sound design and
transitions are allowed, but keep provenance separate from platform evidence.
Produce a separate evidence render when both outputs are needed.

Preserve raw clips and record source HEAD, locale, scene/state, viewport, edit
toolchain, output path/hash and review evidence. Use `ffmpeg`/`ffprobe` or
project-native tools when installed. Descript is optional and external writes
require explicit authorization. If the real runtime, source clips, export or
final inspection is missing, return `BLOCKED` rather than claiming completion.
