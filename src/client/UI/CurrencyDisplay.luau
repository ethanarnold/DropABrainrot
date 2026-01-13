--!strict
--[[
	CurrencyDisplay.luau
	Simple HUD element showing the player's current currency
]]

local Players = game:GetService("Players")

local ClientDataService = require(script.Parent.Parent.Services.ClientDataService)

local CurrencyDisplay = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- UI elements
local screenGui: ScreenGui
local currencyLabel: TextLabel

--[[
	Formats a number with commas for readability.
	e.g., 1234567 -> "1,234,567"
]]
local function formatNumber(num: number): string
	local formatted = tostring(math.floor(num))
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then
			break
		end
	end
	return formatted
end

--[[
	Updates the currency display with the new amount.
]]
local function updateDisplay(amount: number)
	if currencyLabel then
		currencyLabel.Text = "$" .. formatNumber(amount)
	end
end

--[[
	Creates the currency display UI.
]]
local function createUI()
	-- Create ScreenGui
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CurrencyDisplayGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Create container frame
	local container = Instance.new("Frame")
	container.Name = "CurrencyContainer"
	container.Size = UDim2.new(0, 200, 0, 50)
	container.Position = UDim2.new(0, 20, 0, 20)
	container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	container.BackgroundTransparency = 0.3
	container.BorderSizePixel = 0
	container.Parent = screenGui

	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = container

	-- Create currency icon (dollar sign)
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.new(0, 40, 1, 0)
	iconLabel.Position = UDim2.new(0, 0, 0, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
	iconLabel.TextSize = 24
	iconLabel.Text = "$"
	iconLabel.Parent = container

	-- Create currency amount label
	currencyLabel = Instance.new("TextLabel")
	currencyLabel.Name = "Amount"
	currencyLabel.Size = UDim2.new(1, -50, 1, 0)
	currencyLabel.Position = UDim2.new(0, 40, 0, 0)
	currencyLabel.BackgroundTransparency = 1
	currencyLabel.Font = Enum.Font.GothamBold
	currencyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	currencyLabel.TextSize = 22
	currencyLabel.TextXAlignment = Enum.TextXAlignment.Left
	currencyLabel.Text = "$0"
	currencyLabel.Parent = container

	-- Parent to PlayerGui
	screenGui.Parent = playerGui
end

--[[
	Initialize the CurrencyDisplay.
]]
function CurrencyDisplay.init()
	-- Create the UI
	createUI()

	-- Set initial value
	updateDisplay(ClientDataService.getCurrency())

	-- Subscribe to currency changes
	ClientDataService.onCurrencyChanged(updateDisplay)

	print("[CurrencyDisplay] Initialized")
end

return CurrencyDisplay
