-- Exercise authoritative batch quest claims using the real Economy and Rules modules.
-- No Roblox network or published DataStore is involved.
local fs=require("@lune/fs")
local luau=require("@lune/luau")
local modules={}
local function shared(name)
 if modules[name] then return modules[name] end
 local path="src/shared/"..name..".lua"
 local loader=luau.load(fs.readFile(path),{
  debugName=path,
  environment={
   script={Parent={Config="Config",Rules="Rules"}},
   require=function(dep)
    assert(type(dep)=="string","Unexpected module dependency")
    return shared(dep)
   end,
  },
 })
 modules[name]=loader()
 return modules[name]
end
local Config=shared("Config")
local Rules=shared("Rules")
local Economy=shared("Economy")
local checks=0
local function eq(actual,expected,label)
 checks+=1
 assert(actual==expected,label..": expected "..tostring(expected)..", got "..tostring(actual))
end
local function profile()
 return Rules.new(1800000000)
end
local function finishAll(p)
 local count,total=0,0
 for id,q in pairs(Config.Quests) do
  p.Quests[id]=q.goal
  count+=1
  total+=q.reward
 end
 return count,total
end

local base=profile()
local count,total=finishAll(base)
eq(count,5,"catalog includes five predefined missions")
eq(total,550,"all mission rewards total 550 coins")
local initial=base.Coins
local completed,message=Economy.claimAll(base)
eq(completed,true,"all ready missions claim in one transaction")
eq(message,"Claimed 5 missions for 550 coins","summary reports exact claim count and payout")
eq(base.Coins,initial+550,"all coins credited exactly once")
for id in pairs(Config.Quests) do
 eq(base.Claimed[id],true,"claimed mission marked once: "..id)
end
eq(Economy.claimAll(base),false,"claim all is idempotent")
eq(base.Coins,initial+550,"duplicate request cannot mint more coins")
eq(Economy.claim(base,"Gatherer"),false,"single-claim endpoint honors bulk ownership")
local restored=Rules.load(Rules.copy(base),1800000100)
eq(restored.Coins,initial+550,"claimed total round-trips through hydration")
for id in pairs(Config.Quests) do
 eq(restored.Claimed[id],true,"claim markers survive rejoin: "..id)
end

local full=profile()
finishAll(full)
full.Coins=Rules.MAX_COINS-549
local rejected,rejection=Economy.claimAll(full)
eq(rejected,false,"one-coin shortfall refuses entire batch")
eq(rejection,"Coin wallet full: spend coins before claiming all rewards",
 "wallet error explains refused batch")
eq(full.Coins,Rules.MAX_COINS-549,"wallet remains unchanged after refused batch")
for id in pairs(Config.Quests) do
 eq(full.Claimed[id],nil,"no claim marker consumed on failed batch: "..id)
end
full.Coins=Rules.MAX_COINS-total
eq(Economy.claimAll(full),true,"exact wallet headroom allows all claims")
eq(full.Coins,Rules.MAX_COINS,"exact-fit batch fills wallet without overflow")

local mixed=profile()
finishAll(mixed)
mixed.Claimed.Gatherer=true
mixed.Quests.Explorer=0
local expected=Config.Quests.Provider.reward+
 Config.Quests.Maker.reward+Config.Quests.Employer.reward
local beforeMixed=mixed.Coins
eq(Economy.claimAll(mixed),true,"batch skips claimed and unfinished missions")
eq(mixed.Coins,beforeMixed+expected,"only eligible mission rewards are credited")
eq(mixed.Claimed.Gatherer,true,"existing claim remains claimed")
eq(mixed.Claimed.Explorer,nil,"unfinished mission is untouched")
for _,id in ipairs({"Provider","Maker","Employer"}) do
 eq(mixed.Claimed[id],true,"unclaimed completed mission is claimed: "..id)
end
eq(Economy.claimAll(mixed),false,"no remaining eligible missions cannot mint coins")

local one=profile()
one.Quests.Explorer=Config.Quests.Explorer.goal
local oneCoins=one.Coins
eq(Economy.claimAll(one),true,"single eligible mission can use same batch path")
eq(one.Coins,oneCoins+Config.Quests.Explorer.reward,"single mission receives one payout")
eq(one.Claimed.Explorer,true,"single ready mission marked claimed")

local partialWallet=profile()
finishAll(partialWallet)
partialWallet.Coins=Rules.MAX_COINS-70
eq(Economy.claimAll(partialWallet),false,"batch disallows partial wallet overflow")
eq(Economy.claim(partialWallet,"Gatherer"),true,
 "individual claim remains possible after declined batch")
eq(partialWallet.Coins,Rules.MAX_COINS,"small individual claim can use exact remaining headroom")
eq(partialWallet.Claimed.Provider,nil,"batch failure never consumes other missions")

local empty=profile()
eq(Economy.claimAll(empty),false,"not-yet-completed missions cannot be claimed")
eq(empty.Coins,250,"empty batch leaves starter wallet intact")
print("PASS: "..checks.." atomic all-mission claim assertions (Studio UI QA pending).")
