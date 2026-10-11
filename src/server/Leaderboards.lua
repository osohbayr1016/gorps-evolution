local DataStoreService=game:GetService("DataStoreService")
local Players=game:GetService("Players")
local Leaderboards={}
local stores={
 Coins=DataStoreService:GetOrderedDataStore("GorpsRankCoins_v1"),
 Wins=DataStoreService:GetOrderedDataStore("GorpsRankWins_v1"),
 Minutes=DataStoreService:GetOrderedDataStore("GorpsRankMinutes_v1"),
}
local cache={}
local seen={}
local updated=0
function Leaderboards.write(player,p)
 if not p then return end
 local values={Coins=p.Coins,Wins=p.Wins,Minutes=math.floor(p.Seconds/60)}
 for id,store in pairs(stores) do
  local ok,err=pcall(function() store:SetAsync(tostring(player.UserId),values[id]) end)
  if not ok then warn("[Gorps] Rank save failed:",id,player.UserId,err) end
 end
end
function Leaderboards.top()
 if os.time()-updated<180 and next(cache) then return cache end
 local data={}
 local any=false
 for id,store in pairs(stores) do
  data[id]={}
  local ok,pages=pcall(function() return store:GetSortedAsync(false,10) end)
  if ok then
   any=true
   for rank,entry in ipairs(pages:GetCurrentPage()) do
    local name=seen[entry.key]
    if not name then
     local resolved,found=pcall(function() return Players:GetNameFromUserIdAsync(tonumber(entry.key)) end)
     name=resolved and found or ("User "..entry.key)
     seen[entry.key]=name
    end
    table.insert(data[id],{rank=rank,name=name,score=entry.value})
   end
  else
   warn("[Gorps] Failed reading leaderboard:",id,pages)
   data[id]=cache[id] or {}
  end
 end
 if any then cache=data;updated=os.time() end
 return cache
end
function Leaderboards.start(Data)
 task.spawn(function()
  while task.wait(300) do
   for _,player in ipairs(Players:GetPlayers()) do
    local p=Data.get(player)
    if p then task.spawn(Leaderboards.write,player,p) end
   end
  end
 end)
end
return Leaderboards
