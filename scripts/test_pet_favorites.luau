-- Exercise persisted favorite protection and bounded max-level progression.
-- Uses actual shared Modules; this is not a Roblox Studio persistence test.
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
    assert(type(dep)=="string","Unexpected module dependency")
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
local TradeRules=shared("TradeRules")
local CreatureView=shared("CreatureView")
local now=1800000000
local checks=0
local function equal(actual,expected,label)
 checks+=1
 assert(actual==expected,label..": expected "..tostring(expected)..", got "..tostring(actual))
end
local function profile()
 local p=R.new(now)
 p.BaseLevel=8
 p.Coins=100000
 p.Inventory.Wood=50
 p.Inventory.Stone=50
 return p
end

-- New and legacy profiles round-trip without a schema migration or pet loss.
local p=profile()
equal(R.addPet(p,"Shade"),true,"add tradeable creature")
local id=p.Pets[2].id
local toggle,marked=R.toggleFavorite(p,id)
equal(toggle,true,"favorite toggle succeeds")
equal(marked,"Creature protected as favorite","favorite toggle gives helpful feedback")
equal(p.Pets[2].favorite,true,"pet is protected after toggle")
local saved=R.load(R.copy(p),now+200)
equal(R.pet(saved,id).favorite,true,"favorite survives profile hydration")
equal(R.pet(saved,1).favorite,false,"legacy unmarked starter defaults to false")
local legacy=R.load({Pets={{id=1,species="Gorp",rarity="Common",level=1,xp=0,evolved=0}}},now)
equal(legacy.Pets[1].favorite,false,"old pet schema gets safe default")
local visible=CreatureView.list(saved.Pets,"Favorites","All")
equal(visible[1].id,id,"favorites sort puts protected pet first")
equal(visible[2].id,1,"favorites sort retains unprotected pet")
equal(R.toggleFavorite(saved,id),true,"favorite mark can be removed")
equal(R.pet(saved,id).favorite,false,"removing favorite is persisted in memory")
equal(R.toggleFavorite(saved,100000),false,"unknown ID cannot add a favorite")
equal(R.toggleFavorite(saved,"2"),false,"non-numeric IDs are invalid")

-- Favorites are excluded from fusion even when their rarity matches.
local fusion=profile()
for _=1,3 do
 equal(R.addPet(fusion,"Gorp"),true,"seed three inactive creatures")
end
local protectedId=fusion.Pets[2].id
equal(R.toggleFavorite(fusion,protectedId),true,"protect first fusion candidate")
local firstCount=#fusion.Pets
equal(E.tradeUp(fusion,"Common","Shade"),false,
 "two nonfavorite candidates cannot satisfy a three-pet fusion")
equal(#fusion.Pets,firstCount,"rejected fusion preserves all pets")
equal(R.pet(fusion,protectedId).favorite,true,"rejected fusion preserves favorite mark")
equal(R.toggleFavorite(fusion,protectedId),true,"unprotect fusion candidate")
equal(E.tradeUp(fusion,"Common","Shade"),true,"three unprotected inactive pets can fuse")
equal(#fusion.Pets,2,"successful fusion consumes exactly three candidates")
equal(fusion.Pets[2].species,"Shade","fusion grants target creature")

-- Reject an otherwise valid pet trade if the sender marked it as a favorite.
local left,right=profile(),profile()
equal(R.addPet(left,"Shade"),true,"sender owns tradable pet")
local tradedId=left.Pets[2].id
equal(R.toggleFavorite(left,tradedId),true,"sender protects trade pet")
local offer={kind="Pet",id=tradedId,pet=R.copy(left.Pets[2])}
local payment={kind="Material",id="Stone",amount=1}
local originalStone=right.Inventory.Stone
local changed,why=TradeRules.exchange(left,right,offer,payment)
equal(changed,false,"protected pet cannot be traded")
equal(why,"Favorite creatures are protected from trading",
 "refusal explains protection")
equal(right.Inventory.Stone,originalStone,"rejected favorite trade preserves payment")
equal(#left.Pets,2,"rejected favorite trade preserves sender pet")
equal(#right.Pets,1,"rejected favorite trade preserves recipient pets")
equal(R.toggleFavorite(left,tradedId),true,"player can explicitly remove protection")
offer.pet=R.copy(left.Pets[2])
equal(TradeRules.exchange(left,right,offer,payment),true,
 "unprotected pet with refreshed consent can be exchanged")
equal(right.Pets[2].species,"Shade","recipient receives exact traded pet")

-- Max-level training and crafting do not accumulate unpersistable XP.
local maxed=profile()
maxed.Pets[1].level=25
maxed.Pets[1].xp=0
for _=1,5 do
 equal(R.feed(maxed,1),true,"feeding max-level pet remains a quest action")
end
equal(maxed.Pets[1].xp,0,"max-level creature XP stays at zero")
maxed.Level=100
maxed.XP=100000
R.xp(maxed,500)
equal(maxed.XP,0,"max player-level XP stops accumulating")
maxed.CraftLevel=20
maxed.CraftXP=0
equal(E.craft(maxed,"FeedPack"),true,"max-level crafter can still craft")
equal(maxed.CraftXP,0,"max crafting-level XP stops accumulating")
equal(R.load(R.copy(maxed),now).XP,0,"max-level XP survives hydration")
equal(R.load(R.copy(maxed),now).CraftXP,0,"craft XP survives hydration")
print("PASS: "..checks.." favorite protection and capped XP assertions (Studio QA pending).")
