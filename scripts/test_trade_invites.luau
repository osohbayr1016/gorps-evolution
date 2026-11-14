-- Headless state-machine tests of the real same-server invitation router.
-- These tests do not substitute for a Roblox Studio two-client playtest.
local fs=require("@lune/fs")
local luau=require("@lune/luau")
local now=1000
local players={}
local names={}
function players:FindFirstChild(name) return names[name] end
local function player(name,id)
 local value={Name=name,UserId=id,Parent=players}
 names[name]=value
 return value
end
local alice=player("Alice",11)
local bob=player("Bob",12)
local cara=player("Cara",13)
local eve=player("Eve",14)
local modules={}
local function loadShared(name)
 if modules[name] then return modules[name] end
 local path="src/shared/"..name..".lua"
 local chunk=luau.load(fs.readFile(path),{
  debugName=path,
  environment={
   script={Parent={Config="Config",Rules="Rules"}},
   require=function(dependency)
    assert(type(dependency)=="string","Unexpected shared dependency")
    return loadShared(dependency)
   end,
  },
 })
 modules[name]=chunk()
 return modules[name]
end
local shared={Config="Config",Rules="Rules",TradeRules="TradeRules"}
local tradeChunk=luau.load(fs.readFile("src/server/Trade.lua"),{
 debugName="src/server/Trade.lua",
 environment={
  game={GetService=function(_,name)
   if name=="Players" then return players end
   if name=="ReplicatedStorage" then return {Shared=shared} end
   error("Unexpected service: "..name)
  end},
  script={Parent={}},
  require=function(dependency) return loadShared(dependency) end,
  os={clock=function() return now end},
 },
})
local Trade=tradeChunk()
local Rules=loadShared("Rules")
local profiles={}
for _,who in ipairs({alice,bob,cara,eve}) do profiles[who]=Rules.new(now) end
local messages={}
local function emit(who,message)
 table.insert(messages,{to=who.Name,message=message})
end
local function get(who) return profiles[who] end
local function changed() end
local checks=0
local function equal(actual,expected,label)
 checks+=1
 assert(actual==expected,label..": expected "..tostring(expected)..", got "..tostring(actual))
end
local function action(who,name,args)
 return Trade.action(who,name,args or {},get,changed,emit)
end

