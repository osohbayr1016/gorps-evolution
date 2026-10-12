# Research-to-build: Verdant world composition and obstacle-aware terrain
Date: 2026-10-12

## Confirmed primary sources (not claimed hands-on gameplay)
- Roblox [Environmental terrain](https://create.roblox.com/docs/building-and-visuals/studio-modeling/terrain): sculpted 4-stud voxels, native grass/rock materials, support for scripted procedural terrain.
- Roblox [Construct your world](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/construct-your-world): protect gameplay flows while composing landmark silhouettes, terrain transitions, lighting and original reusable assets.
- Roblox [Design for performance](https://create.roblox.com/docs/performance-optimization/design): profile devices, avoid premature assumptions that Studio emulator memory equals phone memory.
- Roblox [Improve performance](https://create.roblox.com/docs/performance-optimization/improve): evaluate instance streaming/mesh fidelity based on measured bottlenecks; do not toggle it before verifying script compatibility.

## Actual gap and original adaptation
The **confirmed code gap** is not a missing Terrain API: the previous `Plan.build({})` CI run asserted 471 cases using **no obstacles**, whereas server `WorldTerrain.obstaclesIn()` supplies all 70 resource anchors and 64 forest trees; it can reject most interior candidate hills. Therefore the CI green result did **not** prove meaningful real-world terrain distribution. Gorps' original adaptation uses authored paired forest/quarry relief and alternate symmetric, organic terrace candidates, all checked against the actual generated resource, tree, knoll and Glowcap positions with the same safety predicate as the server. This preserves the player resource economy and early navigation rather than copying a reference game layout.

## In this milestone (GE-MAP-02d)
- Deterministic inland candidates include a curated primary set plus paired meadow fallback positions, constrained by `MAX_INLAND_SITES=12` and `MAX_WRITES=80`, including existing outer sites.
- The runtime additionally protects handcrafted `TerrainKnoll_` parts and Glowcap mushroom stems against new voxel burial.
- `extract_terrain_obstacles.py` reads the actual generated XML and produces a CI-only obstacle fixture; `test_terrain_real_world.luau` calls the **real TerrainPlan module** with exactly these obstruction shapes. Reject fewer than six accepted safe inland contours, or fewer than two on either forest/quarry side. It also verifies all write names unique and geometric bounds/determinism.
- Real Studio collision, camera screenshots, lighting, streaming, join time, voxel appearance and mobile memory remain pending. Passing CI is **not** an engine screenshot.

## Prior milestone evidence
[Commit e29a957](https://github.com/osohbayr1016/gorps-evolution/commit/e29a95779635c9c09dfbcd374cf042a52b278412), exact push [Actions #38191185397](https://github.com/osohbayr1016/gorps-evolution/actions/runs/38191185397): SUCCESS. That job's 471 empty/fake-obstacle plan assertions motivated this real-map integration test.

## Next Studio acceptance
Take a single before/after screenshot pair from the village north path looking toward west forest and east quarry. Walk from spawn to the first harvest nodes and nearest Glowcap, note buried mushrooms or routes, and record device FPS/memory using actual hardware where possible. If a safe hill blocks gameplay, report coordinates and screenshot; adjust the candidate list, not player collision settings.
