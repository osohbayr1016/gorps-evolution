-- Distinct low-poly creature silhouettes made from real Roblox geometry.
-- Original native-Part rigs. Motor6D joints support client procedural animation.
-- These are not imported/skinned MeshParts or published animation assets.
local C=require(game:GetService("ReplicatedStorage").Shared.Config)
local Factory={}
local function piece(parent,name,size,offset,color,shape,material)
 local p=Instance.new("Part")
 p.Name=name;p.Size=size;p.Anchored=true;p.CanCollide=false;p.CanTouch=false
 p.CanQuery=false;p.Massless=true
 p.CFrame=CFrame.new(offset)
 p.Color=color;p.Material=material or Enum.Material.SmoothPlastic
 if shape then p.Shape=shape end
 p.Parent=parent
 return p
end
local function sphere(parent,name,size,xyz,color,material)
 return piece(parent,name,size,xyz,color,Enum.PartType.Ball,material)
end
local function cube(parent,name,size,xyz,color,material)
 return piece(parent,name,size,xyz,color,Enum.PartType.Block,material)
end
local function label(model,anchor,name,pet)
 local gui=Instance.new("BillboardGui")
 gui.Name="CreatureName";gui.Adornee=anchor
 gui.Size=UDim2.fromOffset(190,40)
 gui.StudsOffsetWorldSpace=Vector3.new(0,3.5,0)
 gui.AlwaysOnTop=false;gui.MaxDistance=90
 gui.Parent=model
 local l=Instance.new("TextLabel")
 l.Size=UDim2.fromScale(1,1);l.BackgroundTransparency=1
 l.Text=name.."  Lv."..pet.level
 l.TextColor3=Color3.fromRGB(242,242,223)
 l.TextStrokeTransparency=.2;l.Font=Enum.Font.GothamBold;l.TextSize=16
 l.Parent=gui
end
local function eyes(model,primary,up,forward,scale)
 for _,dir in ipairs({-1,1}) do
  local ex=dir*1.18*scale
  sphere(model,"EyeWhite",Vector3.new(.91,1.1,.7)*scale,
   Vector3.new(ex,up,forward),Color3.fromRGB(246,245,230))
  sphere(model,"Pupil",Vector3.new(.45,.62,.27)*scale,
   Vector3.new(ex,up,forward-.41*scale),Color3.fromRGB(22,33,42))
  sphere(model,"EyeShine",Vector3.new(.17,.2,.12)*scale,
   Vector3.new(ex-.12*scale,up+.16*scale,forward-.57*scale),
   Color3.fromRGB(255,255,255),Enum.Material.Neon)
 end
end
local function feet(model,color,scale,long)
 for _,sx in ipairs({-1,1}) do
  for _,sz in ipairs({-1,1}) do
   sphere(model,"Paw",Vector3.new(1.15,.9,long and 1.6 or 1.1)*scale,
    Vector3.new(sx*1.2*scale,-1.45*scale,sz*1.25*scale),color)
  end
 end
end
local function horns(model,color,scale,sx,mul)
 sphere(model,"Horn",Vector3.new(.8,2.8,.9)*scale,Vector3.new(sx*2*scale,2.5*scale,.5*scale),
  color,Enum.Material.SmoothPlastic)
 if mul then
  sphere(model,"HornTip",Vector3.new(.45,1.5,.5)*scale,
   Vector3.new(sx*2.15*scale,4.4*scale,.5*scale),color)
 end
