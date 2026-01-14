--!strict
--[[
	Client entry point
	Initializes client-side services, controllers, and UI
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- Disable default Roblox backpack (we use custom inventory UI)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

-- Wait for Remotes to be created by server
ReplicatedStorage:WaitForChild("Remotes", 10)

-- Initialize services first (they manage data)
local ClientDataService = require(script.Services.ClientDataService)
ClientDataService.init()

-- Initialize controllers (they handle input)
local PickupController = require(script.Controllers.PickupController)
local PlotController = require(script.Controllers.PlotController)
local FlyController = require(script.Controllers.FlyController)
PickupController.init()
PlotController.init()
FlyController.init()

-- Initialize UI modules (they display data and handle UI interaction)
local CurrencyDisplay = require(script.UI.CurrencyDisplay)
local InventoryUI = require(script.UI.InventoryUI)
local MessageDisplay = require(script.UI.MessageDisplay)
local SpawnButton = require(script.UI.SpawnButton)
CurrencyDisplay.init()
InventoryUI.init()
MessageDisplay.init()
SpawnButton.init()

print("[Client] All services initialized")
