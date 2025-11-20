-- One of the latest and hardest scripts to accomplish, done by me, a custom inventory system.
-- Some code may have been inspired by public sources such as Roblox dev forums while I was doing research on how to perform such a system.

-- Semi advance inventory system handling basic interactions like equipping/unequipping tools and swapping them.
-- Additionally, this system saves the last known position in the inventory, meaning, player can move their starting tools like they wish, and after respawn,
-- they will be at the same position, saving time and giving player comfort.
-- The inventory of the player can be easily disabled by just setting the Enabled property of the UI to false.

local config = {
	inventorySlots = 9,
	tweenTime = 0.15,
	equippedSizeMultiplier = 1.125,
	toolSortingTimeout = 8, -- seconds after spawn to stop sorting tools
	clickDragThreshold = 0.11, -- seconds to distinguish click from drag
	equipColor = Color3.new(0.396078, 0.486275, 1),
	unequipColor = Color3.new(1, 1, 1),
}

local starterUI = game:GetService("StarterGui")
local mouse = game.Players.LocalPlayer:GetMouse()
local tweenService = game:GetService("TweenService")
-- An overlap module script that checks if two frames overlap each other. Returns true or false.
local overLap = require(game.ReplicatedStorage.MainStorage.Modules.PlayerRelated.UIOverlap)

starterUI:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

-- Persistent storage that remembers where each tool was placed in the inventory (by tool name)
-- This allows the inventory to restore tool positions when the player respawns
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

local backPack = player.Backpack

-- A template UI for the tool display
local template = screen.Template

-- Tracks all tools in player's inventory
-- The order of the tools may not equal to the position within the inventory
local tools = {}

-- Value that stores the currently equipped tool
local equipped = nil

-- Maps KeyCode names to their numeric equivalents for keyboard shortcuts (1-9 keys)
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

local defaultSize = screen.Template.Size

local equippedSize = defaultSize + UDim2.new(
	defaultSize.X.Scale * (config.equippedSizeMultiplier - 1), 
	0, 
	defaultSize.Y.Scale * (config.equippedSizeMultiplier - 1), 
	0
)

-- Keeps track of the Unix timestamp of when said actions happened
-- 0 means the variable was not changed.

-- Both of these restart upon player respawn
local timeSincePlayerSpawn = 0

-- Tracks which inventory slots (1-9) are already occupied during the sorting phase
-- This prevents multiple tools from trying to claim the same slot when restoring positions
local usedToolSpots = {}

-- Store event connections in variables so they can be properly disconnected on respawn
-- This prevents memory leaks from accumulating duplicate events

local backpackChildRemovedConnection
local characterChildRemovedConnection

local function createNewInventoryFrame(toolPosition)
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

-- Searches the tools table for specified tool
local function checkToolsTableForTool(tool, toolPosition)
	if not tool then
		return false, nil
	end

	local foundTool, toolPositionInTable = false, nil
	for i, toolFromTable in tools do
		if toolFromTable == tool then
			foundTool = true
			toolPositionInTable = i
			break
		end
	end

	return foundTool, toolPositionInTable
end

-- Gets the next available slot in the inventory
local function getAvailableSlot()
	for i = 1, config.inventorySlots do
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


local function handleUnequip()
	-- Safe check to make sure there is a tool to be unequipped
	if not equipped then
		return
	end
	local humanoid: Humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end
	-- Each tool has an ObjectValue called "ToolsFrame" that references its UI frame
	-- This allows lookups: tool -> frame and frame -> tool
	local toolFrame = equipped:FindFirstChild("ToolsFrame")
	if not toolFrame then
		return
	end
	if not ui.Enabled then
		return
	end
	toolFrame = toolFrame.Value
	toolFrame.Core.UIStroke.Color = config.unequipColor
	tweenService:Create(toolFrame.Core.Bar, TweenInfo.new(config.tweenTime, Enum.EasingStyle.Linear), {Transparency = 1}):Play()
	tweenService:Create(toolFrame, TweenInfo.new(config.tweenTime, Enum.EasingStyle.Linear), {Size = defaultSize}):Play()
	equipped = nil
	humanoid:UnequipTools()
end

