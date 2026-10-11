local C=require(script.Parent.Config)
local R={}
function R.copy(value)
 if type(value)~="table" then return value end
 local nextValue={}
 for k,v in pairs(value) do nextValue[k]=R.copy(v) end
 return nextValue
end
local function valid(n,max) return type(n)=="number" and n==n and n%1==0 and n>=0 and n<=(max or 1000000) end
function R.new(now)
 return {Coins=250,Level=1,XP=0,CraftLevel=1,CraftXP=0,BaseLevel=1,Wins=0,Seconds=0,
  Inventory={Wood=12,Stone=8,Iron=0,Meat=5,Berries=8,Crystal=0,Fiber=3},Items={},
  Pets={{id=1,species="Gorp",rarity="Common",level=1,xp=0,evolved=0}},NextId=2,ActiveId=1,
  Workers={},Quests={},Claimed={},LastWheel=0,LastSeen=now}
end
function R.pet(p,id)
 if not valid(id,10000000) then return nil end
 for i,pet in ipairs(p.Pets) do if pet.id==id then return pet,i end end
end
function R.capacity(p) return math.min(40,3+(p.BaseLevel-1)*2) end
function R.load(saved,now)
 local p=R.new(now)
 if type(saved)~="table" then return p end
 for _,field in ipairs({"Coins","Level","XP","CraftLevel","CraftXP","BaseLevel","Wins","Seconds","NextId","ActiveId","LastWheel","LastSeen"}) do
  if valid(saved[field],4000000000) then p[field]=saved[field] end
 end
 p.BaseLevel=math.clamp(p.BaseLevel,1,8)
 p.Level=math.clamp(p.Level,1,100)
 p.CraftLevel=math.clamp(p.CraftLevel,1,20)
 p.NextId=math.max(2,p.NextId)
 for id in pairs(C.Resources) do
  if type(saved.Inventory)=="table" and valid(saved.Inventory[id]) then p.Inventory[id]=saved.Inventory[id] end
 end
 if type(saved.Items)=="table" then
  for id,value in pairs(saved.Items) do
   if (C.Recipes[id] or id=="DecorationLamp") and valid(value) then p.Items[id]=value end
  end
 end
 if type(saved.Pets)=="table" then
  local pets,seen={},{}
  for _,pet in ipairs(saved.Pets) do
   if #pets>=40 then break end
   if type(pet)=="table" and C.Species[pet.species] and valid(pet.id,10000000) and not seen[pet.id] then
    seen[pet.id]=true
    table.insert(pets,{id=pet.id,species=pet.species,rarity=table.find(C.Rarities,pet.rarity) and pet.rarity or "Common",
     level=valid(pet.level,25) and math.max(pet.level,1) or 1,
     xp=valid(pet.xp) and pet.xp or 0,evolved=valid(pet.evolved,2) and pet.evolved or 0})
   end
  end
  if #pets>0 then p.Pets=pets end
 end
 for _,pet in ipairs(p.Pets) do p.NextId=math.max(p.NextId,pet.id+1) end
 if not R.pet(p,p.ActiveId) then p.ActiveId=p.Pets[1].id end
 if type(saved.Workers)=="table" then
  for id in pairs(C.Workers) do
   local w=saved.Workers[id]
   if type(w)=="table" and valid(w.count,5) then
    p.Workers[id]={count=w.count,last=valid(w.last,now) and w.last or now}
   end
  end
 end
 for _,field in ipairs({"Quests","Claimed"}) do
  if type(saved[field])=="table" then
   for id in pairs(C.Quests) do
    if field=="Quests" and valid(saved[field][id]) then p.Quests[id]=saved[field][id]
    elseif field=="Claimed" then p.Claimed[id]=saved[field][id]==true end
   end
  end
 end
 return p
end
function R.has(p,cost)
 for id,n in pairs(cost) do
  if not valid(n) then return false end
  local container=C.Resources[id] and p.Inventory or p.Items
  if (container[id] or 0)<n then return false end
 end
 return true
end
function R.spend(p,cost)
 if not R.has(p,cost) then return false end
 for id,n in pairs(cost) do
  local container=C.Resources[id] and p.Inventory or p.Items
  container[id]-=n
 end
 return true
end
function R.add(p,goods)
 for id,n in pairs(goods) do
  local container=C.Resources[id] and p.Inventory or p.Items
  container[id]=math.min(1000000,(container[id] or 0)+n)
 end
end
function R.xp(p,n)
 p.XP+=n
 while p.Level<100 and p.XP>=p.Level*50 do
  p.XP-=p.Level*50;p.Level+=1;p.Coins+=15
 end
end
function R.quest(p,id,n) p.Quests[id]=math.min(1000000,(p.Quests[id] or 0)+n) end
function R.addPet(p,species,rarity)
 if not C.Species[species] then return false,"Unknown creature" end
 if #p.Pets>=R.capacity(p) then return false,"Expand your fence for more creatures" end
 local pet={id=p.NextId,species=species,rarity=rarity or C.Species[species].rarity,level=1,xp=0,evolved=0}
 p.NextId+=1;table.insert(p.Pets,pet);return true,"Received "..species
end
function R.feed(p,id)
 local pet=R.pet(p,id)
 if not pet then return false,"Creature missing" end
 if not R.spend(p,{Meat=1,Berries=1}) then return false,"Need meat and berries" end
 if pet.level<25 then
  pet.xp+=35
  while pet.level<25 and pet.xp>=pet.level*45 do pet.xp-=pet.level*45;pet.level+=1 end
 end
 R.quest(p,"Provider",1);R.xp(p,8);return true,"Creature fed"
end
function R.evolve(p,id)
 local pet=R.pet(p,id)
 if not pet then return false,"Creature missing" end
 if pet.evolved>=2 then return false,"Max evolution" end
 local minimum=pet.evolved==0 and 5 or 12
 if pet.level<minimum then return false,"Needs creature level "..minimum end
 local cost=pet.evolved==0 and {Iron=5,Crystal=1} or {Iron=15,Crystal=6}
 if not R.spend(p,cost) then return false,"Not enough iron and crystals" end
 pet.evolved+=1;return true,"Evolution complete"
end
function R.gather(p,id)
 local node=C.Nodes[id]
 if not node then return false,"Unknown node" end
 R.add(p,{[node[1]]=node[2]});p.Coins+=id=="Wild" and 8 or 2;R.xp(p,5)
 R.quest(p,"Gatherer",node[2])
 if id=="Wild" then R.quest(p,"Explorer",1) end
 return true,"Collected "..node[2].." "..node[1]
end
function R.expand(p)
 if p.BaseLevel>=8 then return false,"Maximum base level" end
 local n=p.BaseLevel
 if p.Coins<n*200 or not R.spend(p,{Wood=n*10,Stone=n*7}) then return false,"Need coins, wood and stone" end
 p.Coins-=n*200;p.BaseLevel+=1;return true,"Base expanded"
end
return R
