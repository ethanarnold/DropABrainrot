--!strict
--[[
	DebugService.luau
	Admin commands for testing brainrot spawning

	Commands (via chat):
	- /spawn <brainrotId> - Spawns a test brainrot at player's position
	- /spawnat <brainrotId> <x> <y> <z> - Spawns at specific position
	- /clearbrainrots - Removes all spawned brainrots
	- /givecurrency <amount> - Adds currency (for testing)
	- /fly - Toggles fly mode
]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local CurrencyService = require(script.Parent.CurrencyService)
local Brainrots = require(ReplicatedStorage.Shared.Data.Brainrots)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DebugService = {}

-- Folder for spawned brainrots
local SPAWNED_FOLDER_NAME = "SpawnedBrainrots"

-- Track fly state per player
local flyingPlayers: { [Player]: boolean } = {}

-- Authorized user IDs (add your user ID here for production)
-- In Studio, everyone is authorized for easier testing
local AUTHORIZED_USERS: { [number]: boolean } = {
	-- Add authorized user IDs here:
	-- [123456789] = true,
}

-- Check if running in Studio
local IS_STUDIO = RunService:IsStudio()

--[[
	Checks if a player is authorized to use debug commands.
]]
local function isAuthorized(player: Player): boolean
	-- Always allow in Studio for testing
	if IS_STUDIO then
		return true
	end

	return AUTHORIZED_USERS[player.UserId] == true
end

--[[
	Gets or creates the SpawnedBrainrots folder.
]]
local function getSpawnedFolder(): Folder
	local folder = workspace:FindFirstChild(SPAWNED_FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = SPAWNED_FOLDER_NAME
		folder.Parent = workspace
	end
	return folder :: Folder
end

--[[
	Spawns a brainrot at the given position.
	Returns the spawned instance if successful.
]]
function DebugService.spawnBrainrot(brainrotId: string, position: Vector3): Instance?
	-- Validate brainrot exists
	local brainrotDef = Brainrots[brainrotId]
	if not brainrotDef then
		warn(`[DebugService] Unknown brainrot: {brainrotId}`)
		return nil
	end

	-- Get the model from ServerStorage
	local brainrotsFolder = ServerStorage:FindFirstChild("Brainrots")
	if not brainrotsFolder then
		warn("[DebugService] Brainrots folder not found in ServerStorage")
		return nil
	end

	local template = brainrotsFolder:FindFirstChild(brainrotId)
	if not template then
		warn(`[DebugService] Brainrot model not found: {brainrotId}`)
		return nil
	end

	-- Clone the model
	local clone = template:Clone()

	-- Generate a unique world ID
	local worldId = HttpService:GenerateGUID(false)
	clone:SetAttribute("WorldId", worldId)
	clone:SetAttribute("BrainrotId", brainrotId)

	-- Position the brainrot
	if clone:IsA("Model") then
		local primaryPart = clone.PrimaryPart
		if primaryPart then
			clone:SetPrimaryPartCFrame(CFrame.new(position))
		else
			-- Try to find any part to position
			local part = clone:FindFirstChildWhichIsA("BasePart")
			if part then
				part.Position = position
			end
		end
	elseif clone:IsA("BasePart") then
		clone.Position = position
	end

	-- Parent to spawned folder
	clone.Parent = getSpawnedFolder()

	print(`[DebugService] Spawned {brainrotId} at {position} with WorldId {worldId}`)
	return clone
end

--[[
	Removes all spawned brainrots from the world.
]]
function DebugService.clearBrainrots()
	local folder = workspace:FindFirstChild(SPAWNED_FOLDER_NAME)
	if folder then
		for _, child in folder:GetChildren() do
			child:Destroy()
		end
		print("[DebugService] Cleared all spawned brainrots")
	end
end

--[[
	Handles chat commands from players.
]]
local function onPlayerChatted(player: Player, message: string)
	if not isAuthorized(player) then
		return
	end

	local args = string.split(message, " ")
	local command = string.lower(args[1])

	if command == "/spawn" then
		local brainrotId = args[2]
		if not brainrotId then
			print("[DebugService] Usage: /spawn <brainrotId>")
			return
		end

		local character = player.Character
		if not character then
			return
		end

		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not humanoidRootPart then
			return
		end

		-- Spawn in front of the player
		local spawnPos = humanoidRootPart.Position + humanoidRootPart.CFrame.LookVector * 5
		spawnPos = Vector3.new(spawnPos.X, spawnPos.Y + 2, spawnPos.Z)

		DebugService.spawnBrainrot(brainrotId, spawnPos)
	elseif command == "/spawnat" then
		local brainrotId = args[2]
		local x = tonumber(args[3])
		local y = tonumber(args[4])
		local z = tonumber(args[5])

		if not brainrotId or not x or not y or not z then
			print("[DebugService] Usage: /spawnat <brainrotId> <x> <y> <z>")
			return
		end

		DebugService.spawnBrainrot(brainrotId, Vector3.new(x, y, z))
	elseif command == "/clearbrainrots" then
		DebugService.clearBrainrots()
	elseif command == "/givecurrency" then
		local amount = tonumber(args[2])
		if not amount then
			print("[DebugService] Usage: /givecurrency <amount>")
			return
		end

		CurrencyService.add(player, amount)
		print(`[DebugService] Gave {amount} currency to {player.Name}`)
	elseif command == "/listbrainrots" then
		print("[DebugService] Available brainrots:")
		for id, def in Brainrots do
			print(`  {id} - {def.name} ({def.rarity}, Level {def.level})`)
		end
	elseif command == "/fly" then
		local isFlying = flyingPlayers[player] or false
		isFlying = not isFlying
		flyingPlayers[player] = isFlying

		Remotes.ToggleFly:FireClient(player, isFlying)
		print(`[DebugService] Fly mode {isFlying and "enabled" or "disabled"} for {player.Name}`)
	end
end

--[[
	Sets up chat listener for a player.
]]
local function onPlayerAdded(player: Player)
	player.Chatted:Connect(function(message)
		onPlayerChatted(player, message)
	end)
end

--[[
	Initialize the DebugService.
]]
function DebugService.init()
	-- Ensure the SpawnedBrainrots folder exists
	getSpawnedFolder()

	-- Connect to player chat
	Players.PlayerAdded:Connect(onPlayerAdded)

	-- Clean up fly state when player leaves
	Players.PlayerRemoving:Connect(function(player)
		flyingPlayers[player] = nil
	end)

	-- Handle existing players (Studio edge case)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	if IS_STUDIO then
		print("[DebugService] Initialized (Studio mode - all users authorized)")
		print("[DebugService] Commands: /spawn, /spawnat, /clearbrainrots, /givecurrency, /listbrainrots, /fly")
	else
		print("[DebugService] Initialized")
	end
end

return DebugService
