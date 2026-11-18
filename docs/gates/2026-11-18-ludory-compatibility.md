# Ludory Compatibility Gate — source-bound review

Date: 2026-11-18. **Scope:** WFA integration only, Ludory source untouched.

## Verified input revisions

- WFA baseline: `e6518146578b1c06310cde96aa305808a303121c` (107 Skills, 78 imported game Skills).
- Ludory: `933c73b195eaf3bfffd12a31ab1cbadb27989eea`.
- Imported game Skills: `gamedev-skills/awesome-gamedev-agent-skills@c6ca6c41c839b68319ffc08430b99ab768debc32`.
- Authority: Ludory `AGENTS.md`, 13 project-local `ludory-*` Skills, WFA Ludory profile, WFA importer manifest and router reference.

## Findings and fixes

1. **HIGH / routing:** preserved upstream router contains obsolete source-relative `skills/godot/`, `skills/web-engines/` paths. It was inappropriately linked as the operational WFA router. The new `WFA-ROUTING.md` is now the operational index with canonical `skills/gamedev/<category>/<skill>/SKILL.md` paths. The pinned upstream reference remains unmodified.
2. **HIGH / custom engine:** a `phaser` dependency or adapter must not select `phaser-core` for the Ludory framework. New routing explicitly requires a verified loaded runtime and treats Ludory as a custom engine. A separate standalone Phaser game remains eligible for Phaser Skills.
3. **HIGH / conflicting art pipeline:** WFA `production-art` is conceptual only on Ludory tasks. For eligible new Studio games, `ludory-production-art` controls ImageGen agent handoff, original/source hashes, import and independent review, and `ludory-asset-rights` controls documentary rights. No generic Skill can authorize generation/upload or CEOS.
4. **MEDIUM / persistence:** `save-systems` and `visual-novel` cannot impose Godot/desktop atomic rename or save migrations over Ludory's native runtime format, version checks or deliberate Back semantics.
5. **HIGH / release:** Steam/itch workflows are never inferred as substitutes for native VK/Yandex Connect, Release, owner approval, rights and platform acceptance.
6. **HIGH / scope:** native `ludory-*` skills are mostly restricted to authorized new Studio-created games. Ludory framework code is governed by its package owner and `AGENTS.md`; frozen CEOS/Starter Kit games remain read-only. The profile's protected skill inventory now covers all 13 local names.

## Gate execution categories

- **SOURCE_REVIEWED:** current source contracts inspected; pinned external references above.
- **OFFLINE_POLICY:** `python scripts/ludory_compatibility.py --cases evals/cases/ludory-compatibility/scenarios.json` exercises 20 positive, near-miss and negative cases; deterministic policy from preverified fixture inputs only.
- **STATIC_INTEGRITY:** Python validator, unittest and Windows smoke run in GitHub Actions on exact final SHA.
- **CODEX_ACTIVATION:** **NOT RUN**; fixture routing is not real agent selection or runtime permission to read local Skills.
- **LUDORY_RUNTIME:** **NOT RUN**; no source modification, studio game, browser, release, image generation or platform submission.
- **GLOBAL_HOME:** **NOT TOUCHED**; 107 WFA source Skills do not imply 107 installed in the user's HOME.

## Positive and negative policy cases

The 20 prepared/executed **offline** cases cover optional Phaser adapter vs real standalone Phaser, engine vs new Studio vs frozen provenance, narrative editing vs independent prose review, authorized/unauthorized image generation, art rights, native saves, UI, VK/Yandex release and owner approval, missing Studio evidence, unrelated prompts, visual QA and framework fixes. See [scenario evidence](../../evals/cases/ludory-compatibility/scenarios.json).

These are metadata-level assertions and do **not** prove source verification; `source_verified` is explicitly test-fixture input. No product or agent operation is executed by the classifier.

## Remaining approval gates

- Run actual Codex positive and negative activation tests for representative Ludory operations with source-read/tool evidence in a disposable workspace, preserving project `AGENTS.md` and `ludory-*` local skill precedence.
- Re-evaluate pinned Ludory scope when its source HEAD or local Skills change.
- Only after separate user authorization may newer WFA global Skills be synced/installed with the transactional backup, preflight and recovery gates.
- Future code changes in Ludory require project-native tests, independent art rights, platform and owner approval. This compatibility gate does not declare any game or platform release-ready.
