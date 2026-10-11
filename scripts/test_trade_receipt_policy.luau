-- Deterministic crash/unknown-response model for the pure trade receipt policy.
-- This is not a live DataStoreService test and does not enable published trades.
local fs=require("@lune/fs")
local luau=require("@lune/luau")
local chunk=luau.load(fs.readFile("src/server/TradeReceiptPolicy.lua"),{
 debugName="src/server/TradeReceiptPolicy.lua",
})
local Policy=chunk()
local checks=0
local function equal(actual,expected,message)
 checks+=1
 assert(actual==expected,message..": expected "..tostring(expected)..", got "..tostring(actual))
end
local function beforeProfiles()
 return {
  Coins=500,Inventory={Wood=100,Stone=10},Pets={},
  _session={id="session-a:111111111111",expiresAt=1800000300},
 },{
  Coins=400,Inventory={Wood=20,Stone=100},Pets={},
  _session={id="session-b:222222222222",expiresAt=1800000300},
 }
end
local function afterProfiles()
 return {Coins=500,Inventory={Wood=90,Stone=20},Pets={}},
  {Coins=400,Inventory={Wood=30,Stone=90},Pets={}}
end
local receiptId="trade:aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
local offerA={kind="Material",id="Wood",amount=10}
local offerB={kind="Material",id="Stone",amount=10}
local function newReceipt()
 local left,right=beforeProfiles()
 local afterLeft,afterRight=afterProfiles()
 return Policy.create(receiptId,1800000000,101,202,offerA,offerB,
  left,afterLeft,right,afterRight)
end
local function assertBefore(left,right,label)
 equal(left.Inventory.Wood,100,label.." left wood")
 equal(left.Inventory.Stone,10,label.." left stone")
 equal(right.Inventory.Wood,20,label.." right wood")
 equal(right.Inventory.Stone,100,label.." right stone")
 equal(left._trade,nil,label.." left marker cleared")
 equal(right._trade,nil,label.." right marker cleared")
end
local function assertAfter(left,right,label)
 equal(left.Inventory.Wood,90,label.." left wood")
 equal(left.Inventory.Stone,20,label.." left stone")
 equal(right.Inventory.Wood,30,label.." right wood")
 equal(right.Inventory.Stone,90,label.." right stone")
 equal(left._trade,nil,label.." left marker cleared")
 equal(right._trade,nil,label.." right marker cleared")
 equal(left._session.id,"session-a:111111111111",label.." left session preserved")
 equal(right._session.id,"session-b:222222222222",label.." right session preserved")
end

local original=newReceipt()
equal(Policy.valid(original),true,"new receipt valid")
equal(original.state,Policy.PREPARING,"new receipt starts preparing")
offerA.amount=999
equal(original.participants.a.offer.amount,10,"receipt offer is immutable copy")
offerA.amount=10
local duplicate=newReceipt()
equal(Policy.same(original,duplicate),true,"same receipt retry is recognizable")

local left,right=beforeProfiles()
local preparedA,reason=Policy.prepare(left,original,"a")
equal(reason,nil,"left prepare succeeds")
equal(Policy.prepared(preparedA,original,"a"),true,"left marker confirms")
equal(preparedA.Inventory.Wood,100,"prepare does not deduct assets")
equal(left._trade,nil,"prepare does not mutate input")
equal(Policy.same(original,newReceipt()),true,"prepare does not mutate receipt")
equal(Policy.prepare(preparedA,original,"a")._trade.id,receiptId,"prepare retry is idempotent")
local changed=beforeProfiles()
changed.Inventory.Wood=99
equal(Policy.prepare(changed,original,"a"),nil,"changed profile cannot prepare")
local conflict=beforeProfiles()
conflict._trade={version=1,id="trade:ffffffff-1111-2222-3333-444444444444",role="a"}
equal(Policy.prepare(conflict,original,"a"),nil,"different pending marker blocks prepare")
equal(Policy.commit(original,preparedA,right),nil,"one marker cannot commit")
local preparedB=Policy.prepare(right,original,"b")
local committed=Policy.commit(original,preparedA,preparedB)
equal(committed.state,Policy.COMMITTED,"both markers commit")
equal(Policy.commit(committed,preparedA,preparedB).state,Policy.COMMITTED,"commit retry is idempotent")
equal(Policy.abort(committed),nil,"committed receipt cannot abort")
equal(Policy.resolve(preparedA,original,"a"),nil,"preparing receipt cannot apply")
local resolvedA=Policy.resolve(preparedA,committed,"a")
local resolvedB=Policy.resolve(preparedB,committed,"b")
assertAfter(resolvedA,resolvedB,"direct commit")
equal(Policy.resolve(resolvedA,committed,"a").Inventory.Stone,20,"apply retry does not duplicate")
equal(Policy.complete(committed,resolvedA,preparedB),nil,"one result cannot complete")
local complete=Policy.complete(committed,resolvedA,resolvedB)
equal(complete.state,Policy.COMPLETE,"both results complete receipt")
equal(Policy.complete(complete,resolvedA,resolvedB).state,Policy.COMPLETE,"complete retry idempotent")
equal(Policy.complete(committed,resolvedA,resolvedA),nil,"one participant result cannot impersonate both roles")

