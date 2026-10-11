-- Pure two-profile trade receipt policy. It performs no DataStore I/O.
-- Published trading stays disabled until Data.lua integrates this policy and
-- private-server fault injection proves every write boundary.
local Policy={}
Policy.VERSION=1
Policy.PREPARING="PREPARING"
Policy.COMMITTED="COMMITTED"
Policy.ABORTED="ABORTED"
Policy.COMPLETE="COMPLETE"

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
local function validId(id)
 return type(id)=="string" and #id>=16 and #id<=44
end
local function equal(left,right)
 if type(left)~=type(right) then return false end
 if type(left)~="table" then return left==right end
 for key,value in pairs(left) do
  if not equal(value,right[key]) then return false end
 end
 for key in pairs(right) do
  if left[key]==nil then return false end
 end
 return true
end
local function gameplay(profile)
 if type(profile)~="table" then return nil end
 local result={}
 for key,value in pairs(profile) do
  if type(key)~="string" or key:sub(1,1)~="_" then
   result[key]=copy(value)
  end
 end
 return result
end
local function validParticipant(participant)
 return type(participant)=="table" and whole(participant.userId,1,10^15)
  and type(participant.offer)=="table" and type(participant.before)=="table"
  and type(participant.after)=="table"
end
local function validReceipt(receipt)
 if type(receipt)~="table" or receipt.version~=Policy.VERSION
  or not validId(receipt.id) or not whole(receipt.createdAt,0,10^15)
  or type(receipt.participants)~="table"
  or not validParticipant(receipt.participants.a)
  or not validParticipant(receipt.participants.b)
  or receipt.participants.a.userId==receipt.participants.b.userId then
  return false
 end
 return receipt.state==Policy.PREPARING or receipt.state==Policy.COMMITTED
  or receipt.state==Policy.ABORTED or receipt.state==Policy.COMPLETE
end
local function markerMatches(profile,receipt,role)
 local marker=type(profile)=="table" and profile._trade or nil
 return type(marker)=="table" and marker.version==Policy.VERSION
  and marker.id==receipt.id and marker.role==role
  and marker.userId==receipt.participants[role].userId
end
local function resultMatches(profile,receipt,role,outcome)
 local result=type(profile)=="table" and profile._tradeResult or nil
 return type(result)=="table" and result.version==Policy.VERSION
  and result.id==receipt.id and result.role==role
  and result.userId==receipt.participants[role].userId
  and result.outcome==outcome and profile._trade==nil
end
local function preserveReserved(target,stored)
 for key,value in pairs(stored) do
  if type(key)=="string" and key:sub(1,1)=="_"
   and key~="_trade" and key~="_tradeResult" then
   target[key]=copy(value)
  end
 end
end

function Policy.create(id,createdAt,leftUserId,rightUserId,leftOffer,rightOffer,
 leftBefore,leftAfter,rightBefore,rightAfter)
 local receipt={
  version=Policy.VERSION,id=id,createdAt=createdAt,state=Policy.PREPARING,
  participants={
   a={userId=leftUserId,offer=copy(leftOffer),before=gameplay(leftBefore),after=gameplay(leftAfter)},
   b={userId=rightUserId,offer=copy(rightOffer),before=gameplay(rightBefore),after=gameplay(rightAfter)},
  },
 }
 if not validReceipt(receipt) then return nil,"Invalid trade receipt" end
 return receipt
end
function Policy.valid(receipt) return validReceipt(receipt) end
function Policy.same(left,right)
 return validReceipt(left) and validReceipt(right) and equal(left,right)
end
function Policy.sameTransaction(left,right)
 if not validReceipt(left) or not validReceipt(right) then return false end
 local leftValue=copy(left)
 local rightValue=copy(right)
 leftValue.state=Policy.PREPARING
 rightValue.state=Policy.PREPARING
 return equal(leftValue,rightValue)
