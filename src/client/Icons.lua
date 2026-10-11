-- Original resolution-independent Roblox UI icons built entirely from native Frames.
-- No borrowed game art, Toolbox assets, uploaded IDs or blurry emoji.
local Icons={}
local COLORS={
 gold=Color3.fromRGB(255,205,93),
 mint=Color3.fromRGB(122,222,163),
 paper=Color3.fromRGB(240,235,210),
 blue=Color3.fromRGB(125,188,244),
 lilac=Color3.fromRGB(193,156,237),
 brown=Color3.fromRGB(170,122,80),
 coral=Color3.fromRGB(243,145,128)
}
local function shape(parent,x,y,w,h,color,radius,rotation)
 local part=Instance.new("Frame")
 part.Name="Glyph"
 part.BorderSizePixel=0
 part.AnchorPoint=Vector2.new(.5,.5)
 part.Position=UDim2.fromScale(x,y)
 part.Size=UDim2.fromScale(w,h)
 part.BackgroundColor3=color
 part.Rotation=rotation or 0
 part.Parent=parent
 if radius then
  local corner=Instance.new("UICorner")
  corner.CornerRadius=UDim.new(radius,0)
  corner.Parent=part
 end
 return part
end
local function line(parent,x,y,w,h,color,rotation)
 return shape(parent,x,y,w,h,color,.5,rotation)
end
function Icons.create(parent,name,size,tint)
 local icon=Instance.new("Frame")
 icon.Name="Icon_"..name
 icon.BackgroundTransparency=1
 icon.BorderSizePixel=0
 icon.Size=UDim2.fromOffset(size or 29,size or 29)
 icon.ClipsDescendants=false
 icon.Parent=parent
 local a=tint or COLORS.paper
 if name=="Eggs" then
  shape(icon,.5,.54,.56,.76,COLORS.gold,.48)
  shape(icon,.37,.4,.11,.11,COLORS.paper,.5)
  shape(icon,.62,.65,.12,.12,COLORS.paper,.5)
  shape(icon,.57,.33,.09,.07,COLORS.paper,.5)
 elseif name=="Creatures" then
  shape(icon,.50,.66,.53,.39,COLORS.coral,.48)
  for _,p in ipairs({{.19,.34},{.40,.19},{.65,.19},{.82,.35}}) do
   shape(icon,p[1],p[2],.19,.24,COLORS.coral,.5)
  end
 elseif name=="Backpack" then
  shape(icon,.50,.60,.67,.68,COLORS.blue,.18)
  shape(icon,.50,.22,.37,.21,COLORS.paper,.5)
  shape(icon,.50,.61,.48,.28,Color3.fromRGB(65,111,169),.19)
  shape(icon,.50,.58,.13,.15,COLORS.gold,.1)
 elseif name=="Quests" then
  shape(icon,.49,.51,.62,.82,COLORS.paper,.13)
  for i=0,2 do
   shape(icon,.55,.33+i*.18,.35,.065,Color3.fromRGB(83,119,138),.5)
   shape(icon,.26,.33+i*.18,.09,.09,COLORS.mint,.5)
  end
 elseif name=="Ranch" then
  shape(icon,.5,.66,.65,.48,COLORS.brown,.05)
  line(icon,.34,.30,.55,.13,COLORS.gold,-39)
  line(icon,.67,.30,.55,.13,COLORS.gold,39)
  shape(icon,.5,.73,.21,.34,Color3.fromRGB(77,95,112),.05)
 elseif name=="Shop" then
  shape(icon,.5,.64,.66,.49,COLORS.paper,.07)
  shape(icon,.5,.37,.81,.22,COLORS.coral,.15)
  for _,x in ipairs({.26,.50,.74}) do
   shape(icon,x,.38,.12,.18,COLORS.gold,.12)
  end
  shape(icon,.6,.72,.24,.3,COLORS.blue,.04)
 elseif name=="Crafting" then
  line(icon,.45,.57,.12,.76,COLORS.brown,42)
  line(icon,.62,.32,.59,.17,COLORS.paper,-35)
  shape(icon,.80,.16,.21,.18,COLORS.blue,.12)
 elseif name=="Workers" then
  for _,x in ipairs({.31,.69}) do
   shape(icon,x,.36,.25,.25,COLORS.paper,.5)
   shape(icon,x,.68,.35,.36,COLORS.blue,.38)
  end
 elseif name=="Trade" then
  line(icon,.49,.34,.75,.15,COLORS.mint,0)
  line(icon,.49,.69,.75,.15,COLORS.gold,0)
  line(icon,.75,.26,.22,.13,COLORS.mint,-38)
  line(icon,.25,.77,.22,.13,COLORS.gold,-38)
 elseif name=="Events" then
  shape(icon,.5,.5,.59,.59,COLORS.lilac,.5)
  shape(icon,.5,.5,.33,.33,COLORS.gold,.5)
  shape(icon,.5,.15,.12,.23,COLORS.paper,.5)
  shape(icon,.84,.5,.19,.11,COLORS.paper,.5)
 elseif name=="Rankings" then
  for i,he in ipairs({.39,.73,.53}) do
   shape(icon,.17+i*.22,.77-he/2,.19,he,
    i==2 and COLORS.gold or COLORS.blue,.08)
  end
 elseif name=="Coins" then
  shape(icon,.5,.5,.74,.74,COLORS.gold,.5)
  shape(icon,.5,.5,.50,.50,Color3.fromRGB(192,132,57),.5)
  shape(icon,.5,.5,.29,.29,COLORS.gold,.5)
 elseif name=="Wood" then
  for _,x in ipairs({.35,.64}) do
   shape(icon,x,.54,.30,.58,COLORS.brown,.2,27)
   shape(icon,x-.12,.29,.19,.15,COLORS.gold,.5,27)
  end
 elseif name=="Stone" then
  shape(icon,.5,.6,.69,.56,Color3.fromRGB(141,155,159),.20,14)
  shape(icon,.61,.41,.36,.32,COLORS.paper,.20,-18)
 elseif name=="Iron" then
  shape(icon,.50,.55,.65,.50,COLORS.blue,.12,-15)
  shape(icon,.50,.55,.45,.29,Color3.fromRGB(60,106,139),.12,-15)
 elseif name=="Meat" then
  shape(icon,.46,.49,.54,.52,COLORS.coral,.43,-22)
  line(icon,.72,.72,.17,.50,COLORS.paper,-40)
  shape(icon,.84,.83,.19,.17,COLORS.paper,.5)
 elseif name=="Berries" then
  for _,v in ipairs({{.34,.55},{.65,.55},{.5,.75}}) do
   shape(icon,v[1],v[2],.31,.31,COLORS.coral,.5)
  end
  line(icon,.54,.28,.12,.3,COLORS.mint,-25)
 elseif name=="Crystal" then
  shape(icon,.50,.48,.45,.65,COLORS.lilac,.12,45)
  shape(icon,.49,.44,.23,.38,COLORS.paper,.08,45)
 elseif name=="Fiber" then
  for _,x in ipairs({.29,.47,.65}) do
   line(icon,x,.54,.12,.73,COLORS.mint,(x-.5)*80)
  end
 else
  shape(icon,.5,.5,.5,.5,a,.25)
 end
 return icon
end
return Icons
