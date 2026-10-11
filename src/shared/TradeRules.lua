-- Safe same-server trade settlement.
-- Both offers are validated and applied to detached copies BEFORE touching live profiles.
-- This prevents pet loss when two full ranches exchange pets.
-- WARNING: two different DataStore keys still require a durable escrow protocol for
-- crash-safe production trading; do not consider multi-player persistence atomic.
local Config=require(script.Parent.Config)
local Rules=require(script.Parent.Rules)
local TradeRules={}

local function whole(n,minimum,maximum)
 return type(n)=="number" and n==n and n%1==0 and n>=minimum and n<=maximum
end

local function verify(profile,offer)
 if type(profile)~="table" or type(profile.Pets)~="table"
  or type(profile.Inventory)~="table" or type(offer)~="table" then
  return false,"Invalid trade data"
 end
 if offer.kind=="Material" then
  if type(offer.id)~="string" or not Config.Resources[offer.id]
   or not whole(offer.amount,1,1000) then return false,"Invalid material offer" end
  if not Rules.has(profile,{[offer.id]=offer.amount}) then
   return false,"Offer materials are no longer available"
  end
  return true
 elseif offer.kind=="Pet" then
  if not whole(offer.id,1,10000000) then return false,"Invalid creature ID" end
  local pet=Rules.pet(profile,offer.id)
  if not pet or pet.id==profile.ActiveId or #profile.Pets<2 then
   return false,"Cannot trade an active or missing creature"
  end
  if not Config.Species[pet.species] then return false,"Unrecognized creature" end
  return true
 end
 return false,"Invalid offer type"
end

local function pullPet(pets,id)
 for index,pet in ipairs(pets) do
  if pet.id==id then return table.remove(pets,index) end
 end
 return nil
end

local function insertPet(pets,pet,nextId)
 if not pet then return nextId end
 if not whole(nextId,1,10000000) then return nil end
 for _,existing in ipairs(pets) do
  if existing.id==nextId then return nil end
 end
 local received=Rules.copy(pet)
 received.id=nextId
 table.insert(pets,received)
 return nextId+1
end

function TradeRules.exchange(p1,p2,offer1,offer2)
 if p1==p2 then return false,"Cannot trade with yourself" end
 local ok,reason=verify(p1,offer1)
 if not ok then return false,reason end
 ok,reason=verify(p2,offer2)
 if not ok then return false,reason end

 local pets1=Rules.copy(p1.Pets)
 local pets2=Rules.copy(p2.Pets)
 local inventory1=Rules.copy(p1.Inventory)
 local inventory2=Rules.copy(p2.Inventory)
 local incoming1,incoming2=nil,nil

 if offer1.kind=="Pet" then incoming2=pullPet(pets1,offer1.id) end
 if offer2.kind=="Pet" then incoming1=pullPet(pets2,offer2.id) end
 if offer1.kind=="Pet" and not incoming2 then return false,"Creature offer no longer exists" end
 if offer2.kind=="Pet" and not incoming1 then return false,"Creature offer no longer exists" end

 if #pets1+(incoming1 and 1 or 0)>Rules.capacity(p1)
  or #pets2+(incoming2 and 1 or 0)>Rules.capacity(p2) then
  return false,"Receiver needs more ranch capacity"
 end

 -- Resolve both material transfers on copies. Check overflow to avoid silently
 -- destroying currency-equivalent materials at the one-million inventory cap.
 local totals={}
 for resource in pairs(Config.Resources) do
  local change1,change2=0,0
  if offer1.kind=="Material" and offer1.id==resource then
   change1-=offer1.amount
   change2+=offer1.amount
  end
  if offer2.kind=="Material" and offer2.id==resource then
   change1+=offer2.amount
   change2-=offer2.amount
  end
  local new1=(inventory1[resource] or 0)+change1
  local new2=(inventory2[resource] or 0)+change2
  if not whole(new1,0,1000000) or not whole(new2,0,1000000) then
   return false,"Inventory capacity or balance changed"
  end
  totals[resource]={new1,new2}
 end

 local next1=p1.NextId
 local next2=p2.NextId
 if incoming1 then
  next1=insertPet(pets1,incoming1,next1)
  if not next1 then return false,"Recipient creature ID invalid" end
 end
 if incoming2 then
  next2=insertPet(pets2,incoming2,next2)
  if not next2 then return false,"Recipient creature ID invalid" end
 end

 -- Commit point: no yields, errors, or partial deductions after this stage.
 for resource,values in pairs(totals) do
  inventory1[resource]=values[1]
  inventory2[resource]=values[2]
 end
 p1.Inventory=inventory1
 p2.Inventory=inventory2
 p1.Pets=pets1
 p2.Pets=pets2
 p1.NextId=next1
 p2.NextId=next2
 return true,"Trade completed"
end

return TradeRules
