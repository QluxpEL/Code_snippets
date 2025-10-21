-- One of the latest and hardest scripts to accomplish, done by me, a custom inventory system.
-- Some code may have been inspired by public sources such as Roblox dev forms while I was doing research on how to perform such a system.

local starterUI = game:GetService("StarterGui")
local mouse = game.Players.LocalPlayer:GetMouse()
local tweenService = game:GetService("TweenService")
local overLap = require(game.ReplicatedStorage.MainStorage.Modules.PlayerRelated.UIOverlap)

starterUI:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local lastSavedFormatting = {
	["1"] = nil,
	["2"] = nil,
	["3"] = nil,
	["4"] = nil,
	["5"] = nil,
	["6"] = nil,
	["7"] = nil,
	["8"] = nil,
	["9"] = nil,
}

local player = game.Players.LocalPlayer

local ui = player.PlayerGui:WaitForChild("HotBar")
local screen = ui.Screen

ui.Enabled = true
local showInventory = false

local tweenTime = 0.15

local backPack = player.Backpack

local equipColor = Color3.new(0.396078, 0.486275, 1)
local unEquipColor = Color3.new(1, 1, 1)

local template = screen.Template

local tools = {}

local equiped = nil

local function creatNewItemInInventory(i)
	local cloned = template:Clone()
	local core = cloned.Core
	core.ToolName.Text = ""
	core.ToolIcon.Image = ""
	core.Bar.Visible = true
	core.Bar.Transparency = 1
	cloned.Name = tostring(i)
	core.ToolPosition.Text = tostring(i)
	cloned.Visible = showInventory
	core.TextButton.Visible = not showInventory
	core.UIDragDetector.Enabled = showInventory
	cloned.Parent = screen
end


local stringToNumber = {
	["One"] = 1,
	["Two"] = 2,
	["Three"] = 3,
	["Four"] = 4,
	["Five"] = 5,
	["Six"] = 6,
	["Seven"] = 7,
	["Eight"] = 8,
	["Nine"] = 9,
}

local function isToolInTable(tool)
	if not tool then
		return false, nil
	end

	local isTool, position = false, nil
	for i, speacialTool in tools do
		if speacialTool == tool then
			isTool = true
			position = i
			break
		end
	end

	return isTool, position
end

local defaultSize = screen.Template.Size

local targetSize = defaultSize + UDim2.new(defaultSize.X.Scale/8, 0, defaultSize.Y.Scale/8, 0)

local function handelUnequip()
	local humanoid: Humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid or not equiped then
		return
	end
	local toolFrame = equiped:FindFirstChild("ToolsFrame")
	if not toolFrame then
		return
	end
	if not ui.Enabled then
		return
	end
	toolFrame = toolFrame.Value
	toolFrame.Core.UIStroke.Color = unEquipColor
	tweenService:Create(toolFrame.Core.Bar, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {Transparency = 1}):Play()
	tweenService:Create(toolFrame, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {Size = defaultSize}):Play()
	equiped = nil
	humanoid:UnequipTools()
end

local function handelEqup(tool)
	local humanoid: Humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	if not tool then
		return
	end
	if equiped == tool then
		return
	end
	if equiped then
		handelUnequip()
	end
	if not ui.Enabled then
		return
	end
	local toolFrame = tool:FindFirstChild("ToolsFrame")
	if not toolFrame then
		return
	end
	toolFrame = toolFrame.Value
	toolFrame.Core.UIStroke.Color = equipColor
	tweenService:Create(toolFrame.Core.Bar, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {Transparency = 0}):Play()
	tweenService:Create(toolFrame, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {Size = targetSize}):Play()
	equiped = tool
	humanoid:EquipTool(tool)
end

