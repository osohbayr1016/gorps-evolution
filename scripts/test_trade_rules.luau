-- Execute the real trade rules and current release flag in headless Luau.
-- Durable cross-DataStore recovery still requires private-published fault injection.
local fs=require("@lune/fs")
local luau=require("@lune/luau")
local modules={}
local function loadModule(name)
 if modules[name] then return modules[name] end
 local path="src/shared/"..name..".lua"
 local chunk=luau.load(fs.readFile(path),{
  debugName=path,
  environment={
   script={Parent={Config="Config",Rules="Rules"}},
   require=function(dependency)
    assert(dependency=="Config" or dependency=="Rules","Unexpected module dependency")
    return loadModule(dependency)
   end,
  },
 })
 modules[name]=chunk()
 return modules[name]
end
local Config=loadModule("Config")
local Rules=loadModule("Rules")
local TradeRules=loadModule("TradeRules")
local checks=0
local function equal(actual,expected,message)
 checks+=1
 assert(actual==expected,message..": expected "..tostring(expected)..", got "..tostring(actual))
end
local function profile()
 local p=Rules.new(1800000000)
 p.BaseLevel=8
 p.Inventory.Wood=100
 p.Inventory.Stone=100
 return p
end

-- Public persistence is intentionally fail-closed until a durable journal ships.
equal(Config.DurableTrades,false,"published durable-trade release flag")

local left,right=profile(),profile()
local ok,message=TradeRules.exchange(left,right,
 {kind="Material",id="Wood",amount=12},{kind="Material",id="Stone",amount=7})
equal(ok,true,"two-way material exchange")
equal(message,"Trade completed","material completion message")
equal(left.Inventory.Wood,88,"left pays wood exactly once")
equal(left.Inventory.Stone,107,"left receives stone exactly once")
equal(right.Inventory.Wood,112,"right receives wood exactly once")
equal(right.Inventory.Stone,93,"right pays stone exactly once")

local activeLeft,activeRight=profile(),profile()
Rules.addPet(activeLeft,"Shade")
Rules.addPet(activeRight,"Boulder")
local beforeLeft=#activeLeft.Pets
ok=TradeRules.exchange(activeLeft,activeRight,
 {kind="Pet",id=activeLeft.ActiveId},{kind="Pet",id=activeRight.Pets[2].id})
equal(ok,false,"active creature is never tradable")
equal(#activeLeft.Pets,beforeLeft,"rejected active trade preserves sender")
equal(#activeRight.Pets,2,"rejected active trade preserves recipient")

local petLeft,petRight=profile(),profile()
Rules.addPet(petLeft,"Shade")
Rules.addPet(petRight,"Boulder")
local sentLeft=petLeft.Pets[2].id
local sentRight=petRight.Pets[2].id
ok=TradeRules.exchange(petLeft,petRight,
 {kind="Pet",id=sentLeft},{kind="Pet",id=sentRight})
equal(ok,true,"full-capacity pet swap succeeds")
equal(#petLeft.Pets,2,"left pet count remains stable")
equal(#petRight.Pets,2,"right pet count remains stable")
equal(petLeft.Pets[2].species,"Boulder","left receives right species")
equal(petRight.Pets[2].species,"Shade","right receives left species")
equal(petLeft.Pets[2].id,3,"received left pet gets local unique ID")
equal(petRight.Pets[2].id,3,"received right pet gets local unique ID")
equal(petLeft.NextId,4,"left next ID advances")
equal(petRight.NextId,4,"right next ID advances")

local poor,rich=profile(),profile()
poor.Inventory.Iron=0
ok=TradeRules.exchange(poor,rich,
 {kind="Material",id="Iron",amount=1},{kind="Material",id="Wood",amount=1})
equal(ok,false,"missing material blocks exchange")
equal(poor.Inventory.Wood,100,"failed exchange does not grant incoming asset")
equal(rich.Inventory.Wood,100,"failed exchange does not deduct partner asset")

local overflowA,overflowB=profile(),profile()
overflowB.Inventory.Wood=1000000
ok=TradeRules.exchange(overflowA,overflowB,
 {kind="Material",id="Wood",amount=1},{kind="Material",id="Stone",amount=1})
equal(ok,false,"inventory overflow blocks exchange")
equal(overflowA.Inventory.Wood,100,"overflow rejection preserves sender")
equal(overflowB.Inventory.Wood,1000000,"overflow rejection preserves receiver")
equal(TradeRules.exchange(left,left,{kind="Material",id="Wood",amount=1},
 {kind="Material",id="Stone",amount=1}),false,"self trade is rejected")

print("PASS: "..checks.." safe-context trade assertions (persistent trading remains closed).")
