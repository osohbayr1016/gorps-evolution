-- Distinct low-poly creature silhouettes made from real Roblox geometry.
-- These models are script-animated companions, not yet skinned/rigged MeshParts.
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
function Factory.create(pet,origin,parent)
 local def=C.Species[pet.species]
 if not def then return nil end
 local tier=table.find(C.Rarities,pet.rarity) or 1
 local scale=1+(pet.evolved or 0)*.2+(tier-1)*.08
 local base=Color3.fromRGB(unpack(def.color))
 local light=base:Lerp(Color3.fromRGB(255,245,214),.25)
 local dark=base:Lerp(Color3.fromRGB(35,50,64),.3)
 local model=Instance.new("Model")
 model.Name="Gorp_"..pet.species.."_"..pet.id
 local body=sphere(model,"Body",Vector3.new(4.9,4.3,5.1)*scale,
  Vector3.new(0,0,0),base)
 model.PrimaryPart=body
 sphere(model,"FacePlate",Vector3.new(3.7,3.1,1.6)*scale,
  Vector3.new(0,.25*scale,-1.75*scale),light)
 eyes(model,body,.75*scale,-2.65*scale,scale)
 sphere(model,"Nose",Vector3.new(.72,.45,.4)*scale,
  Vector3.new(0,-.55*scale,-2.75*scale),dark)
 feet(model,dark,scale,def.role=="Transport")
 if def.role=="Support" then
  horns(model,light,scale,-1,true);horns(model,light,scale,1,true)
  sphere(model,"CrystalCrest",Vector3.new(1.7,2.4,1.7)*scale,
   Vector3.new(0,2.85*scale,0),Color3.fromRGB(132,255,197),Enum.Material.Neon)
  for dir=-1,1,2 do
   sphere(model,"Cheek",Vector3.new(.65,.55,.28)*scale,
    Vector3.new(dir*1.6*scale,-.42*scale,-2.55*scale),
    Color3.fromRGB(244,173,177))
  end
 elseif def.role=="Assassin" then
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
  sphere(model,"Shell",Vector3.new(5.3,3.1,4.9)*scale,
   Vector3.new(0,1.5*scale,.75*scale),Color3.fromRGB(104,126,136))
  for i=-1,1 do
   cube(model,"ShellPlate",Vector3.new(1.3,.55,3.4)*scale,
    Vector3.new(i*1.5*scale,3.05*scale,1*scale),Color3.fromRGB(166,176,169))
  end
  horns(model,Color3.fromRGB(222,187,131),scale,-1,true)
  horns(model,Color3.fromRGB(222,187,131),scale,1,true)
 elseif def.role=="Miner" then
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
 if pet.evolved>0 then
  for side=-1,1,2 do
   sphere(model,"EvolutionGem",Vector3.new(.9,1.15,.65)*scale,
    Vector3.new(side*1.75*scale,1.45*scale,-1.6*scale),
    Color3.fromRGB(231,215,112),Enum.Material.Neon)
  end
 end
 label(model,body,pet.species,pet)
 model.Parent=parent or workspace:WaitForChild("ChaosGalaxy")
 model:PivotTo(CFrame.new(origin))
 return model
end
return Factory
