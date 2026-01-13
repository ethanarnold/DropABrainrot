--!strict
--[[
	Bags.luau
	Bag level definitions with capacity, max brainrot level, and upgrade costs
]]

local Types = require(script.Parent.Parent.Types)

export type BagDefinition = Types.BagDefinition

local Bags: { [number]: BagDefinition } = {
	[1] = {
		level = 1,
		capacity = 3,
		maxBrainrotLevel = 1,
		cost = 0, -- Starter bag (free)
	},
	[2] = {
		level = 2,
		capacity = 5,
		maxBrainrotLevel = 2,
		cost = 141,
	},
	[3] = {
		level = 3,
		capacity = 7,
		maxBrainrotLevel = 3,
		cost = 141,
	},
	[4] = {
		level = 4,
		capacity = 10,
		maxBrainrotLevel = 4,
		cost = 141,
	},
	[5] = {
		level = 5,
		capacity = 15,
		maxBrainrotLevel = 5,
		cost = 141,
	},
	[6] = {
		level = 6,
		capacity = 20,
		maxBrainrotLevel = 6,
		cost = 141,
	},
}

return Bags
