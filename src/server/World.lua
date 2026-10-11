local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local C=require(ReplicatedStorage.Shared.Config)
local CreatureFactory=require(ReplicatedStorage.Shared.CreatureFactory)
local World={}
local folder
local worldReady=false
local gatherHandler=nil
local spots={}
local assigned={}
local companions={}
local animationElapsed=0
RunService.Heartbeat:Connect(function(dt)
 animationElapsed+=dt
 if animationElapsed<0.08 then return end
 animationElapsed=0
 for player,entry in pairs(companions) do
  local model=entry.model
  if model and model.Parent then
   local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
   local target=entry.home+Vector3.new(0,4,2)
   if root then target=root.Position-root.CFrame.LookVector*4+root.CFrame.RightVector*3+Vector3.new(0,1,0) end
   entry.current=entry.current:Lerp(target,0.2)
   local bob=math.sin(os.clock()*3+player.UserId)*0.35
   local tilt=math.sin(os.clock()*2+player.UserId)*0.08
   model:PivotTo(CFrame.new(entry.current+Vector3.new(0,bob,0))*CFrame.Angles(0,tilt,tilt*0.3))
  end
 end
end)
local function part(parent,name,size,cf,color,material,shape)
 local p=Instance.new("Part")
 p.Name=name;p.Anchored=true;p.CanCollide=true;p.Size=size;p.CFrame=cf
 p.Color=color;p.Material=material or Enum.Material.SmoothPlastic
 if shape then p.Shape=shape end
 p.Parent=parent;return p
end
local function sign(parent,anchor,words)
 local gui=Instance.new("BillboardGui")
 gui.Size=UDim2.fromOffset(180,50);gui.StudsOffsetWorldSpace=Vector3.new(0,4,0)
 gui.AlwaysOnTop=true;gui.Parent=anchor
 local txt=Instance.new("TextLabel");txt.Size=UDim2.fromScale(1,1)
 txt.BackgroundTransparency=1;txt.Text=words;txt.TextScaled=true
 txt.Font=Enum.Font.GothamBold;txt.TextStrokeTransparency=0.3;txt.TextColor3=Color3.new(1,1,1);txt.Parent=gui
end
-- Single shared resource-state machine: prompt, model and cooldown always agree.
local function setHarvestVisibility(model,visible,animate)
 local info=model:FindFirstChild("Interact")
 if not info then return end
 local storage={}
 -- Save visual origins once before first depletion. Never trust client-side hide state.
 for _,item in ipairs(model:GetDescendants()) do
  if item:IsA("BasePart") then
   local original=item:GetAttribute("HarvestOriginalTransparency")
   if original==nil then
    original=item.Transparency
    item:SetAttribute("HarvestOriginalTransparency",original)
    item:SetAttribute("HarvestOriginalCollide",item.CanCollide)
    item:SetAttribute("HarvestOriginalPosition",item.Position)
   end
   local pos=item:GetAttribute("HarvestOriginalPosition")
   table.insert(storage,{part=item,position=pos,alpha=original})
  end
 end
 for _,entry in ipairs(storage) do
  local part=entry.part
  part.CanCollide=visible and part:GetAttribute("HarvestOriginalCollide")==true
  local targetAlpha=visible and entry.alpha or 1
  local targetPos=visible and entry.position or (entry.position-Vector3.new(0,2.5,0))
  if visible then
   part.Position=entry.position-Vector3.new(0,2.5,0)
  end
  if animate then
   TweenService:Create(part,TweenInfo.new(visible and .42 or .23,Enum.EasingStyle.Back,
     visible and Enum.EasingDirection.Out or Enum.EasingDirection.In),
    {Transparency=targetAlpha,Position=targetPos}):Play()
  else
   part.Transparency=targetAlpha
   part.Position=targetPos
  end
 end