equal(action(alice,"Invite",{target="Bob"}),true,"first invitation succeeds")
equal(Trade.status(bob).pendingFrom,"Alice","recipient sees invitation")
equal(#messages,1,"first invitation emits one notification")
equal(action(alice,"Invite",{target="Cara"}),false,"sender cooldown prevents spam")
equal(#messages,1,"rejected spam emits no notification")
now=1005
equal(action(cara,"Invite",{target="Bob"}),false,"another inviter cannot overwrite pending consent")
equal(Trade.status(bob).pendingFrom,"Alice","original invitation cannot be hijacked")
equal(#messages,1,"overwritten invitation is not notified")
now=1029
equal(Trade.status(bob).pendingFrom,"Alice","invitation remains valid before 30-second limit")
now=1030
equal(Trade.status(bob).pendingFrom,nil,"invitation expires exactly at deadline")
equal(action(bob,"Join"),false,"expired invitation cannot create trade session")
equal(Trade.status(bob).partner,nil,"expired recipient has no partner")
now=1031
equal(action(alice,"Invite",{target="Bob"}),true,"sender may re-invite after expiry")
equal(action(eve,"Join"),false,"third party cannot join someone else's invite")
equal(action(bob,"Join"),true,"fresh invite joins")
equal(Trade.status(alice).partner,"Bob","inviter sees joined partner")
equal(Trade.status(bob).partner,"Alice","recipient sees joined partner")
equal(action(bob,"Cancel"),true,"recipient cancels active session")
equal(Trade.status(alice).partner,nil,"cancellation clears inviter session")
equal(Trade.status(bob).partner,nil,"cancellation clears recipient session")
now=1040
equal(action(alice,"Invite",{target="Bob"}),true,"sender can issue an invite after cancellation")
now=1044
equal(action(alice,"Invite",{target="Cara"}),false,"only one outgoing invite can remain pending")
equal(Trade.status(alice).pendingTo,"Bob","inviter sees their sole pending recipient")
equal(Trade.status(bob).pendingFrom,"Alice","first pending recipient remains assigned")
equal(Trade.status(cara).pendingFrom,nil,"second recipient never receives stale consent")
equal(action(bob,"Join"),true,"first recipient may still accept")
equal(Trade.status(alice).pendingTo,nil,"joined trade clears outgoing invitation")
equal(action(bob,"Cancel"),true,"joined trade can cancel safely")
now=1048
equal(action(alice,"Invite",{target="Cara"}),true,"sender can invite another player after cancellation")
equal(Trade.status(alice).pendingTo,"Cara","outgoing status follows current recipient")
alice.Parent=nil
Trade.leave(alice,emit)
equal(Trade.status(bob).pendingFrom,nil,"disconnect leaves no stale first invite")
equal(Trade.status(cara).pendingFrom,nil,"disconnect invalidates pending new invite")
equal(action(bob,"Join"),false,"recipient cannot join disconnected inviter")
equal(action(cara,"Join"),false,"second recipient cannot join disconnected inviter")
-- Cancel only withdraws pending invites; it cannot erase anti-spam history.
now=1045
equal(action(bob,"Invite",{target="Eve"}),true,"invite before cancellation succeeds")
equal(action(bob,"Cancel"),true,"cancelling outgoing invite succeeds")
local notified=#messages
now=1045.25
equal(action(bob,"Invite",{target="Eve"}),false,"cancel cannot bypass sender cooldown")
equal(#messages,notified,"cancel and immediate resend never spam recipient")
now=1049
equal(action(cara,"Invite",{target="Eve"}),true,"other inviter can invite independently")
equal(Trade.status(eve).pendingFrom,"Cara","recipient can read pending state before leave")
eve.Parent=nil
equal(Trade.status(eve).pendingFrom,nil,"disconnected recipient cannot retain invitation")
cara.Parent=nil
equal(Trade.status(eve).pendingFrom,nil,"disconnected sender invalidates invitation")
eve.Parent=players
cara.Parent=players
-- Re-enter each action from inside an asynchronous settlement callback to
-- simulate concurrent RemoteFunction invocations while the trade is pending.
now=1060
equal(action(bob,"Invite",{target="Cara"}),true,"sender starts new two-party trade")
equal(action(cara,"Join"),true,"recipient joins consented invite")
equal(action(bob,"OfferMaterial",{resource="Wood",amount=1}),true,"first party offers wood")
equal(action(cara,"OfferMaterial",{resource="Stone",amount=1}),true,"second party offers stone")
equal(action(bob,"Accept"),true,"first party accepts the current snapshot")
local overlapChecks=0
local function blockedSettlement(left,right,leftOffer,rightOffer)
 equal(left,bob,"settlement receives first party")
 equal(right,cara,"settlement receives second party")
 equal(leftOffer.id,"Wood","settlement snapshots first offer")
 equal(rightOffer.id,"Stone","settlement snapshots second offer")
 local cancelOK,cancelMessage=Trade.action(bob,"Cancel",{},get,changed,emit)
 equal(cancelOK,false,"concurrent cancel denied during finalization")
 equal(cancelMessage,"Trade is finalizing","cancel describes finalization lock")
 local editOK=Trade.action(cara,"OfferMaterial",{resource="Stone",amount=2},get,changed,emit)
 equal(editOK,false,"concurrent offer edit denied during finalization")
 local retryOK=Trade.action(bob,"Accept",{},get,changed,emit)
 equal(retryOK,false,"concurrent double accept denied during finalization")
 local state=Trade.status(bob)
 equal(state.finalizing,true,"both parties see finalization flag during settlement")
 overlapChecks+=1
 return false,"Simulated safe rollback"
end
local attempted,reason=Trade.action(cara,"Accept",{},get,changed,emit,blockedSettlement)
equal(attempted,false,"failed settlement returns without a trade")
equal(reason,"Simulated safe rollback","safe settlement error is returned")
equal(overlapChecks,1,"settlement callback was invoked exactly once")
equal(Trade.status(bob).finalizing,false,"failed settlement releases finalization lock")
equal(Trade.status(bob).mine.id,"Wood","failed settlement retains original offer")
equal(Trade.status(cara).mine.id,"Stone","failed settlement retains partner offer")
equal(Trade.status(bob).acceptedMine,false,"failed settlement resets consent")
equal(action(bob,"Accept"),true,"first party can explicitly reaccept")
local failed,failMessage=Trade.action(cara,"Accept",{},get,changed,emit,
 function() error("Simulated unexpected settlement error") end)
equal(failed,false,"exception in settlement is contained")
equal(failMessage,"Trade could not be finalized","exception is normalized")
equal(Trade.status(cara).finalizing,false,"exception unlocks trade")
equal(action(bob,"Accept"),true,"first party reaccepts after exception")
local success,successMessage=Trade.action(cara,"Accept",{},get,changed,emit,
 function() return true,"Trade completed" end)
equal(success,true,"successful durable adapter result completes trade")
equal(successMessage,"Trade completed","successful settlement response")
equal(Trade.status(bob).partner,nil,"successful settlement removes first session")
equal(Trade.status(cara).partner,nil,"successful settlement removes second session")

-- Real router offers must show immutable creature attributes to both
-- players and refuse finalization if a creature was trained after approval.
now=1110
equal(action(bob,"Invite",{target="Cara"}),true,"new pet trade invitation sent")
equal(action(cara,"Join"),true,"pet trade invitation joined")
local bProfile=get(bob)
local cProfile=get(cara)
equal(Rules.addPet(bProfile,"Shade"),true,"sender owns an inactive offered pet")
local petId=bProfile.Pets[#bProfile.Pets].id
equal(action(bob,"OfferPet",{id=petId}),true,"sender offers exact pet snapshot")
local mine=Trade.status(bob).mine
local theirs=Trade.status(cara).theirs
equal(mine.pet.species,"Shade","server records offered creature species")
equal(theirs.pet.rarity,"Uncommon","recipient sees offered creature rarity")
equal(theirs.pet.level,1,"recipient sees agreed creature level")
equal(theirs.pet.evolved,0,"recipient sees agreed evolution tier")
equal(action(cara,"OfferMaterial",{resource="Stone",amount=1}),true,
 "partner offers material for pet")
equal(action(cara,"Accept"),true,"partner accepts the original creature offer")
local stoneBefore=cProfile.Inventory.Stone
bProfile.Pets[#bProfile.Pets].xp+=35
local denied,deniedMessage=action(bob,"Accept")
equal(denied,false,"trade cannot settle a modified pet")
equal(deniedMessage,"Offered creature changed; refresh your offer and accept again",
 "recipient receives explicit changed-offer warning")
equal(cProfile.Inventory.Stone,stoneBefore,"failed consent never spends partner material")
equal(#bProfile.Pets,2,"failed consent preserves sender pet")
equal(Trade.status(cara).acceptedMine,false,"failed consent resets partner acceptance")
equal(action(bob,"OfferPet",{id=petId}),true,"sender refreshes modified offer")
equal(Trade.status(cara).theirs.pet.xp,35,"recipient sees new pet XP")
equal(action(cara,"Accept"),true,"partner accepts updated pet details")
equal(action(bob,"Accept"),true,"unchanged snapshot settles successfully")
equal(cProfile.Pets[2].species,"Shade","recipient receives exact named creature")
equal(cProfile.Pets[2].xp,35,"received pet retains accepted XP")
equal(Trade.status(bob).partner,nil,"completed pet trade clears both sessions")

print("PASS: "..checks.." trade invitation assertions (Studio multiplayer QA remains pending).")
