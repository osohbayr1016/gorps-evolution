-- Fault injection through the concrete DataStore UpdateAsync wrapper.
-- This is a fake service boundary, not a live Roblox DataStore test.
local fs=require("@lune/fs")
local luau=require("@lune/luau")
local function load(path)
 return luau.load(fs.readFile(path),{debugName=path})()
end
local ReceiptPolicy=load("src/server/TradeReceiptPolicy.lua")
local ReceiptRetention=load("src/server/TradeReceiptRetention.lua")
local SessionPolicy=load("src/server/SessionPolicy.lua")
local StoreAdapter=load("src/server/TradeStoreAdapter.lua")
local Persistence=luau.load(fs.readFile("src/server/TradePersistence.lua"),{
 debugName="src/server/TradePersistence.lua",
 environment={
  script={Parent={
   TradeReceiptPolicy=ReceiptPolicy,
   TradeReceiptRetention=ReceiptRetention,
   SessionPolicy=SessionPolicy,
  }},
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

local LiveStore={}
LiveStore.__index=LiveStore
function LiveStore.new(values,failAfterWrite,failCalls)
 return setmetatable({
  values=copy(values),writes=0,calls=0,failAfterWrite=failAfterWrite,
  failedAfterWrite=false,failCalls=failCalls or {},
 },LiveStore)
end
function LiveStore:UpdateAsync(key,transform)
 self.calls+=1
 local prewrite=self.failCalls[self.calls]
 if prewrite then error(prewrite) end
 local current=copy(self.values[key])
 local nextValue=transform(current)
 if nextValue==nil then return nil end
 if not same(current,nextValue) then
  self.values[key]=copy(nextValue)
  self.writes+=1
  if self.failAfterWrite==self.writes and not self.failedAfterWrite then
   self.failedAfterWrite=true
   error("connection response loss after committed write")
  end
 end
 return copy(self.values[key])
end

local tokenA="wrapper-a:111111111111"
local tokenB="wrapper-b:222222222222"
local id="bbbbbbbb-cccc-dddd-eeee-ffffffffffff"
local keys={
 receipt=Persistence.receiptKey(id),
 a={key="player_401",token=tokenA},
 b={key="player_402",token=tokenB},
}
local function profiles()
 return {
  Coins=300,Inventory={Wood=30,Stone=3},Pets={},
  _session={id=tokenA,expiresAt=2000001000},
 },{
  Coins=400,Inventory={Wood=4,Stone=40},Pets={},
  _session={id=tokenB,expiresAt=2000001000},
 }
end
local function values()
 local left,right=profiles()
 return {[keys.a.key]=left,[keys.b.key]=right}
end
local function candidate()
 local left,right=profiles()
 return ReceiptPolicy.create(id,2000000000,401,402,
  {kind="Material",id="Wood",amount=3},
  {kind="Material",id="Stone",amount=3},
  left,{Coins=300,Inventory={Wood=27,Stone=6},Pets={}},
  right,{Coins=400,Inventory={Wood=7,Stone=37},Pets={}})
end
local function wrapped(live)
 local events={}
 local wrapper=StoreAdapter.new(live,{
  now=function() return 2000000100 end,
  record=function(kind,fields)
   table.insert(events,{kind=kind,fields=copy(fields)})
  end,
 })
 return wrapper,events
end
local function failures(events)
 local result={}
 for _,event in ipairs(events) do
  if event.kind=="datastore_update_failed" then table.insert(result,event) end
 end
 return result
end

-- Lose the concrete UpdateAsync response after every durable mutation. The
-- real persistence coordinator must retry through this wrapper and converge.
for boundary=1,8 do
 local live=LiveStore.new(values(),boundary)
 local wrapper,events=wrapped(live)
 local ok,status=Persistence.execute(wrapper,keys,candidate())
 equal(ok,true,"response loss boundary "..boundary.." completes")
 equal(status,ReceiptPolicy.COMPLETE,"response loss boundary "..boundary.." status")
 equal(live.failedAfterWrite,true,"response loss boundary "..boundary.." injected")
 equal(live.writes,8,"response loss boundary "..boundary.." mutation count")
 equal(live.values[keys.a.key].Inventory.Stone,6,
  "response loss boundary "..boundary.." left applies once")
 equal(live.values[keys.b.key].Inventory.Wood,7,
  "response loss boundary "..boundary.." right applies once")
 equal(live.values[keys.receipt]._retention.terminalAt,2000000100,
  "response loss boundary "..boundary.." retention attached")
 local failureEvents=failures(events)
 equal(#failureEvents,1,"response loss boundary "..boundary.." diagnostic count")
 equal(failureEvents[1].kind,"datastore_update_failed",
  "response loss boundary "..boundary.." diagnostic kind")
 equal(failureEvents[1].fields.status,"TRANSIENT",
  "response loss boundary "..boundary.." classification")
 equal(failureEvents[1].fields.scope,(boundary==1 or boundary==4 or boundary==7 or boundary==8)
  and "receipt" or "profile","response loss boundary "..boundary.." scope")
 equal(failureEvents[1].fields.key,nil,"response loss never records raw key")
end

local throttledLive=LiveStore.new(values(),nil,{
 [1]="DataStore request was throttled: too many requests",
 [2]="request limit exceeded",
})
local throttled,throttleEvents=wrapped(throttledLive)
local throttleOk=Persistence.execute(throttled,keys,candidate())
equal(throttleOk,true,"two throttled attempts recover within retry bound")
local throttleFailures=failures(throttleEvents)
equal(#throttleFailures,2,"throttle diagnostics recorded")
equal(throttleFailures[1].fields.status,"THROTTLED","throttle classified")
equal(throttleFailures[2].fields.status,"THROTTLED","request limit classified")

local budgetLive=LiveStore.new(values(),nil,{
 [1]="DataStore request budget exhausted",
 [2]="DataStore request budget exhausted",
 [3]="DataStore request budget exhausted",
})
local budget,budgetEvents=wrapped(budgetLive)
local budgetOk,budgetStatus=Persistence.execute(budget,keys,candidate())
equal(budgetOk,nil,"exhausted budget fails closed")
equal(budgetStatus,Persistence.PENDING,"exhausted budget remains pending")
equal(budgetLive.writes,0,"exhausted budget writes nothing")
equal(#budgetEvents,3,"each exhausted retry is observable")
for index,event in ipairs(budgetEvents) do
 equal(event.fields.status,"BUDGET","budget classification "..index)
end

equal(StoreAdapter.classify("HTTP 503 service unavailable"),"TRANSIENT",
 "service outage classified")
equal(StoreAdapter.classify("403 API access disabled"),"CONFIG",
 "configuration failure classified")
equal(StoreAdapter.classify("unexpected adapter fault"),"UNKNOWN",
 "unknown failure stays explicit")

local rejectLive=LiveStore.new({[keys.receipt]={keep=true}})
local rejected,rejectEvents=wrapped(rejectLive)
local rejectValue,rejectReason=rejected:update(keys.receipt,function()
 return nil,"immutable conflict\nwith details"
end)
equal(rejectValue,nil,"callback rejection returns nil")
equal(rejectReason,"immutable conflict with details","callback reason sanitized")
equal(rejectEvents[1].kind,"datastore_update_rejected","rejection is distinguished")
equal(rejectEvents[1].fields.status,"REJECTED","rejection classification")
equal(rejectEvents[1].fields.scope,"receipt","rejection scope")

local redactionLive=LiveStore.new(values(),nil,{
 [1]="timeout while updating player_401",
})
local redacted,redactionEvents=wrapped(redactionLive)
redacted:update(keys.a.key,function(old) return old end)
equal(redactionEvents[1].fields.status,"TRANSIENT","redaction fault classified")
equal(redactionEvents[1].fields.scope,"profile","redaction keeps safe scope")
equal(redactionEvents[1].fields.reason:find("player_401",1,true),nil,
 "diagnostic reason removes exact DataStore key")
equal(redactionEvents[1].fields.reason:find("[redacted-key]",1,true)~=nil,true,
 "diagnostic reason marks key redaction")

print("PASS: "..checks.." concrete trade DataStore wrapper assertions with classified faults (fake service only).")
