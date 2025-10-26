-- Client-Side Force Field System
-- Allows the local player to pass through force fields only if they meet permission requirements.
-- All code runs on the client since only visual changes and local collision states are modified.
-- The system finds all instances tagged with "CombineForceField" and configures them as team-based barriers.

-- Prevents players from certain teams from passing through
-- Can be disabled or toggled via attributes to allow all players through
-- Visual effects (beams, lights, sounds) respond to enabled/disabled states
-- Collision detection is handled per-player based on team and force field settings
-- Forcefields can eb easly modifed, where server can just change the properties of the forcefield and all player would react to it.
-- There is no point of having server to approve if player can pass throught forcefield, since the exploiter can just manualy disable the parts collisions.

local collectionService = game:GetService("CollectionService")
local player = game.Players.LocalPlayer

local function setUpForceField(forceField: Model)

	-- Attributes store the configuration for each force field
	-- We fetch attributes dynamically each time to ensure we have the latest values
	-- (Using :GetAttributes() once would cache stale data that may not represent latest values and the table would have to be updated upon each change.)
	local function getSettings()
		return forceField:GetAttributes()
	end
	
	local collisionPart = forceField:FindFirstChild("Collide")
	local startTime = os.time()

	-- Verify the collision part exists before proceeding
	if not collisionPart then
		warn("--------")
		warn("Infinite loading for ForceField!")
		forceField.Name = "ForceFieldProblem"
		warn(forceField:GetFullName())
		warn("-------")
		return
	end

	-- Skip setup if this force field is for display purposes only (e.g., background decoration)
	if getSettings().DisplayOnly then
		return
	end

	-- Updates the visual effects (beams, lights, sounds, transparency) of the force field
	local function beamEdit(value)
		
		-- Enable or disable all beam and light effects within the force field
		for i, stuff: Beam in forceField:GetDescendants() do
			if stuff:IsA("Beam") then
				stuff.Enabled = value
			end
			if stuff:IsA("Light") then
				stuff.Enabled = value
			end
		end
		
		if not collisionPart then
			forceField.Name = "NoCollisionPart!"
			warn(forceField:GetFullName(), "is missing collision part!")
			return
		end

		-- Enable or disable the force field based on the value parameter
		if value then
			collisionPart:FindFirstChild("Activate"):Play()
			collisionPart:FindFirstChild("Buzz"):Play()
			collisionPart.Transparency = 0.3
			collisionPart.CanQuery = true
		else
			collisionPart.Transparency = 1
			collisionPart.CanQuery = false
			collisionPart:FindFirstChild("Deactivate"):Play()
			collisionPart:FindFirstChild("Buzz"):Stop()
		end
	end

	-- Automatically adjusts collision behavior based on the local player's team and force field settings
	local function collisionEdit()
		if not collisionPart then
			warn(forceField:GetFullName(), "is missing collision part!")
			return
		end

		-- Allow Combine team members through if the force field is Combine-only
		if getSettings().CombineOnly and player.Team == game.Teams.Combine then
			collisionPart.CanCollide = false
			return -- Exit early to prevent further collision changes
		end

		-- Allow all players through if the force field is not team-restricted
		if not getSettings().CombineOnly then
			collisionPart.CanCollide = false
			return -- Exit early to prevent further collision changes
		end
		
		-- Allow all players through if the force field is disabled
		if not getSettings().Enabled then
			collisionPart.CanCollide = false
			return -- Exit early to prevent further collision changes
		end

		-- Block the player if none of the above conditions are met
		collisionPart.CanCollide = true
		
	end

	-- Initialize visual effects based on whether the force field is enabled
	beamEdit(getSettings().Enabled)

	-- Update collision state when the player changes teams
	player.Changed:Connect(function(property)
		if property ~= "Team" then
			return
		end
		collisionEdit()
	end)

	-- Update collision and visual effects when the "Enabled" attribute changes
	forceField:GetAttributeChangedSignal("Enabled"):Connect(function()
		collisionEdit()
		beamEdit(getSettings().Enabled)
	end)
	
	-- Update collision state when the "CombineOnly" attribute changes
	forceField:GetAttributeChangedSignal("CombineOnly"):Connect(function()
		collisionEdit()
	end)
	
	-- Perform collision setup
	collisionEdit()
end

-- Automatically set up all force fields that have the "CombineForceField" tag
for i, stuff in collectionService:GetTagged("CombineForceField") do
	setUpForceField(stuff)
end
