-- Execute the actual monotonic per-player clock with uneven checkpoint times.
-- These are pure clock tests; private-published DataStore rejoin QA remains separate.
local fs=require("@lune/fs")
local luau=require("@lune/luau")
local module=luau.load(fs.readFile("src/shared/PlaytimeClock.lua"),{
 debugName="src/shared/PlaytimeClock.lua",
})
local Clock=module()
local checks=0
local function equal(actual,expected,label)
 checks+=1
 assert(actual==expected,label..": expected "..tostring(expected)..", got "..tostring(actual))
end
local function advance(previous,now,expectedSeconds,expectedCheckpoint,label)
 local credited,nextCheckpoint=Clock.advance(previous,now)
 equal(credited,expectedSeconds,label.." credit")
 equal(nextCheckpoint,expectedCheckpoint,label.." carry")
 return nextCheckpoint
end
-- Joining at server uptime 59 seconds is NOT one minute of actual play.
local lateJoin=advance(59,60,1,60,"late join at shared timer boundary")
advance(59.75,60,0,59.75,"very recent join cannot receive a minute")
local checkpoint=advance(59.75,60.75,1,60.75,"per-player second boundary")
checkpoint=advance(checkpoint,62.25,1,61.75,"irregular tick retains half-second")
checkpoint=advance(checkpoint,62.75,1,62.75,"fractional remainder becomes a whole second")
advance(checkpoint,62.75,0,62.75,"duplicate tick cannot double count")
local other=advance(60,61,1,61,"independent session begins at own join time")
advance(other,119,58,119,"second player's clock accrues only actual elapsed time")
advance(lateJoin,61,1,61,"first player's clock progresses independently")
advance(0,0,0,0,"zero elapsed session")
advance(10,9,0,10,"backward time cannot deduct or over-credit")
advance(10,10.999,0,10,"sub-second leave cannot invent a whole second")
advance(10,11.001,1,11,"leave flushes final earned whole second")
local restart=advance(100,161.9,61,161,"first checkpoint after a long interval")
advance(restart,162.2,1,162,"retained remainder survives long interval")
advance(10,math.huge,0,10,"invalid clock value rejected")
advance(10,0/0,0,10,"NaN clock value rejected")
print("PASS: "..checks.." playtime clock assertions (Studio session QA pending).")
