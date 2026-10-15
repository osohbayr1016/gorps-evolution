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
- Two-player pet and resource trade confirmation/cancellation in unsaved Studio multiplayer, including fully occupied ranches and asset overflow; published trading remains closed pending durable recovery
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

## Single-profile session ownership — live fault injection pending

Published loads now claim one reserved session token atomically with
`UpdateAsync`. Autosaves renew its five-minute lease, every save rejects a
foreign token, and leave/shutdown final saves remove the token. Legacy profile
tables retain gameplay fields, while malformed profile/lock values fail closed
instead of being replaced with defaults. A 31-assertion pure policy regression
covers takeover, stale writes, release and retry states.

This source guard is not production proof. Roblox DataStoreService timing,
throttling, crash behavior and unknown write outcomes still require the
private-published rapid-rejoin/fault-injection cases in `STUDIO_QA.md`. The
guard protects one profile key; it does not make a two-profile trade atomic.

For bugs, send the first red Output error, plus a screenshot showing the current game and Explorer > ServerScriptService tree.

## Trade integrity follow-up

The settlement engine stages both sides before applying pet or material changes, so a full-capacity 1-for-1 pet swap does not remove one creature prematurely. Rejected transfers must preserve each player's creatures, rarity, level, XP, evolution and inventory. Studio smoke assertions plus 26 headless checks test these in-process transitions.

As an immediate safety boundary, `Config.DurableTrades=false` is enforced by the server in every published session and the UI removes invite/offer controls. Unsaved Studio multiplayer remains available for functional testing. This prevents the confirmed cross-key loss path from being exposed to persisted inventories; it is not a durable-trade implementation.

`TradeReceiptPolicy.lua` now defines and headlessly fault-injects the required
PREPARING, COMMITTED, ABORTED and COMPLETE transitions. Its 101 assertions
converge safely after each of seven modeled durable writes. The policy is pure
and deliberately disconnected from live trade; see `TRADE_RECOVERY.md`.

`TradePersistence.lua` provides bounded retries, session-token checks,
immutable receipt matching and eight-mutation lost-response fault injection,
including the terminal retention schedule.
The published load path now resolves raw PREPARING/COMMITTED markers before
`Rules.load`, and autosave/unload cannot erase pending recovery evidence.
`TradeSettlement.lua` and `Data.settleTrade` now provide the still-gated live
bridge: both profiles are locked, exact preconditions are saved, ownership and
versions are revalidated, and memory changes only from a matching COMPLETE
receipt. Unknown outcomes force rejoin recovery and raw session release instead
of a snapshot save. The release flag remains false. Terminal receipts now
become eligible after 30 days for session-owned compaction to immutable
metadata-only archives; profile markers clear only after a matching archive is
observed. A 64-entry server-only diagnostic ring excludes offers and snapshots.
The concrete `TradeStoreAdapter.lua` now classifies wrapper failures and is
fault-injected with the coordinator, but only against a fake `UpdateAsync`
service; the ring and Output warnings are not restart-safe durable evidence.
The receipt itself now preserves bounded creation, immutable-decision and
completion timestamps across restarts inside its existing atomic writes. This
does not make wrapper error classifications durable and stores no trade payload
in the compact archive.

**Still release-blocking:** each player's profile persists separately. Crash
tests against the concrete/private-published DataStore remain mandatory before
changing the release flag. Required evidence includes failures before and after
receipt creation, each profile prepare, commit, each profile apply, retention
schedule/archive and cleanup, with retry-safe convergence and no duplicate
assets. Receipt decisions now persist bounded lifecycle timestamps inside the
same atomic values, without an extra write or archived offer/profile payload.
Headless audit tests prove chronology and retry stability, not live DataStore
timing or restart-safe wrapper error logs. The fake-store suites are not Roblox
runtime proof; a never-revisited
receipt may also remain full beyond its eligibility deadline because no global
background index has been approved.

## First-session collection loop (Pet Simulator 99 / Steal An Egg inspired)

Original implementation details and original Gorps designs are documented in [DESIGN_REFERENCES.md](DESIGN_REFERENCES.md). A server-owned coin egg hatch and visible gathering lifecycle have been added in source.

Studio QA still required: hatch coin pricing and odds, appearance/disappearance of nodes for all players, cooldown/respawn, purchase fail cases, accessible mobile HUD, screen effects and pet proportions. No guarantee of zero runtime bugs until those cases pass on device.

## Gameplay HUD v2

The compact HUD, centered interactive collection window, deterministic card order and 3D creature/egg preview implementation is documented in [UI_QA.md](UI_QA.md). Studio rendering, mobile and controller QA remain mandatory.

The follow-up objective rail now deterministically guides the full source-level
starter loop: collect and claim, hatch, feed, craft, hire, hunt, claim remaining
rewards, then expand the ranch. Each call-to-action only opens the relevant UI;
the server remains authoritative for rewards and purchases. A 50-assertion
headless regression validates ordering, routes, reward priority, malformed
snapshots and bounded progress. This does not prove player comprehension,
touch-control clearance, gamepad focus or real Studio updates; run the fresh
profile journey in `UI_QA.md` before accepting the onboarding gate.

The mission screen follow-up now shares the onboarding curriculum instead of
alphabetically placing Employer/Explorer before the starter Gatherer mission.
Claim-ready cards move first, unfinished curriculum follows, claimed cards move
last, and the exact current objective receives a visible gold treatment. The
selected top-tab label now changes contrast on the actual child label rather
than the empty parent button. The 68-assertion onboarding suite proves ordering
and state priority, but Studio is still required to verify scrolling, contrast,
focus and text fit on target devices.

Worker collection now preflights the authoritative crew state before mutating
payroll clocks. A stale client request that is fully wage-blocked is held with
an exact shortfall instead of expiring mature work; early/empty checks are also
non-mutating. Headless payroll tests retain the existing partial-pay and
60-minute-cap behavior, but Studio stale-button timing and the separate direct
automatic settlement on player initialization remain open acceptance gates.

The controller follow-up now uses the player's preferred input, assigns a valid
selection when the collection or hatch UI opens, restores selection after live
page reconstruction, skips disabled actions, and provides Y menu / B back
controls plus a visible focus ring. Static contracts prove that these paths are
wired but cannot execute Roblox GUI navigation. Run the Controller Emulator
case in `UI_QA.md`; controller/device acceptance and the 30+ FPS gate remain
open until real engine evidence exists.


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

The follow-up forest pass replaces the repeated three-ball tree with four
equally represented silhouettes, adds low biome floor fields and authored
forest props, and reduces broad Neon glowcap density. Follow
[BIOME_ART.md](BIOME_ART.md) for the required overview, collision, profiler and
device tests. The native-Part library is still an intermediate art system, not
final MeshPart/PBR production quality.

The runtime ranch follow-up turns the path-facing side into a gated homestead,
separates crop and worker coordinates, removes duplicate authored/runtime
fences, and adds visible silo, greenhouse and beacon expansion tiers. Follow
[RANCH_ART.md](RANCH_ART.md) for the required arrival, worker placement,
collision and level-silhouette Studio test. CI source/package contracts do not
prove real ranch physics, multiplayer placement, mobile FPS or final art
quality.
