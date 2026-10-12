-- Safe receipt compaction and profile-marker cleanup over the real modules.
-- This fake store is not evidence of Roblox DataStore timing or throttling.
local fs=require("@lune/fs")
local luau=require("@lune/luau")
local function load(path)
 return luau.load(fs.readFile(path),{debugName=path})()
end
local ReceiptPolicy=load("src/server/TradeReceiptPolicy.lua")
local ReceiptRetention=load("src/server/TradeReceiptRetention.lua")
local SessionPolicy=load("src/server/SessionPolicy.lua")
local adapterChunk=luau.load(fs.readFile("src/server/TradePersistence.lua"),{
 debugName="src/server/TradePersistence.lua",
 environment={
  script={Parent={
   TradeReceiptPolicy=ReceiptPolicy,
   TradeReceiptRetention=ReceiptRetention,
   SessionPolicy=SessionPolicy,
  }},
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

local Store={}
Store.__index=Store
function Store.new(values,time,failAfterWrite)
 return setmetatable({
  values=copy(values),time=time,writes=0,diagnostics={},
  failAfterWrite=failAfterWrite,failed=false,
 },Store)
end
function Store:now() return self.time end
function Store:diagnostic(kind,fields)
 table.insert(self.diagnostics,{kind=kind,fields=copy(fields)})
end
function Store:update(key,transform)
 local current=copy(self.values[key])
 local nextValue,reason=transform(current)
 if nextValue==nil then return nil,reason end
 local changed=false
 local function same(left,right)
  if type(left)~=type(right) then return false end
  if type(left)~="table" then return left==right end
  for k,v in pairs(left) do if not same(v,right[k]) then return false end end
  for k in pairs(right) do if left[k]==nil then return false end end
  return true
 end
 changed=not same(current,nextValue)
 if changed then
  self.values[key]=copy(nextValue);self.writes+=1
  if self.failAfterWrite==self.writes and not self.failed then
   self.failed=true
   error("injected response loss after write "..self.writes)
  end
 end
 return copy(self.values[key])
end

local tokenA="retention-a:111111111111"
local tokenB="retention-b:222222222222"
local id="aaaaaaaa-bbbb-cccc-dddd-ffffffffffff"
local receiptKey=Adapter.receiptKey(id)
local keys={
 receipt=receiptKey,
 a={key="player/301",token=tokenA},
 b={key="player/302",token=tokenB},
}
local function profiles()
 return {
  Coins=100,Inventory={Wood=10},Pets={},
  _session={id=tokenA,expiresAt=1900001000},
 },{
  Coins=200,Inventory={Wood=20},Pets={},
  _session={id=tokenB,expiresAt=1900001000},
 }
end
local function candidate()
 local left,right=profiles()
 return ReceiptPolicy.create(id,1900000000,301,302,
  {kind="Material",id="Wood",amount=1},
  {kind="Material",id="Wood",amount=2},
  left,{Coins=100,Inventory={Wood=11},Pets={}},
  right,{Coins=200,Inventory={Wood=19},Pets={}})
end

local left,right=profiles()
local store=Store.new({[keys.a.key]=left,[keys.b.key]=right},1900000100)
local ok,status=Adapter.execute(store,keys,candidate())
equal(ok,true,"terminal transaction completes")
equal(status,ReceiptPolicy.COMPLETE,"terminal status")
local full=store.values[receiptKey]
equal(full._audit.committedAt,1900000100,"persistence uses store clock for commit audit")
equal(full._audit.completedAt,1900000100,"persistence uses store clock for completion audit")
equal(full._retention.terminalAt,1900000100,"retention starts after both profile results")
equal(full._retention.compactAfter,1900000100+ReceiptRetention.SECONDS,
 "retention has bounded compact time")
equal(type(full.participants.a.offer),"table","full evidence remains before deadline")

local beforeDue=copy(store.values[keys.a.key])
store.time=full._retention.compactAfter-1
local early,earlyState=Adapter.recoverForLoad(store,keys.a.key,tokenA,301,beforeDue)
equal(earlyState,ReceiptPolicy.COMMITTED,"early terminal marker remains")
equal(type(early._tradeResult),"table","early terminal marker is retained")
equal(store.values[receiptKey].state,ReceiptPolicy.COMPLETE,"receipt stays full before deadline")

store.time=full._retention.compactAfter
local archivedA,archiveState,archive=Adapter.recoverForLoad(
 store,keys.a.key,tokenA,301,early
)
equal(archiveState,Adapter.ARCHIVED,"first due load archives receipt")
equal(archivedA._tradeResult,nil,"first terminal marker clears after archive")
equal(ReceiptRetention.validArchive(archive),true,"archive validates")
equal(archive.participants.a.offer,nil,"archive removes offer payload")
equal(archive.participants.a.before,nil,"archive removes before snapshot")
equal(archive.participants.a.after,nil,"archive removes after snapshot")
equal(archive.participants.a.userId,301,"archive keeps participant identity")
equal(archive.outcome,ReceiptPolicy.COMPLETE,"archive keeps terminal decision")
equal(archive.audit.committedAt,1900000100,"archive keeps persisted commit audit")
equal(archive.audit.completedAt,1900000100,"archive keeps persisted completion audit")

local archivedB,archiveStateB=Adapter.recoverForLoad(
 store,keys.b.key,tokenB,302,store.values[keys.b.key]
)
equal(archiveStateB,Adapter.ARCHIVED,"peer accepts matching archive")
equal(archivedB._tradeResult,nil,"peer terminal marker clears")
equal(store.values[receiptKey].state,ReceiptRetention.ARCHIVED,"archive is immutable tombstone")

local lossValues={
 [receiptKey]=copy(store.values[receiptKey]),
 [keys.a.key]=copy(beforeDue),
}
local lossStore=Store.new(lossValues,store.time,1)
local afterLoss,lossState=Adapter.recoverForLoad(
 lossStore,keys.a.key,tokenA,301,lossStore.values[keys.a.key]
)
equal(lossStore.failed,true,"profile cleanup response loss is injected")
equal(lossState,Adapter.ARCHIVED,"profile cleanup response loss converges")
equal(afterLoss._tradeResult,nil,"cleanup retry recognizes already-cleared marker")

local badArchive=copy(store.values[receiptKey])
badArchive.participants.a.userId=999
local badStore=Store.new({
 [receiptKey]=badArchive,
 [keys.a.key]=copy(beforeDue),
},store.time)
local bad,badStatus=Adapter.recoverForLoad(
 badStore,keys.a.key,tokenA,301,badStore.values[keys.a.key]
)
equal(bad,nil,"conflicting archive fails closed")
equal(badStatus,Adapter.PENDING,"conflicting archive needs recovery")
equal(type(badStore.values[keys.a.key]._tradeResult),"table",
 "conflicting archive cannot erase terminal evidence")

local failedLeft,failedRight=profiles()
local failedKeys=copy(keys)
failedKeys.b.token="wrong-session:333333333333"
local failedStore=Store.new({
 [keys.a.key]=failedLeft,
 [keys.b.key]=failedRight,
},1900000200)
local failedOk,failedStatus=Adapter.execute(failedStore,failedKeys,candidate())
equal(failedOk,nil,"lost peer ownership keeps abort cleanup pending")
equal(failedStatus,Adapter.PENDING,"lost peer ownership fails closed")
equal(failedStore.values[receiptKey]._audit.abortedAt,1900000200,
 "persistence uses store clock for abort audit")

local abortLeft,abortRight=profiles()
local abortCandidate=candidate()
local abortReceipt=ReceiptPolicy.abort(abortCandidate)
abortLeft=ReceiptPolicy.prepare(abortLeft,abortCandidate,"a")
local abortStore=Store.new({
 [receiptKey]=abortReceipt,
 [keys.a.key]=abortLeft,
 [keys.b.key]=abortRight,
},1900000200)
local abortOk,abortStatus=Adapter.execute(abortStore,keys,abortCandidate)
equal(abortOk,false,"safe abort returns false")
equal(abortStatus,ReceiptPolicy.ABORTED,"safe abort status")
equal(abortStore.values[keys.a.key]._trade,nil,"safe abort clears prepared marker")
equal(abortStore.values[receiptKey]._retention.terminalAt,1900000200,
 "abort retention starts only after both profiles confirmed clean")
equal(abortStore.values[receiptKey]._audit.abortedAt,1900000000,
 "pre-decided abort retry preserves original audit time")

print("PASS: "..checks.." trade receipt retention assertions with safe archive cleanup (fake store only).")
