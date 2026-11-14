-- Pure autosave schedule tests; actual DataStore throttling still requires Studio.
local fs=require("@lune/fs")
local luau=require("@lune/luau")
local Schedule=luau.load(fs.readFile("src/server/AutosaveSchedule.lua"),{
 debugName="src/server/AutosaveSchedule.lua",
})()
local checks=0
local function eq(actual,expected,label)
 checks+=1
 assert(actual==expected,label..": expected "..tostring(expected)..", got "..tostring(actual))
end
eq(Schedule.INTERVAL,60,"session autosave interval remains one minute")
eq(Schedule.TICK,5,"scheduler checks modest five-second intervals")
eq(Schedule.MIN_OFFSET,15,"initial save is not immediate on load")
eq(Schedule.MAX_OFFSET,60,"first save precedes session lease timeout")
local now=1000
eq(Schedule.initial(now,15),1015,"first eligible deadline")
eq(Schedule.initial(now,60),1060,"latest eligible initial deadline")
eq(Schedule.initial(now,1),1015,"short jitter is clamped")
eq(Schedule.initial(now,999),1060,"long jitter is clamped")
eq(Schedule.initial(now,26.9),1026,"fractional jitter floors safely")
eq(Schedule.initial(now,nil),1015,"invalid offset uses safe fallback")
eq(Schedule.initial(0,15),15,"initial deadlines use supplied clock origin")
eq(Schedule.initial(0/0,15),nil,"NaN clock never schedules datastore operations")
eq(Schedule.initial(math.huge,15),nil,"infinite clock never schedules datastore operations")
eq(Schedule.due(now,nil),false,"missing deadline cannot trigger a mass save")
eq(Schedule.due(1014,1015),false,"not due before deadline")
eq(Schedule.due(1015,1015),true,"due exactly at deadline")
eq(Schedule.due(1020,1015),true,"late scheduler still considers save due")
eq(Schedule.due(0/0,1015),false,"invalid current clock cannot trigger")
eq(Schedule.due(1015,math.huge),false,"infinite deadline is not due")
eq(Schedule.advance(1015),1075,"next save runs sixty seconds after actual scheduling")
eq(Schedule.advance(0/0),nil,"invalid current time cannot advance deadline")
local staggered={}
for offset=15,60,5 do
 table.insert(staggered,Schedule.initial(now,offset))
end
eq(#staggered,10,"ten representative sessions have individual stagger slots")
for tick=1015,1060,5 do
 local dueCount=0
 for index,deadline in ipairs(staggered) do
  if Schedule.due(tick,deadline) then
   dueCount+=1
   staggered[index]=Schedule.advance(tick)
  end
 end
 eq(dueCount,1,"staggered sessions do not all write at "..tick)
end
eq(Schedule.due(1075,staggered[1]),true,"first session remains on minute cadence")
eq(Schedule.due(1074,staggered[1]),false,"first session does not write early")
print("PASS: "..checks.." jittered autosave policy assertions (published DataStore QA pending).")
