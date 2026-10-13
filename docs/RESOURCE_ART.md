# Planet Verdant — original resource art and UI icon pass

The first version relied on generic floating colored spheres. Resource nodes now use deliberately composed Roblox-native **Models**, named and shaped for their actual gameplay function. Because these are authored into the `.rbxmx` map, Rojo syncs them automatically in Edit mode and no imported third-party assets are needed.

| Resource | Visible geometry / expected silhouette |
| --- | --- |
| Tree | Trunk, roots, branching wood and layered crown |
| Rock | Several angular slate boulders and pebbles |
| Ore | Angular mining stone with distinct metal veins |
| Crystal | Rocky base, unequal-height prismatic spires and tips |
| Bush | Shrub clusters with berries, stem and foliage |
| Fiber | Thin individual reeds and seed heads |
| Wild | Boar-like animal with snout, ears, eyes, legs, hooves and tail |

Each remains a **native Roblox Part/WedgePart model**, not a Blender-created MeshPart with custom texture/UVs or skeletal animation. For mesh-quality production assets, generate licensed or original `.gltf` or `.fbx` models and import to Roblox Studio as private MeshPart assets. Asset IDs must be added after import. See Roblox Creator Hub importer documentation. We do not substitute unreviewed marketplace assets.

## Restrained rare-resource cue — GE-MAP-03q

Crystal is the highest-value authored harvest resource (`Config.Resources.Crystal=35`) and has the longest node cooldown (`40`), but its five tips previously shared Glass material with no visual hierarchy. Each of the nine Crystal nodes now uses one pale Neon crown only on the tallest existing spire and keeps four subordinate Glass tips. The crown is static and non-colliding: it adds no part, PointLight, ParticleEmitter, Beam, Trail, animation, script or RNG work. This is a source-authored identity cue, not proof of Studio contrast or rarity comprehension.

`scripts/verify_resource_models.py` protects the one-Neon/four-Glass contract and rejects resource-owned light/particle/trail/beam effects. `scripts/verify_map_routes.py` checks that the starter crown remains visible from a fixed ForestRoute shoulder camera. Studio/device acceptance must compare Crystal against nearby common resources at quality 1/10 and reject bloom washout, color-only ambiguity, prompt overlap or mobile regression.

## Anchored Crystal interaction cue — GE-MAP-03r

The nine Crystal models now place a renderless `PromptAnchor` Attachment 4.7 studs above the low Slate `Interact` center. `World.lua` parents the runtime cross-input ProximityPrompt to that anchor, so its projected cue originates at world y=6.5 beside the crystal body instead of 9.2 studs below the y=11 crown center. Harvest reward, cooldown, distance validation and depletion animation still use `Interact`; the change adds no visible Part, collision, light, particle, trail, animation or loop.

Creator Hub's [Proximity prompts](https://create.roblox.com/docs/ui/proximity-prompts) page explicitly supports Attachment parents and documents keyboard, gamepad and touchscreen cues. Static source/package checks prove hierarchy and server ownership only. Studio must approach `Crystal_006`, harvest, and watch the complete respawn on keyboard/touch to reject crown overlap, prompt drift, competing prompts or an unreachable activation zone.

## Glowcap foreground resource seating — GE-MAP-03s

Generated geometry showed the old west-Grove `LowHill` surface 0.970 studs
above `Tree_025`'s interaction center and 4.507 studs above `Ore_060`'s center.
The resource models/IDs have not moved; the same one-part relief budget is now
a narrower boundary backdrop with conservative clearances from all 70 roots.
This proves static separation only. In Studio, Harvest both nodes from the Grove
and reject a buried body/prompt, collision snag, apparent float or Output error.

## UI icons

The library `src/client/Icons.lua` generates resolution-independent geometric icons as native Roblox UI. The five main dock actions and window navigation have visual icons. Wallet uses a coin icon and resource inventories show wood, stone, iron, meat, berry, crystal and fiber icons.

No external raster URLs or paid icon packs are used. These icons can be replaced by a professionally illustrated sprite atlas later without changing gameplay actions.

## Roblox Studio acceptance

1. Let your existing Rojo Terminal pull the latest main commit; **Stop → Play**. If you are in Studio Edit mode, the map must already show full 3D resource models.
2. Walk to **Wood**, **Stone**, **Iron**, **Crystal**, **Berries**, **Fiber**, and a **Wild** creature. Confirm they are physically recognizable, not basic floating colored spheres.
3. Use **E** on each available resource. The whole model depletes, does not allow a second reward, and respawns with an animation.
4. Open the BAG screen. Every resource icon appears beside its actual count. Check the dock action icons, menu categories, and coin icon.
5. Test small mobile viewport for hit targets, alignment and legibility.
6. Check **Studio Server Output** and **Client Output** for errors; report any missing assets or gameplay defects.

## Automated verification

The GitHub workflow runs `scripts/build_world.py` to create the map, then `scripts/verify_resource_models.py` on both `.rbxmx` and packaged `.rbxlx` to ensure 70 complete model assemblies survived building, alongside existing Luau and game-contract checks. This is **not** a substitute for actual visual QA inside Roblox Studio.
