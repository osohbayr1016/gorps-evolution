-- Real factory geometry/joints and pure pose math, using Lune's Roblox datatypes.
-- Headless inspection cannot prove Studio rendering, physics or visual quality.
local fs=require("@lune/fs")
local luau=require("@lune/luau")
local roblox=require("@lune/roblox")
-- Lune lacks engine Model:PivotTo. This shim only translates the authored geometry;
-- it does not simulate joints, physics, replication or the client update loop.
roblox.implementMethod("Model","PivotTo",function(model,cf)
 for _,part in ipairs(model:GetDescendants()) do
  if part:IsA("BasePart") then part.CFrame=cf*part.CFrame end
 end
end)
local checks=0
local function check(value,message)
 checks+=1
 assert(value,message)
end
local C=luau.load(fs.readFile("src/shared/Config.lua"))()
local environment={Instance=roblox.Instance,Vector3=roblox.Vector3,Color3=roblox.Color3,
 CFrame=roblox.CFrame,UDim2=roblox.UDim2,Enum=roblox.Enum,
 game={GetService=function() return {Shared={Config="Config"}} end},
 require=function(name) assert(name=="Config","unexpected dependency");return C end}
local Factory=luau.load(fs.readFile("src/shared/CreatureFactory.lua"),{environment=environment})()
local Pose=luau.load(fs.readFile("src/shared/CreaturePose.lua"),{environment=environment})()
local parent=roblox.Instance.new("Folder")
local proportions={}
for i,species in ipairs(C.SpeciesOrder) do
 local model=Factory.create({id=i,species=species,rarity=C.Species[species].rarity,
  level=1,evolved=0},roblox.Vector3.zero,parent)
 check(model:GetAttribute("CreatureRig")==true,"rig marker "..species)
 check(model:GetAttribute("PetId")==i,"stable pet identity")
 check(model.PrimaryPart.Anchored,"one anchored assembly root")
 proportions[tostring(model.PrimaryPart.Size)]=true
 local motors,paws,parts=0,0,0
 for _,item in ipairs(model:GetDescendants()) do
  if item:IsA("BasePart") then
   parts+=1
   check(not item.CanCollide and not item.CanTouch and not item.CanQuery,"cosmetic collision safety")
   check(item==model.PrimaryPart or not item.Anchored,"jointed details must move")
  elseif item:IsA("Motor6D") then
   motors+=1
   if item:GetAttribute("PoseKind")=="Paw" then paws+=1 end
   check(item.Part0~=nil and item.Part1~=nil,"joint has both endpoints")
   check(item.Part0==model.PrimaryPart,"animated joint rooted in body")
  elseif item:IsA("WeldConstraint") then
   check(item.Part0~=nil and item.Part1~=nil,"detail weld endpoints")
  end
 end
 check(motors>=6 and paws==4,"head, four paws and appendage joints "..species)
 check(parts<65,"per-creature part budget "..species)
 if species=="Bloom" then
  check(model:FindFirstChild("RabbitEar")~=nil and model:FindFirstChild("Petal")~=nil,"flower rabbit silhouette")
  check(model:FindFirstChild("Horn")==nil,"Bloom distinct from Gorp")
 end
 model:Destroy()
end
local count=0
for _ in pairs(proportions) do count+=1 end
check(count==7,"seven distinct species proportions")
check(Factory.create({species="Unknown"},roblox.Vector3.zero,parent)==nil,"invalid species rejected")
for action,duration in pairs(Pose.Duration) do
 check(Pose.state(action,-.01)=="Idle","future cue ignored")
 check(Pose.state(action,0)==action,"cue starts immediately")
 check(Pose.state(action,duration)=="Idle","cue expires exactly at duration")
 local state,progress=Pose.state(action,duration/2)
 check(state==action and progress==.5,"normalized pose progress")
 for _,kind in ipairs({"Head","Paw","Tail","Wing"}) do
  local cf=Pose.joint(kind,-1,1,10,1,action,progress)
  for _,number in ipairs({cf:GetComponents()}) do check(number==number and math.abs(number)<100,"finite bounded pose") end
 end
end
check(Pose.state("Invalid",0)=="Idle","unknown cue ignored")
check(Pose.bounce(0,0,"Feed",0)==0,"rest pose no drift")
check(math.abs(Pose.bounce(1,0,"Evolve",0)-Pose.bounce(1,0,"Evolve",1))<1e-6,"celebration returns to baseline")
check(Pose.joint("Paw",1,1,.15,1,"Idle",0)~=Pose.joint("Paw",1,1,.15,0,"Idle",0),"walking moves paws")
check(Pose.joint("Head",1,1,1,0,"Feed",.25)~=Pose.joint("Head",1,1,1,0,"Idle",0),"feeding nod differs from idle")
check(Pose.bounce(1,0,"Hunt",.5)>.5,"hunt has a visible lunge")
check(Pose.lunge("Hunt",.5)>1,"hunt moves toward validated target")
check(math.abs(Pose.lunge("Hunt",1))<1e-6 and Pose.lunge("Idle",.5)==0,"lunge returns to rest")
print("PASS creature rig and pose checks: "..checks)
