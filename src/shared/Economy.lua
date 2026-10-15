local C=require(script.Parent.Config)
local R=require(script.Parent.Rules)
local E={}
function E.craft(p,id)
 local recipe=C.Recipes[id]
 if not recipe then return false,"Unknown recipe" end
 if p.CraftLevel<recipe.level then return false,"Crafting level too low" end
 if not R.spend(p,recipe.cost) then return false,"Missing materials" end
 R.add(p,recipe.grant)
 p.CraftXP+=25
 while p.CraftLevel<20 and p.CraftXP>=p.CraftLevel*50 do
  p.CraftXP-=p.CraftLevel*50;p.CraftLevel+=1
 end
 R.quest(p,"Maker",1)
 return true,"Crafted "..id
end
function E.buy(p,id)
 local item=C.Shop[id]
 if not item then return false,"Unknown item" end
 if p.Coins<item.price then return false,"Not enough coins" end
 p.Coins-=item.price;R.add(p,item.grant)
 return true,"Purchased "..id
end
function E.sell(p,id,count)
 if not C.Resources[id] then return false,"Unknown material" end
 if type(count)~="number" or count%1~=0 or count<1 or count>100 then return false,"Invalid quantity" end
 if not R.spend(p,{[id]=count}) then return false,"Not enough materials" end
 p.Coins+=count*C.Resources[id];return true,"Sold "..count.." "..id
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
     local payable=math.min(steps,math.floor(p.Coins/(def.wage*cohort.count)))
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
     -- Paid collections retain this cohort's sub-minute work. Unpaid whole
     -- minutes (including over-cap work) expire without becoming wage debt.
     if payable>0 then cohort.last=now-(elapsed%60)
     else cohort.last=now end
    end
   end
   syncLast(w,now)
  end
 end
 return completed
end
function E.workerStatus(p,now)
 local result={state="empty",due=0,payable=0,nextIn=nil,nextAt=nil,shortfall=0,byId={}}
 local remainingCoins=p.Coins
 local hasWorkers=false
 local minimumShortfall
 for _,id in ipairs(workerIds()) do
  local def=C.Workers[id]
  local w=p.Workers[id]
  local count=w and w.count or 0
  local item={state="empty",count=count,due=0,payable=0,nextIn=nil,shortfall=0}
  if w and count>0 then
   hasWorkers=true
   local itemShortfall
   for _,cohort in ipairs(readCohorts(w,now)) do
    local elapsed=math.max(0,now-cohort.last)
    local steps=math.min(60,math.floor(elapsed/60))
    if steps>0 then
     local due=steps*cohort.count
     local wagePerStep=def.wage*cohort.count
     local payableSteps=math.min(steps,math.floor(remainingCoins/wagePerStep))
     local payable=payableSteps*cohort.count
     item.due+=due
     item.payable+=payable
     remainingCoins-=def.wage*payable
     if payableSteps<steps then
      local shortfall=math.max(0,wagePerStep-remainingCoins)
      itemShortfall=math.min(itemShortfall or shortfall,shortfall)
      minimumShortfall=math.min(minimumShortfall or shortfall,shortfall)
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
function E.claim(p,id)
 local q=C.Quests[id]
 if not q then return false,"Unknown mission" end
 if p.Claimed[id] then return false,"Already claimed" end
 if (p.Quests[id] or 0)<q.goal then return false,"Mission incomplete" end
 p.Claimed[id]=true;p.Coins+=q.reward
 return true,"Quest reward: "..q.reward.." coins"
end
function E.wheel(p,now,roll)
 if now-p.LastWheel<86400 then return false,"Wheel is on cooldown" end
 if type(roll)~="number" or roll<1 or roll>4 or roll%1~=0 then return false,"Invalid roll" end
 p.LastWheel=now
 if roll==1 then p.Coins+=100
 elseif roll==2 then R.add(p,{Meat=6,Berries=8})
 elseif roll==3 then R.add(p,{Crystal=2})
 else
  if #p.Pets<R.capacity(p) then
   local species=C.SpeciesOrder[math.random(1,#C.SpeciesOrder)]
   R.addPet(p,species)
   return true,"Daily wheel pet: "..species
  end
  p.Coins+=250
 end
 return true,({"100 coins!","Food bundle!","2 crystals!","250 coins!"})[roll]
end
function E.tradeUp(p,rarity,species)
 local tier=table.find(C.Rarities,rarity)
 if not tier or tier>=#C.Rarities then return false,"Invalid rarity" end
 if not C.Species[species] then return false,"Invalid creature" end
 local remove={}
 for i,pet in ipairs(p.Pets) do
  if pet.rarity==rarity and pet.id~=p.ActiveId then
   table.insert(remove,i)
   if #remove>=3 then break end
  end
 end
 if #remove<3 then return false,"Need 3 inactive creatures of that rarity" end
 for i=#remove,1,-1 do table.remove(p.Pets,remove[i]) end
 return R.addPet(p,species,C.Rarities[tier+1])
end
return E

