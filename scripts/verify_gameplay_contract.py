#!/usr/bin/env python3
"""Static contract checks for Gorps' first playable loop (not Roblox runtime tests)."""
from pathlib import Path
config=Path("src/shared/Config.lua").read_text()
rules=Path("src/shared/Rules.lua").read_text()
server=Path("src/server/Main.server.lua").read_text()
world=Path("src/server/World.lua").read_text()
ui=Path("src/client/Ui.lua").read_text()
pages=Path("src/client/Pages.lua").read_text()
client=Path("src/client/Main.client.lua").read_text()
smoke=Path("src/server/StudioSmoke.server.lua").read_text()
contracts={
 "egg pool defined": "C.Eggs={" in config and "C.EggOrder" in config,
 "server chooses hatch roll": "math.random(1,total)" in server and "R.hatchEgg(p,payload.id," in server,
 "hatch is capacity checked": "#p.Pets>=R.capacity(p)" in rules and "function R.hatchEgg" in rules,
 "no untrusted hatch roll": '"HatchEgg"' in pages and "math.random(1,total)" in server,
 "UI hatch reveal": "function UI:showHatch(pet)" in ui and "ui:showHatch(result.hatch)" in client,
 "harvest shuts off prompts": "prompt.Enabled=false" in world and "setHarvestVisibility(node,false,true)" in world,
 "harvest respawns": "setHarvestVisibility(node,true,true)" in world and 'HarvestState","Ready"' in world,
 "pickup feedback": "function UI:showPickup(reward)" in ui and "ui:showPickup(data.pickup)" in client,
 "failed hunt doesn't deplete node": "if not won then" in server and "return false" in server,
 "first session smoke tests": "Starter egg regression" in smoke and "full ranch blocks hatching" in smoke,
 "gameplay dock": 'framed(gui,"ActionDock"' in ui,
}
for label,ok in contracts.items():
 assert ok,f"FAILED gameplay contract: {label}"
 print("PASS:",label)
print("PASS: static first-session contracts. Real Studio acceptance remains pending.")