local function handleEquip(tool)
	local humanoid: Humanoid = player.Character:FindFirstChild("Humanoid")
	-- Check that makes sure only alive players can equip tools
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	if not tool then
		return
	end
	if equipped == tool then
		return
	end
	if equipped then
		handleUnequip()
	end
	if not ui.Enabled then
		return
	end
	-- Searches for an object value named ToolsFrame inside the equipped tool
	local toolFrame = tool:FindFirstChild("ToolsFrame")
	if not toolFrame then
		return
	end
	toolFrame = toolFrame.Value
	toolFrame.Core.UIStroke.Color = config.equipColor
	tweenService:Create(toolFrame.Core.Bar, TweenInfo.new(config.tweenTime, Enum.EasingStyle.Linear), {Transparency = 0}):Play()
	tweenService:Create(toolFrame, TweenInfo.new(config.tweenTime, Enum.EasingStyle.Linear), {Size = equippedSize}):Play()
	equipped = tool
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

			-- If ToolName or ToolIcon.Image is an empty string, the slot is not assigned to any tool.
			-- In that case, we only need to show or hide the slot.
			if frame.Core.ToolName.Text == "" and frame.Core.ToolIcon.Image == "" then
				frame.Visible = displayingFullInventory
				continue
			end

			-- We don't modify frames that already contain a tool,
			-- because all tools in the inventory are displayed by default,
			-- and we don't want to hide them when closing the backpack, since that would prevent players from seeing their tools

			-- We enable/disable the button that handles manual tool equipping
			-- to allow or restrict the drag detector from moving the tool.
			frame.Core.TextButton.Visible = not displayingFullInventory
		end

		-- Stopping the code progression, since we know a key was pressed to toggle the inventory, not to equip or unequip any tool
		return
	end

	-- Converts input key to a number
	local inputNumber = stringToNumber[input.KeyCode.Name]

	-- Handles equipping or unequipping the tool by keyboard input

	-- Do not process if the keyCode is not a valid number
	if not inputNumber then
		return
	end
	-- The specific tool and its frame in the inventory UI players is wishing to use
	local targetTool: Tool = nil
	local targetFrame: Frame = nil
	for i, tool: Tool in tools do
		-- Searches for an object value named ToolsFrame inside the equipped tool
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
	if equipped == targetTool then
		handleUnequip()
	else
		handleEquip(targetTool)
	end
end)


