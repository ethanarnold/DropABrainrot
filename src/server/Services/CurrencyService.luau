--!strict
--[[
	CurrencyService.luau
	Handles currency operations with client replication
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local CurrencyService = {}

--[[
	Adds currency to the player and notifies the client.
	Returns the new balance, or nil if failed.
]]
function CurrencyService.add(player: Player, amount: number): number?
	local newAmount = DataService.addCurrency(player, amount)
	if newAmount then
		Remotes.CurrencyUpdated:FireClient(player, newAmount)
	end
	return newAmount
end

--[[
	Attempts to spend currency from the player.
	Returns true if successful, false if insufficient funds.
]]
function CurrencyService.spend(player: Player, amount: number): boolean
	local newAmount = DataService.addCurrency(player, -amount)
	if newAmount then
		Remotes.CurrencyUpdated:FireClient(player, newAmount)
		return true
	end
	return false
end

--[[
	Gets the current currency balance for a player.
	Returns 0 if player data not loaded.
]]
function CurrencyService.get(player: Player): number
	local data = DataService.getData(player)
	if data then
		return data.currency
	end
	return 0
end

--[[
	Initialize the CurrencyService.
]]
function CurrencyService.init()
	print("[CurrencyService] Initialized")
end

return CurrencyService
