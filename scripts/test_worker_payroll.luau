-- Execute the real shared modules in Luau; only Roblox's require path is shimmed.
-- Run from the repository root: lune run scripts/test_worker_payroll.luau
-- This is a domain regression suite, not Roblox Studio/runtime verification.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local modules = {}
local function loadModule(name)
	if modules[name] then return modules[name] end
	local path = "src/shared/" .. name .. ".lua"
	local chunk = luau.load(fs.readFile(path), {
		debugName = path,
		environment = {
			script = { Parent = { Config = "Config", Rules = "Rules" } },
			require = function(dependency)
				assert(dependency == "Config" or dependency == "Rules", "Unexpected module dependency")
				return loadModule(dependency)
			end,
		},
	})
	modules[name] = chunk()
	return modules[name]
end
local C = loadModule("Config")
local R = loadModule("Rules")
local E = loadModule("Economy")
local start = 1800000000
local checks = 0
local function equal(actual, expected, message)
	checks += 1
	assert(actual == expected, message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function hire(id, count)
	local p = R.new(start)
	p.Coins = 10000
	for _ = 1, count or 1 do
		equal(E.hire(p, id, start), true, "hire " .. id)
	end
	return p
end

-- Off-minute claims used to erase paid work and lose the second delivery.
local p = hire("Farmer")
local coins, berries, meat = p.Coins, p.Inventory.Berries, p.Inventory.Meat
equal(E.tick(p, start + 59), 0, "no premature delivery")
equal(p.Coins, coins, "early claim charges no wage")
equal(p.Inventory.Berries, berries, "early claim grants no berries")
equal(E.tick(p, start + 119), 1, "first off-minute delivery")
equal(p.Coins, coins - 8, "first delivery charges one wage")
equal(p.Inventory.Berries, berries + 4, "first delivery grants berries once")
equal(E.tick(p, start + 119), 0, "repeated timestamp grants no duplicate")
equal(E.tick(p, start + 179), 1, "second off-minute delivery preserves worked seconds")
equal(p.Coins, coins - 16, "exactly two wages charged")
equal(p.Inventory.Berries, berries + 8, "exactly two berry deliveries")
equal(p.Inventory.Meat, meat + 2, "exactly two meat deliveries")
equal(E.tick(p, start + 180), 1, "next exact boundary pays the retained minute")
equal(p.Coins, coins - 24, "three funded minutes charge three wages")
equal(p.Inventory.Berries, berries + 12, "three funded minutes grant three deliveries")
equal(E.tick(p, start + 180), 0, "exact boundary cannot double collect")

-- Frequent uneven claims must match a single claim over the same funded work.
local frequent, once = hire("Farmer"), hire("Farmer")
local completed = 0
for offset = 47, 1200, 47 do completed += E.tick(frequent, start + offset) end
completed += E.tick(frequent, start + 1200)
equal(completed, 20, "uneven claims deliver all 20 funded minutes")
equal(E.tick(once, start + 1200), 20, "single delayed claim delivers 20 minutes")
equal(frequent.Coins, once.Coins, "claim timing does not change wages")
equal(frequent.Inventory.Berries, once.Inventory.Berries, "claim timing does not change berries")
equal(frequent.Inventory.Meat, once.Inventory.Meat, "claim timing does not change meat")

-- A fully unpaid collection expires that work; later coins cannot buy old debt.
local unpaid = hire("Farmer")
local unpaidBerries = unpaid.Inventory.Berries
unpaid.Coins = 0
equal(E.tick(unpaid, start + 119), 0, "no production without wages")
equal(unpaid.Inventory.Berries, unpaidBerries, "unpaid production grants nothing")
unpaid.Coins = 100
equal(E.tick(unpaid, start + 120), 0, "refunding does not instantly collect expired work")
equal(E.tick(unpaid, start + 178), 0, "funded production waits a full minute")
equal(E.tick(unpaid, start + 179), 1, "funded production resumes after 60 seconds")
equal(unpaid.Coins, 92, "resumed production charges one wage")

-- Partial affordability drops unpaid whole minutes but keeps the sub-minute remainder.
local partial = hire("Farmer")
local partialBerries = partial.Inventory.Berries
partial.Coins = 8
equal(E.tick(partial, start + 179), 1, "only affordable batch produced")
equal(partial.Coins, 0, "affordable wage exhausts wallet without debt")
equal(partial.Inventory.Berries, partialBerries + 4, "unpaid batch is not granted")
partial.Coins = 80
equal(E.tick(partial, start + 179), 0, "replenishing coins cannot revive unpaid whole minutes")
equal(E.tick(partial, start + 180), 1, "partial paid claim retains 59 worked seconds")
equal(partial.Coins, 72, "retained minute charges once")

-- Long absences remain capped; over-cap work cannot be collected repeatedly.
local capped = hire("Farmer")
local cappedCoins, cappedBerries = capped.Coins, capped.Inventory.Berries
equal(E.tick(capped, start + 60 * 120 + 59), 60, "offline settlement remains capped at 60 minutes")
equal(capped.Coins, cappedCoins - 60 * 8, "cap charges exactly 60 wages")
equal(capped.Inventory.Berries, cappedBerries + 60 * 4, "cap grants exactly 60 batches")
equal(E.tick(capped, start + 60 * 120 + 59), 0, "expired over-cap work cannot be replayed")
equal(E.tick(capped, start + 60 * 121), 1, "cap preserves current partial minute")

-- Worker count scales both output and wages, including off-minute collections.
local crew = hire("Farmer", 2)
local crewCoins, crewBerries = crew.Coins, crew.Inventory.Berries
equal(E.tick(crew, start + 119), 2, "two workers deliver two batches")
equal(E.tick(crew, start + 179), 2, "two workers preserve their partial minute")
equal(crew.Coins, crewCoins - 4 * 8, "crew wages scale once per worker and batch")
equal(crew.Inventory.Berries, crewBerries + 4 * 4, "crew output scales once per worker and batch")

-- Hiring a second worker must not erase the first worker's nearly complete
-- minute, and the new hire must not receive production earned before joining.
local staggered = hire("Farmer")
local staggeredCoins, staggeredBerries = staggered.Coins, staggered.Inventory.Berries
equal(E.hire(staggered, "Farmer", start + 59), true, "hire second worker after 59 seconds")
equal(E.tick(staggered, start + 60), 1, "existing worker keeps the minute completed before second hire")
equal(staggered.Coins, staggeredCoins - C.Workers.Farmer.price - C.Workers.Farmer.wage,
	"59-second additional hire charges one wage, not two")
equal(staggered.Inventory.Berries, staggeredBerries + C.Workers.Farmer.grant.Berries,
	"new worker receives no retroactive berries")
equal(E.tick(staggered, start + 119), 1, "new worker completes its first minute from join time")
equal(E.tick(staggered, start + 120), 1, "existing worker's second minute stays independent")
equal(#staggered.Workers.Farmer.cohorts, 2, "staggered hires retain two bounded join cohorts")
equal(staggered.Workers.Farmer.count, 2, "cohort migration preserves public worker count")

local restoredStaggered = R.load(R.copy(staggered), start + 120)
equal(#restoredStaggered.Workers.Farmer.cohorts, 2, "profile hydration preserves join cohorts")
equal(E.tick(restoredStaggered, start + 179), 1, "hydrated new-worker cohort retains its own remainder")
equal(E.tick(restoredStaggered, start + 180), 1, "hydrated existing-worker cohort retains its own remainder")

local legacyCrew = R.load({
	Coins = 1000,
	Workers = { Farmer = { count = 2, last = start } },
}, start + 59)
equal(#legacyCrew.Workers.Farmer.cohorts, 1, "legacy worker clock hydrates as one cohort")
equal(legacyCrew.Workers.Farmer.cohorts[1].count, 2, "legacy cohort preserves worker count")
equal(E.tick(legacyCrew, start + 60), 2, "legacy crew keeps accrued minute after migration")

local malformedCohorts = R.load({
	Workers = { Farmer = { count = 2, last = start, cohorts = { { count = 1, last = start } } } },
}, start + 59)
equal(#malformedCohorts.Workers.Farmer.cohorts, 1, "incomplete cohort schema falls back atomically")
equal(malformedCohorts.Workers.Farmer.cohorts[1].count, 2, "fallback never loses declared workers")

local boundedCohorts = hire("Miner")
for offset = 1, 4 do
	equal(E.hire(boundedCohorts, "Miner", start + offset), true, "hire staggered bounded cohort " .. offset)
end
equal(#boundedCohorts.Workers.Miner.cohorts, 5, "worker cap also bounds persisted cohort count")
equal(E.hire(boundedCohorts, "Miner", start + 5), false, "sixth cohort is rejected by worker cap")

local miner = hire("Miner")
local minerCoins, stone, iron = miner.Coins, miner.Inventory.Stone, miner.Inventory.Iron
equal(E.tick(miner, start + 119), 1, "miner first delivery")
equal(E.tick(miner, start + 179), 1, "miner second delivery")
equal(miner.Coins, minerCoins - 24, "miner wages match catalog")
equal(miner.Inventory.Stone, stone + 6, "miner stone output matches catalog")
equal(miner.Inventory.Iron, iron + 2, "miner iron output matches catalog")

local caretaker = hire("Caretaker")
local caretakerCoins, caretakerBerries = caretaker.Coins, caretaker.Inventory.Berries
equal(E.tick(caretaker, start + 119), 1, "caretaker first delivery")
equal(E.tick(caretaker, start + 179), 1, "caretaker second delivery")
equal(caretaker.Coins, caretakerCoins - 20, "caretaker wages match catalog")
equal(caretaker.Quests.Provider, 2, "each caretaker batch feeds once")
equal(caretaker.Inventory.Berries, caretakerBerries - 2, "feeding uses supplied berries")
equal(E.tick(caretaker, start + 179), 0, "caretaker cannot double-feed the same delivery")

-- Profile hydration retains progress; this is not a real DataStore round trip.
local saved = hire("Farmer")
equal(E.tick(saved, start + 119), 1, "delivery before profile serialization")
local restored = R.load(R.copy(saved), start + 130)
local restoredCoins, restoredBerries = restored.Coins, restored.Inventory.Berries
equal(E.tick(restored, start + 179), 1, "hydrated worker retains partial progress")
equal(restored.Coins, restoredCoins - C.Workers.Farmer.wage, "hydrated wage charged once")
equal(restored.Inventory.Berries, restoredBerries + 4, "hydrated output granted once")

local backwards = hire("Farmer")
local backwardsCoins = backwards.Coins
equal(E.tick(backwards, start - 10), 0, "backwards clock gives no production")
equal(backwards.Coins, backwardsCoins, "backwards clock charges no wage")
equal(E.tick(backwards, start + 60), 1, "backwards clock does not erase progress")
equal(E.tick(R.new(start), start + 600), 0, "profile without workers produces nothing")
print("PASS: " .. checks .. " worker payroll assertions (headless Luau; Studio QA remains pending).")
