local ReplicatedStorage=game:GetService("ReplicatedStorage")
local remotes=ReplicatedStorage:WaitForChild("GorpsRemotes")
local action=remotes:WaitForChild("Action")
local update=remotes:WaitForChild("Update")
local UI=require(script.Parent.Ui)
local ui
local busy=false
local function send(name,args)
 if busy then return end
 busy=true
 local ok,result=pcall(function() return action:InvokeServer(name,args or {}) end)
 busy=false
 if not ok or type(result)~="table" then
  ui:toastMessage("Connection issue. Please try again.")
  return
 end
 ui:update(result.profile,result.trade,result.message,result.rankings)
end
ui=UI.new(send)
update.OnClientEvent:Connect(function(data)
 if type(data)=="table" then
  ui:update(data.profile,data.trade,data.message,data.rankings)
  if data.openTab then ui:openTab(data.openTab) end
 end
end)
task.spawn(function()
 for attempt=1,25 do
  local ok,result=pcall(function() return action:InvokeServer("State",{}) end)
  if ok and type(result)=="table" and result.ok then
   ui:update(result.profile,result.trade,"Welcome to Planet Verdant!")
   return
  end
  task.wait(0.5)
 end
 ui:toastMessage("Could not load game. Rejoin to retry.")
end)
