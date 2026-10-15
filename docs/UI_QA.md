# Gorps HUD v2 — Visual and functional acceptance

This redesign is built directly into `StarterPlayerScripts/GorpsClient`. The entire interface is constructed in Luau and uses Roblox native UI and 3D ViewportFrames. No paid external assets or copied game code.

## UI concept

Inspired by the clarity of collection-based Roblox games rather than copying their interface:

- **In world**: small GORPS brand chip at the upper left, coin and level chip at the upper right, short next-quest tracker below the brand. No full-width opaque header.
- **Actionable objective rail**: the left card covers the complete starter journey instead of stopping after two counters. It prioritizes unclaimed rewards, then guides collect, hatch, feed, craft, hire, hunt and ranch expansion. Its button opens the matching trusted screen; it never performs a purchase or reward action by itself.
- **Readable mission priority**: QUESTS puts claim-ready rewards first, unfinished missions next in the intended Gatherer → Provider → Maker → Employer → Explorer curriculum, and claimed cards last. The current card has a gold border and `NEXT` marker. The selected top navigation label changes with its tab instead of recoloring an invisible parent caption.
- **Controller continuity**: when gamepad is the preferred input, Y opens the collection window on its active tab and B backs out. Page controls recreated by a server update regain a valid page selection or fall back to the active tab; closing returns selection to MENU. Disabled actions are not selectable, and controller focus has a visible light ring.
- **Quick access**: five large labeled buttons on a bottom dock: EGGS, PETS, BAG, QUESTS, RANCH. Also bound to keyboard 1–5.
- **Collection window**: opens on demand; it uses centered layout, dark blue game colors, gold/mint accents and an explicit close button. The bottom dock and quest tracker hide while this window is visible. Keyboard G toggles the window.
- **Collection-focused cards**: real 3D creature previews from the same CreatureFactory as in-world pets; egg previews, rarity accents, clearly displayed egg probabilities, visual growth bars, and readable requirements.
- **Ordered component layout**: all UIListLayouts sort by LayoutOrder and widgets assign monotonically increasing numbers. Headers, descriptions and buttons must never reverse or shuffle order when values update.
- **Affordability**: buttons say exactly what is missing or that an upgrade is locked. The authoritative validation remains on the server; client-disabled actions are only presentation.
- **Responsive width**: on narrow screens, menu fits viewport width and keyboard shortcuts do not replace touch buttons.
- **Trade safety state**: published profiles show a `PERSISTENT TRADING PAUSED` card and no invitation or offer controls while durable cross-profile recovery is incomplete. Unsaved Studio multiplayer keeps the test controls.

## Test in Roblox Studio

Use your existing Rojo GitHub-to-Studio sync. Wait until the terminal pulls the new main commit, stop Play, then restart.

1. **Play without opening anything**: only small top chips, a left objective, and the bottom dock should overlay the game. The viewport must NOT be covered by a large right sidebar.
2. Follow the objective card through a fresh profile: collect → claim → hatch → feed → claim → craft → claim → hire → claim → hunt → claim → ranch level 2. At every state its button must open the relevant QUESTS, EGGS, PETS, CRAFTING, WORKERS or RANCH screen. QUESTS must put the current/claimable card first with a visible gold `NEXT` treatment, move claimed cards below unfinished work, and show the selected QUESTS tab label in dark text on gold. Opening the card must never grant a reward or spend resources until that screen's explicit server action is pressed.
3. Press **EGGS**: the dock hides and a centered window shows 3D egg previews and odds. Confirm the close X works, then hatch a Meadow Egg for 100 coins.
4. After hatching, the reveal shows the creature in a 3D viewport with rarity and an EQUIP button. Press EQUIP: active companion updates and collection window changes to PETS.
5. Open **PETS**: each creature appears in its own 3D preview with level, rarity, growth and feed/evolve/selection buttons in the correct order.
6. Open **RANCH**: gather progress, feeding progress, exact expansion materials and a Hatchery shortcut. The shortcut must change pages without sending `__openTab` to the server.
7. Open BAG, CRAFT, SHOP, CREW, QUESTS and confirm all related actions and disabled states reflect actual server inventory.
8. Test a narrow/mobile viewport and open/close the menu while moving. Confirm the taller objective does not cover touch controls and its 236×30 action remains readable and tappable.
9. Harvest resources while the modal is closed. Coin and objective counters should update without forcing the menu open or resetting scroll.
10. In **Test > Controller Emulator**, press Y to open the collection window. Use the thumbstick and A to traverse tabs and enabled page actions; disabled actions must be skipped and the selected action must show a thick light ring. While a page action is selected, harvest or claim something so a live profile update redraws that page: focus must move to a valid action or the active tab, never disappear. Hatch an egg, confirm EQUIP starts selected, then press B once to dismiss the reveal and once to close the window. MENU must be selected after closing.
11. Switch back to mouse/keyboard and touch emulation. Opening a modal must not force a gamepad ring while `PreferredInput` is not Gamepad. Studio Output: no errors from `Widgets`, `Pages`, `Ui`, `Onboarding`, `CreatureFactory` or `Main.client`.
12. Compare contexts: a two-client local Studio server must expose invite/offer/accept controls, while a private published server must show `PERSISTENT TRADING PAUSED` without an editable username field or invite button.
13. On a fresh profile, open CREW after hiring Farmer #1 and confirm `WORKING` counts down once per second without page redraw, scroll jump or controller focus loss. Hire Farmer #2 at +59 seconds. At +60/+119/+120, reopen CREW and collect: server feedback and coins/inventory must show exactly 1/1/1 batches, one wage each. Repeat at 375×667 touch emulation with enough coins for `READY`, then with zero wage coins for disabled `WAGE BLOCKED` plus exact shortfall. A local `DELIVERY DUE` label is only a prompt to check; it must never grant resources before the server reply. Reject clipped labels, stale state after reopening, double rewards or Output errors.

## Remaining release blockers

This is a UI implementation milestone, **not** a full art/modeling pass or Phase 5 release. Controller focus continuity is source-implemented but Roblox Studio render quality, actual FPS, ring contrast, thumbstick traversal, accessibility, screen reader support and touch layout remain to be verified. Character models are still stylized primitive assemblies rather than professionally rigged imported meshes. Server persistence, production-safe cross-profile trades, PvP, interplanetary travel and live operations remain on the release gates.

Static CI verifies source integration and packaged scripts, **not** that Studio visual or interaction tests have passed.
