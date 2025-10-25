-- One of the latest and hardest scripts to accomplish, done by me, a custom inventory system.
-- Some code may have been inspired by public sources such as Roblox dev forums while I was doing research on how to perform such a system.

local starterUI = game:GetService("StarterGui")
local mouse = game.Players.LocalPlayer:GetMouse()
local tweenService = game:GetService("TweenService")
-- An overlap module script that checks if two frames overlap each other. Returns true or false.
local overLap = require(game.ReplicatedStorage.MainStorage.Modules.PlayerRelated.UIOverlap)

starterUI:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

-- Table that saves position of tools within the inventory
-- that can be used to sort items upon respawn to save players time.
local lastSavedToolsPositions = {
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

-- When HotBar Enabled property is set to false, script will not react to any inputs given by the player.

local displayingFullInventory = false

local tweenTime = 0.15

local backPack = player.Backpack

local equipColor = Color3.new(0.396078, 0.486275, 1)
local unEquipColor = Color3.new(1, 1, 1)

local template = screen.Template

-- Tracks all tools in player's inventory
-- The order of the tools may not equal the same position within the inventory
local tools = {}

-- Value that stores the currently equipped tool
local equiped = nil

local function creatNewInventoryFrame(toolPosition)
	-- toolPosition argument sets where in the UI should the tool appear
	local clonedTemplate = template:Clone()
	-- Core frame of the tool
	local templateCore = clonedTemplate.Core
	templateCore.ToolName.Text = ""
	templateCore.ToolIcon.Image = ""
	templateCore.Bar.Visible = true
	templateCore.Bar.Transparency = 1
	clonedTemplate.Name = tostring(toolPosition)
	templateCore.ToolPosition.Text = tostring(toolPosition)
	clonedTemplate.Visible = displayingFullInventory
	templateCore.TextButton.Visible = not displayingFullInventory
	templateCore.UIDragDetector.Enabled = displayingFullInventory
	clonedTemplate.Parent = screen
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

-- Searches the tools table for specified tool
local function checkToolsTableForTool(tool, toolPosotion)
	if not tool then
		return false, nil
	end

	local foundTool, toolPositionInTable = false, nil
	for i, speacialTool in tools do
		if speacialTool == tool then
			foundTool = true
			toolPositionInTable = i
			break
		end
	end

	return foundTool, toolPositionInTable
end

local defaultSize = screen.Template.Size

local equipedSize = defaultSize + UDim2.new(defaultSize.X.Scale/8, 0, defaultSize.Y.Scale/8, 0)

local function handelUnequip()
	-- Safe check to make sure there is a tool to be unequipped
	if not equiped then
		return
	end
	local humanoid: Humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end
	-- Searches for a ToolsFrame object value inside the equipped tool
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
	-- Check that makes sure only alive players can equip tools
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
	-- Searches for a ToolsFrame object value inside the equipped tool
	local toolFrame = tool:FindFirstChild("ToolsFrame")
	if not toolFrame then
		return
	end
	toolFrame = toolFrame.Value
	toolFrame.Core.UIStroke.Color = equipColor
	tweenService:Create(toolFrame.Core.Bar, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {Transparency = 0}):Play()
	tweenService:Create(toolFrame, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {Size = equipedSize}):Play()
	equiped = tool
	humanoid:EquipTool(tool)
end


game:GetService("UserInputService").InputBegan:Connect(function(input, proc)
	local humanoid: Humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	if proc then
		return
	end

	-- Toggles between showing and hiding the player's backpack

	if input.KeyCode == Enum.KeyCode.Semicolon or input.KeyCode == Enum.KeyCode.Backquote then

		displayingFullInventory = not displayingFullInventory
		for i, frame in screen:GetChildren() do

			if not frame:IsA("Frame") then
				continue
			end

			frame.Core.UIDragDetector.Enabled = displayingFullInventory

			-- If ToolName or ToolIcon.Image is an empty string, the slot is empty.
			-- In that case, we only need to show or hide the slot.
			if frame.Core.ToolName.Text == "" and frame.Core.ToolIcon.Image == "" then
				frame.Visible = displayingFullInventory
				continue
			end

			-- We don't modify frames that already contain a tool,
			-- because all tools in the inventory are displayed by default,
			-- and we don't want to hide them when closing the backpack.

			-- We enable/disable the button that handles manual tool equipping
			-- to allow or restrict the drag detector from moving the tool.
			frame.Core.TextButton.Visible = not displayingFullInventory
		end

		-- Stopping the code progression, since we know a key was pressed to toggle the inventory
		-- not to equip or unequip any tool
		return
	end

	-- Converts input key to a number
	local inputNumber = stringToNumber[input.KeyCode.Name]

	-- Handles equipping or unequipping the tool by keyboard input

	-- Do not process if the keyCode is not a valid number
	if not inputNumber then
		return
	end
	-- The specific tool and its frame in the inventory UI
	local targetTool: Tool = nil
	local targetFrame: Frame = nil
	for i, tool: Tool in tools do
		-- Searches for ToolsFrame object value inside the tool
		local toolsFrame = tool:FindFirstChild("ToolsFrame")
		if not toolsFrame then
			continue
		end
		local frame = toolsFrame.Value
		-- Frame.Name is always the position of the tool in the inventory
		-- meaning we just have to check if the frame.Name corresponds to the number player has inputted
		-- if so, we know that this is the tool player is referring to
		if frame.Name == tostring(inputNumber) then
			targetFrame = frame
			targetTool = tool
			break
		end
	end
	-- Stop if no tool was found
	if not targetTool or not targetFrame then
		return
	end

	-- if the player has selected the same tool as currently equipped, that can only mean they wish to unequip it
	if equiped == targetTool then
		handelUnequip()
	else
		handelEqup(targetTool)
	end
end)

-- Gets the next available slot in the inventory
local function getAvalaibleSlot()
	for i = 1, 9 do
		local frame = screen:FindFirstChild(tostring(i))
		-- Once again, if .ToolName.Text or .ToolIcon.Image are empty strings, that means no tool is assigned to the frame
		-- meaning it's also empty
		if frame and frame.Core.ToolName.Text == "" and frame.Core.ToolIcon.Image == "" then
			return i
		end
	end
	return nil
end

-- Searches the lastSavedToolsPositions table to check whether there is at least one tool with a previously saved position.
local function hasAnyToolSavedPosition()
	for _, toolName in pairs(lastSavedToolsPositions) do
		if toolName then
			return true
		end
	end
	return false
end

-- Keeps track of the Unix timestamp of when said actions happened
-- 0 means the variable was not changed.

-- Both of these restart upon player respawn
local timeSiceFirstToolWasGiven = 0
local timeSincePlayerSpawn = 0

-- Keeps track of numbers that have already been assigned to a tool slot
local usedToolSpots = {}

local function addNewTool(tool: Tool)

	-- Determines whether the tool's position in the inventory should be affected by the lastSavedToolsPositions table
	local sortTool = false

	-- Check that stops the process if the tool is already in the player's inventory
	if checkToolsTableForTool(tool) then
		return
	end
	if not tool:IsA("Tool") then
		return
	end

	local currentTime = tick()

	-- Checks if this is the first tool to be added in the inventory
	if timeSiceFirstToolWasGiven == 0 then
		timeSiceFirstToolWasGiven = tick()
	end

	-- If the tool is being added to the inventory within three seconds of the first tool being added
	-- we will attempt to sort the tool by the lastSavedToolsPositions table
	-- This is here to only sort the first few tools being given to player and not to attempt to sort all the tools given to player even later on
	if currentTime - timeSiceFirstToolWasGiven < 3 then
		sortTool = true
	end

	-- A safeguard that automatically stops all attempts of tool sorting after 10 seconds of player spawning
	-- If the first tool is given after 10 seconds of player spawning, it will be treated as a new tool to just be added by normal means.
	if currentTime - timeSincePlayerSpawn > 10 then
		sortTool = false
	end

	local toolFrame = nil

	-- Checks if the script needs to sort the tool or not
	if sortTool and hasAnyToolSavedPosition() then
		-- Loops through all possible spots in the table to see if the tool matches any

		for i, toolInSpot in pairs(lastSavedToolsPositions) do
			if toolInSpot == tool.Name then
				local isSpotUsed = false


				-- Checks if the tool spot that the tool is requesting to be in is not already used
				for _, spotAlreadyUsed in pairs(usedToolSpots) do
					if tonumber(i) == spotAlreadyUsed then
						isSpotUsed = true
						break
					end
				end

				if not isSpotUsed then
					table.insert(usedToolSpots, tonumber(i))
					toolFrame = screen:FindFirstChild(tostring(i))
					break
				end
			end
		end

		-- If the first check could not find a saved spot, this will attempt to find an empty spot that is not reserved by any other tool
		if not toolFrame then
			-- 9 because we have 9 tool slots
			for i = 1, 9 do
				-- Fetches tool or nil in the lastSavedToolsPositions
				local toolInTheRspectveSavedPosition = tonumber(lastSavedToolsPositions[tostring(i)])

				--for savedSlotNumber, savedTool in pairs(lastSavedToolsPositions) do
				--	if tonumber(savedSlotNumber) == i and savedTool then
				--		isReserved = true
				--		break
				--	end
				--end

				-- If there is no saved tool in the saved position, we can safely use it without interrupting other tool additions
				if not toolInTheRspectveSavedPosition then
					if screen:FindFirstChild(tostring(i)) then
						toolFrame = screen:FindFirstChild(tostring(i))
						break
					end
				end
			end
		end
	else
		-- If no sorting is needed, we simply fetch any empty slot without considering the lastSavedToolsPositions table,
		-- since by this point, the starting tools should have already been given to the player, and we don't need to skip any slots to ensure safe additions.
		local availableSlot = getAvalaibleSlot()
		if availableSlot then
			toolFrame = screen:FindFirstChild(tostring(availableSlot))
		end
	end

	-- If there is no toolFrame to work with, we stop the process
	if not toolFrame then
		return
	end

	table.insert(tools, tool)

	-- Saves the tool position in lastSavedToolsPositions that can be used again upon respawn
	-- toolFrame.Name is a string that always corresponds to the position of the tool
	lastSavedToolsPositions[toolFrame.Name] = tool.Name

	toolFrame.Visible = true
	-- Sets TextureID for an image to display
	toolFrame.Core.ToolIcon.Image = tool.TextureId
	-- Sets the text to display the tool name only if the tool does not have an image
	toolFrame.Core.ToolName.Text = tool.TextureId == "" and tool.Name or ""

	-- Creates the object value, parents it to the tool, and its value is set to the tool frame.
	-- This is used to easily fetch the current tool frame just by having the tool
	local objectVlue = Instance.new("ObjectValue")
	objectVlue.Value = toolFrame
	objectVlue.Name = "ToolsFrame"
	objectVlue.Parent = tool

	-- ToolRef is an ObjectValue, we set it to easily fetch a tool just from a UI slot
	toolFrame.ToolRef.Value = tool

	-- Disables the manual ability to select tool if the player is currently viewing the backpack
	toolFrame.Core.TextButton.Visible = not displayingFullInventory
	-- Enables dragging the tool around when viewing the full backpack
	toolFrame.Core.UIDragDetector.Enabled = displayingFullInventory

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

	-- Detecting and handling dragging of the tool
	-- UIDragDetector is only enabled if the player is viewing the whole backpack

	toolFrame.Core.UIDragDetector.DragStart:Connect(function()
		local startTime = os.clock()
		toolFrame.Core.UIDragDetector.DragEnd:Once(function()
			local endTime = os.clock()
			-- If the time of drag is 0.11 seconds or less, we will act as if the button for equipping/unequipping was pressed
			-- since it is disabled, and it cannot be enabled, because then the UIDragDetector would not function
			if (endTime - startTime) <= 0.11 then
				buttonPressed()
			end
			local overlapingWith = nil
			-- Gets all of the frames and checks if the UI is overlapping with another UI tool
			for i, specialFrame in screen:GetChildren() do
				if not specialFrame:IsA("Frame") or specialFrame.Name == "Template" or specialFrame == toolFrame then
					continue
				end
				if overLap.isOverlapping(toolFrame.Core, specialFrame.Core) then
					overlapingWith = specialFrame
					break
				end
			end
			-- If there is any UI overlap, we will switch the two frames, resulting in swapping tool positions
			if overlapingWith then

				-- We simply swap the frame properties to "simulate" a tool swap

				local overlapName = overlapingWith.Name
				local standartFrameName = toolFrame.Name

				overlapingWith.Name = standartFrameName
				toolFrame.Name = overlapName

				overlapingWith.Core.ToolPosition.Text = standartFrameName
				toolFrame.Core.ToolPosition.Text = overlapName

				local overlapTool = overlapingWith.ToolRef.Value
				local currentTool = toolFrame.ToolRef.Value

				if overlapTool then
					lastSavedToolsPositions[overlapingWith.Name] = overlapTool.Name
				else
					lastSavedToolsPositions[overlapingWith.Name] = nil
				end

				if currentTool then
					lastSavedToolsPositions[toolFrame.Name] = currentTool.Name
				else
					lastSavedToolsPositions[toolFrame.Name] = nil
				end
			end
			toolFrame.Core.Position = UDim2.new(0,0,0,0)
		end)
	end)

	toolFrame.Core.TextButton.MouseButton1Click:Connect(buttonPressed)
end

-- A function that removes the tool from the player's inventory
local function handelToolRemoval(tool: Tool)
	-- Searches for an object value named ToolsFrame, whose Value is the inventory frame
	local toolsFrameValue = tool:FindFirstChild("ToolsFrame")
	if not toolsFrameValue then
		return
	end
	local frame = toolsFrameValue.Value
	local frameNumber = frame.Name -- Once again, frame.Name is a string position of the tool in the player's inventory
	local _, position = checkToolsTableForTool(tool)

	if equiped == tool then
		equiped = nil
	end

	if position then
		table.remove(tools, position)
	end

	lastSavedToolsPositions[frameNumber] = nil

	-- Removes the frame completely and then instantly creates a new frame at its original position
	frame:Destroy()
	creatNewInventoryFrame(frameNumber)
end

-- Backpack and character added connections. This is here to disconnect them upon player respawn to save memory

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
	for i, thing in screen:GetChildren() do
		if not thing:IsA("Frame") or thing.Name == "Template" then
			continue
		end
		thing:Destroy()
	end
	table.clear(tools)
	equiped = nil
	timeSiceFirstToolWasGiven = false
	timeSincePlayerSpawn = tick()
	usedToolSpots = {}
	for i = 1, 9 do
		creatNewInventoryFrame(i)
	end
	for i, item in player.Backpack:GetChildren() do
		addNewTool(item)
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

-- Connecting character if the player has already loaded, if not, the player.CharacterAdded will do so once fully loaded
if player.Character then
	connectCharacter(player.Character)
end
