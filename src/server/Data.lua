-- Player progression remains playable in unpublished Roblox Studio places.
-- Studio uses isolated unsaved test profiles; published servers fail closed on storage errors.
local Players=game:GetService("Players")
local DataStoreService=game:GetService("DataStoreService")
local RunService=game:GetService("RunService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Rules=require(ReplicatedStorage.Shared.Rules)
local Config=require(ReplicatedStorage.Shared.Config)
local Data={}
local profiles={}
local versions={}
local dirty={}
local saving={}
local studio=RunService:IsStudio()
local store=nil
local function getStore()
 if studio then return nil end
 if store then return store end
 local ok,value=pcall(function() return DataStoreService:GetDataStore(Config.Store) end)
 if not ok then return nil,tostring(value) end
 store=value
 return store
end
local function retry(callback)
 local last
 for attempt=1,3 do
  local ok,value=pcall(callback)
  if ok then return true,value end
  last=value
  if attempt<3 then task.wait(1.5*attempt) end
 end
 return false,last
end
local function syncBoard(player,p)
 local board=player:FindFirstChild("leaderstats")
 if not board then
  board=Instance.new("Folder")
  board.Name="leaderstats"
  board.Parent=player
 end
 for _,name in ipairs({"Coins","Wins","Level","Minutes"}) do
  local item=board:FindFirstChild(name)
  if not item then
   item=Instance.new("IntValue")
   item.Name=name;item.Parent=board
  end
  item.Value=name=="Minutes" and math.floor(p.Seconds/60) or (p[name] or 0)
 end
end
function Data.isStudioTest() return studio end
function Data.get(player) return profiles[player] end
function Data.load(player)
 if profiles[player] then return profiles[player] end
 local saved=nil
 if not studio then
  local liveStore,err=getStore()
  if not liveStore then
   warn("[Gorps Data] Persistent store unavailable:",err)
   player:Kick("Unable to connect to player saves. Please retry.")
   return nil
  end
  local ok,result=retry(function() return liveStore:GetAsync("player_"..player.UserId) end)
  if not ok then
   warn("[Gorps Data] Load failed:",player.UserId,result)
   player:Kick("Unable to load saved progress. Please retry.")
   return nil
  end
  saved=result
 else
  print("[Gorps Data] Local Studio test profile: saves are intentionally disabled.")
 end
 local p=Rules.load(saved,os.time())
 profiles[player]=p
 versions[player]=0;dirty[player]=false
 syncBoard(player,p)
 return p
end
function Data.change(player)
 local p=profiles[player]
 if not p then return end
 versions[player]=(versions[player] or 0)+1
 dirty[player]=true
 syncBoard(player,p)
end
function Data.save(player)
 if studio then return true end
 local p=profiles[player]
 if not p then return true end
 local deadline=os.clock()+20
 while saving[player] and os.clock()<deadline do task.wait(.1) end
 if saving[player] then return false end
 if not dirty[player] then return true end
 local liveStore=getStore()
 if not liveStore then return false end
 saving[player]=true
 local snapshot=Rules.copy(p)
 local version=versions[player]
 local ok,err=retry(function()
  liveStore:UpdateAsync("player_"..player.UserId,function(_old)
   return snapshot
  end)
 end)
 saving[player]=nil
 if ok and profiles[player]==p and versions[player]==version then
  dirty[player]=false
 end
 if not ok then warn("[Gorps Data] Save error:",player.UserId,err) end
 return ok
end
function Data.unload(player)
 if not studio then
  local rounds=0
  repeat
   rounds+=1
   if not Data.save(player) then break end
  until not dirty[player] or rounds>=3
 end
 profiles[player]=nil
 dirty[player]=nil
 versions[player]=nil
 saving[player]=nil
end
function Data.start()
 task.spawn(function()
  while task.wait(60) do
   for player,p in pairs(profiles) do
    p.Seconds+=60
    Data.change(player)
    if not studio then task.spawn(Data.save,player) end
   end
  end
 end)
 game:BindToClose(function()
  if studio then return end
  local jobs=0
  for player in pairs(profiles) do
   jobs+=1
   task.spawn(function()
    Data.save(player)
    jobs-=1
   end)
  end
  local deadline=os.clock()+24
  while jobs>0 and os.clock()<deadline do task.wait(.1) end
 end)
end
return Data
