--!strict
--[[
	BagService.luau
	Handles pickup validation and inventory management

	The bag is a tool that determines:
	1. Which brainrot levels can be picked up (brainrot.level <= bagLevel)
	2. Inventory capacity (based on bag level)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Bags = require(ReplicatedStorage.Shared.Data.Bags)
local Brainrots = require(ReplicatedStorage.Shared.Data.Brainrots)
local Types = require(ReplicatedStorage.Shared.Types)

type BrainrotId = Types.BrainrotId

local BagService = {}

-- Folder where spawned brainrots exist in the world
local SPAWNED_BRAINROTS_FOLDER = "SpawnedBrainrots"

--[[
	Gets the bag capacity based on the player's bag level.
]]
function BagService.getCapacity(player: Player): number
	local data = DataService.getData(player)
	if not data then
		return 0
	end

	local bagDef = Bags[data.bagLevel]
	if not bagDef then
		return 0
	end

	return bagDef.capacity
end

--[[
	Gets the max brainrot level the player can pick up based on bag level.
]]
function BagService.getMaxBrainrotLevel(player: Player): number
	local data = DataService.getData(player)
	if not data then
		return 0
	end

	local bagDef = Bags[data.bagLevel]
	if not bagDef then
		return 0
	end

	return bagDef.maxBrainrotLevel
end

--[[
	Checks if a player can pick up a brainrot.
	Returns (canPickup: boolean, reason: string?)
]]
function BagService.canPickup(player: Player, brainrotId: BrainrotId): (boolean, string?)
	local data = DataService.getData(player)
	if not data then
		return false, "Data not loaded"
	end

	-- Check if brainrot definition exists
	local brainrotDef = Brainrots[brainrotId]
	if not brainrotDef then
		return false, "Unknown brainrot"
	end

	-- Check bag level vs brainrot level
	local maxLevel = BagService.getMaxBrainrotLevel(player)
	if brainrotDef.level > maxLevel then
		return false, `Upgrade your bag to pick up {brainrotDef.rarity} brainrots!`
	end

	-- Check inventory capacity
	local capacity = BagService.getCapacity(player)
	local currentCount = #data.inventory
	if currentCount >= capacity then
		return false, "Inventory full!"
	end

	return true, nil
end

--[[
	Adds a brainrot to the player's inventory.
	Returns true if successful.
]]
function BagService.addToInventory(player: Player, brainrotId: BrainrotId): boolean
	print(`[BagService] addToInventory called for {player.Name} with brainrotId: "{brainrotId}"`)

	local data = DataService.getData(player)
	if not data then
		warn(`[BagService] No data for player {player.Name}`)
		return false
	end

	-- Verify the brainrot exists
	if not Brainrots[brainrotId] then
		warn(`[BagService] Brainrot "{brainrotId}" not found in Brainrots table`)
		return false
	end

	-- Add to inventory
	table.insert(data.inventory, brainrotId)
	print(`[BagService] Added to inventory. New inventory size: {#data.inventory}`)

	-- Notify client
	Remotes.InventoryUpdated:FireClient(player, data.inventory)
	print(`[BagService] Fired InventoryUpdated to client`)

	return true
end

--[[
	Removes a brainrot from the player's inventory by index.
	Returns the brainrot ID if successful, nil otherwise.
]]
function BagService.removeFromInventory(player: Player, index: number): BrainrotId?
	local data = DataService.getData(player)
	if not data then
		return nil
	end

	-- Validate index
	if index < 1 or index > #data.inventory then
		return nil
	end

	-- Remove and get the brainrot ID
	local brainrotId = table.remove(data.inventory, index)

	-- Notify client
	Remotes.InventoryUpdated:FireClient(player, data.inventory)

	return brainrotId
end

--[[
	Gets the player's current inventory.
]]
function BagService.getInventory(player: Player): { BrainrotId }
	local data = DataService.getData(player)
	if not data then
		return {}
	end
	return data.inventory
end

--[[
	Handles the PickupBrainrot remote event.
	Validates the brainrot exists in the world, then adds to inventory.
]]
local function onPickupBrainrot(player: Player, worldBrainrotId: string)
	-- Get the SpawnedBrainrots folder
	local folder = workspace:FindFirstChild(SPAWNED_BRAINROTS_FOLDER)
	if not folder then
		Remotes.ShowMessage:FireClient(player, "No brainrots available!", 2)
		return
	end

	-- Find the brainrot in the world by its unique ID
	local worldBrainrot: Instance? = nil
	for _, child in folder:GetChildren() do
		-- Check by name or attribute for the unique world ID
		local instanceId = child:GetAttribute("WorldId")
		if instanceId == worldBrainrotId or child.Name == worldBrainrotId then
			worldBrainrot = child
			break
		end
	end

	if not worldBrainrot then
		Remotes.ShowMessage:FireClient(player, "Brainrot not found!", 2)
		return
	end

	-- Get the brainrot ID from the world instance
	local brainrotId = worldBrainrot:GetAttribute("BrainrotId") :: string?
	print(`[BagService] BrainrotId attribute: {brainrotId or "nil"}`)
	if not brainrotId then
		-- Fallback: try to extract from model name
		brainrotId = worldBrainrot.Name
		print(`[BagService] Using model name as brainrotId: {brainrotId}`)
	end

	-- Check if player can pick up this brainrot
	local canPickup, reason = BagService.canPickup(player, brainrotId)
	if not canPickup then
		Remotes.ShowMessage:FireClient(player, reason or "Cannot pick up!", 2)
		return
	end

	-- CRITICAL: Destroy the world brainrot BEFORE adding to inventory
	-- This prevents duplication exploits
	worldBrainrot:Destroy()

	-- Add to player's inventory
	local success = BagService.addToInventory(player, brainrotId)
	if not success then
		warn("[BagService] Failed to add brainrot to inventory for", player.Name)
		-- Note: brainrot was already destroyed, this is a loss case
		-- In production, you might want to respawn it or compensate
	end
end

--[[
	Initialize the BagService.
]]
function BagService.init()
	-- Connect remote events
	Remotes.PickupBrainrot.OnServerEvent:Connect(onPickupBrainrot)

	-- Set up GetInventory remote function
	Remotes.GetInventory.OnServerInvoke = function(player: Player)
		return BagService.getInventory(player)
	end

	print("[BagService] Initialized")
end

return BagService
