-- Custom Proximity Prompt System
-- Handles visual effects, UI, and interactions for ProximityPrompts in the game
-- Includes beam effects, highlights, and custom UI elements

local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer
local beamTemplate = script.promptBeem -- Template beam object stored in the script
local highlightTweenDuration = 0.2

-- Table to track all active highlights for cleanup
local highlights = {}

-- Ensures a part has an attachment for beam connection
-- Returns existing attachment or creates a new one
local function ensureAttachment(part: BasePart): Attachment
	local existingAttachment = part:FindFirstChild("RootRigAttachment")
	if existingAttachment then 
		return existingAttachment 
	end

	local newAttachment = Instance.new("Attachment")
	newAttachment.Name = "PromptAttachment"
	newAttachment.Parent = part
	return newAttachment
end

-- Creates a visual beam connecting the player to the prompt
-- The beam shows a line from player's HumanoidRootPart to the prompt's parent part
local function setupBeam(prompt: ProximityPrompt)
	local part = prompt.Parent
	if not part or not part:IsA("BasePart") then 
		return 
	end
	
	local character = localPlayer.Character
	if not character then 
		return 
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then 
		return 
	end

	-- Create attachments for beam endpoints
	local attach0 = ensureAttachment(root)
	local attach1 = ensureAttachment(part)

	-- Clone and configure the beam
	local beam = beamTemplate:Clone()
	beam.Attachment0 = attach0
	beam.Attachment1 = attach1
	beam.Transparency = NumberSequence.new(0)
	beam.Parent = part
end

-- Removes the beam visual effect from a prompt
local function removeBeam(prompt: ProximityPrompt)
	local part = prompt.Parent
	if not part then 
		return 
	end
	
	local beam = part:FindFirstChild(beamTemplate.Name)
	if beam then
		beam:Destroy()
	end
end

