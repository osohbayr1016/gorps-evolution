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
local wildCooldown={}
local function send(player,message)
 local p=Data.get(player)
 if p and player.Parent==Players then
  notify:FireClient(player,{profile=p,trade=Trade.status(player),message=message})
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
 if not p then return false end
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
 if action=="Rankings" then return true,"Rankings refreshed",Leaderboards.top() end
 if type(payload)~="table" then return false,"Invalid request" end
 local tradeOps={Invite=true,Join=true,Cancel=true,OfferMaterial=true,OfferPet=true,Accept=true}
 if tradeOps[action] then
  return Trade.action(player,action,payload,Data.get,function(who) changed(who,nil,true) end,
   function(who,msg) send(who,msg) end)
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
  local amount=E.tick(p,os.time())
  return true,amount>0 and ("Workers produced "..amount.." batches") or "Nothing collected yet (60s intervals)"
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
 if action~="State" and now-(cooldown[player] or 0)<0.2 then
  return {ok=false,message="Slow down"}
 end
 cooldown[player]=now
 local success,ok,message,rankings=pcall(act,player,action,payload or {})
 if not success then
  warn("[Gorps] Action failed:",action,ok)
  return {ok=false,message="Could not complete that action"}
 end
 if ok and action~="State" and action~="Rankings" then
  local visual=action=="Expand" or action=="SelectPet" or action=="Hatch" or action=="TradeUp"
   or action=="Feed" or action=="Evolve" or action=="Hire" or action=="Wheel" or action=="HatchEgg"
  changed(player,message,visual)
  if action=="Feed" or action=="Evolve" or action=="SelectPet" then
   World.react(player,action,type(payload)=="table" and payload.id or nil)
  end
  if action=="SelectPet" or action=="Evolve" then movement(player) end
 end
 return {ok=ok,message=message,profile=Data.get(player),trade=Trade.status(player),
  rankings=action=="Rankings" and rankings or nil,
  hatch=ok and action=="HatchEgg" and rankings or nil}
end
Players.PlayerAdded:Connect(function(player)
 task.spawn(function()
  local p=Data.load(player)
  if not p then return end
  E.tick(p,os.time())
  Data.change(player)
  if not World.assign(player,p) then
   player:Kick("Server is full of ranches. Please try another server.")
   return
  end
  player.CharacterAdded:Connect(function(character)
   World.spawn(player,character)
   movement(player)
  end)
  if player.Character then World.spawn(player,player.Character);movement(player) end
  send(player,"Welcome to Chaos Galaxy!")
 end)
end)
Players.PlayerRemoving:Connect(function(player)
 Trade.disconnect(player,function(who,msg) send(who,msg) end)
 World.release(player)
 local p=Data.get(player)
 if p then task.spawn(Leaderboards.write,player,R.copy(p)) end
 Data.unload(player)
 cooldown[player]=nil
 wildCooldown[player]=nil
end)

