# Planet Verdant route and silhouette QA

This milestone replaces accidental scatter with a deterministic first-session
route. It preserves 12 ranch plots, 70 harvest nodes, the village stations and
all existing reward rules. It does not claim final art quality or Studio proof.

## Authored route

1. The two first ranches open toward the village rather than a random field.
2. The north village exit has a sand trailhead and five colored physical
   markers. Mint points toward food/wood, amber toward stone/ore and violet
   toward wildlife.
3. The first eight harvestables form a short teaching circuit containing every
   harvest category: two trees, rock, ore, bush, crystal, fiber and wildlife.
4. All 70 nodes have at least 18 studs between interaction roots. The main north
   road, forest branch, mine branch, village square, lagoon and quarry entrances
   are protected from random canopy/resource/decor placement.
5. Village shops use pitched roofs. Fountain, beacon and UFO cylinders are
   rotated onto the intended vertical axis instead of rendering on their side.

`scripts/verify_map_routes.py` checks these contracts in both the generated
`.rbxmx` and packaged `.rbxlx`. It cannot verify Roblox pathfinding, camera
readability, collision feel, visual polish, or device performance.

## Roblox Studio acceptance

1. Open the newest `GorpsEvolution.rbxlx`, stop any active Play session, then
   inspect `Workspace > PlanetVerdant` in Edit mode.
2. From either center-near ranch, walk to the village and north trail without
   jumping over props. The fountain must be upright and every shop must have a
   visibly pitched roof.
3. Follow the colored markers. Within the first circuit, identify and collect
   Tree, Bush, Fiber, Rock, Ore, Crystal and Wild without opening a menu.
4. Confirm no harvest model overlaps another model or blocks the center, forest
   or mine paths. Deplete one of every type and confirm the full model hides and
   returns after its configured cooldown.
5. Run Device Emulator for phone portrait/landscape and record whether the
   route remains readable while the HUD and Roblox touch controls are visible.
6. Check Server and Client Output. Any red error, invisible node, impassable
   collision or misleading marker blocks acceptance.

Only human/engine evidence can close this visual milestone. A green workflow
proves deterministic geometry and packaging, not that the map looks finished.

## GE-MAP-03a — village-to-biome route fork

The north trailhead now divides into original curved Ground ribbons: six west
segments meet `ForestPath`, and six east segments meet `MinesPath`. A mint
forest waystone and amber quarry waystone sit between the center road and each
branch. Their Neon bands are emissive cues only—this pass adds no PointLight,
particle, moving part, reward or remote behavior. The 20-part addition keeps
the existing eight-light and 2,350-BasePart static budgets intact.

`verify_map_routes.py` requires both branches to progress north and outward,
remain non-colliding Ground parts, reach their destination roads, and keep both
four-piece waystones at least 20 studs from every resource interaction root.
This proves authored connectivity, not player comprehension or Studio physics.

**One Studio test:** from the default spawn, hold the same camera through the
north gate and identify the mint west/amber east fork without opening a menu.
Walk each ribbon to its named branch, harvest the closest node on each side,
and reject for any invisible gap, z-fighting, misleading turn, covered prompt
or avatar snag. Record one phone FPS/memory sample; Emulator memory is not a
real-device measurement.

## GE-MAP-03b — terraced Sunstone Quarry

The east landmark no longer uses a single low ridge and twelve identical rocks
on a rectangular grid. Three offset Slate terraces climb toward the northeast,
while two buttresses, a lintel, a dark non-colliding entrance and restrained
amber crest establish one readable portal. Nine ore clusters vary in footprint,
height and yaw. The replacement adds one net BasePart and no PointLight,
particle, animation loop or external asset.

`verify_map_routes.py` now rejects missing/non-rising tiers, a non-tapering
silhouette, an incomplete portal kit, repeated equal boulders, blocking Neon,
or ore clusters within 15 studs of any of the 70 resource roots. These are
static placement contracts, not Roblox camera, collision or art approval.

**One Studio test:** from the amber branch, keep a shoulder-height camera aimed
east while walking from `MinesPath` to the quarry apron and through the framed
entrance. Reject if the crest is hidden, terraces collapse into one flat mass,
the avatar snags, an ore cluster covers a prompt, or Slate/Ground surfaces
z-fight. Record the same phone FPS/memory sample used for the prior fork test.

## GE-MAP-03c — layered Moonwater Lagoon

The west lagoon no longer relies on one thin oval rim, ten equally spaced lily
pairs and one flat bridge plank. Three raised, offset shore shoulders frame an
open east entrance; an original four-piece Moonstone crescent anchors the west
skyline; seven uniquely sized lily clusters use hand-authored, non-radial
positions. The bridge now has three shallow deck modules and non-colliding
rails. The change adds seven net BaseParts but no PointLight, particle, runtime
loop, external asset, reward or harvest-node movement.