end
function Factory.build(pet)
 local def=C.Species[pet.species]
 if not def then return nil end
 local tier=table.find(C.Rarities,pet.rarity) or 1
 local scale=.72*(1+(pet.evolved or 0)*.2+(tier-1)*.08)
 local base=Color3.fromRGB(unpack(def.color))
 local light=base:Lerp(Color3.fromRGB(255,245,214),.25)
 local dark=base:Lerp(Color3.fromRGB(35,50,64),.3)
 local model=Instance.new("Model")
 model.Name="Gorp_"..pet.species.."_"..pet.id
 local proportions=({Gorp=Vector3.new(4.5,4.1,4.8),Bloom=Vector3.new(3.8,4.6,4.2),
  Shade=Vector3.new(3.5,3.3,6.1),Boulder=Vector3.new(5.6,3.7,5.7),
  Mole=Vector3.new(4.4,3.5,5.2),Carrier=Vector3.new(4.6,3.8,6.4),
  Dart=Vector3.new(3.5,3.8,4.3)})[pet.species]
 local body=sphere(model,"Body",proportions*scale,
  Vector3.new(0,0,0),base)
 model.PrimaryPart=body
 sphere(model,"FacePlate",Vector3.new(3.7,3.1,1.6)*scale,
  Vector3.new(0,.25*scale,-1.75*scale),light)
 eyes(model,body,.75*scale,-2.65*scale,scale)
 sphere(model,"Nose",Vector3.new(.72,.45,.4)*scale,
  Vector3.new(0,-.55*scale,-2.75*scale),dark)
 feet(model,dark,scale,def.role=="Transport")
 if pet.species=="Bloom" then
  -- A flower rabbit: tall ears and a radial petal crown, distinct from Gorp.
  for side=-1,1,2 do
   sphere(model,"RabbitEar",Vector3.new(1.1,4.5,1)*scale,
    Vector3.new(side*1.1*scale,3.3*scale,.2*scale),base)
   sphere(model,"EarInset",Vector3.new(.55,3,.3)*scale,
    Vector3.new(side*1.1*scale,3.4*scale,-.3*scale),light)
  end
  for i=1,6 do
   local angle=i*math.pi/3
   sphere(model,"Petal",Vector3.new(1.5,1.5,.8)*scale,
    Vector3.new(math.cos(angle)*2.25*scale,math.sin(angle)*2.25*scale,-1.8*scale),
    Color3.fromRGB(255,210,225))
  end
  sphere(model,"FlowerTail",Vector3.new(2,2,2)*scale,
   Vector3.new(0,.2*scale,2.7*scale),light)
 elseif def.role=="Support" then
  horns(model,light,scale,-1,true);horns(model,light,scale,1,true)
  sphere(model,"LeafTail",Vector3.new(1.5,2.5,2.9)*scale,
   Vector3.new(0,1.25*scale,3.1*scale),Color3.fromRGB(80,182,125))
  sphere(model,"ChestBib",Vector3.new(2.6,1.7,1.1)*scale,
   Vector3.new(0,-.9*scale,-1.95*scale),Color3.fromRGB(243,229,185))
  for side=-1,1,2 do
   sphere(model,"EarFrill",Vector3.new(2.2,1.05,1.8)*scale,
    Vector3.new(side*2.5*scale,1.5*scale,.5*scale),light)
  end
  sphere(model,"CrystalCrest",Vector3.new(1.7,2.4,1.7)*scale,
   Vector3.new(0,2.85*scale,0),Color3.fromRGB(132,255,197),Enum.Material.Neon)
  for dir=-1,1,2 do
   sphere(model,"Cheek",Vector3.new(.65,.55,.28)*scale,
    Vector3.new(dir*1.6*scale,-.42*scale,-2.55*scale),
    Color3.fromRGB(244,173,177))
  end
 elseif def.role=="Assassin" then
  for side=-1,1,2 do
   sphere(model,"FoxEar",Vector3.new(1.3,2.4,1)*scale,
    Vector3.new(side*1.4*scale,2.5*scale,-.5*scale),dark)
  end
  for side=-1,1,2 do
   sphere(model,"BackFin",Vector3.new(.8,1.7,2.3)*scale,
    Vector3.new(side*2.05*scale,1.9*scale,1.4*scale),dark)
   cube(model,"Claw",Vector3.new(.4,1.7,.6)*scale,
    Vector3.new(side*2.65*scale,-.55*scale,-1.9*scale),
    Color3.fromRGB(224,201,243),Enum.Material.Neon)
  end
  sphere(model,"ShadowTail",Vector3.new(1.25,1.25,3.6)*scale,
   Vector3.new(0,.5*scale,3.5*scale),dark)
 elseif def.role=="Tank" then
  sphere(model,"ArmoredTail",Vector3.new(1.5,1.3,3)*scale,
   Vector3.new(0,-.1*scale,3.3*scale),dark)
  sphere(model,"Shell",Vector3.new(5.3,3.1,4.9)*scale,
   Vector3.new(0,1.5*scale,.75*scale),Color3.fromRGB(104,126,136))
  for i=-1,1 do
   cube(model,"ShellPlate",Vector3.new(1.3,.55,3.4)*scale,
    Vector3.new(i*1.5*scale,3.05*scale,1*scale),Color3.fromRGB(166,176,169))
  end
  horns(model,Color3.fromRGB(222,187,131),scale,-1,true)
  horns(model,Color3.fromRGB(222,187,131),scale,1,true)
 elseif def.role=="Miner" then
  sphere(model,"MoleTail",Vector3.new(.65,.65,3)*scale,
   Vector3.new(0,-.6*scale,3*scale),light)
  sphere(model,"SafetyHat",Vector3.new(4.2,1.5,4.2)*scale,
   Vector3.new(0,2.25*scale,0),Color3.fromRGB(239,193,85))
  cube(model,"HatRim",Vector3.new(4.6,.45,3.5)*scale,
   Vector3.new(0,1.6*scale,-.45*scale),Color3.fromRGB(222,166,75))
  sphere(model,"WorkLight",Vector3.new(1.15,1.15,.55)*scale,
   Vector3.new(0,2.25*scale,-1.75*scale),Color3.fromRGB(251,246,162),Enum.Material.Neon)
  cube(model,"Backpack",Vector3.new(3,3,1.5)*scale,
   Vector3.new(0,.2*scale,2.65*scale),Color3.fromRGB(88,110,130))
 elseif def.role=="Transport" then
  sphere(model,"Saddle",Vector3.new(3.3,.75,3.2)*scale,
   Vector3.new(0,2.1*scale,.5*scale),Color3.fromRGB(103,76,89))
  for side=-1,1,2 do
   sphere(model,"SpeedWing",Vector3.new(3.2,.6,2.1)*scale,
    Vector3.new(side*2.7*scale,1.6*scale,.7*scale),
    Color3.fromRGB(249,226,151))
  end
  sphere(model,"LongTail",Vector3.new(1.5,1.6,4.2)*scale,
   Vector3.new(0,.4*scale,3.3*scale),dark)
 elseif def.role=="Ranged" then
  for side=-1,1,2 do
   sphere(model,"Wing",Vector3.new(3.5,1.2,4.2)*scale,
    Vector3.new(side*2.85*scale,.9*scale,1*scale),
    Color3.fromRGB(104,183,220))
  end
  for i=-1,1 do
   sphere(model,"Feather",Vector3.new(.85,2.2,.95)*scale,
    Vector3.new(i*1.5*scale,2.75*scale,1.4*scale),light)
  end
 end
 if (pet.evolved or 0)>0 then
  for side=-1,1,2 do
   sphere(model,"EvolutionGem",Vector3.new(.9,1.15,.65)*scale,
    Vector3.new(side*1.75*scale,1.45*scale,-1.6*scale),
    Color3.fromRGB(231,215,112),Enum.Material.Neon)
  end
 end
 -- Each moving appendage has its own joint; face details follow the head.
 local head=model:FindFirstChild("FacePlate")
 local jointIndex=0
 local headNames={EyeWhite=true,Pupil=true,EyeShine=true,Nose=true,Cheek=true,
  RabbitEar=true,EarInset=true,Petal=true,FoxEar=true}
 for _,item in ipairs(model:GetChildren()) do
  if item:IsA("BasePart") and item~=body then
   item.Anchored=false
   local moving=item==head or item.Name=="Paw" or string.find(item.Name,"Tail")
    or item.Name=="Wing" or item.Name=="SpeedWing"
   local anchor=headNames[item.Name] and head or body
   local joint=Instance.new(moving and "Motor6D" or "WeldConstraint")
   joint.Part0=anchor;joint.Part1=item
   if moving then
    jointIndex+=1
    joint.Name=item==head and "Head" or (item.Name..jointIndex)
    joint.C0=anchor.CFrame:ToObjectSpace(item.CFrame)
    joint.C1=CFrame.new()
    joint:SetAttribute("PoseKind",item==head and "Head" or
     (item.Name=="Paw" and "Paw" or (string.find(item.Name,"Tail") and "Tail" or "Wing")))
    joint:SetAttribute("Side",item.CFrame.Position.X<0 and -1 or 1)
    joint:SetAttribute("Front",item.CFrame.Position.Z<0 and 1 or -1)
    item.Name=joint.Name
   else joint.Name="DetailWeld" end
   joint.Parent=item
  end
 end
 model:SetAttribute("CreatureRig",true)
 model:SetAttribute("Species",pet.species)
 model:SetAttribute("PetId",pet.id)
 model:SetAttribute("RigScale",scale)
 label(model,body,pet.species,pet)
 return model
end
function Factory.create(pet,origin,parent)
 local model=Factory.build(pet)
 if not model then return nil end
 model.Parent=parent or workspace:WaitForChild("ChaosGalaxy")
 model:PivotTo(CFrame.new(origin))
 return model
end
return Factory

