# WFA game development routing — canonical paths and project ownership

**Operational index.** The preserved [upstream router](UPSTREAM.md) contains original
unprefixed engine paths (without the WFA gamedev root). Those paths do **not**
exist at the WFA root. Do not copy them verbatim, execute a referenced script
without inspection, or read an upstream link as higher priority than the
project's instructions.

## Canonical lookup

The 78 imported game-development Skills live in this WFA checkout under
`skills/gamedev/<category>/<skill-name>/SKILL.md`. Categories:

| Engine/discipline family | Correct WFA root |
| --- | --- |
| Cross-engine discipline | `skills/gamedev/disciplines/` |
| Genres | `skills/gamedev/genres/` |
| Game workflows (Steam, itch, GDD) | `skills/gamedev/workflows/` |
| Godot | `skills/gamedev/godot/` |
| Unity | `skills/gamedev/unity/` |
| Unreal | `skills/gamedev/unreal/` |
| Phaser, PixiJS, three.js | `skills/gamedev/web-engines/` |
| Other engines (Bevy, LÖVE, Defold, pygame, Roblox) | `skills/gamedev/other-engines/` |
| Ebitengine | `skills/gamedev/ebitengine/` |

**After user-scope installation**, the same Skills appear flattened as
`~/.agents/skills/<skill-name>/SKILL.md`. Select by unique Skill name and
confirm the repository or installed directory exists. The upstream
`create-game-assets` is **not installed as a second Skill**: read WFA
`production-art`, with preserved upstream material at
`skills/domain/production-art/references/gamedev-create-game-assets/UPSTREAM.md`.
The upstream `router` is **not a second Skill**: this index and
`task-planning` own routing. The preserved upstream version-support guide
was imported to `docs/gamedev-upstream/docs/VERSION-SUPPORT.md`.

References inside retained upstream material are historical. For executable
instructions, use the canonical mapping above or an independently resolved
installed Skill path. Do not guess an API from a documentation example.

## Resolution and precedence

1. Confirm target repository, current loaded entrypoint and governing
   `AGENTS.md`. Distinguish code actually imported at runtime from optional
   adapters and packages.
2. Match a **single actual engine**. Custom/proprietary engines are valid.
   If the host runtime is not verified, return UNKNOWN instead of picking a
   framework from an incidental dependency.
3. Use the smallest needed genre/discipline/workflow Skills. Project-local
   rules, frozen-game boundaries, rights, production gates and release
   permissions outrank global examples. Never auto-run imported scripts.
4. On Ludory tasks, consult
   [Ludory compatibility rules](../ludory-compatibility.md). Ludory framework
   ownership is not the same as new Studio game's local Skill ownership.
5. Select Steam/itch publishing instructions **only** for actually targeted
   Steam/itch publications; no inferred SDK or platform support.
6. For unrelated native Phaser games where the entrypoint is verified,
   `phaser-core` remains available; the Ludory exception is NOT global.

This is a selection policy, not a tool that can itself execute commands,
change a project, or prove Codex selected the correct Skill. Use the
[offline compatibility fixture runner](../../../../../scripts/ludory_compatibility.py)
for deterministic policy examples and separate Codex activation evals for
actual model behavior.
