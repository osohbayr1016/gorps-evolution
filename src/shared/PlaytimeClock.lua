-- Monotonic per-session whole-second accounting.
-- Keep sub-second remainder so uneven checkpoint schedules never invent or lose time.
local Clock={}
local function valid(value)
 return type(value)=="number" and value==value and value>=0 and value<math.huge
end
function Clock.advance(last,now)
 if not valid(last) or not valid(now) or now<=last then return 0,last end
 local whole=math.floor(now-last)
 if whole<1 then return 0,last end
 return whole,last+whole
end
return Clock
