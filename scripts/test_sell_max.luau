-- Verify real sale domain boundaries and no-loss bulk selling.
-- Pure Luau validation only; UI and live DataStore behavior require Studio QA.
local fs=require("@lune/fs")
local luau=require("@lune/luau")
local modules={}
local function load(name)
 if modules[name] then return modules[name] end
 local path="src/shared/"..name..".lua"
 local file=fs.readFile(path)
 local compiled=luau.load(file,{
  debugName=path,
  environment={
   script={Parent={Config="Config",Rules="Rules"}},
   require=function(dep)
    assert(type(dep)=="string","Unexpected dependency: "..tostring(dep))
    return load(dep)
   end,
  },
 })
 modules[name]=compiled()
 return modules[name]
end
local Rules=load("Rules")
local Economy=load("Economy")
local Config=load("Config")
local checks=0
local function eq(actual,expected,label)
 checks+=1
 assert(actual==expected,label..": expected "..tostring(expected)..", got "..tostring(actual))
end
local function fresh()
 local p=Rules.new(1800000000)
 p.Coins=0
 return p
end
local big=fresh()
big.Inventory.Wood=1000000
local worked,message=Economy.sellMax(big,"Wood")
eq(worked,true,"one action sells full 1m-resource inventory")
eq(message,"Sold 1000000 Wood","bulk response reports exact count")
eq(big.Inventory.Wood,0,"large bulk sale removes all sold resources")
eq(big.Coins,1000000*Config.Resources.Wood,"bulk payout is exact")
eq(Rules.load(Rules.copy(big),1800000000).Coins,big.Coins,
 "large bulk payout round-trips through persisted hydration")
eq(Economy.sellMax(big,"Wood"),false,"empty resource stack refuses bulk sale")
eq(big.Inventory.Wood,0,"empty repeat cannot sell more than owned")

local capped=fresh()
capped.Coins=Rules.MAX_COINS-10
capped.Inventory.Stone=50
local partial,partialMessage=Economy.sellMax(capped,"Stone")
eq(partial,true,"bulk sale fits exact wallet headroom")
eq(partialMessage,"Sold 2 Stone","bulk sale count matches available coin room")
eq(capped.Coins,Rules.MAX_COINS,"bulk sale never overflows coin wallet")
eq(capped.Inventory.Stone,48,"unsold goods stay owned by player")
eq(Economy.sellMax(capped,"Stone"),false,"full wallet refuses any more sales")
eq(capped.Inventory.Stone,48,"full-wallet refusal cannot lose resources")
eq(Economy.sell(capped,"Stone",1),false,"original small sale also fails safely")

local under=fresh()
under.Coins=Rules.MAX_COINS-1
under.Inventory.Stone=10
eq(Economy.sellMax(under,"Stone"),false,
 "wallet space smaller than one material value refuses sale")
eq(under.Inventory.Stone,10,"under-one-unit wallet space preserves materials")
eq(under.Coins,Rules.MAX_COINS-1,"under-one-unit refusal preserves wallet")
local unknown=fresh()
unknown.Inventory.Wood=9
eq(Economy.sellMax(unknown,"FakeResource"),false,"unlisted resources cannot be bulk sold")
eq(unknown.Coins,0,"unlisted resource cannot mint coins")

local exact=fresh()
exact.Inventory.Berries=11
eq(Economy.sellMax(exact,"Berries"),true,"small bulk sale works")
eq(exact.Inventory.Berries,0,"small bulk sale consumes exact owned amount")
eq(exact.Coins,11*Config.Resources.Berries,"small bulk sale pays exact amount")
local legacy=fresh()
legacy.Inventory.Iron=200
eq(Economy.sell(legacy,"Iron",101),false,"old Sell action retains 100-unit limit")
eq(Economy.sell(legacy,"Iron",100),true,"old Sell action still supports 100")
eq(legacy.Inventory.Iron,100,"old Sell action removes only requested count")
eq(legacy.Coins,100*Config.Resources.Iron,"old Sell pays same catalog price")

print("PASS: "..checks.." authoritative lossless SellMax assertions (Studio QA pending).")
