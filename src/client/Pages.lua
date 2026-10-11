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
function Pages.render(parent,tab,p,trade,send,label,button)
 local function heading(text) local t=label(parent,text,20,Color3.fromRGB(139,225,187),35);t.Font=Enum.Font.GothamBold end
 local function line(text) label(parent,text,14,Color3.fromRGB(198,214,211),35) end
 local function action(text,code,data) button(parent,text,function() send(code,data or {}) end) end
 heading(tab)
 if tab=="Ranch" then
  line("Welcome to Planet Verdant. Harvest with E near trees, crystals and wild creatures.")
  line("Raise creatures to help your ranch thrive. Expand your fence to hold more pets.")
  line("Fence level "..p.BaseLevel.."  •  Capacity "..math.min(40,3+(p.BaseLevel-1)*2))
  action("Expand ranch  •  "..tostring(p.BaseLevel*200).." coins + materials","Expand")
  action("Collect worker deliveries","Collect")
  line("Craft level "..p.CraftLevel.."  •  XP "..p.CraftXP)
  line("Time played: "..math.floor(p.Seconds/60).." minutes")
 elseif tab=="Creatures" then
  for _,pet in ipairs(p.Pets) do
   local def=C.Species[pet.species]
   line(pet.species.."  ["..pet.rarity.."]   Lv."..pet.level.."  "..def.role.."  Evolve "..pet.evolved.."/2")
   line("HP "..def.hp.."  •  ATK "..def.attack.."  •  SPD "..def.speed.."  •  XP "..pet.xp)
   if p.ActiveId~=pet.id then action("Set "..pet.species.." as companion","SelectPet",{id=pet.id}) end
   action("Feed "..pet.species.." (meat + berry)","Feed",{id=pet.id})
   action("Evolve "..pet.species,"Evolve",{id=pet.id})
  end
  action("Hatch a creature • Incubator + crystal","Hatch")
  line("Evolve at creature levels 5 and 12 using iron and crystals.")
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
  line("The workshop sells supplies and decorative items for earned coins.")
  for _,id in ipairs(sortedKeys(C.Shop)) do
   local item=C.Shop[id]
   line(id.."  •  "..item.price.." coins")
   line("Contains "..costText(item.grant))
   action("Buy "..id,"Buy",{id=id})
  end
 elseif tab=="Workers" then
  line("Workers produce resources once per minute, charging wages per delivery.")
  line("While away, paid production is capped at 60 cycles. Unpaid workers stop.")
  for _,id in ipairs(sortedKeys(C.Workers)) do
   local worker=C.Workers[id]
   local owned=p.Workers[id] and p.Workers[id].count or 0
   line(id.."  •  Employed "..owned.."/5  •  Hire "..worker.price.." coins")
   line("Wage "..worker.wage.." coins per minute per worker  •  "..costText(worker.grant))
   action("Hire "..id,"Hire",{id=id})
  end
  action("Collect worker production","Collect")
 elseif tab=="Quests" then
  for _,id in ipairs(sortedKeys(C.Quests)) do
   local q=C.Quests[id];local progress=p.Quests[id] or 0
   local desc=({Gatherer="Gather resources",Provider="Feed creatures",Maker="Craft items",
    Employer="Hire helpers",Explorer="Hunt wild creatures"})[id]
   line(desc.."  •  "..math.min(progress,q.goal).."/"..q.goal)
   if p.Claimed[id] then line("Reward collected")
   else action("Claim "..q.reward.." coins: "..id,"Claim",{id=id}) end
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
 elseif tab=="Events" then
  line("Daily wheel: one free spin every 24 hours.")
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
