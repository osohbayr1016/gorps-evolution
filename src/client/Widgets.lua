local TweenService=game:GetService("TweenService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Config=require(ReplicatedStorage.Shared.Config)
local CreatureFactory=require(ReplicatedStorage.Shared.CreatureFactory)
local Icons=require(script.Parent.Icons)
local W={}
W.colors={
 ink=Color3.fromRGB(23,33,50),surface=Color3.fromRGB(35,48,69),
 deep=Color3.fromRGB(17,26,42),light=Color3.fromRGB(251,247,239),
 muted=Color3.fromRGB(184,195,213),gold=Color3.fromRGB(255,198,79),
 mint=Color3.fromRGB(89,224,166),blue=Color3.fromRGB(106,179,250),
 line=Color3.fromRGB(95,116,147),
}
local colorByRarity={
 Common=Color3.fromRGB(160,194,194),
 Uncommon=Color3.fromRGB(112,213,145),
 Rare=Color3.fromRGB(90,170,252),
 Epic=Color3.fromRGB(191,122,246),
 Legendary=Color3.fromRGB(255,183,69)
}
function W.rarityColor(rarity) return colorByRarity[rarity] or W.colors.light end
function W.round(obj,px)
 local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,px);c.Parent=obj
 return c
end
function W.border(obj,col,thickness)
 local s=Instance.new("UIStroke");s.Color=col or W.colors.line
 s.Thickness=thickness or 1;s.Transparency=.32;s.Parent=obj;return s
end
function W.focus(obj)
 local ring=Instance.new("UIStroke")
 ring.Name="ControllerFocus"
 ring.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
 ring.Color=W.colors.light
 ring.Thickness=3
 ring.Transparency=1
 ring.Parent=obj
 obj.SelectionGained:Connect(function() ring.Transparency=0 end)
 obj.SelectionLost:Connect(function() ring.Transparency=1 end)
 return ring
end
function W.order(parent,child)
 local index=(parent:GetAttribute("OrderCounter") or 0)+1
 parent:SetAttribute("OrderCounter",index)
 child.LayoutOrder=index
 return child
end
function W.stack(parent,gap)
 local l=Instance.new("UIListLayout")
 l.SortOrder=Enum.SortOrder.LayoutOrder
 l.Padding=UDim.new(0,gap or 9)
 l.Parent=parent
 return l
end
function W.label(parent,content,size,color,height)
 local t=Instance.new("TextLabel")
 t.Name="Copy"
 t.Size=UDim2.new(1,-2,0,height or 27)
 t.Text=content;t.TextColor3=color or W.colors.light
 t.TextSize=size or 15;t.Font=Enum.Font.GothamMedium
 t.TextWrapped=true;t.TextXAlignment=Enum.TextXAlignment.Left
 t.BackgroundTransparency=1;t.Parent=parent
 W.order(parent,t)
 return t
end
function W.button(parent,content,callback,enabled,accent)
 local b=Instance.new("TextButton")
 b.Name="Action";b.Size=UDim2.new(1,-2,0,45)
 b.BackgroundColor3=enabled==false and Color3.fromRGB(71,80,96)
  or (accent or W.colors.mint)
 b.TextColor3=enabled==false and W.colors.muted or W.colors.deep
 b.TextSize=14;b.Font=Enum.Font.GothamBold
 b.TextWrapped=true;b.Text=content
 b.AutoButtonColor=false;b.Active=enabled~=false;b.Selectable=enabled~=false
 b.Parent=parent
 W.order(parent,b);b.SelectionOrder=b.LayoutOrder;W.round(b,10)
 if enabled~=false then
  W.focus(b)
  b.Activated:Connect(callback)
  b.MouseEnter:Connect(function()
   TweenService:Create(b,TweenInfo.new(.12),{BackgroundTransparency=.12}):Play()
  end)
  b.MouseLeave:Connect(function()
   TweenService:Create(b,TweenInfo.new(.12),{BackgroundTransparency=0}):Play()
  end)
 end
 return b
end
function W.card(parent,title,description,accent)
 local frame=Instance.new("Frame")
 frame.Name="Card"
 frame.Size=UDim2.new(1,-6,0,0)
 frame.AutomaticSize=Enum.AutomaticSize.Y
 frame.BackgroundColor3=W.colors.surface
 frame.BorderSizePixel=0;frame.Parent=parent
 W.order(parent,frame);W.round(frame,15);W.border(frame,accent or W.colors.line,accent and 2 or 1)
 local pad=Instance.new("UIPadding")
 pad.PaddingTop=UDim.new(0,15);pad.PaddingBottom=UDim.new(0,15)
 pad.PaddingLeft=UDim.new(0,15);pad.PaddingRight=UDim.new(0,15);pad.Parent=frame
 W.stack(frame,8)
 if title then
  local h=W.label(frame,title,18,W.colors.light,28)
  h.Font=Enum.Font.GothamBold
 end
 if description then W.label(frame,description,13,W.colors.muted,37) end
 return frame
