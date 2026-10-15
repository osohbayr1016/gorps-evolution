local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local C=require(ReplicatedStorage.Shared.Config)
local R=require(ReplicatedStorage.Shared.Rules)
local Adventure=require(ReplicatedStorage.Shared.Adventure)
local E=require(ReplicatedStorage.Shared.Economy)
local Data=require(script.Parent.Data)
local World=require(script.Parent.World)
local Trade=require(script.Parent.Trade)
local Leaderboards=require(script.Parent.Leaderboards)
local folder=Instance.new("Folder");folder.Name="GorpsRemotes";folder.Parent=ReplicatedStorage
local invoke=Instance.new("RemoteFunction");invoke.Name="Action";invoke.Parent=folder
local notify=Instance.new("RemoteEvent");notify.Name="Update";notify.Parent=folder
local cooldown={}
local statusCooldown={}
local wildCooldown={}
local TRADE_OPS={Invite=true,Join=true,Cancel=true,OfferMaterial=true,OfferPet=true,Accept=true}
local function tradeState(player)
 local state=Trade.status(player)
 state.available=Data.supportsTrading()
 return state
end
local function publicProfile(p)
 if not p then return nil end
 local snapshot=R.copy(p)
 snapshot.WorkerStatus=E.workerStatus(p,os.time())
 return snapshot
end
local function send(player,message)
 local p=Data.get(player)
 if p and player.Parent==Players then
  notify:FireClient(player,{profile=publicProfile(p),trade=tradeState(player),message=message})
 end
end
local function changed(player,message,visual)
 Data.change(player)
 local p=Data.get(player)
 if p and visual then World.update(player,p) end
 send(player,message)
end
local function movement(player)
 local p=Data.get(player)
 if not p then return end
 local companion=R.pet(p,p.ActiveId)
 local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
 if humanoid then
  local stats=companion and R.stats(companion)
  humanoid.WalkSpeed=stats and stats.role=="Transport" and math.clamp(stats.speed,18,30) or 16
 end
end
local function gather(player,kind,worldPosition)
 local p=Data.get(player)
 if not p or not Data.canMutate(player) then return false end
 local resource=C.Nodes[kind] and C.Nodes[kind][1]
 if not resource then return false end
 local before=p.Inventory[resource] or 0
 if kind=="Wild" then
  local now=os.clock()
  if now-(wildCooldown[player] or -100)<=15 then
   send(player,"Your companion needs a moment before the next hunt")
   return false
  end
  wildCooldown[player]=now
  local enemyLevel=math.clamp(math.floor(p.Level/3)+1,1,20)
  local won,message=Adventure.hunt(p,enemyLevel)
  if not won then
   send(player,message)
   return false
  end
  changed(player,message,false)
 else
  local ok,message=R.gather(p,kind)
  if not ok then send(player,message);return false end
  changed(player,message,false)
 end
 World.react(player,kind=="Wild" and "Hunt" or "Gather",nil,worldPosition)
 local earned=math.max(0,(p.Inventory[resource] or 0)-before)
 if earned>0 then
  notify:FireClient(player,{pickup={resource=resource,amount=earned,position=worldPosition}})
 end
 return true
