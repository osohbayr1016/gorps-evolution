# Roblox Studio QA — Gorps Evolution

**Owner:** TMT Core Studios. **Status:** pending human/in-Studio verification; no runtime pass is claimed by this document.

## Local test environment
- Open the CI artifact `GorpsEvolution.rbxlx` (or build using Rojo).
- Press Play; check Output for `[Gorps Smoke] 33 domain assertions passed` (number may change as tests grow). Any assertion failure is a blocker.
- In a published private test experience, enable Studio API Services only for test data and verify reconnect persistence.
- Run Test → 2 Players to validate material and creature trading. Test mobile screen sizes via Studio Device Emulator.
- Set experience Max Players ≤ 12 until ranch plot allocation supports more.

## First: infinite falling regression

1. Open the **new** `GorpsEvolution.rbxlx` from the latest GitHub Actions build, not the old currently opened place.
2. In Studio Edit mode, expand `Workspace` and confirm `Baseplate` and `SafetySpawn` exist before you press Play.
3. Press **Play**: player should stand on the platform immediately even if DataStore calls take time; when profile loads, player should teleport to a ranch on the generated ground.
4. In the **Server** Output, look for `[Gorps SpawnSafety] Static ground and neutral spawn are ready.` and check smoke test assertions.
5. Confirm `Workspace > ChaosGalaxy > Ground` is anchored and collidable in Play mode.
6. If character enters void below Y=-20 after teleport, it should be restored onto the safe platform within a second.
7. Respawn your avatar using Studio's Reset Character command; it must not fall infinitely.

## Release-blocking acceptance checks

| # | Case | Expected |
| --- | --- | --- |
| 1 | Join as a new player | Receive ranch, Gorp, starting inventory, wallet 250 |
| 2 | Walk toward Tree node and press E | Wood gained; node prompt disables then respawns |
| 3 | Gather ore/stone/crystal/bush/wild creatures | Correct inventory and quest counters |
| 4 | Farm currency and supplies | Balance never becomes negative |
| 5 | Feed Gorp | One meat + one berry spent; XP and level update |
| 6 | Evolve before level 5 | Server refuses without charging |
| 7 | Evolve after requirements met | Appropriate materials deducted once |
| 8 | Add pets past capacity | Server refuses; expanding ranch increases capacity |
| 9 | Select Carrier creature | Walk speed increases and resets when switching away |
| 10 | Purchase one shop item | Coins decrease once; items increase once |
| 11 | Sell 5 wood then attempt to oversell | Sale works; unauthorized oversell fails |
| 12 | Craft FeedPack and Alloy | Costs and crafting XP tracked |
| 13 | Hire Farmer then collect before 60s | No free output or missing wages |
| 14 | Collect after 60s | Output and wage deduction occur once |
| 14a | Hire one Farmer; collect around 59s, 119s, 120s, 179s, 180s | 0, 1, 1, 0, 1 batches; each batch costs 8 coins and grants 4 berries + 1 meat |
| 15 | Hire Caretaker and wait | Pet auto-feeding consumes supplied feed ingredients |
| 16 | Claim unfinished quest | Rejected |
| 17 | Claim finished quest twice | Only first claim produces coins |
| 18 | Spin wheel twice in 24h | Second rejected; reconnect cannot reset cooldown |
| 19 | Weekend UFO exchange | Saturday/Sunday UTC permitted only with costs and capacity |
| 20 | Trade-up 3 creatures | Excludes active companion; no duplicate creature |
| 21 | Two-client material trade in local Studio server | Both propose, both accept, balances transfer correctly once |
| 22 | Two-client pet trade in local Studio server | Active pets cannot be traded; capacity rules enforced |
| 23 | Cancel/disconnect mid-trade in local Studio server | No transfer; offers discarded |
| 23a | Open TRADE in a private published server | Protection notice shown; username input, invite, offer and accept controls absent |
| 24 | Close/rejoin experience | Coins, inventory, pets, worker state, quests and cooldowns persisted |
| 24a | Leave and immediately rejoin a private published server after earning a distinctive coin amount | New session loads that amount, or explicitly refuses while the prior five-minute lease is active; never loads defaults |
| 24b | Rejoin after a deliberately interrupted final save / expired lease | New server takes ownership after expiry, stale server cannot overwrite it, and no coins/items roll back or duplicate |
| 25 | Ordered leaderboards | Saved Coins, Wins, Minutes values appear after refresh |
| 26 | Mobile viewport / touch | Menu scrolls, buttons usable, no off-screen actions |
| 27 | Multi-user server (8-12) | Ranches unique, node respawn and profile saves stable |
| 28 | DataStore failure simulation | New public session is kicked rather than silently overwriting saves |
| 29 | Spam remote actions | Per-action cooldown and validation reject illegitimate changes |
| 30 | Studio console and profiler | No unhandled runtime errors, runaway loops, or severe frame-rate drop |

