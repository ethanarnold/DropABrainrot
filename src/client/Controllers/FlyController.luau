--!strict
--[[
	FlyController.luau
	Handles fly mode toggled by admin command

	Controls:
	- W/S: Forward/Backward
	- A/D: Left/Right
	- Space: Up
	- LeftShift: Down
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local FlyController = {}

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Configuration
local FLY_SPEED = 50
local FLY_SPEED_FAST = 100 -- When holding E

-- State
local isFlying = false
local bodyGyro: BodyGyro? = nil
local bodyVelocity: BodyVelocity? = nil

-- Input state
local keysDown: { [Enum.KeyCode]: boolean } = {}

--[[
	Gets the movement direction based on currently pressed keys.
]]
local function getMovementDirection(): Vector3
	local direction = Vector3.zero

	-- Get camera-relative directions
	local cameraCFrame = camera.CFrame
	local forward = cameraCFrame.LookVector
	local right = cameraCFrame.RightVector
	local up = Vector3.new(0, 1, 0)

	-- WASD movement
	if keysDown[Enum.KeyCode.W] then
		direction = direction + forward
	end
	if keysDown[Enum.KeyCode.S] then
		direction = direction - forward
	end
	if keysDown[Enum.KeyCode.A] then
		direction = direction - right
	end
	if keysDown[Enum.KeyCode.D] then
		direction = direction + right
	end

	-- Vertical movement
	if keysDown[Enum.KeyCode.Space] then
		direction = direction + up
	end
	if keysDown[Enum.KeyCode.LeftShift] then
		direction = direction - up
	end

	-- Normalize if we have any movement
	if direction.Magnitude > 0 then
		direction = direction.Unit
	end

	return direction
end

--[[
	Gets the current fly speed (faster when holding E).
]]
local function getCurrentSpeed(): number
	if keysDown[Enum.KeyCode.E] then
		return FLY_SPEED_FAST
	end
	return FLY_SPEED
end

--[[
	Enables fly mode for the player.
]]
local function enableFly()
	local character = player.Character
	if not character then
		return
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not humanoidRootPart or not humanoid then
		return
	end

	isFlying = true

	-- Create BodyGyro to keep orientation stable
	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	bodyGyro.P = 10000
	bodyGyro.CFrame = humanoidRootPart.CFrame
	bodyGyro.Parent = humanoidRootPart

	-- Create BodyVelocity for movement
	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bodyVelocity.Velocity = Vector3.zero
	bodyVelocity.Parent = humanoidRootPart

	-- Set humanoid state to prevent falling animation
	humanoid.PlatformStand = true

	print("[FlyController] Fly mode enabled (WASD to move, Space/Shift for up/down, E for speed boost)")
end

--[[
	Disables fly mode for the player.
]]
local function disableFly()
	local character = player.Character

	isFlying = false

	-- Clean up physics objects
	if bodyGyro then
		bodyGyro:Destroy()
		bodyGyro = nil
	end

	if bodyVelocity then
		bodyVelocity:Destroy()
		bodyVelocity = nil
	end

	-- Reset humanoid state
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.PlatformStand = false
		end
	end

	print("[FlyController] Fly mode disabled")
end

--[[
	Update loop - handles fly movement.
]]
local function onUpdate()
	if not isFlying then
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

	-- Update body gyro to match camera orientation (yaw only)
	if bodyGyro then
		local cameraCFrame = camera.CFrame
		local _, yaw, _ = cameraCFrame:ToEulerAnglesYXZ()
		bodyGyro.CFrame = CFrame.new(humanoidRootPart.Position) * CFrame.Angles(0, yaw, 0)
	end

	-- Update velocity based on input
	if bodyVelocity then
		local direction = getMovementDirection()
		local speed = getCurrentSpeed()
		bodyVelocity.Velocity = direction * speed
	end
end

--[[
	Handles character respawn - disables fly if character dies.
]]
local function onCharacterAdded(character: Model)
	-- If we were flying, we need to wait for the character to load and re-enable
	if isFlying then
		-- Reset state since physics objects were destroyed with old character
		bodyGyro = nil
		bodyVelocity = nil
		isFlying = false

		-- Wait for character to fully load
		local humanoid = character:WaitForChild("Humanoid", 5)
		local hrp = character:WaitForChild("HumanoidRootPart", 5)

		if humanoid and hrp then
			-- Re-enable fly after a short delay
			task.delay(0.1, function()
				enableFly()
			end)
		end
	end
end

--[[
	Initialize the FlyController.
]]
function FlyController.init()
	-- Listen for fly toggle from server
	Remotes.ToggleFly.OnClientEvent:Connect(function(enabled: boolean)
		if enabled then
			enableFly()
		else
			disableFly()
		end
	end)

	-- Track input
	UserInputService.InputBegan:Connect(function(input, _gameProcessed)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			keysDown[input.KeyCode] = true
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			keysDown[input.KeyCode] = false
		end
	end)

	-- Handle character respawn
	player.CharacterAdded:Connect(onCharacterAdded)

	-- Update loop
	RunService.RenderStepped:Connect(onUpdate)

	print("[FlyController] Initialized")
end

return FlyController