end
World.make(gather)
local startup=ReplicatedStorage:FindFirstChild("GorpsStartupStatus")
if startup and startup:IsA("StringValue") then startup.Value="SERVER_ONLINE" end
Data.start()
Leaderboards.start(Data)
print("[Gorps Server] Gameplay remotes, planet and profile lifecycle are online.")
local function act(player,action,payload)
 local p=Data.get(player)
 if not p then return false,"Profile loading" end
 if action=="State" then return true,"Ready" end
 if action=="WorkerStatus" then return true,nil end
 if action=="Rankings" then return true,"Rankings refreshed",Leaderboards.top() end
 if type(payload)~="table" then return false,"Invalid request" end
 if not Data.canMutate(player) then return false,"Profile is busy; please retry" end
 if TRADE_OPS[action] then
  if not Data.supportsTrading() then
   return false,"Persistent player trading is temporarily closed to protect your inventory"
  end
  local settle=Data.isStudioTest() and nil or Data.settleTrade
  return Trade.action(player,action,payload,Data.get,function(who) changed(who,nil,true) end,
   function(who,msg) send(who,msg) end,settle)
 end
 if action=="HatchEgg" then
  local egg=C.Eggs[payload.id]
  if not egg then return false,"Unknown egg" end
  local total=0
  for _,entry in ipairs(egg.pool) do total+=entry.weight end
  return R.hatchEgg(p,payload.id,math.random(1,total))
 elseif action=="Feed" then return R.feed(p,payload.id)
 elseif action=="Evolve" then return R.evolve(p,payload.id)
 elseif action=="InfuseEgg" then return R.infuse(p)
 elseif action=="SelectPet" then
  if not R.pet(p,payload.id) then return false,"Creature not found" end
  p.ActiveId=payload.id;return true,"Companion selected"
 elseif action=="Expand" then return R.expand(p)
 elseif action=="Craft" then return E.craft(p,payload.id)
 elseif action=="Buy" then return E.buy(p,payload.id)
 elseif action=="Sell" then return E.sell(p,payload.id,payload.amount)
 elseif action=="Hire" then return E.hire(p,payload.id,os.time())
 elseif action=="Collect" then
  local now=os.time()
  local before=E.workerStatus(p,now)
  local amount=E.tick(p,now)
  if amount>0 then return true,"Workers produced "..amount.." batches" end
  if before.state=="empty" then return true,"Hire a ranch worker to begin production" end
  if before.state=="blocked" then
   return true,"Delivery expired: earn ◆ "..before.shortfall.." more before the next wage check"
  end
  return true,"Workers are still working - next delivery in "..math.ceil(before.nextIn or 60).."s"
 elseif action=="Claim" then return E.claim(p,payload.id)
 elseif action=="Wheel" then return E.wheel(p,os.time(),math.random(1,4))
 elseif action=="TradeUp" then return E.tradeUp(p,payload.rarity,C.SpeciesOrder[math.random(1,#C.SpeciesOrder)])
 elseif action=="Hatch" then
  if #p.Pets>=R.capacity(p) then return false,"Expand your ranch first" end
  if not R.spend(p,{EggIncubator=1,Crystal=1}) then return false,"Need incubator and crystal" end
  local species=C.SpeciesOrder[math.random(1,#C.SpeciesOrder)]
  local rarity=p.EggInfusion>=3 and "Epic" or (p.EggInfusion>=1 and "Rare" or C.Species[species].rarity)
  p.EggInfusion=0
  return R.addPet(p,species,rarity)
 elseif action=="UFO" then
  local t=os.date("!*t",os.time())
  if t.wday~=1 and t.wday~=7 then return false,"UFO trader is available Saturdays and Sundays (UTC)" end
  if #p.Pets>=R.capacity(p) then return false,"Your ranch is full" end
  if not R.spend(p,{Crystal=3,Iron=5}) then return false,"Need 3 crystals and 5 iron" end
  return R.addPet(p,C.SpeciesOrder[math.random(1,#C.SpeciesOrder)],"Rare")
 end
 return false,"Unknown action"
end
invoke.OnServerInvoke=function(player,action,payload)
 if type(action)~="string" or #action>32 then return {ok=false,message="Invalid action"} end
 local now=os.clock()
 if action=="WorkerStatus" and now-(statusCooldown[player] or 0)<0.2 then
  return {ok=false,message="Slow down"}
 elseif action~="State" and action~="WorkerStatus" and now-(cooldown[player] or 0)<0.2 then
  return {ok=false,message="Slow down"}
 end
 if action=="WorkerStatus" then statusCooldown[player]=now
 elseif action~="State" then cooldown[player]=now end
 local success,ok,message,rankings=pcall(act,player,action,payload or {})
 if not success then
  warn("[Gorps] Action failed:",action,ok)
  return {ok=false,message="Could not complete that action"}
 end
 if ok and action~="State" and action~="WorkerStatus" and action~="Rankings" and not TRADE_OPS[action] then
  local visual=action=="Expand" or action=="SelectPet" or action=="Hatch" or action=="TradeUp"
   or action=="Feed" or action=="Evolve" or action=="Hire" or action=="Wheel" or action=="HatchEgg"
  changed(player,message,visual)
  if action=="Feed" or action=="Evolve" or action=="SelectPet" then
   World.react(player,action,type(payload)=="table" and payload.id or nil)
  end
  if action=="SelectPet" or action=="Evolve" then movement(player) end
 end
 return {ok=ok,message=message,profile=publicProfile(Data.get(player)),trade=tradeState(player),
  rankings=action=="Rankings" and rankings or nil,
  hatch=ok and action=="HatchEgg" and rankings or nil}
end
-- Bind removal before joins; a player can join while World.make() is yielding.
-- Each Player instance gets one initialization token, even if it is both in
-- GetPlayers() and delivered by PlayerAdded during handler registration.
local starting={}
local function initializePlayer(player)
 if player.Parent~=Players or starting[player] then return end
 local token={}
 starting[player]=token
 task.spawn(function()
  if starting[player]~=token or player.Parent~=Players then return end
  local p=Data.load(player)
  if not p then
   if starting[player]==token then starting[player]=nil end
   return
  end
  -- DataStore:GetAsync can yield across PlayerRemoving. Dispose of a profile
  -- installed after departure rather than assigning an orphan ranch.
  if starting[player]~=token or player.Parent~=Players then
   if Data.get(player)==p then Data.unload(player) end
   return
  end
  E.tick(p,os.time())
  Data.change(player)
  if starting[player]~=token or player.Parent~=Players then return end
  if not World.assign(player,p) then
   player:Kick("Server is full of ranches. Please try another server.")
   return
  end
  player.CharacterAdded:Connect(function(character)
   if starting[player]~=token or player.Parent~=Players then return end
   World.spawn(player,character)
   if starting[player]==token and player.Parent==Players then movement(player) end
  end)
  if player.Character then
   World.spawn(player,player.Character)
   if starting[player]==token and player.Parent==Players then movement(player) end
  end
  if starting[player]==token and player.Parent==Players then
   send(player,"Welcome to Chaos Galaxy!")
   print("[Gorps Server] Player ready:",player.UserId)
  end
 end)
end
Players.PlayerRemoving:Connect(function(player)
 starting[player]=nil
 Trade.disconnect(player,function(who,msg) send(who,msg) end)
 World.release(player)
 local p=Data.get(player)
 if p then task.spawn(Leaderboards.write,player,R.copy(p)) end
 Data.unload(player)
 cooldown[player]=nil
 statusCooldown[player]=nil
 wildCooldown[player]=nil
end)


-- Catch Studio players that spawned before the world finished loading.
-- Event hook is attached first so a concurrent join cannot be missed.
Players.PlayerAdded:Connect(initializePlayer)
for _,player in ipairs(Players:GetPlayers()) do initializePlayer(player) end
