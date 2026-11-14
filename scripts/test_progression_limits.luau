-- Use production shared progression/economy/hunt code with only Roblox require shimmed.
local fs=require("@lune/fs")
local luau=require("@lune/luau")
local modules={}
local function load(name)
 if modules[name] then return modules[name] end
 local path="src/shared/"..name..".lua"
 local chunk=luau.load(fs.readFile(path),{
  debugName=path,
  environment={
   script={Parent={Config="Config",Rules="Rules"}},
   require=function(dependency)
    assert(type(dependency)=="string","Unexpected dependency")
    return load(dependency)
   end,
  },
 })
 modules[name]=chunk()
 return modules[name]
end
local R=load("Rules")
local E=load("Economy")
local C=load("Config")
local Adventure=load("Adventure")
local now=1800000000
local checks=0
local function equal(actual,expected,message)
 checks+=1
 assert(actual==expected,message..": expected "..tostring(expected)..", got "..tostring(actual))
end
local function profile()
 local p=R.new(now)
 p.BaseLevel=8
 return p
end
equal(R.MAX_COINS,4000000000,"coin max matches persisted numeric bound")
equal(R.MAX_PET_ID,10000000,"pet ID max matches hydrated pet bounds")

local seller=profile()
seller.Coins=R.MAX_COINS
seller.Inventory.Wood=100
equal(E.sell(seller,"Wood",1),false,"full wallet rejects paid sale")
equal(seller.Inventory.Wood,100,"failed sale never consumes resource")
equal(seller.Coins,R.MAX_COINS,"failed sale never changes wallet")
seller.Coins=R.MAX_COINS-C.Resources.Wood
equal(E.sell(seller,"Wood",1),true,"exact wallet headroom permits sale")
equal(seller.Coins,R.MAX_COINS,"exact-fit sale fills wallet")
equal(seller.Inventory.Wood,99,"successful sale removes exactly one wood")

local quest=profile()
quest.Quests.Gatherer=C.Quests.Gatherer.goal
quest.Coins=R.MAX_COINS
equal(E.claim(quest,"Gatherer"),false,"full wallet cannot claim coin reward")
equal(quest.Claimed.Gatherer,nil,"rejected quest claim stays available")
quest.Coins=R.MAX_COINS-C.Quests.Gatherer.reward
equal(E.claim(quest,"Gatherer"),true,"claim can resume after making wallet space")
equal(quest.Coins,R.MAX_COINS,"quest claim awards exact safe amount")
equal(quest.Claimed.Gatherer,true,"successful claim marks completion once")

local spin=profile()
spin.Coins=R.MAX_COINS
equal(E.wheel(spin,now,1),false,"full wallet blocks coin wheel outcome")
equal(spin.LastWheel,0,"blocked coin spin does not consume daily entitlement")
spin.Coins=R.MAX_COINS-100
equal(E.wheel(spin,now,1),true,"exact wallet space permits coin wheel outcome")
equal(spin.Coins,R.MAX_COINS,"coin wheel respects persisted cap")
equal(spin.LastWheel,now,"successful wheel records one claim")

local level=profile()
level.Coins=R.MAX_COINS
level.XP=49
R.xp(level,1)
equal(level.Level,2,"reaching wallet cap does not block leveling")
equal(level.Coins,R.MAX_COINS,"level-up never overflows wallet")
local gather=profile()
gather.Coins=R.MAX_COINS
equal(R.gather(gather,"Tree"),true,"full wallet does not block gathering resources")
equal(gather.Coins,R.MAX_COINS,"gather coin bonus never exceeds saved limit")
local hunt=profile()
hunt.Coins=R.MAX_COINS
equal(Adventure.hunt(hunt,1),true,"full coin wallet does not block combat")
equal(hunt.Coins,R.MAX_COINS,"hunt rewards never overflow coins")
equal(R.load(R.copy(hunt),now).Coins,R.MAX_COINS,"capped hunt coins round-trip through hydration")

local exhausted=profile()
exhausted.NextId=R.MAX_PET_ID+1
local coinsBefore=exhausted.Coins
local petsBefore=#exhausted.Pets
equal(R.canCreatePet(exhausted),false,"pet creation rejects IDs beyond hydrated range")
equal(R.addPet(exhausted,"Shade"),false,"exhausted pet sequence cannot create unusable pet")
equal(#exhausted.Pets,petsBefore,"rejected pet creation preserves collection")
equal(R.hatchEgg(exhausted,"Meadow",1),false,"egg hatch refuses invalid next pet ID")
equal(exhausted.Coins,coinsBefore,"invalid pet ID never consumes egg coins")
equal(exhausted.NextId,R.MAX_PET_ID+1,"refusal never advances invalid sequence")
local wheelMessage
local wheelOK
wheelOK,wheelMessage=E.wheel(exhausted,now,4)
equal(wheelOK,true,"pet wheel fallback succeeds for exhausted pet IDs")
equal(wheelMessage,"250 coins!","exhausted pet ID wheel uses truthful coin fallback")
equal(#exhausted.Pets,petsBefore,"fallback does not create an unaddressable pet")
equal(exhausted.Coins,coinsBefore+250,"fallback pays full alternative coins")

local fullWheel=profile()
fullWheel.Coins=R.MAX_COINS
fullWheel.NextId=R.MAX_PET_ID+1
equal(E.wheel(fullWheel,now,4),false,"full wallet and exhausted pets block wheel without loss")
equal(fullWheel.LastWheel,0,"failed fallback keeps wheel available")
local lastID=profile()
lastID.NextId=R.MAX_PET_ID
equal(R.addPet(lastID,"Shade"),true,"final in-range ID can be minted")
equal(R.pet(lastID,R.MAX_PET_ID).species,"Shade","final minted creature is addressable")
equal(lastID.NextId,R.MAX_PET_ID+1,"sequence advances after final mint")
equal(R.addPet(lastID,"Bloom"),false,"no pet can be minted beyond final ID")

local tradeUp=profile()
for _=1,3 do equal(R.addPet(tradeUp,"Gorp"),true,"seed inactive common pets") end
local initialCount=#tradeUp.Pets
local initialActive=tradeUp.ActiveId
tradeUp.NextId=R.MAX_PET_ID+1
equal(E.tradeUp(tradeUp,"Common","Shade"),false,"invalid next ID blocks trade-up")
equal(#tradeUp.Pets,initialCount,"failed trade-up never burns three creatures")
equal(tradeUp.ActiveId,initialActive,"failed trade-up preserves companion")
print("PASS: "..checks.." saved-value coin and pet ID safety assertions.")
