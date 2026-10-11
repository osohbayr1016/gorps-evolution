-- Planet Verdant visual identity: warm daylight, soft atmospheric depth, gentle motion.
local Lighting=game:GetService("Lighting")
local RunService=game:GetService("RunService")

Lighting.Brightness=2.4
Lighting.ClockTime=14
Lighting.ExposureCompensation=.05
Lighting.Ambient=Color3.fromRGB(120,155,149)
Lighting.OutdoorAmbient=Color3.fromRGB(165,194,182)
Lighting.EnvironmentDiffuseScale=.65
Lighting.EnvironmentSpecularScale=.3

local sky=Lighting:FindFirstChild("GorpsAtmosphere")
if not sky then
 sky=Instance.new("Atmosphere")
 sky.Name="GorpsAtmosphere"
 sky.Density=.27
 sky.Offset=.16
 sky.Color=Color3.fromRGB(193,221,219)
 sky.Decay=Color3.fromRGB(125,168,160)
 sky.Glare=.15
 sky.Haze=1.4
 sky.Parent=Lighting
end
local grade=Lighting:FindFirstChild("GorpsColorGrade")
if not grade then
 grade=Instance.new("ColorCorrectionEffect")
 grade.Name="GorpsColorGrade"
 grade.Brightness=.03
 grade.Contrast=.10
 grade.Saturation=.09
 grade.TintColor=Color3.fromRGB(251,248,235)
 grade.Parent=Lighting
end
local bloom=Lighting:FindFirstChild("GorpsSoftBloom")
if not bloom then
 bloom=Instance.new("BloomEffect")
 bloom.Name="GorpsSoftBloom"
 bloom.Intensity=.15
 bloom.Size=18
 bloom.Threshold=1.6
 bloom.Parent=Lighting
end
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt
 if elapsed>=2 then
  elapsed=0
  local now=os.clock()
  Lighting.ClockTime=13.9+math.sin(now/400)*.7
 end
end)
