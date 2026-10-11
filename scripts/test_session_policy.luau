-- Deterministic overlapping-server tests for the pure persisted lock policy.
-- This does not call live Roblox DataStoreService.
local fs=require("@lune/fs")
local luau=require("@lune/luau")
local chunk=luau.load(fs.readFile("src/server/SessionPolicy.lua"),{
 debugName="src/server/SessionPolicy.lua",
})
local Policy=chunk()
local checks=0
local function equal(actual,expected,message)
 checks+=1
 assert(actual==expected,message..": expected "..tostring(expected)..", got "..tostring(actual))
end
local now=1800000000
local serverA="job-a:11111111-1111-1111-1111-111111111111"
local serverB="job-b:22222222-2222-2222-2222-222222222222"

local legacy={Coins=480,Inventory={Wood=30}}
local claimedA,reason=Policy.claim(legacy,serverA,now)
equal(reason,nil,"legacy profile claim succeeds")
equal(claimedA.Coins,480,"claim preserves progression")
equal(claimedA.Inventory.Wood,30,"claim preserves nested inventory")
equal(claimedA._session.id,serverA,"claim records owner")
equal(claimedA._session.expiresAt,now+Policy.TIMEOUT,"claim records bounded expiry")
equal(legacy._session,nil,"claim does not mutate source")
equal(Policy.confirms(claimedA,serverA,false),true,"claim result confirms owner")

local blocked,blockedReason=Policy.claim(claimedA,serverB,now+1)
equal(blocked,nil,"active foreign session is rejected")
equal(blockedReason,"Profile is active on another server","foreign owner reason")
local refreshedA=Policy.claim(claimedA,serverA,now+60)
equal(refreshedA._session.expiresAt,now+60+Policy.TIMEOUT,"owner retry refreshes lease")

local claimedB=Policy.claim(claimedA,serverB,now+Policy.TIMEOUT)
equal(claimedB._session.id,serverB,"exact-expiry takeover succeeds")
local staleSave,staleReason=Policy.save(claimedB,{Coins=999},serverA,now+Policy.TIMEOUT+1,false)
equal(staleSave,nil,"expired owner cannot overwrite takeover")
equal(staleReason,"Session ownership lost","stale save gives ownership error")

local savedB=Policy.save(claimedB,{Coins=525,Inventory={Wood=31}},serverB,now+Policy.TIMEOUT+1,false)
equal(savedB.Coins,525,"current owner saves progression")
equal(savedB._session.id,serverB,"save retains owner")
equal(savedB._lastSession,serverB,"save records last writer")
equal(claimedB.Coins,480,"save does not mutate stored input")

local releasedB=Policy.save(savedB,{Coins=530},serverB,now+Policy.TIMEOUT+2,true)
equal(releasedB.Coins,530,"release includes final progression")
equal(releasedB._session,nil,"release removes active lock")
equal(releasedB._lastSession,serverB,"release records terminal owner")
equal(Policy.confirms(releasedB,serverB,true),true,"release result confirms owner")
local releaseRetry=Policy.save(releasedB,{Coins=0},serverB,now+Policy.TIMEOUT+3,true)
equal(releaseRetry.Coins,530,"unknown-outcome release retry is idempotent")

local claimedAgain=Policy.claim(releasedB,serverA,now+Policy.TIMEOUT+4)
equal(claimedAgain._session.id,serverA,"released profile can be claimed immediately")
local releasedAgain=Policy.save(claimedAgain,{Coins=540},serverA,now+Policy.TIMEOUT+5,true)
local ancientRetry=Policy.save(releasedAgain,{Coins=999},serverB,now+Policy.TIMEOUT+6,true)
equal(ancientRetry,nil,"older server cannot acknowledge a later release")

local corruptValue,corruptValueReason=Policy.claim("bad",serverA,now)
equal(corruptValue,nil,"non-table stored profile fails closed")
equal(corruptValueReason,"Corrupt profile value","corrupt profile reason")
local corruptLock,corruptLockReason=Policy.claim({_session={id="short",expiresAt=now+30}},serverA,now)
equal(corruptLock,nil,"malformed lock fails closed")
equal(corruptLockReason,"Corrupt session lock","corrupt lock reason")
equal(Policy.claim({},"short",now),nil,"invalid token rejected")
equal(Policy.save(claimedA,{},serverA,-1,false),nil,"invalid timestamp rejected")
equal(Policy.claim({},serverA,math.huge),nil,"infinite timestamp rejected")
print("PASS: "..checks.." session ownership assertions (pure policy; live DataStore QA remains pending).")
