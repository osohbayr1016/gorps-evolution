# Gorps Evolution / Chaos Galaxy — continuous improvement

Owner: TMT Core Studios. Updated: 2026-10-11. This is the cross-run implementation backlog. Source, headless Luau, lint and build evidence do **not** establish Roblox Studio, device, multiplayer, persistence, art quality or publish readiness. [RELEASE_GATES.md](RELEASE_GATES.md) remains the acceptance contract.

## Resume procedure

1. Read fresh `origin/main`, recent commits, open work and the latest Actions run. Preserve concurrent changes; never force-push or replay an old tree over main.
2. Read this file and the release gates. First finish a failing/incomplete previous milestone. Record the previous implementation commit and its exact CI run here in the **next** consolidated implementation commit; a commit cannot contain its own SHA.
3. Select one coherent, highest-value confirmed defect. Prioritize startup and first-ten-minute playability. Reproduce suspected issues before changing behavior.
4. Implement actual code, meaningful regression coverage and the matching Studio test instructions. Run the relevant tests, Selene and Rojo; push one consolidated commit directly to main and inspect its actual Actions results.
5. Update issue status, verification limits and NEXT ACTION. Rotate deeper audits through the coverage table; do not repeat a full audit from scratch on every run or create content/commit spam.

No paid dependencies, player-value wagers, live publishing or Robux changes. Phase 5 requires real Studio/private-experience evidence and user approval. The existing hourly automation resumes from this file; this document itself does not schedule execution.

## Latest implemented milestone: GE-MAP-01d — ranch and farming visual language

