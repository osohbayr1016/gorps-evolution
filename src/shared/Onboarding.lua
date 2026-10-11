local Config = require(script.Parent.Config)

local Onboarding = {}

local QUEST_STEPS = {
	{ id = "Gatherer", title = "Gather 15 materials", detail = "Follow the mint trail north", action = "VIEW QUEST", tab = "Quests" },
	{ id = "Provider", title = "Feed your active Gorp", detail = "Meat and berries restore its spirit", action = "OPEN PETS", tab = "Creatures" },
	{ id = "Maker", title = "Craft two ranch items", detail = "Turn gathered resources into gear", action = "OPEN CRAFTING", tab = "Crafting" },
	{ id = "Employer", title = "Hire your first worker", detail = "The Farmer Guild manages ranch crew", action = "OPEN WORKERS", tab = "Workers" },
	{ id = "Explorer", title = "Hunt five wild creatures", detail = "Wildlife waits beyond the village", action = "VIEW QUEST", tab = "Quests" },
}

local function safeTable(value)
	return type(value) == "table" and value or {}
end

local function safeCount(value)
	local count = 0
	for _ in pairs(safeTable(value)) do
		count += 1
	end
	return count
end

local function progress(value, goal)
	local number = tonumber(value) or 0
	number = math.clamp(number, 0, goal)
	return number, number / goal
end

local function questDescriptor(step, value)
	local definition = Config.Quests[step.id]
	local current, ratio = progress(value, definition.goal)
	return {
		id = step.id,
		title = step.title,
		detail = step.detail,
		action = step.action,
		tab = step.tab,
		current = current,
		goal = definition.goal,
		progress = ratio,
	}
end

function Onboarding.resolve(profile)
	profile = safeTable(profile)
	local quests = safeTable(profile.Quests)
	local claimed = safeTable(profile.Claimed)

	-- A finished objective is not progress until its server-owned reward is claimed.
	for _, step in ipairs(QUEST_STEPS) do
		local definition = Config.Quests[step.id]
		local current = math.max(0, tonumber(quests[step.id]) or 0)
		if current >= definition.goal and claimed[step.id] ~= true then
			return {
				id = "Claim" .. step.id,
				title = "Claim " .. step.id .. " reward",
				detail = "+" .. definition.reward .. " coins are ready",
				action = "CLAIM REWARD",
				tab = "Quests",
				current = definition.goal,
				goal = definition.goal,
				progress = 1,
			}
		end
	end

	local gatherer = QUEST_STEPS[1]
	if (tonumber(quests.Gatherer) or 0) < Config.Quests.Gatherer.goal then
		return questDescriptor(gatherer, quests.Gatherer)
	end

	local petCount = safeCount(profile.Pets)
	if petCount < 2 then
		local egg = Config.Eggs.Meadow
		local current, ratio = progress(petCount, 2)
		return {
			id = "Hatch",
			title = "Hatch a second Gorp",
			detail = egg.title .. " costs " .. egg.price .. " coins",
			action = "OPEN EGGS",
			tab = "Eggs",
			current = current,
			goal = 2,
			progress = ratio,
		}
	end

	for index = 2, #QUEST_STEPS do
		local step = QUEST_STEPS[index]
		if (tonumber(quests[step.id]) or 0) < Config.Quests[step.id].goal then
			return questDescriptor(step, quests[step.id])
		end
	end

	local ranchLevel = math.max(0, tonumber(profile.BaseLevel) or 0)
	if ranchLevel < 2 then
		local current, ratio = progress(ranchLevel, 2)
		return {
			id = "Expand",
			title = "Expand your ranch",
			detail = "Level 2 adds capacity and a silo",
			action = "OPEN RANCH",
			tab = "Ranch",
			current = current,
			goal = 2,
			progress = ratio,
		}
	end

	return {
		id = "Explore",
		title = "Planet Verdant awaits",
		detail = "Choose a mission or explore a biome",
		action = "VIEW MISSIONS",
		tab = "Quests",
		current = 1,
		goal = 1,
		progress = 1,
		complete = true,
	}
end

return Onboarding
