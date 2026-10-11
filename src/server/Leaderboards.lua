-- Global ordered ranks are nonessential to starting the game.
-- Never access OrderedDataStore until a live, published server needs it.
local DataStoreService=game:GetService("DataStoreService")
local RunService=game:GetService("RunService")
local Players=game:GetService("Players")
local Ranking={}
local studio=RunService:IsStudio()
local stores={}
local cache={}
local names={}
local lastRefresh=0
local function store(id)
 if studio then return nil end
 if stores[id] then return stores[id] end
 local ok,s=pcall(function()
  return DataStoreService:GetOrderedDataStore("GorpsRank"..id.."_v1")
 end)
 if ok then stores[id]=s;return s end
 warn("[Gorps Rankings] Couldn't open "..id..":",s)
 return nil
end
function Ranking.write(player,p)
 if studio or not p then return end
 local values={Coins=p.Coins,Wins=p.Wins,Minutes=math.floor(p.Seconds/60)}
 for id,value in pairs(values) do
  local s=store(id)
  if s then
   local ok,err=pcall(function() s:SetAsync(tostring(player.UserId),value) end)
   if not ok then warn("[Gorps Rankings] Write failed:",id,err) end
  end
 end
end
function Ranking.top()
 if studio then return {Coins={},Wins={},Minutes={}} end
 if os.time()-lastRefresh<180 and next(cache) then return cache end
 local entries={}
 for _,id in ipairs({"Coins","Wins","Minutes"}) do
  entries[id]={}
  local s=store(id)
  if s then
   local ok,page=pcall(function() return s:GetSortedAsync(false,10) end)
   if ok then
    for rank,value in ipairs(page:GetCurrentPage()) do
     local name=names[value.key]
     if not name then
      local idNumber=tonumber(value.key)
      local success,found=pcall(function() return Players:GetNameFromUserIdAsync(idNumber) end)
      name=success and found or ("User "..value.key)
      names[value.key]=name
     end
     table.insert(entries[id],{rank=rank,name=name,score=value.value})
    end
   else
    warn("[Gorps Rankings] Read failed:",id,page)
    entries[id]=cache[id] or {}
   end
  end
 end
 cache=entries
 lastRefresh=os.time()
 return cache
end
function Ranking.start(Data)
 if studio then return end
 task.spawn(function()
  while task.wait(300) do
   for _,player in ipairs(Players:GetPlayers()) do
    local p=Data.get(player)
    if p then task.spawn(Ranking.write,player,p) end
   end
  end
 end)
end
return Ranking
