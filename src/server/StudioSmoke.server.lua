-- Runs automatically in Studio Play, but is never executed in the published game.
local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local R=require(ReplicatedStorage.Shared.Rules)
local Adventure=require(ReplicatedStorage.Shared.Adventure)
local Data=require(script.Parent.Data)
local TradeRules=require(ReplicatedStorage.Shared.TradeRules)
local E=require(ReplicatedStorage.Shared.Economy)
local C=require(ReplicatedStorage.Shared.Config)
local checks=0
-- The place must be safe before Main.server.lua loads player profiles or generates the planet.
local baseplate=workspace:FindFirstChild("Baseplate")
local safeSpawn=workspace:FindFirstChild("SafetySpawn")
assert(baseplate and baseplate:IsA("BasePart") and baseplate.Anchored and baseplate.CanCollide, "[Gorps Smoke] Missing static baseplate")
assert(safeSpawn and safeSpawn:IsA("SpawnLocation") and safeSpawn.Anchored and safeSpawn.CanCollide
 and safeSpawn.Enabled and safeSpawn.Neutral, "[Gorps Smoke] Missing neutral safety spawn")
local function check(value,message)
 checks+=1
 assert(value,"[Gorps Smoke] "..message)
end
local function fresh() return R.new(1800000000) end
local planet=workspace:WaitForChild("PlanetVerdant",10)
local terrain=planet and planet:FindFirstChild("TerrainAndPaths")
local ground=terrain and terrain:FindFirstChild("Ground")
check(ground and ground:IsA("BasePart") and ground.Anchored and ground.CanCollide,
 "runtime planet ground must exist and be collidable")
check(planet and planet:FindFirstChild("ResourceNodes") and #planet.ResourceNodes:GetChildren()==70,
 "authored world contains all 70 resource nodes")
check(planet and planet:FindFirstChild("RanchPlots") and #planet.RanchPlots:GetChildren()==12,
 "authored world contains all 12 ranch plots")
check(baseplate.Size.X>=650 and baseplate.Size.Z>=650,
 "fallback baseplate covers every ranch")
check(safeSpawn.Position.Y>baseplate.Position.Y+baseplate.Size.Y/2,
 "safe spawn must sit above fallback ground")