game:GetService("UserInputService").InputBegan:Connect(function(input, proc)
	local humanoid: Humanoid = player.Character:FindFirstChild("Humanoid")
	local number = stringToNumber[input.KeyCode.Name]
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	if proc then
		return
	end
	if input.KeyCode == Enum.KeyCode.Semicolon or input.KeyCode == Enum.KeyCode.Backquote then
		showInventory = not showInventory
		for i, frame in screen:GetChildren() do
			if not frame:IsA("Frame") then
				continue
			end
			if frame.Core.ToolName.Text == "" and frame.Core.ToolIcon.Image == "" then
				frame.Visible = showInventory
				frame.Core.UIDragDetector.Enabled = showInventory
				continue
			end
			frame.Core.TextButton.Visible = not showInventory
			frame.Core.UIDragDetector.Enabled = showInventory
		end
		return
	end
	if not number then
		return
	end
	local targetFrame: Frame = nil
	local targetTool: Tool = nil
	for i, tool: Tool in tools do
		local toolsFrame = tool:FindFirstChild("ToolsFrame")
		if not toolsFrame then
			continue
		end
		local frame = toolsFrame.Value
		if frame.Name == tostring(number) then
			targetFrame = frame
			targetTool = tool
			break
		end
	end
	if not targetTool or not targetFrame then
		return
	end

	if equiped == targetTool then
		handelUnequip()
	else
		handelEqup(targetTool)
	end
end)

local function getAvalaibleSlot()
	for i = 1, 9 do
		local frame = screen:FindFirstChild(tostring(i))
		if frame and frame.Core.ToolName.Text == "" and frame.Core.ToolIcon.Image == "" then
			return i
		end
	end
	return nil
end

local function hasAnyToolsInFormatting()
	for _, toolName in pairs(lastSavedFormatting) do
		if toolName then
			return true
		end
	end
	return false
end

local alreadyFirst = false
local timeFirstGiven = 0
local timeSinceSpawn = 0
local usedToolSpots = {}

