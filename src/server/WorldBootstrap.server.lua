-- Server bootstrap deliberately has NO DataStore, shop, trade or leaderboard dependencies.
-- If gameplay modules fail to initialize, Planet Verdant must still be visible.
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local status=ReplicatedStorage:FindFirstChild("GorpsStartupStatus")
if not status then
 status=Instance.new("StringValue")
 status.Name="GorpsStartupStatus"
 status.Parent=ReplicatedStorage
end
status.Value="BUILDING_WORLD"
local ok,err=pcall(function()
 local World=require(script.Parent.World)
 World.make()
end)
if ok then
 status.Value="WORLD_READY"
 print("[Gorps Bootstrap] Planet is ready before player data loads.")
else
 status.Value="WORLD_ERROR: "..tostring(err):sub(1,180)
 warn("[Gorps Bootstrap] World generation failed:",err)
 -- Emergency visible landmark so a broken bootstrap never looks like an empty project.
 local marker=Instance.new("Part")
 marker.Name="GorpsWorldFailureMarker"
 marker.Anchored=true
 marker.CanCollide=true
 marker.Material=Enum.Material.Neon
 marker.Color=Color3.fromRGB(231,72,84)
 marker.Size=Vector3.new(24,10,24)
 marker.Position=Vector3.new(0,7,55)
 marker.Parent=workspace
 local gui=Instance.new("BillboardGui")
 gui.Size=UDim2.fromOffset(350,100)
 gui.StudsOffsetWorldSpace=Vector3.new(0,9,0)
 gui.AlwaysOnTop=true
 gui.Parent=marker
 local label=Instance.new("TextLabel")
 label.Size=UDim2.fromScale(1,1)
 label.BackgroundColor3=Color3.fromRGB(32,30,38)
 label.TextColor3=Color3.fromRGB(255,255,255)
 label.TextScaled=true
 label.TextWrapped=true
 label.Text="GORPS STARTUP ERROR\nCheck the Server Output window"
 label.Parent=gui
end
