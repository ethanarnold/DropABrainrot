--!strict
--[[
	InventoryUI.luau
	Displays the player's inventory with capacity indicator
	Can be opened in selection mode for placing brainrots on plots
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientDataService = require(script.Parent.Parent.Services.ClientDataService)
local PlotController = require(script.Parent.Parent.Controllers.PlotController)
local Brainrots = require(ReplicatedStorage.Shared.Data.Brainrots)
local Bags = require(ReplicatedStorage.Shared.Data.Bags)
local Types = require(ReplicatedStorage.Shared.Types)

type BrainrotId = Types.BrainrotId

local InventoryUI = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- UI state
local isOpen = false
local isSelectionMode = false
local pendingSlotIndex: number? = nil

-- UI elements
local screenGui: ScreenGui
local mainFrame: Frame
local inventoryGrid: Frame
local capacityLabel: TextLabel
local titleLabel: TextLabel

-- Rarity colors
local RARITY_COLORS = {
	Common = Color3.fromRGB(150, 150, 150),
	Uncommon = Color3.fromRGB(100, 200, 100),
	Rare = Color3.fromRGB(100, 150, 255),
	Epic = Color3.fromRGB(200, 100, 255),
	Legendary = Color3.fromRGB(255, 200, 50),
	Mythic = Color3.fromRGB(255, 100, 100),
}

--[[
	Gets the capacity for the current bag level.
]]
local function getCapacity(): number
	local data = ClientDataService.getData()
	if not data then
		return 3 -- Default
	end

	local bagDef = Bags[data.bagLevel]
	if not bagDef then
		return 3
	end

	return bagDef.capacity
end

--[[
	Creates a single inventory slot button.
]]
local function createSlotButton(index: number, brainrotId: BrainrotId?): TextButton
	local button = Instance.new("TextButton")
	button.Name = "Slot_" .. index
	button.Size = UDim2.new(0, 80, 0, 80)
	button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Text = ""

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button

	if brainrotId then
		local brainrotDef = Brainrots[brainrotId]
		if brainrotDef then
			-- Set background color based on rarity
			local rarityColor = RARITY_COLORS[brainrotDef.rarity] or RARITY_COLORS.Common
			button.BackgroundColor3 = rarityColor

			-- Add brainrot name
			local nameLabel = Instance.new("TextLabel")
			nameLabel.Name = "Name"
			nameLabel.Size = UDim2.new(1, -4, 0.6, 0)
			nameLabel.Position = UDim2.new(0, 2, 0, 2)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			nameLabel.TextSize = 10
			nameLabel.TextWrapped = true
			nameLabel.TextYAlignment = Enum.TextYAlignment.Top
			nameLabel.Text = brainrotDef.name
			nameLabel.Parent = button

			-- Add income label
			local incomeLabel = Instance.new("TextLabel")
			incomeLabel.Name = "Income"
			incomeLabel.Size = UDim2.new(1, -4, 0.3, 0)
			incomeLabel.Position = UDim2.new(0, 2, 0.7, -2)
			incomeLabel.BackgroundTransparency = 1
			incomeLabel.Font = Enum.Font.Gotham
			incomeLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
			incomeLabel.TextSize = 10
			incomeLabel.Text = "$" .. brainrotDef.incomePerSecond .. "/s"
			incomeLabel.Parent = button
		end
	else
		-- Empty slot
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Name = "Empty"
		emptyLabel.Size = UDim2.new(1, 0, 1, 0)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Font = Enum.Font.Gotham
		emptyLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
		emptyLabel.TextSize = 24
		emptyLabel.Text = "-"
		emptyLabel.Parent = button
	end

	-- Click handler
	button.MouseButton1Click:Connect(function()
		if isSelectionMode and brainrotId then
			-- Selection mode: select this brainrot for placement
			if pendingSlotIndex then
				PlotController.placeBrainrot(index, pendingSlotIndex)
				InventoryUI.close()
			end
		end
	end)

	return button
end

--[[
	Updates the inventory grid with current contents.
]]
local function updateInventoryGrid()
	if not inventoryGrid then
		return
	end

	-- Clear existing slots
	for _, child in inventoryGrid:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local inventory = ClientDataService.getInventory()
	local capacity = getCapacity()
	print(`[InventoryUI] updateInventoryGrid: {#inventory} items, capacity {capacity}`)

	-- Update capacity label
	if capacityLabel then
		capacityLabel.Text = `{#inventory}/{capacity}`
	end

	-- Create slots for inventory items and empty slots up to capacity
	for i = 1, capacity do
		local brainrotId = inventory[i]
		local button = createSlotButton(i, brainrotId)
		button.LayoutOrder = i
		button.Parent = inventoryGrid
	end
end

--[[
	Creates the inventory UI.
]]
local function createUI()
	-- Create ScreenGui
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "InventoryGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Enabled = false

	-- Create main frame
	mainFrame = Instance.new("Frame")
	mainFrame.Name = "InventoryFrame"
	mainFrame.Size = UDim2.new(0, 350, 0, 400)
	mainFrame.Position = UDim2.new(0.5, -175, 0.5, -200)
	mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	mainFrame.BackgroundTransparency = 0.1
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 12)
	mainCorner.Parent = mainFrame

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 40)
	titleBar.Position = UDim2.new(0, 0, 0, 0)
	titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = mainFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 12)
	titleCorner.Parent = titleBar

	-- Title label
	titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
	titleLabel.Position = UDim2.new(0, 15, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextSize = 18
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Text = "Inventory"
	titleLabel.Parent = titleBar

	-- Capacity label
	capacityLabel = Instance.new("TextLabel")
	capacityLabel.Name = "Capacity"
	capacityLabel.Size = UDim2.new(0.3, -15, 1, 0)
	capacityLabel.Position = UDim2.new(0.7, 0, 0, 0)
	capacityLabel.BackgroundTransparency = 1
	capacityLabel.Font = Enum.Font.GothamBold
	capacityLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	capacityLabel.TextSize = 16
	capacityLabel.TextXAlignment = Enum.TextXAlignment.Right
	capacityLabel.Text = "0/3"
	capacityLabel.Parent = titleBar

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, -35, 0, 5)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
	closeButton.BorderSizePixel = 0
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 16
	closeButton.Text = "X"
	closeButton.Parent = titleBar

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent = closeButton

	closeButton.MouseButton1Click:Connect(function()
		InventoryUI.close()
	end)

	-- Inventory grid container
	local gridContainer = Instance.new("Frame")
	gridContainer.Name = "GridContainer"
	gridContainer.Size = UDim2.new(1, -20, 1, -60)
	gridContainer.Position = UDim2.new(0, 10, 0, 50)
	gridContainer.BackgroundTransparency = 1
	gridContainer.Parent = mainFrame

	-- Scrolling frame for grid
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "ScrollFrame"
	scrollFrame.Size = UDim2.new(1, 0, 1, 0)
	scrollFrame.Position = UDim2.new(0, 0, 0, 0)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.Parent = gridContainer

	-- Inventory grid
	inventoryGrid = Instance.new("Frame")
	inventoryGrid.Name = "InventoryGrid"
	inventoryGrid.Size = UDim2.new(1, 0, 0, 0)
	inventoryGrid.Position = UDim2.new(0, 0, 0, 0)
	inventoryGrid.BackgroundTransparency = 1
	inventoryGrid.AutomaticSize = Enum.AutomaticSize.Y
	inventoryGrid.Parent = scrollFrame

	-- Grid layout
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 80, 0, 80)
	gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridLayout.Parent = inventoryGrid

	-- Parent to PlayerGui
	screenGui.Parent = playerGui
