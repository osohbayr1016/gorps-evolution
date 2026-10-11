-- Fault injection for the dependency-injected trade persistence adapter.
-- This uses no live Roblox DataStore and does not enable published trading.
local fs=require("@lune/fs")
local luau=require("@lune/luau")
local receiptChunk=luau.load(fs.readFile("src/server/TradeReceiptPolicy.lua"),{
 debugName="src/server/TradeReceiptPolicy.lua",
})
local ReceiptPolicy=receiptChunk()
local sessionChunk=luau.load(fs.readFile("src/server/SessionPolicy.lua"),{
 debugName="src/server/SessionPolicy.lua",
})
local SessionPolicy=sessionChunk()
local adapterChunk=luau.load(fs.readFile("src/server/TradePersistence.lua"),{
 debugName="src/server/TradePersistence.lua",
 environment={
  script={Parent={TradeReceiptPolicy=ReceiptPolicy,SessionPolicy=SessionPolicy}},
  require=function(value) return value end,
 },
})
local Adapter=adapterChunk()
local checks=0
local function equal(actual,expected,message)
 checks+=1
 assert(actual==expected,message..": expected "..tostring(expected)..", got "..tostring(actual))
end
local function copy(value)
 if type(value)~="table" then return value end
 local result={}
 for key,item in pairs(value) do result[key]=copy(item) end
 return result
end
local function same(left,right)
 if type(left)~=type(right) then return false end
 if type(left)~="table" then return left==right end
 for key,value in pairs(left) do
  if not same(value,right[key]) then return false end
 end
 for key in pairs(right) do
  if left[key]==nil then return false end
 end
 return true
end

local Store={}
Store.__index=Store
function Store.new(values,failAfterWrite,blockedKey)
 return setmetatable({
  values=copy(values),writes=0,failAfterWrite=failAfterWrite,
  failed=false,blockedKey=blockedKey,
 },Store)
end
function Store:update(key,transform)
 if self.blockedKey==key then error("injected pre-write failure for "..key) end
 local current=copy(self.values[key])
 local nextValue,reason=transform(current)
 if nextValue==nil then return nil,reason or "callback rejected" end
 if not same(current,nextValue) then
  self.values[key]=copy(nextValue)
  self.writes+=1
  if self.failAfterWrite==self.writes and not self.failed then
   self.failed=true
   error("injected post-write response loss at boundary "..self.writes)
  end
 end
 return copy(self.values[key])
end

local tokenA="session-a:111111111111"
local tokenB="session-b:222222222222"
local receiptKey="trade:aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
local keys={
 receipt="receipt/"..receiptKey,
 a={key="profile/101",token=tokenA},
 b={key="profile/202",token=tokenB},
}
local function profiles()
 return {
  Coins=500,Inventory={Wood=100,Stone=10},Pets={},
  _session={id=tokenA,expiresAt=1800000300},
 },{
  Coins=400,Inventory={Wood=20,Stone=100},Pets={},
  _session={id=tokenB,expiresAt=1800000300},
 }
end
local function receipt()
 local left,right=profiles()
 return ReceiptPolicy.create(receiptKey,1800000000,101,202,
  {kind="Material",id="Wood",amount=10},
  {kind="Material",id="Stone",amount=10},
  left,{Coins=500,Inventory={Wood=90,Stone=20},Pets={}},
  right,{Coins=400,Inventory={Wood=30,Stone=90},Pets={}})
end
local function values()
 local left,right=profiles()
 return {[keys.a.key]=left,[keys.b.key]=right}
end
local function assertCommitted(store,label)
 local left=store.values[keys.a.key]
 local right=store.values[keys.b.key]
 equal(left.Inventory.Wood,90,label.." left wood")
 equal(left.Inventory.Stone,20,label.." left stone")
 equal(right.Inventory.Wood,30,label.." right wood")
 equal(right.Inventory.Stone,90,label.." right stone")
 equal(left._session.id,tokenA,label.." left session preserved")
 equal(right._session.id,tokenB,label.." right session preserved")
 equal(left._trade,nil,label.." left marker cleared")
 equal(right._trade,nil,label.." right marker cleared")
 equal(left._tradeResult.outcome,ReceiptPolicy.COMMITTED,label.." left committed result")
 equal(right._tradeResult.outcome,ReceiptPolicy.COMMITTED,label.." right committed result")
 equal(store.values[keys.receipt].state,ReceiptPolicy.COMPLETE,label.." receipt complete")
end

