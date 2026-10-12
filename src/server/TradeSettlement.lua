-- Pure bridge from a validated live offer to the durable receipt coordinator.
-- Data.lua owns player locks and is the only module allowed to replace live profiles.
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Rules=require(ReplicatedStorage.Shared.Rules)
local TradeRules=require(ReplicatedStorage.Shared.TradeRules)
local ReceiptPolicy=require(script.Parent.TradeReceiptPolicy)
local TradePersistence=require(script.Parent.TradePersistence)

local Settlement={}

local function participant(value)
 return type(value)=="table" and type(value.userId)=="number"
  and type(value.profile)=="table" and type(value.offer)=="table"
end

function Settlement.plan(request)
 if type(request)~="table" or type(request.id)~="string"
  or type(request.createdAt)~="number" or not participant(request.a)
  or not participant(request.b) or request.a.userId==request.b.userId then
  return nil,"Invalid live trade request"
 end
 local beforeA=Rules.copy(request.a.profile)
 local beforeB=Rules.copy(request.b.profile)
 local afterA=Rules.copy(beforeA)
 local afterB=Rules.copy(beforeB)
 local ok,reason=TradeRules.exchange(afterA,afterB,request.a.offer,request.b.offer)
 if not ok then return nil,reason end
 local receipt
 receipt,reason=ReceiptPolicy.create(request.id,request.createdAt,
  request.a.userId,request.b.userId,request.a.offer,request.b.offer,
  beforeA,afterA,beforeB,afterB)
 if not receipt then return nil,reason end
 return receipt
end

function Settlement.execute(store,keys,request)
 local receipt,reason=Settlement.plan(request)
 if not receipt then return false,"REJECTED",nil,reason end
 local ok,status,terminal=TradePersistence.execute(store,keys,receipt)
 if ok~=true then return ok,status,nil,terminal end
 if type(terminal)~="table" or terminal.state~=ReceiptPolicy.COMPLETE
  or not ReceiptPolicy.sameTransaction(terminal,receipt) then
  return nil,TradePersistence.PENDING,nil,"Durable result was not complete"
 end
 return true,status,{
  a=Rules.copy(terminal.participants.a.after),
  b=Rules.copy(terminal.participants.b.after),
 },terminal
end

return Settlement
