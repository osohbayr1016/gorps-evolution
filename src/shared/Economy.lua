local C=require(script.Parent.Config)
local R=require(script.Parent.Rules)
local E={}
function E.craft(p,id)
 local recipe=C.Recipes[id]
 if not recipe then return false,"Unknown recipe" end
 if p.CraftLevel<recipe.level then return false,"Crafting level too low" end
 if not R.canAdd(p,recipe.grant) then return false,"Inventory full: cannot craft without losing items" end
 if not R.spend(p,recipe.cost) then return false,"Missing materials" end
 R.add(p,recipe.grant)
 if p.CraftLevel<20 then
  p.CraftXP+=25
  while p.CraftLevel<20 and p.CraftXP>=p.CraftLevel*50 do
   p.CraftXP-=p.CraftLevel*50;p.CraftLevel+=1
  end
  if p.CraftLevel>=20 then p.CraftXP=0 end
 end
 R.quest(p,"Maker",1)
 return true,"Crafted "..id
end
function E.buy(p,id)
 local item=C.Shop[id]
 if not item then return false,"Unknown item" end
 if p.Coins<item.price then return false,"Not enough coins" end
 if not R.canAdd(p,item.grant) then return false,"Inventory full: purchase would lose items" end
 p.Coins-=item.price;R.add(p,item.grant)
 return true,"Purchased "..id
end
-- One authoritative sale routine for small manual sales and bounded bulk sales.
-- A failed wallet or inventory preflight never removes goods.
local function sellAmount(p,id,count)
 if not R.canCreditCoins(p,count*C.Resources[id]) then
  return false,"Coin wallet full: spend coins before selling"
 end
 if not R.spend(p,{[id]=count}) then return false,"Not enough materials" end
 R.creditCoins(p,count*C.Resources[id])
 return true,"Sold "..count.." "..id
end
function E.sell(p,id,count)
 if not C.Resources[id] then return false,"Unknown material" end
 if type(count)~="number" or count%1~=0 or count<1 or count>100 then return false,"Invalid quantity" end
 return sellAmount(p,id,count)
end
function E.sellMax(p,id,expectedAmount)
 local price=C.Resources[id]
 if not price then return false,"Unknown material" end
 local owned=p.Inventory[id] or 0
 if type(owned)~="number" or owned%1~=0 or owned<1 or owned>1000000 then
  return false,"No materials to sell"
 end
 -- Respect the exact persisted wallet ceiling; sell only the subset that fits.
 local walletRoom=math.max(0,R.MAX_COINS-p.Coins)
 local count=math.min(owned,math.floor(walletRoom/price))
 if count<1 then return false,"Coin wallet full: spend coins before selling" end
 -- The client confirmation must match the exact currently sellable amount.
 -- Never sell more than was reviewed before a concurrent wallet/inventory
 -- change; old internal callers may omit the optional expectedAmount.
 if expectedAmount~=nil and expectedAmount~=count then
  return false,"Bulk sale preview changed: review the updated amount"
 end
 return sellAmount(p,id,count)
end
local function cohorts(w,now)
 if type(w.cohorts)~="table" then
  w.cohorts={}
  if w.count>0 then table.insert(w.cohorts,{count=w.count,last=w.last or now}) end
 end
 return w.cohorts
end
local function syncLast(w,now)
 local earliest
 for _,cohort in ipairs(w.cohorts) do earliest=math.min(earliest or cohort.last,cohort.last) end
 w.last=earliest or now
end
local function workerIds()
 local ids={}
 for id in pairs(C.Workers) do table.insert(ids,id) end
 table.sort(ids)
 return ids
end
local function readCohorts(w,now)
 if type(w.cohorts)=="table" then return w.cohorts end
 if w.count>0 then return {{count=w.count,last=w.last or now}} end
 return {}
end
-- A paid delivery must fit in the destination inventory in full.
local function storageSteps(inventory,worker,count)
 local capacity=60
 for id,amount in pairs(worker.grant) do
  local available=1000000-(inventory[id] or 0)
  capacity=math.min(capacity,math.max(0,math.floor(available/(amount*count))))
 end
 return capacity