-- Lose the response after each actual durable mutation. Retry must recognize the
-- written value and converge without a duplicate debit or credit.
for boundary=1,7 do
 local store=Store.new(values(),boundary)
 local ok,status=Adapter.execute(store,keys,receipt())
 equal(ok,true,"post-write boundary "..boundary.." succeeds")
 equal(status,ReceiptPolicy.COMPLETE,"post-write boundary "..boundary.." status")
 equal(store.failed,true,"post-write boundary "..boundary.." injected")
 equal(store.writes,7,"post-write boundary "..boundary.." has seven mutations")
 assertCommitted(store,"post-write boundary "..boundary)
 local retryOk,retryStatus=Adapter.execute(store,keys,receipt())
 equal(retryOk,true,"terminal retry "..boundary.." succeeds")
 equal(retryStatus,ReceiptPolicy.COMPLETE,"terminal retry "..boundary.." status")
 equal(store.writes,7,"terminal retry "..boundary.." adds no mutation")
end

local blocked=Store.new(values(),nil,keys.b.key)
local blockedOk,blockedStatus=Adapter.execute(blocked,keys,receipt())
equal(blockedOk,false,"permanent pre-write failure aborts")
equal(blockedStatus,ReceiptPolicy.ABORTED,"pre-write failure has durable abort")
equal(blocked.values[keys.receipt].state,ReceiptPolicy.ABORTED,"receipt records abort")
equal(blocked.values[keys.a.key].Inventory.Wood,100,"abort preserves left assets")
equal(blocked.values[keys.a.key]._trade,nil,"abort clears prepared left marker")
equal(blocked.values[keys.b.key].Inventory.Stone,100,"abort preserves right assets")

local staleValues=values()
staleValues[keys.a.key]._session.id="session-other:333333333333"
local stale=Store.new(staleValues)
local staleOk,staleStatus=Adapter.execute(stale,keys,receipt())
equal(staleOk,false,"stale session cannot prepare")
equal(staleStatus,ReceiptPolicy.ABORTED,"stale session aborts before commit")
equal(stale.values[keys.a.key].Inventory.Wood,100,"stale session cannot debit profile")
equal(stale.values[keys.b.key].Inventory.Stone,100,"stale session cannot credit peer")

local recoveryReceipt=receipt()
local recoveryValues=values()
recoveryValues[keys.a.key]=ReceiptPolicy.prepare(recoveryValues[keys.a.key],recoveryReceipt,"a")
recoveryValues[keys.receipt]=recoveryReceipt
local recovery=Store.new(recoveryValues,1)
local recovered,recoveryState=Adapter.recoverProfile(
 recovery,keys.receipt,keys.a.key,tokenA,"a"
)
equal(recoveryState,ReceiptPolicy.ABORTED,"join-time preparing marker aborts")
equal(recovered.Inventory.Wood,100,"aborted join recovery preserves assets")
equal(recovered._trade,nil,"aborted join recovery clears marker")
equal(recovered._tradeResult.outcome,ReceiptPolicy.ABORTED,"aborted join recovery records result")
equal(recovery.failed,true,"join recovery survives lost abort response")

local committedReceipt=receipt()
local committedValues=values()
committedValues[keys.a.key]=ReceiptPolicy.prepare(committedValues[keys.a.key],committedReceipt,"a")
committedValues[keys.b.key]=ReceiptPolicy.prepare(committedValues[keys.b.key],committedReceipt,"b")
committedReceipt=ReceiptPolicy.commit(
 committedReceipt,committedValues[keys.a.key],committedValues[keys.b.key]
)
committedValues[keys.receipt]=committedReceipt
local committedStore=Store.new(committedValues)
local recoveredA,stateA=Adapter.recoverProfile(
 committedStore,keys.receipt,keys.a.key,tokenA,"a"
)
local recoveredB,stateB=Adapter.recoverProfile(
 committedStore,keys.receipt,keys.b.key,tokenB,"b"
)
equal(stateA,ReceiptPolicy.COMMITTED,"committed left recovery decision")
equal(stateB,ReceiptPolicy.COMMITTED,"committed right recovery decision")
equal(recoveredA.Inventory.Stone,20,"committed left recovery applies after snapshot")
equal(recoveredB.Inventory.Wood,30,"committed right recovery applies after snapshot")
local finishOk,finishStatus=Adapter.execute(committedStore,keys,receipt())
equal(finishOk,true,"executor completes join-recovered receipt")
equal(finishStatus,ReceiptPolicy.COMPLETE,"join-recovered receipt completes")
assertCommitted(committedStore,"join recovery")

local conflictValues=values()
local conflict=receipt()
conflict.participants.a.offer.amount=99
conflictValues[keys.receipt]=conflict
local conflictStore=Store.new(conflictValues)
local conflictOk,conflictStatus=Adapter.execute(conflictStore,keys,receipt())
equal(conflictOk,nil,"receipt payload conflict fails closed")
equal(conflictStatus,Adapter.PENDING,"receipt payload conflict is not overwritten")
equal(conflictStore.values[keys.receipt].participants.a.offer.amount,99,
 "conflicting receipt stays immutable")
equal(conflictStore.values[keys.a.key].Inventory.Wood,100,
 "receipt conflict does not change profile")

print("PASS: "..checks.." trade persistence assertions with pre/post-write faults and session checks (fake store only).")