-- When a player respawns, their starting tools are given rapidly within a few seconds
-- We use timestamps to identify this "initial batch" of tools and apply saved positions only to them
-- This prevents tools picked up later in gameplay from jumping to saved positions

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

	-- A safeguard that automatically stops all attempts of tool sorting after configured seconds of player spawning
	-- If the first tool is given after the timeout, it will be treated as a new tool to just be added by normal means.
	-- This permits player to sort their starting items however they wish, and on their next respawn, when the first tools are being given,
	-- the script will move the tools on players behalf to save their time and comfort.
	if currentTime - timeSincePlayerSpawn > config.toolSortingTimeout then
		sortTool = false
	end

	local toolFrame = nil

	-- Checks if the script needs to sort the tool or not
	if sortTool and hasAnyToolSavedPosition() then
		-- Two-pass slot assignment for sorted tools:
		-- Pass 1: Try to find the tool's saved position if available and not already used
		-- This is useful if the player has two kinds of a same item, but differently arranged. This makes sure that if e.g. player has two SMGs, it won't attempt to put two SMGs into one slot
		for slot, toolInSpot in lastSavedToolsPositions do
			if toolInSpot == tool.Name then
				-- Uses usedToolSpots to attempt find the slot number, if it finds the slot number, it means the slot is already used
				local isSpotUsed = table.find(usedToolSpots, tonumber(slot))

				if not isSpotUsed then
					table.insert(usedToolSpots, tonumber(slot))
					toolFrame = screen:FindFirstChild(tostring(slot))
					break
				end
			end

		end

		-- If the tool had no saved position or its saved spot was taken,
		-- find any empty slot that isn't reserved by another tool in the saved positions table
		if not toolFrame then
			-- Loop through all inventory slots
			for slot = 1, config.inventorySlots do
				-- Checks to see if there are any tools that reserved this position
				local toolInTheRespectiveSavedPosition = tonumber(lastSavedToolsPositions[tostring(slot)])

				-- If there is no saved tool in the saved position, we can safely use it without interrupting other tool additions
				if not toolInTheRespectiveSavedPosition then
					if screen:FindFirstChild(tostring(slot)) then
						toolFrame = screen:FindFirstChild(tostring(slot))
						break
					end
				end

			end
		end
	else
		-- If no sorting is needed, we simply fetch any empty slot without considering the lastSavedToolsPositions table,
		-- since by this point, the starting tools should have already been given to the player, and we don't need to skip any slots to ensure safe additions.
		local availableSlot = getAvailableSlot()
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

	-- Bidirectional linking system:
	-- Creates the object value, parents it to the tool, and its value is set to the tool frame.
	-- This is used to easily fetch the current tool frame just by having the tool
	local objectValue = Instance.new("ObjectValue")
	objectValue.Value = toolFrame
	objectValue.Name = "ToolsFrame"
	objectValue.Parent = tool

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
		if equipped == tool then
			handleUnequip()
		else
			handleEquip(tool)
		end
	end

	-- Drag-and-drop implementation with click detection:
	-- UIDragDetector is only enabled if the player is viewing the whole backpack
	-- Uses timing to differentiate between clicks and actual drags

	toolFrame.Core.UIDragDetector.DragStart:Connect(function()
		local startTime = os.clock()
		toolFrame.Core.UIDragDetector.DragEnd:Once(function()
			local endTime = os.clock()
			-- If the time of drag is less than threshold, we will act as if the button for equipping/unequipping was pressed
			-- since it is disabled, and it cannot be enabled, because then the UIDragDetector would not function
			if (endTime - startTime) <= config.clickDragThreshold then
				buttonPressed()
			end
			local overlappingWith = nil
			-- Gets all of the frames and checks if the UI is overlapping with another UI tool
			for i, specialFrame in screen:GetChildren() do
				if not specialFrame:IsA("Frame") or specialFrame.Name == "Template" or specialFrame == toolFrame then
					continue
				end
				
				if overLap.isOverlapping(toolFrame.Core, specialFrame.Core) then
					overlappingWith = specialFrame
					break
				end
			end

			-- If dragged tool overlaps another slot, swap their properties (names, references, etc.)
			-- instead of moving them. This is more efficient and maintains event connections
			-- It's worth mentioning there is a UIList layout that will swap the positions by the name of the slot.
			if overlappingWith then

				-- We simply swap the frame properties to "simulate" a tool swap

				local overlapName = overlappingWith.Name
				local standardFrameName = toolFrame.Name

				overlappingWith.Name = standardFrameName
				toolFrame.Name = overlapName

				overlappingWith.Core.ToolPosition.Text = standardFrameName
				toolFrame.Core.ToolPosition.Text = overlapName

				local overlapTool = overlappingWith.ToolRef.Value
				local currentTool = toolFrame.ToolRef.Value

				-- Update saved positions for both swapped tools
				if overlapTool then
					lastSavedToolsPositions[overlappingWith.Name] = overlapTool.Name
				else
					lastSavedToolsPositions[overlappingWith.Name] = nil
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
local function handleToolRemoval(tool: Tool)
	-- Searches for an object value named ToolsFrame, whose Value is the inventory frame
	local toolsFrameValue = tool:FindFirstChild("ToolsFrame")
	if not toolsFrameValue then
		return
	end
	local frame = toolsFrameValue.Value
	local frameNumber = frame.Name -- Once again, frame.Name is a string number that represents the position of the tool in the player's inventory
	local _, position = checkToolsTableForTool(tool)

	if equipped == tool then
		equipped = nil
	end

	if position then
		table.remove(tools, position)
	end

	lastSavedToolsPositions[frameNumber] = nil

	-- Removes the frame completely and then instantly creates a new frame at its original position
	frame:Destroy()
	createNewInventoryFrame(frameNumber)
end


local function connectBackpack(backpack)
	if backpackChildRemovedConnection then
		backpackChildRemovedConnection:Disconnect()
	end

	backpackChildRemovedConnection = backpack.ChildRemoved:Connect(function(tool)
		if tool.Parent ~= player.Character then
			handleToolRemoval(tool)
			return
		end
		handleEquip(tool)
	end)
	
	-- We can not have just one connection for backpack at the start, since I have found out that the removed and added back after every characterAdded event.
end

local function connectCharacter(character)
	-- Full inventory reset on character spawn
	for i, thing in screen:GetChildren() do
		if not thing:IsA("Frame") or thing.Name == "Template" then
			continue
		end
		thing:Destroy()
	end
	table.clear(tools)
	equipped = nil
	timeSincePlayerSpawn = tick()
	usedToolSpots = {}
	for i = 1, config.inventorySlots do
		createNewInventoryFrame(i)
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
			handleToolRemoval(tool)
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
