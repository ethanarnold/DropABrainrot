--!strict
--[[
	Server Entry Point
	Initializes all server-side services
]]

local DataService = require(script.Services.DataService)

-- Initialize services
DataService.init()

print("[Server] All services initialized")
