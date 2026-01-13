--!strict
--[[
	PlotController.luau
	Handles plot interaction - placing and removing brainrots

	The UI modules will call these functions when the player:
	1. Clicks on an empty plot slot -> opens inventory to select brainrot
	2. Clicks on an occupied plot slot -> can remove the brainrot
	3. Walks over the plot -> triggers income collection
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local PlotController = {}

local player = Players.LocalPlayer

-- Debounce for income collection
local lastCollectionTime = 0
local COLLECTION_COOLDOWN = 0.5

--[[
	Requests to place a brainrot from inventory onto a plot slot.
	Called by UI when player selects a brainrot for placement.
]]
function PlotController.placeBrainrot(inventoryIndex: number, slotIndex: number)
	Remotes.PlaceBrainrot:FireServer(inventoryIndex, slotIndex)
end

--[[
	Requests to remove a brainrot from a plot slot.
	Called by UI when player wants to remove a placed brainrot.
]]
function PlotController.removeBrainrot(slotIndex: number)
	Remotes.RemoveBrainrot:FireServer(slotIndex)
end

--[[
	Requests to collect accumulated income.
	Called when player walks over their plot collection zone.
]]
function PlotController.collectIncome()
	local now = os.clock()
	if now - lastCollectionTime < COLLECTION_COOLDOWN then
		return
	end
	lastCollectionTime = now

	Remotes.CollectIncome:FireServer()
end

--[[
	Sets up a Touched listener on a Part for income collection.
	Call this with the collection zone Part from the plot.
]]
function PlotController.setupCollectionZone(collectionPart: BasePart)
	collectionPart.Touched:Connect(function(hit)
		-- Check if the hit part belongs to the local player
		local character = player.Character
		if not character then
			return
		end

		if hit:IsDescendantOf(character) then
			PlotController.collectIncome()
		end
	end)
end

--[[
	Initialize the PlotController.
]]
function PlotController.init()
	-- Note: The collection zone setup will be done when the plot is assigned/created
	-- For now, we just set up the basic controller

	print("[PlotController] Initialized")
end

return PlotController
