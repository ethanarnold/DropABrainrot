--!strict
--[[
	PlotService.luau
	Handles plot placement, income calculation, and collection
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local BagService = require(script.Parent.BagService)
local CurrencyService = require(script.Parent.CurrencyService)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Brainrots = require(ReplicatedStorage.Shared.Data.Brainrots)
local Types = require(ReplicatedStorage.Shared.Types)

type BrainrotId = Types.BrainrotId
type PlacedBrainrot = Types.PlacedBrainrot

local PlotService = {}

-- Track which players are on cooldown for income collection
local collectionCooldowns: { [Player]: number } = {}
local COLLECTION_COOLDOWN = 0.5 -- Seconds between collections

--[[
	Gets the current plot state for a player.
	Returns a table of slotIndex -> brainrotId mappings.
]]
function PlotService.getPlotState(player: Player): { [number]: BrainrotId }
	local data = DataService.getData(player)
	if not data then
		return {}
	end
	return data.placedBrainrots
end

--[[
	Places a brainrot from inventory to a plot slot.
	Returns true if successful.
]]
function PlotService.placeBrainrot(player: Player, inventoryIndex: number, slotIndex: number): boolean
	local data = DataService.getData(player)
	if not data then
		Remotes.ShowMessage:FireClient(player, "Data not loaded!", 2)
		return false
	end

	-- Validate slot index
	if slotIndex < 1 or slotIndex > data.plotSlots then
		Remotes.ShowMessage:FireClient(player, "Invalid slot!", 2)
		return false
	end

	-- Check if slot is already occupied
	if data.placedBrainrots[slotIndex] then
		Remotes.ShowMessage:FireClient(player, "Slot already occupied!", 2)
		return false
	end

	-- Validate inventory index
	if inventoryIndex < 1 or inventoryIndex > #data.inventory then
		Remotes.ShowMessage:FireClient(player, "Invalid inventory slot!", 2)
		return false
	end

	-- Remove from inventory (this returns the brainrotId)
	local brainrotId = BagService.removeFromInventory(player, inventoryIndex)
	if not brainrotId then
		Remotes.ShowMessage:FireClient(player, "Failed to remove from inventory!", 2)
		return false
	end

	-- Place on plot
	data.placedBrainrots[slotIndex] = brainrotId

	-- Notify client of plot update
	Remotes.PlotUpdated:FireClient(player, data.placedBrainrots)

	return true
end

--[[
	Removes a brainrot from a plot slot and returns it to inventory.
	Returns true if successful.
]]
function PlotService.removeBrainrot(player: Player, slotIndex: number): boolean
	local data = DataService.getData(player)
	if not data then
		Remotes.ShowMessage:FireClient(player, "Data not loaded!", 2)
		return false
	end

	-- Check if slot has a brainrot
	local brainrotId = data.placedBrainrots[slotIndex]
	if not brainrotId then
		Remotes.ShowMessage:FireClient(player, "No brainrot in this slot!", 2)
		return false
	end

	-- Check if inventory has space
	local capacity = BagService.getCapacity(player)
	if #data.inventory >= capacity then
		Remotes.ShowMessage:FireClient(player, "Inventory full!", 2)
		return false
	end

	-- Remove from plot
	data.placedBrainrots[slotIndex] = nil

	-- Add back to inventory
	local success = BagService.addToInventory(player, brainrotId)
	if not success then
		-- Rollback: put it back on the plot
		data.placedBrainrots[slotIndex] = brainrotId
		Remotes.ShowMessage:FireClient(player, "Failed to add to inventory!", 2)
		return false
	end

	-- Notify client of plot update
	Remotes.PlotUpdated:FireClient(player, data.placedBrainrots)

	return true
end

--[[
	Calculates the income per second for a player based on placed brainrots.
]]
function PlotService.getIncomePerSecond(player: Player): number
	local data = DataService.getData(player)
	if not data then
		return 0
	end

	local incomePerSecond = 0
	for _, brainrotId in data.placedBrainrots do
		local brainrotDef = Brainrots[brainrotId]
		if brainrotDef then
			incomePerSecond += brainrotDef.incomePerSecond
		end
	end

	-- Apply global income multiplier
	incomePerSecond *= data.upgrades.globalIncomeMultiplier

	return incomePerSecond
end

--[[
	Calculates the accumulated income since last collection.
]]
function PlotService.calculateAccumulatedIncome(player: Player): number
	local data = DataService.getData(player)
	if not data then
		return 0
	end

	local now = os.time()
	local lastCollect = data.lastIncomeCollect
	if lastCollect == 0 then
		-- First time - set the timestamp and return 0
		data.lastIncomeCollect = now
		return 0
	end

	local elapsedSeconds = now - lastCollect
	local incomePerSecond = PlotService.getIncomePerSecond(player)

	return elapsedSeconds * incomePerSecond
end

--[[
	Collects accumulated income and adds it to the player's currency.
	Returns the amount collected.
]]
function PlotService.collectIncome(player: Player): number
	-- Check cooldown
	local now = os.clock()
	local lastCollection = collectionCooldowns[player]
	if lastCollection and (now - lastCollection) < COLLECTION_COOLDOWN then
		return 0
	end
	collectionCooldowns[player] = now

	local data = DataService.getData(player)
	if not data then
		return 0
	end

	-- Calculate accumulated income
	local income = PlotService.calculateAccumulatedIncome(player)
	if income <= 0 then
		return 0
	end

	-- Floor the income (no fractional currency)
	income = math.floor(income)

	-- Add to currency
	local newBalance = CurrencyService.add(player, income)
	if not newBalance then
		return 0
	end

	-- Reset the collection timer
	data.lastIncomeCollect = os.time()

	return income
end

--[[
	Handles the PlaceBrainrot remote event.
]]
local function onPlaceBrainrot(player: Player, inventoryIndex: number, slotIndex: number)
	-- Validate input types
	if type(inventoryIndex) ~= "number" or type(slotIndex) ~= "number" then
		return
	end

	PlotService.placeBrainrot(player, inventoryIndex, slotIndex)
end

--[[
	Handles the RemoveBrainrot remote event.
]]
local function onRemoveBrainrot(player: Player, slotIndex: number)
	-- Validate input type
	if type(slotIndex) ~= "number" then
		return
	end

	PlotService.removeBrainrot(player, slotIndex)
end

--[[
	Handles the CollectIncome remote event.
]]
local function onCollectIncome(player: Player)
	local income = PlotService.collectIncome(player)
	if income > 0 then
		Remotes.ShowMessage:FireClient(player, `+${income}`, 1)
	end
end

--[[
	Clean up when player leaves.
]]
local function onPlayerRemoving(player: Player)
	collectionCooldowns[player] = nil
end

--[[
	Initialize the PlotService.
]]
function PlotService.init()
	-- Connect remote events
	Remotes.PlaceBrainrot.OnServerEvent:Connect(onPlaceBrainrot)
	Remotes.RemoveBrainrot.OnServerEvent:Connect(onRemoveBrainrot)
	Remotes.CollectIncome.OnServerEvent:Connect(onCollectIncome)

	-- Set up GetPlotState remote function
	Remotes.GetPlotState.OnServerInvoke = function(player: Player)
		return PlotService.getPlotState(player)
	end

	-- Clean up on player leave
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	print("[PlotService] Initialized")
end

return PlotService