end
function Policy.prepare(profile,receipt,role)
 if not validReceipt(receipt) or receipt.state~=Policy.PREPARING
  or (role~="a" and role~="b") or type(profile)~="table" then
  return nil,"Invalid trade preparation"
 end
 if resultMatches(profile,receipt,role,Policy.ABORTED)
  or resultMatches(profile,receipt,role,Policy.COMMITTED) then
  return nil,"Trade already resolved"
 end
 if profile._trade~=nil then
  if markerMatches(profile,receipt,role) then return copy(profile) end
  return nil,"Profile already has another pending trade"
 end
 if not equal(gameplay(profile),receipt.participants[role].before) then
  return nil,"Profile changed before trade preparation"
 end
 local nextValue=copy(profile)
 nextValue._trade={version=Policy.VERSION,id=receipt.id,role=role,
  userId=receipt.participants[role].userId}
 return nextValue
end
function Policy.prepared(profile,receipt,role)
 return validReceipt(receipt) and markerMatches(profile,receipt,role)
end
function Policy.commit(receipt,leftProfile,rightProfile)
 if not validReceipt(receipt) then return nil,"Invalid trade receipt" end
 if receipt.state==Policy.COMMITTED or receipt.state==Policy.COMPLETE then
  return copy(receipt)
 end
 if receipt.state~=Policy.PREPARING then return nil,"Trade cannot commit" end
 if not markerMatches(leftProfile,receipt,"a")
  or not markerMatches(rightProfile,receipt,"b") then
  return nil,"Both profiles must be prepared"
 end
 local nextValue=copy(receipt)
 nextValue.state=Policy.COMMITTED
 return nextValue
end
function Policy.abort(receipt)
 if not validReceipt(receipt) then return nil,"Invalid trade receipt" end
 if receipt.state==Policy.ABORTED then return copy(receipt) end
 if receipt.state~=Policy.PREPARING then return nil,"Committed trade cannot abort" end
 local nextValue=copy(receipt)
 nextValue.state=Policy.ABORTED
 return nextValue
end
function Policy.resolve(profile,receipt,role)
 if not validReceipt(receipt) or (role~="a" and role~="b")
  or type(profile)~="table" then return nil,"Invalid trade recovery" end
 local outcome=receipt.state==Policy.ABORTED and Policy.ABORTED
  or ((receipt.state==Policy.COMMITTED or receipt.state==Policy.COMPLETE) and Policy.COMMITTED or nil)
 if not outcome then return nil,"Trade decision is still preparing" end
 if resultMatches(profile,receipt,role,outcome) then return copy(profile) end
 if not markerMatches(profile,receipt,role) then
  return nil,"Profile trade marker mismatch"
 end
 local nextValue
 if outcome==Policy.COMMITTED then
  nextValue=copy(receipt.participants[role].after)
  preserveReserved(nextValue,profile)
 else
  nextValue=copy(profile)
  nextValue._trade=nil
 end
 nextValue._tradeResult={version=Policy.VERSION,id=receipt.id,role=role,
  userId=receipt.participants[role].userId,outcome=outcome}
 return nextValue
end
function Policy.resolved(profile,receipt,role,outcome)
 return validReceipt(receipt) and (role=="a" or role=="b")
  and resultMatches(profile,receipt,role,outcome)
end
function Policy.complete(receipt,leftProfile,rightProfile)
 if not validReceipt(receipt) then return nil,"Invalid trade receipt" end
 if receipt.state==Policy.COMPLETE then return copy(receipt) end
 if receipt.state~=Policy.COMMITTED then return nil,"Trade is not committed" end
 if not resultMatches(leftProfile,receipt,"a",Policy.COMMITTED)
  or not resultMatches(rightProfile,receipt,"b",Policy.COMMITTED) then
  return nil,"Both profiles must resolve before completion"
 end
 local nextValue=copy(receipt)
 nextValue.state=Policy.COMPLETE
 return nextValue
end
return Policy