end

--[[
	Opens the inventory UI.
	If slotIndex is provided, opens in selection mode for placing.
]]
function InventoryUI.open(slotIndex: number?)
	if slotIndex then
		isSelectionMode = true
		pendingSlotIndex = slotIndex
		if titleLabel then
			titleLabel.Text = "Select Brainrot to Place"
		end
	else
		isSelectionMode = false
		pendingSlotIndex = nil
		if titleLabel then
			titleLabel.Text = "Inventory"
		end
	end

	updateInventoryGrid()
	screenGui.Enabled = true
	isOpen = true
end

--[[
	Closes the inventory UI.
]]
function InventoryUI.close()
	screenGui.Enabled = false
	isOpen = false
	isSelectionMode = false
	pendingSlotIndex = nil
end

--[[
	Toggles the inventory UI.
]]
function InventoryUI.toggle()
	if isOpen then
		InventoryUI.close()
	else
		InventoryUI.open()
	end
end

--[[
	Returns whether the inventory is currently open.
]]
function InventoryUI.isOpen(): boolean
	return isOpen
end

--[[
	Initialize the InventoryUI.
]]
function InventoryUI.init()
	-- Create the UI
	createUI()

	-- Subscribe to inventory changes
	ClientDataService.onInventoryChanged(function(_)
		if isOpen then
			updateInventoryGrid()
		end
	end)

	-- Toggle with tilde (`) key - native Roblox inventory keybind
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.Backquote then
			InventoryUI.toggle()
		end
	end)

	print("[InventoryUI] Initialized (Press ` to toggle)")
end

return InventoryUI
