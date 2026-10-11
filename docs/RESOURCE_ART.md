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
