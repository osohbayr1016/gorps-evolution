-- Use the actual Config/Rules/Economy/Adventure code, with Roblox module paths shimmed.
-- These assertions guard server-authoritative caps, not live Studio rendering.
local fs=require("@lune/fs")
local luau=require("@lune/luau")
local loaded={}
local function shared(name)
 if loaded[name] then return loaded[name] end
 local path="src/shared/"..name..".lua"
 local module=luau.load(fs.readFile(path),{
  debugName=path,
  environment={
   script={Parent={Config="Config",Rules="Rules"}},
   require=function(dep)
    assert(type(dep)=="string","Unexpected dependency")
    return shared(dep)
   end,
  },
 })
 loaded[name]=module()
 return loaded[name]
end
local C=shared("Config")
local R=shared("Rules")
local E=shared("Economy")
local Adventure=shared("Adventure")
local now=1800000000
local checks=0
local function equal(actual,expected,label)
 checks+=1
 assert(actual==expected,label..": expected "..tostring(expected)..", got "..tostring(actual))
end
local function player()
 local p=R.new(now)
 p.Coins=10000
 return p
end
local p=player()
p.Inventory.Berries=0
equal(R.canAdd(p,{Berries=1000000}),true,"preflight allows exact capacity from zero")
equal(R.canAdd(p,{Berries=1000001}),false,"preflight rejects excessive grant")
equal(R.canAdd(p,{UnlistedItem=1}),false,"preflight rejects unrecognized item")
equal(R.canAdd(p,{Wood=-1}),false,"preflight rejects negative grant")
equal(R.canAdd(p,{Wood=0/0}),false,"preflight rejects NaN grant")
equal(R.canAdd(p,nil),false,"preflight rejects non-table grant")

local shop=player()
shop.Inventory.Meat=999993
local beforeCoins=shop.Coins
local beforeBerries=shop.Inventory.Berries
equal(E.buy(shop,"FoodCrate"),false,"overfilling food bundle is blocked")
equal(shop.Coins,beforeCoins,"blocked bundle doesn't charge coins")
equal(shop.Inventory.Berries,beforeBerries,"blocked bundle doesn't grant partial contents")
shop.Inventory.Meat=999992
equal(E.buy(shop,"FoodCrate"),true,"exactly fitting food bundle succeeds")
equal(shop.Inventory.Meat,1000000,"shop grants exact meat without clamping")
equal(shop.Inventory.Berries,beforeBerries+C.Shop.FoodCrate.grant.Berries,
 "shop grants entire bundle on success")
equal(shop.Coins,beforeCoins-C.Shop.FoodCrate.price,"successful bundle charges once")
shop.Items.DecorationLamp=1000000
local spentCoins=shop.Coins
equal(E.buy(shop,"DecorationLamp"),false,"full decoration stack blocks purchase")
equal(shop.Coins,spentCoins,"decoration cap never consumes coins")

local crafter=player()
crafter.Items.FeedPack=999999
local craftingMeat=crafter.Inventory.Meat
local craftingBerries=crafter.Inventory.Berries
local craftingFiber=crafter.Inventory.Fiber
equal(E.craft(crafter,"FeedPack"),false,"overflowing crafted grant is blocked")
equal(crafter.Inventory.Meat,craftingMeat,"blocked recipe preserves meat")
equal(crafter.Inventory.Berries,craftingBerries,"blocked recipe preserves berries")
equal(crafter.Inventory.Fiber,craftingFiber,"blocked recipe preserves fiber")
equal(crafter.CraftXP,0,"blocked recipe gives no crafting XP")
crafter.Items.FeedPack=999998
equal(E.craft(crafter,"FeedPack"),true,"recipe succeeds at exact stack headroom")
equal(crafter.Items.FeedPack,1000000,"recipe fills stack without truncation")

local gatherer=player()
gatherer.Inventory.Wood=999998
local woodCoins=gatherer.Coins
local woodXP=gatherer.XP
equal(R.gather(gatherer,"Tree"),false,"harvest refuses overflowing wood")
equal(gatherer.Inventory.Wood,999998,"blocked harvest does not partially grant wood")
equal(gatherer.Coins,woodCoins,"blocked harvest gives no coins")
equal(gatherer.XP,woodXP,"blocked harvest gives no XP")
gatherer.Inventory.Wood=999997
equal(R.gather(gatherer,"Tree"),true,"harvest allows exact-fit resource reward")
equal(gatherer.Inventory.Wood,1000000,"harvest awards exact-fit amount")

