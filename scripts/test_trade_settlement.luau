-- Execute the real live-to-durable settlement bridge over a fake UpdateAsync store.
-- Player locks remain a Data.lua/runtime concern; published trading stays disabled.
local fs=require("@lune/fs")
local luau=require("@lune/luau")
local shared={}
local function loadShared(name)
 if shared[name] then return shared[name] end
 local path="src/shared/"..name..".lua"
 local chunk=luau.load(fs.readFile(path),{
  debugName=path,
  environment={
   script={Parent={Config="Config",Rules="Rules"}},
   require=function(value) return loadShared(value) end,
  },
 })
 shared[name]=chunk()
 return shared[name]
end
local ReceiptPolicy=luau.load(fs.readFile("src/server/TradeReceiptPolicy.lua"),{
 debugName="src/server/TradeReceiptPolicy.lua",
})()
local SessionPolicy=luau.load(fs.readFile("src/server/SessionPolicy.lua"),{
 debugName="src/server/SessionPolicy.lua",
})()
local Persistence=luau.load(fs.readFile("src/server/TradePersistence.lua"),{
 debugName="src/server/TradePersistence.lua",
 environment={
  script={Parent={TradeReceiptPolicy=ReceiptPolicy,SessionPolicy=SessionPolicy}},
  require=function(value) return value end,
 },
})()
local Rules=loadShared("Rules")
local TradeRules=loadShared("TradeRules")
local ReplicatedStorage={Shared={Rules=Rules,TradeRules=TradeRules}}
local Settlement=luau.load(fs.readFile("src/server/TradeSettlement.lua"),{
 debugName="src/server/TradeSettlement.lua",
 environment={
  game={GetService=function(_,name)
   assert(name=="ReplicatedStorage","Unexpected service")
   return ReplicatedStorage
  end},
  script={Parent={TradeReceiptPolicy=ReceiptPolicy,TradePersistence=Persistence}},
  require=function(value) return value end,
 },
})()

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
 for key,value in pairs(left) do if not same(value,right[key]) then return false end end
 for key in pairs(right) do if left[key]==nil then return false end end
 return true
end

local Store={}
Store.__index=Store
function Store.new(values,blocked,rejectPrepare)
 return setmetatable({
  values=copy(values),blocked=blocked,rejectPrepare=rejectPrepare,writes=0,
 },Store)
end
function Store:update(key,transform)
 if self.blocked==key then error("injected blocked profile") end
 local current=copy(self.values[key])
 local nextValue,reason=transform(current)
 if nextValue==nil then return nil,reason end
 if self.rejectPrepare==key and type(nextValue)=="table" and nextValue._trade~=nil
  and (type(current)~="table" or current._trade==nil) then
  return nil,"injected prepare rejection"
 end
 if not same(current,nextValue) then self.writes+=1;self.values[key]=copy(nextValue) end
 return copy(self.values[key])
end

local tokenA="settlement-session-a"
local tokenB="settlement-session-b"
local keys={
 receipt=Persistence.receiptKey("aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"),
 a={key="player_101",token=tokenA},
 b={key="player_202",token=tokenB},
}
local function profile(token)
 local value=Rules.new(1800000000)
 value.BaseLevel=8
 value.Inventory.Wood=100
 value.Inventory.Stone=100
 value._session={id=token,expiresAt=1800000300}
 return value
end
local function request(left,right)
 return {
  id="aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",createdAt=1800000000,
  a={userId=101,profile=left,offer={kind="Material",id="Wood",amount=12}},
  b={userId=202,profile=right,offer={kind="Material",id="Stone",amount=7}},
 }
end

local left,right=profile(tokenA),profile(tokenB)
local store=Store.new({[keys.a.key]=left,[keys.b.key]=right})
local ok,status,snapshots,receipt=Settlement.execute(store,keys,request(left,right))
equal(ok,true,"durable settlement succeeds")
equal(status,ReceiptPolicy.COMPLETE,"durable settlement completes")
equal(store.writes,7,"settlement uses seven durable mutations")
equal(left.Inventory.Wood,100,"planning never mutates live left profile")
equal(right.Inventory.Stone,100,"planning never mutates live right profile")
equal(snapshots.a.Inventory.Wood,88,"returned left snapshot pays once")
equal(snapshots.a.Inventory.Stone,107,"returned left snapshot receives once")
equal(snapshots.b.Inventory.Wood,112,"returned right snapshot receives once")
equal(snapshots.b.Inventory.Stone,93,"returned right snapshot pays once")
equal(snapshots.a._session,nil,"live snapshot excludes reserved storage fields")
equal(receipt.state,ReceiptPolicy.COMPLETE,"returned receipt is terminal")
snapshots.a.Inventory.Wood=1
equal(receipt.participants.a.after.Inventory.Wood,88,"returned snapshot is detached from receipt")
equal(store.values[keys.a.key].Inventory.Wood,88,"persisted left matches committed receipt")
equal(store.values[keys.b.key].Inventory.Stone,93,"persisted right matches committed receipt")

local abortLeft,abortRight=profile(tokenA),profile(tokenB)
local abortStore=Store.new({[keys.a.key]=abortLeft,[keys.b.key]=abortRight},nil,keys.b.key)
local abortOk,abortStatus,abortSnapshots=Settlement.execute(
 abortStore,keys,request(abortLeft,abortRight)
)
equal(abortOk,false,"blocked second profile aborts")
equal(abortStatus,ReceiptPolicy.ABORTED,"blocked profile records abort")
equal(abortSnapshots,nil,"aborted settlement exposes no memory snapshots")
equal(abortStore.values[keys.a.key].Inventory.Wood,100,"abort preserves left storage")
equal(abortStore.values[keys.b.key].Inventory.Stone,100,"abort preserves right storage")

local pendingLeft,pendingRight=profile(tokenA),profile(tokenB)
local conflict=Settlement.plan(request(pendingLeft,pendingRight))
conflict.participants.a.offer.amount=99
local pendingStore=Store.new({
 [keys.a.key]=pendingLeft,[keys.b.key]=pendingRight,[keys.receipt]=conflict,
})
local pendingOk,pendingStatus,pendingSnapshots=Settlement.execute(
 pendingStore,keys,request(pendingLeft,pendingRight)
)
equal(pendingOk,nil,"receipt conflict remains an unknown durable outcome")
equal(pendingStatus,Persistence.PENDING,"receipt conflict fails closed as pending")
equal(pendingSnapshots,nil,"pending settlement exposes no memory snapshots")

local invalid=request(profile(tokenA),profile(tokenB))
invalid.a.offer.amount=1001
local invalidOk,invalidStatus,invalidSnapshots,invalidReason=Settlement.execute(
 Store.new({[keys.a.key]=invalid.a.profile,[keys.b.key]=invalid.b.profile}),keys,invalid
)
equal(invalidOk,false,"invalid offer is rejected before persistence")
equal(invalidStatus,"REJECTED","invalid offer has rejected status")
equal(invalidSnapshots,nil,"invalid offer returns no snapshots")
equal(type(invalidReason),"string","invalid offer has a safe reason")

print("PASS: "..checks.." live-to-durable settlement assertions with exact memory snapshots (fake store only).")