local function newItem(tool: Tool)
	local Sorting = false
	if isToolInTable(tool) then
		return
	end
	if not tool:IsA("Tool") then
		return
	end

	if not alreadyFirst then
		alreadyFirst = true
		timeFirstGiven = tick()
	end

	if tick() - timeFirstGiven < 3 then
		Sorting = true
	end
	if tick() - timeSinceSpawn > 10 then
		Sorting = false
	end

	table.insert(tools, tool)

	local toolFrame = nil

	if Sorting and hasAnyToolsInFormatting() then
		local foundSpot = false
		for i, toolInSpot in pairs(lastSavedFormatting) do
			if toolInSpot == tool.Name then
				local spotUsed = false
				for _, spotAlreadyUsed in pairs(usedToolSpots) do
					if tonumber(i) == spotAlreadyUsed then
						spotUsed = true
						break
					end
				end
				if not spotUsed then
					table.insert(usedToolSpots, tonumber(i))
					toolFrame = screen:FindFirstChild(tostring(i))
					foundSpot = true
					break
				end
			end
		end
		if not foundSpot then
			for i = 1, 9 do
				local isReserved = false
				for savedSlot, savedTool in pairs(lastSavedFormatting) do
					if tonumber(savedSlot) == i and savedTool then
						isReserved = true
						break
					end
				end
				if not isReserved then
					if screen:FindFirstChild(tostring(i)) then
						toolFrame = screen:FindFirstChild(tostring(i))
						break
					end
				end
			end
		end
	else
		local availableSlot = getAvalaibleSlot()
		if availableSlot then
			toolFrame = screen:FindFirstChild(tostring(availableSlot))
		end
	end

	if not toolFrame then
		return
	end

	lastSavedFormatting[toolFrame.Name] = tool.Name

	toolFrame.Visible = true
	toolFrame.Core.ToolIcon.Image = tool.TextureId
	toolFrame.Core.ToolName.Text = tool.TextureId == "" and tool.Name or ""

	local objectVlue = Instance.new("ObjectValue")
	objectVlue.Value = toolFrame
	objectVlue.Name = "ToolsFrame"
	objectVlue.Parent = tool

	toolFrame.ToolRef.Value = tool

	toolFrame.Core.TextButton.Visible = not showInventory
	toolFrame.Core.UIDragDetector.Enabled = showInventory

	local function buttonPressed()
		local humanoid: Humanoid = player.Character:FindFirstChild("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return
		end
		if equiped == tool then
			handelUnequip()
		else
			handelEqup(tool)
		end
	end

	toolFrame.Core.UIDragDetector.DragStart:Connect(function()
		local startTime = os.clock()
		toolFrame.Core.UIDragDetector.DragEnd:Once(function()
			local endTime = os.clock()
			if (endTime - startTime) <= 0.11 then
				buttonPressed()
			end
			local overlapingWith = nil
			for i, specialFrame in screen:GetChildren() do
				if not specialFrame:IsA("Frame") or specialFrame.Name == "Template" or specialFrame == toolFrame then
					continue
				end
				if overLap.isOverlapping(toolFrame.Core, specialFrame.Core) then
					overlapingWith = specialFrame
					break
				end
			end
			if overlapingWith then
				local overlapName = overlapingWith.Name
				local standartFrameName = toolFrame.Name

				overlapingWith.Name = standartFrameName
				toolFrame.Name = overlapName

				overlapingWith.Core.ToolPosition.Text = standartFrameName
				toolFrame.Core.ToolPosition.Text = overlapName

				local overlapTool = overlapingWith.ToolRef.Value
				local currentTool = toolFrame.ToolRef.Value

				if overlapTool then
					lastSavedFormatting[overlapingWith.Name] = overlapTool.Name
				else
					lastSavedFormatting[overlapingWith.Name] = nil
				end

				if currentTool then
					lastSavedFormatting[toolFrame.Name] = currentTool.Name
				else
					lastSavedFormatting[toolFrame.Name] = nil
				end
			end
			toolFrame.Core.Position = UDim2.new(0,0,0,0)
		end)
	end)

	toolFrame.Core.TextButton.MouseButton1Click:Connect(function()
		buttonPressed()
	end)
end


local function handelToolRemoval(tool: Tool)
	local toolsFrame = tool:FindFirstChild("ToolsFrame")
	if not toolsFrame then
		return
	end
	local frame = toolsFrame.Value
	local frameNumber = frame.Name
	local _, position = isToolInTable(tool)

	if equiped == tool then
		equiped = nil
	end

	if position then
		table.remove(tools, position)
	end

	lastSavedFormatting[frameNumber] = nil

	frame:Destroy()
	creatNewItemInInventory(frameNumber)
end

local backpackChildRemovedConnection
local characterChildRemovedConnection

local function connectBackpack(backpack)
	if backpackChildRemovedConnection then
		backpackChildRemovedConnection:Disconnect()
	end

	backpackChildRemovedConnection = backpack.ChildRemoved:Connect(function(tool)
		if tool.Parent ~= player.Character then
			handelToolRemoval(tool)
			return
		end
		handelEqup(tool)
	end)
end

local function connectCharacter(character)
	
	print("CharAdded")
	for i, thing in screen:GetChildren() do
		if not thing:IsA("Frame") or thing.Name == "Template" then
			continue
		end
		thing:Destroy()
	end
	table.clear(tools)
	equiped = nil
	alreadyFirst  =false
	timeSinceSpawn = tick()
	usedToolSpots = {}
	for i = 1, 9 do
		creatNewItemInInventory(i)
	end
	for i, item in player.Backpack:GetChildren() do
		newItem(item)
	end
	
	if characterChildRemovedConnection then
		characterChildRemovedConnection:Disconnect()
	end

	characterChildRemovedConnection = character.ChildRemoved:Connect(function(tool)
		if not tool:IsA("Tool") then
			return
		end
		if tool.Parent ~= player.Backpack and tool.Parent ~= nil then
			handelToolRemoval(tool)
			return
		end
	end)

	local backpack = player:WaitForChild("Backpack")
	connectBackpack(backpack)

	player:WaitForChild("PlayerGui"):WaitForChild("HotBar").Enabled = true
end

player.CharacterAdded:Connect(function(character)
	connectCharacter(character)
end)

if player.Character then
	connectCharacter(player.Character)
end
