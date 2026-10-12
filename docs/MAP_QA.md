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


## GE-MAP-02a — solid relief and fantasy lighting (source-only, Studio QA pending)

The 2026-10-12 environment pass adds 14 peripheral escarpments, cleared solid knolls, four local village lantern PointLights, four Glowcap PointLights, and bounded Atmosphere/Bloom/ColorCorrection/SunRays in the Rojo Lighting tree. See [WORLD_ART_ROADMAP.md](WORLD_ART_ROADMAP.md) for reference links and acceptance. These do not constitute Roblox voxel Terrain.

**One engine walkthrough:** stop/restart Play after Rojo sync, pan from spawn toward north ridge, walk forest and quarry and try the nearest knoll, then go to Glowcap Grove. Check that new solid terrain never obstructs resources or the main path and the glow is visible but never blows out signs/UI; capture Device Emulator FPS and any first Output error. Source/CI alone cannot approve this art.

## GE-MAP-02b — actual voxel Terrain studio test

The runtime now calls the guarded server-side voxel builder on world bootstrap. Terrain is authored with Roblox's smooth voxel API, not merely native Ball/WedgePart props; freshly generated Rojo XML is still not a pre-baked Terrain asset. Confirm the server Output `[Gorps World] Applied smooth voxel terrain` line, that `workspace.Terrain` genuinely contains landscape in Play, 70 resource interact roots and 12 ranch plots remain usable, and no hill occludes a path. See [WORLD_ART_ROADMAP.md](WORLD_ART_ROADMAP.md) for the optional manual bake-to-Edit command. Record Android/iPhone device emulator frame time and screenshot; no source/CI pass substitutes for this check.

## GE-MAP-02c — test new forest/quarry terrain transitions

With synced main, Stop → Play and watch the server's `[Gorps World] Applied smooth voxel terrain` line. From the village north exit compare the west forest, east quarry, and distant edge as actual different-elevation landscapes. Walk to the nearest safe inland slope, approach harvest resources and check no buried interaction prompts. Phone Emulator: note frame rate and memory before and after the change, not estimated values. The generator still retains the original ground Part until engine testing proves the new walkable terrain is complete.
