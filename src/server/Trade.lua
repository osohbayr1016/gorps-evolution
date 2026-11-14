local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local C=require(ReplicatedStorage.Shared.Config)
local R=require(ReplicatedStorage.Shared.Rules)
local TradeRules=require(ReplicatedStorage.Shared.TradeRules)
local Trade={}
local sessions={}
local pending={}
local lastInvite={}
local INVITE_TTL=30
local INVITE_COOLDOWN=3
local function uid(player) return player.UserId end
-- Resolve lazily so an expired or disconnected sender can never be joined.
local function pendingSender(player)
 local invitation=pending[uid(player)]
 if not invitation then return nil end
 if os.clock()>=invitation.expiresAt or invitation.sender.Parent~=Players
  or player.Parent~=Players or sessions[uid(invitation.sender)] then
  pending[uid(player)]=nil
  return nil
 end
 return invitation.sender
end
-- Only one outstanding outgoing invitation is allowed at a time; otherwise
-- a previous recipient can join unexpectedly after another trade ends.
local function outgoingTarget(sender)
 for recipientId,invitation in pairs(pending) do
  if invitation.sender==sender then
   local recipient=invitation.recipient
   if recipient and pendingSender(recipient)==sender then return recipient end
   pending[recipientId]=nil
  end
 end
 return nil
end
local function other(session,player) return session.a==player and session.b or session.a end
function Trade.status(player)
 local s=sessions[uid(player)]
 if not s then
  local inviter=pendingSender(player)
  local outgoing=outgoingTarget(player)
  return {pendingFrom=inviter and inviter.Name or nil,
   pendingTo=outgoing and outgoing.Name or nil}
 end
 local partner=other(s,player)
 return {partner=partner.Name, mine=s.offers[uid(player)], theirs=s.offers[uid(partner)],
  acceptedMine=s.accepted[uid(player)]==true,acceptedTheirs=s.accepted[uid(partner)]==true,
  finalizing=s.settling==true}
end
function Trade.disconnect(player,emit,force)
 local s=sessions[uid(player)]
 if s and s.settling and not force then return false,"Trade is finalizing" end
 pending[uid(player)]=nil
 for id,invitation in pairs(pending) do
  if invitation.sender==player then pending[id]=nil end
 end
 if not s then return true end
 if sessions[uid(s.a)]==s then sessions[uid(s.a)]=nil end
 if sessions[uid(s.b)]==s then sessions[uid(s.b)]=nil end
 local partner=other(s,player)
 if partner.Parent==Players then emit(partner,"Trade cancelled") end
 return true
end
-- An ordinary Cancel must not reset anti-spam timing. Only a real departure
-- discards the per-player timestamp and any pending invitations.
function Trade.leave(player,emit)
 Trade.disconnect(player,emit,true)
 lastInvite[uid(player)]=nil
end
function Trade.action(player,action,payload,get,changed,emit,settle)
 local id=uid(player)
 if action=="Invite" then
  if sessions[id] then return false,"Already trading" end
  local target=Players:FindFirstChild(tostring(payload.target or ""))
  if not target or target==player or sessions[uid(target)] or not get(target) then return false,"Player unavailable" end
  local now=os.clock()
  if now-(lastInvite[id] or -100)<INVITE_COOLDOWN then
   return false,"Wait before sending another invitation"
  end
  if outgoingTarget(player) then return false,"Cancel your current invitation before sending another" end
  if pendingSender(target) then return false,"Player already has a trade invitation" end
  pending[uid(target)]={sender=player,recipient=target,expiresAt=now+INVITE_TTL}
  lastInvite[id]=now
  emit(target,player.Name.." invited you to trade (30 seconds)")
  return true,"Trade invitation sent"
 elseif action=="Join" then
  local inviter=pendingSender(player);pending[id]=nil
  if not inviter or inviter.Parent~=Players or sessions[id] or sessions[uid(inviter)]
   or not get(inviter) or not get(player) then return false,"Invitation expired" end
  local s={a=inviter,b=player,offers={},accepted={}}
  sessions[id]=s;sessions[uid(inviter)]=s
  emit(inviter,"Trade opened");emit(player,"Trade opened")
  return true,"Trade opened"
 elseif action=="Cancel" then
  local cancelled,reason=Trade.disconnect(player,emit)
  if not cancelled then return false,reason end
  return true,"Trade cancelled"
 end
 local s=sessions[id]
 if not s then return false,"No active trade" end
 if s.settling then return false,"Trade is finalizing" end
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
  if pet.favorite==true then return false,"Remove the favorite mark before trading" end
  -- Freeze exactly what both players are consenting to. Later feeding or
  -- evolution must not silently change an accepted creature offer.
  s.offers[id]={kind="Pet",id=pet.id,pet=R.copy(pet)}
 elseif action=="Accept" then
  s.accepted[id]=true
  local otherPlayer=other(s,player)
  if s.accepted[uid(otherPlayer)] then
   local p1,p2=get(s.a),get(s.b)
   if not p1 or not p2 or not s.offers[uid(s.a)] or not s.offers[uid(s.b)] then
    s.accepted={}
    emit(otherPlayer,"Trade could not complete; review offers and accept again")
    return false,"Both players must offer assets"
   end
   -- The persistence settlement may yield across several DataStore operations.
   -- Lock the shared offer/consent state before entering that asynchronous path.
   s.settling=true
   local callOK,settled,message=pcall(function()
    if settle then
     return settle(s.a,s.b,s.offers[uid(s.a)],s.offers[uid(s.b)])
    end
    return TradeRules.exchange(p1,p2,s.offers[uid(s.a)],s.offers[uid(s.b)])
   end)
   if not callOK or not settled then
    s.settling=false
    s.accepted={}
    if otherPlayer.Parent==Players then
     emit(otherPlayer,"Trade not completed; review offers and accept again")
    end
    return false,callOK and (message or "Trade not completed") or "Trade could not be finalized"
   end
   if not settle then changed(s.a);changed(s.b) end
   if sessions[uid(s.a)]==s then sessions[uid(s.a)]=nil end
   if sessions[uid(s.b)]==s then sessions[uid(s.b)]=nil end
   if otherPlayer.Parent==Players then emit(otherPlayer,"Trade completed") end
   return true,"Trade completed"
  end
 else return false,"Unknown trade action" end
 if action~="Accept" then s.accepted={} end
 emit(other(s,player),"Trade offer updated")
 return true,"Trade updated"
end
return Trade
