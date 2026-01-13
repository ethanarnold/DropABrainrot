--!strict
--[[
	Upgrades.luau
	Player upgrade definitions with costs and effects
]]

local Types = require(script.Parent.Parent.Types)

export type UpgradeDefinition = Types.UpgradeDefinition

local Upgrades: { [string]: UpgradeDefinition } = {
	plotSlots = {
		id = "plotSlots",
		name = "Plot Slots",
		description = "Unlock additional slots to place more brainrots on your plot",
		maxLevel = 10,
		getCost = function(_currentLevel: number): number
			return 141 -- Placeholder cost
		end,
		getEffect = function(level: number): number
			return level -- Number of slots = level
		end,
	},

	autocollect = {
		id = "autocollect",
		name = "Autocollect",
		description = "Automatically collect passive income from your plot",
		maxLevel = 1,
		getCost = function(_currentLevel: number): number
			return 141 -- One-time purchase
		end,
		getEffect = function(level: number): number
			return level -- 0 = off, 1 = on
		end,
	},

	offlineHours = {
		id = "offlineHours",
		name = "Offline Income Hours",
		description = "Increase the number of hours your brainrots generate income while offline",
		maxLevel = 24,
		getCost = function(_currentLevel: number): number
			return 141 -- Placeholder cost
		end,
		getEffect = function(level: number): number
			return 4 + level -- Base 4 hours + level
		end,
	},

	offlineMultiplier = {
		id = "offlineMultiplier",
		name = "Offline Income Multiplier",
		description = "Multiply the income earned while offline",
		maxLevel = 10,
		getCost = function(_currentLevel: number): number
			return 141 -- Placeholder cost
		end,
		getEffect = function(level: number): number
			return 1 + (level * 0.1) -- 1.0, 1.1, 1.2, ... 2.0
		end,
	},

	globalIncomeMultiplier = {
		id = "globalIncomeMultiplier",
		name = "Global Income Multiplier",
		description = "Multiply all income from placed brainrots",
		maxLevel = 10,
		getCost = function(_currentLevel: number): number
			return 141 -- Placeholder cost
		end,
		getEffect = function(level: number): number
			return 1 + (level * 0.25) -- 1.0, 1.25, 1.5, ... 3.5
		end,
	},
}

return Upgrades
