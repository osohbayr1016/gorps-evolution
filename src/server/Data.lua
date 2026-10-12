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
local TradePersistence=require(script.Parent.TradePersistence)
local TradeSettlement=require(script.Parent.TradeSettlement)
local Data={}
local profiles={}
local versions={}
local dirty={}
local saving={}
local sessions={}
local unloading={}
local settling={}
local settlementFault={}
local tradeDiagnostics={}
local TRADE_DIAGNOSTIC_LIMIT=64
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
local function tradeStore(liveStore)
 local adapter={}
 function adapter:update(key,transform)
  local rejected
  local value=liveStore:UpdateAsync(key,function(old)
   local nextValue,reason=transform(old)
   rejected=reason
   return nextValue
  end)
  if value==nil then return nil,rejected end
  return value
 end
 function adapter:now() return os.time() end
 function adapter:diagnostic(kind,fields)
  local entry={at=os.time(),kind=tostring(kind):sub(1,40)}
  if type(fields)=="table" then
   if type(fields.id)=="string" then entry.id=fields.id:sub(1,44) end
   if type(fields.status)=="string" then entry.status=fields.status:sub(1,24) end
   if type(fields.reason)=="string" then entry.reason=fields.reason:sub(1,160) end
  end
  table.insert(tradeDiagnostics,entry)
  if #tradeDiagnostics>TRADE_DIAGNOSTIC_LIMIT then table.remove(tradeDiagnostics,1) end
 end
 return adapter
end
local function releaseClaim(liveStore,key,token)
 local ok,result=retry(function()
  return liveStore:UpdateAsync(key,function(old)
   return SessionPolicy.releaseRaw(old,token)
  end)
 end)
 return ok and SessionPolicy.confirms(result,token,true)
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
function Data.supportsTrading()
 return studio or Config.DurableTrades==true
end
function Data.get(player) return profiles[player] end
function Data.getTradeDiagnostics()
 return Rules.copy(tradeDiagnostics)
end
function Data.canMutate(player)
 return profiles[player]~=nil and not unloading[player] and not settling[player]
end
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
  local key="player_"..player.UserId
  local recovered,status,recoveryDetail=TradePersistence.recoverForLoad(
   tradeStore(liveStore),key,token,player.UserId,result
  )
  if not recovered then
   warn("[Gorps Data] Trade recovery failed:",player.UserId,status,recoveryDetail)
   releaseClaim(liveStore,key,token)
   player:Kick("Unable to safely recover a pending trade. Please retry.")
   return nil
  end
  saved=recovered
  sessions[player]=token
  if status~=TradePersistence.CLEAN then
   warn("[Gorps Data] Recovered persisted trade:",player.UserId,status)
  end
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
 if unloading[player] or settling[player] then return false end
 local p=profiles[player]
 if not p then return false end
 versions[player]=(versions[player] or 0)+1
 dirty[player]=true
 syncBoard(player,p)
 return true
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
   local nextValue,reason
   if release==true and type(old)=="table" and old._trade~=nil then
    nextValue,reason=SessionPolicy.releaseRaw(old,token)
   else
    nextValue,reason=SessionPolicy.save(old,snapshot,token,os.time(),release==true)
   end
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
 elseif not confirmed and rejected=="Trade recovery required" then
  warn("[Gorps Data] Autosave deferred for pending trade:",player.UserId)
 elseif not confirmed then
  warn("[Gorps Data] Stale session write rejected:",player.UserId,rejected)
  sessions[player]=nil
  if player.Parent==Players then
   player:Kick("This server lost ownership of your save and stopped to protect your progress.")
  end
 end
 return confirmed
end
local function waitForSave(player)
 local deadline=os.clock()+20
 while saving[player] and os.clock()<deadline do task.wait(.1) end
 return not saving[player]
end
local function rawRelease(player)
 local liveStore=getStore()
 local token=sessions[player]
 if not liveStore or not token then return false end
 local ok=releaseClaim(liveStore,"player_"..player.UserId,token)
 if ok then sessions[player]=nil end
 return ok
