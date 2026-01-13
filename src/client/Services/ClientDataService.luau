--!strict
--[[
	ClientDataService.luau
	Manages local cache of player data and listens for server updates
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)

type PlayerData = Types.PlayerData
type BrainrotId = Types.BrainrotId

local ClientDataService = {}

-- Cached player data
local cachedData: PlayerData? = nil
local currency: number = 0
local inventory: { BrainrotId } = {}
local plotState: { [number]: BrainrotId } = {}

-- Callbacks for data changes
local currencyChangedCallbacks: { (newAmount: number) -> () } = {}
local inventoryChangedCallbacks: { (newInventory: { BrainrotId }) -> () } = {}
local plotChangedCallbacks: { (newPlotState: { [number]: BrainrotId }) -> () } = {}

--[[
	Gets the cached player data.
	Returns nil if not yet loaded.
]]
function ClientDataService.getData(): PlayerData?
	return cachedData
end

--[[
	Gets the current currency amount.
]]
function ClientDataService.getCurrency(): number
	return currency
end

--[[
	Gets the current inventory.
]]
function ClientDataService.getInventory(): { BrainrotId }
	return inventory
end

--[[
	Gets the current plot state.
]]
function ClientDataService.getPlotState(): { [number]: BrainrotId }
	return plotState
end

--[[
	Subscribes to currency changes.
	Returns a function to unsubscribe.
]]
function ClientDataService.onCurrencyChanged(callback: (newAmount: number) -> ()): () -> ()
	table.insert(currencyChangedCallbacks, callback)
	return function()
		local index = table.find(currencyChangedCallbacks, callback)
		if index then
			table.remove(currencyChangedCallbacks, index)
		end
	end
end

--[[
	Subscribes to inventory changes.
	Returns a function to unsubscribe.
]]
function ClientDataService.onInventoryChanged(callback: (newInventory: { BrainrotId }) -> ()): () -> ()
	table.insert(inventoryChangedCallbacks, callback)
	return function()
		local index = table.find(inventoryChangedCallbacks, callback)
		if index then
			table.remove(inventoryChangedCallbacks, index)
		end
	end
end

--[[
	Subscribes to plot state changes.
	Returns a function to unsubscribe.
]]
function ClientDataService.onPlotChanged(callback: (newPlotState: { [number]: BrainrotId }) -> ()): () -> ()
	table.insert(plotChangedCallbacks, callback)
	return function()
		local index = table.find(plotChangedCallbacks, callback)
		if index then
			table.remove(plotChangedCallbacks, index)
		end
	end
end

--[[
	Fires all callbacks for a specific type.
]]
local function fireCurrencyCallbacks(newAmount: number)
	for _, callback in currencyChangedCallbacks do
		task.spawn(callback, newAmount)
	end
end

local function fireInventoryCallbacks(newInventory: { BrainrotId })
	for _, callback in inventoryChangedCallbacks do
		task.spawn(callback, newInventory)
	end
end

local function firePlotCallbacks(newPlotState: { [number]: BrainrotId })
	for _, callback in plotChangedCallbacks do
		task.spawn(callback, newPlotState)
	end
end

--[[
	Initialize the ClientDataService.
	Fetches initial data and sets up listeners.
]]
function ClientDataService.init()
	-- Listen for server updates
	Remotes.CurrencyUpdated.OnClientEvent:Connect(function(newAmount: number)
		currency = newAmount
		fireCurrencyCallbacks(newAmount)
	end)

	Remotes.InventoryUpdated.OnClientEvent:Connect(function(newInventory: { BrainrotId })
		print(`[ClientDataService] Received InventoryUpdated with {#newInventory} items`)
		inventory = newInventory
		fireInventoryCallbacks(newInventory)
	end)

	Remotes.PlotUpdated.OnClientEvent:Connect(function(newPlotState: { [number]: BrainrotId })
		plotState = newPlotState
		firePlotCallbacks(newPlotState)
	end)

	-- Fetch initial data from server
	task.spawn(function()
		local data = Remotes.GetPlayerData:InvokeServer()
		if data then
			cachedData = data
			currency = data.currency
			inventory = data.inventory
			plotState = data.placedBrainrots

			-- Fire initial callbacks
			fireCurrencyCallbacks(currency)
			fireInventoryCallbacks(inventory)
			firePlotCallbacks(plotState)

			print("[ClientDataService] Initial data loaded")
		else
			warn("[ClientDataService] Failed to load initial data")
		end
	end)

	print("[ClientDataService] Initialized")
end

return ClientDataService
