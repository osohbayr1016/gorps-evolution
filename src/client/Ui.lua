local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local Pages=require(script.Parent.Pages)
local UI={}
UI.__index=UI
local function corner(obj,r)
 local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r);c.Parent=obj
end
local function label(parent,text,size,color,height)
 local t=Instance.new("TextLabel");t.Name="Label";t.Size=UDim2.new(1,-8,0,height or 26)
 t.BackgroundTransparency=1;t.TextXAlignment=Enum.TextXAlignment.Left
 t.TextWrapped=true;t.Text=text;t.TextSize=size or 16
 t.Font=Enum.Font.Gotham;t.TextColor3=color or Color3.fromRGB(226,239,235);t.Parent=parent
 return t
end
local function button(parent,text,fn)
 local b=Instance.new("TextButton");b.Name="Action"
 b.Size=UDim2.new(1,-4,0,38);b.BackgroundColor3=Color3.fromRGB(53,91,92)
 b.TextColor3=Color3.fromRGB(240,248,241);b.Font=Enum.Font.GothamMedium
 b.TextSize=14;b.Text=text;b.AutoButtonColor=false;b.Parent=parent
 corner(b,8)
 b.MouseEnter:Connect(function() TweenService:Create(b,TweenInfo.new(0.16),{BackgroundColor3=Color3.fromRGB(75,125,116)}):Play() end)
 b.MouseLeave:Connect(function() TweenService:Create(b,TweenInfo.new(0.16),{BackgroundColor3=Color3.fromRGB(53,91,92)}):Play() end)
 b.Activated:Connect(fn)
 return b
end
function UI.new(send)
 local self=setmetatable({send=send,tab="Ranch",profile=nil,trade={},rankings={},message=nil},UI)
 local gui=Instance.new("ScreenGui");gui.Name="GorpsHUD";gui.ResetOnSpawn=false
 gui.IgnoreGuiInset=true;gui.Parent=Players.LocalPlayer:WaitForChild("PlayerGui")
 self.gui=gui
 local shell=Instance.new("Frame");shell.Name="Main";shell.Position=UDim2.fromScale(.02,.09)
 shell.Size=UDim2.fromScale(.49,.82)
 shell.BackgroundColor3=Color3.fromRGB(24,34,42);shell.BorderSizePixel=0;shell.Parent=gui
 corner(shell,14)
 local size=Instance.new("UISizeConstraint");size.MinSize=Vector2.new(320,330)
 size.MaxSize=Vector2.new(760,850);size.Parent=shell
 local top=label(shell,"GORPS EVOLUTION   /   CHAOS GALAXY",19,Color3.fromRGB(140,234,197),42)
 top.Position=UDim2.fromOffset(16,9);top.Size=UDim2.new(1,-30,0,40);top.Font=Enum.Font.GothamBold
 local stats=label(shell,"Loading planet...",14,Color3.fromRGB(191,207,204),28)
 stats.Position=UDim2.fromOffset(16,47);stats.Size=UDim2.new(1,-30,0,28);self.stats=stats
 local nav=Instance.new("ScrollingFrame");nav.Name="Navigation";nav.Position=UDim2.fromOffset(12,84)
 nav.Size=UDim2.new(0,128,1,-95);nav.BackgroundTransparency=1;nav.ScrollBarThickness=2
 nav.AutomaticCanvasSize=Enum.AutomaticSize.Y;nav.CanvasSize=UDim2.new();nav.Parent=shell
 local nl=Instance.new("UIListLayout");nl.Padding=UDim.new(0,6);nl.Parent=nav
 for _,tab in ipairs({"Ranch","Creatures","Backpack","Crafting","Shop","Workers","Quests","Trade","Events","Rankings"}) do
  button(nav,tab,function() self.tab=tab;self:render() end)
 end
 local page=Instance.new("ScrollingFrame");page.Name="Content"
 page.Position=UDim2.fromOffset(154,84);page.Size=UDim2.new(1,-166,1,-96)
 page.BackgroundTransparency=1;page.BorderSizePixel=0;page.ScrollBarThickness=4
 page.CanvasSize=UDim2.new();page.AutomaticCanvasSize=Enum.AutomaticSize.Y;page.Parent=shell
 local list=Instance.new("UIListLayout");list.Padding=UDim.new(0,9);list.Parent=page
 self.page=page
 local toast=label(gui,"",15,Color3.new(1,1,1),44)
 toast.Name="Toast";toast.Position=UDim2.fromScale(.25,.025)
 toast.Size=UDim2.fromScale(.5,.05);toast.BackgroundColor3=Color3.fromRGB(45,70,73)
 toast.BackgroundTransparency=.12;toast.TextXAlignment=Enum.TextXAlignment.Center
 toast.Visible=false;corner(toast,8);self.toast=toast
 local toggle=Instance.new("TextButton");toggle.Name="Toggle";toggle.Size=UDim2.fromOffset(90,36)
 toggle.Position=UDim2.fromScale(.02,.015);toggle.BackgroundColor3=Color3.fromRGB(30,75,68)
 toggle.Text="Hide UI";toggle.TextColor3=Color3.new(1,1,1);toggle.Parent=gui;corner(toggle,8)
 toggle.Activated:Connect(function()
  shell.Visible=not shell.Visible;toggle.Text=shell.Visible and "Hide UI" or "Show UI"
 end)
 return self
end
function UI:toastMessage(message)
 if not message or message=="" then return end
 self.toast.Text=tostring(message);self.toast.Visible=true
 local token={}
 self.currentToast=token
 task.delay(3,function() if self.currentToast==token then self.toast.Visible=false end end)
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
 self.stats.Text=string.format("Coins %d  •  Level %d  •  Ranch %d  •  Pets %d/%d",
  p.Coins,p.Level,p.BaseLevel,#p.Pets,math.min(40,3+(p.BaseLevel-1)*2))
 for _,child in ipairs(self.page:GetChildren()) do
  if not child:IsA("UIListLayout") then child:Destroy() end
 end
 Pages.render(self.page,self.tab,p,self.trade,self.send,label,button,self.rankings)
end
return UI
