-- Runs automatically in Studio Play, but is never executed in the published game.
local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local R=require(ReplicatedStorage.Shared.Rules)
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
print("[Gorps Smoke] "..checks.." domain assertions passed (Studio only).")
