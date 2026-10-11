local Players=game:GetService("Players")
local GuiService=game:GetService("GuiService")
local TweenService=game:GetService("TweenService")
local UserInputService=game:GetService("UserInputService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local W=require(script.Parent.Widgets)
local Icons=require(script.Parent.Icons)
local Pages=require(script.Parent.Pages)
local Config=require(ReplicatedStorage.Shared.Config)
local Onboarding=require(ReplicatedStorage.Shared.Onboarding)

local UI={}
UI.__index=UI
local C=W.colors
local TABS={
 {"Ranch","HOME"},{"Eggs","EGGS"},{"Creatures","PETS"},{"Backpack","BAG"},
 {"Crafting","CRAFT"},{"Shop","SHOP"},{"Workers","CREW"},
 {"Quests","QUESTS"},{"Trade","TRADE"},{"Events","EVENTS"},{"Rankings","RANKS"},
}
local SHORTCUTS={{"EGGS","Eggs","1"},{"PETS","Creatures","2"},
 {"BAG","Backpack","3"},{"QUESTS","Quests","4"},{"RANCH","Ranch","5"}}
local function framed(parent,name,background)
 local frame=Instance.new("Frame")
 frame.Name=name;frame.BackgroundColor3=background or C.deep
 frame.BorderSizePixel=0;frame.Parent=parent
 W.round(frame,14);W.border(frame)
 return frame
end
local function absoluteText(parent,text,size,color)
 local t=Instance.new("TextLabel")
 t.BackgroundTransparency=1;t.Text=text;t.TextColor3=color or C.light
 t.Font=Enum.Font.GothamBold;t.TextSize=size;t.TextXAlignment=Enum.TextXAlignment.Left
 t.TextTruncate=Enum.TextTruncate.AtEnd;t.Parent=parent
 return t
end
local function noWorldBlocking(gui)
 local overlay=Instance.new("Frame")
 overlay.Name="DimWorld"
 overlay.Size=UDim2.fromScale(1,1)
 overlay.BackgroundColor3=Color3.fromRGB(7,14,25)
 overlay.BackgroundTransparency=.46
 overlay.BorderSizePixel=0
 overlay.Visible=false
 overlay.Parent=gui
 return overlay
end
function UI.new(send)
 local self=setmetatable({
  send=send,tab="Ranch",open=false,profile=nil,trade={},rankings={},
  toastSerial=0,viewportWidth=1200
 },UI)
 local gui=Instance.new("ScreenGui")
 gui.Name="GorpsHUD"
 gui.IgnoreGuiInset=false
 gui.ResetOnSpawn=false
 gui.DisplayOrder=12
 gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
 gui.Parent=Players.LocalPlayer:WaitForChild("PlayerGui")
 self.gui=gui
 local brand=framed(gui,"Brand",C.deep)
 brand.Position=UDim2.fromOffset(16,74)
 brand.Size=UDim2.fromOffset(220,51)
 local logo=absoluteText(brand,"GORPS",23,C.gold)
 logo.Position=UDim2.fromOffset(15,5);logo.Size=UDim2.fromOffset(100,29)
 local descriptor=absoluteText(brand,"EVOLUTION  /  VERDANT",10,C.muted)
 descriptor.Position=UDim2.fromOffset(15,31);descriptor.Size=UDim2.fromOffset(196,13)
 local wallet=framed(gui,"Wallet",C.deep)
 wallet.AnchorPoint=Vector2.new(1,0)
 wallet.Position=UDim2.new(1,-16,0,74);wallet.Size=UDim2.fromOffset(190,51)
 local coin=absoluteText(wallet,"0",20,C.gold)
 local coinIcon=Icons.create(wallet,"Coins",29)
 coinIcon.Position=UDim2.fromOffset(11,6)
 coin.Position=UDim2.fromOffset(47,5);coin.Size=UDim2.fromOffset(125,25)
 local line=absoluteText(wallet,"LEVEL 1  ·  1/3 GORPS",11,C.muted)
 line.Position=UDim2.fromOffset(13,32);line.Size=UDim2.fromOffset(164,15)
 self.wallet=coin;self.levelLine=line;self.walletContainer=wallet
 local objective=framed(gui,"Mission",Color3.fromRGB(24,39,54))
 objective.Position=UDim2.fromOffset(16,137)
 objective.Size=UDim2.fromOffset(262,132)
 self.objective=objective
 local objectiveTitle=absoluteText(objective,"NEXT STEP",12,C.gold)
 objectiveTitle.Position=UDim2.fromOffset(13,9);objectiveTitle.Size=UDim2.fromOffset(226,20)
 local objectiveBody=absoluteText(objective,"Collect materials 0/15",14,C.light)
 objectiveBody.Position=UDim2.fromOffset(13,31);objectiveBody.Size=UDim2.fromOffset(238,23)
 self.objectiveBody=objectiveBody
 local objectiveDetail=absoluteText(objective,"Follow the mint trail north",11,C.muted)
 objectiveDetail.Position=UDim2.fromOffset(13,55);objectiveDetail.Size=UDim2.fromOffset(238,18)
 self.objectiveDetail=objectiveDetail
 local objectiveLine=Instance.new("Frame")
 objectiveLine.Name="MissionProgress";objectiveLine.Position=UDim2.fromOffset(13,78)
 objectiveLine.Size=UDim2.fromOffset(236,4);objectiveLine.BackgroundColor3=Color3.fromRGB(72,89,107)
 objectiveLine.BorderSizePixel=0;objectiveLine.Parent=objective
 W.round(objectiveLine,4)
 local objectiveFill=Instance.new("Frame")
 objectiveFill.BackgroundColor3=C.mint;objectiveFill.Size=UDim2.fromScale(0,1)
 objectiveFill.BorderSizePixel=0;objectiveFill.Parent=objectiveLine
 W.round(objectiveFill,4);self.objectiveFill=objectiveFill
 local objectiveAction=Instance.new("TextButton")
 objectiveAction.Name="MissionAction"
 objectiveAction.Position=UDim2.fromOffset(13,91)
 objectiveAction.Size=UDim2.fromOffset(236,30)
 objectiveAction.BackgroundColor3=C.mint
 objectiveAction.TextColor3=C.deep
 objectiveAction.Text="VIEW QUEST  →"
 objectiveAction.TextSize=11
 objectiveAction.Font=Enum.Font.GothamBold
 objectiveAction.AutoButtonColor=false
 objectiveAction.SelectionOrder=10
 objectiveAction.Parent=objective
 W.round(objectiveAction,8);W.focus(objectiveAction)
 objectiveAction.Activated:Connect(function()
  self:openTab(self.objectiveTab or "Quests")
 end)
 self.objectiveAction=objectiveAction

 local dim=noWorldBlocking(gui);self.dim=dim
 local panel=framed(gui,"CollectionWindow",Color3.fromRGB(23,33,51))
 panel.AnchorPoint=Vector2.new(.5,.5)
 panel.Position=UDim2.fromScale(.5,.52)
 panel.Size=UDim2.fromOffset(680,610)
 panel.Visible=false
 self.panel=panel
 local accent=Instance.new("Frame")
 accent.Name="AccentStripe"
 accent.Size=UDim2.new(1,-4,0,6)
 accent.Position=UDim2.fromOffset(2,2)
 accent.BackgroundColor3=C.gold;accent.BorderSizePixel=0
 accent.Parent=panel;W.round(accent,3)
 local heading=absoluteText(panel,"MY RANCH",23,C.light)
 heading.Position=UDim2.fromOffset(23,21);heading.Size=UDim2.new(1,-110,0,38)
 self.heading=heading
 local hint=absoluteText(panel,"Make the galaxy yours",13,C.muted)
 hint.Position=UDim2.fromOffset(24,59);hint.Size=UDim2.new(1,-110,0,19)
 self.hint=hint
 local close=Instance.new("TextButton")
 close.Name="CloseWindow"
 close.Size=UDim2.fromOffset(48,43)
 close.AnchorPoint=Vector2.new(1,0)
 close.Position=UDim2.new(1,-20,0,24)
 close.BackgroundColor3=Color3.fromRGB(66,81,104)
 close.Text="X";close.TextSize=18;close.Font=Enum.Font.GothamBold
 close.TextColor3=C.light;close.Parent=panel
 close.SelectionOrder=1
 W.round(close,11);W.focus(close)
 self.close=close
 close.Activated:Connect(function() self:setOpen(false) end)
 local nav=Instance.new("ScrollingFrame")
 nav.Name="Tabs"
 nav.Position=UDim2.fromOffset(20,96)
 nav.Size=UDim2.new(1,-40,0,47)
 nav.BackgroundTransparency=1
 nav.AutomaticCanvasSize=Enum.AutomaticSize.X
 nav.CanvasSize=UDim2.fromOffset(0,0)
 nav.ScrollBarThickness=0
 nav.ScrollingDirection=Enum.ScrollingDirection.X
 nav.Parent=panel
 local navLayout=Instance.new("UIListLayout")
 navLayout.FillDirection=Enum.FillDirection.Horizontal
 navLayout.SortOrder=Enum.SortOrder.LayoutOrder
 navLayout.Padding=UDim.new(0,7);navLayout.Parent=nav
 self.tabButtons={};self.tabLabels={}
 for index,tab in ipairs(TABS) do
  local b=Instance.new("TextButton")
  b.Name="Tab_"..tab[1]
  b.LayoutOrder=index
  b.Size=UDim2.fromOffset(math.max(74,#tab[2]*11+18),38)
  b.Text="";b.AutoButtonColor=false
  b.BackgroundColor3=C.surface
  b.SelectionOrder=10+index
  b.Parent=nav;W.round(b,9);W.focus(b)
  local tabIcon=Icons.create(b,tab[1],19)
  tabIcon.Position=UDim2.fromOffset(7,9)
  local tabName=absoluteText(b,tab[2],11,C.light)
  tabName.Position=UDim2.fromOffset(32,8)
  tabName.Size=UDim2.new(1,-35,0,22)
  b.Activated:Connect(function() self:openTab(tab[1]) end)
  self.tabButtons[tab[1]]=b
  self.tabLabels[tab[1]]=tabName
 end
 local content=Instance.new("ScrollingFrame")
 content.Name="Content";content.BackgroundTransparency=1
 content.Position=UDim2.fromOffset(24,153)
 content.Size=UDim2.new(1,-48,1,-178)
 content.ScrollBarThickness=5
 content.ScrollBarImageColor3=C.gold
 content.CanvasSize=UDim2.fromOffset(0,0)
 content.AutomaticCanvasSize=Enum.AutomaticSize.Y
 content.Parent=panel
 W.stack(content,12)
 self.page=content

 local dock=framed(gui,"ActionDock",C.deep)
 dock.AnchorPoint=Vector2.new(.5,1)
 dock.Position=UDim2.new(.5,0,1,-16)
 dock.Size=UDim2.fromOffset(520,68)
 self.dock=dock
 local items=Instance.new("Frame")
 items.BackgroundTransparency=1
 items.Size=UDim2.new(1,-12,1,-12)
 items.Position=UDim2.fromOffset(6,6);items.Parent=dock
 local horizontal=Instance.new("UIListLayout")
 horizontal.FillDirection=Enum.FillDirection.Horizontal
 horizontal.HorizontalAlignment=Enum.HorizontalAlignment.Center
 horizontal.VerticalAlignment=Enum.VerticalAlignment.Center
 horizontal.Padding=UDim.new(0,6);horizontal.Parent=items
 self.quick={}
 for index,entry in ipairs(SHORTCUTS) do
  local button=Instance.new("TextButton")
  button.Name="Quick_"..entry[2]
  button.LayoutOrder=index
  button.Size=UDim2.new(.2,-9,1,-2)
  button.BackgroundColor3=index==1 and C.gold or C.surface
  button.TextColor3=index==1 and C.deep or C.light
  button.Text=""
  button.AutoButtonColor=false
  button.SelectionOrder=10+index
  button.Parent=items
  W.round(button,10);W.focus(button)
  local picture=Icons.create(button,entry[2],28)
  picture.AnchorPoint=Vector2.new(.5,0)
  picture.Position=UDim2.new(.5,0,0,6)
  local caption=absoluteText(button,entry[1],11,index==1 and C.deep or C.light)
  caption.Position=UDim2.new(0,0,1,-22)
  caption.Size=UDim2.new(1,0,0,18)
  caption.TextXAlignment=Enum.TextXAlignment.Center
  button.Activated:Connect(function() self:openTab(entry[2]) end)
  self.quick[entry[2]]=button
 end

 local menu=Instance.new("TextButton")
 menu.Name="OpenMenu"
 menu.AnchorPoint=Vector2.new(1,1)
 menu.Position=UDim2.new(1,-16,1,-24)
 menu.Size=UDim2.fromOffset(94,44)
 menu.Text="MENU [G/Y]"
 menu.Font=Enum.Font.GothamBold;menu.TextSize=13
 menu.TextColor3=C.light
 menu.BackgroundColor3=C.deep
 menu.SelectionOrder=1
 menu.Parent=gui
 W.round(menu,13);W.border(menu);W.focus(menu)
 self.menu=menu
 menu.Activated:Connect(function() self:setOpen(not self.open) end)
 local toast=framed(gui,"Toast",C.surface)
 toast.AnchorPoint=Vector2.new(.5,0)
 toast.Position=UDim2.new(.5,0,0,88)
 toast.Size=UDim2.fromOffset(370,55)
 toast.Visible=false
 self.toast=toast
 local toastText=absoluteText(toast,"",14,C.light)
 toastText.TextXAlignment=Enum.TextXAlignment.Center
 toastText.Size=UDim2.new(1,-20,1,0);toastText.Position=UDim2.fromOffset(10,0)
 self.toastText=toastText
 UserInputService.InputBegan:Connect(function(input,consumed)
  if consumed or UserInputService:GetFocusedTextBox() then return end
  if input.KeyCode==Enum.KeyCode.G or input.KeyCode==Enum.KeyCode.ButtonY then
   self:setOpen(not self.open)
  elseif input.KeyCode==Enum.KeyCode.ButtonB then
   if self.hatchDismiss then
    self.hatchDismiss()
   elseif self.open then
    self:setOpen(false)
   end
  elseif input.KeyCode==Enum.KeyCode.One then self:openTab("Eggs")
  elseif input.KeyCode==Enum.KeyCode.Two then self:openTab("Creatures")
  elseif input.KeyCode==Enum.KeyCode.Three then self:openTab("Backpack")
  elseif input.KeyCode==Enum.KeyCode.Four then self:openTab("Quests")
  elseif input.KeyCode==Enum.KeyCode.Five then self:openTab("Ranch")
  end
 end)
 UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
  if self:usesController() then
   self:selectForController(self.open and self.tabButtons[self.tab] or self.menu)
  end
 end)
 local function resize()
  local camera=workspace.CurrentCamera
  if not camera then return end
  local width,height=camera.ViewportSize.X,camera.ViewportSize.Y
  self.viewportWidth=width
  local narrow=width<730
  panel.Size=UDim2.fromOffset(math.min(narrow and width-18 or 720,width-18),
   math.min(height-70,narrow and 680 or 630))
  dock.Size=UDim2.fromOffset(math.min(510,width-24),narrow and 60 or 68)
  if narrow then
   objective.Position=UDim2.fromOffset(9,124)
   objective.Size=UDim2.fromOffset(math.min(260,width-18),132)
   brand.Position=UDim2.fromOffset(9,63);brand.Size=UDim2.fromOffset(137,49)
   descriptor.Visible=false;logo.Text="GORPS"
   wallet.Position=UDim2.new(1,-9,0,63);wallet.Size=UDim2.fromOffset(160,49)
   menu.Position=UDim2.new(1,-8,1,-89);menu.Size=UDim2.fromOffset(72,38)
   for _,button in pairs(self.quick) do
    local glyph=button:FindFirstChild("Icon_"..string.sub(button.Name,7))
    if glyph then glyph.Size=UDim2.fromOffset(24,24) end
   end
  else
   objective.Position=UDim2.fromOffset(16,137);objective.Size=UDim2.fromOffset(262,132)
   brand.Position=UDim2.fromOffset(16,74);brand.Size=UDim2.fromOffset(220,51)
   descriptor.Visible=true;logo.Text="GORPS"
   wallet.Position=UDim2.new(1,-16,0,74);wallet.Size=UDim2.fromOffset(190,51)
   menu.Position=UDim2.new(1,-16,1,-24);menu.Size=UDim2.fromOffset(94,44)
   for _,button in pairs(self.quick) do
    local glyph=button:FindFirstChild("Icon_"..string.sub(button.Name,7))
    if glyph then glyph.Size=UDim2.fromOffset(28,28) end
   end
  end
 end
 self.resize=resize
 local camera=workspace.CurrentCamera
 if camera then camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
 workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(resize)
 resize()
 return self
end
function UI:usesController()
 local preferred=UserInputService.PreferredInput
 return preferred==Enum.PreferredInput.Gamepad
  or preferred==Enum.PreferredInput.MicroGamepad
end
function UI:selectionTargetIsUsable(target)
 if target==nil or not target:IsDescendantOf(self.gui) or not target.Selectable then
  return false
 end
 local current=target
 while current and current~=self.gui do
  if current:IsA("GuiObject") and not current.Visible then return false end
  current=current.Parent
 end
 return current==self.gui
end
function UI:selectForController(target)
 if not self:usesController() then return end
 task.defer(function()
  if self:selectionTargetIsUsable(target) then
   GuiService.SelectedObject=target
  end
 end)
end
function UI:restorePageFocus()
 if not self:usesController() then return end
 task.defer(function()
  if not self.open then return end
  GuiService:Select(self.page)
  local selected=GuiService.SelectedObject
  if not selected or not selected:IsDescendantOf(self.page) then
   self:selectForController(self.tabButtons[self.tab])
  end
 end)
end
function UI:setOpen(open)
 self.open=open
 self.dim.Visible=open
 self.panel.Visible=open
 self.dock.Visible=not open
 self.objective.Visible=not open
 self.menu.Visible=not open
 if open then
  self:render()
  self:selectForController(self.tabButtons[self.tab])
 else
  self:selectForController(self.menu)
 end
end
function UI:openTab(tab)
 if not self.tabButtons[tab] then return end
 local switched=self.tab~=tab
 self.tab=tab
 self:setOpen(true)
 if switched then self.page.CanvasPosition=Vector2.zero end
end
function UI:toastMessage(message)
 if not message or message=="" then return end
 self.toastSerial+=1
 local serial=self.toastSerial
 self.toastText.Text=tostring(message)
 self.toast.Visible=true
 task.delay(2.8,function()
  if self.toastSerial==serial then self.toast.Visible=false end
 end)
end
function UI:showPickup(reward)
 if type(reward)~="table" or type(reward.resource)~="string" then return end
 local number=tonumber(reward.amount)
 if not number or number<=0 then return end
 local notification=framed(self.gui,"Pickup",Color3.fromRGB(33,110,83))
 notification.AnchorPoint=Vector2.new(.5,.5)
 notification.Position=UDim2.fromScale(.5,.67)
 notification.Size=UDim2.fromOffset(205,52)
 local label=absoluteText(notification,"+ "..number.." "..string.upper(reward.resource),18,C.light)
 label.Size=UDim2.fromScale(1,1);label.TextXAlignment=Enum.TextXAlignment.Center
 TweenService:Create(notification,TweenInfo.new(.6,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),
  {Position=UDim2.fromScale(.5,.56)}):Play()
 task.delay(1,function()
  if notification.Parent then notification:Destroy() end
 end)
end
function UI:showHatch(pet)
 if type(pet)~="table" or not Config.Species[pet.species] then return end
 if self.hatchDismiss then self.hatchDismiss() end
 local previousSelection=GuiService.SelectedObject
 local overlay=Instance.new("Frame")
 overlay.Name="HatchReveal"
 overlay.Size=UDim2.fromScale(1,1);overlay.BorderSizePixel=0
 overlay.BackgroundColor3=Color3.fromRGB(12,23,43)
 overlay.BackgroundTransparency=.08
 overlay.Parent=self.gui
 local card=framed(overlay,"RewardCard",C.surface)
 card.AnchorPoint=Vector2.new(.5,.5)
 card.Position=UDim2.fromScale(.5,.48)
 card.Size=UDim2.fromOffset(320,420)
 local header=absoluteText(card,"NEW GORP DISCOVERED!",19,C.gold)
 header.Size=UDim2.new(1,-24,0,36);header.Position=UDim2.fromOffset(20,21)
 header.TextXAlignment=Enum.TextXAlignment.Center
 local preview=W.petPortrait(card,pet.species,pet.rarity,pet)
 preview.AnchorPoint=Vector2.new(.5,0)
 preview.Position=UDim2.new(.5,0,0,76)
 preview.Size=UDim2.fromOffset(205,205)
 local name=absoluteText(card,string.upper(pet.species),26,W.rarityColor(pet.rarity))
 name.Position=UDim2.fromOffset(18,300);name.Size=UDim2.new(1,-36,0,35)
 name.TextXAlignment=Enum.TextXAlignment.Center
 local rarity=absoluteText(card,string.upper(pet.rarity),15,C.light)
 rarity.Position=UDim2.fromOffset(18,331);rarity.Size=UDim2.new(1,-36,0,20)
 rarity.TextXAlignment=Enum.TextXAlignment.Center
 local equip=Instance.new("TextButton")
 equip.Name="EquipNow"
 equip.Text="EQUIP & CONTINUE"
 equip.TextSize=15;equip.Font=Enum.Font.GothamBold
 equip.TextColor3=C.deep;equip.BackgroundColor3=C.gold
 equip.Position=UDim2.fromOffset(20,366)
 equip.Size=UDim2.new(1,-40,0,41)
 equip.SelectionOrder=1
 equip.Parent=card;W.round(equip,10);W.focus(equip)
 local dismissed=false
 local function dismissReveal()
  if dismissed then return end
  dismissed=true
  if overlay.Parent then overlay:Destroy() end
  self.hatchDismiss=nil
  local fallback=self.open and self.tabButtons[self.tab] or self.menu
  self:selectForController(self:selectionTargetIsUsable(previousSelection)
   and previousSelection or fallback)
 end
 self.hatchDismiss=dismissReveal
 equip.Activated:Connect(function()
  dismissReveal()
  self.send("SelectPet",{id=pet.id})
 end)
 local dismiss=Instance.new("TextButton")
 dismiss.Name="Dismiss"
 dismiss.Text="X";dismiss.Font=Enum.Font.GothamBold;dismiss.TextSize=17
 dismiss.TextColor3=C.light;dismiss.BackgroundColor3=C.deep
 dismiss.Position=UDim2.new(1,-43,0,8);dismiss.Size=UDim2.fromOffset(34,33)
 dismiss.SelectionOrder=2
 dismiss.Parent=card;W.round(dismiss,9);W.focus(dismiss)
 dismiss.Activated:Connect(dismissReveal)
 card.Size=UDim2.fromOffset(250,340)
 TweenService:Create(card,TweenInfo.new(.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
  {Size=UDim2.fromOffset(320,420)}):Play()
 self:selectForController(equip)
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
 self.wallet.Text=tostring(p.Coins)
 local capacity=math.min(40,3+(p.BaseLevel-1)*2)
 self.levelLine.Text="LEVEL "..p.Level.."  ·  "..#p.Pets.."/"..capacity.." GORPS"
 local objective=Onboarding.resolve(p)
 self.objectiveBody.Text=objective.title.."  "..objective.current.."/"..objective.goal
 self.objectiveDetail.Text=objective.detail
 self.objectiveFill.Size=UDim2.fromScale(objective.progress,1)
 self.objectiveAction.Text=objective.action.."  →"
 self.objectiveTab=objective.tab
 if not self.open then return end
 local info={
  Ranch={"MY RANCH","Expand, manage your animals and complete quests"},
  Eggs={"GORPS HATCHERY","Discover creatures and build your collection"},
  Creatures={"MY CREATURES","Select a companion, feed and evolve"},
  Backpack={"INVENTORY","Your resources, materials and equipment"},
  Crafting={"CRAFTING","Turn your resources into equipment"},
  Shop={"SHOP","Buy supplies with coins you earn"},
  Workers={"RANCH CREW","Hire helpers who work while you explore"},
  Quests={"MISSIONS","Follow clear goals and claim earned rewards"},
  Trade={"PLAYER TRADING","Exchange items and creatures with other players"},
  Events={"GALAXY EVENTS","Daily rewards and visiting UFO traders"},
  Rankings={"LEADERBOARDS","The most accomplished explorers"}
 }
 self.heading.Text=info[self.tab][1]
 self.hint.Text=info[self.tab][2]
 for key,button in pairs(self.tabButtons) do
  local active=key==self.tab
  button.BackgroundColor3=active and C.gold or C.surface
  self.tabLabels[key].TextColor3=active and C.deep or C.light
 end
 local selected=GuiService.SelectedObject
 local restorePageSelection=self:usesController() and selected~=nil
  and selected:IsDescendantOf(self.page)
 local oldPosition=self.page.CanvasPosition
 self.page:SetAttribute("OrderCounter",0)
 for _,child in ipairs(self.page:GetChildren()) do
  if not child:IsA("UIListLayout") then child:Destroy() end
 end
 Pages.render(self.page,self.tab,p,self.trade,function(action,args)
  if action=="__openTab" then
   self:openTab(args.id)
  else
   self.send(action,args)
  end
 end,self.rankings)
 self.page.CanvasPosition=oldPosition
 if restorePageSelection then self:restorePageFocus() end
end
return UI

