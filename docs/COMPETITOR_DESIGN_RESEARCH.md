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

## 2026-10-12 corrective evidence — GE-MAP-02e

- **Confirmed:** exact push [Actions 38192594721](https://github.com/osohbayr1016/gorps-evolution/actions/runs/38192594721) failed with `actual authored terrain has too few inland contours: 0`. This rejects GE-MAP-02d's claimed minimum-six acceptance; it is not a subjective screenshot judgment.
- **Creator Hub technique retained:** native material Terrain and deterministic scripted sculpting remain appropriate, while Roblox's performance guidance requires real baseline-device frame/memory measurement rather than treating Studio/CI as device proof. No competitor map, mesh or texture is copied.
- **Original corrective action (P1, low/medium complexity):** preserve large preferred contours, then use twelve compact clearance-checked Verdant hillocks in measured gaps. Their safety footprint exceeds their actual fill, with an even forest/quarry split and unchanged resource/ranch/path identities.
- **Acceptance:** generated real-map fixture produces 12 inland contours, 6 west/6 east, within 80 total fills and deterministically. Studio Play must still prove material blending, no buried prompts, safe traversal and mobile performance.
- **Exact next milestone:** fixed-camera Studio validation; repair the first observed contour/collision/lighting defect before adding more world density.

## Prior milestone evidence
[Commit e29a957](https://github.com/osohbayr1016/gorps-evolution/commit/e29a95779635c9c09dfbcd374cf042a52b278412), exact push [Actions #38191185397](https://github.com/osohbayr1016/gorps-evolution/actions/runs/38191185397): SUCCESS. That job's 471 empty/fake-obstacle plan assertions motivated this real-map integration test.

## Next Studio acceptance
Take a single before/after screenshot pair from the village north path looking toward west forest and east quarry. Walk from spawn to the first harvest nodes and nearest Glowcap, note buried mushrooms or routes, and record device FPS/memory using actual hardware where possible. If a safe hill blocks gameplay, report coordinates and screenshot; adjust the candidate list, not player collision settings.

## 2026-10-12 route hierarchy research — GE-MAP-03a

- **Confirmed primary-source patterns:** Roblox [Construct your world](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/construct-your-world) describes applying cohesive assets to communicate information about distinct areas and using local visual cues for directionality. BIG Games' official [Tech World update](https://www.biggames.io/post/pet-simulator-99-update-6) documents named sequential areas, portals, larger context icons and an improved early tutorial. These sources do not prove retention, current balance, mobile FPS or the quality of Gorps.
- **Inference, not a copied layout:** a visible fork with distinct destinations should reduce first-session ambiguity more safely than adding more UI text. Gorps retains its own village, woodland, quarry, resources, colors and geometry; no competitor mesh, texture, trademark, code or route coordinates are used.
- **Measured Gorps gap:** `MainRoadNorth` was centered at x=0 while `ForestPath` and `MinesPath` began around x=-125 and x=133. No authored path joined them, despite eight starter resources occupying the intervening grass. Evidence: `scripts/build_world.py` before GE-MAP-03a and its generated XML.
- **Original action:** two differently colored curved six-segment Ground ribbons join the trailhead to the forest/quarry roads. Four-piece mint/amber waystones sit outside the travel lane and resource clearance. Total addition: 20 BaseParts, zero lights, zero particles and zero runtime loops. Priority P1; complexity low/medium.
- **Acceptance:** `scripts/verify_map_routes.py` checks exactly six monotonic segments per branch, non-collision, Ground material, start/end reach, paired four-piece landmarks and >=20-stud clearance from all 70 resource roots in both `.rbxmx` and `.rbxlx`. Studio must still prove visual continuity, no z-fighting, avatar traversal, prompt readability and baseline-device performance.
- **Exact next milestone:** fixed spawn→gate→fork camera plus two route walks. Repair the first observed seam/occlusion/collision; if none is supplied, audit the next repetitive skyline/structure module without increasing light or particle budgets.