end
function World.make(onGather)
 if type(onGather)=="function" then gatherHandler=onGather end
 if worldReady and folder and folder.Parent then return folder end
 local planet=workspace:WaitForChild("PlanetVerdant",15)
 if not planet then error("Authored PlanetVerdant map missing. Run python3 scripts/build_world.py then let Rojo sync.") end
 local nodes=planet:FindFirstChild("ResourceNodes")
 local terrain=planet:FindFirstChild("TerrainAndPaths")
 if not nodes or not terrain or not terrain:FindFirstChild("Ground") then
  error("PlanetVerdant is incomplete: missing ResourceNodes or Ground")
 end
 folder=workspace:FindFirstChild("ChaosGalaxy")
 if not folder then
  folder=Instance.new("Folder")
  folder.Name="ChaosGalaxy"
  folder.Parent=workspace
 end
 for row=1,2 do
  for col=1,6 do
   table.insert(spots,Vector3.new((col-3.5)*89,1,-210+(row-1)*93))
  end
 end
 local count=0
 for _,node in ipairs(nodes:GetChildren()) do
  if node:IsA("Model") then
   local kind=string.match(node.Name,"^([A-Za-z]+)_")
   local base=node:FindFirstChild("Interact")
   if kind and C.Nodes[kind] and base and base:IsA("BasePart") then
    local prompt=base:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then prompt=Instance.new("ProximityPrompt");prompt.Parent=base end
    prompt.ActionText=kind=="Wild" and "Hunt" or "Harvest"
    prompt.ObjectText=kind
    prompt.MaxActivationDistance=13
    prompt.HoldDuration=.3
    prompt.RequiresLineOfSight=false
    local cooling=false
    node:SetAttribute("HarvestState","Ready")
    prompt.Triggered:Connect(function(player)
     if cooling or not gatherHandler then return end
     local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
     if not root or (root.Position-base.Position).Magnitude>19 then return end
     cooling=true
     prompt.Enabled=false
     local worked,awarded=pcall(gatherHandler,player,kind,base.Position)
     if not worked or not awarded then
      if not worked then warn("[Gorps World] Harvest failed:",awarded) end
      cooling=false
      prompt.Enabled=true
      return
     end
     node:SetAttribute("HarvestState","Depleted")
     setHarvestVisibility(node,false,true)
     task.delay(C.Nodes[kind][3],function()
      if not node.Parent or not prompt.Parent then return end
      setHarvestVisibility(node,true,true)
      node:SetAttribute("HarvestState","Ready")
      cooling=false
      prompt.Enabled=true
     end)
    end)
    count+=1
   end
  end
 end
 local village=planet:FindFirstChild("VillageHub")
 if village then
  for _,shop in ipairs(village:GetChildren()) do
   local tab=({
    TradingPost="Shop",CraftingWorkshop="Crafting",
    FarmerGuild="Workers",CreatureNursery="Eggs"
   })[shop.Name]
   local door=tab and shop:FindFirstChild("Door",true)
   if tab and door and door:IsA("BasePart") then
    local prompt=Instance.new("ProximityPrompt")
    prompt.ActionText="Open "..tab
    prompt.ObjectText=shop.Name
    prompt.MaxActivationDistance=17
    prompt.RequiresLineOfSight=false
    prompt.Parent=door
    prompt.Triggered:Connect(function(player)
     local remotes=ReplicatedStorage:FindFirstChild("GorpsRemotes")
     local signal=remotes and remotes:FindFirstChild("Update")
     if signal then signal:FireClient(player,{openTab=tab}) end
    end)
   end
  end
 end
 -- Hatchery landmark is readable from the village plaza.
 -- The player can also hatch immediately through the bottom HUD shortcut.
 local nest=Instance.new("Model")
 nest.Name="GorpsHatchery"
 nest.Parent=folder
 for i=1,2 do
  local x=45+i*7
  part(nest,"EggPod",Vector3.new(3.4,4.6,3.4),CFrame.new(x,4,-27),
   i==1 and Color3.fromRGB(253,211,129) or Color3.fromRGB(179,151,247),
   Enum.Material.SmoothPlastic,Enum.PartType.Ball)
  local plate=part(nest,"HatchStand",Vector3.new(5.2,1.1,5.2),CFrame.new(x,2,-27),
   Color3.fromRGB(141,116,104),Enum.Material.Wood,Enum.PartType.Cylinder)
  plate.CanCollide=false
 end
 local labelAnchor=part(nest,"HatcheryLabel",Vector3.new(1,1,1),CFrame.new(55,8,-27),
  Color3.fromRGB(249,208,133))
 labelAnchor.Transparency=1;labelAnchor.CanCollide=false
 sign(nest,labelAnchor,"GORPS HATCHERY")
 local ship=planet:FindFirstChild("UFO")
 if ship and ship:IsA("Model") then
  RunService.Heartbeat:Connect(function(dt)
   if ship.Parent then ship:PivotTo(ship:GetPivot()*CFrame.Angles(0,dt*0.12,0)) end
  end)
 end
 worldReady=true
 print("[Gorps World] Authored map loaded: "..count.." harvest nodes, 12 plots, UFO, static terrain.")
 return folder