check(Data.isStudioTest(),"Studio must use isolated, unsaved local profiles")
local p=fresh()
check(p.Coins==250,"starter coin balance")
check(#p.Pets==1 and p.Pets[1].species=="Gorp","starter creature")
check(R.capacity(p)==3,"initial pet capacity")
check(not R.spend(p,{Crystal=1}),"reject missing inventory")
check(not R.has(p,{Wood=-5}),"reject negative material costs")
check(R.spend(p,{Wood=2}) and p.Inventory.Wood==10,"atomic resource spend")
check(R.gather(p,"Tree") and p.Inventory.Wood==13,"tree harvesting")
check(p.Quests.Gatherer==3,"quest gathering progress")
check(R.feed(p,1) and p.Pets[1].xp==35,"feeding changes creature XP")
check(p.Quests.Provider==1,"feeding updates mission")
check(not R.evolve(p,1),"evolution level requirement")
check(not R.addPet(p,"NotAThing"),"reject undefined creatures")
check(R.addPet(p,"Mole"),"add valid creature")
check(R.addPet(p,"Carrier"),"fill capacity")
check(not R.addPet(p,"Dart"),"enforce pet capacity")
local before=p.Coins
check(E.buy(p,"FoodCrate") and p.Coins==before-80,"shop coin debit")
check(not E.buy(p,"Unknown"),"reject unknown shop listing")
check(not E.sell(p,"Wood",-5),"reject negative material sale")
check(E.sell(p,"Wood",1),"sell earned material")
check(E.craft(p,"FeedPack"),"craft valid recipe")
check(p.Items.FeedPack==2,"craft output")
check(E.hire(p,"Farmer",1800000000),"hire worker")
local money=p.Coins
check(E.tick(p,1800000060)==1,"worker produces after one minute")
check(p.Coins==money-C.Workers.Farmer.wage,"worker wages debited")
check(E.tick(p,1800000060)==0,"no duplicate worker collection")
check(not E.claim(p,"Maker"),"mission cannot be claimed early")
R.quest(p,"Maker",1)
check(E.claim(p,"Maker"),"mission claim succeeds after completion")
check(not E.claim(p,"Maker"),"mission can be claimed once")
check(E.wheel(p,1800000000,3),"first daily spin")
check(not E.wheel(p,1800000001,3),"daily wheel cooldown")
local saved=R.copy(p)
local loaded=R.load(saved,1800000200)
check(loaded.LastWheel==p.LastWheel,"persist wheel timestamp")
check(loaded.Pets[1].species=="Gorp","persist pet data")
check(loaded.NextId>3,"persist unique pet id sequence")
check(not E.sell(loaded,"Meat",2000),"reject oversized sell")
check(not E.craft(loaded,"Imaginary"),"reject crafted item forgery")
local hunting=fresh()
local fought,result,details=Adventure.hunt(hunting,1)
check(fought,"starter Gorp defeats entry-level wild creature")
check(details and details.victory,"battle result includes victory details")
check((hunting.Inventory.Meat or 0)>5,"successful hunt rewards meat")
check((hunting.Quests.Explorer or 0)==1,"successful hunt progresses quest")
check(not Adventure.hunt(hunting,0),"invalid enemy level rejected")
-- Full ranches must exchange creatures without destroying either offered pet.
local left=fresh()
local right=fresh()
check(R.addPet(left,"Shade"),"left ranch receives trade candidate")
check(R.addPet(left,"Mole"),"left ranch reaches full capacity")
check(R.addPet(right,"Boulder"),"right ranch receives trade candidate")
check(R.addPet(right,"Dart"),"right ranch reaches full capacity")
left.Pets[2].level=7;left.Pets[2].xp=23;left.Pets[2].evolved=1
right.Pets[3].level=9;right.Pets[3].xp=44
local swapped,swapMessage=TradeRules.exchange(left,right,{kind="Pet",id=2},{kind="Pet",id=3})
check(swapped,"full ranch pet-for-pet swap succeeds: "..tostring(swapMessage))
check(#left.Pets==3 and #right.Pets==3,"full ranches retain all three pets")
check(left.Pets[3].species=="Dart" and left.Pets[3].level==9 and left.Pets[3].xp==44,
 "received right pet preserves species, level and experience")
check(right.Pets[3].species=="Shade" and right.Pets[3].level==7 and right.Pets[3].evolved==1,
 "received left pet preserves evolution and level")
check(left.Pets[3].id==4 and right.Pets[3].id==4,
 "traded pets receive unique IDs in recipient ranches")
check(left.NextId==5 and right.NextId==5,"trade increments recipient pet ID counters")
local copyLeft=R.copy(left)
local copyRight=R.copy(right)
check(not TradeRules.exchange(left,right,{kind="Pet",id=1},{kind="Material",id="Wood",amount=1}),
 "active pet cannot be traded")
check(left.NextId==copyLeft.NextId and #left.Pets==#copyLeft.Pets and #right.Pets==#copyRight.Pets,
 "rejected active pet trade preserves pet inventories")
check(not TradeRules.exchange(left,right,{kind="Material",id="Iron",amount=1},
 {kind="Material",id="Stone",amount=1}),"insufficient resources block trade")
check(left.Inventory.Wood==copyLeft.Inventory.Wood and right.Inventory.Stone==copyRight.Inventory.Stone,
 "rejected material trade preserves balances")
local materialLeft=fresh()
local materialRight=fresh()
local transfer=TradeRules.exchange(materialLeft,materialRight,
 {kind="Material",id="Wood",amount=4},{kind="Material",id="Stone",amount=3})
check(transfer,"two-way material trade succeeds")
check(materialLeft.Inventory.Wood==8 and materialLeft.Inventory.Stone==11,
 "left receives stone and spends wood exactly once")
check(materialRight.Inventory.Wood==16 and materialRight.Inventory.Stone==5,
 "right receives wood and spends stone exactly once")
local overflowLeft=fresh()
local overflowRight=fresh()
overflowRight.Inventory.Wood=999999
check(not TradeRules.exchange(overflowLeft,overflowRight,{kind="Material",id="Wood",amount=4},
 {kind="Material",id="Stone",amount=2}),"material overflow is rejected")
check(overflowLeft.Inventory.Wood==12 and overflowRight.Inventory.Wood==999999,
 "overflow rejection keeps both inventories unchanged")
-- Starter egg regression: fair deterministic odds with server-selected roll.
local starterEgg=R.new(1800000000)
local initialCoins=starterEgg.Coins
local hatchOk,hatchMessage,newPet=R.hatchEgg(starterEgg,"Meadow",1)
check(hatchOk and newPet and newPet.species=="Gorp","Meadow egg first tier hatch succeeds")
check(starterEgg.Coins==initialCoins-C.Eggs.Meadow.price,"hatching charges coins exactly once")
check(#starterEgg.Pets==2 and newPet.id==2,"hatching adds a unique creature")
check(not R.hatchEgg(starterEgg,"Meadow",999),"invalid server hatch roll is rejected")
check(not R.hatchEgg(starterEgg,"Imaginary",1),"unknown egg is rejected")
local poor=R.new(1800000000)
poor.Coins=0
check(not R.hatchEgg(poor,"Meadow",1),"insufficient money blocks hatching")
check(poor.Coins==0 and #poor.Pets==1,"failed hatch leaves assets unchanged")
local full=R.new(1800000000)
R.addPet(full,"Mole")
R.addPet(full,"Carrier")
check(not R.hatchEgg(full,"Meadow",1),"full ranch blocks hatching before charging")
check(full.Coins==250 and #full.Pets==3,"full ranch preserves coins")
local wildEgg=R.new(1800000000)
wildEgg.Coins=500
local wildOk,_,rarePet=R.hatchEgg(wildEgg,"Wild",100)
check(wildOk and rarePet and rarePet.species=="Bloom","rare last-ticket roll awarded correctly")
print("[Gorps Smoke] "..checks.." domain assertions passed (Studio only).")
