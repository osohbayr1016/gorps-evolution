-- Restart-safe lifecycle audit coverage over the real receipt/retention modules.
-- This is pure policy evidence, not a live Roblox DataStore test.
local fs=require("@lune/fs")
local luau=require("@lune/luau")
local function load(path)
 return luau.load(fs.readFile(path),{debugName=path})()
end
local Policy=load("src/server/TradeReceiptPolicy.lua")
local Retention=load("src/server/TradeReceiptRetention.lua")
local checks=0
local function equal(actual,expected,message)
 checks+=1
 assert(actual==expected,message..": expected "..tostring(expected)..", got "..tostring(actual))
end
local function copy(value)
 if type(value)~="table" then return value end
 local result={}
 for key,item in pairs(value) do result[key]=copy(item) end
 return result
end

local createdAt=2100000000
local id="audit:aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
local function profiles()
 return {Coins=100,Inventory={Wood=5},Pets={}},
  {Coins=200,Inventory={Stone=8},Pets={}}
end
local function candidate()
 local left,right=profiles()
 return Policy.create(id,createdAt,501,502,
  {kind="Material",id="Wood",amount=1},
  {kind="Material",id="Stone",amount=2},
  left,{Coins=100,Inventory={Wood=4,Stone=2},Pets={}},
  right,{Coins=200,Inventory={Stone=6,Wood=1},Pets={}})
end

local receipt=candidate()
equal(receipt._audit.version,Policy.AUDIT_VERSION,"new audit schema")
equal(receipt._audit.createdAt,createdAt,"new audit starts at receipt creation")
equal(receipt._audit.committedAt,nil,"preparing receipt has no decision time")
equal(Policy.valid(receipt),true,"new audited receipt validates")

local left,right=profiles()
left=Policy.prepare(left,receipt,"a")
right=Policy.prepare(right,receipt,"b")
local committed=Policy.commit(receipt,left,right,createdAt+10)
equal(committed._audit.committedAt,createdAt+10,"commit records supplied store time")
equal(committed._audit.abortedAt,nil,"commit excludes abort time")
equal(Policy.valid(committed),true,"committed audit validates")
local committedRetry=Policy.commit(committed,left,right,createdAt+99)
equal(committedRetry._audit.committedAt,createdAt+10,"commit retry preserves first time")
equal(Policy.sameTransaction(receipt,committedRetry),true,
 "derived lifecycle times do not change transaction identity")

local resolvedLeft=Policy.resolve(left,committed,"a")
local resolvedRight=Policy.resolve(right,committed,"b")
local complete=Policy.complete(committed,resolvedLeft,resolvedRight,createdAt+20)
equal(complete._audit.committedAt,createdAt+10,"completion preserves commit time")
equal(complete._audit.completedAt,createdAt+20,"completion records supplied store time")
equal(Policy.valid(complete),true,"complete audit validates")
local completeRetry=Policy.complete(complete,resolvedLeft,resolvedRight,createdAt+99)
equal(completeRetry._audit.completedAt,createdAt+20,"completion retry preserves first time")

local retained=Retention.attach(complete,createdAt+25)
local archive=Retention.compact(retained,createdAt+25+Retention.SECONDS)
equal(Retention.validArchive(archive),true,"audited archive validates")
equal(archive.audit.createdAt,createdAt,"archive keeps creation time")
equal(archive.audit.committedAt,createdAt+10,"archive keeps decision time")
equal(archive.audit.completedAt,createdAt+20,"archive keeps completion time")
equal(archive.audit.abortedAt,nil,"complete archive excludes abort time")
equal(archive.participants.a.offer,nil,"archive carries no offer payload")
equal(archive.participants.a.before,nil,"archive carries no profile snapshot")

local aborted=Policy.abort(candidate(),createdAt+15)
equal(aborted._audit.abortedAt,createdAt+15,"abort records supplied store time")
equal(aborted._audit.committedAt,nil,"abort excludes commit time")
equal(Policy.abort(aborted,createdAt+99)._audit.abortedAt,createdAt+15,
 "abort retry preserves first time")
local abortArchive=Retention.compact(
 Retention.attach(aborted,createdAt+25),createdAt+25+Retention.SECONDS
)
equal(Retention.validArchive(abortArchive),true,"aborted audit archive validates")
equal(abortArchive.audit.abortedAt,createdAt+15,"archive keeps abort time")
equal(abortArchive.audit.completedAt,nil,"abort archive excludes completion time")

local legacy=candidate()
legacy._audit=nil
equal(Policy.valid(legacy),true,"legacy receipt remains recoverable")
local legacyAbort=Policy.abort(legacy,createdAt+30)
equal(legacyAbort._audit.createdAt,createdAt,"legacy transition backfills audit base")
equal(legacyAbort._audit.abortedAt,createdAt+30,"legacy transition records decision")

local invalid=copy(committed)
invalid._audit.abortedAt=createdAt+11
equal(Policy.valid(invalid),false,"conflicting decision times fail closed")
invalid=copy(complete)
invalid._audit.completedAt=createdAt+9
equal(Policy.valid(invalid),false,"completion before commit fails closed")
invalid=copy(receipt)
invalid._audit.createdAt=createdAt+1
equal(Policy.valid(invalid),false,"audit creation mismatch fails closed")
equal(Policy.commit(receipt,left,right,createdAt-1),nil,"commit before creation rejected")
equal(Policy.abort(receipt,createdAt-1),nil,"abort before creation rejected")
equal(Policy.complete(committed,resolvedLeft,resolvedRight,createdAt+9),nil,
 "completion before decision rejected")

print("PASS: "..checks.." bounded restart-safe trade audit assertions (pure policy only).")
