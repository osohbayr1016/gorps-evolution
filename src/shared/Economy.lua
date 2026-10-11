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
function E.hire(p,id,now)
 local worker=C.Workers[id]
 if not worker then return false,"Unknown worker" end
 local old=p.Workers[id] or {count=0,last=now}
 if old.count>=5 then return false,"Maximum workers hired" end
 if p.Coins<worker.price then return false,"Not enough coins" end
 p.Coins-=worker.price;old.count+=1;old.last=now;p.Workers[id]=old
 R.quest(p,"Employer",1);return true,"Hired "..id
end
function E.tick(p,now)
 local completed=0
 for id,def in pairs(C.Workers) do
  local w=p.Workers[id]
  if w and w.count>0 then
   local steps=math.min(60,math.floor(math.max(0,now-w.last)/60))
   if steps>0 then
    local payable=math.min(steps,math.floor(p.Coins/(def.wage*w.count)))
    if payable>0 then
     p.Coins-=def.wage*w.count*payable
     local goods={}
     for material,count in pairs(def.grant) do goods[material]=count*w.count*payable end
     R.add(p,goods);completed+=payable*w.count
     if id=="Caretaker" and #p.Pets>0 then
      for i=1,math.min(payable*w.count,120) do
       local pet=p.Pets[((i-1)%#p.Pets)+1]
       local fed=R.feed(p,pet.id)
       if not fed then break end
      end
     end
    end
    -- Advance even if unpaid to avoid accumulating imaginary debt.
    w.last=now
   end
  end
 end
 return completed
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
 else p.Coins+=250 end
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
