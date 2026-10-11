-- Materialize the same original factory into editable Studio assets in ServerStorage.
-- No web/paid assets, animation uploads, credentials or engine simulation required.
local fs=require("@lune/fs")
local luau=require("@lune/luau")
local roblox=require("@lune/roblox")
local C=luau.load(fs.readFile("src/shared/Config.lua"))()
local Factory=luau.load(fs.readFile("src/shared/CreatureFactory.lua"),{environment={
 Instance=roblox.Instance,Vector3=roblox.Vector3,Color3=roblox.Color3,CFrame=roblox.CFrame,
 UDim2=roblox.UDim2,Enum=roblox.Enum,
 game={GetService=function() return {Shared={Config="Config"}} end},
 require=function(name) assert(name=="Config","unexpected dependency");return C end,
}})()
local shelf=roblox.Instance.new("Folder")
shelf.Name="CreatureRigs"
for index,species in ipairs(C.SpeciesOrder) do
 local model=Factory.build({id=index,species=species,rarity=C.Species[species].rarity,
  level=1,evolved=0})
 model.Name=species;model.Parent=shelf
 -- Author keyframe animations against these joints in Studio's Animation Editor.
 -- The runtime companions use procedural animation and need no uploaded animation IDs.
 local controller=roblox.Instance.new("AnimationController")
 controller.Name="AnimationController";controller.Parent=model
 local animator=roblox.Instance.new("Animator")
 animator.Parent=controller
end
fs.writeFile("world/CreatureRigs.rbxmx",roblox.serializeModel({shelf},true))
local roundtrip=roblox.deserializeModel(fs.readFile("world/CreatureRigs.rbxmx"))[1]
assert(#roundtrip:GetChildren()==7,"export must preserve all seven species")
for _,model in ipairs(roundtrip:GetChildren()) do
 assert(model.PrimaryPart and model:GetAttribute("CreatureRig"),"export must preserve rig root and attributes")
 local names={}
 local count=0
 for _,item in ipairs(model:GetDescendants()) do
  if item:IsA("Motor6D") then
   assert(item.Part0 and item.Part1,"serialized joint endpoints")
   assert(not names[item.Part1.Name],"unique animation part names")
   names[item.Part1.Name]=true;count+=1
  end
 end
 assert(count>=6,"serialized animation joints")
end
print("PASS: seven editable Motor6D rigs exported and serialization verified (not Studio QA)")
