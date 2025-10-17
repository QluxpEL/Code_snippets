
[3] Simple shop with server authority, Local + Server Script – New Section
-- A simple shop for player to purchase items or anything else, E.g., Developers can script to trigger an event. Additionally,
-- developer can script any beforePurchase check, making sure player can purchase a specific item under a specific condition other than having Money for it.

Local Script: 
local template = script.Template
local mainFrame = script.Parent
local scrolingFrame = mainFrame.ScrollingFrame
local player = game.Players.LocalPlayer

local purchaseEvent = game.ReplicatedStorage.purchaseRequest
local messageDisplay = script.Message

workspace.ShopPart.ShopPrompt.Triggered:Connect(function()
	mainFrame.Parent.Enabled = true
end)

mainFrame.Close.MouseButton1Click:Connect(function()
	mainFrame.Parent.Enabled = false
end)

local function newMessage(text, lenght)
	if not lenght or lenght < 3 then lenght = 3 end
	
	local clonedMessageDisplay = messageDisplay:Clone()
	clonedMessageDisplay.Text = text
	clonedMessageDisplay.Parent = mainFrame
	clonedMessageDisplay.Visible = true
	game.Debris:AddItem(clonedMessageDisplay, lenght)
end

for i, item in script.Items:GetChildren() do
	local moduleScript = require(item)
	local newFrame = template:Clone()
	newFrame.PurchaseButton.Text = "Purchase for "..moduleScript.Price
	newFrame.Name = moduleScript.Name
	newFrame.Title.Text = moduleScript.Name
	
	newFrame.PurchaseButton.MouseButton1Click:Connect(function()
		local success, message = moduleScript.beforePurchase()
		if not moduleScript.beforePurchase() then
			newMessage(message)
			return
		end	
		
		local status, serverMessage = purchaseEvent:InvokeServer(item.Name)
		newMessage(serverMessage)
	end)
	
	newFrame.Parent = scrolingFrame
end

ServerScript:

game.ReplicatedStorage.purchaseRequest.OnServerInvoke = function(player, itemName)
	if not itemName or typeof(itemName) ~= "string" then
		return false, "itemName is not a string or is nil."
	end
	
	local items = game.StarterGui.ShopUI.MainFrame.CoreHandler.Items
	local itemModule = items:FindFirstChild(itemName)
	
	if not itemModule then
		return false, "Item not found"
	end
	
	itemModule = require(itemModule)
	
	local status, message = itemModule.beforePurchase(player)
	
	if not status then
		return false, "Server declines purchase | "..message
	end
	
	local purchaseStatus, purchaseMessage = itemModule.processPurchase(player)
	return purchaseStatus, purchaseMessage
end
