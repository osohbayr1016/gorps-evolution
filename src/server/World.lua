local CollectionService=game:GetService("CollectionService")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local C=require(ReplicatedStorage.Shared.Config)
local CreatureFactory=require(ReplicatedStorage.Shared.CreatureFactory)
local WorldTerrain=require(script.Parent.WorldTerrain)
local World={}
local folder
local worldReady=false
local gatherHandler=nil
local spots={}
local assigned={}
local companions={}
local function part(parent,name,size,cf,color,material,shape)
 local p=Instance.new("Part")
 p.Name=name;p.Anchored=true;p.CanCollide=true;p.Size=size;p.CFrame=cf
 p.Color=color;p.Material=material or Enum.Material.SmoothPlastic
 if shape then p.Shape=shape end
 p.Parent=parent;return p
end
local function decor(parent,name,size,cf,color,material,shape)
 local p=part(parent,name,size,cf,color,material,shape)
 p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
 return p
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
 -- Generate smooth *real voxel terrain* at server startup (not a fake Part
 -- terrain). Never block player boot if the engine rejects a terrain write.
 -- Editing Studio users can bake the exact same deterministic plan manually.
 task.defer(function()
  if not planet.Parent then return end
  local applied,okOrReason,detail=pcall(WorldTerrain.apply,planet)
  if not applied or not okOrReason then
   warn("[Gorps World] Voxel relief unavailable:",detail or okOrReason)
  end
 end)
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
 local active
 for _,pet in ipairs(profile.Pets) do if pet.id==profile.ActiveId then active=pet;break end end
 local workers={}
 for id,worker in pairs(profile.Workers) do table.insert(workers,id..":"..worker.count) end
 table.sort(workers)
 local signature=tostring(profile.BaseLevel).."/"..table.concat(workers,",").."/"
  ..(active and (active.id..":"..(active.evolved or 0)..":"..active.rarity) or "none")
 if assignedSpot.model and assignedSpot.signature==signature then
  local entry=companions[player]
  local gui=entry and entry.model:FindFirstChild("CreatureName")
  local text=gui and gui:FindFirstChildOfClass("TextLabel")
  if text and active then text.Text=active.species.."  Lv."..active.level end
  return
 end
 assignedSpot.signature=signature
 if assignedSpot.model then assignedSpot.model:Destroy() end
 companions[player]=nil
 local base=Instance.new("Model");base.Name="Base_"..player.UserId;base.Parent=folder
 assignedSpot.model=base
 local pos=assignedSpot.pos
 local front=assignedSpot.front
 local level=profile.BaseLevel
 local half=20+level*3
 local houseWidth=14+level*2
 part(base,"RanchGround",Vector3.new(half*2,0.7,half*2),CFrame.new(pos.X,1.5,pos.Z),
  Color3.fromRGB(104,143,105),Enum.Material.Grass)

 -- A real perimeter with a wide gate makes the ranch readable without trapping
 -- the avatar. Both rows mirror toward the shared ranch path.
 for _,side in ipairs({-1,1}) do
  for step=-half,half,10 do
   local offset=math.clamp(step,-half,half)
   part(base,"FencePost",Vector3.new(1.35,5.4,1.35),CFrame.new(pos.X+offset,3,pos.Z+side*half),
    Color3.fromRGB(153,111,75),Enum.Material.Wood)
   part(base,"FencePost",Vector3.new(1.35,5.4,1.35),CFrame.new(pos.X+side*half,3,pos.Z+offset),
    Color3.fromRGB(153,111,75),Enum.Material.Wood)
  end
 end
 part(base,"FenceRailBack",Vector3.new(half*2,0.75,0.8),CFrame.new(pos.X,3.2,pos.Z-front*half),
  Color3.fromRGB(173,132,90),Enum.Material.Wood)
 for _,side in ipairs({-1,1}) do
  part(base,"FenceRailSide",Vector3.new(0.8,0.75,half*2),CFrame.new(pos.X+side*half,3.2,pos.Z),
   Color3.fromRGB(173,132,90),Enum.Material.Wood)
  part(base,"FenceRailFront",Vector3.new(half-5,0.75,0.8),
   CFrame.new(pos.X+side*(half+5)/2,3.2,pos.Z+front*half),Color3.fromRGB(173,132,90),Enum.Material.Wood)
  part(base,"GatePost",Vector3.new(1.7,6.7,1.7),CFrame.new(pos.X+side*5,3.5,pos.Z+front*half),
   Color3.fromRGB(126,91,65),Enum.Material.Wood)
  decor(base,"GateBanner",Vector3.new(3.2,4.4,0.35),
   CFrame.new(pos.X+side*5,6.6,pos.Z+front*(half-.5)),
   side==-1 and Color3.fromRGB(107,171,129) or Color3.fromRGB(224,179,103),Enum.Material.Fabric)
 end

 -- Verdant homestead: a pitched roof, porch and path-facing facade replace the
 -- old box with a flat slab roof whose door faced away from arriving players.
 part(base,"HouseFrame",Vector3.new(houseWidth,10,12),CFrame.new(pos.X,5,pos.Z-front*10),
  Color3.fromRGB(211,196,165),Enum.Material.WoodPlanks)
 for _,side in ipairs({-1,1}) do
  part(base,"RoofPanel",Vector3.new(houseWidth/2+1.8,1.1,15),
   CFrame.new(pos.X+side*houseWidth/4,11.15,pos.Z-front*10)*CFrame.Angles(0,0,side*math.rad(23)),
   Color3.fromRGB(73,91,87),Enum.Material.Slate)
 end
 decor(base,"RoofRidge",Vector3.new(1.2,1.2,15.4),CFrame.new(pos.X,12.7,pos.Z-front*10),
  Color3.fromRGB(114,91,68),Enum.Material.Wood)
 part(base,"FrontPorch",Vector3.new(houseWidth+3,0.7,4.2),CFrame.new(pos.X,1.65,pos.Z-front*1.8),
  Color3.fromRGB(154,116,78),Enum.Material.WoodPlanks)
 part(base,"PorchStep",Vector3.new(7,0.7,2),CFrame.new(pos.X,1.25,pos.Z+front*1.1),
  Color3.fromRGB(177,139,96),Enum.Material.WoodPlanks)
 part(base,"Door",Vector3.new(4,6,0.45),CFrame.new(pos.X,4.1,pos.Z-front*3.8),
  Color3.fromRGB(82,112,103),Enum.Material.Wood)
 decor(base,"RanchLevelCrest",Vector3.new(3.4,3.4,0.5),CFrame.new(pos.X,8.5,pos.Z-front*3.5),
  level>=5 and Color3.fromRGB(206,151,236) or Color3.fromRGB(226,190,103),Enum.Material.Wood,
  Enum.PartType.Ball)
 for _,side in ipairs({-1,1}) do
  decor(base,"Window",Vector3.new(3.5,3,0.5),
   CFrame.new(pos.X+side*(houseWidth/2-2.4),6,pos.Z-front*3.7),
   Color3.fromRGB(132,203,210),Enum.Material.Glass)
  decor(base,"Lantern",Vector3.new(1.3,1.7,1.3),
   CFrame.new(pos.X+side*(houseWidth/2+.2),5.7,pos.Z-front*3.3),Color3.fromRGB(244,204,119),
   Enum.Material.Neon,Enum.PartType.Ball)
 end

 -- Farming stays on the west side; workers use a separate east-side yard, so
 -- hiring the first worker can no longer place them inside a crop bed.
 local cropColors={Color3.fromRGB(96,184,111),Color3.fromRGB(226,174,83),Color3.fromRGB(153,116,205)}
 for i=1,3 do
  local rowZ=pos.Z+front*(3+i*4)
  part(base,"CropBed_"..i,Vector3.new(9,0.55,3.1),CFrame.new(pos.X-12,1.5,rowZ),
   Color3.fromRGB(116,83,65),Enum.Material.Ground)
  decor(base,"SoilFurrow_"..i,Vector3.new(8.2,0.18,1.7),CFrame.new(pos.X-12,1.88,rowZ),
   Color3.fromRGB(86,62,52),Enum.Material.Ground)
  for j=1,3 do
   decor(base,"Crop_"..i.."_"..j,Vector3.new(1.2,1.7,1.2),
    CFrame.new(pos.X-15.2+j*2.1,2.7,rowZ),cropColors[i],Enum.Material.Grass,Enum.PartType.Ball)
  end
 end
 decor(base,"IrrigationChannel",Vector3.new(0.9,0.3,14.5),CFrame.new(pos.X-6.7,1.75,pos.Z+front*11),
  Color3.fromRGB(94,161,180),Enum.Material.Glass)
 decor(base,"WaterBowl",Vector3.new(0.8,4.2,4.2),
  CFrame.new(pos.X+2,1.65,pos.Z+front*15)*CFrame.Angles(0,0,math.rad(90)),
  Color3.fromRGB(105,157,177),Enum.Material.Metal,Enum.PartType.Cylinder)
 part(base,"FeedCrate",Vector3.new(5.5,2.2,3.7),CFrame.new(pos.X+2,2.3,pos.Z+front*19),
  Color3.fromRGB(164,123,79),Enum.Material.WoodPlanks)

 if level>=2 then
  part(base,"StorageSilo",Vector3.new(8,6.5,6.5),
   CFrame.new(pos.X+houseWidth/2+5,5,pos.Z-front*10)*CFrame.Angles(0,0,math.rad(90)),
   Color3.fromRGB(168,176,157),Enum.Material.Metal,Enum.PartType.Cylinder)
  decor(base,"SiloCap",Vector3.new(1.2,7.1,7.1),
   CFrame.new(pos.X+houseWidth/2+5,9.3,pos.Z-front*10)*CFrame.Angles(0,0,math.rad(90)),
   Color3.fromRGB(83,101,96),Enum.Material.Slate,Enum.PartType.Cylinder)
 end
 if level>=4 then
  local greenhouseX=pos.X-houseWidth/2-6
  for _,side in ipairs({-1,1}) do
   decor(base,"GreenhousePost",Vector3.new(0.7,6,0.7),
    CFrame.new(greenhouseX+side*5,4,pos.Z-front*8),Color3.fromRGB(109,129,115),Enum.Material.Metal)
  end
  decor(base,"GreenhouseCanopy",Vector3.new(11,0.55,7),CFrame.new(greenhouseX,7,pos.Z-front*8),
   Color3.fromRGB(158,211,196),Enum.Material.Glass)
 end
 if level>=6 then
  decor(base,"RanchBeacon",Vector3.new(2.6,2.6,2.6),CFrame.new(pos.X,15.2,pos.Z-front*10),
   Color3.fromRGB(213,161,237),Enum.Material.Neon,Enum.PartType.Ball)
 end
 local marker=part(base,"Name",Vector3.new(3,3,3),
  CFrame.new(pos.X,5,pos.Z+front*(half-4)),Color3.fromRGB(73,159,169))
 marker.Transparency=1;marker.CanCollide=false
 sign(base,marker,player.DisplayName.."'s Ranch")
 local workerOffset=0
 for id,worker in pairs(profile.Workers) do
  for _=1,math.min(worker.count,5) do
   workerOffset+=1
   local wx=pos.X+6+((workerOffset-1)%3)*5
   local wz=pos.Z+front*(2+math.floor((workerOffset-1)/3)*4.5)
   local suit=id=="Farmer" and Color3.fromRGB(125,185,120)
    or (id=="Miner" and Color3.fromRGB(113,154,207) or Color3.fromRGB(207,156,112))
   part(base,id.."Body",Vector3.new(2.2,3,1.8),CFrame.new(wx,3,wz),suit,Enum.Material.Fabric)
   local head=decor(base,id.."Head",Vector3.new(2.1,2.1,2.1),CFrame.new(wx,5.5,wz),
    Color3.fromRGB(225,195,157),Enum.Material.SmoothPlastic,Enum.PartType.Ball)
   sign(base,head,id)
  end
 end
 local petData
 for _,pet in ipairs(profile.Pets) do if pet.id==profile.ActiveId then petData=pet;break end end
 if petData then
  local origin=pos+Vector3.new(0,5,front*2)
  local model=CreatureFactory.create(petData,origin,base)
  if model then
   model:SetAttribute("OwnerUserId",player.UserId)
   CollectionService:AddTag(model,"GorpsCompanion")
   companions[player]={model=model}
  end
 end
end
-- Called only after server gameplay validation. Invalid actions have no success pose.
function World.react(player,action,petId,target)
 local entry=companions[player]
 if not entry or not entry.model.Parent then return end
 if petId and entry.model:GetAttribute("PetId")~=petId then return end
 entry.model:SetAttribute("PetActionTarget",target)
 entry.model:SetAttribute("PetAction",action)
 entry.model:SetAttribute("PetActionStarted",workspace:GetServerTimeNow())
end
function World.assign(player,p)
 local used={}
 for _,spot in pairs(assigned) do used[spot.index]=true end
 local index
 for _,i in ipairs({9,10,8,11,7,12,3,4,2,5,1,6}) do
  if not used[i] then index=i;break end
 end
 if not index then return false end
 assigned[player]={index=index,pos=spots[index],front=index<=6 and 1 or -1}
 World.update(player,p)
 return true
end
function World.spawn(player,character)
 local slot=assigned[player]
 if slot then
  local root=character:WaitForChild("HumanoidRootPart",10)
  if root then
   local start=slot.pos+Vector3.new(0,6,slot.front*15)
   character:PivotTo(CFrame.lookAt(start,slot.pos+Vector3.new(0,5,0)))
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

