# Gorps Evolution — playable release gates

This checklist is a **shipping contract**, not a feature advertisement. A green GitHub Actions build means the Roblox place file and Lua source can be packaged. It **does not** prove multiplayer, animation, economic integrity, or production readiness.

## Current rebuild: Core reliability and a real first session

### Accepted by GitHub Actions
- Luau lint and Rojo package generation
- Procedural 3D map generated into the .rbxlx
- Baked ground/spawn, 12 ranch plots and resource nodes
- Critical server/client/shared scripts present with source
- Automated regression checks for built assets

### Must pass in Roblox Studio (pending user test)
- Studio Play shows the GORPS HUD within ~2 seconds, even while server profile loads
- Studio local test profile starts without publishing or enabling DataStore API access
- Main gameplay status becomes SERVER_ONLINE and a starter ranch/pet appears
- Resource node E interaction works; quest and inventory update
- Hunting a wild creature produces a combat message, with meat/coins only on victory
- Feed, evolve prerequisites, buy, craft, sell, hire, collect and quest-claim rules
- Two-player pet and resource trade confirmation/cancellation, including fully occupied ranches and asset overflow
- Mobile and controller input, consistent 30+ FPS on target hardware
- Persistence and reconnect tested **in a private published experience** (studio profile is intentionally temporary)

## Phase 3 — competition

- [ ] Real-time PvP arena with server-authoritative matchmaker and team roles
- [ ] Combat animation, cooldown, damage indicators, positional abilities and fair rebalancing
- [ ] Ranked rewards, match history and dispute/recovery flow
- [ ] No player-value wagers or gambling
- [ ] Disconnect/reconnect and exploit tests

## Phase 4 — multiple planets

- [ ] Craftable rocket assembled from genuine resource costs
- [ ] At least two completed biomes/maps with unique creatures and mining drops
- [ ] Durable travel/unlock system, safe teleport and progression gates
- [ ] World streaming, memory and render-performance budgets validated

## Phase 5 — live operations and release

- [ ] Seasonal content calendar with tested Halloween/Christmas assets
- [ ] Event rollover, limited inventories and reward entitlement
- [ ] Robux product IDs and receipt processing with idempotent fulfillment
- [ ] Localization, accessibility, safety and moderation
- [ ] Load tests, device regression, retention/onboarding metrics, data-loss tests
- [ ] Legal/store policies reviewed; private experience QA approved
- [ ] Public publish and rollback strategy verified

**Do not call this production-ready until all relevant gates have real execution evidence.**

## How to test your next build

You already have Rojo Studio live sync. Wait for the terminal to fast-forward GitHub main; Rojo updates edit mode. Stop and press Play to restart the Roblox server scripts.

In **Studio > View > Output > Server**, look for:

- `[Gorps Data] Local Studio test profile: saves are intentionally disabled.`
- `[Gorps Server] SERVER_ONLINE - profile test mode: true`
- `[Gorps Server] Player ready: ...`
- `[Gorps Smoke] ... domain assertions passed (Studio only).`

The HUD should be visible immediately. If server connectivity fails, it should show a specific timeout error rather than disappear.

Studio test progress is intentionally discarded to keep isolated, unpublished testing safe. Test persistence separately in a private **published** Roblox experience with real DataStores.

For bugs, send the first red Output error, plus a screenshot showing the current game and Explorer > ServerScriptService tree.

## Trade integrity follow-up

The settlement engine now stages both sides before applying pet or material changes, so a full-capacity 1-for-1 pet swap does not remove one creature prematurely. Rejected transfers must preserve each player's creatures, rarity, level, XP, evolution and inventory. Studio smoke assertions test these transitions.

**Still release-blocking:** each player's profile persists separately. A Roblox server crash, write failure, or process shutdown between the two DataStore writes can leave cross-player trade balances inconsistent. A transaction receipt/escrow-and-recovery protocol must be implemented and crash-tested before public trading is enabled in a production experience. The current fix addresses atomicity only within a live server process.

## First-session collection loop (Pet Simulator 99 / Steal An Egg inspired)

Original implementation details and original Gorps designs are documented in [DESIGN_REFERENCES.md](DESIGN_REFERENCES.md). A server-owned coin egg hatch and visible gathering lifecycle have been added in source.

Studio QA still required: hatch coin pricing and odds, appearance/disappearance of nodes for all players, cooldown/respawn, purchase fail cases, accessible mobile HUD, screen effects and pet proportions. No guarantee of zero runtime bugs until those cases pass on device.

## Gameplay HUD v2

The compact HUD, centered interactive collection window, deterministic card order and 3D creature/egg preview implementation is documented in [UI_QA.md](UI_QA.md). Studio rendering, mobile and controller QA remain mandatory.


## Companion art source milestone — engine acceptance pending

Jointed original native-Part creatures, action poses, editable rig exports and pet-screen feedback are now implemented. This does not close an art/animation release gate. Follow [CREATURE_ART.md](CREATURE_ART.md) for Studio, multiplayer and device evidence; sculpted/skinned art, authored clips, clean-map/full-UI approval and later phases remain outstanding.

## Planet Verdant route milestone — engine acceptance pending

The generated map now preserves clear village/forest/mine corridors, teaches all
seven harvest categories in an eight-node starter circuit, spaces all 70 nodes,
adds physical route markers, and repairs pitched shop roofs plus sideways
cylinders. CI validates the authored and packaged coordinates. Follow
[MAP_QA.md](MAP_QA.md) for actual Studio navigation, collision, readability,
device and visual-quality acceptance. Static geometry checks do not prove that
the map is clean, fun, performant, or release-ready.