`verify_map_routes.py` rejects a flat shore hierarchy, repeated/equiangular
lilies, incomplete crescent, colliding Neon/water, excessive bridge step,
lagoon-local lights or landmark pieces within 15 studs of any of the 70
resource roots. These static contracts do not prove a safe Roblox water edge,
avatar collision, visual quality, bloom readability or mobile performance.

**One Studio test:** hold a shoulder-height camera while following the mint
west route to the lagoon, cross all three bridge decks, circle the north and
south banks, then continue toward Glowcap Grove. Reject for a snag, apparent
walkable water, hidden Moonstone silhouette, z-fighting, blown-out Neon, covered
resource prompt or unclear onward route; capture the same view and real-phone
FPS/memory before approving.

## GE-MAP-03d — lagoon-to-Glowcap cross-lanes

The lagoon bridge now joins the existing `ForestPath` with four low Ground
segments. Five more segments leave the north section of that primary lane and
turn west to the first Glowcaps. This deliberately reuses the established road
instead of shrinking the biome with a direct shortcut. A four-piece
non-colliding Glass/Neon guide identifies the last turn. The milestone adds 13
BaseParts and no PointLight, particle, runtime script, reward or moved node.

`verify_map_routes.py` requires exact 4+5 monotonically progressing links,
Ground material, no collision, correct endpoints, >=20 studs from all 70
resource roots, a Grove endpoint within 15 studs of a Glowcap, the exact guide
kit and zero handoff-local lights. The measured minimum segment-center resource
clearance is 24.2 studs. Static geometry cannot prove player comprehension,
terrain blending, collision feel, visual quality or real-device performance.

**One Studio test:** cross Moonwater bridge, follow the first link onto
`ForestPath`, go north, then take the Glass-cap guide west until the first
Glowcap. Reject if any turn is visually lost, a segment z-fights or floats,
the avatar snags, a prompt is covered, or the guide/Glowcaps bloom white; record
the same camera path and real-phone FPS/memory.


## GE-MAP-02a — solid relief and fantasy lighting (source-only, Studio QA pending)

The 2026-10-12 environment pass adds 14 peripheral escarpments, cleared solid knolls, four local village lantern PointLights, four Glowcap PointLights, and bounded Atmosphere/Bloom/ColorCorrection/SunRays in the Rojo Lighting tree. See [WORLD_ART_ROADMAP.md](WORLD_ART_ROADMAP.md) for reference links and acceptance. These do not constitute Roblox voxel Terrain.

**One engine walkthrough:** stop/restart Play after Rojo sync, pan from spawn toward north ridge, walk forest and quarry and try the nearest knoll, then go to Glowcap Grove. Check that new solid terrain never obstructs resources or the main path and the glow is visible but never blows out signs/UI; capture Device Emulator FPS and any first Output error. Source/CI alone cannot approve this art.

## GE-MAP-02b — actual voxel Terrain studio test

The runtime now calls the guarded server-side voxel builder on world bootstrap. Terrain is authored with Roblox's smooth voxel API, not merely native Ball/WedgePart props; freshly generated Rojo XML is still not a pre-baked Terrain asset. Confirm the server Output `[Gorps World] Applied smooth voxel terrain` line, that `workspace.Terrain` genuinely contains landscape in Play, 70 resource interact roots and 12 ranch plots remain usable, and no hill occludes a path. See [WORLD_ART_ROADMAP.md](WORLD_ART_ROADMAP.md) for the optional manual bake-to-Edit command. Record Android/iPhone device emulator frame time and screenshot; no source/CI pass substitutes for this check.

## GE-MAP-02e — corrected authored-map contour check

The previous actual-map CI run failed with zero accepted inland contours. The corrected plan targets twelve smaller measured hillocks, evenly split west/east, while preserving larger preferred contours when they are genuinely clear. In Studio Play, inspect the nearest hillocks at `(-92, 76)`, `(100, 90)`, `(-76, 150)` and `(256, 136)`. Walk around and over each one, activate the nearest harvest prompt, and reject the build for any buried root, avatar trap, abrupt material seam or blocked sightline. Record real device FPS/memory separately; CI cannot validate them.

## GE-MAP-02c — test new forest/quarry terrain transitions

With synced main, Stop → Play and watch the server's `[Gorps World] Applied smooth voxel terrain` line. From the village north exit compare the west forest, east quarry, and distant edge as actual different-elevation landscapes. Walk to the nearest safe inland slope, approach harvest resources and check no buried interaction prompts. Phone Emulator: note frame rate and memory before and after the change, not estimated values. The generator still retains the original ground Part until engine testing proves the new walkable terrain is complete.


## GE-MAP-02d real authored-map obstacle acceptance

CI now extracts the exact resource/tree/handcrafted-knoll/Glowcap anchors from `world/PlanetVerdant.rbxmx`, not invented test positions, then invokes the actual pure Luau terrain planner and requires usable hills on both sides of the resource corridor. This verifies placement intent in source and packaging only. In Studio check the west and east forest/quarry contours have not buried a glowing mushroom or a harvest node, and compare phone FPS before accepting the shape changes.
