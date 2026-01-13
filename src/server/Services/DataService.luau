--!strict
--[[
	DataService.luau
	Handles player data persistence using ProfileService
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileService = require(ServerScriptService.Packages.ProfileService)
local PlayerData = require(ReplicatedStorage.Shared.PlayerData)
local Types = require(ReplicatedStorage.Shared.Types)

type PlayerData = Types.PlayerData
type Profile = typeof(ProfileService.GetProfileStore("", {}):LoadProfileAsync(""))

local PROFILE_STORE_NAME = "PlayerData_v1"

local DataService = {}
DataService.__index = DataService

local ProfileStore = ProfileService.GetProfileStore(PROFILE_STORE_NAME, PlayerData.DEFAULT_DATA)
local Profiles: { [Player]: Profile } = {}

--[[
	Called when a player joins the game.
	Loads their profile from DataStore.
]]
function DataService.onPlayerAdded(player: Player)
	local profileKey = "Player_" .. player.UserId

	local profile = ProfileStore:LoadProfileAsync(profileKey)

	if profile then
		profile:AddUserId(player.UserId)
		profile:Reconcile() -- Fill in missing fields with defaults

		profile:ListenToRelease(function()
			Profiles[player] = nil
			player:Kick("Your data was loaded on another server. Please rejoin.")
		end)

		if player:IsDescendantOf(Players) then
			Profiles[player] = profile

			-- Update last online timestamp
			profile.Data.lastOnline = os.time()

			print("[DataService] Loaded profile for", player.Name)
		else
			-- Player left before profile loaded
			profile:Release()
		end
	else
		-- Profile failed to load (DataStore issues)
		player:Kick("Failed to load your data. Please try again later.")
	end
end

--[[
	Called when a player leaves the game.
	Releases their profile (triggers auto-save).
]]
function DataService.onPlayerRemoving(player: Player)
	local profile = Profiles[player]
	if profile then
		-- Update metadata before saving
		profile.Data.lastOnline = os.time()

		profile:Release()
		Profiles[player] = nil
		print("[DataService] Released profile for", player.Name)
	end
end

--[[
	Returns the player's data table.
	Returns nil if the player's profile hasn't loaded yet.
]]
function DataService.getData(player: Player): PlayerData?
	local profile = Profiles[player]
	if profile then
		return profile.Data
	end
	return nil
end

--[[
	Waits for the player's data to load and returns it.
	Times out after 10 seconds and returns nil.
]]
function DataService.waitForData(player: Player): PlayerData?
	local startTime = os.clock()
	local TIMEOUT = 10

	while os.clock() - startTime < TIMEOUT do
		local data = DataService.getData(player)
		if data then
			return data
		end
		task.wait(0.1)
	end

	warn("[DataService] Timeout waiting for data for", player.Name)
	return nil
end

--[[
	Updates a specific field in the player's data.
	Returns true if successful, false otherwise.
]]
function DataService.updateData(player: Player, key: string, value: any): boolean
	local profile = Profiles[player]
	if profile then
		(profile.Data :: any)[key] = value
		return true
	end
	return false
end

--[[
	Adds (or subtracts if negative) currency from the player.
	Returns the new currency amount, or nil if failed.
]]
function DataService.addCurrency(player: Player, amount: number): number?
	local profile = Profiles[player]
	if profile then
		local newAmount = profile.Data.currency + amount
		if newAmount < 0 then
			return nil -- Not enough currency
		end
		profile.Data.currency = newAmount
		return newAmount
	end
	return nil
end

--[[
	Force saves all active profiles.
	Call this during game shutdown.
]]
function DataService.saveAll()
	for _, profile in pairs(Profiles) do
		if profile then
			profile.Data.lastOnline = os.time()
			-- ProfileService will save on release
		end
	end
end

--[[
	Initialize the DataService.
	Sets up player connections and shutdown handling.
]]
function DataService.init()
	-- Connect player events
	Players.PlayerAdded:Connect(DataService.onPlayerAdded)
	Players.PlayerRemoving:Connect(DataService.onPlayerRemoving)

	-- Handle players already in game (studio edge case)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(DataService.onPlayerAdded, player)
	end

	-- Handle graceful shutdown
	game:BindToClose(function()
		DataService.saveAll()

		-- Release all profiles
		for _, profile in pairs(Profiles) do
			if profile then
				profile:Release()
			end
		end

		-- Wait for profiles to save
		task.wait(3)
	end)

	print("[DataService] Initialized")
end

return DataService
