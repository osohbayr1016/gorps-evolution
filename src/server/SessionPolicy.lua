-- Pure persisted-session policy. Data.lua is the only module that performs I/O.
-- Reserved fields are stripped by Rules.load before a profile reaches gameplay.
local Policy={}
Policy.TIMEOUT=300

local function copy(value)
 if type(value)~="table" then return value end
 local result={}
 for key,item in pairs(value) do result[key]=copy(item) end
 return result
end
local function validToken(token)
 return type(token)=="string" and #token>=16 and #token<=200
end
local function validTime(now)
 return type(now)=="number" and now==now and now>=0
  and now<math.huge and now%1==0
end
local function validLock(lock)
 return type(lock)=="table" and validToken(lock.id)
  and validTime(lock.expiresAt)
end
function Policy.owns(stored,token)
 return type(stored)=="table" and validToken(token)
  and validLock(stored._session) and stored._session.id==token
end
function Policy.claim(stored,token,now)
 if not validToken(token) or not validTime(now) then
  return nil,"Invalid session claim"
 end
 if stored~=nil and type(stored)~="table" then
  return nil,"Corrupt profile value"
 end
 local nextValue=copy(stored or {})
 local lock=nextValue._session
 if lock~=nil then
  if not validLock(lock) then return nil,"Corrupt session lock" end
  if lock.id~=token and lock.expiresAt>now then
   return nil,"Profile is active on another server"
  end
 end
 nextValue._session={id=token,expiresAt=now+Policy.TIMEOUT}
 return nextValue
end
function Policy.save(stored,snapshot,token,now,release)
 if not validToken(token) or not validTime(now) or type(snapshot)~="table" then
  return nil,"Invalid session save"
 end
 -- An error response can hide a successful release. A same-token retry may
 -- acknowledge that terminal state, but never a later server's release.
 if release and type(stored)=="table" and stored._session==nil
  and stored._lastSession==token then
  return copy(stored)
 end
 if not Policy.owns(stored,token) then
  return nil,"Session ownership lost"
 end
 local nextValue=copy(snapshot)
 nextValue._lastSession=token
 if release then
  nextValue._session=nil
 else
  nextValue._session={id=token,expiresAt=now+Policy.TIMEOUT}
 end
 return nextValue
end
function Policy.confirms(stored,token,release)
 if release then
  return type(stored)=="table" and stored._session==nil
   and stored._lastSession==token
 end
 return Policy.owns(stored,token)
end
return Policy
