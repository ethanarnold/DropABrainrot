--!strict
--[[
	Remotes.luau
	Centralized RemoteEvent/RemoteFunction definitions
	Server creates them, client waits for them
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local IS_SERVER = RunService:IsServer()

type RemoteTable = {
	-- Client to Server events
	PickupBrainrot: RemoteEvent,
	PlaceBrainrot: RemoteEvent,
	RemoveBrainrot: RemoteEvent,
	CollectIncome: RemoteEvent,
	SpawnRandomBrainrot: RemoteEvent,

	-- Server to Client events
	CurrencyUpdated: RemoteEvent,
	InventoryUpdated: RemoteEvent,
	PlotUpdated: RemoteEvent,
	ShowMessage: RemoteEvent,
	ToggleFly: RemoteEvent,

	-- Request/Response functions
	GetPlayerData: RemoteFunction,
	GetInventory: RemoteFunction,
	GetPlotState: RemoteFunction,
}

-- Remote definitions with their types
local REMOTE_EVENTS = {
	-- Client to Server
	"PickupBrainrot", -- (worldBrainrotId: string) - Request pickup from world
	"PlaceBrainrot", -- (inventoryIndex: number, slotIndex: number) - Place on plot
	"RemoveBrainrot", -- (slotIndex: number) - Remove from plot back to inventory
	"CollectIncome", -- () - Collect accumulated income
	"SpawnRandomBrainrot", -- () - Request random brainrot spawn

	-- Server to Client
	"CurrencyUpdated", -- (newBalance: number) - Currency changed
	"InventoryUpdated", -- (inventory: {BrainrotId}) - Inventory changed
	"PlotUpdated", -- (plotState: {[number]: BrainrotId}) - Plot state changed
	"ShowMessage", -- (message: string, duration: number?) - Display brief UI message
	"ToggleFly", -- (enabled: boolean) - Toggle fly mode
}

local REMOTE_FUNCTIONS = {
	"GetPlayerData", -- () -> PlayerData
	"GetInventory", -- () -> {BrainrotId}
	"GetPlotState", -- () -> {[number]: BrainrotId}
}

local Remotes: RemoteTable = {} :: RemoteTable

-- Create or get the Remotes folder
local remotesFolder: Folder
if IS_SERVER then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage
else
	local folder = ReplicatedStorage:WaitForChild("Remotes", 10)
	if not folder then
		error("[Remotes] Could not find Remotes folder in ReplicatedStorage")
	end
	remotesFolder = folder :: Folder
end

-- Create or get RemoteEvents
for _, name in REMOTE_EVENTS do
	if IS_SERVER then
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remotesFolder
		Remotes[name] = remote
	else
		local remote = remotesFolder:WaitForChild(name, 10)
		if not remote then
			error(`[Remotes] Could not find RemoteEvent: {name}`)
		end
		Remotes[name] = remote :: RemoteEvent
	end
end

-- Create or get RemoteFunctions
for _, name in REMOTE_FUNCTIONS do
	if IS_SERVER then
		local remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = remotesFolder
		Remotes[name] = remote
	else
		local remote = remotesFolder:WaitForChild(name, 10)
		if not remote then
			error(`[Remotes] Could not find RemoteFunction: {name}`)
		end
		Remotes[name] = remote :: RemoteFunction
	end
end

return Remotes