end
function World.update(player,profile)
 local assignedSpot=assigned[player]
 if not assignedSpot then return end
 if assignedSpot.model then assignedSpot.model:Destroy() end
 companions[player]=nil
 local base=Instance.new("Model");base.Name="Base_"..player.UserId;base.Parent=folder
 assignedSpot.model=base
 local pos=assignedSpot.pos
 local half=20+profile.BaseLevel*3
 part(base,"Land",Vector3.new(half*2,0.7,half*2),CFrame.new(pos.X,1.5,pos.Z),Color3.fromRGB(99,133,101),Enum.Material.Grass)
 for _,side in ipairs({-1,1}) do
  for step=-half,half,8 do
   local offset=math.clamp(step,-half,half)
   part(base,"Fence",Vector3.new(2,6,2),CFrame.new(pos.X+offset,3,pos.Z+side*half),
    Color3.fromRGB(187,143,101),Enum.Material.Wood)
   part(base,"Fence",Vector3.new(2,6,2),CFrame.new(pos.X+side*half,3,pos.Z+offset),
    Color3.fromRGB(187,143,101),Enum.Material.Wood)
  end
 end
 part(base,"House",Vector3.new(14+profile.BaseLevel*2,10,12),CFrame.new(pos.X,5,pos.Z-10),
  Color3.fromRGB(206,194,167),Enum.Material.WoodPlanks)
 part(base,"Roof",Vector3.new(18+profile.BaseLevel*2,2,15),CFrame.new(pos.X,11,pos.Z-10),
  Color3.fromRGB(78,96,115),Enum.Material.Slate)
 part(base,"Door",Vector3.new(4,6,.45),CFrame.new(pos.X,3.5,pos.Z-16.2),
  Color3.fromRGB(91,116,118),Enum.Material.Wood)
 for _,side in ipairs({-1,1}) do
  part(base,"Window",Vector3.new(3.5,3,.5),CFrame.new(pos.X+side*5.8,6,pos.Z-16.3),
   Color3.fromRGB(126,218,229),Enum.Material.Glass)
  part(base,"Lantern",Vector3.new(1.5,2,1.5),CFrame.new(pos.X+side*7.3,5.8,pos.Z-16.8),
   Color3.fromRGB(242,209,130),Enum.Material.Neon,Enum.PartType.Ball)
 end
 for i=1,3 do
  part(base,"CropBed",Vector3.new(8,.55,3.1),CFrame.new(pos.X-12,1.5,pos.Z+2+i*4),
   Color3.fromRGB(120,90,74),Enum.Material.Ground)
  for j=1,4 do
   part(base,"Sprout",Vector3.new(1.1,2,1.1),CFrame.new(pos.X-15+j*1.7,2.5,pos.Z+2+i*4),
    Color3.fromRGB(89,189,121),Enum.Material.Grass,Enum.PartType.Ball)
  end
 end
 part(base,"WaterBowl",Vector3.new(4,.8,4),CFrame.new(pos.X+9,1.5,pos.Z+7),
  Color3.fromRGB(113,170,193),Enum.Material.Metal,Enum.PartType.Cylinder)
 part(base,"RanchStone",Vector3.new(8,1.2,4),CFrame.new(pos.X+9,1.4,pos.Z+13),
  Color3.fromRGB(173,165,147),Enum.Material.Slate)
 local marker=part(base,"Name",Vector3.new(3,3,3),CFrame.new(pos.X,5,pos.Z+half-4),Color3.fromRGB(73,159,169))
 marker.Transparency=1;marker.CanCollide=false
 sign(base,marker,player.DisplayName.."'s Ranch")
 local workerOffset=0
 for id,worker in pairs(profile.Workers) do
  for _=1,math.min(worker.count,5) do
   workerOffset+=1
   local wx=pos.X-half+6+(workerOffset%6)*5
   local wz=pos.Z+8+math.floor(workerOffset/6)*5
   local suit=id=="Farmer" and Color3.fromRGB(125,185,120)
    or (id=="Miner" and Color3.fromRGB(113,154,207) or Color3.fromRGB(207,156,112))
   part(base,id.."Body",Vector3.new(2.2,3,1.8),CFrame.new(wx,3,wz),suit,Enum.Material.Fabric)
   local head=part(base,id.."Head",Vector3.new(2.1,2.1,2.1),CFrame.new(wx,5.5,wz),
    Color3.fromRGB(225,195,157),Enum.Material.SmoothPlastic,Enum.PartType.Ball)
   sign(base,head,id)
  end
 end
 local petData
 for _,pet in ipairs(profile.Pets) do if pet.id==profile.ActiveId then petData=pet;break end end
 if petData then
  local origin=pos+Vector3.new(0,5,2)
  local model=CreatureFactory.create(petData,origin,base)
  if model then
   companions[player]={model=model,home=pos,current=origin}
  end
 end
end
function World.assign(player,p)
 local used={}
 for _,spot in pairs(assigned) do used[spot.index]=true end
 local index
 for _,i in ipairs({9,10,8,11,7,12,3,4,2,5,1,6}) do
  if not used[i] then index=i;break end
 end
 if not index then return false end
 assigned[player]={index=index,pos=spots[index]}
 World.update(player,p)
 return true
end
function World.spawn(player,character)
 local slot=assigned[player]
 if slot then
  local root=character:WaitForChild("HumanoidRootPart",10)
  if root then
   local start=slot.pos+Vector3.new(0,6,15)
   character:PivotTo(CFrame.lookAt(start,Vector3.new(0,6,0)))
  end
 end
end
function World.release(player)
 local spot=assigned[player]
 if spot and spot.model then spot.model:Destroy() end
 assigned[player]=nil
 companions[player]=nil
end
return World