## Known QA gaps / priorities
- Studio host is not accessible through the current chat: no actual frame-rate, memory, reconnect, or UI device evidence yet.
- Native-Part Motor6D rigs and procedural action poses are implemented; visible joint motion, collision behavior, Animation Editor compatibility and mobile performance remain unverified. Run [CREATURE_ART.md](CREATURE_ART.md) before accepting the art milestone.
- Live PvP, interplanetary travel, premium Robux purchases, and matchmaking are out of scope for this initial Phase 1–2 branch.
- Published player trading is deliberately fail-closed because separate profile keys are not a durable transaction. Do not enable `Config.DurableTrades` until receipt/prepare/commit/abort recovery passes every-write-boundary private-server fault injection.
- The 101-assertion receipt suite models state transitions only. It does not call DataStoreService; live trade stays closed until the adapter, join-time recovery and private-published crash cases in `TRADE_RECOVERY.md` pass.
- OrderedDataStore requests require production permissions and are rate limited. Verify ranking update frequency.
- Studio build and Selene checks are necessary but insufficient for acceptance.
- The session-policy suite is pure Luau. It does not prove real `UpdateAsync` retries, throttling, unknown outcomes or cross-server lease timing; capture both server logs and the persisted value in a private published experience.

## Empty baseplate regression

- On Studio Play the first ranches, colorful nodes and UFO should be visible even if player profile loading is delayed.
- Output must include `[Gorps Bootstrap] Planet is ready before player data loads.`.
- Output must include `[Gorps World] Planet Verdant initialized`.
- UI should appear after successful profile load; if it fails, an independent startup diagnostic appears on screen.
- If a world module errors, a **bright red** `GorpsWorldFailureMarker` must appear.
- CI must reject a place build that is missing the Main server/client scripts or shared game modules.
- When Rojo live sync is connected, a new push to main should download automatically into the local clone, then propagate into Studio edit mode; Stop/Play to reload.

## Authored planet + gameplay UI acceptance

- With Rojo connected and Play **stopped**, Workspace contains `PlanetVerdant`. Its child groups include `VillageHub`, `ForestsAndWildlife`, `ResourceNodes`, `RanchPlots`, `SignatureLandmarks`, and `UFO`.
- Village hub, quarry, lagoon, glowcap forest, roads, and stalls are visible in **Edit mode**.
- Playing shows the top HUD, right menu, mission hint, player ranch, and moving starter Gorp.
- Harvest an `Interact` node using E; currency/inventory and quest progress change.
- At a village shop door, press E; the menu should open directly to Shop/Crafting/Workers/Creatures.
- The first ranch assigned should be one of the two center-near-village plots.
- In the Server Output look for `[Gorps World] Authored map loaded: 70 harvest nodes`.
- New CI assertions must confirm 350+ baked 3D parts, 70 nodes, and 12 ranch plots in the generated place before upload.

If the editor still looks empty after the initial map update, stop the live-sync Terminal process and relaunch `bash scripts/studio-live-sync.sh`, then reconnect the Rojo Studio plugin. Do not download a new .rbxlx.

## Worker payroll regression

`lune run scripts/test_worker_payroll.luau` executes the actual shared modules outside Roblox and checks collection timing, wages, output, caps, insufficient funds, all worker types and profile hydration. The suite is also run by GitHub Actions. This does not verify real DataStores, UI input or Roblox scheduling.

In Studio Play, hire a Farmer and use Workers > Collect around the timestamps in case 14a. Use the hire time as zero, allow for real click latency, and check the resulting wallet and inventory. StudioSmoke repeats the exact simulated timestamps automatically. With no wage funds, completed work is forfeited rather than accumulated as debt; production resumes after a newly funded minute. Additional hires currently reset that group's timer (GE-WORK-02), so do not hire a second worker during this timing test.


## Creature reaction milestone

Run every case in [CREATURE_ART.md](CREATURE_ART.md), including active/inactive and rejected feeding, all seven rigs, two observers, respawn and evolved portrait framing. Source/headless passes are not a substitute for these tests.
## Trade raw-load recovery fault case — source integrated, private publish required

Published trading remains disabled. For a dedicated disposable test universe,
seed a profile with a valid session-owned `_trade` marker and matching receipt,
then join once for PREPARING and once for COMMITTED:

- PREPARING must become ABORTED, preserve the original inventory and clear the
  pending marker into an ABORTED terminal result.
- COMMITTED must apply the exact after snapshot once and retain a COMMITTED
  terminal result.
- An invalid receipt, wrong user/role or unavailable receipt store must kick
  with the safe recovery message; it must never load defaults.
- During a pending marker, autosave must log that it deferred. Leaving must
  release `_session` without deleting `_trade`.

Do not run this against valuable player data. CI fake-store coverage is not
evidence of Roblox DataStore timing, throttling or cross-server behavior.
