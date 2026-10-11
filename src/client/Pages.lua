local Config=require(game:GetService("ReplicatedStorage").Shared.Config)
local Rules=require(game:GetService("ReplicatedStorage").Shared.Rules)
local W=require(script.Parent.Widgets)
local C=W.colors
local Pages={}

local function keys(source)
 local ids={}
 for name in pairs(source) do table.insert(ids,name) end
 table.sort(ids)
 return ids
end
local function countCost(cost)
 local parts={}
 for _,id in ipairs(keys(cost)) do
  table.insert(parts,id.." x"..cost[id])
 end
 return table.concat(parts,"   +   ")
end
local function fmt(value)
 return tostring(math.floor(value))
end
local function heading(parent,title,subtitle)
 local t=W.label(parent,title,16,C.gold,29)
 t.Font=Enum.Font.GothamBold
 if subtitle then W.label(parent,subtitle,13,C.muted,34) end
end
local function textRow(parent,text)
 return W.label(parent,text,14,C.light,27)
end
local function descriptor(parent,text)
 return W.label(parent,text,13,C.muted,28)
end
local function action(parent,text,callback,canPress,color)
 return W.button(parent,text,callback,canPress,color)
end
local function eggPanel(parent,eggId,profile,send)
 local egg=Config.Eggs[eggId]
 local owned=#profile.Pets
 local capacity=math.min(40,3+(profile.BaseLevel-1)*2)
 local card=W.card(parent,nil,nil)
 local row=W.row(card,112)
 local view=W.eggPortrait(row,eggId=="Meadow" and Color3.fromRGB(243,198,112)
  or Color3.fromRGB(168,135,237))
 view.Position=UDim2.fromOffset(2,2)
 local title=Instance.new("TextLabel")
 title.Name="EggTitle";title.BackgroundTransparency=1
 title.Position=UDim2.fromOffset(119,7);title.Size=UDim2.new(1,-122,0,29)
 title.Text=egg.title
 title.TextColor3=C.light;title.TextSize=21;title.Font=Enum.Font.GothamBold
 title.TextXAlignment=Enum.TextXAlignment.Left;title.Parent=row
 local cost=Instance.new("TextLabel")
 cost.Position=UDim2.fromOffset(119,43);cost.Size=UDim2.new(1,-124,0,27)
 cost.BackgroundTransparency=1;cost.Text="◆ "..fmt(egg.price).." coins"
 cost.TextColor3=C.gold;cost.Font=Enum.Font.GothamBold;cost.TextSize=18
 cost.TextXAlignment=Enum.TextXAlignment.Left;cost.Parent=row
 local description=Instance.new("TextLabel")
 description.Position=UDim2.fromOffset(119,77)
 description.Size=UDim2.new(1,-125,0,24)
 description.BackgroundTransparency=1
 description.Text=eggId=="Meadow" and "Great for new explorers" or "Stronger creatures await"
 description.TextColor3=C.muted;description.Font=Enum.Font.Gotham
 description.TextSize=12;description.TextXAlignment=Enum.TextXAlignment.Left
 description.Parent=row
 heading(card,"HATCH CHANCES","Each purchase reveals exactly one creature")
 for _,entry in ipairs(egg.pool) do
  local def=Config.Species[entry.species]
  local label=W.label(card,entry.species.."   •   "..def.rarity.."    "..entry.weight.."%",13,
   W.rarityColor(def.rarity),25)
  label.Font=Enum.Font.GothamBold
  local fill=W.progress(card,entry.weight/100)
  fill.BackgroundColor3=W.rarityColor(def.rarity)
 end
 local affordable=profile.Coins>=egg.price
 local hasRoom=owned<capacity
 action(card,not hasRoom and "RANCH FULL  •  EXPAND TO HATCH" or
  not affordable and "NEED "..fmt(egg.price-profile.Coins).." MORE COINS" or
  "HATCH 1 EGG  ·  ◆ "..fmt(egg.price),
  function() send("HatchEgg",{id=eggId}) end,affordable and hasRoom,C.gold)
