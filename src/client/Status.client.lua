-- Independent player-visible diagnostics: works even if Main.client.lua fails to load.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local gui=Instance.new("ScreenGui")
gui.Name="GorpsStartupDiagnostic"
gui.ResetOnSpawn=false
gui.DisplayOrder=50
gui.Parent=Players.LocalPlayer:WaitForChild("PlayerGui")
local text=Instance.new("TextLabel")
text.AnchorPoint=Vector2.new(0.5,0)
text.Position=UDim2.fromScale(0.5,0.08)
text.Size=UDim2.new(.6,0,0,54)
text.BackgroundColor3=Color3.fromRGB(28,35,43)
text.BackgroundTransparency=0.06
text.TextColor3=Color3.fromRGB(229,242,242)
text.TextSize=17
text.TextWrapped=true
text.Font=Enum.Font.GothamBold
text.Text="GORPS EVOLUTION • Starting planet..."
text.Parent=gui
local rounding=Instance.new("UICorner")
rounding.CornerRadius=UDim.new(0,12)
rounding.Parent=text
local player=Players.LocalPlayer
local start=os.clock()
while player.Parent do
 local hud=player.PlayerGui:FindFirstChild("GorpsHUD")
 local status=ReplicatedStorage:FindFirstChild("GorpsStartupStatus")
 local stage=status and status.Value or "BOOTSTRAP_NOT_STARTED"
 if hud then
  gui:Destroy()
  return
 end
 if os.clock()-start>=4 then
  if string.sub(stage,1,11)=="WORLD_ERROR" then
   text.Text="GORPS WORLD ERROR • Open Studio View > Output (Server)\n"..stage
  elseif stage=="BOOTSTRAP_NOT_STARTED" then
   text.Text="GORPS SCRIPTS NOT RUNNING • Check ServerScriptService and View > Output"
  elseif stage=="WORLD_READY" then
   text.Text="PLANET READY • Gameplay server is still starting\nCheck Studio Server Output if this persists"
  elseif stage=="SERVER_ONLINE" then
   text.Text="SERVER ONLINE • HUD loading\nCheck StarterPlayerScripts if this persists"
  else
   text.Text="GORPS STARTUP: "..stage.."\nCheck Server Output if this persists"
  end
 end
 task.wait(1)
end
