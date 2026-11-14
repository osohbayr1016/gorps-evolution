-- Client-side acceptance policy for authoritative per-player state snapshots.
-- A late action response must never roll back a newer server push.
local Order={}
function Order.accept(lastSeen,sequence)
 local last=type(lastSeen)=="number" and lastSeen or 0
 if type(sequence)~="number" or sequence~=sequence or sequence%1~=0
  or sequence<1 or sequence>9007199254740991 then
  return false,last
 end
 if sequence<=last then return false,last end
 return true,sequence
end
return Order
