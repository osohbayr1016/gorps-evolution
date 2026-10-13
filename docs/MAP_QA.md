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

## GE-MAP-03f — seam-safe Glowcap threshold

The final rotated `GroveLink_05` and `GroveClearing` previously shared only a
1.37 stud² corner even though their centers satisfied the older proximity
check. One 12×11 non-colliding Ground `GroveThreshold` now overlaps the ribbon
by 28.36 stud² and the clearing by 92.40 stud². No route, harvest root, ranch,
Glowcap or gameplay payload moved; the world adds one BasePart and no light,
particle, script or external asset.

`verify_map_routes.py` clips the actual XZ oriented footprints in both source
and Rojo package, requires >=20/30 stud² joins, preserves Ground/non-collision
policy, and keeps the threshold >=20 studs from all 70 resource interaction
roots. This cannot prove Roblox rendering, avatar physics or player navigation.

**One Studio test:** hold the same shoulder-height lagoon→Grove camera and walk
slowly across `GroveLink_05`→`GroveThreshold`→`GroveClearing`. Reject any gap,
z-fighting, float, abrupt material edge, avatar snag or covered prompt. Then
record real-phone FPS/memory; Device Emulator is not real-device evidence.

## GE-MAP-03g — continuous bridge-to-Grove camera chain

The source-level camera audit found no unintended opaque part across the three
fixed sightlines from lagoon to forest, forest to Glass guide, and Grove entry
to north focal cap. It did expose a different geometric seam: the final bridge
deck and first LagoonLink segment overlapped by only 4.99 stud². Moving that
existing anchor four studs into the deck raises overlap to 31.37 stud² without
adding a part, light, particle, script, reward or RNG draw.

`verify_map_routes.py` now clips all five major route joints and rejects bridge,
ForestPath or clearing joins below their explicit overlap budgets. It also
casts shoulder-height 3D segments through authored oriented boxes to prevent
foliage/structure regressions from hiding the link, guide or focal cap. These
checks cannot prove Roblox camera projection, avatar physics or visual quality.

**One Studio test:** walk slowly from `ReedBridgeDeck_03` onto
`LagoonLink_01`, continue to the Glass guide and north focal cap without
changing the shoulder-height camera. Reject any gap, z-fighting, float, snag,
hidden cue or projected prompt overlap; record real-phone FPS/memory.

## GE-MAP-03h — asymmetric receding Verdant horizon

The original 14 escarpments used 56 real solid parts, but every ridge stacked
its foot, slope, shelf and crest at one X/Z center; the first four west/east
pairs were exact profile mirrors. The same 56 pieces now form 14 unique
profiles with 8.0–13.5 studs of receding depth and top elevations from 19.92 to
29.65 studs. Decorative distant shelves/crests do not cast shadows; collidable
feet/slopes still do. No part, light, particle, script or external asset was
added.

`verify_biome_art.py` checks both authored and packaged worlds for depth,
profile/top variety, no exact side mirrors, four-piece integrity, shadow policy
and existing part/light budgets. These checks cannot see parallax, skyline
holes, camera framing, collision feel or phone performance.

**One Studio test:** from default spawn capture west/east/north views, then walk
toward Moonwater and Sunstone at shoulder height. Reject intersecting strata,
sky holes, obvious mirrored repetition, invisible destination silhouettes or
an unexpected collision wall; record real-phone FPS/memory.


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

## GE-MAP-03i — modular village silhouettes at first spawn

The four village stations previously reused the exact same monolithic `Walls`
block, paired roof sizes/pitches and ridge elevation. Their colors and small
icons differed, but their spawn-facing architectural masses did not. Each shop
now uses a six-piece structural shell around the unchanged interaction Door,
with a distinct footprint, wall height, roof depth/pitch and ridge tier. The
four ridge centers span 16.4–19.1 studs; the nearest collidable station edge
remains at least 36.75 studs from the central lane.

This adds 20 anchored parts across the whole village and no light, particle,
script, external asset or RNG work. `verify_map_routes.py` enforces four unique
profiles, the modular wall kit, Door contract and central-lane clearance in
both authored and packaged XML. It cannot see wall/roof seams, projected
prompts, camera composition, collision feel or device performance.

**One Studio test:** from default spawn rotate once through Trading Post,
Workshop, Farmer Guild and Nursery, then activate each Door. Reject floating
trim, roof gaps, blocked prompts, invisible collision or silhouettes that still
read as clones; confirm the north gate remains visible and record real-phone
FPS/memory.

## GE-MAP-03j — clear spawn egress and gate reveal

