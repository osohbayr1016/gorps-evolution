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
| 15 | Hire Caretaker and wait | Pet auto-feeding consumes supplied feed ingredients |
| 16 | Claim unfinished quest | Rejected |
| 17 | Claim finished quest twice | Only first claim produces coins |
| 18 | Spin wheel twice in 24h | Second rejected; reconnect cannot reset cooldown |
| 19 | Weekend UFO exchange | Saturday/Sunday UTC permitted only with costs and capacity |
| 20 | Trade-up 3 creatures | Excludes active companion; no duplicate creature |
| 21 | Two-client material trade | Both propose, both accept, balances transfer correctly |
| 22 | Two-client pet trade | Active pets cannot be traded; capacity rules enforced |
| 23 | Cancel/disconnect mid-trade | No transfer; offers discarded |
| 24 | Close/rejoin experience | Coins, inventory, pets, worker state, quests and cooldowns persisted |
| 25 | Ordered leaderboards | Saved Coins, Wins, Minutes values appear after refresh |
| 26 | Mobile viewport / touch | Menu scrolls, buttons usable, no off-screen actions |
| 27 | Multi-user server (8-12) | Ranches unique, node respawn and profile saves stable |
| 28 | DataStore failure simulation | New public session is kicked rather than silently overwriting saves |
| 29 | Spam remote actions | Per-action cooldown and validation reject illegitimate changes |
| 30 | Studio console and profiler | No unhandled runtime errors, runaway loops, or severe frame-rate drop |

## Known QA gaps / priorities
- Studio host is not accessible through the current chat: no actual frame-rate, memory, reconnect, or UI device evidence yet.
- Procedural creature Part assemblies have movement/bob animation but are not skinned skeletal animation assets.
- Live PvP, interplanetary travel, premium Robux purchases, and matchmaking are out of scope for this initial Phase 1–2 branch.
- Trades are server-local and not durable multi-player database transactions; a server crash during a trade can cause cross-profile persistence disagreement. Consider escrow plus idempotency before opening the trading system to large public audiences.
- OrderedDataStore requests require production permissions and are rate limited. Verify ranking update frequency.
- Studio build and Selene checks are necessary but insufficient for acceptance.

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
