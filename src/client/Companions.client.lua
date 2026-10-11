-- All observers animate the same server-approved cues locally.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local CollectionService=game:GetService("CollectionService")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Pose=require(Shared:WaitForChild("CreaturePose"))
local rigs={}
local function register(model)
 if not model:IsA("Model") or rigs[model] then return end
 local entry={current=nil,joints={}}
 rigs[model]=entry
 local function addJoint(item)
  if item:IsA("Motor6D") then entry.joints[item]=true end
 end
 for _,item in ipairs(model:GetDescendants()) do addJoint(item) end
 entry.connection=model.DescendantAdded:Connect(addJoint)
end
CollectionService:GetInstanceAddedSignal("GorpsCompanion"):Connect(register)
for _,model in ipairs(CollectionService:GetTagged("GorpsCompanion")) do register(model) end
RunService.PreSimulation:Connect(function(dt)
 local camera=workspace.CurrentCamera
 local now=workspace:GetServerTimeNow()
 for model,entry in pairs(rigs) do
  if not model.Parent then entry.connection:Disconnect();rigs[model]=nil;continue end
  local owner=Players:GetPlayerByUserId(model:GetAttribute("OwnerUserId") or 0)
  local root=owner and owner.Character and owner.Character:FindFirstChild("HumanoidRootPart")
  local body=model.PrimaryPart
  if not root or not body then continue end
  if camera and (camera.CFrame.Position-root.Position).Magnitude>180 then continue end
  local scale=model:GetAttribute("RigScale") or .72
  local target=root.Position-root.CFrame.LookVector*4.5+root.CFrame.RightVector*3
  target=Vector3.new(target.X,root.Position.Y-3+1.9*scale,target.Z)
  if not entry.current or (entry.current-target).Magnitude>40 then entry.current=target end
  entry.current=entry.current:Lerp(target,1-math.exp(-dt*9))
  local moving=math.clamp(Vector3.new(root.AssemblyLinearVelocity.X,0,
   root.AssemblyLinearVelocity.Z).Magnitude/12,0,1)
  local action,progress=Pose.state(model:GetAttribute("PetAction"),
   now-(model:GetAttribute("PetActionStarted") or -100))
  local position=entry.current+Vector3.new(0,Pose.bounce(now,moving,action,progress)*scale,0)
  local look=root.CFrame.LookVector
  local targetPoint=model:GetAttribute("PetActionTarget")
  if (action=="Hunt" or action=="Gather") and typeof(targetPoint)=="Vector3" then
   local delta=Vector3.new(targetPoint.X-position.X,0,targetPoint.Z-position.Z)
   if delta.Magnitude>.1 then look=delta.Unit end
  end
  look=Vector3.new(look.X,0,look.Z)
  look=look.Magnitude>.01 and look.Unit or Vector3.new(0,0,-1)
  position+=look*Pose.lunge(action,progress)*scale
  model:PivotTo(CFrame.lookAt(position,position+look))
  for joint in pairs(entry.joints) do
   if not joint.Parent then entry.joints[joint]=nil else
    joint.Transform=Pose.joint(joint:GetAttribute("PoseKind"),joint:GetAttribute("Side") or 1,
     joint:GetAttribute("Front") or 1,now,moving,action,progress)
   end
  end
 end
end)
