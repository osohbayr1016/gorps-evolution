-- Concrete Roblox DataStore UpdateAsync boundary for durable trades.
-- It records only bounded operational metadata; no keys, offers or snapshots.
local Adapter={}
Adapter.VERSION=1

local function clean(value,limit)
 local text=tostring(value or "Unknown error")
 text=text:gsub("[%c]"," "):gsub("%s+"," ")
 return text:sub(1,limit)
end
local function redactKey(value,key)
 local text=clean(value,160)
 if type(key)=="string" and #key>0 then
  local pattern=key:gsub("(%W)","%%%1")
  text=text:gsub(pattern,"[redacted-key]")
 end
 return text
end

function Adapter.classify(reason)
 local value=string.lower(tostring(reason or ""))
 if value:find("throttl",1,true) or value:find("too many requests",1,true)
  or value:find("request limit",1,true) then return "THROTTLED" end
 if value:find("budget",1,true) then return "BUDGET" end
 if value:find("timeout",1,true) or value:find("timed out",1,true)
  or value:find("http 5",1,true) or value:find("service unavailable",1,true)
  or value:find("internal server",1,true) or value:find("response loss",1,true)
  or value:find("connection",1,true) then return "TRANSIENT" end
 if value:find("api access",1,true) or value:find("permission",1,true)
  or value:find("unauthorized",1,true) or value:find("forbidden",1,true)
  or value:find("403",1,true) then return "CONFIG" end
 return "UNKNOWN"
end

local function scope(key)
 if type(key)~="string" then return "invalid" end
 if key:sub(1,6)=="trade_" then return "receipt" end
 if key:sub(1,7)=="player_" or key:sub(1,8)=="profile/" then return "profile" end
 return "other"
end

function Adapter.new(liveStore,options)
 options=type(options)=="table" and options or {}
 local record=type(options.record)=="function" and options.record or function() end
 local now=type(options.now)=="function" and options.now or os.time
 local wrapper={}
 local function emit(kind,fields)
  local event={scope=fields.scope,status=fields.status}
  if type(fields.id)=="string" then event.id=fields.id:sub(1,44) end
  if fields.reason~=nil then event.reason=clean(fields.reason,160) end
  pcall(record,kind,event)
 end
 function wrapper:update(key,transform)
  if liveStore==nil or type(liveStore.UpdateAsync)~="function"
   or type(key)~="string" or #key==0 or type(transform)~="function" then
   emit("datastore_update_failed",{
    scope=scope(key),status="CONFIG",reason="Invalid DataStore adapter request",
   })
   return nil,"Invalid DataStore adapter request"
  end
  local rejected
  local ok,value=pcall(function()
   return liveStore:UpdateAsync(key,function(old)
    local nextValue,reason=transform(old)
    rejected=reason
    return nextValue
   end)
  end)
  if not ok then
   local reason=redactKey(value,key)
   emit("datastore_update_failed",{
    scope=scope(key),status=Adapter.classify(reason),reason=reason,
   })
   return nil,reason
  end
  if value==nil then
   local reason=redactKey(rejected or "Update rejected",key)
   emit("datastore_update_rejected",{
    scope=scope(key),status="REJECTED",reason=reason,
   })
   return nil,reason
  end
  return value
 end
 function wrapper:now()
  local ok,value=pcall(now)
  if ok and type(value)=="number" then return math.floor(value) end
  return os.time()
 end
 function wrapper:diagnostic(kind,fields)
  fields=type(fields)=="table" and fields or {}
  emit(clean(kind,40),fields)
 end
 return wrapper
end

return Adapter
