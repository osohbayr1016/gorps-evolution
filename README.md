# GORPS EVOLUTION — Chaos Galaxy

A Roblox creature-survival, ranch-building and economy game by **TMT Core Studios**.

**Current status:** Phase 1 + Phase 2 foundation implemented as a Roblox Studio build. The repository is not yet a playtested, published Roblox experience. Source is published directly on `main`.

## Recommended: live Studio sync on macOS (setup once, then no more place downloads)

Run the following **once** in macOS Terminal:

```bash
brew install rojo
git clone https://github.com/osohbayr1016/gorps-evolution.git
cd gorps-evolution
rojo plugin install
bash scripts/studio-live-sync.sh
```

If you already cloned the repository, use `cd /path/to/gorps-evolution` instead of cloning it again. `rojo plugin install` may require restarting Studio so that the plugin appears.

In Roblox Studio: **Stop** Play, open the game's place, select **Plugins → Rojo → Connect** to localhost port `34872`. Rojo synchronizes edited files from the local repository into Studio's **edit** state. Leave Terminal running. Every 15 seconds, the script checks `origin/main`, pulls only fast-forward updates (never overwrites uncommitted changes), and Rojo syncs the changed sources. **Stop and press Play again** after updates to restart scripts. If Studio is closed, you can restart this script when ready; there is no need to download a .rbxlx every update.

This is local live sync, **not remote control of your Mac from ChatGPT**; GitHub pushes alone cannot inject edits into an arbitrary open Studio window. The Rojo CLI + Studio plugin must run locally. Keep the loopback-only sync endpoint private.

## Alternative: download a release place file (not required after Rojo setup)

1. Install [Roblox Studio](https://create.roblox.com/docs/studio/setup), [Aftman](https://github.com/LPGhatguy/aftman) and [Rojo](https://rojo.space/).
2. Clone the repository and use the `main` branch.
3. Run `aftman install`, then `rojo build default.project.json -o GorpsEvolution.rbxlx`.
4. Open the **newly downloaded** `GorpsEvolution.rbxlx` in Studio as a **new place** (do not press Play in an already-open old build). Press **Play**. The permanent Baseplate + SafetySpawn keep characters safe even while the planet and profile are loading.
5. For hot-reload development, run `rojo serve` and connect the Rojo Studio plugin.
6. **Publish a private test experience before relying on persistence.** In Studio, enable access to API Services for test DataStores, and avoid pointing Studio test sessions at a production datastore. Studio falls back to **unsaved** test data when API access is unavailable.
7. Use a 12-player maximum server size until plots and world streaming are expanded.

The GitHub Actions pipeline generates a `GorpsEvolution.rbxlx` artifact on every push to `main`. Download from **Actions → Roblox validation → Artifacts** if you prefer not to build locally.

## Current feature status

| System | Available in source |
| --- | --- |
| Starter Planet Verdant | 70 procedural resource/creature nodes, 12 ranch plots, weekend UFO landmark |
| Species | Gorp, Shade, Boulder, Bloom, Carrier, Mole, Dart |
| Raising creatures | Feeding, XP, up to 25 levels, two evolution tiers, hatch incubators |
| Class roles | Support, Assassin, Tank, Transport, Miner, Ranged; transportation and harvesting effects |
| Ranch | Individual fenced land, expansion costs, pet capacity |
| Gathering | Wood, stone, iron, berries, meat, crystal, fiber, respawns |
| Crafting | Crafting level, consumables, alloys, incubator |
| Shop | Supplies, decorations, crystal bundles purchased with earned coins |
| Employees | Farmer, Miner, Caretaker with wage costs and one-minute production; caretakers auto-feed |
| Trading | Real-time two-party material or pet offers with mutual acceptance |
| Rewards | One spin every 24h, quests, rarity-based three-pet trade-ups |
| UFO | Weekend exchange for a Rare creature |
| Rankings | Cross-server ordered Coins, Wins, and Minutes, with a HUD view; Wins remains 0 until PvP is added |
| Persistence | DataStore load/save, autosave, retry, validation |
| HUD | Creature, backpack, crafting, shop, worker, quest, trading, events and ranking menus |
| Automated checks | Selene linter, Rojo build, Studio-only smoke assertions |

## Important scope boundaries

**Not included yet:** inter-planet flight, real PvP/ranked wins, wagers, monetized Robux pet IDs, sculpted/skinned production art, animated skeletons, complete creature combat AI, multi-server trades, or production-scale concurrency guarantees. Procedural creatures are Roblox Part assemblies with scripted floating/follow animation, not imported professional-grade rigs.

Do not introduce wagered-value PvP. Skill-based ranked modes and game-funded rewards can be built separately.

## Architecture

- `src/shared/Config.lua` — trusted catalog and costs
- `src/shared/Rules.lua` — pure progression rules and safe profile hydration
- `src/shared/Economy.lua` — crafting, shops, worker wages, quests, daily prizes
- `src/server/World.lua` — runtime world, ranch construction, creature visualization
- `src/server/Main.server.lua` — network action router, server-side authority, per-action cooldown
- `src/server/Data.lua` — player profiles and DataStore write lifecycle
- `src/server/Trade.lua` — consent-based multiplayer trades
- `src/server/Leaderboards.lua` — cross-server ranked scores
- `src/client/Ui.lua` / `Pages.lua` — adaptive in-game menus
- `src/server/StudioSmoke.server.lua` — assertions during Studio playtests

## Testing and release

`selene src` lints Luau; `rojo build default.project.json -o GorpsEvolution.rbxlx` validates packaging. In Studio **Play**, check the Output panel for `[Gorps Smoke]`; then follow [QA checklist](docs/STUDIO_QA.md), including two-client trading and reconnect persistence.

**Build passing does not imply runtime QA passing.** Run Studio gameplay, persistence, multiplayer, and mobile QA before public release. The repository uses direct pushes to `main`, not a pull-request workflow.

## Spawn/fall prevention (October 2026)

The original Rojo project generated its only ground inside `World.make()` at runtime, with no authored `Workspace.Baseplate` or `SpawnLocation`. This made spawning fragile if server initialization failed or the character appeared before player data was ready.

- `default.project.json` embeds a permanent 700x700 anchored collidable floor plus neutral `SafetySpawn` directly into the place.
- `src/server/SpawnSafety.server.lua` runs independently of game initialization. It assigns player respawn locations and restores characters if they fall below Y=-20.
- CI verifies **the actual built .rbxlx** contains collidable ground + spawn. Studio smoke tests check that both exist and the generated planet ground is collidable.
- To retest, stop Studio, open **the new .rbxlx build artifact**, and press Play. Existing already-open place files do not auto-update when a commit is pushed. If the avatar still falls, send the first red Output error from the server tab.

## Debugging the empty-baseplate problem

Before this update, `Main.server.lua` was the only script responsible for creating the planet, and it first required persistence/trading/economy modules. A failure during initialization could leave only the baked baseplate without any ranch, tree or HUD.

The independent `WorldBootstrap.server.lua` now generates Planet Verdant immediately without waiting for profile or economy systems, and creates a visible red error marker if world generation fails. An independent `Status.client.lua` shows a diagnostic panel if the normal HUD does not initialize.

The CI check `scripts/verify_runtime_package.py` verifies that the produced XML place actually contains live Source on every critical Script, LocalScript and ModuleScript. The previous CI only validated the baked floor and spawn, which did not prove the gameplay scripts existed.

For errors, switch to **Server** in Studio and open **View → Output**. Search for `[Gorps Bootstrap]`, `[Gorps World]` and `[Gorps Server]`. If the red error marker appears, share the first error.