-- Tweens the custom prompt UI transparency
-- Used for fade in/out effects when showing/hiding prompts
local function tweenPrompt(prompt: ProximityPrompt, backgroundTransparency: number, textTransparency: number)
	if not prompt or not prompt.Parent then
		return
	end
	
	local newPrompt = prompt.Parent:FindFirstChild("Prompt")
	if newPrompt then
		local tweenInfo = TweenInfo.new(highlightTweenDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
		local properties = { BackgroundTransparency = backgroundTransparency }
		local textProperties = { TextTransparency = textTransparency }

		-- Apply tweens to all text labels in the prompt UI
		for _, ui in newPrompt:GetChildren() do
			if ui:IsA("TextLabel") then
				TweenService:Create(ui, tweenInfo, properties):Play()
				TweenService:Create(ui, tweenInfo, textProperties):Play()
			end
		end
	end
end

-- Creates or updates the custom prompt UI with current prompt information
local function togglePromptUI(prompt: ProximityPrompt, value: boolean)
	if not prompt or not prompt.Parent then
		return
	end
	
	local part = prompt.Parent
	local newPrompt = part:FindFirstChild("Prompt")

	-- Clone the template if it doesn't exist
	if not newPrompt then
		newPrompt = script.Prompt:Clone()
		newPrompt.Parent = part
	end

	-- Update UI text with prompt data
	newPrompt.Main.Key.Text = prompt.KeyboardKeyCode.Name
	newPrompt.Main.Texto.Text = prompt.ActionText
	newPrompt.Main.Objectiono.Text = prompt.ObjectText
	newPrompt.Enabled = value
end

-- Main function to show/hide the custom prompt UI
local function togglePrompt(value: boolean, prompt: ProximityPrompt)
	-- Ensure prompt is set to Custom style to use our UI
	if prompt.Style == Enum.ProximityPromptStyle.Default then
		prompt.Style = Enum.ProximityPromptStyle.Custom
	end

	togglePromptUI(prompt, value)
end

-- Handles the visual fill animation when holding a prompt
-- Shows a progress bar that fills during the hold duration
local function promptHoldBegan(prompt: ProximityPrompt)
	local newPrompt = prompt.Parent:FindFirstChild("Prompt")
	if not newPrompt then 
		return 
	end
	
	local fillFrame = newPrompt.Main.Fill

	-- Only animate for reasonable hold durations (< 800 seconds)
	-- If the hold duration is over 800 seconds, the prompt will act like if the hold time is infinite
	-- This is used in healing station where you hold E to heal, but the heal duration is unknow, so we set the hold to be infinite.
	if prompt.HoldDuration > 800 then 
		return 
	end

	local tweenInfo = TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
	fillFrame.Visible = true
	
	-- Tween the fill bar to full width
	local tween = TweenService:Create(fillFrame, tweenInfo, { Size = UDim2.new(4, 0, 0.05, 0) })
	tween:Play()

	-- Reset fill bar if hold is released early
	prompt.PromptButtonHoldEnded:Once(function()
		fillFrame.Visible = false
		tween:Cancel()
		fillFrame.Size = UDim2.new(0, 0, 0.05, 0)
	end)
end

-- Adds a highlight effect to an instance
-- Different colors are used based on the instance name (stations)
local function addHighlight(instance: Instance)
	-- Don't highlight workspace itself
	if instance:IsA("Workspace") then
		return
	end
	
	local highlight = Instance.new("Highlight")
	table.insert(highlights, highlight)
	highlight.Adornee = instance
	highlight.OutlineTransparency = 1
	highlight.DepthMode = "Occluded"
	highlight.FillTransparency = 0.9
	highlight.FillColor = Color3.fromHex("#ffffff")

	-- Set outline color based on station type
	if instance.Name == "ArmorStation" then
		highlight.OutlineColor = Color3.fromHex("#ffc45d") -- Orange for armor
	elseif instance.Name == "HealthStation" then
		highlight.OutlineColor = Color3.fromHex("#3396ff") -- Blue for health
	else
		highlight.OutlineColor = Color3.new(1, 1, 1) -- White default
	end

	highlight.Parent = instance

	-- Fade in the outline
	TweenService:Create(highlight, TweenInfo.new(highlightTweenDuration), { OutlineTransparency = 0.25 }):Play()
	return highlight
end

-- Removes all highlight effects from an instance
local function removeHighlight(instance: Instance)
	for _, child in instance:GetChildren() do
		if child:IsA("Highlight") then
			child:Destroy()
		end
	end
end

-- Initialize all existing ProximityPrompts to use custom style
for _, descendant in game:GetDescendants() do
	if descendant:IsA("ProximityPrompt") then
		descendant.Style = Enum.ProximityPromptStyle.Custom
	end
end

-- Handle prompt activation with visual feedback (green flash)
ProximityPromptService.PromptTriggered:Connect(function(prompt)
	local newPrompt = prompt.Parent:FindFirstChild("Prompt")
	if not newPrompt then
		return
	end
	
	local bar: Frame = newPrompt.Main.Background
	-- Flash green to indicate successful activation
	TweenService:Create(bar, TweenInfo.new(0.3, Enum.EasingStyle.Linear), {BackgroundColor3 = Color3.new(0.0235294, 1, 0.415686)}):Play()
	task.wait(0.3) -- Using task.wait instead of deprecated wait()
	TweenService:Create(bar, TweenInfo.new(0.3, Enum.EasingStyle.Linear), {BackgroundColor3 = Color3.new(1, 1, 1)}):Play()
end)

-- Handle prompt visibility with team and restriction checks
ProximityPromptService.PromptShown:Connect(function(prompt)
	-- Check if prompt is team-restricted
	local team = prompt:FindFirstChildWhichIsA("ObjectValue") or prompt.Parent.Parent:FindFirstChildWhichIsA("ObjectValue")
	if team and team.Value and team.Value:IsA("Team") then
		-- Only show to team members or players with lockpick
		if localPlayer.Team ~= team.Value and not localPlayer.Character:FindFirstChild("Lockpick") then 
			return 
		end
	end

	-- Check custom restrictions module if it exists
	if prompt:FindFirstChild("PromptRestrictions") then
		local restrictionModule = require(prompt:FindFirstChild("PromptRestrictions"))
		if not restrictionModule.canSee(localPlayer) then
			return
		end
	end

	-- Show the prompt UI and effects
	togglePrompt(true, prompt)
	tweenPrompt(prompt, 0.4, 0)
	setupBeam(prompt)

	-- Add highlight to the parent object (e.g., the station itself)
	local parentToHighlight = prompt.Parent.Parent
	if parentToHighlight then
		addHighlight(parentToHighlight)
	end
end)

-- Handle prompt hidden event - cleanup all visual effects
ProximityPromptService.PromptHidden:Connect(function(prompt)
	tweenPrompt(prompt, 1, 1)
	togglePrompt(false, prompt)
	removeBeam(prompt)
	
	if not prompt or not prompt.Parent then
		return
	end
	
	-- Remove highlight from parent object
	local parentToHighlight = prompt.Parent.Parent
	if parentToHighlight then
		removeHighlight(parentToHighlight)
	end
end)

-- Handle hold button interaction with team check
ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
	-- Verify team access before showing hold animation
	local team = prompt:FindFirstChildWhichIsA("ObjectValue") or prompt.Parent.Parent:FindFirstChildWhichIsA("ObjectValue")
	if team and team.Value and team.Value:IsA("Team") then
		if localPlayer.Team ~= team.Value then 
			return 
		end
	end
	
	promptHoldBegan(prompt)
end)

-- Cleanup all highlights when player dies or character is removed
localPlayer.CharacterRemoving:Connect(function()
	for _, highlight in highlights do
		highlight:Destroy()
	end
	-- Clear the table
	table.clear(highlights)
end)

-- Limit to only show one prompt at a time for clarity
ProximityPromptService.MaxPromptsVisible = 1
