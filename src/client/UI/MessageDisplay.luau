--!strict
--[[
	MessageDisplay.luau
	Displays brief toast-style messages to the player
	Messages appear at the top of the screen and auto-dismiss
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local MessageDisplay = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- UI elements
local screenGui: ScreenGui
local messageContainer: Frame

-- Queue of active messages
local activeMessages: { Frame } = {}
local MAX_VISIBLE_MESSAGES = 3
local DEFAULT_DURATION = 2

--[[
	Creates a message label and animates it in.
]]
local function createMessage(text: string, duration: number): Frame
	-- Create message frame
	local messageFrame = Instance.new("Frame")
	messageFrame.Name = "Message"
	messageFrame.Size = UDim2.new(0, 300, 0, 40)
	messageFrame.Position = UDim2.new(0.5, -150, 0, -50) -- Start above screen
	messageFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	messageFrame.BackgroundTransparency = 0.2
	messageFrame.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = messageFrame

	-- Add text
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Text"
	textLabel.Size = UDim2.new(1, -20, 1, 0)
	textLabel.Position = UDim2.new(0, 10, 0, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextSize = 16
	textLabel.Text = text
	textLabel.TextWrapped = true
	textLabel.Parent = messageFrame

	-- Parent to container
	messageFrame.Parent = messageContainer

	-- Calculate target Y position based on existing messages
	local targetY = 10
	for _, existingMessage in activeMessages do
		targetY = targetY + existingMessage.AbsoluteSize.Y + 10
	end

	-- Add to active messages
	table.insert(activeMessages, messageFrame)

	-- Animate in
	local tweenIn = TweenService:Create(
		messageFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, -150, 0, targetY) }
	)
	tweenIn:Play()

	-- Schedule removal
	task.delay(duration, function()
		-- Animate out
		local tweenOut = TweenService:Create(
			messageFrame,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{
				Position = UDim2.new(0.5, -150, 0, messageFrame.Position.Y.Offset - 20),
				BackgroundTransparency = 1,
			}
		)

		-- Fade text
		local textFade = TweenService:Create(
			textLabel,
			TweenInfo.new(0.3),
			{ TextTransparency = 1 }
		)

		tweenOut:Play()
		textFade:Play()

		tweenOut.Completed:Connect(function()
			-- Remove from active messages
			local index = table.find(activeMessages, messageFrame)
			if index then
				table.remove(activeMessages, index)
			end

			-- Destroy the frame
			messageFrame:Destroy()

			-- Reposition remaining messages
			local newY = 10
			for _, msg in activeMessages do
				local reposition = TweenService:Create(
					msg,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad),
					{ Position = UDim2.new(0.5, -150, 0, newY) }
				)
				reposition:Play()
				newY = newY + msg.AbsoluteSize.Y + 10
			end
		end)
	end)

	return messageFrame
end

--[[
	Shows a message to the player.
]]
function MessageDisplay.show(text: string, duration: number?)
	-- Limit active messages
	if #activeMessages >= MAX_VISIBLE_MESSAGES then
		-- Remove oldest message early
		local oldest = activeMessages[1]
		if oldest then
			oldest:Destroy()
			table.remove(activeMessages, 1)
		end
	end

	createMessage(text, duration or DEFAULT_DURATION)
end

--[[
	Creates the message display UI.
]]
local function createUI()
	-- Create ScreenGui
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MessageDisplayGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 100 -- Show above other UIs

	-- Create container for messages
	messageContainer = Instance.new("Frame")
	messageContainer.Name = "MessageContainer"
	messageContainer.Size = UDim2.new(1, 0, 1, 0)
	messageContainer.Position = UDim2.new(0, 0, 0, 0)
	messageContainer.BackgroundTransparency = 1
	messageContainer.Parent = screenGui

	-- Parent to PlayerGui
	screenGui.Parent = playerGui
end

--[[
	Initialize the MessageDisplay.
]]
function MessageDisplay.init()
	-- Create the UI
	createUI()

	-- Listen for server messages
	Remotes.ShowMessage.OnClientEvent:Connect(function(message: string, duration: number?)
		MessageDisplay.show(message, duration)
	end)

	print("[MessageDisplay] Initialized")
end

return MessageDisplay
