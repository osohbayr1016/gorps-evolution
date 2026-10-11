-- Session-checked durable trade coordinator over an injected UpdateAsync-style store.
-- This module is intentionally not wired to live trading while DurableTrades is false.
local ReceiptPolicy=require(script.Parent.TradeReceiptPolicy)
local SessionPolicy=require(script.Parent.SessionPolicy)

local Persistence={}
Persistence.RETRIES=3
Persistence.PENDING="PENDING"
Persistence.CLEAN="CLEAN"

local function copy(value)
 if type(value)~="table" then return value end
 local result={}
 for key,item in pairs(value) do result[key]=copy(item) end
 return result
end

function Persistence.receiptKey(id)
 if type(id)~="string" or #id<16 or #id>44 then return nil end
 return "trade_"..id
end

local function validEntry(entry)
 return type(entry)=="table" and type(entry.key)=="string" and #entry.key>0
  and type(entry.token)=="string"
end
local function validKeys(keys)
 return type(keys)=="table" and type(keys.receipt)=="string" and #keys.receipt>0
  and validEntry(keys.a) and validEntry(keys.b)
  and keys.a.key~=keys.b.key and keys.receipt~=keys.a.key
  and keys.receipt~=keys.b.key
end
local function updateValue(store,key,transform)
 if type(store)~="table" or type(store.update)~="function" then
  return nil,"Invalid trade store"
 end
 local lastReason="Update failed"
 for _=1,Persistence.RETRIES do
  local ok,value,reason=pcall(store.update,store,key,transform)
  if ok and value~=nil then return value end
  lastReason=ok and (reason or "Update rejected") or tostring(value)
 end
 return nil,lastReason
end
local function sameTransaction(stored,candidate)
 return ReceiptPolicy.sameTransaction(stored,candidate)
end
local function observeReceipt(store,key,candidate)
 return updateValue(store,key,function(stored)
  if not sameTransaction(stored,candidate) then
   return nil,"Stored receipt does not match transaction"
  end
  return stored
 end)
end
local function updateOwnedProfile(store,entry,transform)
 return updateValue(store,entry.key,function(stored)
  if not SessionPolicy.owns(stored,entry.token) then
   return nil,"Session ownership lost"
  end
  return transform(stored)
 end)
end
local function resolveProfile(store,entry,receipt,role)
 return updateOwnedProfile(store,entry,function(stored)
  local outcome=receipt.state==ReceiptPolicy.ABORTED and ReceiptPolicy.ABORTED
   or ReceiptPolicy.COMMITTED
  if ReceiptPolicy.resolved(stored,receipt,role,outcome) then return stored end
  return ReceiptPolicy.resolve(stored,receipt,role)
 end)
end
local function abortPrepared(store,keys,candidate)
 local receipt,reason=updateValue(store,keys.receipt,function(stored)
  if not sameTransaction(stored,candidate) then
   return nil,"Stored receipt does not match transaction"
  end
  if stored.state==ReceiptPolicy.PREPARING or stored.state==ReceiptPolicy.ABORTED then
   return ReceiptPolicy.abort(stored)
  end
  return stored
 end)
 if not receipt then
  return nil,Persistence.PENDING,reason
 end
 if receipt.state~=ReceiptPolicy.ABORTED then
  return nil,Persistence.PENDING,"Commit decision requires recovery"
 end
 -- A side may not have reached preparation. Cleanup is therefore best-effort
 -- here; matching markers are idempotently cleared, absent markers are ignored.
 resolveProfile(store,keys.a,receipt,"a")
 resolveProfile(store,keys.b,receipt,"b")
 return false,ReceiptPolicy.ABORTED,receipt
end