end
local function pets(parent,p,send)
 heading(parent,"YOUR TEAM",#p.Pets.." / "..math.min(40,3+(p.BaseLevel-1)*2)..
  " creature slots filled. Only your active companion follows you.")
 for _,pet in ipairs(p.Pets) do
  local def=Config.Species[pet.species]
  if def then
   local active=pet.id==p.ActiveId
   local card=W.card(parent,nil,nil)
   local row=W.row(card,112)
   W.petPortrait(row,pet.species,pet.rarity,pet).Position=UDim2.fromOffset(0,3)
   local header=Instance.new("TextLabel")
   header.Name="PetName";header.BackgroundTransparency=1
   header.Position=UDim2.fromOffset(120,5);header.Size=UDim2.new(1,-124,0,33)
   header.Text=pet.species.."  "..(active and "✓" or "")
   header.TextXAlignment=Enum.TextXAlignment.Left;header.Font=Enum.Font.GothamBold
   header.TextSize=21;header.TextColor3=C.light;header.Parent=row
   local rarity=Instance.new("TextLabel")
   rarity.Name="Rarity";rarity.BackgroundTransparency=1
   rarity.Position=UDim2.fromOffset(120,40);rarity.Size=UDim2.new(1,-124,0,27)
   rarity.Text=string.upper(pet.rarity).."  ·  "..def.role
   rarity.TextXAlignment=Enum.TextXAlignment.Left;rarity.Font=Enum.Font.GothamBold
   rarity.TextSize=13;rarity.TextColor3=W.rarityColor(pet.rarity);rarity.Parent=row
   local level=Instance.new("TextLabel")
   level.Name="PetLevel";level.BackgroundTransparency=1
   level.Position=UDim2.fromOffset(120,76);level.Size=UDim2.new(1,-124,0,25)
   level.Text="LEVEL "..pet.level.."  /  25"
   level.TextXAlignment=Enum.TextXAlignment.Left;level.Font=Enum.Font.GothamMedium
   level.TextSize=13;level.TextColor3=C.muted;level.Parent=row
   local baseline=Rules.stats(pet)
   textRow(card,"HP "..baseline.hp.."    ATK "..baseline.attack.."    SPD "..baseline.speed)
   W.progress(card,pet.xp/math.max(1,pet.level*45))
   descriptor(card,"Growth XP  "..pet.xp.." / "..tostring(pet.level*45).."  •  Evolution "..pet.evolved.."/2")
   if not active then
    action(card,"EQUIP AS COMPANION",function() send("SelectPet",{id=pet.id}) end,true,C.gold)
   end
   local hasFood=(p.Inventory.Meat or 0)>0 and (p.Inventory.Berries or 0)>0
   action(card,hasFood and ((active and "FEED & WATCH" or "FEED").."  ·  1 MEAT + 1 BERRY") or "NEED MEAT + BERRIES TO FEED",
    function() send("Feed",{id=pet.id}) end,hasFood,C.mint)
   local target=pet.evolved==0 and 5 or 12
   if pet.evolved<2 then
    action(card,"EVOLVE  ·  LEVEL "..target.."+",
     function() send("Evolve",{id=pet.id}) end,pet.level>=target,C.blue)
   end
  end
 end
