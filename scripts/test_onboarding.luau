-- Execute the real onboarding state machine against real Config/Rules profiles.
-- Run from the repository root: lune run scripts/test_onboarding.luau
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local modules = {}

local function loadModule(name)
	if modules[name] then
		return modules[name]
	end
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

local Config = loadModule("Config")
local Rules = loadModule("Rules")
local Onboarding = loadModule("Onboarding")
local checks = 0

local function equal(actual, expected, message)
	checks += 1
	assert(actual == expected, message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local function resolved(profile, id, tab, current, goal)
	local objective = Onboarding.resolve(profile)
	equal(objective.id, id, id .. " objective")
	equal(objective.tab, tab, id .. " route")
	equal(objective.current, current, id .. " current")
	equal(objective.goal, goal, id .. " goal")
	return objective
end

local function questOrder(profile, expected, message)
	local actual = Onboarding.questOrder(profile)
	equal(#actual, #expected, message .. " count")
	for index, id in ipairs(expected) do
		equal(actual[index], id, message .. " position " .. index)
	end
end

local profile = Rules.new(1800000000)
questOrder(profile, { "Gatherer", "Provider", "Maker", "Employer", "Explorer" }, "fresh curriculum order")
resolved(profile, "Gatherer", "Quests", 0, Config.Quests.Gatherer.goal)
profile.Quests.Gatherer = Config.Quests.Gatherer.goal
local reward = resolved(profile, "ClaimGatherer", "Quests", 15, 15)
equal(reward.action, "CLAIM REWARD", "completed quest exposes claim action")
profile.Claimed.Gatherer = true
questOrder(profile, { "Provider", "Maker", "Employer", "Explorer", "Gatherer" }, "claimed mission moves behind unfinished work")
resolved(profile, "Hatch", "Eggs", 1, 2)
Rules.addPet(profile, "Mole")
resolved(profile, "Provider", "Creatures", 0, Config.Quests.Provider.goal)
profile.Quests.Provider = Config.Quests.Provider.goal
profile.Claimed.Provider = true
resolved(profile, "Maker", "Crafting", 0, Config.Quests.Maker.goal)
profile.Quests.Maker = Config.Quests.Maker.goal
profile.Claimed.Maker = true
resolved(profile, "Employer", "Workers", 0, Config.Quests.Employer.goal)
profile.Quests.Employer = Config.Quests.Employer.goal
profile.Claimed.Employer = true
resolved(profile, "Explorer", "Quests", 0, Config.Quests.Explorer.goal)
profile.Quests.Explorer = Config.Quests.Explorer.goal
profile.Claimed.Explorer = true
resolved(profile, "Expand", "Ranch", 1, 2)
profile.BaseLevel = 2
local complete = resolved(profile, "Explore", "Quests", 1, 1)
equal(complete.complete, true, "finished journey marks free exploration")

-- Claim-ready rewards always outrank later guidance, even on migrated profiles.
profile.Claimed.Maker = false
questOrder(profile, { "Maker", "Gatherer", "Provider", "Employer", "Explorer" }, "claim-ready reward moves first")
resolved(profile, "ClaimMaker", "Quests", 2, 2)

-- Malformed or missing client snapshots must stay bounded and never crash the HUD.
local empty = resolved({}, "Gatherer", "Quests", 0, 15)
equal(empty.progress, 0, "empty profile progress is bounded")
local malformed = Onboarding.resolve({ Quests = { Gatherer = -900 }, Claimed = "bad", Pets = "bad" })
equal(malformed.id, "Gatherer", "malformed profile remains on first objective")
equal(malformed.current, 0, "negative progress clamps to zero")
profile.Claimed.Maker = true
profile.Quests.Explorer = 999999
local bounded = Onboarding.resolve(profile)
equal(bounded.progress, 1, "finished objective progress clamps to one")

print("PASS: " .. checks .. " onboarding assertions (headless Luau; Studio/device QA remains pending).")
