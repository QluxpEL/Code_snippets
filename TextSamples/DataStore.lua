[1] Semi-Advanced DataStore system, Server Script – New Section
-- DataStore system that creates a folder under the player instance, providing easy data management and change. Additionally,
-- new data froms can be added easily in the structure table.

local dataStoreService = game:GetService("DataStoreService")
local playerStore = dataStoreService:GetDataStore("PlayerStore")

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
	local dataStoreFolder = Instance.new("Folder")
	dataStoreFolder.Name = "DataStore"
	dataStoreFolder.Parent = player
	
	
	local success, playerData = pcall(function()
		return playerStore:GetAsync(tostring(player.UserId))
	end)
	
	if not success then
		warn("Error while fetching playerData")
		return
	end
	
	for dataName, dataTable in structure do
		local dataFolder = Instance.new("Folder")
		dataFolder.Name = tostring(dataName)
		dataFolder.Parent = dataStoreFolder
		
		for dataTitle, dataInfo in dataTable do
			local specificValue: Instance = Instance.new(tostring(dataInfo.Type))
			specificValue.Parent = dataFolder
			specificValue.Name = dataInfo.Name
			
			local theValue =  dataInfo.Default
			if playerData and playerData[tostring(dataName)] and playerData[tostring(dataName)][tostring(dataInfo.Name)] then 
				theValue = playerData[tostring(dataName)][tostring(dataInfo.Name)]
			end
			
			specificValue.Value = theValue
		end
	end
end)

game.Players.PlayerRemoving:Connect(function(player)
	local dataStoreFolder = player:FindFirstChild("DataStore")
	if not dataStoreFolder then
		return
	end
	
	local dataToSave = {}
	for i, dataFolder: Folder in dataStoreFolder:GetChildren() do
		dataToSave[dataFolder.Name] = {}
		for _, specificData in dataFolder:GetChildren() do
			dataToSave[dataFolder.Name][specificData.Name] = dataStoreFolder:FindFirstChild(dataFolder.Name):FindFirstChild(specificData.Name).Value
		end
	end
	
	local succes, err = pcall(function()
		playerStore:SetAsync(tostring(player.UserId),dataToSave)
	end)
	
	if not succes then
		warn("Error while saving data:", err)
	end

end)
