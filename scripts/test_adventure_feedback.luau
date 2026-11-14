-- Exercise the actual server-authoritative PvE hunt domain, without Studio.
local fs=require("@lune/fs")
local luau=require("@lune/luau")
local modules={}
local function loadShared(name)
 if modules[name] then return modules[name] end
 local path="src/shared/"..name..".lua"
 local chunk=luau.load(fs.readFile(path),{
  debugName=path,
  environment={
   script={Parent={Config="Config",Rules="Rules"}},
   require=function(dep)
    assert(type(dep)=="string","Unexpected shared dependency")
    return loadShared(dep)
   end,
  },
 })
 modules[name]=chunk()
 return modules[name]
end
local Rules=loadShared("Rules")
local Adventure=loadShared("Adventure")
local checks=0
local function equal(actual,expected,reason)
 checks+=1
 assert(actual==expected,reason..": expected "..tostring(expected)..", got "..tostring(actual))
end
local now=1800000000
local winner=Rules.new(now)
local beforeCoins=winner.Coins
local ok,message,report=Adventure.hunt(winner,1)
equal(ok,true,"starter Gorp can complete first encounter")
equal(report.outcome,"victory","victory report has stable outcome")
equal(report.victory,true,"victory uses explicit boolean")
equal(report.enemyLevel,1,"combat report records server enemy level")
equal(report.companion,"Gorp","combat report identifies companion")
equal(report.role,"Support","combat report identifies companion role")
equal(type(report.turns),"number","combat report includes battle turns")
equal(report.turns>0,true,"victory requires actual combat turns")
equal(report.remainingHP>0,true,"victory reports surviving HP")
equal(report.damage>0,true,"victory reports damage dealt")
equal(winner.Coins>beforeCoins,true,"server awards earned hunt coins")
equal(winner.Wins,0,"PvE never grants ranked PvP wins")
equal(type(message),"string","victory includes displayable server feedback")

local defeated=Rules.new(now)
local savedMeat=defeated.Inventory.Meat
local lost,description,loss=Adventure.hunt(defeated,25)
equal(lost,false,"low-level starter cannot beat level 25 creature")
equal(loss.outcome,"defeat","actual loss is not storage refusal")
equal(loss.victory,false,"defeat is not victory")
equal(loss.turns>=1,true,"defeat includes combat rounds")
equal(loss.remainingHP,0,"defeated companion has zero remaining HP")
equal(defeated.Inventory.Meat,savedMeat,"defeat awards no resources")
equal(defeated.Quests.Explorer,nil,"defeat cannot advance hunt quest")
equal(type(description),"string","defeat includes user feedback")

local full=Rules.new(now)
full.Inventory.Meat=1000000
local fullCoins=full.Coins
local fullXP=full.XP
local blocked,reason,blockedReport=Adventure.hunt(full,1)
equal(blocked,false,"full meat inventory refuses the hunt")
equal(blockedReport.outcome,"storage_full","full bag has distinct outcome")
equal(blockedReport.victory,false,"full bag awards no victory")
equal(blockedReport.turns,0,"storage refusal happens before combat starts")
equal(blockedReport.remainingHP,100,"blocked hunt does not damage the companion")
equal(full.Coins,fullCoins,"blocked hunt awards no coins")
equal(full.XP,fullXP,"blocked hunt awards no experience")
equal(full.Inventory.Meat,1000000,"blocked hunt never truncates loot")
equal(type(reason),"string","storage refusal explains the next action")
full.Inventory.Meat=999998
local recovered,_,recoveredReport=Adventure.hunt(full,1)
equal(recovered,true,"player can retry immediately after freeing storage")
equal(recoveredReport.outcome,"victory","successful retry reports victory")
equal(full.Inventory.Meat,1000000,"exact-fit hunt reward succeeds")

local invalid,badMessage,invalidReport=Adventure.hunt(Rules.new(now),0)
equal(invalid,false,"invalid enemy level remains rejected")
equal(invalidReport,nil,"invalid levels do not fabricate battle rounds")
equal(type(badMessage),"string","invalid request remains understandable")
print("PASS: "..checks.." authoritative PvE combat-report assertions (Studio QA pending).")
