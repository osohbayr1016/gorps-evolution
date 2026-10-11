# Gorps Evolution — inspiration and first-session loop

Reviewed public gameplay descriptions of:

- [Pet Simulator 99](https://www.roblox.com/games/8737899170/PS99) — eggs, easy-to-understand pet team progression, currency from breakables, clear area unlocks.
- [Steal An Egg](https://www.roblox.com/games/107778070777162/Steal-An-Egg) — immediate egg → pet → income → base improvements; readable world stations and escalating goals.

**Design principles we adapt; do not copy their original meshes, code, UI art, assets, trademarks, character designs or proprietary implementation.** All Gorps species and planets remain distinct, with mining, feeding, hunting, house/ranch upgrades and future space travel. No player-value theft or betting is implemented.

## First five minutes

1. Spawn at a personal ranch on Planet Verdant. World remains explorable without menus.
2. Bottom dock has four large buttons: **EGGS, PETS, RANCH, TASKS**. Additional options live in MENU / G.
3. Harvest a glowing node with E. The node must shrink/sink and disappear; only after its cooldown should it pop back. A +resource pickup animation appears near the center of the screen.
4. Start with 250 coins. Hatch the original **Meadow Egg** for 100 coins; odds visible: Gorp 45%, Mole 30%, Carrier 20%, Bloom 5%.
5. Pick the creature that matches your next activity: Mole for minerals, Carrier for movement speed, Gorp for food from bushes.
6. Feed your companion, claim quest rewards, and work toward ranch capacity and a more advanced **Wild Egg** for 280 coins.
7. The village Creature Nursery opens the **Eggs** screen. Coin hatch is distinct from mineral-infused incubator crafting (later progression).

## Fairness and feedback requirements

- The **server** chooses the random roll. The client can request only a catalog egg ID.
- Always check coin balance and ranch capacity **before** spending.
- Any unsuccessful collection leaves the resource visible and the interaction prompt enabled.
- Reward quantities come from server-owned profiles, not client-supplied numbers.
- The map's resource node lifecycle is shared across the server: collection makes it unavailable to everyone until respawn.
- Short animations are decorative; they cannot be used for reward validation or prevent normal interactions.
- Hatch results are announced to the player; odds are shown before purchase. No paid random eggs.

## Studio acceptance checks (not automatically proven by CI)

- Enter Play: HUD starts minimized with top wallet and bottom action dock; center remains uncluttered.
- Open EGGS, hatch Meadow: coin cost 100, pet added, clear hatch reveal, new pet selectable.
- Try an egg without coins or with a full ranch: no charges and no added pet.
- Harvest Tree twice quickly: first pickup appears and tree disappears, second attempt unavailable; tree respawns after about 12 seconds.
- Lose a wildlife hunt: node does not disappear, no free meat.
- Verify Coins, Inventory, quests and creature stats stay in sync after multiple harvests and hatches.
- On a narrow mobile viewport, dock shortcuts remain accessible and no text fills the entire screen.
- Two clients see the same depleted world resources.
- Studio Output runs egg and trade smoke assertions without failures.

## Out of scope for this iteration

Roblox Studio live-engine verification, professional skinned/rigged models, PvP, secure cross-server pet trades, new planets, guaranteed performance on low-end mobile, and production publishing. This is a first-session design/interaction improvement, not a Phase 5 release.
