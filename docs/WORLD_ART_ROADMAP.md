# Planet Verdant — world relief and restrained fantasy glow (2026-10-12)

## What is evidence, and what is design direction

**Confirmed source gap:** `scripts/build_world.py` authors a 648×648 flat Grass Ground Part, twelve noncollidable low color fields and four low Ball hills. `default.project.json` previously configured only basic Lighting properties. This creates a flat horizon and no deliberately authored post-processing. The previous user's Studio screenshot confirms the flat visual impression; this does not prove a collision/FPS defect.

**Primary design references:** Roblox [Environmental terrain](https://create.roblox.com/docs/building-and-visuals/studio-modeling/terrain), [Terrain Editor](https://create.roblox.com/docs/studio/terrain-editor), [Lighting and effects](https://create.roblox.com/docs/environment), [Post-processing](https://create.roblox.com/docs/environment/post-processing-effects), [Atmosphere](https://create.roblox.com/docs/environment/atmosphere), [Performance design](https://create.roblox.com/docs/performance-optimization/design). These document sculpted 3D terrain, atmosphere/haze, selective Bloom/Color Correction and profiling. Inspiration is methodological; no competing game geography or asset is copied.

**This source milestone (GE-MAP-02a, original authored art):** 14 solid wedge-and-strata escarpments frame the outer wilderness horizon, at least six distinct solid, cleared knolls add localized navigable elevation between resource stations; village lanterns and Glowcap Grove attach exactly eight bounded non-shadowing PointLights; authored Atmosphere, Bloom, color grading and sun rays give a restrained warm Verdant afternoon. Only peripheral/cleared locations are elevated; player ranch plots and reserved tutorial roads remain on the original walkable base. These are native-part art assets, not Roblox voxel Terrain or professional skinned/UV-mapped meshes. Source/package checks protect this boundary.

**Next visual production milestones:** (1) fixed-camera Studio comparisons from spawn, quarry, Glowcap Grove and west forest; repair intersecting silhouettes, verify lighting legibility. (2) Sculpt original *real* Roblox Terrain via deterministic approved Studio import/build pipeline with a protected flat ranch corridor, smooth walking slopes, suitable grass/rock/shore materials and a safe water edge; an imported heightmap alone must not break 12 ranch or 70 resource roots. (3) Replace remaining overtly repetitive native-Parts with optimized original modeled cliff/tree/rock modules using authored materials, optional LOD and bounded FX. (4) Mobile/device MicroProfiler FPS, memory, rendering and collision validation before increasing density.

**Studio visual acceptance:** Start Play on updated Rojo build. From center spawn pan north to compare escarpment depth and avoid jagged cutoffs; walk forest/mines/Glowcap routes, harvest every starter node, approach knolls to verify genuine elevation and no impassable overlap; inspect glow during afternoon and 19:00 Studio Lighting ClockTime; verify text/prompt contrast, no washed-out Bloom, and Phone Emulator frame time/memory (measure, do not assume). Record the first failing screenshot/output error.

**Release safety:** Published trading stays disabled. New lighting and landscape source tests/green CI prove packaging and positional contracts only, not real Studio shading, engine collision, visual quality, 30/60 FPS, multiplayer or monetization readiness.



## GE-MAP-02b — real smooth Roblox Terrain hills (2026-10-12, engine QA pending)

**Implementation:** `src/shared/TerrainPlan.lua` produces a stable, bounded, server-authoritative plan of 16 original peripheral shoulder sites with two material layers (rock foot, grassy crest); `src/server/WorldTerrain.lua` writes **real workspace.Terrain smooth voxels** with `FillBall`. The launcher `src/server/World.lua` invokes it once per untouched server terrain version. Obstacles are read from the current 70 authored harvest interact roots and 64 forest trunks and compared with protected village/trail/ranch/lagoon/quarry regions *before* sculpting; unsafe sites are skipped. Maximum 48 sphere writes, actual planned maximum 32. This does not move a ranch, resource, road or pet. `Terrain:Clear()` is never called, and existing authored Terrain is not erased.

**Edit mode:** Rojo cannot serialize newly created voxels into the statically generated XML part model, so the .rbxlx build itself contains only this code; normal Play automatically builds voxels server-side. To **bake them permanently into a local Studio Place** after Rojo sync (opt-in; save your own backup), stop Play and paste this into Studio's **Command Bar**:

```lua
local gameTerrain = require(game.ServerScriptService.GorpsServer.WorldTerrain)
local ok,info=gameTerrain.apply(workspace:WaitForChild("PlanetVerdant"))
print("Voxel bake:",ok,info)
```

Save the edited place to retain Workspace.Terrain on your machine. The terrain version attribute prevents a second application of identical shapes. An edited .rbxlx must not be claimed to contain baked voxels unless saved from Studio.

**Authoritative API:** [Roblox Terrain:FillBall](https://create.roblox.com/docs/reference/engine/classes/Terrain#FillBall) creates smooth material-filled voxel spheres. It is not a MeshPart, a disc, or a thin cosmetic overlay. The terrain authoring is deterministic and its pure Luau plan is tested in CI; engine geometry and rendering are not proven by headless tests.

**Required QA:** Play the latest synced Studio build, inspect `Workspace.Terrain` and the `[Gorps World] Applied smooth voxel terrain` Output line; compare fixed-camera spawn-to-north and forest/quarry horizon, walk each tutorial route and ranch perimeter, harvest from an edge-near node, and check no buried nodes, abrupt cube seams or newly impassable paths. Profile mobile FPS/memory with the same device as before; keep native-Part fallback until Studio accepts new voxels. Do not claim published-client voxel replication without an actual two-client test.
