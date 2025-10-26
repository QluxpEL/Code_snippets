-- Simple Shop System with Client and Server Validation
-- Allows players to purchase items, trigger events, or execute custom scripted actions.
-- Includes a beforePurchase check system for custom conditions beyond currency requirements.
-- See WorkExamples.rbxl for multiple example item configurations.


-- Client and server validation ensures purchase eligibility
-- Shop items don't have to be physical tools, they can trigger events or any scripted behavior
-- New items are easily added by duplicating a module script and modifying its behavior/rewards
-- Each item module contains settings (price, name) and functions (beforePurchase, processPurchase)

-- LOCAL SCRIPT:

-- References to UI elements and services
local template = script.Template -- Template UI frame used as the base for each shop item
local mainFrame = script.Parent
local scrollingFrame = mainFrame.ScrollingFrame
local player = game.Players.LocalPlayer
local purchaseEvent = game.ReplicatedStorage.purchaseRequest
local messageDisplay = script.Message -- TextLabel template for displaying messages to the player

workspace.ShopPart.ShopPrompt.Triggered:Connect(function()
	mainFrame.Parent.Enabled = true
end)

mainFrame.Close.MouseButton1Click:Connect(function()
	mainFrame.Parent.Enabled = false
end)

-- Creates and displays a temporary message to the player
local function newMessage(text, length)
	-- Length determines how long the message remains visible (minimum 3 seconds)
	if not length or length < 3 then length = 3 end
	
	local clonedMessageDisplay = messageDisplay:Clone()
	clonedMessageDisplay.Text = text
	clonedMessageDisplay.Parent = mainFrame
	clonedMessageDisplay.Visible = true
	game.Debris:AddItem(clonedMessageDisplay, length)
end

-- Generates shop items from module scripts in Script.Items
-- Each module contains item settings (price, name) and purchase logic
for i, item in script.Items:GetChildren() do
	local moduleScript = require(item)
	local newFrame = template:Clone()
	newFrame.PurchaseButton.Text = "Purchase for " .. moduleScript.Price
	newFrame.Name = moduleScript.Name
	newFrame.Title.Text = moduleScript.Name
	
	newFrame.PurchaseButton.MouseButton1Click:Connect(function()
		-- Run client-side validation to check if the player can purchase the item
		local success, message = moduleScript.beforePurchase()
		if not success then
			newMessage(message)
			return
		end
		
		-- If client validation passes, send the request to the server for final validation
		local status, serverMessage = purchaseEvent:InvokeServer(item.Name)
		newMessage(serverMessage)
	end)
	
	newFrame.Parent = scrollingFrame
end

-- SERVER SCRIPT:

game.ReplicatedStorage.purchaseRequest.OnServerInvoke = function(player, itemName)
	-- Validate that itemName is a string, preventing Exploiter abuse
	if not itemName or typeof(itemName) ~= "string" then
		return false, "itemName is not a string or is nil."
	end
	
	local items = game.StarterGui.ShopUI.MainFrame.CoreHandler.Items
	local itemModule = items:FindFirstChild(itemName)
	
	-- Verify the requested item exists in the shop
	if not itemModule then
		return false, "Item not found"
	end
	
	itemModule = require(itemModule)
	
	-- Run server-side validation to ensure the player meets all purchase requirements
	local status, message = itemModule.beforePurchase(player)
	
	if not status then
		return false, "Server declines purchase | " .. message
	end
	
	-- Process the purchase: grant rewards, deduct currency, or execute custom behavior
	-- The processPurchase function is defined in each item's module script
	local purchaseStatus, purchaseMessage = itemModule.processPurchase(player)
	return purchaseStatus, purchaseMessage
end