Static measurement found the old 15-stud fountain basin centered inside the
18×18 `SafetySpawn` footprint and its column crossing the fixed shoulder-height
spawn→`GateCrest` segment. The same four pieces now sit at `(-15.5, 12)` as a
smaller left-shoulder landmark. The basin/water diameters are 11.5/9 studs and
the decorative water disc no longer collides. Generated XML measures 1.409
studs of spawn clearance, a 9.75-stud central half-lane and zero blockers on the
fixed gate line. No part, light, effect, script, external asset or RNG draw was
added.

`verify_map_routes.py` protects those geometry and collision contracts in the
authored model and packaged place. It cannot prove Roblox spawn resolution,
camera clipping, apparent scale, surface grounding, avatar movement or phone
performance.

**One Studio test:** press Play from the default spawn five times, walk straight
through the north gate each time, then circle the fountain. Reject any spawn
overlap, forced sidestep, camera clip, floating/embedded basin, hidden gate,
seam, prompt obstruction or red Output error; record real-phone FPS/memory.

## GE-MAP-03k — protect the first forest prompt approach

- **Date / status:** 2026-10-13; P1 source milestone, Studio/device QA pending; complexity low.
- **Confirmed source evidence:** the generated north-road→trailhead overlap is 240.00 stud²; trailhead→forest/quarry overlaps are 63.72/64.95 stud²; all adjacent branch segments overlap by at least 12.72 stud². The handoff is continuous. The first west prompt was the defect: a conservative player-root-height route approach to `Tree_001.Interact` measured 12.086 studs against its 13-stud `MaxActivationDistance`, leaving only 0.914 studs. This is deterministic geometry, not observed prompt UI or traversal.
- **Original design action:** preserve every resource root and reshape one internal forest-ribbon control point from `(-39, 80)` to `(-39, 76)` so the material path passes the first tree comfortably. New conservative distance/margin: 9.168/3.832 studs. No new art, light, particle, script, reward, RNG draw or external asset; 70 resources and 12 plots remain.
- **Acceptance evidence:** `scripts/verify_map_routes.py` checks source and package for the road/pad/fork footprint joints, >=12 stud² segment seams, both first prompts within 11 studs 3D of their branch centerline, and zero unintended fixed-line opaque blockers. Creator Hub [Construct your world](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/construct-your-world) documents material paths as navigation communication; [Proximity prompts](https://create.roblox.com/docs/ui/proximity-prompts) documents `MaxActivationDistance` visibility range. Numeric thresholds and placement are measured/original Gorps decisions.
- **Exact next milestone:** in Studio, walk the forest ribbon center from the gate and record where `Tree_001` first shows Harvest on keyboard and touch. Repair the first real projection, terrain-height, collision or input defect. Without engine evidence, measure the first forest resource→Moonwater turn before adding light or decorative density.

## GE-MAP-03l — mark the forest-to-Moonwater junction

- **Date / status:** 2026-10-13; P1 source milestone, Studio/device QA pending; complexity low.
- **Confirmed source evidence:** no missing surface was found: `ForestRoute_06`→`ForestPath`, `ForestPath`→`LagoonLink_04` and `LagoonLink_01`→`ReedBridgeDeck_03` overlap by 54.32, 57.88 and 31.37 stud². The final forest vector and southbound lagoon exit do form a 102.80-degree turn, while no local Moonwater cue existed at that junction. This does not prove a player became lost.
- **Original design action:** place a four-piece non-colliding `MoonwaterTurnGuide` at `(-116, 104)` on the east shoulder. Slate/Wood ground it; a Glass lens and one bounded Neon south rune distinguish the lagoon direction without another PointLight or particle. Four parts added; 70 resources, 12 plots, routes, rewards, RNG and all prompt rules remain fixed. Minimum starter-root clearance is 30.0 studs.
- **Acceptance evidence:** `scripts/verify_map_routes.py` checks exact source/package composition, materials/collision, resource clearance, measured turn band and fixed 3D visibility from the forest approach. Creator Hub [Construct your world](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/construct-your-world) supports repeated area cues at lane intersections; numeric placement is original Gorps measurement.
- **Exact next milestone:** in Studio, follow the forest ribbon past `Crystal_006`, keep shoulder-height camera through the junction, use the guide to turn south and reach Moonwater bridge. Reject wrong direction, hidden/oversized cue, float/embed, prompt overlap, snag or Output error; repeat with touch and record real-phone FPS/memory.

## GE-MAP-03m — close the bridge's vertical approach seam

- **Date / status:** 2026-10-13; P1 source milestone, Studio/device QA pending; complexity low.
- **Confirmed source evidence:** guide→`CrescentSpire` has zero unintended opaque CFrame intersections and the closest resource root to LagoonLink is `Wild_016` at 39.37 studs, so neither suspected reveal nor prompt crowding reproduced. The real defect is vertical: `LagoonLink_01` top y=1.32 and `ReedBridgeDeck_03` top y=4.60 leave a 3.28-stud rise even though their XZ footprints overlap.
- **Original design action:** add one collidable Wood `ReedBridgeApproach` aligned to the existing diagonal, 7.5×1×9.5 studs at a 19.7-degree pitch. Its low/high top edges are y=1.35/4.55, within 0.03/0.05 studs of the adjoining surfaces. Net +1 part; 70 resources, 12 plots, routes, lights, particles, rewards, scripts and RNG remain fixed.
- **Acceptance evidence:** `scripts/verify_map_routes.py` checks exact material/collision and <=0.1-stud endpoint deltas in both generated artifacts; it also protects the clear destination ray and >=30-stud resource clearance. Creator Hub [Construct your world](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/construct-your-world) uses wedge surfaces for elevation transitions; this inclined Wood block and its dimensions are original Gorps work.
- **Exact next milestone:** in Studio walk `LagoonLink_01`→ramp→first deck without jumping on keyboard and touch. Reject snag, forced jump, slide, float, water/deck clipping, seam, camera bump or Output error; record real-phone FPS/memory.

## GE-MAP-03n — contain the Moonwater overlook

- **Date / status:** 2026-10-13; P1 source milestone, Studio/device QA pending; complexity low.
- **Confirmed source evidence:** the west deck edge is 1.90 studs above `GlowingWater` and 2.78 studs above the solid rim surface. `BridgeRailNorth`/`South` were `CanCollide=false`, sat 1.60 studs above the deck, and the west edge had no rail. Static geometry therefore did not contain a player; no actual fall or camera issue is claimed.
- **Original design action:** lower and enable collision on both side rails, then add one Wood `BridgeRailWest` aligned with the -3-degree final deck. The U-guard seats at y=4.60, keeps a 7.0-stud return corridor and adds one part only. No water/shore/route/resource/ranch/light/particle/script/RNG change.
- **Acceptance evidence:** `scripts/verify_map_routes.py` checks the exact three Wood rails, collision, deck-height seating, >=6.5-stud corridor and >=3 stud² west-rail/deck overlap in both artifacts. Creator Hub [Construct your world](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/construct-your-world) documents containment of playable areas; placement is original Gorps geometry.
- **Exact next milestone:** in Studio cross the ramp, touch the west end, make a 180-degree keyboard/touch turn and return without jumping. Reject fall-through, rail vault, narrow turn, snag, camera bump, water clipping or Output error; record real-phone FPS/memory.

## GE-MAP-03o — make both Moonwater shore returns explicit

- **Date / status:** 2026-10-13; P1 source milestone, Studio/device QA pending; complexity low.
- **Confirmed/rejected source evidence:** ellipsoid sampling rejects the suspected fully enclosed lagoon: the east rim already descends toward the global y=1 ground. It does confirm there was no named or tested solid handoff around either side of the newly guarded bridge. This is a missing authored affordance, not evidence that a player was trapped.
- **Original design action:** add two 11×1×7 Slate `LagoonExitNorth`/`South` shelves at `(-185, 1.5, 31/59)`, yawed -7/+7 degrees. Their water-side ends overlap the existing solid rim with a 0.481-stud upward delta; their land-side ends extend beyond the rim and sit 1.0 stud above global ground. The pair frames the open east bank without another rail, light, particle or glow. Net +2 parts; 70 resources, 12 plots and all prompts/routes remain fixed.
- **Acceptance evidence:** `scripts/verify_map_routes.py` validates exact placement/material/collision, computes the real ellipsoid rim height at each rotated endpoint, requires <=0.55-stud rim rise and <=1-stud ground step, and keeps resource clearance/effect budgets in both generated artifacts. Creator Hub [Construct your world](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/construct-your-world) uses playable/unplayable materials and containment to communicate navigable boundaries; all dimensions are measured/original Gorps work.
- **Exact next milestone:** in Studio walk from the shallow visual water to north shelf→ground and south shelf→ground without jumping. Repair the first hidden edge, float/embed, snag, unexpected collision, material seam or camera defect. Without engine evidence, measure `GlowingWater`'s curved cue against the solid rim for a deterministic visual seam before more glow.

## GE-MAP-03p — level and package the Moonwater surface

- **Date / status:** 2026-10-13; P1 source/package milestone, Studio/device QA pending; complexity low/medium.
- **Confirmed source evidence:** the old 58×0.8×55 Ball cue was not a level surface: its bottom intersected the solid rim by 0.150 studs at center but floated 0.648–0.746 studs at the four cardinal edges. Rojo also omitted the uppercase `Shape` property on the packaged `GlowingWater`. No visible Studio seam is claimed.
- **Original design action:** use one non-colliding Neon elliptical Cylinder with its thin axis rotated vertical, bottom y=1.45 and top y=2.25. Its perimeter embeds 0.004–0.102 studs into the rim; seven original lily pads move down together and sit 0.005 studs into the level top. Canonical lowercase `shape` now protects all authored Part silhouettes through Rojo. No extra part, light, particle, runtime loop, reward or RNG draw.
- **Acceptance evidence:** `scripts/verify_map_routes.py` checks exact Cylinder shape/axis/size, four analytic rim samples, <=0.05 positive gap, <=0.15 burial and <=0.02 lily-seat delta in source/package. `scripts/verify_world.py` requires source/package PlanetVerdant histograms to match at 698 Ball, 714 Block and 95 Cylinder parts. Creator Hub [Construct your world](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/construct-your-world) supports iterative cohesive construction, material boundaries and cross-device optimization; the water profile and thresholds are original Gorps measurements.
- **Exact next milestone:** in Studio orbit Moonwater from the first deck, then traverse water→both exits. Repair the first floating/embedded edge, lily burial, z-fighting, blown-out glow, depth ambiguity or collision defect. Without engine evidence, audit rare-resource/Glowcap visibility and effect budgets before adding feedback.

## GE-MAP-03q — static rare-resource crown within the existing effect budget

- **Date / status:** 2026-10-14; P1 source/package milestone, Studio/device QA pending; complexity low.
- **Confirmed source evidence:** `src/shared/Config.lua` values Crystal at 35 and gives its node a 40-second cooldown, both highest among harvest resources. `scripts/resource_models.py` previously authored every one of five tips as overlapping Glass. The world already owns exactly eight bounded non-shadowing PointLights: four village lanterns and four Glowcap lights. This confirms a missing material hierarchy and a closed light budget, not a player-recognition failure.
- **Original design action:** change only the tallest existing tip on each of nine Crystal clusters to pale Neon. Four smaller tips remain Glass, so identity is shape-plus-height-plus-material rather than color alone. No part, position, prompt, collision, reward, cooldown, PointLight, particle, beam, trail, animation, script or RNG changes.
- **Acceptance evidence:** `scripts/verify_resource_models.py` requires one Neon/four Glass tips and no resource-owned animated/local-light effect. `scripts/verify_map_routes.py` casts a fixed unobstructed ray from `ForestRoute_05` to the `Crystal_006` crown. `scripts/verify_biome_art.py` fixes the 4+4 light ownership, total Range 136/brightness 4.12, shadows off and zero ParticleEmitter/Beam/Trail. Creator Hub warns that layered transparent effects and particle density increase GPU cost; numeric budgets and the cue are original Gorps decisions.
- **Exact next milestone:** in Studio compare `Crystal_006` against nearby Tree/Rock/Ore at quality 1 and 10, then enter Harvest range on keyboard/touch. Repair the first bloom washout, invisible cue, prompt overlap, color ambiguity, flicker or mobile-cost defect. Without engine evidence, measure the next rare-resource route sightline before changing glow.

## GE-MAP-03r — anchor the Crystal prompt without more glow

- **Date / status:** 2026-10-14; P1 source/package milestone, Studio/device QA pending; complexity low.
- **Confirmed source evidence:** Crystal `Interact` center y=1.8 was the runtime ProximityPrompt parent while its highest crown center is y=11.0. This confirms a 9.2-stud cue/silhouette separation, not a rendered overlap or missed interaction.
- **Original design action:** add one renderless `PromptAnchor` Attachment at local y=4.7 in each of nine Crystal bases and parent the existing runtime prompt there. The world origin is y=6.5; the original base still owns server distance, reward, cooldown and animation. Common nodes and every render/effect budget remain unchanged.
- **Acceptance evidence:** `scripts/verify_resource_models.py` checks nine exact source/package anchors, zero common-node anchors and no authored ProximityPrompt; `scripts/verify_gameplay_contract.py` checks Attachment parenting while preserving the 19-stud base-distance guard. Creator Hub [Proximity prompts](https://create.roblox.com/docs/ui/proximity-prompts) explicitly supports Attachment parents and cross-input cues. Studio rendering and input remain unverified.
- **One Studio test:** approach `Crystal_006` from `ForestRoute_05` at quality 1 on keyboard, note first Harvest appearance, trigger it, and hold the camera through depletion/respawn; repeat on touch Device Emulator and quality 10. Reject base burial, crown coverage, drift, unreachable activation, wrong competing prompt, flicker or Output error; record real-phone FPS/memory separately.
