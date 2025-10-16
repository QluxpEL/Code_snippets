[5] Custom Proximity Prompt, LocalScript – New Section
-- Script that sets up custom proximityPrompts
-- This is one of my older scripts

local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer
local deem = script.promptBeem
local highlightTweenDuration = 0.2

local function ensureAttachment(part: BasePart): Attachment
	local existingAttachment = part:FindFirstChild("RootRigAttachment")
	if existingAttachment then return existingAttachment end

	local newAttachment = Instance.new("Attachment")
	newAttachment.Name = "PromptAttachment"
	newAttachment.Parent = part
	return newAttachment
end

local function setupBeem(prompt: ProximityPrompt)
	local part = prompt.Parent
	if not part or not part:IsA("BasePart") then return end
	local character = localPlayer.Character
	if not character then return end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local attach0 = ensureAttachment(root)
	local attach1 = ensureAttachment(part)

	local beem = deem:Clone()
	beem.Attachment0 = attach0
	beem.Attachment1 = attach1
	beem.Transparency = NumberSequence.new(0)
	beem.Parent = part
end

local function removeBeem(prompt: ProximityPrompt)
	local part = prompt.Parent
	if not part then return end
	local beem = part:FindFirstChild(deem.Name)
	if beem then
		beem:Destroy()
	end
end

local function tweenPrompt(prompt: ProximityPrompt, backgroundTransparency: number, textTransparency: number)
	if not prompt or not prompt.Parent then
		return
	end
	local newPrompt = prompt.Parent:FindFirstChild("Prompt")
	if newPrompt then
		local tweenInfo = TweenInfo.new(highlightTweenDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
		local properties = { BackgroundTransparency = backgroundTransparency }
		local textProperties = { TextTransparency = textTransparency }

		for _, ui in pairs(newPrompt:GetChildren()) do
			if ui:IsA("TextLabel") then
				TweenService:Create(ui, tweenInfo, properties):Play()
				TweenService:Create(ui, tweenInfo, textProperties):Play()
			end
		end
	end
end

local function togglePromptUI(prompt: ProximityPrompt, value: boolean)
	if not prompt or not prompt.Parent then
		return
	end
	local part = prompt.Parent
	local newPrompt = part:FindFirstChild("Prompt")

	if not newPrompt then
		newPrompt = script.Prompt:Clone()
		newPrompt.Parent = part
	end

	newPrompt.Main.Key.Text = prompt.KeyboardKeyCode.Name
	newPrompt.Main.Texto.Text = prompt.ActionText
	newPrompt.Main.Objectiono.Text = prompt.ObjectText
	newPrompt.Enabled = value
end

local function togglePrompt(value: boolean, prompt: ProximityPrompt)
	if prompt.Style == Enum.ProximityPromptStyle.Default then
		prompt.Style = Enum.ProximityPromptStyle.Custom
	end

	togglePromptUI(prompt, value)
end

local function promptHoldBegan(prompt: ProximityPrompt)
	local newPrompt = prompt.Parent:FindFirstChild("Prompt")
	local fillFrame = newPrompt.Main.Fill

	if prompt.HoldDuration > 800 then return end

	local tweenInfo = TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
	fillFrame.Visible = true
	local tween = TweenService:Create(fillFrame, tweenInfo, { Size = UDim2.new(4, 0,0.05, 0) })
	tween:Play()

	prompt.PromptButtonHoldEnded:Once(function()
		fillFrame.Visible = false
		tween:Cancel()
		fillFrame.Size = UDim2.new(0, 0,0.05, 0)
	end)
	
end

local highLights = {}

local function addHighlight(instance: Instance)
	if instance:IsA("Workspace") then
		return
	end
	local highlight = Instance.new("Highlight")
	table.insert(highLights, highlight)
	highlight.Adornee = instance
	highlight.OutlineTransparency = 1
	highlight.DepthMode = "Occluded"
	highlight.FillTransparency = 0.9
	highlight.FillColor = Color3.fromHex("#ffffff")

	if instance.Name == "ArmorStation" then
		highlight.OutlineColor = Color3.fromHex("#ffc45d")
	elseif instance.Name == "HealthStation" then
		highlight.OutlineColor = Color3.fromHex("#3396ff")
	else
		highlight.OutlineColor = Color3.new(1, 1, 1)
	end

	highlight.Parent = instance

	TweenService:Create(highlight, TweenInfo.new(highlightTweenDuration), { OutlineTransparency = 0.25 }):Play()
	return highlight
end

local function removeHighlight(instance: Instance)
	for i, thing in instance:GetChildren() do
		if thing:IsA("Highlight") then
			thing:Destroy()
		end
	end
end

for _, thing in pairs(game:GetDescendants()) do
	if thing:IsA("ProximityPrompt") then
		thing.Style = Enum.ProximityPromptStyle.Custom
	end
end

ProximityPromptService.PromptTriggered:Connect(function(prompt)
	local newPrompt = prompt.Parent:FindFirstChild("Prompt")
	if not newPrompt then
		return
	end
	local bar: Frame = newPrompt.Main.Background
	TweenService:Create(bar, TweenInfo.new(0.3, Enum.EasingStyle.Linear), {BackgroundColor3 = Color3.new(0.0235294, 1, 0.415686)}):Play()
	wait(0.3)
	TweenService:Create(bar, TweenInfo.new(0.3, Enum.EasingStyle.Linear), {BackgroundColor3 = Color3.new(1, 1, 1)}):Play()
end)

ProximityPromptService.PromptShown:Connect(function(prompt)
	local team = prompt:FindFirstChildWhichIsA("ObjectValue") or prompt.Parent.Parent:FindFirstChildWhichIsA("ObjectValue")
	if team and team.Value and team.Value:IsA("Team") then
		if localPlayer.Team ~= team.Value and not localPlayer.Character:FindFirstChild("Lockpick") then return end
	end

	if prompt:FindFirstChild("PromptRestrictions") then
		local modul = require(prompt:FindFirstChild("PromptRestrictions"))
		if not modul.canSee(localPlayer) then
			return
		end
	end
	--if localPlayer.Character:FindFirstChild("Lockpick") and prompt.Name ~= "DoorPrompt" then return end

	togglePrompt(true, prompt)
	tweenPrompt(prompt, 0.4, 0)
	setupBeem(prompt)

	local parentToHighlight = prompt.Parent.Parent
	if parentToHighlight then
		addHighlight(parentToHighlight)
	end
end)

ProximityPromptService.PromptHidden:Connect(function(prompt)
	tweenPrompt(prompt, 1, 1)
	togglePrompt(false, prompt)
	removeBeem(prompt)
	if not prompt or not prompt.Parent then
		return
	end
	local parentToHighlight = prompt.Parent.Parent
	if parentToHighlight then
		removeHighlight(parentToHighlight)
	end
end)

ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
	local team = prompt:FindFirstChildWhichIsA("ObjectValue") or prompt.Parent.Parent:FindFirstChildWhichIsA("ObjectValue")
	if team and team.Value and team.Value:IsA("Team") then
		if localPlayer.Team ~= team.Value then return end
	end
	promptHoldBegan(prompt)
end)

localPlayer.ChildRemoved:Connect(function()
	for i, hl in highLights do
		hl:Destroy()
	end
end)

ProximityPromptService.MaxPromptsVisible = 1
