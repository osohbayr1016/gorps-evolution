local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UI=require(script.Parent.Ui)
local SnapshotOrder=require(script.Parent.SnapshotOrder)
local ui
local latestSnapshot=0
local function acceptServerUpdate(data)
 if type(data)~="table" then return false end
 if data.profile or data.trade or data.rankings then
  local accept,sequence=SnapshotOrder.accept(latestSnapshot,data.sequence)
  if not accept then return false end
  latestSnapshot=sequence
  ui:update(data.profile,data.trade,data.message,data.rankings)
 elseif data.message then
  ui:toastMessage(data.message)
 end
 return true
end
local busy=false
local action=nil
local function send(name,args)
 if busy then return end
 if not action then
  ui:toastMessage("Connecting to gameplay server...")
  return
 end
 busy=true
 local ok,result=pcall(function() return action:InvokeServer(name,args or {}) end)
 busy=false
 if not ok or type(result)~="table" then
  ui:toastMessage("Server request failed - open the Studio Server Output")
  return
 end
 acceptServerUpdate(result)
 -- Reveal the active companion's successful reaction instead of hiding it behind the menu.
 if result.ok and result.profile and (name=="Feed" or name=="Evolve" or name=="SelectPet")
  and args and args.id==result.profile.ActiveId then ui:setOpen(false) end
 if result.hatch then ui:showHatch(result.hatch) end
end
-- Render interface first. A server failure must never make the client appear empty.
ui=UI.new(send)
task.spawn(function()
 local remotes=ReplicatedStorage:WaitForChild("GorpsRemotes",12)
 if not remotes then
  ui:toastMessage("Gameplay server did not start. Open Studio > Output > Server.")
  warn("[Gorps Client] No GorpsRemotes after 12 seconds")
  return
 end
 action=remotes:WaitForChild("Action",5)
 local update=remotes:WaitForChild("Update",5)
 if not action or not update then
  ui:toastMessage("Server remotes are incomplete; check Server Output.")
  warn("[Gorps Client] Missing Action or Update remote")
  return
 end
 update.OnClientEvent:Connect(function(data)
  if type(data)=="table" then
   acceptServerUpdate(data)
   if data.openTab then ui:openTab(data.openTab) end
   if data.pickup then ui:showPickup(data.pickup) end
   if data.combat then ui:showCombat(data.combat) end
  end
 end)
 for attempt=1,20 do
  local success,result=pcall(function() return action:InvokeServer("State",{}) end)
  if success and type(result)=="table" and result.ok and result.profile then
   acceptServerUpdate(result)
   if latestSnapshot>0 then ui:toastMessage("Planet Verdant is ready!") end
   print("[Gorps Client] UI connected and profile synchronized.")
   return
  end
  task.wait(.5)
 end
 ui:toastMessage("Profile couldn't load. Check Studio Server Output.")
end)