end
local function settlementFailure(left,right,reason)
 settlementFault[left]=true;settlementFault[right]=true
 warn("[Gorps Data] Durable trade needs recovery:",left.UserId,right.UserId,reason)
 for _,player in ipairs({left,right}) do
  if player.Parent==Players then
   player:Kick("Your trade is safely paused for recovery. Please rejoin.")
  end
 end
end
function Data.settleTrade(left,right,leftOffer,rightOffer)
 if studio or Config.DurableTrades~=true then
  return false,"Persistent player trading is not enabled"
 end
 if left==right or not Data.canMutate(left) or not Data.canMutate(right) then
  return false,"A player profile is busy"
 end
 local leftProfile=profiles[left]
 local rightProfile=profiles[right]
 local leftVersion=versions[left]
 local rightVersion=versions[right]
 local leftToken=sessions[left]
 local rightToken=sessions[right]
 if not leftToken or not rightToken then return false,"Save ownership is unavailable" end
 settling[left]=true;settling[right]=true
 if not waitForSave(left) or not waitForSave(right) then
  settlementFailure(left,right,"Timed out waiting for a profile save")
  return nil,"Trade recovery required"
 end
 -- Persist the exact gameplay snapshots used as receipt preconditions. Normal
 -- actions and the minute tick are blocked by settling[] throughout this span.
 if not Data.save(left,false) or not Data.save(right,false) then
  settlementFailure(left,right,"Could not establish durable preconditions")
  return nil,"Trade recovery required"
 end
 if profiles[left]~=leftProfile or profiles[right]~=rightProfile
  or versions[left]~=leftVersion or versions[right]~=rightVersion
  or sessions[left]~=leftToken or sessions[right]~=rightToken then
  settlementFailure(left,right,"Profile ownership changed during settlement")
  return nil,"Trade recovery required"
 end
 local liveStore=getStore()
 if not liveStore then
  settlementFailure(left,right,"Persistent store unavailable")
  return nil,"Trade recovery required"
 end
 local id=HttpService:GenerateGUID(false)
 local keys={
  receipt=TradePersistence.receiptKey(id),
  a={key="player_"..left.UserId,token=leftToken},
  b={key="player_"..right.UserId,token=rightToken},
 }
 local ok,status,snapshots,detail=TradeSettlement.execute(tradeStore(liveStore),keys,{
  id=id,createdAt=os.time(),
  a={userId=left.UserId,profile=leftProfile,offer=leftOffer},
  b={userId=right.UserId,profile=rightProfile,offer=rightOffer},
 })
 if ok==true and snapshots then
  profiles[left]=snapshots.a;profiles[right]=snapshots.b
  versions[left]=(versions[left] or 0)+1;versions[right]=(versions[right] or 0)+1
  dirty[left]=false;dirty[right]=false
  settling[left]=nil;settling[right]=nil
  syncBoard(left,snapshots.a);syncBoard(right,snapshots.b)
  return true,"Trade completed"
 end
 if ok==false then
  settling[left]=nil;settling[right]=nil
  return false,type(detail)=="string" and detail or "Trade was cancelled safely"
 end
 settlementFailure(left,right,detail or status or "Unknown durable outcome")
 return nil,"Trade recovery required"
end
function Data.unload(player)
 unloading[player]=true
 if not studio then
  if settlementFault[player] or settling[player] then rawRelease(player)
  else Data.save(player,true) end
 end
 profiles[player]=nil
 dirty[player]=nil
 versions[player]=nil
 saving[player]=nil
 sessions[player]=nil
 settling[player]=nil
 settlementFault[player]=nil
 unloading[player]=nil
end
function Data.start()
 task.spawn(function()
  while task.wait(60) do
   for player,p in pairs(profiles) do
    if not unloading[player] and not settling[player] then
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
    if settlementFault[player] or settling[player] then rawRelease(player)
    else Data.save(player,true) end
    jobs-=1
   end)
  end
  local deadline=os.clock()+24
  while jobs>0 and os.clock()<deadline do task.wait(.1) end
 end)
end
return Data