end
local function ranch(parent,p,send)
 local cap=math.min(40,3+(p.BaseLevel-1)*2)
 local card=W.card(parent,"YOUR VERDANT RANCH",
  "Raise your creatures, expand your land and unlock more space for new discoveries.")
 textRow(card,"Ranch Level  "..p.BaseLevel.."/8   ·   Gorps  "..#p.Pets.."/"..cap)
 W.progress(card,p.BaseLevel/8)
 local cost={Wood=p.BaseLevel*10,Stone=p.BaseLevel*7}
 local affordable=p.Coins>=p.BaseLevel*200
 for id,n in pairs(cost) do
  if (p.Inventory[id] or 0)<n then affordable=false end
 end
 if p.BaseLevel<8 then
  descriptor(card,"Next upgrade: ◆ "..tostring(p.BaseLevel*200).."  +  "..countCost(cost))
  action(card,affordable and "EXPAND RANCH  →" or "COLLECT MATERIALS TO UPGRADE",
   function() send("Expand",{}) end,affordable,C.gold)
 else
  descriptor(card,"Maximum ranch level reached")
 end
 local path=W.card(parent,"STARTER ROADMAP","A clear path through your first five minutes.")
 local gather=p.Quests.Gatherer or 0
 local feed=p.Quests.Provider or 0
 textRow(path,"01   Gather resources     "..math.min(15,gather).."/15")
 W.progress(path,gather/15)
 textRow(path,"02   Hatch a Meadow Egg  ·  ◆ 100")
 textRow(path,"03   Feed your Gorp       "..math.min(feed,3).."/3")
 W.progress(path,feed/3)
 textRow(path,"04   Upgrade your ranch and hire a worker")
 action(path,"VISIT THE HATCHERY",function() send("__openTab",{id="Eggs"}) end,true,C.gold)
 local help=W.card(parent,"HOW TO PLAY","Explore the planet and approach glowing resources.")
 textRow(help,"E  ·  Gather, hunt or open village stations")
 textRow(help,"1–5  ·  Quick menu shortcuts")
 textRow(help,"G  ·  Open or close your menu")
end
local function backpack(parent,p,send)
 heading(parent,"YOUR MATERIALS","Collect resources around the world and sell extras for coins.")
 for _,id in ipairs(keys(Config.Resources)) do
  local count=p.Inventory[id] or 0
  local card=W.card(parent,nil,"Trade value: ◆ "..Config.Resources[id].." per item")
  local header=W.row(card,46)
  local symbol=W.resourceIcon(header,id,42)
  symbol.Position=UDim2.fromOffset(1,1)
  local itemName=Instance.new("TextLabel")
  itemName.Name="MaterialCount"
  itemName.BackgroundTransparency=1
  itemName.Size=UDim2.new(1,-60,0,37)
  itemName.Position=UDim2.fromOffset(58,3)
  itemName.Text=id.."  ·  x"..fmt(count)
  itemName.TextXAlignment=Enum.TextXAlignment.Left
  itemName.TextColor3=C.light
  itemName.TextSize=17
  itemName.Font=Enum.Font.GothamBold
  itemName.Parent=header
  action(card,count>=5 and "SELL 5 FOR ◆ "..5*Config.Resources[id] or "COLLECT 5 TO SELL",
   function() send("Sell",{id=id,amount=5}) end,count>=5,C.gold)
 end
 heading(parent,"CRAFTED INVENTORY")
 if not next(p.Items) then descriptor(parent,"Your crafted equipment will appear here.") end
 for _,id in ipairs(keys(p.Items)) do textRow(parent,id.."  x"..fmt(p.Items[id])) end
end
local function crafting(parent,p,send)
 heading(parent,"WORKBENCH","Turn harvested materials into useful items.")
 for _,id in ipairs(keys(Config.Recipes)) do
  local recipe=Config.Recipes[id]
  local card=W.card(parent,id,"Craft skill required: Lv."..recipe.level)
  descriptor(card,"Materials:  "..countCost(recipe.cost))
  local ready=p.CraftLevel>=recipe.level
  for material,amount in pairs(recipe.cost) do
   local stock=Config.Resources[material] and p.Inventory or p.Items
   if (stock[material] or 0)<amount then ready=false end
  end
  action(card,ready and "CRAFT "..string.upper(id) or "LOCKED / NEED MATERIALS",
   function() send("Craft",{id=id}) end,ready,C.blue)
 end
end
local function shop(parent,p,send)
 heading(parent,"VILLAGE SHOP","Useful supplies. All items use coins earned in game.")
 for _,id in ipairs(keys(Config.Shop)) do
  local item=Config.Shop[id]
  local card=W.card(parent,id,"◆ "..item.price.." coins")
  descriptor(card,"You receive:  "..countCost(item.grant))
  action(card,p.Coins>=item.price and "BUY NOW" or "NOT ENOUGH COINS",
   function() send("Buy",{id=id}) end,p.Coins>=item.price,C.gold)
 end
end
local function workers(parent,p,send)
 heading(parent,"RANCH CREW","Helpers produce resources each minute. Wages are charged per delivery.")
 action(parent,"COLLECT WORKER DELIVERIES",function() send("Collect",{}) end,true,C.gold)
 for _,id in ipairs(keys(Config.Workers)) do
  local worker=Config.Workers[id]
  local owned=p.Workers[id] and p.Workers[id].count or 0
  local card=W.card(parent,id.."  ·  "..owned.."/5",
   "Wage: ◆ "..worker.wage.." per worker / min")
  descriptor(card,"Production:  "..countCost(worker.grant))
  action(card,p.Coins>=worker.price and "HIRE FOR ◆ "..worker.price or "NEED ◆ "..worker.price,
   function() send("Hire",{id=id}) end,p.Coins>=worker.price and owned<5,C.mint)
 end
end
local function quests(parent,p,send)
 heading(parent,"MISSIONS","Play your way and claim rewards when goals are complete.")
 local labels={Gatherer="Collect materials",Provider="Feed your Gorps",
  Maker="Craft equipment",Employer="Hire a ranch worker",Explorer="Hunt wild creatures"}
 for _,id in ipairs(keys(Config.Quests)) do
  local q=Config.Quests[id]
  local current=math.min(p.Quests[id] or 0,q.goal)
  local card=W.card(parent,labels[id],"REWARD   ◆ "..q.reward.." coins")
  textRow(card,current.." / "..q.goal.." completed")
  W.progress(card,current/q.goal)
  if p.Claimed[id] then
   descriptor(card,"✓  Reward claimed")
  else
   action(card,current>=q.goal and "CLAIM ◆ "..q.reward or "MISSION IN PROGRESS",
    function() send("Claim",{id=id}) end,current>=q.goal,C.gold)
  end
 end
end
local function trade(parent,p,tradeState,send)
 heading(parent,"PLAYER TRADING","Only trade with another player in this server. Both sides must confirm.")
 if tradeState.partner then
  local offer=W.card(parent,"TRADE WITH "..tradeState.partner,"Review both offers before accepting.")
  local function offerText(x)
   if type(x)~="table" then return "Nothing offered" end
   if x.kind=="Material" then return x.amount.." "..x.id end
   return "Creature #"..tostring(x.id)
  end
  textRow(offer,"You: "..offerText(tradeState.mine))
  textRow(offer,"Them: "..offerText(tradeState.theirs))
  textRow(offer,"Your confirmation: "..(tradeState.acceptedMine and "READY" or "WAITING"))
  textRow(offer,"Their confirmation: "..(tradeState.acceptedTheirs and "READY" or "WAITING"))
  action(offer,"ACCEPT TRADE",function() send("Accept",{}) end,true,C.mint)
  action(offer,"CANCEL",function() send("Cancel",{}) end,true,Color3.fromRGB(225,139,136))
  heading(parent,"OFFER MATERIALS")
  for _,id in ipairs(keys(Config.Resources)) do
   if (p.Inventory[id] or 0)>=5 then
    action(parent,"OFFER 5 "..string.upper(id),
     function() send("OfferMaterial",{resource=id,amount=5}) end,true,C.blue)
   end
  end
  for _,pet in ipairs(p.Pets) do
   if pet.id~=p.ActiveId then
    action(parent,"OFFER "..pet.species.." #"..pet.id,
     function() send("OfferPet",{id=pet.id}) end,true,C.blue)
   end
  end
 else
  local card=W.card(parent,"INVITE A PLAYER","Enter the exact Roblox username of a player in your server.")
  local box=Instance.new("TextBox")
  box.Name="PlayerName";box.Size=UDim2.new(1,-2,0,44)
  box.BackgroundColor3=C.deep
  box.TextColor3=C.light;box.PlaceholderColor3=C.muted
  box.PlaceholderText="Roblox username";box.Text=""
  box.Font=Enum.Font.GothamMedium;box.TextSize=15
  box.ClearTextOnFocus=false;box.Parent=card;W.order(card,box)
  W.round(box,10)
  action(card,"SEND TRADE INVITE",function() send("Invite",{target=box.Text}) end,true,C.gold)
  if tradeState.pendingFrom then
   local incoming=W.card(parent,"TRADE INVITATION",
    tradeState.pendingFrom.." wants to trade.")
   action(incoming,"REVIEW TRADE",function() send("Join",{}) end,true,C.mint)
  end
 end
end
local function events(parent,p,send)
 local left=86400-(os.time()-p.LastWheel)
 local wheel=W.card(parent,"DAILY REWARD","One free spin every 24 hours. Includes coins, food or a creature.")
 action(wheel,left<=0 and "SPIN FREE WHEEL" or
  "AVAILABLE IN "..math.ceil(left/3600).." HOURS",
  function() send("Wheel",{}) end,left<=0,C.gold)
 local ufo=W.card(parent,"WEEKEND UFO","Only on Saturdays and Sundays (UTC).")
 descriptor(ufo,"Exchange 3 crystals + 5 iron for a rare Gorp.")
 action(ufo,"VISIT THE UFO TRADER",function() send("UFO",{}) end,true,C.blue)
 local upgrade=W.card(parent,"TRADE UP","Combine three inactive pets from the same rarity.")
 for _,rarity in ipairs(Config.Rarities) do
  if rarity~="Legendary" then
   action(upgrade,"UPGRADE 3 "..string.upper(rarity),
    function() send("TradeUp",{rarity=rarity}) end,true,C.mint)
  end
 end
end
local function renderRankings(parent,ranking,send)
 heading(parent,"GALAXY LEADERS","Rankings update periodically after players join published servers.")
 for _,id in ipairs({"Coins","Wins","Minutes"}) do
  local title=({Coins="Richest explorers",Wins="Most PvP wins",Minutes="Longest adventures"})[id]
  local card=W.card(parent,title,nil)
  local records=ranking and ranking[id] or {}
  if #records==0 then descriptor(card,"No ranked players yet") end
  for _,row in ipairs(records) do
   textRow(card,"#"..row.rank.."  "..row.name.."   •   "..row.score)
  end
 end
 action(parent,"REFRESH LEADERBOARDS",function() send("Rankings",{}) end,true,C.blue)
end
function Pages.render(parent,tab,p,tradeState,send,rankings)
 local function route(actionName,args)
  send(actionName,args)
 end
 if tab=="Eggs" then
  heading(parent,"COLLECT NEW GORPS","Buy eggs with coins earned while exploring. All odds are shown.")
  for _,id in ipairs(Config.EggOrder) do eggPanel(parent,id,p,route) end
 elseif tab=="Creatures" then pets(parent,p,route)
 elseif tab=="Ranch" then ranch(parent,p,route)
 elseif tab=="Backpack" then backpack(parent,p,route)
 elseif tab=="Crafting" then crafting(parent,p,route)
 elseif tab=="Shop" then shop(parent,p,route)
 elseif tab=="Workers" then workers(parent,p,route)
 elseif tab=="Quests" then quests(parent,p,route)
 elseif tab=="Trade" then trade(parent,p,tradeState or {},route)
 elseif tab=="Events" then events(parent,p,route)
 elseif tab=="Rankings" then renderRankings(parent,rankings,route)
 end
end
return Pages

