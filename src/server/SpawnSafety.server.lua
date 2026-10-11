-- Independent crash-safe spawn system: runs even if inventory/profile services fail.
-- The static Workspace.Baseplate and Workspace.SafetySpawn are embedded by Rojo.
local Players=game:GetService("Players")
local spawn=workspace:WaitForChild("SafetySpawn",10)
if not spawn or not spawn:IsA("SpawnLocation") then
 warn("[Gorps SpawnSafety] SafetySpawn missing. Rebuild the place from the latest main branch.")
 return
end
local function bindCharacter(player,character)
 task.spawn(function()
  local root=character:WaitForChild("HumanoidRootPart",10)
  if not root then return end
  -- Safe for both default spawn and later ranch teleport.
  while player.Parent==Players and player.Character==character and root.Parent do
   if root.Position.Y<-20 then
    root.AssemblyLinearVelocity=Vector3.zero
    root.AssemblyAngularVelocity=Vector3.zero
    character:PivotTo(spawn.CFrame*CFrame.new(0,spawn.Size.Y/2+5,0))
    warn("[Gorps SpawnSafety] Recovered player from void:",player.UserId)
   end
   task.wait(0.3)
  end
 end)
end
local function bindPlayer(player)
 player.RespawnLocation=spawn
 player.CharacterAdded:Connect(function(character) bindCharacter(player,character) end)
 if player.Character then bindCharacter(player,player.Character) end
end
Players.PlayerAdded:Connect(bindPlayer)
for _,player in ipairs(Players:GetPlayers()) do task.spawn(bindPlayer,player) end
print("[Gorps SpawnSafety] Static ground and neutral spawn are ready.")
