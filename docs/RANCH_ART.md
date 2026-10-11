# Planet Verdant ranch and farming art QA

This pass gives the runtime player ranch a clear arrival facade, separate farm
and worker zones, and visible expansion tiers. It uses an original native-Part
kit and the same restrained Verdant palette as the village and forest passes.
No competitor, Creator Store or third-party models, textures or code are used.

Relevant Roblox Creator Hub guidance:

- [Environmental art curriculum](https://create.roblox.com/docs/tutorials/curriculums/environmental-art)
- [Construct your world](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/construct-your-world)
- [Design for performance](https://create.roblox.com/docs/performance-optimization/design)

## Confirmed pre-pass defects

- Every ranch door and window used the `-Z` wall even though the two ranch rows
  sit on opposite sides of the shared center path. The entire back row faced
  away from its arrival side, and spawn orientation had no row-facing model.
- The first worker used `pos.X-half+6`, which placed a level-one worker at
  `x=-12`, directly inside the crop beds centered at `x=-12`.
- The ranch house was a rectangular block with a flat roof slab, and higher
  ranch levels only made the land and house wider.
- Every authored empty plot contained perimeter fence posts while the runtime
  ranch created another expandable perimeter. At some levels those two fence
  systems intersected and spent unnecessary static parts.

## Implemented composition

- Both ranch rows now mirror toward the shared center path. A wide gate, split
  front fence, porch, door, windows and spawn point share that arrival side.
- Two angled roof panels, a ridge, porch, step, crest and warm facade lighting
  give the house a recognizable homestead silhouette.
- Three named crop beds, furrows, varied crop colors and a narrow irrigation
  channel form a west-side farming zone.
- Workers occupy a capped east-side grid and no longer share crop coordinates.
- Ranch levels 2, 4 and 6 visibly add a storage silo, greenhouse canopy and
  beacon respectively. These are presentation cues; upgrade prices and
  progression rules are unchanged.
- Decorative glass, foliage, lights and banners do not collide. The perimeter,
  house, porch and gate remain physical.
- Authored empty plots keep only a low land reserve, homestead pad, arrival
  path and four corner stones. Runtime ranches own the actual expandable fence.

## Roblox Studio acceptance

Run one unpublished Play test from a fresh profile, approach the assigned ranch
from the central ranch path, and then hire a Farmer. The gate, porch and door
must face the approach; the Farmer must appear in the east work yard rather
than a west crop bed; the avatar must pass through the front gate; decorations
must not snag movement; and Output must contain no red error. Use a temporary
test profile at ranch levels 1, 2, 4 and 6 to confirm the silo, greenhouse and
beacon appear without intersecting the house or fence.

The Python/Rojo contract proves source/package presence and removes the two
known coordinate regressions. It does not prove final art quality, Roblox
physics, live multiplayer placement, lighting or mobile performance.