function Persistence.execute(store,keys,candidate)
 if not validKeys(keys) or not ReceiptPolicy.valid(candidate)
  or candidate.state~=ReceiptPolicy.PREPARING then
  return nil,Persistence.PENDING,"Invalid durable trade request"
 end
 local receipt,reason=updateValue(store,keys.receipt,function(stored)
  if stored==nil then return candidate end
  if sameTransaction(stored,candidate) then return stored end
  return nil,"Receipt key already contains another transaction"
 end)
 if not receipt then return nil,Persistence.PENDING,reason end
 if receipt.state==ReceiptPolicy.ABORTED then
  return false,ReceiptPolicy.ABORTED,receipt
 end
 if receipt.state==ReceiptPolicy.COMPLETE then
  return true,ReceiptPolicy.COMPLETE,receipt
 end

 local left
 local right
 if receipt.state==ReceiptPolicy.PREPARING then
  left,reason=updateOwnedProfile(store,keys.a,function(stored)
   return ReceiptPolicy.prepare(stored,receipt,"a")
  end)
  if not left then return abortPrepared(store,keys,candidate) end
  right,reason=updateOwnedProfile(store,keys.b,function(stored)
   return ReceiptPolicy.prepare(stored,receipt,"b")
  end)
  if not right then return abortPrepared(store,keys,candidate) end
  receipt,reason=updateValue(store,keys.receipt,function(stored)
   if not sameTransaction(stored,candidate) then
    return nil,"Stored receipt does not match transaction"
   end
   return ReceiptPolicy.commit(stored,left,right)
  end)
  if not receipt then
   receipt=observeReceipt(store,keys.receipt,candidate)
   if not receipt then return nil,Persistence.PENDING,reason end
   if receipt.state==ReceiptPolicy.PREPARING then
    return abortPrepared(store,keys,candidate)
   end
  end
 end

 if receipt.state~=ReceiptPolicy.COMMITTED then
  if receipt.state==ReceiptPolicy.COMPLETE then
   return true,ReceiptPolicy.COMPLETE,receipt
  end
  if receipt.state==ReceiptPolicy.ABORTED then
   return false,ReceiptPolicy.ABORTED,receipt
  end
  return nil,Persistence.PENDING,"Receipt has no recoverable decision"
 end
 left,reason=resolveProfile(store,keys.a,receipt,"a")
 if not left then return nil,Persistence.PENDING,reason end
 right,reason=resolveProfile(store,keys.b,receipt,"b")
 if not right then return nil,Persistence.PENDING,reason end
 receipt,reason=updateValue(store,keys.receipt,function(stored)
  if not sameTransaction(stored,candidate) then
   return nil,"Stored receipt does not match transaction"
  end
  return ReceiptPolicy.complete(stored,left,right)
 end)
 if not receipt then
  receipt=observeReceipt(store,keys.receipt,candidate)
  if not receipt or receipt.state~=ReceiptPolicy.COMPLETE then
   return nil,Persistence.PENDING,reason
  end
 end
 return true,ReceiptPolicy.COMPLETE,receipt
end

function Persistence.recoverProfile(store,receiptKey,profileKey,sessionToken,role)
 if type(receiptKey)~="string" or #receiptKey==0
  or type(profileKey)~="string" or #profileKey==0
  or type(sessionToken)~="string" or (role~="a" and role~="b") then
  return nil,Persistence.PENDING,"Invalid profile recovery request"
 end
 local receipt,reason=updateValue(store,receiptKey,function(stored)
  if not ReceiptPolicy.valid(stored) then return nil,"Invalid stored receipt" end
  if stored.state==ReceiptPolicy.PREPARING then return ReceiptPolicy.abort(stored) end
  return stored
 end)
 if not receipt then return nil,Persistence.PENDING,reason end
 local profile
 profile,reason=updateOwnedProfile(store,{key=profileKey,token=sessionToken},function(stored)
  local outcome=receipt.state==ReceiptPolicy.ABORTED and ReceiptPolicy.ABORTED
   or ReceiptPolicy.COMMITTED
  if ReceiptPolicy.resolved(stored,receipt,role,outcome) then return stored end
  return ReceiptPolicy.resolve(stored,receipt,role)
 end)
 if not profile then return nil,Persistence.PENDING,reason end
 return profile,receipt.state,receipt
end

local function validMarker(marker,userId,terminal)
 if type(marker)~="table" or marker.version~=ReceiptPolicy.VERSION
  or marker.userId~=userId or (marker.role~="a" and marker.role~="b")
  or not Persistence.receiptKey(marker.id) then return false end
 if terminal then
  return marker.outcome==ReceiptPolicy.ABORTED
   or marker.outcome==ReceiptPolicy.COMMITTED
 end
 return marker.outcome==nil
end

function Persistence.recoverForLoad(store,profileKey,sessionToken,userId,claimed)
 if type(userId)~="number" or userId%1~=0 or userId<1
  or type(claimed)~="table"
  or not SessionPolicy.owns(claimed,sessionToken) then
  return nil,Persistence.PENDING,"Invalid claimed profile recovery"
 end
 local pending=claimed._trade
 local terminal=claimed._tradeResult
 if pending~=nil and terminal~=nil then
  return nil,Persistence.PENDING,"Profile has conflicting trade markers"
 end
 if pending~=nil then
  if not validMarker(pending,userId,false) then
   return nil,Persistence.PENDING,"Invalid pending trade marker"
  end
  return Persistence.recoverProfile(store,Persistence.receiptKey(pending.id),
   profileKey,sessionToken,pending.role)
 end
 if terminal~=nil then
  if not validMarker(terminal,userId,true) then
   return nil,Persistence.PENDING,"Invalid terminal trade marker"
  end
  return copy(claimed),terminal.outcome
 end
 return copy(claimed),Persistence.CLEAN
end

return Persistence
