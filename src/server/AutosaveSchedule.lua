-- Pure, per-player autosave schedule. Stagger initial writes to avoid
-- every player in a server sending UpdateAsync on the same minute boundary.
local Schedule={}
Schedule.INTERVAL=60
Schedule.TICK=5
Schedule.MIN_OFFSET=15
Schedule.MAX_OFFSET=60
local function finite(value)
 return type(value)=="number" and value==value and value<math.huge and value>-math.huge
end
function Schedule.initial(now,offset)
 if not finite(now) then return nil end
 local delay=finite(offset) and math.floor(offset) or Schedule.MIN_OFFSET
 delay=math.clamp(delay,Schedule.MIN_OFFSET,Schedule.MAX_OFFSET)
 return now+delay
end
function Schedule.due(now,deadline)
 return finite(now) and finite(deadline) and now>=deadline
end
function Schedule.advance(now)
 if not finite(now) then return nil end
 return now+Schedule.INTERVAL
end
return Schedule
