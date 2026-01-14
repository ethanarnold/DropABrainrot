--!strict
--[[
	SpawnButton.luau
	Button in the top-right corner that spawns a random brainrot
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local SpawnButton = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- UI elements
local screenGui: ScreenGui
local spawnButton: TextButton

--[[
	Creates the spawn button UI.
]]
local function createUI()
	-- Create ScreenGui
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SpawnButtonGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Create button (top-right corner)
	spawnButton = Instance.new("TextButton")
	spawnButton.Name = "SpawnButton"
	spawnButton.Size = UDim2.new(0, 120, 0, 50)
	spawnButton.Position = UDim2.new(1, -140, 0, 20)
	spawnButton.AnchorPoint = Vector2.new(0, 0)
	spawnButton.BackgroundColor3 = Color3.fromRGB(80, 160, 80)
	spawnButton.BorderSizePixel = 0
	spawnButton.AutoButtonColor = true
	spawnButton.Font = Enum.Font.GothamBold
	spawnButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	spawnButton.TextSize = 16
	spawnButton.Text = "Spawn!"
	spawnButton.Parent = screenGui

	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = spawnButton

	-- Click handler
	spawnButton.MouseButton1Click:Connect(function()
		Remotes.SpawnRandomBrainrot:FireServer()
	end)

	-- Parent to PlayerGui
	screenGui.Parent = playerGui
end

--[[
	Initialize the SpawnButton.
]]
function SpawnButton.init()
	createUI()
	print("[SpawnButton] Initialized")
end

return SpawnButton