-- Simulate a crash after each durable write: receipt, prepare A, prepare B,
-- commit, apply A, apply B, and completion. Recovery must converge safely.
for crashAfter=1,7 do
 local receipt=newReceipt()
 local crashLeft,crashRight=beforeProfiles()
 if crashAfter>=2 then crashLeft=Policy.prepare(crashLeft,receipt,"a") end
 if crashAfter>=3 then crashRight=Policy.prepare(crashRight,receipt,"b") end
 if crashAfter>=4 then receipt=Policy.commit(receipt,crashLeft,crashRight) end
 if crashAfter>=5 then crashLeft=Policy.resolve(crashLeft,receipt,"a") end
 if crashAfter>=6 then crashRight=Policy.resolve(crashRight,receipt,"b") end
 if crashAfter>=7 then receipt=Policy.complete(receipt,crashLeft,crashRight) end

 if receipt.state==Policy.PREPARING then receipt=Policy.abort(receipt) end
 if crashLeft._trade then crashLeft=Policy.resolve(crashLeft,receipt,"a") end
 if crashRight._trade then crashRight=Policy.resolve(crashRight,receipt,"b") end
 if receipt.state==Policy.COMMITTED then
  receipt=Policy.complete(receipt,crashLeft,crashRight)
 end
 if crashAfter<4 then
  equal(receipt.state,Policy.ABORTED,"pre-commit crash aborts at boundary "..crashAfter)
  assertBefore(crashLeft,crashRight,"boundary "..crashAfter)
 else
  equal(receipt.state,Policy.COMPLETE,"post-commit crash completes at boundary "..crashAfter)
  assertAfter(crashLeft,crashRight,"boundary "..crashAfter)
 end
end

local aborted=Policy.abort(newReceipt())
equal(aborted.state,Policy.ABORTED,"preparing receipt aborts")
equal(Policy.abort(aborted).state,Policy.ABORTED,"abort retry is idempotent")
local abortLeft,abortRight=beforeProfiles()
abortLeft=Policy.prepare(abortLeft,newReceipt(),"a")
abortLeft=Policy.resolve(abortLeft,aborted,"a")
assertBefore(abortLeft,abortRight,"explicit abort")
equal(Policy.resolve(abortLeft,aborted,"a").Inventory.Wood,100,"abort retry preserves assets")
equal(Policy.complete(aborted,abortLeft,abortRight),nil,"aborted receipt cannot complete")

local wrongRoleLeft=beforeProfiles()
wrongRoleLeft=Policy.prepare(wrongRoleLeft,newReceipt(),"a")
equal(Policy.resolve(wrongRoleLeft,committed,"b"),nil,"wrong participant cannot resolve marker")
wrongRoleLeft._trade.userId=202
equal(Policy.prepared(wrongRoleLeft,committed,"a"),false,"wrong user ID cannot confirm marker")
equal(Policy.create("short",1800000000,101,202,offerA,offerB,{}, {}, {}, {}),nil,
 "short receipt ID rejected")
equal(Policy.create(receiptId,1800000000,101,101,offerA,offerB,{}, {}, {}, {}),nil,
 "same participant rejected")

print("PASS: "..checks.." trade receipt assertions across seven crash boundaries (pure policy only).")
