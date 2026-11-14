-- Headless state-machine tests of the real same-server invitation router.
-- These tests do not substitute for a Roblox Studio two-client playtest.
local fs=require("@lune/fs")
local luau=require("@lune/luau")
local now=1000
local players={}
local names={}
function players:FindFirstChild(name) return names[name] end
local function player(name,id)
 local value={Name=name,UserId=id,Parent=players}
 names[name]=value
 return value
end
local alice=player("Alice",11)
local bob=player("Bob",12)
local cara=player("Cara",13)
local eve=player("Eve",14)
local modules={}
local function loadShared(name)
 if modules[name] then return modules[name] end
 local path="src/shared/"..name..".lua"
 local chunk=luau.load(fs.readFile(path),{
  debugName=path,
  environment={
   script={Parent={Config="Config",Rules="Rules"}},
   require=function(dependency)
    assert(type(dependency)=="string","Unexpected shared dependency")
    return loadShared(dependency)
   end,
  },
 })
 modules[name]=chunk()
 return modules[name]
end
local shared={Config="Config",Rules="Rules",TradeRules="TradeRules"}
local tradeChunk=luau.load(fs.readFile("src/server/Trade.lua"),{
 debugName="src/server/Trade.lua",
 environment={
  game={GetService=function(_,name)
   if name=="Players" then return players end
   if name=="ReplicatedStorage" then return {Shared=shared} end
   error("Unexpected service: "..name)
  end},
  script={Parent={}},
  require=function(dependency) return loadShared(dependency) end,
  os={clock=function() return now end},
 },
})
local Trade=tradeChunk()
local Rules=loadShared("Rules")
local profiles={}
for _,who in ipairs({alice,bob,cara,eve}) do profiles[who]=Rules.new(now) end
local messages={}
local function emit(who,message)
 table.insert(messages,{to=who.Name,message=message})
end
local function get(who) return profiles[who] end
local function changed() end
local checks=0
local function equal(actual,expected,label)
 checks+=1
 assert(actual==expected,label..": expected "..tostring(expected)..", got "..tostring(actual))
end
local function action(who,name,args)
 return Trade.action(who,name,args or {},get,changed,emit)
end

equal(action(alice,"Invite",{target="Bob"}),true,"first invitation succeeds")
equal(Trade.status(bob).pendingFrom,"Alice","recipient sees invitation")
equal(#messages,1,"first invitation emits one notification")
equal(action(alice,"Invite",{target="Cara"}),false,"sender cooldown prevents spam")
equal(#messages,1,"rejected spam emits no notification")
now=1005
equal(action(cara,"Invite",{target="Bob"}),false,"another inviter cannot overwrite pending consent")
equal(Trade.status(bob).pendingFrom,"Alice","original invitation cannot be hijacked")
equal(#messages,1,"overwritten invitation is not notified")
now=1029
equal(Trade.status(bob).pendingFrom,"Alice","invitation remains valid before 30-second limit")
now=1030
equal(Trade.status(bob).pendingFrom,nil,"invitation expires exactly at deadline")
equal(action(bob,"Join"),false,"expired invitation cannot create trade session")
equal(Trade.status(bob).partner,nil,"expired recipient has no partner")
now=1031
equal(action(alice,"Invite",{target="Bob"}),true,"sender may re-invite after expiry")
equal(action(eve,"Join"),false,"third party cannot join someone else's invite")
equal(action(bob,"Join"),true,"fresh invite joins")
equal(Trade.status(alice).partner,"Bob","inviter sees joined partner")
equal(Trade.status(bob).partner,"Alice","recipient sees joined partner")
equal(action(bob,"Cancel"),true,"recipient cancels active session")
equal(Trade.status(alice).partner,nil,"cancellation clears inviter session")
equal(Trade.status(bob).partner,nil,"cancellation clears recipient session")
now=1040
equal(action(alice,"Invite",{target="Bob"}),true,"sender can issue an invite after cancellation")
now=1044
equal(action(alice,"Invite",{target="Cara"}),true,"sender can invite another player after cooldown")
equal(Trade.status(bob).pendingFrom,"Alice","first pending recipient remains assigned")
equal(Trade.status(cara).pendingFrom,"Alice","second pending recipient remains assigned")
Trade.disconnect(alice,emit)
equal(Trade.status(bob).pendingFrom,nil,"disconnect invalidates first pending invite")
equal(Trade.status(cara).pendingFrom,nil,"disconnect invalidates second pending invite")
equal(action(bob,"Join"),false,"recipient cannot join disconnected inviter")
equal(action(cara,"Join"),false,"second recipient cannot join disconnected inviter")
now=1045
equal(action(cara,"Invite",{target="Eve"}),true,"other inviter can invite independently")
eve.Parent=nil
equal(Trade.status(eve).pendingFrom,"Cara","recipient can read pending state before leave")
cara.Parent=nil
equal(Trade.status(eve).pendingFrom,nil,"disconnected sender invalidates invitation")
print("PASS: "..checks.." trade invitation assertions (Studio multiplayer QA remains pending).")
