--!strict
--[[
	Server Entry Point
	Initializes all server-side services
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Initialize Remotes first (creates the RemoteEvents/Functions)
local _ = require(ReplicatedStorage.Shared.Remotes)

-- Require services
local DataService = require(script.Services.DataService)
local CurrencyService = require(script.Services.CurrencyService)
local BagService = require(script.Services.BagService)
local PlotService = require(script.Services.PlotService)
local DebugService = require(script.Services.DebugService)

-- Initialize services in dependency order
DataService.init() -- Must be first (others depend on player data)
CurrencyService.init() -- Depends on DataService
BagService.init() -- Depends on DataService, CurrencyService
PlotService.init() -- Depends on DataService, BagService, CurrencyService
DebugService.init() -- Debug commands for testing

-- Set up GetPlayerData remote function
local Remotes = require(ReplicatedStorage.Shared.Remotes)
Remotes.GetPlayerData.OnServerInvoke = function(player: Player)
	return DataService.waitForData(player)
end

print("[Server] All services initialized")
