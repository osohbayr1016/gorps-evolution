local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local UserInputService=game:GetService("UserInputService")
local Pages=require(script.Parent.Pages)

local UI={}
UI.__index=UI
local COLORS={
 ink=Color3.fromRGB(23,33,39),
 surface=Color3.fromRGB(31,44,51),
 surface2=Color3.fromRGB(42,60,66),
 teal=Color3.fromRGB(88,210,170),
 cream=Color3.fromRGB(238,241,225),
 muted=Color3.fromRGB(168,192,189),
 stroke=Color3.fromRGB(83,112,112),
 gold=Color3.fromRGB(246,201,115),
}
local function radius(object,size)
 local c=Instance.new("UICorner")
 c.CornerRadius=UDim.new(0,size)
 c.Parent=object
end
local function stroke(object,alpha)
 local s=Instance.new("UIStroke")
 s.Thickness=1;s.Transparency=alpha or .45;s.Color=COLORS.stroke;s.Parent=object
end
local function text(parent,content,size,color,height)
 local lbl=Instance.new("TextLabel")
 lbl.Name="Text"
 lbl.Size=UDim2.new(1,-8,0,height or 28)
 lbl.Text=content
 lbl.TextColor3=color or COLORS.cream
 lbl.TextSize=size or 15
 lbl.Font=Enum.Font.Gotham
 lbl.TextWrapped=true
 lbl.TextXAlignment=Enum.TextXAlignment.Left
 lbl.BackgroundTransparency=1
 lbl.Parent=parent
 return lbl
end
local function action(parent,title,callback)
 local b=Instance.new("TextButton")
 b.Name="Action"
 b.Size=UDim2.new(1,-8,0,43)
 b.BackgroundColor3=COLORS.surface2
 b.TextColor3=COLORS.cream
 b.TextSize=14
 b.TextWrapped=true
 b.Font=Enum.Font.GothamMedium
 b.Text=title
 b.AutoButtonColor=false
 b.Parent=parent
 radius(b,8)
 b.MouseEnter:Connect(function()
  TweenService:Create(b,TweenInfo.new(.12),{BackgroundColor3=Color3.fromRGB(59,94,96)}):Play()
 end)
 b.MouseLeave:Connect(function()
  TweenService:Create(b,TweenInfo.new(.12),{BackgroundColor3=COLORS.surface2}):Play()
 end)
 b.Activated:Connect(callback)
 return b
end
local function labelContainer(parent)
 local bg=Instance.new("Frame")
 bg.BackgroundColor3=COLORS.ink
 bg.BackgroundTransparency=.08
 bg.BorderSizePixel=0
 bg.Parent=parent
 radius(bg,12)
 stroke(bg,.55)
 return bg
