#!/usr/bin/env python3
"""Static contracts for gameplay HUD v2. Does not claim visual Studio QA."""
from pathlib import Path

ui=Path("src/client/Ui.lua").read_text()
pages=Path("src/client/Pages.lua").read_text()
widgets=Path("src/client/Widgets.lua").read_text()
icons=Path("src/client/Icons.lua").read_text()
factory=Path("src/shared/CreatureFactory.lua").read_text()
world=Path("src/server/World.lua").read_text()
checks={
 "world and pet UI reuse same creature factory":
    "ReplicatedStorage.Shared.CreatureFactory" in world
    and "ReplicatedStorage.Shared.CreatureFactory" in widgets,
 "deterministic card order":'SortOrder=Enum.SortOrder.LayoutOrder' in widgets
    and 'child.LayoutOrder=index' in widgets and 'W.order(parent,t)' in widgets
    and 'W.order(parent,b)' in widgets,
 "compact HUD":'framed(gui,"Brand"' in ui
    and 'framed(gui,"Wallet"' in ui and 'framed(gui,"CollectionWindow"' in ui,
 "first-session objective":'MissionProgress' in ui and 'self.objectiveBody.Text=' in ui,
 "no overlapping dock when modal opens":'self.dock.Visible=not open' in ui
    and 'self.objective.Visible=not open' in ui,
 "mobile panel bounds":'math.min(narrow and width-18 or 720,width-18)' in ui,
 "client-side tab routing":'if action=="__openTab" then' in ui
    and 'self:openTab(args.id)' in ui and '"__openTab"' in pages,
 "3D egg and pet cards":'W.eggPortrait' in pages and 'W.petPortrait' in pages
    and 'WorldModel' in widgets,
 "correct ranking function binding":'renderRankings(parent,rankings,route)' in pages,
 "hatch result and equip":'function UI:showHatch(pet)' in ui
    and 'self.send("SelectPet",{id=pet.id})' in ui,
 "gameplay controls preserved":all(k in pages for k in (
    '"HatchEgg"','"Feed"','"Evolve"','"Expand"','"Craft"',
    '"Buy"','"Sell"','"Hire"','"Claim"','"OfferPet"','"Accept"'
 )),
 "native resource and dock icons": 'local Icons=require(script.Parent.Icons)' in ui
   and 'Icons.create(button,entry[2],28)' in ui
   and 'function Icons.create(parent,name,size,tint)' in icons
   and all(('name=="'+item+'"') in icons for item in
     ("Eggs","Creatures","Backpack","Quests","Ranch","Coins","Wood","Stone","Iron","Berries")),
 "resource preview in inventory": 'function W.resourceIcon(parent,id,size)' in widgets
   and 'W.resourceIcon(header,id,42)' in pages,
 "creature model retained":'function Factory.create(pet,origin,parent)' in factory,
}
for name,valid in checks.items():
 assert valid, f"UI regression: {name}"
 print("PASS:",name)
print("PASS: static UI contract checks (Roblox Studio/device QA remains pending)")
