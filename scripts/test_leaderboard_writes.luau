-- Actual leaderboard module under mocked reentrant OrderedDataStore writes.
-- Verifies that an earlier yielding write cannot win after a newer save.
local fs=require("@lune/fs")
local luau=require("@lune/luau")
local Ranking=nil
local byBoard={}
local writes={}
local injected=false
local warned=0
local keys={Coins="GorpsRankCoins_v1",Wins="GorpsRankWins_v1",Minutes="GorpsRankMinutes_v1"}
local user42={UserId=42}
local user43={UserId=43}
local function boardFor(name)
 local board=byBoard[name]
 if board then return board end
 board={latest={},history={}}
 function board:SetAsync(key,value)
  assert(type(key)=="string" and type(value)=="number","rank write requires bounded key/value")
  -- Simulate asynchronous newer periodic/leave writes arriving while the
  -- older user's first Coins write is waiting inside OrderedDataStore.
  if name=="Coins" and key=="42" and not injected then
   injected=true
   Ranking.write(user42,{Coins=500,Wins=7,Seconds=300})
   Ranking.write(user42,{Coins=600,Wins=9,Seconds=600})
   Ranking.write(user43,{Coins=70,Wins=2,Seconds=180})
  end
  self.latest[key]=value
  table.insert(self.history,{key=key,value=value})
  table.insert(writes,{board=name,key=key,value=value})
 end
 byBoard[name]=board
 return board
end
local services={
 RunService={IsStudio=function() return false end},
 DataStoreService={GetOrderedDataStore=function(_,key)
  assert(key==keys.Coins or key==keys.Wins or key==keys.Minutes,
   "Unknown leaderboard store "..tostring(key))
  return boardFor(key:match("^GorpsRank(.+)_v1$"))
 end},
 Players={GetNameFromUserIdAsync=function() return "MockPlayer" end},
}
local module=luau.load(fs.readFile("src/server/Leaderboards.lua"),{
 debugName="src/server/Leaderboards.lua",
 environment={
  game={GetService=function(_,name)
   assert(services[name],"Unexpected service "..tostring(name))
   return services[name]
  end},
  warn=function() warned+=1 end,
 },
})
Ranking=module()
local checks=0
local function eq(actual,expected,what)
 checks+=1
 assert(actual==expected,what..": expected "..tostring(expected)..", got "..tostring(actual))
end
Ranking.write(user42,{Coins=100,Wins=1,Seconds=60})
eq(injected,true,"reentrant writes arrived while original Coins call was pending")
eq(#byBoard.Coins.history,3,"old/newest same-user writes plus separate player")
eq(#byBoard.Wins.history,3,"no intermediate same-user Wins write")
eq(#byBoard.Minutes.history,3,"no intermediate same-user Minutes write")
for _,id in ipairs({"Coins","Wins","Minutes"}) do
 local history=byBoard[id].history
 eq(history[1].key,"43","independent user can write while first user is blocked")
 eq(history[2].key,"42","original user finishes original snapshot")
 eq(history[3].key,"42","only latest buffered snapshot is flushed")
end
eq(byBoard.Coins.latest["42"],600,"latest Coins survive old write finishing late")
eq(byBoard.Wins.latest["42"],9,"latest Wins survive old write finishing late")
eq(byBoard.Minutes.latest["42"],10,"latest Minutes survive old write finishing late")
eq(byBoard.Coins.latest["43"],70,"separate player's Coins remain unaffected")
eq(byBoard.Wins.latest["43"],2,"separate player's Wins remain unaffected")
eq(byBoard.Minutes.latest["43"],3,"separate player's Minutes remain unaffected")
eq(warned,0,"no write failures under normal reentrancy")
Ranking.write(user42,{Coins=10,Wins=12,Seconds=120})
eq(byBoard.Coins.latest["42"],10,"a new completed session can legitimately spend coins")
eq(byBoard.Wins.latest["42"],12,"a new write can advance Wins")
eq(byBoard.Minutes.latest["42"],2,"a new write can update Minutes")
eq(#byBoard.Coins.history,4,"writer lock is released after successful write")
eq(#byBoard.Wins.history,4,"Wins lock is released")
eq(#byBoard.Minutes.history,4,"Minutes lock is released")
Ranking.write(user42,nil)
eq(#byBoard.Coins.history,4,"nil snapshots never write")
print("PASS: "..checks.." coalesced per-player leaderboard write assertions (published DataStore QA pending).")
