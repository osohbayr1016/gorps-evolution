# Original creature rigs and reactions — GE-ART-01a

This is an implemented companion art/interaction milestone, **not** acceptance of the whole game's art or Phase 1–5 release. These are original native Roblox geometry rigs, not downloaded assets, sculpted meshes, finished professional art or uploaded animation clips. No paid dependencies or animation IDs are required.

## What is implemented

| Species | Original silhouette | Moving joints |
| --- | --- | --- |
| Gorp | Round leaf guardian, antlers, bib and crest | Head, four paws, leaf tail |
| Bloom | Narrow flower rabbit, tall ears, six petals | Head with attached ears/petals, four paws, flower tail |
| Shade | Long low fox, pointed ears, fins and claws | Head, four paws, shadow tail |
| Boulder | Broad armored creature, segmented shell and horns | Head, four paws, armored tail |
| Mole | Low miner, lamp/helmet and backpack | Head, four paws, thin tail |
| Carrier | Long pack animal, saddle and side fins | Head, four paws, two fins, long tail |
| Dart | Compact bird creature, broad wings and feather crest | Head, four paws, two wings |

The root is anchored; all other parts are unanchored and connected by Motor6D joints or detail welds. Every part has collision, touch and query disabled. Four distinct paw names and unique moving-part names allow joint animation authoring. Each current species has fewer than 65 parts. Evolution and rarity scale the rig; both the world and portraits use the same factory.

`CreaturePose.lua` supplies idle breathing/head motion, diagonal walking paws, tail sways and wing movement. Successful feeding adds repeated chewing nods and faster wagging; harvesting and hunting turn toward the node and lean/lunge; evolution/equipping perform a short celebration. Cues expire and return to idle. Only validated successful server actions issue cues; cosmetic code never grants rewards or damage. Feeding an inactive creature does not animate the active one.

`Companions.client.lua` runs follow positioning and Motor6D.Transform poses on each observer, culls beyond 180 studs and removes destroyed rigs/connections. It no longer replicates per-frame pet pivots from the server. This is an architecture change, **not a measured performance improvement**. The UFO and resource tween replication still need separate profiling. Unchanged ranch/pet construction is preserved when feeding; the name/level label updates in place.

Successful active feeding/evolution/equipping closes the pet menu to reveal the reaction. Rejected actions keep it open. Inactive feeding keeps it open. Cards show gameplay-derived growth stats, and the portrait camera fits the actual model bounds, including evolution and tall ears.

## Build and edit

```bash
aftman install
python3 scripts/build_world.py
lune run scripts/export_creatures.luau
rojo build default.project.json -o GorpsEvolution.rbxlx
```

The generated `ServerStorage > CreatureRigs` shelf contains all seven editable models, their joints and AnimationControllers/Animators. These templates do not replicate to clients. They are generated from the runtime factory so geometry does not drift. Change `CreatureFactory.lua` to retain edits across regeneration. For exploratory Studio edits, duplicate a template into a separate local place before editing it. Confirm Animation Editor recognition in Studio before authoring clips; custom rig editor compatibility is not established by XML serialization.

## Automated evidence

- `lune run scripts/test_creature_rigs.luau`: real factory construction, all seven proportions, one anchored root, collision safety, weld/joint endpoints, four paws, part budgets, Bloom/Gorp differentiation, invalid species, cue start/expiry/future timestamps, finite bounded poses and visible pose differences. Lune lacks engine PivotTo; the harness explicitly supplies a geometry translation shim. It does not simulate constraints or client physics.
- `lune run scripts/export_creatures.luau`: round-trip XML serialization verifies all seven models, attributes, roots, unique moving names and joint references.
- Rojo packaging checks verify both executable animation scripts and all seven editable rigs are present.
- StudioSmoke defines engine construction checks but has **not been run here**.

## Required Studio/device acceptance

Use a fresh unsaved Studio place with isolated profiles; do not enable or publish monetization. Stop/Play after updating. Record the first red Output error plus a short capture if a visual case fails.

1. Walk, stop, turn and jump with the starter Gorp. Confirm four paws alternate, head/tail move, facing follows the character, the model stays assembled and does not push the avatar. Check slope/edge/jump following; ground contact is still a simplified avatar-height offset, not foot IK/pathfinding.
2. Feed the active Gorp with food. Menu closes, creature nods/wags for about 2.2s, XP/quest increment once, level label updates and the ranch/model remains the same instance. Attempt without food: no reaction and no deduction; menu stays open.
3. Feed an inactive pet. Only that pet gains XP; the active companion does not play a feed cue and the menu stays open.
4. Harvest a tree and win a hunt. Pet turns toward the successful target, poses and returns to idle. Failed hunts, distance rejection, depleted nodes and cooldown rejection must not play a success cue or grant extra resources.
5. Select all seven species using a **test-only Studio fixture**, never a production remote bypass. Inspect proportions, paw/head/tail/wing joints, all rarity/evolution sizes and unclipped portraits. Reach valid evolution prerequisites, evolve and check celebration plus correct card stats.
6. Start Server with two clients. Both see the owner's successful reactions; the other player's companion is unaffected. Reset, leave/rejoin, and move beyond/within 180 studs: no stuck poses, orphan connections or detached parts. Local visual position is cosmetic; do not use it as authoritative combat distance.
7. On phone/tablet emulation and a real target mobile device, check pet card buttons, feed & watch transition, tall/evolved previews, touch-control occlusion and frame time with 1/8/12 companions. Record profiler/network results before accepting performance.
8. In edit mode, duplicate a rig into Workspace in an isolated art place and open Animation Editor. Confirm joints are recognized. This is a separate manual authoring check; runtime animation already uses procedural poses.

## Research translated into implementation

- [Roblox performance guidance](https://create.roblox.com/docs/performance-optimization/improve) recommends client visual NPC animation and Motor6D.Transform for procedural joint motion. That informed the observer-side pose implementation; no FPS/network benchmark is claimed.
- [Motor6D reference](https://create.roblox.com/docs/reference/engine/classes/Motor6D) describes non-replicated Transform. Each observer applies shared server-clock cues locally in PreSimulation.
- [Roblox onboarding](https://create.roblox.com/docs/production/game-design/onboarding) prioritizes clear early goals and demonstrating mechanics. Revealing the companion after a successful action makes the player's first feed visibly understandable.
- Competitor progression research is recorded in [CONTINUOUS_IMPROVEMENT.md](CONTINUOUS_IMPROVEMENT.md). Pet collection alone does not establish art quality or first-session usability; a complete original world/UI pass and real playtests remain required.
