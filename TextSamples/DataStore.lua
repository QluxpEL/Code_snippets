-- Semi-Advanced DataStore System
-- Creates a folder hierarchy under each player instance for organized data management.

local dataStoreService = game:GetService("DataStoreService")
local playerStore = dataStoreService:GetDataStore("PlayerStore")

-- A "DataStore" folder is created inside each player instance with subfolders based on the structure below.
-- Data can be modified by any server script using: player.DataStore.[Group].[Data].Value = newValue
-- Example: player.DataStore.Global.Coins.Value += 10 will add 10 coins to the player's data.
--
-- Client scripts can read player data and listen for changes via .Changed events
-- Client scripts cannot directly modify the server's authoritative data state
-- New data fields are added automatically by updating the structure table
-- The system compares saved player data with the default structure on load
-- Missing fields are created with defaults; obsolete fields are ignored
--
-- Name = the identifier for this specific data field
-- Default = the initial value assigned when data is created for the first time
-- Type = the Roblox instance class to use (NumberValue, StringValue, BoolValue, etc.)

local structure = {
	Global = {
		{Name = "Coins", Default = 100, Type = "NumberValue"},
		{Name = "GlobalXP", Default = 0, Type = "NumberValue"}
	},
	Sigma = {
		{Name = "Arrest", Default = 0, Type = "NumberValue"}
	},
}

game.Players.PlayerAdded:Connect(function(player)
	-- Attempt to load existing player data from the DataStore
	local success, playerData = pcall(function()
		return playerStore:GetAsync(tostring(player.UserId))
	end)
	
	if not success then
		warn("Error while fetching playerData for " .. player.Name)
		return
	end
	-- We first check if the data loads correctly and only then creat the DataStore folder, by this, we are preventing errors when the player leaves.
		
	-- Create the main DataStore folder container
	local dataStoreFolder = Instance.new("Folder")
	dataStoreFolder.Name = "DataStore"
	dataStoreFolder.Parent = player
	
	-- Create category folders and their data instances based on the structure
	for dataName, dataTable in structure do
		-- Create a category folder (e.g., "Global", "Sigma")
		local dataFolder = Instance.new("Folder")
		dataFolder.Name = tostring(dataName)
		dataFolder.Parent = dataStoreFolder
		
		-- Create individual data instances within this category
		for _, dataInfo in dataTable do
			-- Create the value instance
			local specificValue: Instance = Instance.new(tostring(dataInfo.Type))
			specificValue.Parent = dataFolder
			specificValue.Name = dataInfo.Name
			
			-- Start with the default value from the structure
			local valueToAssign = dataInfo.Default
			
			-- Check if saved player data exists for this field and use it instead
			if playerData and playerData[tostring(dataName)] and playerData[tostring(dataName)][tostring(dataInfo.Name)] then 
				valueToAssign = playerData[tostring(dataName)][tostring(dataInfo.Name)]
			end
			
			specificValue.Value = valueToAssign
		end
	end
end)

game.Players.PlayerRemoving:Connect(function(player)
	local dataStoreFolder = player:FindFirstChild("DataStore")
	if not dataStoreFolder then
		return
	end
	
	-- Convert the instances from the DataStore folder back into a table structure for saving
	local dataToSave = {}
	
	for i, dataFolder: Folder in dataStoreFolder:GetChildren() do
		dataToSave[dataFolder.Name] = {}
		
		-- Extract each data field's current value
		for _, specificData in dataFolder:GetChildren() do
			dataToSave[dataFolder.Name][specificData.Name] = dataStoreFolder:FindFirstChild(dataFolder.Name):FindFirstChild(specificData.Name).Value
		end
	end

	local success, err = pcall(function()
		playerStore:SetAsync(tostring(player.UserId), dataToSave)
	end)
	
	if not success then
		warn("Error while saving data for " .. player.Name .. ": " .. tostring(err))
	end
end)