end
function W.progress(parent,fraction)
 local base=Instance.new("Frame")
 base.Name="Progress"
 base.Size=UDim2.new(1,-2,0,9)
 base.BackgroundColor3=Color3.fromRGB(64,77,99)
 base.BorderSizePixel=0;base.Parent=parent
 W.order(parent,base);W.round(base,8)
 local fill=Instance.new("Frame")
 fill.Size=UDim2.fromScale(math.clamp(fraction,0,1),1)
 fill.BackgroundColor3=W.colors.gold
 fill.BorderSizePixel=0;fill.Parent=base;W.round(fill,8)
 return fill
end
function W.row(parent,height)
 local frame=Instance.new("Frame")
 frame.Name="Row"
 frame.Size=UDim2.new(1,-2,0,height)
 frame.BackgroundTransparency=1;frame.Parent=parent
 W.order(parent,frame)
 return frame
end
function W.resourceIcon(parent,id,size)
 local box=Instance.new("Frame")
 box.Name="ResourceIcon_"..id
 box.Size=UDim2.fromOffset(size or 40,size or 40)
 box.BackgroundColor3=Color3.fromRGB(53,72,97)
 box.BorderSizePixel=0;box.Parent=parent
 W.round(box,10)
 local glyph=Icons.create(box,id,math.floor((size or 40)*.72))
 glyph.AnchorPoint=Vector2.new(.5,.5)
 glyph.Position=UDim2.fromScale(.5,.5)
 return box
end
function W.petPortrait(parent,species,rarity,pet)
 local preview=Instance.new("ViewportFrame")
 preview.Name="PetPreview"
 preview.BackgroundColor3=Color3.fromRGB(44,64,90)
 preview.Size=UDim2.fromOffset(104,104)
 preview.Ambient=Color3.fromRGB(235,235,235)
 preview.LightColor=Color3.fromRGB(255,244,221)
 preview.LightDirection=Vector3.new(-1,-1,-1)
 preview.BorderSizePixel=0;preview.Parent=parent
 W.round(preview,13);W.border(preview,W.rarityColor(rarity),1.5)
 local model=Instance.new("WorldModel")
 model.Name="PreviewWorld";model.Parent=preview
 local center=Vector3.zero
 local distance=19
 local definition=Config.Species[species]
 if definition then
  local previewPet=pet or {id=0,species=species,rarity=rarity,level=1,evolved=0}
  local creature=CreatureFactory.create(previewPet,Vector3.zero,model)
  if creature then
   local bounds,size=creature:GetBoundingBox()
   center=bounds.Position;distance=math.max(8,size.Magnitude*1.3)
   for _,descendant in ipairs(creature:GetDescendants()) do
    if descendant:IsA("BillboardGui") then descendant:Destroy() end
   end
  end
 end
 local camera=Instance.new("Camera");camera.FieldOfView=43
 camera.CFrame=CFrame.lookAt(center+Vector3.new(10,7,-15).Unit*distance,center)
 camera.Parent=preview;preview.CurrentCamera=camera
 return preview
end
function W.eggPortrait(parent,rgb)
 local viewport=Instance.new("ViewportFrame")
 viewport.BackgroundColor3=Color3.fromRGB(50,68,92)
 viewport.Size=UDim2.fromOffset(104,104)
 viewport.BorderSizePixel=0
 viewport.LightColor=Color3.fromRGB(255,243,218)
 viewport.Ambient=Color3.fromRGB(221,226,232)
 viewport.Parent=parent;W.round(viewport,13)
 local world=Instance.new("WorldModel");world.Parent=viewport
 local egg=Instance.new("Part")
 egg.Name="Egg";egg.Shape=Enum.PartType.Ball;egg.Anchored=true;egg.CanCollide=false
 egg.Size=Vector3.new(3.1,4.2,3.1);egg.Color=rgb or W.colors.gold
 egg.Material=Enum.Material.SmoothPlastic;egg.Parent=world
 for side=-1,1,2 do
  local dot=Instance.new("Part")
  dot.Name="Pattern";dot.Shape=Enum.PartType.Ball;dot.Anchored=true;dot.CanCollide=false
  dot.Size=Vector3.new(.85,.8,.45);dot.Position=Vector3.new(side*.85,.7,-1.25)
  dot.Color=W.colors.light;dot.Parent=world
 end
 local camera=Instance.new("Camera");camera.FieldOfView=36
 camera.CFrame=CFrame.lookAt(Vector3.new(7,4,-12),Vector3.new(0,0,0))
 camera.Parent=viewport;viewport.CurrentCamera=camera
 return viewport
end
return W