end
function UI.new(send)
 local self=setmetatable({send=send,tab="Ranch",profile=nil,trade={},rankings={},open=false},UI)
 local gui=Instance.new("ScreenGui")
 gui.Name="GorpsHUD";gui.IgnoreGuiInset=false;gui.ResetOnSpawn=false;gui.DisplayOrder=10
 gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
 gui.Parent=Players.LocalPlayer:WaitForChild("PlayerGui")
 self.gui=gui
 local top=labelContainer(gui)
 top.Name="StatusBar";top.Position=UDim2.fromOffset(16,15);top.Size=UDim2.new(1,-32,0,64)
 self.top=top
 local mark=Instance.new("TextLabel")
 mark.Name="Brand";mark.Size=UDim2.fromOffset(225,48)
 mark.Position=UDim2.fromOffset(17,7);mark.BackgroundTransparency=1
 mark.Text="GORPS  /  EVOLUTION";mark.Font=Enum.Font.GothamBold
 mark.TextColor3=COLORS.teal;mark.TextSize=19;mark.TextXAlignment=Enum.TextXAlignment.Left
 mark.Parent=top
 local status=Instance.new("TextLabel")
 status.Position=UDim2.fromOffset(245,10);status.Size=UDim2.new(1,-365,0,45)
 status.BackgroundTransparency=1;status.TextXAlignment=Enum.TextXAlignment.Left
 status.TextColor3=COLORS.cream;status.Font=Enum.Font.GothamMedium;status.TextSize=16
 status.Text="Entering Planet Verdant..."
 status.TextTruncate=Enum.TextTruncate.AtEnd;status.Parent=top
 self.status=status
 local open=Instance.new("TextButton")
 open.Size=UDim2.fromOffset(98,40);open.Position=UDim2.new(1,-108,0,12)
 open.Text="MENU  [G]";open.TextColor3=COLORS.ink
 open.TextSize=13;open.Font=Enum.Font.GothamBold
 open.BackgroundColor3=COLORS.teal;open.Parent=top
 radius(open,8)
 self.menuButton=open
 local panel=labelContainer(gui)
 panel.Name="GamePanel"
 panel.AnchorPoint=Vector2.new(1,0)
 panel.Position=UDim2.new(1,-16,0,90)
 panel.Size=UDim2.fromOffset(420,620)
 self.panel=panel
 panel.Visible=false
 local heading=text(panel,"YOUR ADVENTURE",14,COLORS.teal,24)
 heading.Position=UDim2.fromOffset(16,14);heading.Size=UDim2.new(1,-32,0,24)
 heading.Font=Enum.Font.GothamBold
 local nav=Instance.new("ScrollingFrame")
 nav.Name="Navigation"
 nav.Position=UDim2.fromOffset(12,49);nav.Size=UDim2.new(1,-24,0,46)
 nav.CanvasSize=UDim2.new(0,0,0,0)
 nav.AutomaticCanvasSize=Enum.AutomaticSize.X
 nav.ScrollBarThickness=0
 nav.ScrollingDirection=Enum.ScrollingDirection.X
 nav.BackgroundTransparency=1;nav.Parent=panel
 local nl=Instance.new("UIListLayout");nl.FillDirection=Enum.FillDirection.Horizontal
 nl.Padding=UDim.new(0,6);nl.Parent=nav
 self.tabButtons={}
 local tabs={"Ranch","Eggs","Creatures","Backpack","Crafting","Shop","Workers","Quests","Trade","Events","Rankings"}
 for _,tab in ipairs(tabs) do
  local btn=Instance.new("TextButton")
  btn.Name=tab;btn.Size=UDim2.fromOffset(math.max(80,#tab*9+24),38)
  btn.BackgroundColor3=COLORS.surface2
  btn.TextColor3=COLORS.cream
  btn.TextSize=13;btn.Font=Enum.Font.GothamMedium
  btn.Text=tab;btn.AutoButtonColor=false;btn.Parent=nav
  radius(btn,7)
  btn.Activated:Connect(function()
   self.tab=tab;self:render()
  end)
  self.tabButtons[tab]=btn
 end
 local separator=Instance.new("Frame")
 separator.Size=UDim2.new(1,-24,0,1);separator.Position=UDim2.fromOffset(12,102)
 separator.BackgroundColor3=COLORS.stroke;separator.BorderSizePixel=0;separator.Parent=panel
 local page=Instance.new("ScrollingFrame")
 page.Name="Content"
 page.BackgroundTransparency=1
 page.BorderSizePixel=0
 page.Position=UDim2.fromOffset(16,115)
 page.Size=UDim2.new(1,-32,1,-132)
 page.CanvasSize=UDim2.fromScale(0,0)
 page.AutomaticCanvasSize=Enum.AutomaticSize.Y
 page.ScrollBarThickness=4
 page.ScrollBarImageColor3=COLORS.teal
 page.Parent=panel
 local layout=Instance.new("UIListLayout")
 layout.Padding=UDim.new(0,9);layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Parent=page
 self.page=page
 local guide=labelContainer(gui)
 guide.Name="Guide";guide.Position=UDim2.new(0,16,1,-97)
 guide.Size=UDim2.fromOffset(345,78)
 local guideTitle=text(guide,"FIRST MISSION",13,COLORS.gold,22)
 guideTitle.Font=Enum.Font.GothamBold;guideTitle.Position=UDim2.fromOffset(14,8)
 guideTitle.Size=UDim2.new(1,-28,0,22)
 local guideText=text(guide,"Harvest trees, rocks or bushes with E. Feed your Gorp to grow stronger.",13,COLORS.cream,44)
 guideText.Position=UDim2.fromOffset(14,30);guideText.Size=UDim2.new(1,-28,0,42)
 self.guideText=guideText
 local dock=labelContainer(gui)
 dock.Name="QuickDock"
 dock.AnchorPoint=Vector2.new(.5,1)
 dock.Position=UDim2.new(.5,0,1,-15)
 dock.Size=UDim2.fromOffset(390,62)
 dock.BackgroundColor3=Color3.fromRGB(34,48,58)
 self.dock=dock
 local links={{"EGGS","Eggs"},{"PETS","Creatures"},{"RANCH","Ranch"},{"TASKS","Quests"}}
 for i,item in ipairs(links) do
  local shortcut=Instance.new("TextButton")
  shortcut.Name="Quick_"..item[2]
  shortcut.Size=UDim2.new(.25,-8,1,-14)
  shortcut.Position=UDim2.new((i-1)*.25,4,0,7)
  shortcut.BackgroundColor3=i==1 and Color3.fromRGB(249,204,105) or Color3.fromRGB(60,86,96)
  shortcut.TextColor3=i==1 and Color3.fromRGB(37,40,48) or COLORS.cream
  shortcut.TextSize=14
  shortcut.Font=Enum.Font.GothamBold
  shortcut.Text=item[1]
  shortcut.Parent=dock
  radius(shortcut,9)
  shortcut.Activated:Connect(function() self:openTab(item[2]) end)
 end
 local toast=labelContainer(gui)
 toast.Name="Toast";toast.AnchorPoint=Vector2.new(.5,0)
 toast.Position=UDim2.new(.5,0,0,90)
 toast.Size=UDim2.fromOffset(380,53)
 toast.Visible=false
 local toastLabel=text(toast,"",15,COLORS.cream,52)
 toastLabel.TextXAlignment=Enum.TextXAlignment.Center
 toastLabel.Position=UDim2.fromOffset(8,0)
 toastLabel.Size=UDim2.new(1,-16,1,0)
 self.toast=toast;self.toastLabel=toastLabel
 local camera=workspace.CurrentCamera
 local function resize()
  camera=workspace.CurrentCamera
  if not camera then return end
  local sz=camera.ViewportSize
  if sz.X<750 then
   top.Size=UDim2.new(1,-20,0,58);top.Position=UDim2.fromOffset(10,8)
   mark.Size=UDim2.fromOffset(132,40);mark.Text="GORPS";mark.TextSize=17
   status.Position=UDim2.fromOffset(145,8);status.Size=UDim2.new(1,-235,0,40)
   open.Size=UDim2.fromOffset(78,38);open.Position=UDim2.new(1,-85,0,10)
   panel.Position=UDim2.new(1,-10,0,73)
   panel.Size=UDim2.new(1,-20,1,-160)
   guide.Position=UDim2.new(0,10,1,-165)
   dock.Size=UDim2.new(1,-24,0,58)
   guide.Size=UDim2.new(1,-20,0,75)
  else
   top.Size=UDim2.new(1,-32,0,64);top.Position=UDim2.fromOffset(16,15)
   mark.Size=UDim2.fromOffset(225,48);mark.Text="GORPS  /  EVOLUTION";mark.TextSize=19
   status.Position=UDim2.fromOffset(245,10);status.Size=UDim2.new(1,-365,0,45)
   open.Size=UDim2.fromOffset(98,40);open.Position=UDim2.new(1,-108,0,12)
   panel.Position=UDim2.new(1,-16,0,90)
   panel.Size=UDim2.fromOffset(math.min(440,math.floor(sz.X*.36)),math.min(650,sz.Y-140))
   guide.Position=UDim2.new(0,16,1,-103)
   dock.Size=UDim2.fromOffset(390,62)
   guide.Size=UDim2.fromOffset(345,78)
  end
 end
 if camera then camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
 resize()
 local function toggle()
  self.open=not self.open
  panel.Visible=self.open
  open.Text=self.open and "CLOSE [G]" or "MENU [G]"
 end
 open.Activated:Connect(toggle)
 UserInputService.InputBegan:Connect(function(input,consumed)
  if not consumed and input.KeyCode==Enum.KeyCode.G then toggle() end
 end)
 return self
end
function UI:openTab(tab)
 if not self.tabButtons[tab] then return end
 self.tab=tab
 self.open=true
 self.panel.Visible=true
 self.menuButton.Text="CLOSE [G]"
 self:render()
end
function UI:showPickup(reward)
 if type(reward)~="table" or type(reward.resource)~="string" then return end
 local amount=tonumber(reward.amount)
 if not amount or amount<=0 then return end
 local pill=labelContainer(self.gui)
 pill.Name="PickupFeedback"
 pill.AnchorPoint=Vector2.new(.5,.5)
 pill.Position=UDim2.fromScale(.5,.68)
 pill.Size=UDim2.fromOffset(230,46)
 pill.BackgroundColor3=Color3.fromRGB(39,102,81)
 local copy=text(pill,"+"..amount.." "..string.upper(reward.resource),19,Color3.fromRGB(251,246,224),46)
 copy.TextXAlignment=Enum.TextXAlignment.Center
 copy.Font=Enum.Font.GothamBold
 copy.Size=UDim2.fromScale(1,1)
 TweenService:Create(pill,TweenInfo.new(.7,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),
  {Position=UDim2.fromScale(.5,.55),BackgroundTransparency=.38}):Play()
 task.delay(1.1,function()
  if pill.Parent then
   TweenService:Create(pill,TweenInfo.new(.2),{BackgroundTransparency=1}):Play()
   TweenService:Create(copy,TweenInfo.new(.2),{TextTransparency=1}):Play()
   task.delay(.25,function() pill:Destroy() end)
  end
 end)
end
function UI:showHatch(pet)
 if type(pet)~="table" or type(pet.species)~="string" then return end
 local overlay=Instance.new("Frame")
 overlay.Name="HatchReveal"
 overlay.Size=UDim2.fromScale(1,1)
 overlay.BackgroundColor3=Color3.fromRGB(9,25,34)
 overlay.BackgroundTransparency=.2
 overlay.ZIndex=50
 overlay.Parent=self.gui
 local egg=Instance.new("Frame")
 egg.Name="HatchingEgg";egg.AnchorPoint=Vector2.new(.5,.5)
 egg.Position=UDim2.fromScale(.5,.45);egg.Size=UDim2.fromOffset(95,126)
 egg.BackgroundColor3=Color3.fromRGB(255,224,151)
 egg.ZIndex=51
 egg.Parent=overlay
 radius(egg,48)
 local shine=Instance.new("UIGradient")
 shine.Rotation=40
 shine.Color=ColorSequence.new(Color3.fromRGB(255,247,208),Color3.fromRGB(238,168,106))
 shine.Parent=egg
 local title=text(overlay,"HATCHING...",23,COLORS.cream,55)
 title.AnchorPoint=Vector2.new(.5,.5)
 title.Position=UDim2.fromScale(.5,.68)
 title.Size=UDim2.new(.8,0,0,55)
 title.TextXAlignment=Enum.TextXAlignment.Center
 title.Font=Enum.Font.GothamBold
 title.ZIndex=52
 TweenService:Create(egg,TweenInfo.new(.48,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
  {Size=UDim2.fromOffset(175,220),Rotation=10}):Play()
 task.delay(.55,function()
  if not overlay.Parent then return end
  egg.BackgroundColor3=Color3.fromRGB(106,224,170)
  TweenService:Create(egg,TweenInfo.new(.25,Enum.EasingStyle.Back),
   {Size=UDim2.fromOffset(235,235),Rotation=0}):Play()
  title.Text=string.upper(pet.species).."  •  "..string.upper(pet.rarity or "COMMON")
 end)
 task.delay(2.7,function()
  if overlay.Parent then
   TweenService:Create(overlay,TweenInfo.new(.32),{BackgroundTransparency=1}):Play()
   task.delay(.35,function() overlay:Destroy() end)
  end
 end)
end
function UI:toastMessage(message)
 if not message or message=="" then return end
 self.toastLabel.Text=tostring(message)
 self.toast.Visible=true
 local token={}
 self.lastToast=token
 task.delay(3.2,function()
  if self.lastToast==token then self.toast.Visible=false end
 end)
end
function UI:update(profile,trade,message,rankings)
 if profile then self.profile=profile end
 if trade then self.trade=trade end
 if rankings then self.rankings=rankings end
 if message then self:toastMessage(message) end
 self:render()
end
function UI:render()
 local p=self.profile
 if not p then return end
 self.status.Text=string.format("◈ %s COINS   |   LV %d   |   %d PETS   |   RANCH %d",
  tostring(p.Coins),p.Level,#p.Pets,p.BaseLevel)
 local goals={
  "Go to a glowing resource and press E to collect it.",
  "Feed your Gorp in the Creatures tab to increase its level.",
  "Craft an item, hire a worker and grow your ranch.",
 }
 local count=p.Quests and (p.Quests.Gatherer or 0) or 0
 self.guideText.Text=count<5 and goals[1] or
  ((p.Quests.Provider or 0)<1 and goals[2] or goals[3])
 for tab,b in pairs(self.tabButtons) do
  b.BackgroundColor3=tab==self.tab and COLORS.teal or COLORS.surface2
  b.TextColor3=tab==self.tab and COLORS.ink or COLORS.cream
 end
 for _,child in ipairs(self.page:GetChildren()) do
  if not child:IsA("UIListLayout") then child:Destroy() end
 end
 Pages.render(self.page,self.tab,p,self.trade,self.send,text,action,self.rankings)
end
return UI