end
function E.hire(p,id,now)
 local worker=C.Workers[id]
 if not worker then return false,"Unknown worker" end
 local old=p.Workers[id] or {count=0,last=now,cohorts={}}
 if old.count>=5 then return false,"Maximum workers hired" end
 if p.Coins<worker.price then return false,"Not enough coins" end
 local groups=cohorts(old,now)
 local latest=groups[#groups]
 if latest and latest.last==now then latest.count+=1
 else table.insert(groups,{count=1,last=now}) end
 p.Coins-=worker.price;old.count+=1;syncLast(old,now);p.Workers[id]=old
 R.quest(p,"Employer",1);return true,"Hired "..id
end
function E.tick(p,now)
 local completed=0
 for _,id in ipairs(workerIds()) do
  local def=C.Workers[id]
  local w=p.Workers[id]
  if w and w.count>0 then
   for _,cohort in ipairs(cohorts(w,now)) do
    local elapsed=math.max(0,now-cohort.last)
    local steps=math.min(60,math.floor(elapsed/60))
    if steps>0 then
     local wages=math.floor(p.Coins/(def.wage*cohort.count))
     local capacity=storageSteps(p.Inventory,def,cohort.count)
     local payable=math.min(steps,wages,capacity)
     if payable>0 then
      local batches=payable*cohort.count
      p.Coins-=def.wage*batches
      local goods={}
      for material,count in pairs(def.grant) do goods[material]=count*batches end
      R.add(p,goods);completed+=batches
      if id=="Caretaker" and #p.Pets>0 then
       for i=1,math.min(batches,120) do
        local pet=p.Pets[((i-1)%#p.Pets)+1]
        local fed=R.feed(p,pet.id)
        if not fed then break end
       end
      end
     end
     -- Inventory congestion is not permission to charge wages for lost goods.
     -- Hold storage-blocked accrued minutes up to the existing 60-minute cap.
     -- Unfunded wage minutes keep their existing no-debt expiration policy.
     if capacity<math.min(steps,wages) then
      cohort.last=math.max(cohort.last+payable*60,now-3600-(elapsed%60))
     elseif payable>0 then cohort.last=now-(elapsed%60)
     else cohort.last=now end
    end
   end
   syncLast(w,now)
  end
 end
 return completed
end
function E.workerStatus(p,now)
 local result={state="empty",due=0,payable=0,nextIn=nil,nextAt=nil,shortfall=0,
  storageBlocked=false,byId={}}
 local remainingCoins=p.Coins
 -- Simulate actual sorted payroll grants and caretaker feed consumption without
 -- altering the live profile. Status and collection must agree at capacity.
 local inventory=R.copy(p.Inventory or {})
 local hasWorkers=false
 local minimumShortfall
 for _,id in ipairs(workerIds()) do
  local def=C.Workers[id]
  local w=p.Workers[id]
  local count=w and w.count or 0
  local item={state="empty",count=count,due=0,payable=0,nextIn=nil,shortfall=0,
   storageBlocked=false}
  if w and count>0 then
   hasWorkers=true
   local itemShortfall
   for _,cohort in ipairs(readCohorts(w,now)) do
    local elapsed=math.max(0,now-cohort.last)
    local steps=math.min(60,math.floor(elapsed/60))
    if steps>0 then
     local due=steps*cohort.count
     local wagePerStep=def.wage*cohort.count
     local wageSteps=math.min(steps,math.floor(remainingCoins/wagePerStep))
     local capacity=storageSteps(inventory,def,cohort.count)
     local payableSteps=math.min(wageSteps,capacity)
     local payable=payableSteps*cohort.count
     item.due+=due
     item.payable+=payable
     remainingCoins-=def.wage*payable
     if capacity<wageSteps then
      item.storageBlocked=true
      result.storageBlocked=true
     end
     if wageSteps<steps then
      local shortfall=math.max(0,wagePerStep-remainingCoins)
      itemShortfall=math.min(itemShortfall or shortfall,shortfall)
      minimumShortfall=math.min(minimumShortfall or shortfall,shortfall)
     end
     for material,amount in pairs(def.grant) do
      inventory[material]=(inventory[material] or 0)+amount*payable
     end
     if id=="Caretaker" and type(p.Pets)=="table" and #p.Pets>0 and payable>0 then
      local fed=math.min(payable,120,inventory.Meat or 0,inventory.Berries or 0)
      inventory.Meat-=fed
      inventory.Berries-=fed
     end
    else
     local nextIn=math.max(1,60-elapsed)
     item.nextIn=math.min(item.nextIn or nextIn,nextIn)
     result.nextIn=math.min(result.nextIn or nextIn,nextIn)
    end
   end
   item.shortfall=itemShortfall or 0
   if item.nextIn then item.nextAt=now+item.nextIn end
   if item.payable>0 then item.state="ready"
   elseif item.due>0 then item.state="blocked"
   else item.state="working" end
   result.due+=item.due
   result.payable+=item.payable
  end
  result.byId[id]=item
 end
 result.shortfall=minimumShortfall or 0
 if result.nextIn then result.nextAt=now+result.nextIn end
 if result.payable>0 then result.state="ready"
 elseif result.due>0 then result.state="blocked"
 elseif hasWorkers then result.state="working" end
 return result
end
function E.collect(p,now)
 local before=E.workerStatus(p,now)
 -- Collection is an explicit claim. A stale client may believe the crew is
 -- ready even after another action spends the last wage coins, so only the
 -- authoritative ready state may advance cohort clocks.
 if before.state~="ready" then return 0,before end
 return E.tick(p,now),before
end
function E.claim(p,id)
 local q=C.Quests[id]
 if not q then return false,"Unknown mission" end
 if p.Claimed[id] then return false,"Already claimed" end
 if (p.Quests[id] or 0)<q.goal then return false,"Mission incomplete" end
 if not R.canCreditCoins(p,q.reward) then
  return false,"Coin wallet full: spend coins before claiming"
 end
 p.Claimed[id]=true;R.creditCoins(p,q.reward)
 return true,"Quest reward: "..q.reward.." coins"
end
-- Claim ready missions atomically. Never mark any as claimed when a wallet
-- cannot fit the complete combined reward; players can still claim one by one.
function E.claimAll(p)
 local ready={}
 local total=0
 for id,q in pairs(C.Quests) do
  if p.Claimed[id]~=true and (p.Quests[id] or 0)>=q.goal then
   table.insert(ready,id)
   total+=q.reward
  end
 end
 if #ready==0 then return false,"No completed unclaimed missions" end
 if not R.canCreditCoins(p,total) then
  return false,"Coin wallet full: spend coins before claiming all rewards"
 end
 for _,id in ipairs(ready) do p.Claimed[id]=true end
 R.creditCoins(p,total)
 return true,"Claimed "..#ready.." missions for "..total.." coins"
end
-- Freeze an outcome at draw time so a full inventory cannot be used to
-- reject unwanted rolls repeatedly. Unclaimed prizes survive profile reloads.
local function wheelDescription(reserved)
 if reserved.roll==1 then return "100 coins" end
 if reserved.roll==2 then return "6 meat and 8 berries" end
 if reserved.roll==3 then return "2 crystals" end
 if reserved.fallback then return "250 coins" end
 return reserved.species.." creature"
end
local function claimReservedWheel(p,reserved)
 if reserved.roll==1 then
  if not R.canCreditCoins(p,100) then
   return false,"Coin wallet full: spend coins to claim 100 coins"
  end
  R.creditCoins(p,100)
 elseif reserved.roll==2 then
  if not R.canAdd(p,{Meat=6,Berries=8}) then
   return false,"Backpack full: free space to claim your food bundle"
  end
  R.add(p,{Meat=6,Berries=8})
 elseif reserved.roll==3 then
  if not R.canAdd(p,{Crystal=2}) then
   return false,"Backpack full: free space to claim your crystals"
  end
  R.add(p,{Crystal=2})
 elseif reserved.fallback then
  if not R.canCreditCoins(p,250) then
   return false,"Coin wallet full: spend coins to claim 250 coins"
  end
  R.creditCoins(p,250)
 else
  if #p.Pets>=R.capacity(p) then
   return false,"Ranch full: expand before claiming your creature"
  end
  local ok,message=R.addPet(p,reserved.species)
  if not ok then return false,message end
 end
 p.WheelPending=nil
 return true,"Daily reward claimed: "..wheelDescription(reserved)
end
function E.wheel(p,now,roll)
 if p.WheelPending then
  -- Ignore the caller's new random roll. Only the original pending prize
  -- may be claimed, even after days offline or a profile migration.
  return claimReservedWheel(p,p.WheelPending)
 end
 if now-p.LastWheel<86400 then return false,"Wheel is on cooldown" end
 if type(roll)~="number" or roll<1 or roll>4 or roll%1~=0 then return false,"Invalid roll" end
 local reserved={roll=roll}
 if roll==4 then
  if #p.Pets<R.capacity(p) and R.canCreatePet(p) then
   reserved.species=C.SpeciesOrder[math.random(1,#C.SpeciesOrder)]
  else
   reserved.fallback=true
  end
 end
 p.LastWheel=now
 p.WheelPending=reserved
 local claimed,message=claimReservedWheel(p,reserved)
 if claimed then return true,message end
 -- This is a state change, not a failed roll: the reserved outcome and
 -- spin timestamp must be persisted by the normal successful action path.
 return true,"Daily reward reserved ("..wheelDescription(reserved).."): "..message
end
function E.tradeUp(p,rarity,species)
 local tier=table.find(C.Rarities,rarity)
 if not tier or tier>=#C.Rarities then return false,"Invalid rarity" end
 if not C.Species[species] then return false,"Invalid creature" end
 if not R.canCreatePet(p) then return false,"Creature ID limit reached; contact support" end
 local remove={}
 for i,pet in ipairs(p.Pets) do
  if pet.rarity==rarity and pet.id~=p.ActiveId and pet.favorite~=true then
   table.insert(remove,i)
   if #remove>=3 then break end
  end
 end
 if #remove<3 then return false,"Need 3 inactive creatures of that rarity" end
 for i=#remove,1,-1 do table.remove(p.Pets,remove[i]) end
 return R.addPet(p,species,C.Rarities[tier+1])
end
return E

