# Каталог Agent Skills

**Статусы:** implemented = в репозитории есть рабочее описание SKILL.md; planned = запланировано, но пока не реализовано. **Implemented не означает validated:** фактическое выполнение сценариев и соответствие конкретному агенту необходимо проверять отдельно. Skills Stage 8 помечены `implemented` для адаптированного контракта; runtime activation и внешние platform gates остаются отдельными статусами в migration report.

| Категория | Skill | Когда использовать | Статус |
|---|---|---|---|
| Core | task-planning | План и adaptive routing по TYPE/SIZE/RISK, review gates, DOCS_IMPACT и anti-loop | implemented |
| Development | codebase-exploration | Найти правильное место изменения по коду | implemented |
| Development | root-cause-debugging | Ошибка, регрессия, нестабильное поведение | implemented |
| Testing | regression-testing | Защитить исправление от повторного сбоя | implemented |
| Development | code-review | Проверить код и архитектурные риски | implemented |
| Development | minimal-change | Внести локальное изменение без лишнего рефакторинга | implemented |
| Development | git-workflow | Main-first: работа в main, merge проверенного результата и очистка своих временных веток | implemented |
| Testing | release-verification | Проверить сборку и release gates | implemented |
| Design | visual-audit | Независимая оценка UI и визуальной целостности | implemented |
| Frontend | responsive-design | Адаптивность и геометрия экрана | planned |
| Design | interaction-design | Жесты, состояния и взаимодействия | planned |
| Frontend | accessibility-audit | Доступность UI | planned |
| Testing | browser-qa | Сценарии в реальном браузере | implemented |
| Domain | interactive-fiction | Ветвления, решения, переменные, концовки | planned |
| Domain | game-visual-integrity | Ассеты, шрифты, CG, изображения и экраны игры | planned |
| Domain | drawing-editor | Безопасные document/layer/history/pointer contracts для Canvas-редакторов | implemented |
| Automation | browser-automation | Stateful browser automation с lease, durable fence и independent receipt для внешних side effects | implemented |
| Automation | document-extraction | Поля и разметка документов/PDF | planned |
| Automation | classification-quality | Независимые labels, offline replay, baseline и fail-closed quality gates | implemented |
| Domain | seo-calculators | Полезные SEO-инструменты и калькуляторы | planned |
| Content | content-pipeline | Конвейер подготовки и проверки публикаций | planned |
| Development | audit | Read-only аудит с evidence и классификацией findings | implemented |
| Development | audit-repair-loop | Ограниченный audit → repair → verification → fresh re-audit | implemented |
| Development | ceos-continue | Только явно запрошенное продолжение CEOS run/checkpoint | implemented |
| Development | fix | Reproduce → root cause → minimal fix → regression → verification | implemented |
| Testing | verification | Независимая проверка acceptance claims | implemented |
| Testing | release | Release candidate gates и exact artifact evidence | implemented |
| Design | visual-qa | Runtime/browser visual evidence и viewport QA | implemented |
| Content | video-production | Gameplay evidence и отдельный promo trailer pipeline | implemented |
| Domain | romance-narrative | Romance-first concept и bounded editorial review | implemented |
| Domain | narrative-dialogue-editor | Voice, subtext, localization и branch-safe line editing | implemented |
| Domain | narrative-continuity-engine | Route-conditioned continuity и save/back evidence | implemented |
| Domain | reader-experience-review | Bounded blind-reader comprehension and payoff review | implemented |
| Domain | production-art | Source-bound art provenance, mapping and separate acceptance gates | implemented |
| Operations | prod-check | Read-only production inspection | implemented |
| Operations | incident-analysis | Incident timeline и causal evidence analysis | implemented |
| Operations | logging-standard | Структурированные события, trace/request correlation, retries/fallback, privacy-safe диагностика | implemented |

<!-- gamedev-managed:start -->

## Game development — sourced and deduplicated

Source: https://github.com/gamedev-skills/awesome-gamedev-agent-skills/tree/c6ca6c41c839b68319ffc08430b99ab768debc32. These Skills are imported descriptions, not runtime activation PASS.

