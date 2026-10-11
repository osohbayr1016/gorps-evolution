# Planet Verdant — Roblox Studio live test

## What you should see in Edit mode (not Play)

After the GitHub update is pulled, `scripts/studio-live-sync.sh` runs `python3 scripts/build_world.py`, which writes `world/PlanetVerdant.rbxmx`. Rojo syncs that Model into `Workspace > PlanetVerdant` **without Play**.

A large landscaped island should appear: central village, four buildings, fountain, roads, 85 stylized forest trees, 70 harvestable nodes, 12 ranch plots, and an animated (in Play) UFO. The permanent green baseplate remains under the land as fall protection.

If Edit mode remains a blank floor:
1. Stop Play and read the **Terminal where the live-sync script is running**. It should say `Generated world/PlanetVerdant.rbxmx`.
2. In Studio's **Explorer**, expand `Workspace`. If `PlanetVerdant` is not present, open **Rojo → Disconnect → Connect** once.
3. Make sure the Terminal is inside the checked-out `gorps-evolution` clone, has `main` checked out and `git pull --ff-only origin main` succeeds.
4. Restart `bash scripts/studio-live-sync.sh` after closing any old Rojo server. Don't download another .rbxlx.

## What you should see in Play mode

- Top resource bar: GORPS / EVOLUTION, coins, level, creature count, ranch level.
- Right-hand game panel with Ranch / Creatures / Backpack / Crafting / Shop / Workers / Quests / Trade / Events / Rankings.
- Left-bottom mission tutorial.
- Your own ranch built on one of the 12 plots, with a starter Gorp following you.
- Press **E** near trees / ore / bushes to collect resources.
- Use **Creatures → Feed Gorp** to increase its XP; use **Shop** and **Workers** to progress.

**Verify in Server Output:** `[Gorps World] Authored map loaded: 70 harvest nodes`, `[Gorps Server] Gameplay remotes`, and `[Gorps Smoke]` test message. If errors, share the *first* red line and its stack trace. GitHub Actions cannot certify real Studio gameplay until this live test is executed.

## Source-of-truth and synchronisation

This generated map is deterministic from `scripts/build_world.py`; it is not hand-edited inside Studio. Changes to `world/PlanetVerdant.rbxmx` are overwritten by the next generation. For new buildings, trees, scene layout, or materials, update the Python generator. Rojo live sync is local and depends on the Terminal staying open.

The Github CI first runs the generator, then builds the place, and checks the output contains the actual map, the spawn and all critical game scripts.