local hunter=player()
hunter.Pets[1].level=25
hunter.Pets[1].evolved=2
hunter.Inventory.Meat=1000000
local huntCoins=hunter.Coins
equal(Adventure.hunt(hunter,1),false,"victorious hunt doesn't truncate meat loot")
equal(hunter.Coins,huntCoins,"blocked hunt doesn't award partial coins")
hunter.Inventory.Meat=999998
equal(Adventure.hunt(hunter,1),true,"hunter can claim exact-fit meat")
equal(hunter.Inventory.Meat,1000000,"hunter gets exact meat on victory")

local spin=player()
spin.Inventory.Berries=1000000
equal(E.wheel(spin,now,2),false,"full food wheel prize is blocked")
equal(spin.LastWheel,0,"blocked wheel doesn't consume daily reward")
spin.Inventory.Berries=0
spin.Inventory.Crystal=999999
equal(E.wheel(spin,now,3),false,"full crystal wheel prize is blocked")
equal(spin.LastWheel,0,"crystal overflow doesn't consume daily reward")
spin.Inventory.Crystal=999998
equal(E.wheel(spin,now,3),true,"fitting crystal reward succeeds")
equal(spin.Inventory.Crystal,1000000,"spin grants exact crystals")
equal(spin.LastWheel,now,"successful wheel is claimed once")

local crew=player()
equal(E.hire(crew,"Farmer",now),true,"hire farmer for warehouse congestion")
crew.Inventory.Berries=1000000
local crewCoins=crew.Coins
local last=crew.Workers.Farmer.cohorts[1].last
local status=E.workerStatus(crew,now+120)
equal(status.state,"blocked","full warehouse reports blocked worker")
equal(status.storageBlocked,true,"blocked worker exposes storage reason")
equal(status.byId.Farmer.storageBlocked,true,"individual crew card exposes storage reason")
equal(status.payable,0,"full warehouse promises zero collectable batches")
local batch,heldStatus=E.collect(crew,now+120)
equal(batch,0,"full warehouse cannot produce a truncated delivery")
equal(heldStatus.state,"blocked","collect uses storage-blocked authoritative status")
equal(crew.Coins,crewCoins,"full warehouse does not charge worker wages")
equal(crew.Workers.Farmer.cohorts[1].last,last,"full warehouse preserves mature work")
crew.Inventory.Berries=999996
status=E.workerStatus(crew,now+120)
equal(status.payable,1,"one free slot for four berries means one payable batch")
equal(E.collect(crew,now+120),1,"congested worker pays one fully storable batch")
equal(crew.Inventory.Berries,1000000,"first batch fills warehouse exactly")
equal(crew.Coins,crewCoins-C.Workers.Farmer.wage,"only delivered batch charged")
equal(crew.Workers.Farmer.cohorts[1].last,now+60,
 "storage congestion preserves one unpaid capacity-blocked minute")
crew.Inventory.Berries=999996
equal(E.collect(crew,now+120),1,"freeing space permits held second minute")
equal(crew.Inventory.Berries,1000000,"second batch delivered without truncation")
equal(crew.Coins,crewCoins-2*C.Workers.Farmer.wage,"second delivery charges once")
equal(crew.Workers.Farmer.cohorts[1].last,now+120,"second payment catches up exactly")
equal(E.collect(crew,now+120),0,"same timestamp cannot double deliver")
local reader=R.copy(crew)
equal(E.workerStatus(crew,now+180).state,"blocked","full warehouse blocks next minute")
equal(crew.Inventory.Berries,reader.Inventory.Berries,"status never mutates live inventory")
equal(crew.Workers.Farmer.cohorts[1].last,reader.Workers.Farmer.cohorts[1].last,
 "status never mutates accrual clocks")

local limited=player()
equal(E.hire(limited,"Farmer",now),true,"hire worker for sixty-minute cap")
limited.Inventory.Berries=1000000
equal(E.tick(limited,now+7200),0,"storage cannot produce beyond capacity")
equal(limited.Workers.Farmer.cohorts[1].last,now+3600,
 "fully blocked storage retains at most sixty minutes of work")
limited.Inventory.Berries=999996
equal(E.collect(limited,now+7200),1,"one slot pays one held bounded minute")
equal(limited.Workers.Farmer.cohorts[1].last,now+3660,
 "held backlog advances by paid minutes, not overwritten whole interval")

print("PASS: "..checks.." exact reward capacity and warehouse payroll assertions (Studio QA pending).")
