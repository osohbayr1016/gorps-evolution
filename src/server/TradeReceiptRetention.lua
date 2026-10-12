-- Pure retention policy for terminal durable-trade receipts.
-- Full snapshots are compacted only after both profiles are known terminal.
local Retention={}
Retention.VERSION=1
Retention.ARCHIVED="ARCHIVED"
Retention.SECONDS=30*24*60*60

local function copy(value)
 if type(value)~="table" then return value end
 local result={}
 for key,item in pairs(value) do result[key]=copy(item) end
 return result
end
local function whole(value,minimum,maximum)
 return type(value)=="number" and value==value and value%1==0
  and value>=minimum and value<=maximum
end
local function terminal(receipt)
 return type(receipt)=="table" and receipt.version==1
  and type(receipt.id)=="string" and #receipt.id>=16 and #receipt.id<=44
  and whole(receipt.createdAt,0,10^15)
  and (receipt.state=="COMPLETE" or receipt.state=="ABORTED")
  and type(receipt.participants)=="table"
  and type(receipt.participants.a)=="table"
  and type(receipt.participants.b)=="table"
  and whole(receipt.participants.a.userId,1,10^15)
  and whole(receipt.participants.b.userId,1,10^15)
  and receipt.participants.a.userId~=receipt.participants.b.userId
end
local function validSchedule(receipt)
 local schedule=type(receipt)=="table" and receipt._retention or nil
 return type(schedule)=="table" and schedule.version==Retention.VERSION
  and whole(schedule.terminalAt,receipt.createdAt,10^15)
  and schedule.compactAfter==schedule.terminalAt+Retention.SECONDS
end

function Retention.attach(receipt,terminalAt)
 if not terminal(receipt) or not whole(terminalAt,receipt.createdAt,10^15) then
  return nil,"Invalid terminal receipt retention"
 end
 if receipt._retention~=nil then
  if validSchedule(receipt) then return copy(receipt) end
  return nil,"Conflicting receipt retention metadata"
 end
 local nextValue=copy(receipt)
 nextValue._retention={
  version=Retention.VERSION,
  terminalAt=terminalAt,
  compactAfter=terminalAt+Retention.SECONDS,
 }
 return nextValue
end

function Retention.due(receipt,now)
 return terminal(receipt) and validSchedule(receipt)
  and whole(now,0,10^15) and now>=receipt._retention.compactAfter
end

function Retention.compact(receipt,now)
 if not Retention.due(receipt,now) then
  return nil,"Receipt retention is not due"
 end
 return {
  version=Retention.VERSION,
  state=Retention.ARCHIVED,
  id=receipt.id,
  createdAt=receipt.createdAt,
  outcome=receipt.state,
  participants={
   a={userId=receipt.participants.a.userId},
   b={userId=receipt.participants.b.userId},
  },
  retention={
   terminalAt=receipt._retention.terminalAt,
   archivedAt=now,
  },
 }
end

function Retention.validArchive(value)
 return type(value)=="table" and value.version==Retention.VERSION
  and value.state==Retention.ARCHIVED
  and type(value.id)=="string" and #value.id>=16 and #value.id<=44
  and whole(value.createdAt,0,10^15)
  and (value.outcome=="COMPLETE" or value.outcome=="ABORTED")
  and type(value.participants)=="table"
  and type(value.participants.a)=="table"
  and type(value.participants.b)=="table"
  and whole(value.participants.a.userId,1,10^15)
  and whole(value.participants.b.userId,1,10^15)
  and value.participants.a.userId~=value.participants.b.userId
  and type(value.retention)=="table"
  and whole(value.retention.terminalAt,value.createdAt,10^15)
  and whole(value.retention.archivedAt,value.retention.terminalAt,10^15)
end

function Retention.matchesArchive(value,marker)
 if not Retention.validArchive(value) or type(marker)~="table" then return false end
 if marker.id~=value.id or (marker.role~="a" and marker.role~="b") then return false end
 local expected=value.outcome=="COMPLETE" and "COMMITTED" or "ABORTED"
 return marker.version==1 and marker.userId==value.participants[marker.role].userId
  and marker.outcome==expected
end

return Retention
