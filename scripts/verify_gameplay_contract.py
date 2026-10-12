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
 "pickup feedback": "function UI:showPickup(reward)" in ui and "ui:showPickup(data.pickup)" in client,
 "failed hunt doesn't deplete node": "if not won then" in server and "return false" in server,
 "first session smoke tests": "Starter egg regression" in smoke and "full ranch blocks hatching" in smoke,
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
