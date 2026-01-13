--!strict
--[[
	Types.luau
	Shared type definitions for Drop A Brainrot
]]

export type Rarity = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic"

export type BrainrotId = string

export type BrainrotDefinition = {
	id: BrainrotId,
	name: string,
	rarity: Rarity,
	level: number,
	incomePerSecond: number,
}

export type BagDefinition = {
	level: number,
	capacity: number,
	maxBrainrotLevel: number,
	cost: number,
}

export type UpgradeDefinition = {
	id: string,
	name: string,
	description: string,
	maxLevel: number,
	getCost: (currentLevel: number) -> number,
	getEffect: (level: number) -> number,
}

export type PlacedBrainrot = {
	slotIndex: number,
	brainrotId: BrainrotId,
	placedAt: number,
}

export type TutorialStep = "NotStarted" | "GetBag" | "GoToCatchArea" | "PickupBrainrot" | "PlaceBrainrot" | "Complete"

export type PlayerUpgrades = {
	autocollect: number,
	offlineHours: number,
	offlineMultiplier: number,
	globalIncomeMultiplier: number,
}

export type PlayerData = {
	-- Currency
	currency: number,

	-- Bag (level determines pickup eligibility and inventory capacity)
	bagLevel: number,
	inventory: { BrainrotId },

	-- Plot
	plotSlots: number,
	placedBrainrots: { [number]: BrainrotId },
	accumulatedIncome: number,
	lastIncomeCollect: number,

	-- Upgrades
	upgrades: PlayerUpgrades,

	-- Tutorial
	tutorialStep: TutorialStep,

	-- Metadata
	lastOnline: number,
	totalPlayTime: number,
}

return nil
