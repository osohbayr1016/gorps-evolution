-- True Roblox smooth-voxel terrain. The authored map, gameplay rewards and
-- 12 plot positions remain untouched. No Terrain:Clear or paid assets.
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Plan=require(ReplicatedStorage.Shared.TerrainPlan)
local WorldTerrain={}

local function obstaclesIn(planet)
 local obstacles={}
 local nodes=planet:FindFirstChild("ResourceNodes")
 if nodes then
  for _,node in ipairs(nodes:GetChildren()) do
   local root=node:FindFirstChild("Interact")
   if root and root:IsA("BasePart") then
    table.insert(obstacles,{x=root.Position.X,z=root.Position.Z,radius=16})
   end
  end
 end
 local forest=planet:FindFirstChild("ForestsAndWildlife")
 if forest then
  for _,tree in ipairs(forest:GetChildren()) do
   if tree:IsA("Model") and string.sub(tree.Name,1,11)=="CanopyTree_" then
    for _,part in ipairs(tree:GetChildren()) do
     if part:IsA("BasePart") and string.find(part.Name,"Trunk",1,true) then
      table.insert(obstacles,{x=part.Position.X,z=part.Position.Z,radius=9})
      break
     end
    end
   end
  end
 end
 return obstacles
end

function WorldTerrain.apply(planet)
 if not planet or planet.Name~="PlanetVerdant" then
  return false,"Missing authored world"
 end
 local terrain=workspace.Terrain
 if terrain:GetAttribute("GorpsTerrainVersion")==Plan.VERSION then
  return true,"already baked"
 end
 local writes,sites=Plan.build(obstaclesIn(planet))
 if sites<4 then
  return false,"Not enough safe voxel relief sites"
 end
 local succeeded,reason=pcall(function()
  for index,entry in ipairs(writes) do
   terrain:FillBall(Vector3.new(entry.x,entry.y,entry.z),entry.radius,
    Enum.Material[entry.material])
   -- Amortize voxel writes rather than stalling the join/bootstrap frame.
   if index%4==0 then task.wait() end
  end
 end)
 if not succeeded then
  -- Leave the version unset; retry may reapply the same idempotent fills.
  return false,tostring(reason)
 end
 terrain:SetAttribute("GorpsTerrainVersion",Plan.VERSION)
 print("[Gorps World] Applied smooth voxel terrain:",sites,"sites,",#writes,"bounded fills")
 return true,sites
end
return WorldTerrain
