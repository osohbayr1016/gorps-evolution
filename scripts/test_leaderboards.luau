-- Run actual leaderboard adapter with mocked, re-entrant OrderedDataStore reads.
-- This is not a published Roblox DataStore or live engine integration test.
local fs=require("@lune/fs")
local luau=require("@lune/luau")
local now=1000
local readCount=0
local nameLookups=0
local reentrantCalls=0
local failWins=false
local failMinutes=false
local Ranking=nil
local stores={}
local function storeFor(id)
 if stores[id] then return stores[id] end
 local store={}
 function store:GetSortedAsync(desc,limit)
  assert(desc==false and limit==10,"Expected descending top-10 read")
  readCount+=1
  if id=="Coins" then
   reentrantCalls+=1
   local nested=Ranking.top()
   assert(type(nested)=="table" and type(nested.Coins)=="table",
    "Re-entrant read must return a stale safe snapshot")
  end
  if id=="Wins" and failWins then error("Simulated OrderedDataStore read failure") end
  return {
   GetCurrentPage=function()
    if id=="Minutes" and failMinutes then error("Simulated page read failure") end
    return {{key="42",value=id=="Coins" and 900 or (id=="Wins" and 7 or 30)}}
   end,
  }
 end
 stores[id]=store
 return store
end
local services={
 RunService={IsStudio=function() return false end},
 DataStoreService={GetOrderedDataStore=function(_,key)
  local id=string.match(key,"^GorpsRank(.+)_v1$")
  assert(id,"Unexpected leaderboard key: "..key)
  return storeFor(id)
 end},
 Players={GetNameFromUserIdAsync=function(_,id)
  nameLookups+=1
  return "Player"..tostring(id)
 end},
}
local chunk=luau.load(fs.readFile("src/server/Leaderboards.lua"),{
 debugName="src/server/Leaderboards.lua",
 environment={
  game={GetService=function(_,name)
   assert(services[name],"Unexpected service "..name)
   return services[name]
  end},
  os={time=function() return now end},
  warn=function() end,
 },
})
Ranking=chunk()
local checks=0
local function equal(actual,expected,message)
 checks+=1
 assert(actual==expected,message..": expected "..tostring(expected)..", got "..tostring(actual))
end
local first=Ranking.top()
equal(readCount,3,"first cold-cache refresh reads exactly three rankings")
equal(reentrantCalls,1,"reentrant callback does not refresh recursively")
equal(first.Coins[1].score,900,"coins board has correct scores")
equal(first.Wins[1].score,7,"wins board has correct scores")
equal(first.Minutes[1].score,30,"minutes board has correct scores")
equal(first.Coins[1].name,"Player42","name lookup is normalized")
equal(nameLookups,1,"shared user ID lookup is cached across boards")
local cached=Ranking.top()
equal(cached,first,"concurrent reads reuse the same snapshot")
equal(readCount,3,"cached read performs no new datastore query")
now=1179
equal(Ranking.top(),first,"179-second cache remains valid")
equal(readCount,3,"cache does not refresh before TTL")
now=1180
local refreshed=Ranking.top()
equal(readCount,6,"180-second boundary triggers one complete refresh")
equal(reentrantCalls,2,"each refresh protects reentrant callers")
equal(refreshed.Coins[1].score,900,"refresh preserves leaderboard content")
now=1360
failWins=true
failMinutes=true
local partiallyFailed=Ranking.top()
equal(readCount,9,"failed refresh still attempts each independent board")
equal(partiallyFailed.Wins[1].score,7,"failed Wins read retains stale rankings")
equal(partiallyFailed.Minutes[1].score,30,"failed Minutes page retains stale rankings")
equal(partiallyFailed.Coins[1].score,900,"healthy Coins board still updates")
equal(Ranking.top(),partiallyFailed,"failure results are also cached to avoid retry storms")
equal(readCount,9,"failure does not cause unbounded immediate retries")
print("PASS: "..checks.." leaderboard singleflight and stale-cache assertions (live DataStore QA pending).")
