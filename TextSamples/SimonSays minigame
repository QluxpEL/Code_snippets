[4] Simon-Says hacking minigame, LocaLScript – New Section
-- A core script that handles the core mechanics of the SimonSays minigame.
-- It shows the player the right pattern and then waits 3 seconds. If the player does not press anything, the cycle repeats.
-- if the player presses any button within that timeframe, the timer restarts.

local player = game.Players.LocalPlayer
local buttons = script.Parent.Buttons
local tweenService = game:GetService("TweenService")
local conterProvider = game:GetService("ContentProvider")

local assetIds = {
	"rbxassetid://18786398285",
	"rbxassetid://18786397338",
	"rbxassetid://18786396063",
	"rbxassetid://18786394878",
	"rbxassetid://18786393713",
	"rbxassetid://18786392370",
	"rbxassetid://18786391255",
	"rbxassetid://18786389883",
	"rbxassetid://18786387906",
	"rbxassetid://18786386307",
	"rbxassetid://18786385075",
	"rbxassetid://18786384027",
	"rbxassetid://18786382644",
	"rbxassetid://18786381566",
	"rbxassetid://18786380543",
	"rbxassetid://18786379367",
	"rbxassetid://18786377979",
	"rbxassetid://18786376180",
	"rbxassetid://18786374738",
	"rbxassetid://18786373702",
	"rbxassetid://18786372348",
	"rbxassetid://18786368967",
	"rbxassetid://18786367695",
	"rbxassetid://18786366330",
	"rbxassetid://18786365071",
	"rbxassetid://18786362307",
	"rbxassetid://18786361169",
	"rbxassetid://18786360128",
	"rbxassetid://18786357691",
	"rbxassetid://18786356411",
}

local userFailButton = Color3.fromHex("#ff3a3d")
local showButton = Color3.new(0.988235, 1, 0.403922)
local userSelect = Color3.new(0, 1, 0.282353)

local defaultSize = buttons:FindFirstChild("1").Size
local targetSize = UDim2.new(defaultSize.X.Scale*1.2, 0, defaultSize.Y.Scale *1.2, 0)

local playerSlecting = 0
local target = nil
local playerSelection = {}
local reseved = {}
local currentFormat = {}
local activeTweens = {}
local stages = 1

local tweenTimeIn = 0.2
local tweenIn = TweenInfo.new(tweenTimeIn, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, true)

local function getRandomID()
	local randomID = assetIds[math.random(1, #assetIds)]
	if table.find(reseved, randomID) then
		return getRandomID()
	end
	table.insert(reseved, randomID)
	return randomID
end

for i, button: TextButton in buttons:GetChildren() do
	if not button:IsA("TextButton") then
		continue
	end
	button:FindFirstChildWhichIsA("ImageLabel").Image = getRandomID()
end

local progress = script.progress
local currentStage = 1

local function doThing()
	currentFormat = {}
	playerSelection = {}

	for i, button: TextButton in buttons:GetChildren() do
		if not button:IsA("TextButton") then
			continue
		end
		button:FindFirstChildWhichIsA("ImageLabel").Image = getRandomID()
	end

	reseved = {}
	
	for i = 1, 6 do
		table.insert(currentFormat, math.random(1,4))
	end
	

	task.spawn(function()
		local localStage = currentStage

		while script.Parent.Parent and script.Parent.Parent.Enabled and currentStage == localStage do
			if #playerSelection >= #currentFormat then
				progress:Fire()
				break
			end
			wait()
			if (os.time()-playerSlecting) <= 3 then
				continue
			end

			for i, number in currentFormat do
				if (os.time()-playerSlecting) <= 3 then
					break
				end

				playerSelection = {}

				local button: TextButton = buttons:FindFirstChild(tostring(number))
				button.Size = defaultSize
				button.BackgroundColor3 = Color3.fromHex("#77adff")
				button:FindFirstChildWhichIsA("Sound"):Play()
				local tween = tweenService:Create(button, tweenIn, {Size = targetSize, BackgroundColor3 = showButton})
				table.insert(activeTweens, tween)
				tween:Play()
				task.wait( (tweenTimeIn*2)+0.05 )
			end
			wait(3)
		end
	end)
end

local defaulButtonPos = script.Parent.Buttons.Position

local function tweenCoreUI(tweenOut)
	for i, thing: Instance in script.Parent:GetDescendants() do
		local savedProprties = {}
		local canTween = false

		if thing:IsA("Frame") then
			savedProprties.BackgroundTransparency = thing.BackgroundTransparency
			if not tweenOut then
				thing.BackgroundTransparency = 1
			else
				local tween = tweenService:Create(thing, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
					BackgroundTransparency = 1,
				})
				tween:Play()
			end
			canTween = true
		elseif thing:IsA("TextButton") then
			savedProprties.BackgroundTransparency = thing.BackgroundTransparency
			savedProprties.TextTransparency = thing.TextTransparency
			if not tweenOut then
				thing.TextTransparency = 1
				thing.BackgroundTransparency = 1
			else
				local tween = tweenService:Create(thing, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
					BackgroundTransparency = 1,
					TextTransparency = 1,
				})
				tween:Play()
			end
			canTween = true
		elseif thing:IsA("ImageLabel") then
			savedProprties.BackgroundTransparency = thing.BackgroundTransparency
			savedProprties.ImageTransparency = thing.ImageTransparency
			if not tweenOut then
				thing.ImageTransparency = 1
				thing.BackgroundTransparency = 1
			else
				local tween = tweenService:Create(thing, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
					BackgroundTransparency = 1,
					ImageTransparency = 1,
				})
				tween:Play()
			end
			canTween = true
		elseif thing:IsA("UIStroke") then
			savedProprties.Thickness = thing.Thickness
			if not tweenOut then
				thing.Thickness = 0
			else
				local tween = tweenService:Create(thing, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
					Thickness = 0,
				})
				tween:Play()
			end
			canTween = true
		elseif thing:IsA("TextLabel") then
			savedProprties.BackgroundTransparency = thing.BackgroundTransparency
			savedProprties.TextTransparency = thing.TextTransparency
			if not tweenOut then
				thing.BackgroundTransparency = 1
				thing.TextTransparency = 1
			else
				local tween = tweenService:Create(thing, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
					BackgroundTransparency = 1,
					TextTransparency = 1,
				})
				tween:Play()
			end
			canTween = true
		end

		if not canTween then
			continue
		end

		if not tweenOut then
			local tween = tweenService:Create(thing, TweenInfo.new(1.5), savedProprties)
			tween:Play()
		else
			task.delay(2.2, function()
				local tween = tweenService:Create(thing, TweenInfo.new(0), savedProprties)
				tween:Play()
			end)
		end
	end
