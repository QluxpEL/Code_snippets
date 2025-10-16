[2] ForceField system, LocalScript – New Section
-- This system lets local player pass through only if they are permitted to do so.

local collectioNService = game:GetService("CollectionService")
local player = game.Players.LocalPlayer

local function setUpForceField(forceField: Model)
	
	local function getSettings()
		return forceField:GetAttributes()
	end
	
	
	local collisionpart = forceField:FindFirstChild("Collide")
	local startTime = os.time()
	local broke = false
	while not collisionpart do
		wait()
		if (os.time()-startTime) > 10 then
			warn("--------")
			warn("Infinite loading for ForceField!")
			forceField.Name = "ForceFieldProblem"
			warn(forceField:GetFullName())
			warn("-------")
			broke = true
			break
		end
	end
	
	if broke then
		return
	end
	
	if getSettings().DisplayOnly then
		return
	end
	
	local function beamEdit(value)	
		for i, stuff: Beam in forceField:GetDescendants() do
			if stuff:IsA("Beam") then
				stuff.Enabled = value
			end
			if stuff:IsA("Light") then
				stuff.Enabled = value
			end
		end
		if not collisionpart then
			forceField.Name = "NoCollisionPart!"
			warn(forceField:GetFullName(), "is missing collision part!")
			return
		end
		if value then
			collisionpart:FindFirstChild("Activate"):Play()
			collisionpart:FindFirstChild("Buzz"):Play()
			collisionpart.Transparency = 0.3
			collisionpart.CanQuery = true
		else
			collisionpart.Transparency = 1
			collisionpart.CanQuery = false
			collisionpart:FindFirstChild("Deactivate"):Play()
			collisionpart:FindFirstChild("Buzz"):Stop()
		end
	end
	
	local function collisionEdit()
		if not collisionpart then
			warn(forceField:GetFullName(), "is missing collision part!")
			return
		end
		
		if getSettings().CombineOnly and player.Team == game.Teams.Combine then
			collisionpart.CanCollide = false
			return
		end
		
		if not getSettings().CombineOnly then
			collisionpart.CanCollide = false
			return
		end
		
		if not getSettings().Enabled then
			collisionpart.CanCollide = false
			return
		end
		
		collisionpart.CanCollide = true
		
	end

	beamEdit(getSettings().Enabled)
	
	player.Changed:Connect(function(property)
		if property ~= "Team" then
			return
		end
		collisionEdit()
	end)
	
	forceField:GetAttributeChangedSignal("Enabled"):Connect(function()
		collisionEdit()
		beamEdit(getSettings().Enabled)
	end)
	
	forceField:GetAttributeChangedSignal("CombineOnly"):Connect(function()
		collisionEdit()
	end)
	
	collisionEdit()
end

for i, stuff in collectioNService:GetTagged("CombineForceField") do
	setUpForceField(stuff)
end
