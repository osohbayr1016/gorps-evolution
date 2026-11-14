#!/usr/bin/env python3
"""Static contract checks for Gorps' first playable loop (not Roblox runtime tests)."""
from pathlib import Path
config=Path("src/shared/Config.lua").read_text()
rules=Path("src/shared/Rules.lua").read_text()
server=Path("src/server/Main.server.lua").read_text()
world=Path("src/server/World.lua").read_text()
ui=Path("src/client/Ui.lua").read_text()
pages=Path("src/client/Pages.lua").read_text()
client=Path("src/client/Main.client.lua").read_text()
smoke=Path("src/server/StudioSmoke.server.lua").read_text()
data=Path("src/server/Data.lua").read_text()
sessions=Path("src/server/SessionPolicy.lua").read_text()
trade=Path("src/server/Trade.lua").read_text()
trade_receipts=Path("src/server/TradeReceiptPolicy.lua").read_text()
trade_retention=Path("src/server/TradeReceiptRetention.lua").read_text()
trade_audit_test=Path("scripts/test_trade_audit.luau").read_text()
trade_persistence=Path("src/server/TradePersistence.lua").read_text()
trade_store=Path("src/server/TradeStoreAdapter.lua").read_text()
trade_settlement=Path("src/server/TradeSettlement.lua").read_text()
config=Path("src/shared/Config.lua").read_text()
contracts={
 "egg pool defined": "C.Eggs={" in config and "C.EggOrder" in config,
 "server chooses hatch roll": "math.random(1,total)" in server and "R.hatchEgg(p,payload.id," in server,
 "hatch is capacity checked": "#p.Pets>=R.capacity(p)" in rules and "function R.hatchEgg" in rules,
 "no untrusted hatch roll": '"HatchEgg"' in pages and "math.random(1,total)" in server,
 "UI hatch reveal": "function UI:showHatch(pet)" in ui and "ui:showHatch(result.hatch)" in client,
 "harvest shuts off prompts": "prompt.Enabled=false" in world and "setHarvestVisibility(node,false,true)" in world,
 "harvest respawns": "setHarvestVisibility(node,true,true)" in world and 'HarvestState","Ready"' in world,
 "rare prompt uses authored anchor without moving authoritative root":
    'base:FindFirstChild("PromptAnchor")' in world
    and 'anchor:IsA("Attachment")' in world
    and 'prompt.Parent=promptParent' in world
    and '(root.Position-base.Position).Magnitude>19' in world,
 "pickup feedback": "function UI:showPickup(reward)" in ui and "ui:showPickup(data.pickup)" in client,
 "failed hunt doesn't deplete node": "if not won then" in server and "return false" in server,
 "first session smoke tests": "Starter egg regression" in smoke and "full ranch blocks hatching" in smoke,
 "server-derived worker status": all(token in server for token in (
    'snapshot.WorkerStatus=E.workerStatus(p,os.time())',
    'if action=="WorkerStatus" then return true,nil end',
    'local statusCooldown={}',
    'if action=="WorkerStatus" then statusCooldown[player]=now',
    'statusCooldown[player]=nil',
    'local amount,before=E.collect(p,now)',
    'Delivery held: earn ◆ ',
    'accrued work was not reset',
    'Workers are still working - next delivery in '
 )),
 "wage-safe automatic rejoin": 'local _,resumeStatus=E.collect(p,os.time())' in server
    and 'resumeStatus.state=="blocked"' in server
    and 'unfunded rejoin does not erase accrued work' in Path("scripts/test_worker_payroll.luau").read_text(),
 "expiring rate-limited trade invitations": all(token in trade for token in (
    'INVITE_TTL=30','INVITE_COOLDOWN=3',
    'if now-(lastInvite[id] or -100)<INVITE_COOLDOWN then',
    'if pendingSender(target) then',
    'local inviter=pendingSender(player);pending[id]=nil',
    'lastInvite[uid(player)]=nil'
 )) and Path("scripts/test_trade_invites.luau").exists(),
 "state snapshot request limited": all(token in server for token in (
    'local stateCooldown={}',
    'if action=="State" and now-(stateCooldown[player] or -100)<0.5 then',
    'if action=="State" then stateCooldown[player]=now',
    'stateCooldown[player]=nil',
 )),
 "leaderboard singleflight and stale snapshot": all(token in Path("src/server/Leaderboards.lua").read_text() for token in (
    'local refreshing=false',
    'if refreshing or (initialized and now-lastRefresh<180) then return cache end',
    'refreshing=true',
    'refreshing=false',
    'entries[id]=cache[id] or {}',
 )) and Path("scripts/test_leaderboards.luau").exists(),
 "per-player monotonic playtime with leave flush": all(token in data for token in (
    'local PlaytimeClock=require(ReplicatedStorage.Shared.PlaytimeClock)',
    'lastPlaytime[player]=os.clock()',
    'function Data.accountPlaytime(player)',
    'PlaytimeClock.advance(since,os.clock())',
    'Data.accountPlaytime(player)',
    'lastPlaytime[player]=nil'
 )) and 'Data.accountPlaytime(player)' in server
    and 'p.Seconds+=60' not in data
    and Path("scripts/test_playtime_clock.luau").exists(),
 "trade cancel cannot bypass invitation throttle": all(token in trade for token in (
    'function Trade.leave(player,emit)',
    'Trade.disconnect(player,emit)',
    'lastInvite[uid(player)]=nil',
 )) and 'Trade.leave(player,function(who,msg) send(who,msg) end)' in server
    and 'cancel cannot bypass sender cooldown' in Path("scripts/test_trade_invites.luau").read_text(),
 "one outgoing trade invite with live status": all(token in trade for token in (
    'local function outgoingTarget(sender)',
    'if outgoingTarget(player) then return false',
    'recipient=target,expiresAt=now+INVITE_TTL',
    'pendingTo=outgoing and outgoing.Name or nil',
 )) and all(token in pages for token in (
    'if tradeState.pendingTo then',
    '"INVITATION PENDING"',
    '"CANCEL INVITATION"',
 )),
 "trade settlement is mutually exclusive": all(token in trade for token in (
    'if s.settling then return false,"Trade is finalizing" end',
    'if s and s.settling and not force then return false',
    's.settling=true',
    'pcall(function()',
    's.settling=false',
 )) and all(token in pages for token in (
    'if tradeState.finalizing then',
    'not tradeState.finalizing',
 )) and 'concurrent double accept denied during finalization' in Path("scripts/test_trade_invites.luau").read_text(),
 "lossless capacity preflight": all(token in rules for token in (
    'function R.canAdd(p,goods)',
    'Backpack full: sell or spend materials before harvesting',
 )) and all(token in Path("src/shared/Economy.lua").read_text() for token in (
    'not R.canAdd(p,recipe.grant)',
    'not R.canAdd(p,item.grant)',
    'local capacity=storageSteps(p.Inventory,def,cohort.count)',
    'storageBlocked=false',
 )) and 'not Rules.canAdd(profile,{Meat=meat})' in Path("src/shared/Adventure.lua").read_text()
    and 'before.storageBlocked' in server
    and 'status.storageBlocked' in pages
    and Path("scripts/test_reward_capacity.luau").exists(),
 "creature collection client-only view": all(token in pages for token in (
    'local CreatureView=require(',
    'CreatureView.list(p.Pets,creatureSort,creatureRole)',
    'CreatureView.nextSort(creatureSort)',
    'CreatureView.nextRole(creatureRole)',
    'send("__refreshPage",{})',
 )) and 'elseif action=="__refreshPage" then' in ui
    and Path("scripts/test_creature_view.luau").exists(),
 "trade offer freezes pet identity and progression": all(token in trade for token in (
    's.offers[id]={kind="Pet",id=pet.id,pet=R.copy(pet)}',
    'emit(otherPlayer,"Trade not completed; review offers and accept again")',
 )) and all(token in Path("src/shared/TradeRules.lua").read_text() for token in (
    'if offer.pet~=nil then',
    'snapshot.rarity~=pet.rarity',
    'snapshot.level~=pet.level',
    'snapshot.xp~=pet.xp',
    'snapshot.evolved~=pet.evolved',
 )) and all(token in pages for token in (
    'tostring(x.pet.rarity)',
    'tostring(x.pet.species)',
    'tostring(x.pet.level)',
    'tostring(x.pet.evolved)',
 )) and 'mutated offered creature cannot settle' in Path("scripts/test_trade_rules.luau").read_text(),
 "explicit hunt report and preflighted storage": all(token in Path("src/shared/Adventure.lua").read_text() for token in (
    'outcome="storage_full"',
    'outcome="defeat"',
    'outcome="victory"',
    'turns=0',
 )) and all(token in server for token in (
    'local won,message,combat=Adventure.hunt(p,enemyLevel)',
    'if not combat or combat.outcome=="storage_full" then wildCooldown[player]=nil end',
    'notify:FireClient(player,{combat=combat})',
 )) and 'function UI:showCombat(result)' in ui
    and 'if data.combat then ui:showCombat(data.combat) end' in client
    and Path("scripts/test_adventure_feedback.luau").exists(),
 "persistable currency and pet IDs": all(token in rules for token in (
    'R.MAX_COINS=4000000000',
    'R.MAX_PET_ID=10000000',
    'function R.canCreditCoins(p,amount)',
    'function R.creditCoins(p,amount)',
    'function R.canCreatePet(p)',
 )) and all(token in Path("src/shared/Economy.lua").read_text() for token in (
    'Coin wallet full: spend coins before selling',
    'Coin wallet full: spend coins before claiming',
    'if #p.Pets<R.capacity(p) and R.canCreatePet(p) then',
    'if not R.canCreatePet(p) then return false',
 )) and 'Rules.creditCoins(profile,coins)' in Path("src/shared/Adventure.lua").read_text()
    and server.count('if not R.canCreatePet(p) then return false')>=2
    and Path("scripts/test_progression_limits.luau").exists(),
 "favorites persist and protect valuable creatures": all(token in rules for token in (
    'favorite=pet.favorite==true',
    'function R.toggleFavorite(p,id)',
    'pet.favorite=pet.favorite~=true',
    'function R.xp(p,n)',
 )) and all(token in Path("src/shared/Economy.lua").read_text() for token in (
    'pet.favorite~=true',
    'if p.CraftLevel<20 then',
 )) and 'pet.favorite==true' in Path("src/shared/TradeRules.lua").read_text()
    and 'if pet.favorite==true then return false' in trade
    and 'ToggleFavorite' in server
    and 'CreatureView.nextSort(creatureSort)' in pages
    and 'REMOVE FAVORITE PROTECTION' in pages
    and 'View.SortModes={"Acquired","Favorites","Level","Rarity","Species"}'
        in Path("src/shared/CreatureView.lua").read_text()
    and Path("scripts/test_pet_favorites.luau").exists(),
 "bounded SellMax is authoritative and visible": all(token in Path("src/shared/Economy.lua").read_text() for token in (
    'function E.sellMax(p,id)',
    'local walletRoom=math.max(0,R.MAX_COINS-p.Coins)',
    'return sellAmount(p,id,count)',
 )) and 'elseif action=="SellMax" then return E.sellMax(p,payload.id)' in server
    and 'send("SellMax",{id=id})' in pages
    and 'maximum=math.min(count,math.floor(headroom/value))' in pages
    and Path("scripts/test_sell_max.luau").exists(),
 "ordered client snapshots and independent visual events": all(token in server for token in (
    'local snapshotSerial={}',
    'local function nextSnapshotSerial(player)',
    'sequence=nextSnapshotSerial(player)',
    'snapshotSerial[player]=nil',
 )) and all(token in client for token in (
    'local SnapshotOrder=require(script.Parent.SnapshotOrder)',
    'local function acceptServerUpdate(data)',
    'SnapshotOrder.accept(latestSnapshot,data.sequence)',
    'if data.pickup then ui:showPickup(data.pickup) end',
    'if data.combat then ui:showCombat(data.combat) end',
 )) and Path("scripts/test_snapshot_order.luau").exists(),
 "invite cancellation sends two-party state refresh": all(token in trade for token in (
    'emit(incoming.sender,player.Name.." declined your trade invitation")',
    'emit(recipient,player.Name.." withdrew the trade invitation")',
    'if not s then return true end',
 )) and all(token in Path("scripts/test_trade_invites.luau").read_text() for token in (
    'withdrawal invalidates recipient invitation',
    'decline clears sender\'s waiting screen',
    'declined invitation cannot be joined',
 )),
 "wheel locks original outcome across reconnect": all(token in rules for token in (
    'local reserved=saved.WheelPending',
    'p.WheelPending={roll=reserved.roll}',
    'p.WheelPending={roll=4,fallback=true}',
 )) and all(token in Path("src/shared/Economy.lua").read_text() for token in (
    'local function claimReservedWheel(p,reserved)',
    'if p.WheelPending then',
    'p.LastWheel=now',
    'p.WheelPending=reserved',
    'return true,"Daily reward reserved ("',
 )) and all(token in pages for token in (
    'local pending=p.WheelPending',
    '"CLAIM RESERVED REWARD"',
 )) and Path("scripts/test_wheel_reservations.luau").exists(),
 "leaderboard writes serialize same-user updates": all(token in Path("src/server/Leaderboards.lua").read_text() for token in (
    'local writers={}',
    'local BOARD_IDS={"Coins","Wins","Minutes"}',
    'state.latest=snapshot',
    'while state.latest do',
    'writers[key]=nil',
 )) and all(token in Path("scripts/test_leaderboard_writes.luau").read_text() for token in (
    'latest Coins survive old write finishing late',
    'only latest buffered snapshot is flushed',
    'separate player',
 )) ,
 "gameplay dock": 'framed(gui,"ActionDock"' in ui,
 "atomic persisted session claim":'liveStore:UpdateAsync(key,function(old)' in data
    and 'SessionPolicy.claim(old,token,os.time())' in data
    and 'function Policy.claim(stored,token,now)' in sessions,
 "stale session save rejection":'SessionPolicy.save(old,snapshot,token,os.time(),release==true)' in data
    and 'Session ownership lost' in sessions
    and 'player:Kick("This server lost ownership' in data,
 "final save releases ownership":'Data.save(player,true)' in data
    and 'unloading[player]=true' in data
    and 'nextValue._session=nil' in sessions
    and 'stored._lastSession==token' in sessions,
 "unsafe persisted trades fail closed":'C.DurableTrades=false' in config
    and 'function Data.supportsTrading()' in data
    and 'studio or Config.DurableTrades==true' in data
    and 'if not Data.supportsTrading() then' in server
    and 'Trade.action(player,action,payload' in server
    and 'TradeRules.exchange' in trade,
 "trade receipt recovery remains gated":all(token in trade_receipts for token in (
    'Policy.PREPARING="PREPARING"','Policy.COMMITTED="COMMITTED"',
    'Policy.ABORTED="ABORTED"','Policy.COMPLETE="COMPLETE"',
    'function Policy.prepare(','function Policy.commit(','function Policy.abort(',
    'function Policy.resolve(','function Policy.complete('
 )) and 'C.DurableTrades=false' in config,
 "trade persistence adapter remains release-gated":all(token in trade_persistence for token in (
    'function Persistence.execute(','function Persistence.recoverProfile(',
    'function Persistence.recoverForLoad(','SessionPolicy.owns(',
    'ReceiptPolicy.sameTransaction(','Persistence.RETRIES=3'
 )) and 'TradePersistence.recoverForLoad(' in data
    and 'Autosave deferred for pending trade' in data
    and 'SessionPolicy.releaseRaw(' in data
    and 'C.DurableTrades=false' in config,
 "terminal trade retention is bounded and observable":all(token in trade_retention for token in (
    'Retention.SECONDS=30*24*60*60','function Retention.attach(',
    'function Retention.compact(','function Retention.validArchive(',
    'function Retention.matchesArchive('
 )) and all(token in trade_persistence for token in (
    'ReceiptRetention.attach(','ReceiptRetention.compact(',
    'diagnostic(store,"retention_scheduled"','diagnostic(store,"receipt_archived"'
 )) and 'TRADE_DIAGNOSTIC_LIMIT=64' in data
    and 'function Data.getTradeDiagnostics()' in data
    and 'C.DurableTrades=false' in config,
 "trade lifecycle audit is bounded and restart-safe":all(token in trade_receipts for token in (
    'Policy.AUDIT_VERSION=1','_audit={version=Policy.AUDIT_VERSION,createdAt=createdAt}',
    'nextValue._audit.committedAt','nextValue._audit.abortedAt',
    'nextValue._audit.completedAt',
 )) and all(token in trade_audit_test for token in (
    'commit retry preserves first time','archive carries no offer payload',
    'legacy receipt remains recoverable',
 )) and 'C.DurableTrades=false' in config,
 "concrete trade store wrapper classifies safe diagnostics":all(token in trade_store for token in (
    'function Adapter.classify(','function Adapter.new(',
    'datastore_update_failed','datastore_update_rejected',
    'return "THROTTLED"','return "BUDGET"','return "TRANSIENT"',
    'return "CONFIG"','return "UNKNOWN"'
 )) and 'TradeStoreAdapter.new(liveStore' in data
    and 'local TradeStoreAdapter=require(script.Parent.TradeStoreAdapter)' in data
    and 'tradeDiagnosticSequence+=1' in data
    and 'TRADE_DIAGNOSTIC_LIMIT=64' in data
    and 'C.DurableTrades=false' in config,
 "durable settlement synchronizes exact committed snapshots":all(token in data for token in (
    'function Data.canMutate(','function Data.settleTrade(',
    'settling[left]=true;settling[right]=true','TradeSettlement.execute(',
    'profiles[left]=snapshots.a;profiles[right]=snapshots.b',
    'if settlementFault[player] or settling[player] then rawRelease(player)'
 )) and all(token in trade_settlement for token in (
    'function Settlement.plan(','function Settlement.execute(',
    'TradeRules.exchange(','TradePersistence.execute(',
    'terminal.participants.a.after','terminal.participants.b.after'
 )) and 'not Data.canMutate(player)' in server
    and 'C.DurableTrades=false' in config,
}
for label,ok in contracts.items():
 assert ok,f"FAILED gameplay contract: {label}"
 print("PASS:",label)
print("PASS: static first-session contracts. Real Studio acceptance remains pending.")