| Категория | Skill | Когда использовать | Статус |
|---|---|---|---|
| GameDev discipline | ai-behavior-trees-utility-ai | Engine-neutral behavior tree and utility AI code for NPCs in any language: Blackboard, reactive composites, decorators and response-curve scoring. | implemented |
| GameDev discipline | audio-design | Engine-neutral game audio technique: bus layout, volume sliders in decibels, loudness, ducking music under dialogue, adaptive music and SFX variation, with Godot, Unity and FMOD/Wwise mappings. | implemented |
| GameDev engine | bevy-ecs | Builds and debugs Bevy 0.20 games in Rust: components, Query and Commands systems, schedules, States, observers and headless tests. | implemented |
| GameDev discipline | camera-systems | Builds and tunes game cameras, engine-neutral with Godot and Cinemachine 3 mappings: 2D follow with deadzone and look-ahead, third-person orbit, first-person look and split-screen. | implemented |
| GameDev genre | card-game | Designs card games and deckbuilders in any engine: cards as data with one effect interpreter, deck zones, a trigger stack and seeded shuffles. | implemented |
| GameDev engine | defold-core | Builds and debugs Defold 1.14 games in Lua: collections, game objects, input focus, msg.post messaging, factories, collection proxies and Bob builds. | implemented |
| GameDev discipline | dialogue-systems | Builds engine-neutral branching dialogue with Ink, Yarn Spinner or a small JSON graph runner: lines, choices, conditions, variables and localization IDs. | implemented |
| GameDev engine | ebitengine-game | Creates, debugs and packages 2D games in Go with Ebitengine v2: a play-and-retry loop, input, pixel-art scaling, text, audio and desktop, WASM or mobile builds. | implemented |
| GameDev genre | fps-shooter | Designs first-person shooter combat in any engine: hitscan vs projectiles, time-to-kill, damage falloff, recoil patterns, ADS sensitivity and lag-compensated hits. | implemented |
| GameDev discipline | game-ai | Designs engine-neutral enemy and NPC AI: picks FSM, behavior tree, utility or GOAP, and builds perception, steering and A* pathfinding. | implemented |
| GameDev workflow | game-docs | Writes and maintains a game's design docs: a one-page GDD with a feature index and short feature notes, kept true to the code by a link and status checker. | implemented |
| GameDev discipline | game-feel | Adds engine-neutral juice to a working mechanic: trauma-based screen shake, hit-stop, eased tweens, squash and stretch, and knockback. | implemented |
| GameDev workflow | game-jam | Plans and ships a game jam entry against a fixed deadline: reads the jam rules, scopes to the clock, keeps a cut list and checks the build before submitting. | implemented |
| GameDev discipline | game-ui-ux | Engine-neutral design rules for game HUDs and menus: anchors and containers, scaling, safe areas, gamepad focus, HUDs driven by events instead of polling, and accessibility minimums. | implemented |
| GameDev engine | godot-2d-movement | Godot 4.7 CharacterBody2D movement in GDScript: platformer run and jump, top-down 8-direction motion, slopes and one-way platforms, with a headless landing test. | implemented |
| GameDev engine | godot-3d-essentials | Godot 4.7 3D scene setup: Camera3D, lights, WorldEnvironment (sky, ambient, tonemap, fog), StandardMaterial3D, GridMap and local vs global transforms, with a headless scene check. | implemented |
| GameDev engine | godot-animation | Godot 4.7 animation APIs: AnimationPlayer, AnimationTree state machines, AnimatedSprite2D and create_tween() Tweens, with a headless state test. | implemented |
| GameDev engine | godot-audio | Godot 4.7 audio APIs: AudioStreamPlayer 2D and 3D, the bus layout, AudioServer volume and mute, polyphony, looping imports and playback position for beat sync. | implemented |
| GameDev engine | godot-csharp | C# and .NET in Godot 4.7: partial node classes, the PascalCase lifecycle, [Export] and [Signal], signals as C# events, the .csproj and calling GDScript. | implemented |
| GameDev engine | godot-export | Exports Godot 4.7 projects: templates, export_presets.cfg for desktop, Web and Android, command-line exports and web COOP/COEP headers. | implemented |
| GameDev engine | godot-gdscript | GDScript 2.0 for Godot 4.7: static typing, @export and @onready, await and coroutines, and porting 3.x code. | implemented |
| GameDev engine | godot-gdscript-headless-testing | Runs Godot 4.7 GDScript tests with godot --headless and a SceneTree runner that exits non-zero on failure, so CI can gate merges. | implemented |
| GameDev engine | godot-multiplayer | Godot 4.7 high-level multiplayer: ENet host and join, @rpc with rpc_id(), MultiplayerSpawner and MultiplayerSynchronizer, with a two-instance headless test. | implemented |
| GameDev engine | godot-nodes-scenes | Godot 4.7 scene-tree structure: reusable .tscn scenes, instantiate(), autoloads and a checker for broken res:// paths and uids. | implemented |
| GameDev engine | godot-physics | Godot 4.7 physics API in 2D and 3D: body and Area types, collision_layer and mask bits, Area signals for hurtboxes, RayCast and space queries, and Jolt (3D default since 4.6). | implemented |
| GameDev engine | godot-resources | Godot 4.7 data-driven design with custom Resources: class_name and @export fields, .tres files, shared references vs duplicate_deep(), uids and threaded loading. | implemented |
| GameDev engine | godot-shaders | Godot 4.7 Shading Language syntax and pipeline: canvas_item, spatial and particle shaders, built-ins, ShaderMaterial wiring, a headless compile check and 3.x porting. | implemented |
| GameDev engine | godot-signals-groups | Godot 4.7 signals and node groups: typed signals, connect() with Callables, one-shot and deferred connections, event-bus autoloads and call_group broadcasts. | implemented |
| GameDev engine | godot-tilemap | Godot 4.7 tile maps with TileMapLayer and TileSet: atlas sources, data layers, terrain autotiling and set_cell or local_to_map at runtime. | implemented |
| GameDev engine | godot-ui-control | Godot 4.7 Control-node API for menus and HUDs: anchors, Containers, Theme and StyleBox, focus neighbours and stretch settings, with a headless layout check. | implemented |
| GameDev discipline | input-systems | Engine-neutral input architecture with Godot InputMap code: named actions, stick deadzones, buffered presses and rebinding with conflict checks. | implemented |
| GameDev workflow | itch-publish | Publishes and updates games on itch.io with the butler CLI: butler push to user/game:channel, channel platform tags, HTML5 builds, --userversion and CI uploads. | implemented |
| GameDev discipline | level-design | Engine-neutral level design with Godot checks: player metrics from the real controller, key and ability gating with a soft-lock check, and pacing. | implemented |
| GameDev engine | love2d-core | Builds and debugs LÖVE (Love2D) 11.x games in Lua: main.lua callbacks, conf.lua, fixed steps, crisp pixel-art scaling, love.filesystem saves and a scripted run. | implemented |
| GameDev discipline | performance-optimization | Finds and fixes game frame-rate problems by measurement in Godot, Unity, Unreal or Roblox: CPU- vs GPU-bound, then the biggest fix (draw calls, pooling, GC spikes). | implemented |
| GameDev engine | phaser-arcade-physics | Phaser 4 Arcade Physics movement and collision: bodies, velocity, gravity, colliders vs overlaps, groups and bullet pools. | implemented |
| GameDev engine | phaser-core | Sets up and debugs Phaser 4 games (and pinned Phaser 3.90): Game config, Scene lifecycle, the loader, scene transitions and Phaser 3 to 4 migration. | implemented |
| GameDev discipline | physics-tuning | Engine-neutral physics tuning with Godot checks: fixed timestep and interpolation, CCD against tunnelling, damping, solver iterations and collision layer matrices. | implemented |
| GameDev engine | pixijs-rendering | Builds and debugs 2D browser game rendering with PixiJS v8: async init, Assets loading, the Container and Sprite scene graph, pointer dragging and v7-to-v8 migration. | implemented |
| GameDev genre | platformer | Designs 2D platformers in any engine: jump feel (coyote time, jump buffering, variable height, fall gravity, corner correction), wall jumps, hazards, checkpoints and one-way platforms. | implemented |
| GameDev discipline | procedural-gen | Engine-neutral procedural generation in Python with Godot and Unity mappings: seeded RNG, dungeon layouts, wave function collapse, noise terrain and loot tables. | implemented |
| GameDev workflow | prototype-fast | Builds a throwaway playable prototype in about an hour to answer one question, usually "is this mechanic fun?": a one-question brief, a greybox, a debug HUD, a playtest and a keep, kill or retune call. | implemented |
| GameDev genre | puzzle | Designs grid and logic puzzle games in any engine: match-3 cascades, Sokoban pushing, unique-solution grids (nonogram, Sudoku), exact undo and solver-checked levels. | implemented |
| GameDev engine | pygame-core | Builds and debugs 2D games in Python with pygame-ce (imported as pygame): the event-update-draw loop, delta time, Surfaces and Rects, Sprite groups and headless tests. | implemented |
| GameDev engine | roblox-characters | Roblox player characters: CharacterAdded lifecycle, Humanoid and HumanoidRootPart, R6, R15 and custom rigs, respawn and Tools. | implemented |
| GameDev engine | roblox-datastores | Roblox DataStoreService persistence: load on join, save on leave and BindToClose, UpdateAsync vs SetAsync, session locking and OrderedDataStore leaderboards. | implemented |
| GameDev engine | roblox-luau | Roblox Luau scripting and code structure: services, Instances, Script vs LocalScript vs ModuleScript, the task library and typed Luau, with selene and luau-lsp checks. | implemented |
| GameDev engine | roblox-networking | Roblox client-server networking and anti-exploit: RemoteEvent and RemoteFunction contracts, server authority, rate limits, hit validation and replication. | implemented |
| GameDev engine | roblox-physics | Roblox physics and spatial queries: assemblies, constraints, collision groups, Raycast and Shapecast, and network ownership. | implemented |
| GameDev engine | roblox-simulator-economy | Roblox simulator, tycoon and idle-game economies in Luau: upgrade cost curves, income per second, rebirth pacing, big-number formatting and paid-egg odds, with a Lune calculator. | implemented |
| GameDev engine | roblox-studio-workflow | Safely edits an existing Roblox place or Rojo project: finds the source of truth and proves changes with the right test mode or Studio MCP (execute_luau). | implemented |
| GameDev engine | roblox-ui | Roblox UI with ScreenGui and PlayerGui: ResetOnSpawn, UDim2 scale and offset, UIListLayout flex, safe areas, StyleSheet, gamepad selection and touch controls. | implemented |
| GameDev genre | roguelike | Designs run-based roguelikes and roguelites in any engine: run structure, permadeath, meta-progression, seeded and daily runs, turn order and symmetric field of view. | implemented |
| GameDev genre | rpg | Designs RPG progression and combat numbers in any engine: stats with a modifier stack, XP curves, damage formulas, items and equipment (slots, rarity, affixes) and quests. | implemented |
| GameDev discipline | save-systems | Engine-neutral save and load with Godot and Python code: what to serialize, slots and autosave, atomic writes and versioned migration. | implemented |
| GameDev discipline | shader-programming | Engine-neutral shader technique in GLSL with HLSL equivalents: how dissolve, outline, fresnel rim and post effects work, and porting GLSL to HLSL. | implemented |
| GameDev workflow | steam-publish | Publishes or updates a game on Steam with Steamworks and SteamPipe: depots, app_build .vdf scripts, steamcmd uploads, beta branches, SetLive, store review and Coming Soon. | implemented |
| GameDev genre | survival-crafting | Designs survival-crafting loops in any engine: gathering, recipes and tech trees, carry weight, spoilage, hunger and temperature, and base building. | implemented |
| GameDev engine | threejs-gltf-loading | Loads glTF/GLB models into three.js r187 and plays their animations: GLTFLoader, DRACO, Meshopt and KTX2 decoders, AnimationMixer cross-fades and SkeletonUtils clones. | implemented |
| GameDev engine | threejs-materials-lighting | Lights and shades three.js r187 scenes: standard, physical and unlit materials, lights, shadows, HDR environment lighting and tone mapping. | implemented |
| GameDev engine | threejs-scene-setup | Sets up and debugs a plain three.js r187 game or 3D scene: import maps, Scene, PerspectiveCamera and WebGLRenderer, setAnimationLoop with Timer, resize, OrbitControls and WebGPURenderer. | implemented |
| GameDev genre | tower-defense | Designs tower defense games in any engine: lane and maze pathing, wave pacing, targeting priorities, armoured and flying counters, and the gold economy, with a wave-curve checker. | implemented |
| GameDev engine | unity-animation | Unity 6.3 LTS character animation with the Animator (Mecanim): states and transitions, blend trees, Avatar Mask layers, root motion and humanoid IK. | implemented |
| GameDev engine | unity-build-pipeline | Builds and ships Unity 6.3 LTS players: Build Profiles, IL2CPP vs Mono, managed stripping with link.xml, scripted BuildPlayer, Addressables and CI or headless builds. | implemented |
| GameDev engine | unity-build-size | Finds and shrinks what makes a Unity 6.3 LTS build too big: Build Report reading, uncompressed textures, glTFast models, PCM audio and per-platform levers. | implemented |
| GameDev engine | unity-csharp-scripting | Writes and fixes Unity 6.3 LTS C# gameplay scripts: MonoBehaviour lifecycle, serialization, .meta/GUID discipline and command-line tests. | implemented |
| GameDev engine | unity-input-system | Wires Unity 6.3 LTS player input with the Input System package: .inputactions assets, action maps, PlayerInput and control schemes. | implemented |
| GameDev engine | unity-navmesh | Unity 6.3 LTS pathfinding with the AI Navigation package: NavMeshSurface baking, NavMeshAgent, NavMeshLink jumps and runtime rebakes. | implemented |
| GameDev engine | unity-physics | Unity 6.3 LTS physics in 3D and 2D: Rigidbody and Rigidbody2D, forces and linearVelocity, the layer collision matrix and raycasts. | implemented |
| GameDev engine | unity-scriptableobjects | Unity 6.3 LTS data and decoupling with ScriptableObjects: CreateAssetMenu config assets, shared runtime variables, event channels and .asset files made from code. | implemented |
| GameDev engine | unity-tilemap-2d | Unity 6.3 LTS 2D tilemaps: the Tile Palette, Tilemap Collider 2D with a Composite Collider, Rule Tiles and runtime SetTile. | implemented |
| GameDev engine | unreal-behavior-trees | Unreal Engine 5 (UE 5.8) NPC AI with Behavior Trees, Blackboards, EQS and StateTree: decorators with Observer Aborts, C++ BTTask nodes and running trees from an AIController. | implemented |
| GameDev engine | unreal-blueprints | Unreal Engine 5 (UE 5.8) Blueprint visual scripting: Blueprint Classes vs the Level Blueprint, Event Graph, and Cast, Interfaces and Event Dispatchers. | implemented |
| GameDev engine | unreal-cpp-gameplay | Unreal Engine 5 (UE 5.8) C++ gameplay code: UCLASS and UPROPERTY reflection, the Gameplay Framework, GC-safe pointers, Build.cs and command-line builds. | implemented |
| GameDev engine | unreal-enhanced-input | Unreal Engine 5 (UE 5.8) player input with Enhanced Input: Input Actions (IA_), Mapping Contexts (IMC_), ETriggerEvent bindings and remappable keys. | implemented |
| GameDev engine | unreal-niagara | Unreal Engine 5 (UE 5.8) Niagara VFX: systems, emitters, User parameters, spawning from C++ or Blueprints, bounds and GPU vs CPU sim. | implemented |
| GameDev engine | unreal-packaging | Packages and ships Unreal Engine 5 (UE 5.8) projects: Shipping builds, cooking, pak/IoStore and RunUAT BuildCookRun with UAT and cook log reading. | implemented |
| GameDev genre | visual-novel | Builds visual novels and choice-driven stories in Ren'Py or any engine: routes and endings, save-anywhere, backlog, skip-read-only and typewriter text. | implemented |

<!-- gamedev-managed:end -->

## Критерии для нового Skill

- Задача повторяется хотя бы в нескольких сценариях или требует существенной воспроизводимой процедуры.
- Есть конкретные позитивные и негативные условия активации.
- Описано, что выполнять, чего не делать и как подтвердить завершение.
- Есть владелец области знаний / способ поддерживать актуальность.
- Поведение лучше оформить как Skill, а не как короткое глобальное правило, одноразовую заметку или длинную роль агента.

Начать с 8–10 базовых, затем добавлять специальные по фактической необходимости. Не считать эту таблицу перечнем готовых инструментов.
