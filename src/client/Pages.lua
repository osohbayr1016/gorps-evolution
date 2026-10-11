local C=require(game:GetService("ReplicatedStorage").Shared.Config)
local Pages={}
local function sortedKeys(obj)
 local keys={}
 for id in pairs(obj) do table.insert(keys,id) end
 table.sort(keys);return keys
end
local function costText(cost)
 local items={}
 for _,id in ipairs(sortedKeys(cost)) do table.insert(items,id.." "..cost[id]) end
 return table.concat(items,"  •  ")
end
local function input(parent,hint)
 local t=Instance.new("TextBox")
 t.Size=UDim2.new(1,-4,0,38);t.BackgroundColor3=Color3.fromRGB(42,55,63)
 t.TextColor3=Color3.fromRGB(235,246,243);t.PlaceholderColor3=Color3.fromRGB(165,177,181)
 t.PlaceholderText=hint;t.Text="";t.Font=Enum.Font.Gotham;t.TextSize=14
 t.ClearTextOnFocus=false;t.Parent=parent
 local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=t
 return t
end
function Pages.render(parent,tab,p,trade,send,label,button,rankings)
 local function heading(text) local t=label(parent,text,20,Color3.fromRGB(139,225,187),35);t.Font=Enum.Font.GothamBold end
 local function line(text) label(parent,text,14,Color3.fromRGB(198,214,211),35) end
 local function action(text,code,data) button(parent,text,function() send(code,data or {}) end) end
 local function card(name,detail)
  local panel=Instance.new("Frame")
  panel.Name="Card_"..name
  panel.Size=UDim2.new(1,-8,0,0)
  panel.AutomaticSize=Enum.AutomaticSize.Y
  panel.BackgroundColor3=Color3.fromRGB(38,55,62)
  panel.BorderSizePixel=0
  panel.Parent=parent
  local round=Instance.new("UICorner");round.CornerRadius=UDim.new(0,11);round.Parent=panel
  local pad=Instance.new("UIPadding")
  pad.PaddingLeft=UDim.new(0,12);pad.PaddingRight=UDim.new(0,12)
  pad.PaddingTop=UDim.new(0,12);pad.PaddingBottom=UDim.new(0,12);pad.Parent=panel
  local layout=Instance.new("UIListLayout")
  layout.Padding=UDim.new(0,6);layout.Parent=panel
  local title=label(panel,name,17,Color3.fromRGB(243,240,218),27)
  title.Font=Enum.Font.GothamBold
  if detail then label(panel,detail,13,Color3.fromRGB(183,204,201),35) end
  return panel
 end
 local function cardLine(where,what)
  label(where,what,14,Color3.fromRGB(211,228,221),26)
 end
 local function cardAction(where,what,code,data)
  button(where,what,function() send(code,data or {}) end)
 end
 local function progress(where,value,maxValue)
  local bar=Instance.new("Frame")
  bar.Size=UDim2.new(1,-10,0,8)
  bar.BackgroundColor3=Color3.fromRGB(68,82,88)
  bar.BorderSizePixel=0;bar.Parent=where
  local arc=Instance.new("UICorner");arc.CornerRadius=UDim.new(1,0);arc.Parent=bar
  local fill=Instance.new("Frame");fill.Size=UDim2.fromScale(math.clamp(value/math.max(1,maxValue),0,1),1)
  fill.BackgroundColor3=Color3.fromRGB(111,212,177);fill.BorderSizePixel=0;fill.Parent=bar
  local rounded=Instance.new("UICorner");rounded.CornerRadius=UDim.new(1,0);rounded.Parent=fill
 end
 heading(tab)
 if tab=="Ranch" then
  local first=card("WELCOME TO VERDANT","Explore the village, gather supplies and raise your first Gorp.")
  cardLine(first,"Ranch  "..p.BaseLevel.." / 8     |     Creatures  "..#p.Pets.." / "..math.min(40,3+(p.BaseLevel-1)*2))
  progress(first,p.BaseLevel,8)
  cardAction(first,"EXPAND MY RANCH  •  "..tostring(p.BaseLevel*200).." coins","Expand")
  local mission=card("YOUR NEXT MOVE","Your first adventure takes just a few minutes.")
  local gatherCount=p.Quests and (p.Quests.Gatherer or 0) or 0
  local fed=p.Quests and (p.Quests.Provider or 0) or 0
  cardLine(mission,"01   Collect resources     "..math.min(15,gatherCount).."/15")
  progress(mission,gatherCount,15)
  cardLine(mission,"02   Feed your companion     "..math.min(3,fed).."/3")
  progress(mission,fed,3)
  cardLine(mission,"03   Craft items and hire a helper")
  cardAction(mission,"COLLECT WORKER DELIVERIES","Collect")
  local help=card("PLANET GUIDE","Walk toward glowing objects and press E to harvest. Hunt wild Gorps for meat.")
  cardLine(help,"G  •  Show or hide game menu")
  cardLine(help,"E  •  Interact with resources and shops")
  cardLine(help,"First reward: +70 coins for harvesting 15 resources")
 elseif tab=="Eggs" then
  local top=card("THE HATCHERY","Discover new Gorps. Every hatch costs earned coins, and odds are shown below.")
  cardLine(top,"Ranch space: "..#p.Pets.." / "..math.min(40,3+(p.BaseLevel-1)*2))
  for _,eggId in ipairs(C.EggOrder) do
   local egg=C.Eggs[eggId]
   local cardEgg=card(egg.title,"Cost: "..egg.price.." coins")
   for _,entry in ipairs(egg.pool) do
    cardLine(cardEgg,entry.species.."  •  "..entry.weight.."%")
   end
   cardAction(cardEgg,"HATCH "..string.upper(egg.title).."  |  "..egg.price.." COINS","HatchEgg",{id=eggId})
  end
  cardLine(top,"Hatch creatures, select one as companion, then use its abilities to gather faster.")
 elseif tab=="Creatures" then
  local active=p.ActiveId
  for _,pet in ipairs(p.Pets) do
   local def=C.Species[pet.species]
   local selected=active==pet.id and "  •  ACTIVE" or ""
   local panel=card(pet.species.."  /  "..pet.rarity..selected,
    def.role.."  •  Level "..pet.level.." / 25  •  Evolution "..pet.evolved.." / 2")
   cardLine(panel,"Health "..def.hp.."    Attack "..def.attack.."    Speed "..def.speed)
   cardLine(panel,"Growth to next level")
   progress(panel,pet.xp,pet.level*45)
   if active~=pet.id then cardAction(panel,"SELECT AS COMPANION","SelectPet",{id=pet.id}) end
   cardAction(panel,"FEED  •  1 meat + 1 berry","Feed",{id=pet.id})
   cardAction(panel,"EVOLVE  •  Requires rare minerals","Evolve",{id=pet.id})
  end
  local eggs=card("EGG LABORATORY","Craft an incubator, infuse minerals and discover new species.")
  cardLine(eggs,"Infusion "..(p.EggInfusion or 0).." / 3")
  progress(eggs,p.EggInfusion or 0,3)
  cardAction(eggs,"INFUSE  •  3 iron + 2 crystals","InfuseEgg")
  cardAction(eggs,"HATCH  •  Incubator + crystal","Hatch")
 elseif tab=="Backpack" then
  line("Sell gathered materials for coins; resources can also be used to craft items.")
  for _,id in ipairs(sortedKeys(C.Resources)) do
   line(id.."  x"..(p.Inventory[id] or 0).."  •  "..C.Resources[id].." coins each")
   action("Sell 5 "..id,"Sell",{id=id,amount=5})
  end
  for _,id in ipairs(sortedKeys(p.Items)) do line(id.." x"..(p.Items[id] or 0)) end
 elseif tab=="Crafting" then
  line("New recipes unlock as your crafting level increases.")
  for _,id in ipairs(sortedKeys(C.Recipes)) do
   local recipe=C.Recipes[id]
   line(id.."  [Craft Lv."..recipe.level.."]")
   line("Requires "..costText(recipe.cost))
   action("Craft "..id,"Craft",{id=id})
  end
 elseif tab=="Shop" then
  for _,id in ipairs(sortedKeys(C.Shop)) do
   local item=C.Shop[id]
   local entry=card(id,item.price.." coins  •  "..costText(item.grant))
   cardAction(entry,"PURCHASE  •  "..item.price.." coins","Buy",{id=id})
  end
 elseif tab=="Workers" then
  local summary=card("RANCH CREW","Hire workers to harvest automatically. Wages are charged only for completed production.")
  cardLine(summary,"One production cycle = 60 seconds")
  cardAction(summary,"COLLECT DELIVERIES","Collect")
  for _,id in ipairs(sortedKeys(C.Workers)) do
   local worker=C.Workers[id]
   local owned=p.Workers[id] and p.Workers[id].count or 0
   local staff=card(id.."  •  "..owned.."/5 employed",
    "Wage "..worker.wage.." coins / worker / minute")
   cardLine(staff,"Production: "..costText(worker.grant))
   cardAction(staff,"HIRE  •  "..worker.price.." coins","Hire",{id=id})
  end
 elseif tab=="Quests" then
  local missions={
   Gatherer="Gather materials",Provider="Care for your companion",Maker="Craft useful equipment",
   Employer="Build a ranch crew",Explorer="Hunt wild creatures"
  }
  for _,id in ipairs(sortedKeys(C.Quests)) do
   local q=C.Quests[id]
   local value=p.Quests[id] or 0
   local entry=card(missions[id],"REWARD  +"..q.reward.." coins")
   cardLine(entry,math.min(value,q.goal).." / "..q.goal)
   progress(entry,value,q.goal)
   if p.Claimed[id] then cardLine(entry,"COMPLETE  ✓")
   else cardAction(entry,"CLAIM REWARD","Claim",{id=id}) end
  end
 elseif tab=="Trade" then
  line("Player trading is a mutual exchange. Both players must offer and confirm.")
  if trade.partner then
   line("Trading with "..trade.partner)
   local function fmt(offer)
    if not offer then return "Nothing offered" end
    return offer.kind=="Material" and (offer.amount.." "..offer.id) or ("Pet #"..offer.id)
   end
   line("You: "..fmt(trade.mine).."  •  "..(trade.acceptedMine and "Ready" or "Review"))
   line("Them: "..fmt(trade.theirs).."  •  "..(trade.acceptedTheirs and "Ready" or "Review"))
   for _,id in ipairs(sortedKeys(C.Resources)) do
    action("Offer 5 "..id,"OfferMaterial",{resource=id,amount=5})
   end
   for _,pet in ipairs(p.Pets) do
    if pet.id~=p.ActiveId then action("Offer pet: "..pet.species.." #"..pet.id,"OfferPet",{id=pet.id}) end
   end
   action("Accept proposed exchange","Accept")
   action("Cancel trade","Cancel")
  else
   local target=input(parent,"Other player's username")
   button(parent,"Invite player",function() send("Invite",{target=target.Text}) end)
   if trade.pendingFrom then
    line("Invitation from "..trade.pendingFrom)
    action("Join trade","Join")
   end
  end
 elseif tab=="Rankings" then
  line("Global rankings are updated periodically. PvP wins start once ranked combat launches.")
  for _,stat in ipairs({"Coins","Wins","Minutes"}) do
   heading(({Coins="Richest players",Wins="Most PvP wins",Minutes="Most time played"})[stat])
   local entries=rankings and rankings[stat] or {}
   if #entries==0 then line("No ranked entries available yet") end
   for _,entry in ipairs(entries) do
    line("#"..entry.rank.."  "..entry.name.."  •  "..entry.score)
   end
  end
  action("Refresh leaderboard","Rankings")
 elseif tab=="Events" then
  line("Daily wheel: one free spin every 24 hours. Win coins, materials, or a random creature.")
  local left=86400-(os.time()-p.LastWheel)
  line(left>0 and ("Next spin in "..math.ceil(left/3600).." hours") or "Spin ready!")
  action("Spin free daily wheel","Wheel")
  line("Weekend UFO trader  •  Saturday / Sunday UTC")
  line("Trade 3 crystals + 5 iron for a rare creature")
  action("Exchange with UFO","UFO")
  line("Trade up: combine three non-active creatures of one rarity.")
  for _,rarity in ipairs(C.Rarities) do
   if rarity~="Legendary" then action("Trade up 3 "..rarity.." pets","TradeUp",{rarity=rarity}) end
  end
 end
end
return Pages
