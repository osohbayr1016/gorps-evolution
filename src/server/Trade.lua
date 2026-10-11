local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local C=require(ReplicatedStorage.Shared.Config)
local R=require(ReplicatedStorage.Shared.Rules)
local Trade={}
local sessions={}
local pending={}
local function uid(player) return player.UserId end
local function other(session,player) return session.a==player and session.b or session.a end
local function notify(session,callback)
 callback(session.a);callback(session.b)
end
function Trade.status(player)
 local s=sessions[uid(player)]
 if not s then return {pendingFrom=pending[uid(player)] and pending[uid(player)].Name or nil} end
 local partner=other(s,player)
 return {partner=partner.Name, mine=s.offers[uid(player)], theirs=s.offers[uid(partner)],
  acceptedMine=s.accepted[uid(player)]==true,acceptedTheirs=s.accepted[uid(partner)]==true}
end
function Trade.disconnect(player,emit)
 local s=sessions[uid(player)]
 pending[uid(player)]=nil
 for id,inviter in pairs(pending) do if inviter==player then pending[id]=nil end end
 if not s then return end
 sessions[uid(s.a)]=nil;sessions[uid(s.b)]=nil
 local partner=other(s,player)
 if partner.Parent==Players then emit(partner,"Trade cancelled") end
end
local function checkOffer(p,offer)
 if not offer then return true end
 if offer.kind=="Material" then
  return C.Resources[offer.id]~=nil and R.has(p,{[offer.id]=offer.amount})
 elseif offer.kind=="Pet" then
  local pet=R.pet(p,offer.id)
  return pet~=nil and pet.id~=p.ActiveId and #p.Pets>1
 end
 return false
end
local function exchange(p,target,offer)
 if not offer then return end
 if offer.kind=="Material" then
  R.spend(p,{[offer.id]=offer.amount});R.add(target,{[offer.id]=offer.amount})
 else
  local pet,i=R.pet(p,offer.id)
  table.remove(p.Pets,i)
  local success=R.addPet(target,pet.species,pet.rarity)
  assert(success,"validated creature trade failed")
  local received=target.Pets[#target.Pets]
  received.level=pet.level;received.xp=pet.xp;received.evolved=pet.evolved
 end
end
function Trade.action(player,action,payload,get,changed,emit)
 local id=uid(player)
 if action=="Invite" then
  if sessions[id] then return false,"Already trading" end
  local target=Players:FindFirstChild(tostring(payload.target or ""))
  if not target or target==player or sessions[uid(target)] or not get(target) then return false,"Player unavailable" end
  pending[uid(target)]=player;emit(target,player.Name.." invited you to trade")
  return true,"Trade invitation sent"
 elseif action=="Join" then
  local inviter=pending[id];pending[id]=nil
  if not inviter or inviter.Parent~=Players or sessions[id] or sessions[uid(inviter)] then return false,"Invitation expired" end
  local s={a=inviter,b=player,offers={},accepted={}}
  sessions[id]=s;sessions[uid(inviter)]=s
  emit(inviter,"Trade opened");emit(player,"Trade opened")
  return true,"Trade opened"
 elseif action=="Cancel" then
  Trade.disconnect(player,emit);return true,"Trade cancelled"
 end
 local s=sessions[id]
 if not s then return false,"No active trade" end
 if action=="OfferMaterial" then
  local resource=payload.resource
  local amount=payload.amount
  if type(resource)~="string" or not C.Resources[resource] or type(amount)~="number"
   or amount%1~=0 or amount<1 or amount>1000 then return false,"Invalid offer" end
  if not R.has(get(player),{[resource]=amount}) then return false,"Insufficient resources" end
  s.offers[id]={kind="Material",id=resource,amount=amount}
 elseif action=="OfferPet" then
  local pet=R.pet(get(player),payload.id)
  if not pet or pet.id==get(player).ActiveId or #get(player).Pets<2 then return false,"Cannot offer that creature" end
  s.offers[id]={kind="Pet",id=pet.id}
 elseif action=="Accept" then
  s.accepted[id]=true
  local otherPlayer=other(s,player)
  if s.accepted[uid(otherPlayer)] then
   local p1,p2=get(s.a),get(s.b)
   if not p1 or not p2 or not s.offers[uid(s.a)] or not s.offers[uid(s.b)]
    or not checkOffer(p1,s.offers[uid(s.a)]) or not checkOffer(p2,s.offers[uid(s.b)]) then
    s.accepted={};return false,"Trade assets changed. Review offers again"
   end
   local a=s.offers[uid(s.a)];local b=s.offers[uid(s.b)]
   local after1=#p1.Pets+(b.kind=="Pet" and 1 or 0)-(a.kind=="Pet" and 1 or 0)
   local after2=#p2.Pets+(a.kind=="Pet" and 1 or 0)-(b.kind=="Pet" and 1 or 0)
   if after1>R.capacity(p1) or after2>R.capacity(p2) then
    s.accepted={};return false,"Creature capacity exceeded"
   end
   -- Non-yielding transfer; complete validation of both sides before mutation.
   exchange(p1,p2,a);exchange(p2,p1,b)
   changed(s.a);changed(s.b)
   sessions[uid(s.a)]=nil;sessions[uid(s.b)]=nil
   emit(otherPlayer,"Trade completed")
   return true,"Trade completed"
  end
 else return false,"Unknown trade action" end
 if action~="Accept" then s.accepted={} end
 emit(other(s,player),"Trade offer updated")
 return true,"Trade updated"
end
return Trade
