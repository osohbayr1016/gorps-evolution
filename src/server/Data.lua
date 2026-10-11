local Players=game:GetService("Players")
local DataStoreService=game:GetService("DataStoreService")
local RunService=game:GetService("RunService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Rules=require(ReplicatedStorage.Shared.Rules)
local Config=require(ReplicatedStorage.Shared.Config)
local Store=DataStoreService:GetDataStore(Config.Store)
local Data={}
local profiles={}
local dirty={}
local saving={}
local versions={}
local function retry(callback)
 local last
 for attempt=1,3 do
  local success,result=pcall(callback)
  if success then return true,result end
  last=result
  if attempt<3 then task.wait(attempt*1.5) end
 end
 return false,last
end
function Data.get(player) return profiles[player] end
function Data.load(player)
 if profiles[player] then return profiles[player] end
 local ok,saved=retry(function() return Store:GetAsync("player_"..player.UserId) end)
 if not ok then
  if RunService:IsStudio() then
   warn("[Gorps] DataStore unavailable in Studio, using UNSAVED TEST PROFILE:",saved)
   saved=nil
  else
   player:Kick("Unable to load your saved progress. Please rejoin.")
   return nil
  end
 end
 local p=Rules.load(saved,os.time())
 profiles[player]=p;dirty[player]=false;versions[player]=0
 local stats=Instance.new("Folder");stats.Name="leaderstats";stats.Parent=player
 for _,name in ipairs({"Coins","Wins","Level","Minutes"}) do
  local stat=Instance.new("IntValue");stat.Name=name;stat.Value=name=="Minutes" and math.floor(p.Seconds/60) or (p[name] or 0);stat.Parent=stats
 end
 return p
end
function Data.change(player)
 local p=profiles[player]
 if not p then return end
 dirty[player]=true
 versions[player]=(versions[player] or 0)+1
 local board=player:FindFirstChild("leaderstats")
 if board then
  for _,name in ipairs({"Coins","Wins","Level"}) do
   local stat=board:FindFirstChild(name)
   if stat then stat.Value=p[name] or 0 end
  end
 end
end
function Data.save(player)
 local p=profiles[player]
 if not p then return true end
 local deadline=os.clock()+20
 while saving[player] and os.clock()<deadline do task.wait(0.1) end
 if saving[player] then return false end
 if not dirty[player] then return true end
 saving[player]=true
 -- Snapshot to avoid mutations while a yielding cloud request is in progress.
 local snapshot=Rules.copy(p)
 local version=versions[player]
 local ok,err=retry(function()
  return Store:UpdateAsync("player_"..player.UserId,function(_old)
   return snapshot
  end)
 end)
 saving[player]=nil
 if ok then
  -- Changes during the request must be persisted in the next cycle.
  if profiles[player]==p and versions[player]==version then dirty[player]=false end
 else
  warn("[Gorps] Save failed for ",player.UserId,err)
 end
 return ok
end
function Data.unload(player)
 Data.save(player)
 profiles[player]=nil;dirty[player]=nil;versions[player]=nil
end
function Data.start()
 task.spawn(function()
  while task.wait(60) do
   for player in pairs(profiles) do
    local p=profiles[player]
    p.Seconds+=60
    Data.change(player)
    task.spawn(Data.save,player)
   end
  end
 end)
 game:BindToClose(function()
  local pending=0
  for player in pairs(profiles) do
   pending+=1
   task.spawn(function()
    Data.save(player)
    pending-=1
   end)
  end
  local started=os.clock()
  while pending>0 and os.clock()-started<25 do task.wait(0.2) end
 end)
end
return Data
