local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local C=require(ReplicatedStorage.Shared.Config)
local R=require(ReplicatedStorage.Shared.Rules)
local TradeRules=require(ReplicatedStorage.Shared.TradeRules)
local Trade={}
local sessions={}
local pending={}
local function uid(player) return player.UserId end
local function other(session,player) return session.a==player and session.b or session.a end
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
function Trade.action(player,action,payload,get,changed,emit,settle)
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
   if not p1 or not p2 or not s.offers[uid(s.a)] or not s.offers[uid(s.b)] then
    s.accepted={}
    return false,"Both players must offer assets"
   end
   local settled,message
   if settle then
    settled,message=settle(s.a,s.b,s.offers[uid(s.a)],s.offers[uid(s.b)])
   else
    settled,message=TradeRules.exchange(p1,p2,s.offers[uid(s.a)],s.offers[uid(s.b)])
   end
   if not settled then
    s.accepted={}
    return false,message
   end
   if not settle then changed(s.a);changed(s.b) end
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
