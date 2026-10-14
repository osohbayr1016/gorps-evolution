# Planet Verdant forest and terrain art QA

This pass replaces the repeated trunk plus three-ball canopy with a small
original native-Part asset library. The design follows Roblox Creator Hub's
environment-art guidance: environmental art should support gameplay, distinguish
areas and communicate world context; modular kits should create variety without
shipping each scene as a separate heavy asset.

Primary references:

- [Environmental art curriculum](https://create.roblox.com/docs/tutorials/curriculums/environmental-art)
- [Construct your world](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/construct-your-world)
- [Assemble modular environments](https://create.roblox.com/docs/tutorials/use-case-tutorials/modeling/assemble-modular-environments)
- [Design for performance](https://create.roblox.com/docs/performance-optimization/design)

No Roblox, competitor, Creator Store or third-party geometry, textures or code
are copied into Gorps. This remains a lightweight native-Part art pass, not a
substitute for final original MeshPart/PBR production assets.

## Implemented composition

- 64 trees split evenly across Broadleaf, Pine, Birch and Ancient silhouettes.
- Tree centers are at least 12 studs apart and stay outside the protected
  village/resource paths and starter-node clearances.
- Foliage is non-collidable while trunks remain collidable.
- Twelve low non-collidable biome fields vary the forest, meadow and quarry
  floor color without creating avatar steps.
- Six fallen logs add deliberate forest-floor storytelling.
- Glowcap Grove was reduced from 29 large Neon caps plus 87 dots to 16 Glass
  caps plus 32 small light dots. This is a static density reduction, not a
  measured frame-rate claim.
- Those 16 caps now form an authored asymmetric ring around a 46×34
  non-colliding Ground clearing rather than an unconstrained RNG scatter. The
  protected center is at least 50 studs from every stem, stem pairs remain at
  least 19 studs apart, and eight height tiers rise to one north focal cap.
  The four existing grove lights and downstream world RNG boundary are unchanged.
- The former broad west `LowHill` enclosed two nearby resource interaction
  centers. Its one-part budget now forms a narrower/taller boundary backdrop;
  CI keeps a conservative margin around all 70 resource roots and 16 stems and
  preserves the clearing-to-focal-cap shoulder-height sightline.
- The other three broad `LowHill` ellipsoids enclosed six more interaction
  centers by 3.160–7.140 studs. Their unchanged three-part budget now forms
  unique forest/quarry/Sunstone boundary backdrops with 15/16/17-stud height
  tiers, no covered resource roots and no new light, particle, script or RNG.
- Conservative rotated AABBs then found forest/Grove/Sunstone shoulders cutting
  four upper `CliffSlope` solids. The unchanged four-part shoulder budget now
  touches only escarpment `RockFoot` bases; fixed forest/quarry route-to-crest
  rays remain clear, and source/package checks reject an upper-layer overlap.
- The actual runtime terrain plan previously stacked all three
  `EastRimHillock` voxel lobes through `QuarryBackdropHill`. That contour now
  occupies the measured east escarpment gap at `(312,210)`; exact generated-map
  regression keeps every planned sphere at least 5.720 studs from all four
  authored backdrop ellipsoids while preserving 46 fills and the 6/6 biome split.
- CI rejects a return to generic `Leaves_*` trees, missing archetypes, path
  obstruction, overlapping tree centers, excessive glow lights or more than
  2,350 packaged static BaseParts.

## Roblox Studio acceptance

1. Inspect Planet Verdant from the same overview angle used for the previous
   screenshot. Broadleaf, Pine, Birch and Ancient trees must read as four
   different silhouettes, not recolored duplicates.
2. Walk the village-to-resource route and both branch paths. No foliage should
   collide with the avatar; only trunks should stop movement.
3. Enter Glowcap Grove from the new east link, stand on `GroveClearing`, and
   rotate the camera. The center must stay walkable; the north focal cap must
   read above the ring; harvest prompts must remain visible without bloom
   whiteout. Harvest `Tree_025` and `Ore_060`; neither body/prompt may be buried
   in the hill. Then compare western forest, northern meadow and eastern quarry.
4. In Device Emulator, test a representative phone in portrait and landscape.
   Record client FPS, memory and any visible pop-in using Studio profiling tools.
5. Check Server and Client Output. The first red error, impassable collision,
   severe overlap or unreadable biome blocks acceptance.

The Python/Rojo tests prove deterministic authored geometry and packaging only.
They cannot prove final visual quality, lighting, real collision feel or mobile
performance. Do not accept this milestone without the Studio checks above.