end


script.Parent.StartHack.Event:Connect(function(targetField)
	
	if script.Parent.Parent.Enabled then
		return
	end
	
	currentStage = 1
	target = targetField
	reseved = {}
	
	script.Parent.Parent.Enabled = true
	tweenCoreUI()
	wait(2)
	doThing()
end)

local transition = false

for i, button: TextButton in buttons:GetChildren() do
	if not button:IsA("TextButton") then
		continue
	end
	local db = false

	button.MouseButton1Click:Connect(function()
		playerSlecting = os.time()
	
		if db or not script.Parent.Parent.Enabled or transition then
			return
		end

		for i, tween: Tween in activeTweens do
			tween:Cancel()
		end
		wait()
		for index, newButton in buttons:GetChildren() do
			if not newButton:IsA("TextButton") then
				continue
			end
			newButton.Size = defaultSize
			newButton.BackgroundColor3 = Color3.fromHex("#77adff")
		end

		local correct = true

		if currentFormat[#playerSelection+1] ~= tonumber(button.Name) then
			correct = false
		end

		if correct then
			table.insert(playerSelection, tonumber(button.Name))	
			button:FindFirstChildWhichIsA("Sound"):Play()
			local tweenButton = tweenService:Create(button, tweenIn, {Size = targetSize, BackgroundColor3 = userSelect})
			tweenButton:Play()
		else
			playerSelection = {}
			script.Parent.Error:Play()
			for index, newButton in buttons:GetChildren() do
				if not newButton:IsA("TextButton") then
					continue
				end
				local tweenButton = tweenService:Create(newButton, tweenIn, {Size = targetSize, BackgroundColor3 = userFailButton})
				tweenButton:Play()
			end
		end

		db = true
		task.wait( (tweenTimeIn*2)-0.1 )
		db = false
	end)

end

progress.Event:Connect(function()
	transition = true
	for index, newButton in buttons:GetChildren() do
		if not newButton:IsA("TextButton") then
			continue
		end
		local tweenButton = tweenService:Create(newButton, tweenIn, {Size = targetSize, BackgroundColor3 = userSelect})
		tweenButton:Play()
	end
	script.Parent.Success:Play()
	task.wait(tweenTimeIn*2+0.1)
	if currentStage+1 > stages then
		tweenCoreUI(true)
		task.wait(2)
		script.Parent.Parent.Enabled = false
		game.ReplicatedStorage.MainStorage.RemoteEvent.FieldHacking.HackingCompleated:FireServer(target)
		target = nil
	else
		currentStage += 1
		doThing()
		task.delay(5, function()
			transition = false
		end)
		return
	end
	transition = false
end)
