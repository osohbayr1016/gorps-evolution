-- Real daily wheel and profile hydration, verifying no capacity reroll loophole.
local fs=require("@lune/fs")
local luau=require("@lune/luau")
local mods={}
local function load(name)
 if mods[name] then return mods[name] end
 local path="src/shared/"..name..".lua"
 local chunk=luau.load(fs.readFile(path),{
  debugName=path,
  environment={script={Parent={Rules="Rules",Config="Config"}},
   require=function(dependency)
    assert(type(dependency)=="string","Unexpected dependency")
    return load(dependency)
   end},
 })
 mods[name]=chunk()
 return mods[name]
end
local R=load("Rules")
local E=load("Economy")
local now=1800000000
local checks=0
local function eq(actual,expected,label)
 checks+=1
 assert(actual==expected,label..": expected "..tostring(expected)..", got "..tostring(actual))
end
local function player()
 local p=R.new(now)
 p.BaseLevel=8
 return p
end

local food=player()
food.Inventory.Meat=1000000
local initialBerries=food.Inventory.Berries
eq(E.wheel(food,now,2),true,"blocked food spin is persisted as valid action")
eq(food.LastWheel,now,"blocked food draw records daily timestamp")
eq(food.WheelPending.roll,2,"food outcome reserved")
eq(food.Inventory.Berries,initialBerries,"blocked food pays no partial items")
local savedFood=R.load(R.copy(food),now+10)
eq(savedFood.WheelPending.roll,2,"rejoin preserves reserved food outcome")
eq(E.wheel(savedFood,now+20,4),false,"cannot redraw or claim while food storage full")
eq(savedFood.WheelPending.roll,2,"blocked repeated claim retains original prize")
eq(savedFood.LastWheel,now,"blocked retry never shifts cooldown")
savedFood.Inventory.Meat=999994
eq(E.wheel(savedFood,now+30,4),true,"free space claims original food")
eq(savedFood.Inventory.Meat,1000000,"reserved food grants exact meat")
eq(savedFood.Inventory.Berries,initialBerries+8,"reserved food grants exact berries")
eq(savedFood.WheelPending,nil,"claim is terminal")
eq(E.wheel(savedFood,now+31,4),false,"cannot claim twice same day")
eq(E.wheel(savedFood,now+86400,3),true,"new day permits separate draw")
eq(savedFood.LastWheel,now+86400,"new day updates draw timestamp")
eq(savedFood.Inventory.Crystal,2,"next-day prize grants crystals")

local coins=player()
coins.Coins=R.MAX_COINS
eq(E.wheel(coins,now,1),true,"overflowed coin reward is reserved")
eq(coins.WheelPending.roll,1,"original 100-coin outcome preserved")
eq(R.load(R.copy(coins),now+1).WheelPending.roll,1,"coin pending persists")
coins.Coins=R.MAX_COINS-99
eq(E.wheel(coins,now+1,4),false,"less than exact wallet headroom cannot claim")
eq(coins.WheelPending.roll,1,"overflowing coin claim remains reserved")
coins.Coins=R.MAX_COINS-100
eq(E.wheel(coins,now+2,4),true,"exact coin capacity can claim reward")
eq(coins.Coins,R.MAX_COINS,"coin payout matches stored cap")
eq(coins.WheelPending,nil,"no pending after coin claim")

local depleted=player()
depleted.NextId=R.MAX_PET_ID+1
depleted.Coins=R.MAX_COINS
eq(E.wheel(depleted,now,4),true,"wheel awards fixed fallback when pet ID exhausted")
eq(depleted.WheelPending.fallback,true,"fallback is not a creature")
eq(depleted.WheelPending.roll,4,"fallback preserves original wheel outcome")
local reloaded=R.load(R.copy(depleted),now+3)
eq(reloaded.WheelPending.fallback,true,"fallback status survives reload")
reloaded.NextId=2
reloaded.Coins=R.MAX_COINS-250
eq(E.wheel(reloaded,now+4,1),true,"resumed fallback cannot upgrade to random pet")
eq(reloaded.Coins,R.MAX_COINS,"fallback grants exact 250 coins")
eq(#reloaded.Pets,1,"coin fallback cannot mint a pet")
eq(reloaded.WheelPending,nil,"fallback ends after single claim")

local lucky=player()
local beforePetCount=#lucky.Pets
eq(E.wheel(lucky,now,4),true,"eligible pet wheel can be claimed immediately")
eq(#lucky.Pets,beforePetCount+1,"pet prize actually adds one creature")
eq(lucky.WheelPending,nil,"successful pet prize leaves no reservation")
eq(E.wheel(lucky,now+1,4),false,"pet cannot be claimed twice")

local malformed=player()
malformed.WheelPending={roll=3,species="Unlisted"}
-- Extra fields on resource-prize reservations are discarded when loaded.
local sanitized=R.load(R.copy(malformed),now)
eq(sanitized.WheelPending.roll,3,"resource pending roll hydrates safely")
eq(sanitized.WheelPending.species,nil,"unexpected reward fields are stripped")
malformed.WheelPending={roll=4,species="Nonexistent"}
eq(R.load(R.copy(malformed),now).WheelPending,nil,"unknown reserved species is rejected")
malformed.WheelPending={roll=4,fallback=true,species="Gorp"}
eq(R.load(R.copy(malformed),now).WheelPending,nil,"conflicting pending reward data rejected")
malformed.WheelPending={roll=-1}
eq(R.load(R.copy(malformed),now).WheelPending,nil,"invalid negative rolls rejected")
print("PASS: "..checks.." single-draw wheel reservation and hydration assertions (Studio QA pending).")
