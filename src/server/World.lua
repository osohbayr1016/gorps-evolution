local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local C=require(ReplicatedStorage.Shared.Config)
local World={}
local folder
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
function World.make(onGather)
 folder=Instance.new("Folder");folder.Name="ChaosGalaxy";folder.Parent=workspace
 part(folder,"Ground",Vector3.new(650,2,650),CFrame.new(0,-1,0),Color3.fromRGB(48,87,75),Enum.Material.Grass)
 part(folder,"LandingField",Vector3.new(100,0.4,36),CFrame.new(0,0.1,18),Color3.fromRGB(69,78,87),Enum.Material.Slate)
 for row=1,2 do
  for col=1,6 do
   local x=(col-3.5)*89
   local z=-210+(row-1)*93
   table.insert(spots,Vector3.new(x,0,z))
  end
 end
 local kinds={"Tree","Tree","Rock","Ore","Bush","Crystal","Fiber","Wild"}
 for i=1,70 do
  local kind=kinds[(i-1)%#kinds+1]
  local angle=i*2.3999632
  local distance=75+(i%6)*28
  local x=math.cos(angle)*distance
  local z=math.sin(angle)*distance+115
  z=math.clamp(z,-14,296)
  local node=Instance.new("Model");node.Name=kind.."_"..i;node.Parent=folder
  local base=part(node,"Interact",Vector3.new(5,5,5),CFrame.new(x,3,z),
   Color3.fromRGB(99,154,127),Enum.Material.SmoothPlastic,Enum.PartType.Ball)
  if kind=="Tree" then
   base.Shape=Enum.PartType.Block;base.Size=Vector3.new(3,10,3);base.Position=Vector3.new(x,5,z)
   base.Color=Color3.fromRGB(115,82,63)
   part(node,"Canopy",Vector3.new(11,11,11),CFrame.new(x,12,z),Color3.fromRGB(54,146,100),Enum.Material.Grass,Enum.PartType.Ball)
  elseif kind=="Wild" then
   base.Color=Color3.fromRGB(217,105,104)
   part(node,"Ear",Vector3.new(2,5,2),CFrame.new(x-2,7,z),base.Color,nil,Enum.PartType.Ball)
  elseif kind=="Ore" then base.Color=Color3.fromRGB(144,169,192)
  elseif kind=="Crystal" then base.Color=Color3.fromRGB(152,118,236);base.Material=Enum.Material.Neon
  elseif kind=="Bush" then base.Color=Color3.fromRGB(86,171,90)
  elseif kind=="Fiber" then base.Color=Color3.fromRGB(193,202,119)
  else base.Color=Color3.fromRGB(119,127,135) end
  local prompt=Instance.new("ProximityPrompt")
  prompt.ActionText=kind=="Wild" and "Hunt" or "Harvest"
  prompt.ObjectText=kind;prompt.MaxActivationDistance=12;prompt.HoldDuration=0.5;prompt.Parent=base
  local cooling=false
  prompt.Triggered:Connect(function(player)
   if cooling then return end
   local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
   if not root or (root.Position-base.Position).Magnitude>17 then return end
   cooling=true;prompt.Enabled=false
   onGather(player,kind)
   task.delay(C.Nodes[kind][3],function()
    if prompt.Parent then cooling=false;prompt.Enabled=true end
   end)
  end)
 end
 -- Rotating trade ship: event is open during each weekend UTC.
 local ufo=Instance.new("Model");ufo.Name="WeeklyUFO";ufo.Parent=folder
 local plate=part(ufo,"Saucer",Vector3.new(18,3,18),CFrame.new(0,22,0),
  Color3.fromRGB(111,205,217),Enum.Material.Metal,Enum.PartType.Cylinder)
 local dome=part(ufo,"Dome",Vector3.new(10,7,10),CFrame.new(0,26,0),
  Color3.fromRGB(152,120,240),Enum.Material.Glass,Enum.PartType.Ball)
 ufo.PrimaryPart=plate;sign(ufo,dome,"WEEKEND UFO")
 RunService.Heartbeat:Connect(function(dt)
  if ufo.Parent then ufo:PivotTo(ufo:GetPivot()*CFrame.Angles(0,dt*0.25,0)) end
 end)
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
 part(base,"Land",Vector3.new(half*2,0.7,half*2),CFrame.new(pos.X,0.2,pos.Z),Color3.fromRGB(99,133,101),Enum.Material.Grass)
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
 local marker=part(base,"Name",Vector3.new(3,3,3),CFrame.new(pos.X,5,pos.Z+half-4),Color3.fromRGB(73,159,169))
 marker.Transparency=1;marker.CanCollide=false
 sign(base,marker,player.DisplayName.."'s Ranch")
 local petData
 for _,pet in ipairs(profile.Pets) do if pet.id==profile.ActiveId then petData=pet;break end end
 if petData then
  local def=C.Species[petData.species]
  local color=Color3.fromRGB(unpack(def.color))
  local pet=Instance.new("Model");pet.Name="Companion_"..petData.species;pet.Parent=base
  local body=part(pet,"Body",Vector3.new(5,4,5),CFrame.new(pos.X,4,pos.Z+2),color,nil,Enum.PartType.Ball)
  pet.PrimaryPart=body
  for _,side in ipairs({-1,1}) do
   part(pet,"Eye",Vector3.new(0.8,1,0.8),CFrame.new(pos.X+side*1.1,4.5,pos.Z-0.3),
    Color3.fromRGB(24,32,42),nil,Enum.PartType.Ball)
   part(pet,"Ear",Vector3.new(1.5,3,1.5),CFrame.new(pos.X+side*1.6,7,pos.Z+2),
    color,nil,Enum.PartType.Ball)
  end
  local tier=table.find(C.Rarities,petData.rarity) or 1
  local variant=petData.evolved
  local scale=1+variant*0.18+(tier-1)*0.06
  body.Size=Vector3.new(5,4,5)*scale
  if def.role=="Tank" then
   part(pet,"Armor",Vector3.new(5*scale,2,4*scale),CFrame.new(pos.X,6,pos.Z+3),
    Color3.fromRGB(95,105,115),Enum.Material.Slate,Enum.PartType.Ball)
  elseif def.role=="Assassin" then
   for _,side in ipairs({-1,1}) do
    part(pet,"Blade",Vector3.new(1,4,1),CFrame.new(pos.X+side*3,4,pos.Z+2),
     Color3.fromRGB(222,181,246),Enum.Material.Neon)
   end
  elseif def.role=="Support" then
   part(pet,"Halo",Vector3.new(4,0.5,4),CFrame.new(pos.X,8.5,pos.Z+2),
    Color3.fromRGB(144,254,207),Enum.Material.Neon,Enum.PartType.Cylinder)
  elseif def.role=="Transport" then
   part(pet,"Saddle",Vector3.new(3,1,3),CFrame.new(pos.X,6,pos.Z+2),
    Color3.fromRGB(85,65,81),Enum.Material.Fabric)
  elseif def.role=="Miner" then
   part(pet,"Helmet",Vector3.new(3,1.5,3),CFrame.new(pos.X,6.8,pos.Z+2),
    Color3.fromRGB(247,206,93),Enum.Material.Metal)
   part(pet,"Headlamp",Vector3.new(1.3,1.3,1.3),CFrame.new(pos.X,7,pos.Z+0.6),
    Color3.fromRGB(250,239,173),Enum.Material.Neon,Enum.PartType.Ball)
  elseif def.role=="Ranged" then
   for _,side in ipairs({-1,1}) do
    part(pet,"Wing",Vector3.new(3,1,4),CFrame.new(pos.X+side*3,4.5,pos.Z+3),
     Color3.fromRGB(96,187,229),Enum.Material.SmoothPlastic)
   end
  end
  sign(pet,body,petData.species.." Lv."..petData.level)
  for _,piece in ipairs(pet:GetDescendants()) do
   if piece:IsA("BasePart") then piece.CanCollide=false end
  end
  companions[player]={model=pet,home=pos,current=body.Position}
 end
end
function World.assign(player,p)
 local used={}
 for _,spot in pairs(assigned) do used[spot.index]=true end
 local index
 for i=1,#spots do if not used[i] then index=i;break end end
 if not index then return false end
 assigned[player]={index=index,pos=spots[index]}
 World.update(player,p)
 return true
end
function World.spawn(player,character)
 local slot=assigned[player]
 if slot then
  local root=character:WaitForChild("HumanoidRootPart",10)
  if root then character:PivotTo(CFrame.new(slot.pos+Vector3.new(0,6,15))) end
 end
end
function World.release(player)
 local spot=assigned[player]
 if spot and spot.model then spot.model:Destroy() end
 assigned[player]=nil
 companions[player]=nil
end
return World