- Fresh baseline: [`040aeee`](https://github.com/osohbayr1016/gorps-evolution/commit/040aeeea178568087a8125e3303c8d552436a72b). Its exact push [Actions run 38138564695](https://github.com/osohbayr1016/gorps-evolution/actions/runs/38138564695) completed successfully. That previous forest pass shipped four tree silhouettes, biome floor fields, forest props and static density contracts; Studio acceptance is still pending.
- Confirmed visual/navigation defects: every runtime ranch door/window used the `-Z` wall although two plot rows sit on opposite sides of the shared center path, so the back row faced away from arrival; spawn orientation did not model the row direction; the first level-one worker spawned at `x=-12`, exactly inside crop beds centered at `x=-12`; the house used a flat roof slab; level growth mostly changed dimensions; and authored fence posts remained under a second expanding runtime fence.
- Implemented: row-aware mirrored gates, split fences, spawn points, porches and facades that face the shared center path; a two-panel pitched roof and ridge; west-side named crop/furrow/irrigation zone; east-side capped worker grid; non-colliding decorative glass, crops, banners and lights; visible silo/greenhouse/beacon tiers at ranch levels 2/4/6. Prices, inventory, worker output, pet state and progression rules are unchanged.
- Static cleanup: each of 12 empty authored plots now keeps one land reserve, homestead pad, arrival path and four corner stones. It no longer pre-builds a fence that can intersect the runtime level-dependent perimeter.
- Regression: `scripts/verify_ranch_art.py` checks both source and packaged `World` code for the path-facing door, separated worker grid, non-colliding decorations, worker visual cap and three upgrade tiers; it rejects the old door/worker/flat-roof coordinates and validates all 12 authored and packaged plot reserves.
- Verification boundary: Luau lint/compile, Python contracts and Rojo packaging cannot prove real facade orientation, collision feel, multiplayer plot overlap, visual quality or mobile performance. `RANCH_ART.md` defines one arrival → hire → level-tier Studio acceptance test.

## Previous implemented milestone: GE-MAP-01c — forest and terrain visual language

- Fresh baseline: [`ce1e4f3`](https://github.com/osohbayr1016/gorps-evolution/commit/ce1e4f36abf6a7bc847ceab22ab114563c33def7). Its exact push [Actions run 38136449650](https://github.com/osohbayr1016/gorps-evolution/actions/runs/38136449650) completed successfully. That previous village pass added four distinct station silhouettes and `VerdantWayfinder`; Studio visual approval is still pending.
- Confirmed visual defect: all 85 background trees used the same rectangular trunk and three overlapping ball crowns. The entire 648-stud ground read as one flat green plane, while Glowcap Grove used 29 broad Neon caps and 87 light dots. The screenshot therefore still looked like a greybox even after the village pass.
- Implemented: a reusable original native-Part forest kit with 16 Broadleaf, 16 Pine, 16 Birch and 16 Ancient trees; 12 low non-collidable forest/meadow/quarry color fields; six mossy fallen logs; and at least 12 studs between tree centers. Trunks remain collidable while every crown/bough/fan is non-collidable. Protected routes and starter-node clearances remain intact.
- Density/performance boundary: Glowcap Grove now has 16 Glass caps and 32 small Neon dots instead of 29 Neon caps and 87 dots. This lowers authored light/decor density but is not a measured FPS or memory claim. Official Roblox environment-art and performance guidance is linked in `BIOME_ART.md`.
- Regression: `scripts/verify_biome_art.py` checks four equal tree archetypes, required silhouette pieces, angular Pine/Ancient geometry, removal of generic `Leaves_*`, tree spacing, route clearance, foliage collision, biome fields, fallen logs, glowcap density/material and a 2,350 packaged BasePart ceiling.
- Verification boundary: deterministic Python generation, Rojo packaging and CI cannot prove that the forest looks professional, that avatar collision feels correct, or that target phones maintain 30+ FPS. `BIOME_ART.md` defines the required same-camera screenshot, walk and profiler acceptance.

## Previous implemented milestone: GE-MAP-01b — distinct village destinations

- Commit [`ce1e4f3`](https://github.com/osohbayr1016/gorps-evolution/commit/ce1e4f36abf6a7bc847ceab22ab114563c33def7) and [Actions run 38136449650](https://github.com/osohbayr1016/gorps-evolution/actions/runs/38136449650) passed. Trading, crafting, farming and nursery stations have separate palettes, roofline details and physical purpose marks; a walk-through wayfinder and plaza dressing replace cloned hut fronts. Studio visual QA remains pending.

## Previous implemented milestone: GE-MAP-01a — readable starter resource circuit

- Fresh baseline: [`c80d5c2`](https://github.com/osohbayr1016/gorps-evolution/commit/c80d5c207c7f360f15c10f563253412d8c535e31). Its exact push [Actions run 38134309847](https://github.com/osohbayr1016/gorps-evolution/actions/runs/38134309847) completed successfully. No open PR was present at inspection.
- Confirmed map defect: the resource spiral clamped many unrelated nodes to the same `z=37` line; random canopy and flowers had only small center exclusions; resource pairs had no minimum spacing. The main/forest/mine routes and landmark entrances were not protected. All village roofs were flat blocks, while the fountain, UFO and beacon used Roblox cylinders on their default horizontal X axis.
- Implemented: a deterministic eight-node teaching circuit containing Tree, Bush, Fiber, Rock, Ore, Crystal and Wild; seeded rejection placement with at least 18 studs between all 70 interaction roots; reserved village, north-road, forest, mine, lagoon and quarry corridors; canopy/decor exclusions around routes and starter nodes; physical color-coded trailhead markers.
- Silhouette repair: all four stations have two pitched planes and a ridge; fountain, UFO saucer and north beacon cylinders use vertical axes. Existing node rewards, cooldowns, 12 ranch plots and 70 modeled-resource contract are unchanged.
- Regression: `scripts/verify_map_routes.py` checks exact starter locations, every-category coverage, resource spacing, the clear north route, route markers, roofs and cylinder orientation in both source `.rbxmx` and packaged `.rbxlx`. `MAP_QA.md` defines the remaining engine/device test.
- Verification boundary: Python generation/static checks and Rojo package inspection do not prove that an avatar can navigate every collision, that markers are visually obvious, or that art/FPS is acceptable. Studio acceptance remains open.

## Previous implemented milestone: GE-ART-01a — companion rigs and action feedback

User feedback: the existing presentation is unacceptable; maps, UI and creature interaction need substantial original visual work. This entry addresses **one coherent companion milestone**, not the entire game or approved art quality. Do not describe Phase 5 or the game as finished.

- Fresh baseline: [`fcd3365`](https://github.com/osohbayr1016/gorps-evolution/commit/fcd33659a8837423c65e2c27ffec464c9a781063). Its exact [Actions run 38133019081](https://github.com/osohbayr1016/gorps-evolution/actions/runs/38133019081) completed successfully. Recent commits and main were rechecked; no newer main changes existed at inspection.
- Confirmed problem: all species shared the same body proportions, Gorp/Bloom had identical role-based geometry, every part was anchored, server Heartbeat only bobbed/floated models, and no successful feeding/hunting/harvesting pose existed. Feeding also destroyed/reconstructed the entire ranch and pet. Cards displayed catalog stats instead of growth stats, and the modal concealed pet reactions.
- Implemented: seven original body proportions; flower-rabbit Bloom and fox Shade details; movable head, four unique paws and appendage joints; one anchored root with detail welds; local idle/walk/feed/gather/hunt/evolution/equip poses. Server-authorized cues use the shared clock, target matching and expiry. No cosmetic client code mutates rewards or damage.
- World changes: unchanged ranch/active-pet construction is retained; feeding updates the label in place. Runtime companion tags register observer-side animation; the server no longer pivots companion assemblies every frame. No measured performance claim is made.
- Art deliverable: `scripts/export_creatures.luau` generates seven editable native-Part rigs with animation controllers into `ServerStorage > CreatureRigs`, packaged in the Studio build but not replicated as unused templates. Moving parts have unique animation names. Source, exporter and Rojo mapping are shipped; generated XML remains reproducible/ignored.
- Pet UX: successful active feed/evolution/equip reveals the companion; failed and inactive feeds retain the menu. Cards use Rules.stats; portrait framing fits actual rig bounds.
- Regression evidence: the new rig suite fails on the pre-change factory (`rig marker Gorp`), demonstrating that it detects the former unrigged models.
- Verification: **774** executable headless rig/pose assertions, **72** existing payroll assertions; seven rig XML serialization round trips; strict Selene; 23 runtime source compilations; gameplay/UI static contracts; Rojo and world/resource/spawn/runtime packaging checks. Headless geometry uses an explicit PivotTo translation shim, not Roblox joint/physics simulation. CI runs these suites and regenerates the rig shelf.
- StudioSmoke adds native construction checks. [CREATURE_ART.md](CREATURE_ART.md) contains the required visual, failed-action, inactive-pet, two-client, device, reset, culling and Animation Editor cases. They have **not** been run here.
- Remaining scope: these are native-Part rigs and procedural poses, not sculpted/skinned art or authored animation clips. Simplified follow height is not foot IK/pathfinding. Clean authored map composition, coherent full HUD/menu redesign, onboarding wayfinding and measured mobile polish remain separate milestones.
- Final Actions status: commit `c80d5c207c7f360f15c10f563253412d8c535e31`, run [38134309847](https://github.com/osohbayr1016/gorps-evolution/actions/runs/38134309847), completed successfully.

## Previous completed milestone: GE-WORK-01

**P1 — paid worker collections discarded fractional worked minutes. Fixed in the commit containing this entry.**

- Baseline inspected: [`0286285`](https://github.com/osohbayr1016/gorps-evolution/commit/0286285076ab13e93f37bc65b7cecbf7a23a9481). Its [Actions run 38126511705](https://github.com/osohbayr1016/gorps-evolution/actions/runs/38126511705) passed lint, static contracts, generated-world checks and Rojo packaging. No open PRs were found at inspection.
- Root cause: `src/shared/Economy.lua`, `E.tick`, assigned `w.last=now` after every completed collection. At 119s and 179s it paid two batches; at 180s the third completed minute incorrectly paid nothing. Repeated uneven collections slowed progression solely because of claim timing.
- Previously prepared [`2564d46`](https://github.com/osohbayr1016/gorps-evolution/commit/2564d46f33fc51a1d96a6dbb2868f3c8948df1ab) had an older parent and was not on inspected main. Its payroll approach was integrated into current main without reverting the later HUD/resource work.
- Fix: a collection with payable batches retains the elapsed sub-minute remainder. Unpaid whole minutes expire; a completely unpaid collection still resets its clock. The 60-minute cap, catalog prices, wages and output remain the same.
- Regression: `scripts/test_worker_payroll.luau` executes the actual Config, Rules and Economy sources with Lune 0.10.5. Only Roblox module-path resolution is shimmed; payroll and profile logic are not mocked or translated. The suite failed on baseline (third funded minute: expected 1 batch, got 0) and passed **72 assertions** after the fix.
- Coverage: early/exact/off-minute claims, repeated timestamps, uneven claims versus one delayed claim, no/partial wage funds, capped absence, worker-count scaling, Farmer/Miner/Caretaker outputs, auto-feeding, profile copy/hydration and backwards timestamps. Profile hydration is not a real DataStore test.
- CI: added the headless payroll step and pinned free Lune in `aftman.toml`; Selene also lints the regression runner. `StudioSmoke.server.lua` contains matching in-engine payroll assertions, still awaiting Studio execution.
- Local verification: 72 payroll assertions, all 21 runtime-source Luau compilations, first-session/UI contracts, Rojo 7.6.1 build, authored world/resource checks, baked spawn and packaged-script checks passed. Selene 0.32.0 also passed with zero errors/warnings/parse errors using the official generated Roblox standard-library artifact from Selene Actions run 36936804173 after the direct API fetch failed. That temporary file is not shipped; CI retains its normal strict Roblox lint configuration.
- Final Actions status: commit `fcd33659a8837423c65e2c27ffec464c9a781063`, run [38133019081](https://github.com/osohbayr1016/gorps-evolution/actions/runs/38133019081), completed successfully; checked again when starting GE-ART-01a.
- Remaining engine check: hire one Farmer and collect around 59s, 119s, 120s, 179s, 180s. Expect 0, 1, 1, 0, 1 batches; each delivery costs 8 coins and grants 4 berries + 1 meat. Real input timing can vary; StudioSmoke uses exact timestamps.

## Prior shipped source work (engine verification pending)

| Commit | Change | Verification boundary |
| --- | --- | --- |
| [`0e1a042`](https://github.com/osohbayr1016/gorps-evolution/commit/0e1a042b1753dc3c965ce4059d2b65e9c5470190) | Studio test-profile startup, HUD and wildlife repair | Included in current source; real Studio result not supplied |
| [`7291dfa`](https://github.com/osohbayr1016/gorps-evolution/commit/7291dfa5521fe1fd3fad79e9c17f476c23c86dd5) | Staged full-ranch pet trade settlement | Live-server atomicity assertions exist; durable two-profile settlement still missing |
| [`65e9692`](https://github.com/osohbayr1016/gorps-evolution/commit/65e9692dc25382bbfbacca3699c0e5104956b628) | Coin eggs and visible harvesting lifecycle | Static contracts pass in inspected main CI; depletion and feedback need two-client Studio QA |
| [`a85d694`](https://github.com/osohbayr1016/gorps-evolution/commit/a85d6947a07d394da96f41983900c8cea4fca225) / [`0286285`](https://github.com/osohbayr1016/gorps-evolution/commit/0286285076ab13e93f37bc65b7cecbf7a23a9481) | HUD safe area, modeled resources and native icons | Main CI green; visual/device approval remains pending |

## Severity-ordered active backlog

Confirmed means supported by current source or an executed regression. Suspected means a targeted reproduction is required. Pending QA is a release gate, not a claim that the feature is broken.

| ID | Priority / state | Evidence and impact | Next concrete action |
| --- | --- | --- | --- |
| GE-TRADE-01 | P0 release blocker; confirmed missing recovery | `Trade.lua` changes two profiles; `Data.lua` saves each separately. `RELEASE_GATES.md` explicitly documents disagreement after a crash between writes. | Design durable receipts/escrow, idempotent settlement and recovery; fault-inject every write boundary in a private test experience before public trading. |
| GE-START-02 | P1; source fixed / Studio pending | [`70084b6`](https://github.com/osohbayr1016/gorps-evolution/commit/70084b6be1b886797d9480c4e58068f57484c927) binds removal/join handlers, deduplicates initialization and enumerates existing players after bootstrap. [Run 38135950394](https://github.com/osohbayr1016/gorps-evolution/actions/runs/38135950394) passed; no real join-during-bootstrap evidence exists. | In Studio, delay bootstrap and verify an already-present plus concurrently joining player each receive exactly one profile/ranch. Add a deterministic lifecycle harness if an engine defect appears. |
| GE-SAVE-02 | P1; source guarded / fault injection pending | `70084b6` uses per-player tokens, parent checks and unloads a profile installed after departure. It does not execute a real yielding DataStore disconnect test. | Fault-inject departure before/after `Data.load` returns; assert no orphan ranch, message, movement connection or later save. |
| GE-SAVE-03 | P1 release blocker; confirmed missing session ownership | `Data.save` returns its local snapshot from UpdateAsync without comparing `_old` to an ownership token/version from another server. | Reproduce overlapping server sessions, then add a safe session-ownership protocol and stale-writer rejection; verify recovery. |
| GE-WORK-02 | P2; confirmed clock reset on additional hire | `E.hire` sets the whole worker group's `last=now` on every hire. Hiring at 59s discards the existing worker's nearly completed minute. | Define per-worker/joined-worker accounting; add a 59s additional-hire regression before fixing. Do not grant a new hire retroactive output. |
| GE-WORK-03 | P2; confirmed feedback gap | `Pages.lua` shows wages/production but no pending-batch timer; Collect reports the same generic wait message for insufficient wages and genuinely immature work. | Add server-derived ready/blocked feedback and clearly explain unfunded work, with exact-boundary and mobile checks. |
| GE-PLAY-01 | P1 gate; pending Studio QA | Source has safe spawn, ranch, 70 nodes, hatch/feed/hunt/craft/sell/hire/quest paths. No supplied uninterrupted first-ten-minute playthrough proves they work together. | Execute `STUDIO_QA.md` core cases in an unpublished place; capture first red Server Output error and fix that blocker before later phases. |
| GE-UI-01 | P1 gate; pending device QA | HUD has resize/safe-area rules and activated buttons; controller navigation and smallest touch screens have not been tested. | Run portrait/landscape phone, tablet and controller cases in `UI_QA.md`; check focus, occlusion, touch controls and every actionable screen. |
| GE-SEC-01 | P1 gate; partly audited, unverified exploits | Main validates action/payload and uses a cooldown; World checks harvest distance; trade confirmation is server-owned. This does not prove exploit resistance for every route. | Exercise malformed IDs/types, replay, remote flood, distant prompts, simultaneous harvest and changed offers; classify failures before patching. |
| GE-MULTI-01 | P1 gate; pending Studio QA | Shared node depletion, plot allocation and server-local trades exist; no observed 2-client or 8–12-player runtime test. | Check unique ranches, shared cooldowns, no double rewards, late join, reset and disconnect; record client/server evidence. |
| GE-PERF-01 | P2 gate; unmeasured | Companions now animate locally with distance culling; World still creates resource tweens and moves the UFO; authored map uses many Parts. No measured FPS, memory or network budget. | Profile 1/8/12 clients and target mobile devices; record actual timings/replication cost before changing architecture. |
| GE-ART-01 | P1 visual milestone; source implemented / Studio pending | GE-ART-01a provides jointed native-Part rigs and action poses; no sculpted/skinned art or authored clips, and no engine visual approval. | Execute CREATURE_ART.md; repair the first visible/engine defect before accepting the companion milestone. Later commission/author original refined mesh art and clips. |
| GE-MAP-01 | P1 visual milestone; four source passes / Studio pending | Route/spacing, distinct village destinations, a four-archetype biome kit and a path-facing ranch/farm composition are implemented with packaged contracts. No engine/device visual approval exists and native Parts remain intermediate art. | Execute `MAP_QA.md`, `BIOME_ART.md` and `RANCH_ART.md`; repair the first navigation, collision, visibility, FPS or art defect. Later replace approved silhouettes with original optimized MeshPart/PBR assets where they add material value. |
| GE-UI-02 | P1 next visual milestone; user-reported inadequate presentation | Eleven modal tabs and prototype cards lack a unified finished visual pass; onboarding has counters but no guided location workflow. | Apply one original ranch/galaxy art direction to HUD, menus and touch layouts; actionable goals and world guidance, then device/first-session QA. |
| GE-PROG-01 | P2; confirmed incomplete long-term milestones | Quest counters, eggs and ranch expansion exist; public-release area progression and interplanetary goals are not implemented. | After core gates pass, specify clear next-goal/unlock feedback without copying competitors' assets. Test new-player comprehension. |
| GE-PVP-01 | P2 Phase 3; missing | Release gates are unchecked; README declares no real PvP/ranked wins. | Server-authoritative non-wager arena, disconnect handling, readable abilities and fair reward tests. |
| GE-SPACE-01 | P2 Phase 4; missing | Only Planet Verdant exists; no craftable spacecraft/durable second-planet travel. | Genuine recipe costs, second original biome, durable unlocks and safe travel/reconnect tests. |
| GE-LIVE-01 | P3 Phase 5; missing/pending | Seasonal rollover, entitlement recovery, localization, accessibility, moderation/load QA and approved publish/rollback remain ungated. | Work on one milestone only after core/PvP/travel gates; publishing and Robux changes require explicit authorization. |

## Audit rotation and coverage

This is an inventory of coverage and remaining checks, not a claim that every file was deeply audited in this run.

| Area | Phase | Current evidence | Next deep review |
| --- | --- | --- | --- |
| Startup / unsaved Studio profiles / ranch spawn | 1 | Data, Main, World, SpawnSafety sources and prior packaged-script CI | GE-START-02 / GE-PLAY-01 |
| Gathering / wildlife / cooldowns | 1–2 | World lifecycle and Adventure/Rules routes; static gameplay contracts | 2-client depletion and failed-hunt behavior |
| Feeding / evolution / crafting / eggs | 1–2 | Config and Rules/Economy source; Studio smoke definitions | In-engine prerequisites, feedback and full-ranch failure cases |
| Worker wages / economy | 1–2 | GE-WORK-01 real headless Luau regression | Additional hires, mixed-worker insufficient-wallet ordering and balance |
| UI / onboarding / icons / accessibility | 1–2 | Pages/Ui/Main/Status source, existing UI contract checks | Goal navigation, pending wages, mobile/gamepad readability |
| 3D models / animation / authored world | 1–5 | Original procedural models and generated-asset CI | Rig quality, device rendering and action animations |
| Performance / memory / networking | 1–5 | Heartbeat/tween source reviewed, no runtime measurements | Device profiler and replicated-part budget |
| Multiplayer / trades / data persistence | 2–5 | Live-server staged trades; cross-profile and ownership gaps | Crash recovery and lifecycle fault injection |
| Security / malformed input / anti-exploit | 1–5 | Representative server validations only | All route and replay tests |
| Skill-based non-wager PvP | 3 | Missing per release contract | Begin after core release gates |
| Multi-planet / craftable travel | 4 | Missing per release contract | Begin after stable core and travel design |
| Seasons / leaderboards / live operations | 5 | Basic leaderboards and weekend UFO exist; production gates pending | Rollover, entitlement, privacy/localization and approved release |

## Competitor research checkpoint — 2026-10-11

Read public primary descriptions, not a hands-on session or a retention/performance benchmark. See also [DESIGN_REFERENCES.md](DESIGN_REFERENCES.md).

| Reference | Verified public pattern | Gorps gap / original adaptation |
| --- | --- | --- |
| [Pet Simulator 99 — official BIG Games update](https://www.biggames.io/post/pet-simulator-99-update-7) and [official systems index](https://db.biggames.io/wiki) | The dated update describes area quests, visible quest locations and rank-based egg/pet-equipment unlocks. It does not prove today's balance. | Source has mission counters and ranch upgrades; test whether players understand their next task/location, then develop original activity/planet milestones. |
| [Steal An Egg — official Roblox description](https://www.roblox.com/games/107778070777162/Steal-An-Egg) | Describes eggs → hatch → pet income → base/movement upgrades and desktop/console/mobile/tablet support. | Gorps workers need dependable earnings first (GE-WORK-01), then readable delivery timing and a tested device flow. Keep Gorps' consent-based trades and original ranch/creature roles. |
| Other collecting/farming games | Grow a Garden and Creatures of Sonaria are existing README inspirations; no fresh hands-on review claimed here. | Next rotation: inspect primary descriptions and a concrete progression/biome-readability pattern when that subsystem becomes the selected milestone. |

Research is translated into backlog/implementation decisions. It is not a reason to add unrelated features before fixing core gameplay.

## NEXT ACTION

1. Verify the exact main commit/Actions run for GE-MAP-01d and record results when resuming. Repair a failing build or supplied first red Studio error before adding another milestone.
2. If map/companion/ranch Studio feedback is supplied, fix the first confirmed engine or visual defect. Otherwise continue the user-requested visual overhaul with GE-UI-02: one coherent first-session HUD/onboarding milestone with clear world guidance and touch layouts; do not add unrelated raw features.
3. GE-START-02 / GE-SAVE-02 have source guards but still require engine/fault-injection evidence; GE-TRADE-01 / GE-SAVE-03 remain public-release blockers. Do not hide them behind art work or claim public readiness.
4. After verified core/visual gates, progress to skill-based non-wager PvP, original refined assets/clips, genuine multi-planet craftable travel and seasonal content. No public publishing or Robux changes are authorized.

Studio acceptance request: follow the single arrival → hire → level-tier test in `RANCH_ART.md`. Confirm the gate/door face the shared path, the Farmer appears east of the crop beds, decorations do not snag the avatar, level 2/4/6 silhouettes do not intersect, and record the first red Output error or severe overlap. Route, biome, companion and device acceptance remain in `MAP_QA.md`, `BIOME_ART.md`, `CREATURE_ART.md` and `RELEASE_GATES.md`.
