-- Player progression remains playable in unpublished Roblox Studio places.
-- Studio uses isolated unsaved test profiles; published servers fail closed on storage errors.
local Players=game:GetService("Players")
local DataStoreService=game:GetService("DataStoreService")
local HttpService=game:GetService("HttpService")
local RunService=game:GetService("RunService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Rules=require(ReplicatedStorage.Shared.Rules)
local Config=require(ReplicatedStorage.Shared.Config)
local SessionPolicy=require(script.Parent.SessionPolicy)
local Data={}
local profiles={}
local versions={}
local dirty={}
local saving={}
local sessions={}
local unloading={}
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
local function claimSession(liveStore,key,token)
 local lastError
 for attempt=1,3 do
  local rejected
  local ok,result=pcall(function()
   return liveStore:UpdateAsync(key,function(old)
    local nextValue,reason=SessionPolicy.claim(old,token,os.time())
    rejected=reason
    return nextValue
   end)
  end)
  if ok and SessionPolicy.confirms(result,token,false) then
   return true,result
  end
  lastError=ok and (rejected or "Profile is active on another server") or result
  if attempt<3 then task.wait(1.5*attempt) end
 end
 return false,lastError
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
  local token=game.JobId..":"..HttpService:GenerateGUID(false)
  local ok,result=claimSession(liveStore,"player_"..player.UserId,token)
  if not ok then
   warn("[Gorps Data] Session claim failed:",player.UserId,result)
   if tostring(result):find("active on another server",1,true) then
    player:Kick("Your progress is still active on another server. Please retry in a moment.")
   else
    player:Kick("Unable to safely load saved progress. Please retry.")
   end
   return nil
  end
  saved=result
  sessions[player]=token
 else
  print("[Gorps Data] Local Studio test profile: saves are intentionally disabled.")
 end
 local p=Rules.load(saved,os.time())
 profiles[player]=p
 versions[player]=0;dirty[player]=false;unloading[player]=nil
 syncBoard(player,p)
 return p
end
function Data.change(player)
 if unloading[player] then return end
 local p=profiles[player]
 if not p then return end
 versions[player]=(versions[player] or 0)+1
 dirty[player]=true
 syncBoard(player,p)
end
function Data.save(player,release)
 if studio then return true end
 local p=profiles[player]
 if not p then return true end
 local deadline=os.clock()+20
 while saving[player] and os.clock()<deadline do task.wait(.1) end
 if saving[player] then return false end
 local liveStore=getStore()
 if not liveStore then return false end
 local token=sessions[player]
 if not token then return false end
 saving[player]=true
 local snapshot=Rules.copy(p)
 local version=versions[player]
 local rejected
 local ok,err=retry(function()
  return liveStore:UpdateAsync("player_"..player.UserId,function(old)
   local nextValue,reason=SessionPolicy.save(old,snapshot,token,os.time(),release==true)
   rejected=reason
   return nextValue
  end)
 end)
 saving[player]=nil
 local confirmed=ok and SessionPolicy.confirms(err,token,release==true)
 if confirmed and profiles[player]==p and versions[player]==version then
  dirty[player]=false
 end
 if confirmed and release then sessions[player]=nil end
 if not ok then
  warn("[Gorps Data] Save error:",player.UserId,err)
 elseif not confirmed then
  warn("[Gorps Data] Stale session write rejected:",player.UserId,rejected)
  sessions[player]=nil
  if player.Parent==Players then
   player:Kick("This server lost ownership of your save and stopped to protect your progress.")
  end
 end
 return confirmed
end
function Data.unload(player)
 unloading[player]=true
 if not studio then
  Data.save(player,true)
 end
 profiles[player]=nil
 dirty[player]=nil
 versions[player]=nil
 saving[player]=nil
 sessions[player]=nil
 unloading[player]=nil
end
function Data.start()
 task.spawn(function()
  while task.wait(60) do
   for player,p in pairs(profiles) do
    if not unloading[player] then
     p.Seconds+=60
     Data.change(player)
     if not studio then task.spawn(Data.save,player) end
    end
   end
  end
 end)
 game:BindToClose(function()
  if studio then return end
  local jobs=0
  for player in pairs(profiles) do
   jobs+=1
   task.spawn(function()
    unloading[player]=true
    Data.save(player,true)
    jobs-=1
   end)
  end
  local deadline=os.clock()+24
  while jobs>0 and os.clock()<deadline do task.wait(.1) end
 end)
end
return Data
