--!strict
--[[
	PickupController.luau
	Handles "hold E" input to pick up brainrots from the world
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Brainrots = require(ReplicatedStorage.Shared.Data.Brainrots)

local PickupController = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local SPAWNED_FOLDER_NAME = "SpawnedBrainrots"
local MAX_PICKUP_DISTANCE = 15 -- Studs
local HOLD_DURATION = 0.5 -- Seconds to hold E

-- State
local isHoldingE = false
local holdStartTime = 0
local currentTargetBrainrot: Instance? = nil
local currentTargetWorldId: string? = nil

-- UI elements
local pickupGui: ScreenGui
local promptFrame: Frame
local promptLabel: TextLabel
local progressBar: Frame
local progressFill: Frame

--[[
	Creates the pickup prompt UI.
]]
local function createUI()
	pickupGui = Instance.new("ScreenGui")
	pickupGui.Name = "PickupPromptGui"
	pickupGui.ResetOnSpawn = false
	pickupGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	promptFrame = Instance.new("Frame")
	promptFrame.Name = "PromptFrame"
	promptFrame.Size = UDim2.new(0, 200, 0, 60)
	promptFrame.Position = UDim2.new(0.5, -100, 0.7, 0)
	promptFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	promptFrame.BackgroundTransparency = 0.3
	promptFrame.BorderSizePixel = 0
	promptFrame.Visible = false
	promptFrame.Parent = pickupGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = promptFrame

	-- "Hold E" label
	local keyLabel = Instance.new("TextLabel")
	keyLabel.Name = "KeyLabel"
	keyLabel.Size = UDim2.new(0, 40, 0, 30)
	keyLabel.Position = UDim2.new(0, 10, 0, 5)
	keyLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	keyLabel.BorderSizePixel = 0
	keyLabel.Font = Enum.Font.GothamBold
	keyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	keyLabel.TextSize = 18
	keyLabel.Text = "E"
	keyLabel.Parent = promptFrame

	local keyCorner = Instance.new("UICorner")
	keyCorner.CornerRadius = UDim.new(0, 4)
	keyCorner.Parent = keyLabel

	-- Brainrot name label
	promptLabel = Instance.new("TextLabel")
	promptLabel.Name = "PromptLabel"
	promptLabel.Size = UDim2.new(1, -60, 0, 30)
	promptLabel.Position = UDim2.new(0, 55, 0, 5)
	promptLabel.BackgroundTransparency = 1
	promptLabel.Font = Enum.Font.GothamBold
	promptLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	promptLabel.TextSize = 14
	promptLabel.TextXAlignment = Enum.TextXAlignment.Left
	promptLabel.TextTruncate = Enum.TextTruncate.AtEnd
	promptLabel.Text = "Pick up"
	promptLabel.Parent = promptFrame

	-- Progress bar background
	progressBar = Instance.new("Frame")
	progressBar.Name = "ProgressBar"
	progressBar.Size = UDim2.new(1, -20, 0, 8)
	progressBar.Position = UDim2.new(0, 10, 1, -18)
	progressBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	progressBar.BorderSizePixel = 0
	progressBar.Parent = promptFrame

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 4)
	barCorner.Parent = progressBar

	-- Progress bar fill
	progressFill = Instance.new("Frame")
	progressFill.Name = "Fill"
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	progressFill.Position = UDim2.new(0, 0, 0, 0)
	progressFill.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressBar

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = progressFill

	pickupGui.Parent = playerGui
end

--[[
	Shows the pickup prompt for a brainrot.
]]
local function showPrompt(brainrotId: string)
	local brainrotDef = Brainrots[brainrotId]
	local displayName = if brainrotDef then brainrotDef.name else brainrotId

	promptLabel.Text = displayName
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	promptFrame.Visible = true
end

--[[
	Hides the pickup prompt.
]]
local function hidePrompt()
	promptFrame.Visible = false
	progressFill.Size = UDim2.new(0, 0, 1, 0)
end

--[[
	Updates the progress bar fill.
]]
local function updateProgress(progress: number)
	progressFill.Size = UDim2.new(math.clamp(progress, 0, 1), 0, 1, 0)

	-- Change color based on progress
	if progress >= 1 then
		progressFill.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
	else
		progressFill.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	end
end

--[[
	Checks if an instance is a brainrot in the SpawnedBrainrots folder.
	Returns the root brainrot instance if valid, nil otherwise.
]]
local function getBrainrotFromHit(hit: Instance?): Instance?
	if not hit then
		return nil
	end

	-- Walk up the hierarchy to find an instance in SpawnedBrainrots
	local current: Instance? = hit
	while current and current ~= workspace do
		local parent = current.Parent
		if parent and parent.Name == SPAWNED_FOLDER_NAME and parent.Parent == workspace then
			return current
		end
		current = parent
	end

	return nil
end

--[[
	Gets the world ID from a brainrot instance.
]]
local function getWorldId(brainrot: Instance): string?
	local worldId = brainrot:GetAttribute("WorldId")
	if worldId then
		return worldId :: string
	end
	return brainrot.Name
end

--[[
	Gets the brainrot ID from a brainrot instance.
]]
local function getBrainrotId(brainrot: Instance): string?
	local brainrotId = brainrot:GetAttribute("BrainrotId")
	if brainrotId then
		return brainrotId :: string
	end
	return brainrot.Name
end

--[[
	Performs a raycast from the camera center into the world.
]]
local function raycastFromCenter(): (Instance?, Vector3?)
	local viewportSize = camera.ViewportSize
	local centerX = viewportSize.X / 2
	local centerY = viewportSize.Y / 2

	local ray = camera:ViewportPointToRay(centerX, centerY)

	local character = player.Character
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	if character then
		raycastParams.FilterDescendantsInstances = { character }
	end

	local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
	if result then
		return result.Instance, result.Position
	end

	return nil, nil
end

--[[
	Checks if the player is looking at a brainrot within range.
	Returns the brainrot instance and its world ID if valid.
]]
local function getTargetBrainrot(): (Instance?, string?, string?)
	local character = player.Character
	if not character then
		return nil, nil, nil
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoidRootPart then
		return nil, nil, nil
	end

	local hit, hitPosition = raycastFromCenter()
	if not hit or not hitPosition then
		return nil, nil, nil
	end

	local brainrot = getBrainrotFromHit(hit)
	if not brainrot then
		return nil, nil, nil
	end

	-- Check distance
	local distance = (humanoidRootPart.Position - hitPosition).Magnitude
	if distance > MAX_PICKUP_DISTANCE then
		return nil, nil, nil
	end

	local worldId = getWorldId(brainrot)
	local brainrotId = getBrainrotId(brainrot)

	return brainrot, worldId, brainrotId
end

--[[
	Completes the pickup action.
]]
local function completePickup()
	if currentTargetWorldId then
		Remotes.PickupBrainrot:FireServer(currentTargetWorldId)
	end

	-- Reset state
	isHoldingE = false
	holdStartTime = 0
	currentTargetBrainrot = nil
	currentTargetWorldId = nil
	hidePrompt()
end

--[[
	Update loop - checks for brainrot targeting and hold progress.
]]
local function onUpdate()
	local brainrot, worldId, brainrotId = getTargetBrainrot()

	if brainrot and worldId and brainrotId then
		-- Player is looking at a valid brainrot
		if currentTargetBrainrot ~= brainrot then
			-- New target - reset hold progress
			currentTargetBrainrot = brainrot
			currentTargetWorldId = worldId
			isHoldingE = false
			holdStartTime = 0
			showPrompt(brainrotId)
		end

		-- Update hold progress if holding E
		if isHoldingE then
			local holdTime = os.clock() - holdStartTime
			local progress = holdTime / HOLD_DURATION
			updateProgress(progress)

			if progress >= 1 then
				completePickup()
			end
		else
			updateProgress(0)
		end
	else
		-- Not looking at a brainrot
		if currentTargetBrainrot then
			currentTargetBrainrot = nil
			currentTargetWorldId = nil
			isHoldingE = false
			holdStartTime = 0
			hidePrompt()
		end
	end
end

--[[
	Initialize the PickupController.
]]
function PickupController.init()
	-- Create UI
	createUI()

	-- Listen for E key press
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.E then
			if currentTargetBrainrot then
				isHoldingE = true
				holdStartTime = os.clock()
			end
		end
	end)

	-- Listen for E key release
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.E then
			isHoldingE = false
			holdStartTime = 0
			if currentTargetBrainrot then
				updateProgress(0)
			end
		end
	end)

	-- Update loop
	RunService.RenderStepped:Connect(onUpdate)

	print("[PickupController] Initialized (Hold E to pick up brainrots)")
end

return PickupController
