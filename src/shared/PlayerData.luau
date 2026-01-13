--!strict
--[[
	PlayerData.luau
	Player data schema and default template
]]

local Types = require(script.Parent.Types)

export type PlayerData = Types.PlayerData
export type PlayerUpgrades = Types.PlayerUpgrades
export type TutorialStep = Types.TutorialStep

local PlayerData = {}

PlayerData.DEFAULT_DATA = {
	-- Currency
	currency = 0,

	-- Bag (level determines pickup eligibility and inventory capacity)
	bagLevel = 1,
	inventory = {},

	-- Plot
	plotSlots = 1,
	placedBrainrots = {},
	accumulatedIncome = 0,
	lastIncomeCollect = 0,

	-- Upgrades
	upgrades = {
		autocollect = 0,
		offlineHours = 4,
		offlineMultiplier = 1,
		globalIncomeMultiplier = 1,
	},

	-- Tutorial
	tutorialStep = "NotStarted",

	-- Metadata
	lastOnline = 0,
	totalPlayTime = 0,
}

--[[
	Creates a deep copy of the default player data template.
	Use this when initializing a new player's data.
]]
function PlayerData.getDefaultData(): PlayerData
	-- Deep copy to avoid shared references
	local data: PlayerData = {
		currency = PlayerData.DEFAULT_DATA.currency,
		bagLevel = PlayerData.DEFAULT_DATA.bagLevel,
		inventory = {},
		plotSlots = PlayerData.DEFAULT_DATA.plotSlots,
		placedBrainrots = {},
		accumulatedIncome = PlayerData.DEFAULT_DATA.accumulatedIncome,
		lastIncomeCollect = PlayerData.DEFAULT_DATA.lastIncomeCollect,
		upgrades = {
			autocollect = PlayerData.DEFAULT_DATA.upgrades.autocollect,
			offlineHours = PlayerData.DEFAULT_DATA.upgrades.offlineHours,
			offlineMultiplier = PlayerData.DEFAULT_DATA.upgrades.offlineMultiplier,
			globalIncomeMultiplier = PlayerData.DEFAULT_DATA.upgrades.globalIncomeMultiplier,
		},
		tutorialStep = PlayerData.DEFAULT_DATA.tutorialStep,
		lastOnline = PlayerData.DEFAULT_DATA.lastOnline,
		totalPlayTime = PlayerData.DEFAULT_DATA.totalPlayTime,
	}
	return data
end

return PlayerData
