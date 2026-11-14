-- Real client sequence policy. Models delayed RPC vs later server pushes.
local fs=require("@lune/fs")
local luau=require("@lune/luau")
local Order=luau.load(fs.readFile("src/client/SnapshotOrder.lua"),{
 debugName="src/client/SnapshotOrder.lua",
})()
local checks=0
local function equal(value,expected,label)
 checks+=1
 assert(value==expected,label..": expected "..tostring(expected)..", got "..tostring(value))
end
local function accept(last,version,okExpected,nextExpected,label)
 local accepted,nextValue=Order.accept(last,version)
 equal(accepted,okExpected,label.." accepted")
 equal(nextValue,nextExpected,label.." last seen")
 return nextValue
end
local current=accept(nil,1,true,1,"initial State response")
current=accept(current,3,true,3,"later server push")
current=accept(current,2,false,3,"slow earlier RPC cannot roll back newer push")
current=accept(current,3,false,3,"duplicate event cannot regress UI")
current=accept(current,4,true,4,"next state change is accepted")
current=accept(current,0,false,4,"zero cannot be a valid sequence")
current=accept(current,-1,false,4,"negative sequence rejected")
current=accept(current,4.5,false,4,"fractional sequence rejected")
current=accept(current,0/0,false,4,"NaN rejected")
current=accept(current,math.huge,false,4,"infinity rejected")
current=accept(current,"5",false,4,"string coercion rejected")
current=accept(current,nil,false,4,"unversioned profile payload rejected")
current=accept(current,9007199254740992,false,4,"precision-unsafe number rejected")
current=accept(current,5,true,5,"valid state continues after invalid payloads")
local nextServer=accept(0,1,true,1,"new client session starts independently")
equal(nextServer,1,"new session has a fresh sequence range")
print("PASS: "..checks.." out-of-order state snapshot assertions (Studio network QA pending).")
