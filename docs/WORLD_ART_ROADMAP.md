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

## GE-MAP-02c — interior transition contours and nonblocking generation (2026-10-12)

**Prior exact evidence:** commit `87972fb3fbddbd51de176c02b880321019ba3aa5`, [push Actions 38190352361](https://github.com/osohbayr1016/gorps-evolution/actions/runs/38190352361) **success**. It established a safe original voxel boundary but **only at the outskirts**, so central meadow-to-forest and meadow-to-quarry transitions still appeared flat in the previous map composition.

**This milestone:** the `TerrainPlan` adds a deliberate **two-sided progression of interior contour candidates** between plaza shoulders, western Glowcap woodland and eastern quarry forest. Each accepted interior hill has overlapping Rock foundation, Grass/Ground rounded slope, and an offset crest—all within a 19-stud reserved footprint, creating three-piece joined shapes instead of isolated equal balls. Dynamic 70 resource and 64 tree checks, 12-plot reserve, roads, lagoon, quarry entrances, existing outer-site spacing and max 12 interior contours remain enforced. The plan returns interior counts to support regression assertions; real game requests do not control terrain geometry.

**Smoothness:** `World.make` defers the voxel writer until after gameplay startup; `WorldTerrain.apply` yields between each batch of four bounded `FillBall` writes. Studio Editing can still run the same module via Command Bar to bake after opting in. Release version `VerdantVoxelRelief_02` ensures prior saved V1 Terrain receives the additional new relief on the next Studio run. **Neither effect on join time nor rendered quality is measured**; validate profiling in Studio.

**Next art gate:** Compare fixed camera from village spawn toward woodland and quarry. At each accepted terrace test avatar traversal and whether terrain intersects authored forest furniture or resources. In Device Emulator record frame time and memory; do not call the world finished until a Studio screenshot and functional navigation evidence exist. Existing 648×648 Grass Part still underlays the entire playfield and should not be removed before tested replacement terrain supports all player paths.


## GE-MAP-02d — actual map-aware terrain acceptance (2026-10-12)

The current auto-placement pipeline previously only ran source tests against an empty obstacle array. Real gameplay has 70 resource interact roots, 64 tree trunks, >=6 handcrafted knolls and 16 Glowcap stems. That meant an all-green build could still produce almost no visible inland relief. The updated deterministic planner retains a symmetric backup set of original hillside contours and checks them against the **actual authored XML** in a Lune regression. Each chosen site remains within the same run-time clearance/writes budgets; the first 12 safe sites are the only filled ones. WorldTerrain now excludes original knolls and mushroom props; no existing assets are moved or deleted. See [COMPETITOR_DESIGN_RESEARCH.md](COMPETITOR_DESIGN_RESEARCH.md) for primary citations and evidence boundaries.

**Studio remaining:** inspect west/east contour balance, changed Grove skyline, mushroom roots, all tutorial resource interactions, device frame pacing and memory. Real voxel material blending and physics are not proven by this fixture.

## GE-MAP-02e — measured compact hillock fallback (2026-10-12)

Exact push run [38192594721](https://github.com/osohbayr1016/gorps-evolution/actions/runs/38192594721) exposed that GE-MAP-02d's generated fallback grid still accepted **zero** real-map inland sites. The failure was geometric, not a Roblox engine result: a 17-stud site, six-stud buffer and 16-stud resource radius required roughly 39 studs of center separation, while the authored forest/quarry composition intentionally places interactables more densely.

The repaired fallback uses 12 measured open pockets split evenly west/east. Each compact hillock reserves a 12-stud horizontal footprint with a four-stud buffer around a maximum ten-stud rock fill, so its validation boundary remains larger than its generated voxel footprint. Large primary contours remain preferred when safe; resource roots, trees, existing knolls, Glowcaps, all protected paths, ranches, lagoon and quarry regions remain hard exclusions. `VerdantVoxelRelief_04` forces a previously stamped local Studio place to receive the corrected plan once.

**Evidence boundary:** generated-XML/Luau tests establish deterministic clearance and distribution only. In Studio, capture the same village-to-west/east camera pair, walk each nearest hillock and harvest adjacent resources, then record the first collision/material seam plus baseline-device frame time and memory. Do not accept visual quality from CI alone.

## GE-MAP-03a — original spawn-to-biome route hierarchy

**Baseline:** `c910db2be7c59d22e6b02e5686bb859e1754517d`, exact push [Actions 38212951333](https://github.com/osohbayr1016/gorps-evolution/actions/runs/38212951333) **success**. Source inspection confirmed the center north road and distant forest/quarry roads had no authored surface connection.

**Implementation:** `VerdantRouteFork` uses twelve low non-colliding Ground segments to create two gentle, asymmetric arcs through the existing starter resource circuit. Paired original waystones use a terrace foot, angular stone spire, emissive band and rune to make the forest/quarry choice legible through the existing gate. They add no local lights, particles, animation loop or asset dependency and do not replace genuine voxel relief.

**Acceptance boundary:** static tests prove route topology, material/collision policy, landmark composition and clearance from all 70 interaction roots in source and package. They do not prove camera legibility, z-fighting, terrain blending, avatar navigation or mobile cost. Fixed-camera Studio and real-device evidence remain mandatory before art acceptance.

## GE-MAP-03b — east quarry vertical landmark

**Baseline:** [`5f1e376`](https://github.com/osohbayr1016/gorps-evolution/commit/5f1e37606d392d55a80cb5280cac17600dc44b78), exact push [Actions 38227714787](https://github.com/osohbayr1016/gorps-evolution/actions/runs/38227714787) **success**. Its route fork made the east choice legible, but source inspection found the destination itself was a low Ball and repeated 4x3 boulder grid.

**Implementation:** an original 27-part quarry kit forms three offset tapering terraces, a framed portal, amber crest, nine varied ore clusters and a low approach. The kit stays inside the existing quarry reserve, adds one net BasePart and no light/particle/runtime cost category. It does not claim a modeled MeshPart, cave interior or voxel cliff.

**Acceptance boundary:** XML/package tests prove hierarchy, naming, material/collision policy, cluster variation and 70-resource clearance. Studio must still prove the east vista, apparent scale, portal traversal, terrain/material joins, shadows and baseline-phone cost. Next art production should repair observed engine defects first; absent evidence, compose the west lagoon/Glowcap handoff with the same bounded approach.

## GE-MAP-03c — Moonwater basin and west skyline

**Verified design basis:** Roblox's environmental-art curriculum ties distinct
area materials/assets to world information and requires later device profiling;
official Fisch and Creatures of Sonaria descriptions confirm exploration around
water/world resources, not a reusable map layout. The original Gorps response
is a layered open-east lagoon with a Moonstone crescent, irregular lilies and a
shallow modular bridge. No competitor geography or asset is copied.

**Measured implementation:** the prior 29-part flat/radial kit is replaced by
36 authored parts: one retained low rim, three raised shore shoulders, one
non-colliding emissive water cue, four crescent pieces, seven two-part lily
clusters, three shallow decks, eight posts and two non-colliding rails. No
PointLight, particle, script or external asset is added; 12 ranch plots and 70
resource identities remain fixed.

**Evidence boundary and next step:** XML/package checks enforce hierarchy,
irregularity, bridge rise, nonblocking emissive pieces, resource clearance and
zero local lights. Studio must still validate water affordance, collision,
seams, west-route/Glowcap continuity, prompt/UI contrast and actual phone
frame-time/memory. The first recorded engine defect outranks another art pass.

## GE-MAP-03d — preserve a primary lane, add two cross-lanes

**Verified design basis:** Creator Hub's environment greybox guidance separates
long primary lanes from cross-lanes and asks developers to test traversal before
polish. Official Bee Swarm and PS99 pages establish chained resource/area
progression, not a map template. Gorps' original response preserves
`ForestPath` as the northbound spine and uses short lagoon/Glowcap cross-lanes.

**Measured implementation:** four LagoonLink plus five GroveLink Ground
segments and one four-piece non-colliding guide add 13 authored parts. The
generated map measures at least 24.2 studs from each segment center to any of
70 harvest roots; the final center sits within 15 studs of an authored Glowcap.
There are no new lights, particles, scripts, rewards or changed RNG draws.

**Evidence boundary and next step:** source/package tests prove topology,
endpoints, material/collision policy, resource clearance, Glowcap reach and no
local light. Studio must prove the route reads as one chain, sits on terrain,
does not snag avatars or obscure prompts, and retains real-phone performance.
If no engine defect is supplied, measure the grove's internal walkable clearing
before any additional prop or effect density.

## GE-MAP-03e — frame a walkable Glowcap activity pocket

**Verified design basis:** Creator Hub's world-construction guidance uses
intentional activity pockets, controlled entrances, peaks/valleys, sight lines
and differentiated floor materials to orient players. Gorps adapts that method
to its original route and Glowcap kit; the work does not copy another game's
grove, map, assets or effects.

**Measured implementation:** the former independent RNG scatter is replaced by
an asymmetric 16-stem ring around one 46×34 non-colliding Ground clearing.
Every stem is at least 50 studs from center and 19 studs from another stem;
eight stem heights culminate in a 15-stud north focal cap. Existing counts stay
at 16 Glass caps, 32 dots and four grove PointLights. Historical RNG calls stay
in the same order, 70 resources and 12 ranches do not move, and only one new
BasePart is added.

**Evidence boundary and next step:** source/package checks prove declared
geometry, spacing, interaction clearance, hierarchy and bounded budgets, not
Roblox camera readability or collision feel. Studio must walk the full lagoon
handoff, rotate once from the clearing, test ring prompts and bloom, inspect
Output, then record phone frame time/memory. Fix the first engine-visible defect
before adding more glow, particles or set dressing.

## GE-MAP-03f — measure and reinforce the Grove surface handoff

**Verified design basis:** Creator Hub's greybox and world-construction guidance
requires traversal testing and preservation of playable path intent through
polish. Theme Park Tycoon 2's official page verifies cooperative plot building
only; no competitor path, map or asset is used as a geometric template.

**Measured implementation:** convex clipping of the real rotated XZ footprints
found only 1.365 stud² where `GroveLink_05` met `GroveClearing`. One original
12×11 non-colliding Ground threshold raises the two joins to 28.357 and 92.403
stud². It adds one BasePart, no light/particle/script/reward/external asset, and
moves no authored route, harvest root, ranch, Glowcap or RNG draw.

**Evidence boundary and next step:** source/package checks establish oriented
surface overlap, material/collision policy and 70-root clearance only. Studio
must still prove no gap, z-fighting, float, snag, prompt occlusion or phone
regression. After that, measure the fixed entry camera's foliage/prompt corridor
to the north focal cap before increasing glow or prop density.

## GE-MAP-03g — close the bridge seam and protect the camera chain

**Verified design basis:** Creator Hub treats connected lane traversal as a
greybox requirement and expects final art to preserve that playable intent.
Restaurant Tycoon 2's official page verifies build/visit activities only; its
map, roads and assets are not evidence or templates for this Gorps correction.

**Measured implementation:** three 3D CFrame/Size sightline casts reject the
suspected opaque occlusion, but route footprint clipping finds only 4.986 stud²
between `ReedBridgeDeck_03` and `LagoonLink_01`. Moving the existing first
anchor four studs into the deck raises the joint to 31.374 stud². No geometry
count, RNG draw, route destination, resource, ranch, light, particle or script
changes.

**Evidence boundary and next step:** source/package tests now protect five
surface joints and three fixed camera lines. Studio must still verify rendered
seams, perspective/UI prompt projection, avatar traversal and real-phone cost.
If no engine evidence arrives, next measure the west/east background depth and
repeated skyline modules before a bounded original composition pass.

## GE-MAP-03h — receding asymmetric perimeter without a density increase

**Verified basis:** Roblox's environmental-art curriculum treats world art as
gameplay context, and its construction/optimization guidance pairs distinct
area composition with device profiling and selective edge-detail shadows. The
official PS99 Tech World post confirms named zones/portals only; no proprietary
skyline or map geometry is used here.

**Measured gap and implementation:** all 14 four-piece escarpments previously
shared one X/Z center per model, while four west/east pairs repeated exact
mirrored profiles. The generator now assigns each ridge a deterministic rise,
yaw, retreat and crest proportion. Foot-to-crest depth spans 8.0–13.5 studs,
all 14 profiles are unique, no side pair is an exact mirror, and top elevations
span 19.92–29.65 studs. Part count remains 56; the 28 far decorative
shelf/crest pieces stop casting shadows while the solid foot/slope layers keep
them. No light, particle, script, texture or runtime work is added.

**Evidence boundary and next step:** source/package tests protect the declared
spatial hierarchy and budgets, not actual parallax, shadow quality, collision,
destination readability or device cost. Capture fixed spawn west/east/north
views and walk both destination approaches in Studio. Fix the first observed
gap, intersection or visibility defect; otherwise measure the next box-like
foreground module in the village reveal before adding density.

## GE-MAP-03i — replace cloned village boxes with one varied modular kit

**Verified design basis:** Creator Hub's environment curriculum converts
greybox architecture with reusable wall, corner and door modules, then varies
their contextual treatment so players can orient themselves. Its modular
environment guide supports cohesive reuse with configured variety. Theme Park
Tycoon 2's official description confirms broad scenery/customization only; no
proprietary building shape or layout is used here.

**Measured implementation:** all four stations shared one 19×11×15 wall box,
two 26.5×1.6×11.3 roof planes at the same pitch and one identical ridge. The
same `hut()` authoring function now composes six named wall modules around the
unchanged Door and applies four original shell/roof parameter sets. Ridge
centers span 16.4–19.1 studs and every collidable shop remains at least 36.75
studs from the central route. Cost: +20 anchored parts; zero new lights,
particles, scripts, assets or RNG draws.

**Evidence boundary and next step:** source/package checks protect module
presence, profile variety, Door identity/collision, height hierarchy and lane
clearance. Studio still owns facade/roof seam, prompt projection, avatar snag,
spawn composition and real-phone performance. Without engine evidence, next
measure the fountain/platform frame and north-gate camera corridor before any
additional prop or glow work.

## GE-MAP-03j — move the fountain off the first navigation axis

**Verified design basis:** Creator Hub's greybox curriculum makes spawn exits,
primary lanes, camera-safe dimensions and sightline testing layout concerns that
precede polish. The PS99 official area update confirms distributed area
activities only; Gorps does not copy a plaza, prop, texture or branded layout.

**Measured implementation:** the old 15-stud solid basin overlapped the fixed
18×18 `SafetySpawn` by 7.5 studs and the solid column intersected a fixed
spawn→`GateCrest` 3D segment. Repositioning the same four fountain pieces at
`(-15.5, 12)`, reducing basin/water diameters to 11.5/9 and disabling water
collision produces 1.409 studs of spawn clearance, a 9.75-stud central
half-lane and zero static sightline blockers. Counts and budgets do not change.
Priority P1; complexity low.

**Evidence boundary and next step:** source/package tests protect the exact
composition, clearance, collision policy and camera ray, not Studio spawning,
visual grounding, camera clipping, avatar physics or device cost. Run five
default spawns, direct north-gate walks and one fountain circle; repair the
first engine defect. Without engine evidence, next measure the gate→route-fork
surface/view handoff before new geometry or glow.

## GE-MAP-03l — local Moonwater turn landmark

**Verified design basis:** Creator Hub's environment curriculum uses repeated
area colors/materials at primary and cross-lane intersections so players can
orient quickly. Bee Swarm's official description confirms chained resource,
quest and exploration progression only; Gorps does not copy its mountain,
signage, geometry or assets.

**Measured implementation:** the existing surface chain is continuous, but the
forest heading changes 102.80 degrees onto the southbound Moonwater exit with
no local cue. One original four-piece shoulder landmark at `(-116, 104)` uses a
Slate foot, Wood stem, Glass lens and nonblocking Neon south rune. It adds four
anchored parts, no PointLight/particle/script/RNG work, and keeps 30.0 studs to
the nearest starter resource root.

**Evidence boundary and next step:** source/package checks prove the kit,
collision/material policy, turn angle, resource clearance and fixed approach
sightline—not player comprehension, terrain seating, prompt projection, avatar
physics or device cost. Studio must follow the forest approach through the
guide to Moonwater bridge on keyboard and touch, then repair the first observed
direction/scale/terrain/prompt/collision defect before adding more glow.

## GE-MAP-03m — grounded Moonwater bridge ascent

**Verified design basis:** Creator Hub's construction curriculum preserves
elevation as navigation information and explicitly uses wedge geometry to form
rises between floor levels. This milestone adapts only that general principle;
the bridge position, profile, palette and measurements remain original Gorps
work.

**Measured implementation:** the guide already sees `CrescentSpire` with zero
opaque authored blockers, and LagoonLink's nearest harvest root is 39.37 studs
away. The missed dimension was height: link and first deck top surfaces were
y=1.32 and y=4.60. One collidable 7.5×1×9.5 Wood approach, pitched 19.7 degrees,
now lands at y=1.35 and y=4.55. Cost is one anchored part and no light,
particle, script, external asset, runtime loop or RNG change.

**Evidence boundary and next step:** deterministic source/package checks prove
the two endpoint deltas are <=0.1 studs, not that Roblox Humanoid physics feels
safe. Studio must cross the ramp without jumping on keyboard and touch, reject
snag/slide/float/water clipping/camera bump, and record real-phone FPS/memory.
If clean, next measure the deck→lagoon-bank surface and safe water-edge return.

## GE-MAP-03n — readable, bounded Moonwater overlook

**Verified design basis:** Creator Hub treats containment as part of polished
world construction so playable areas do not permit unintended falls. Fisch's
official description verifies water exploration/progression only; it does not
publish a bridge, barrier, device result or licensed geometry for reuse.

**Measured implementation:** the bridge's west edge stood 1.90 studs over the
visual water and 2.78 studs over the solid rim while both long rails were
non-colliding and the end was open. The two existing rails now sit at deck
height and collide; one aligned west rail closes the water edge. The original
east ramp remains the sole return opening, with a 7.0-stud inner corridor.
Cost: +1 anchored part, zero light/particle/script/asset/RNG changes.

**Evidence boundary and next step:** source/package contracts prove the rail
kit, seating, overlap and nominal corridor width—not Humanoid turning, jumping,
camera collision or visual weight. Studio must cross, touch the end guard,
U-turn and return on keyboard/touch. If clean, next source audit measures the
walkable rim/shore boundary for a deterministic water-edge trap.
