-- Simon Says Hacking Minigame
-- Shows the player a sequence of button presses to memorize
-- Player must repeat the sequence correctly to progress through stages
-- If no input is detected for 3 seconds, the pattern repeats

local player = game.Players.LocalPlayer
local buttonsContainer = script.Parent.Buttons
local tweenService = game:GetService("TweenService")
local contentProvider = game:GetService("ContentProvider")

-- Asset IDs for button images (30 unique symbols)
local symbolAssetIds = {
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

-- Color scheme for button states
local colorFail = Color3.fromHex("#ff3a3d") -- Red when player makes mistake
local colorShowPattern = Color3.new(0.988235, 1, 0.403922) -- Yellow when showing pattern
local colorUserCorrect = Color3.new(0, 1, 0.282353) -- Green when player selects correctly
local colorDefault = Color3.fromHex("#77adff") -- Blue default state

-- Button size animations
local defaultButtonSize = buttonsContainer:FindFirstChild("1").Size
local enlargedButtonSize = UDim2.new(defaultButtonSize.X.Scale * 1.2, 0, defaultButtonSize.Y.Scale * 1.2, 0)

-- Game state variables
local lastPlayerInputTime = 0 -- Timestamp of last button press
local hackTarget = nil -- The object being hacked
local playerSequence = {} -- Player's current input sequence
local usedSymbolIds = {} -- Prevents duplicate symbols on buttons
local currentPattern = {} -- The correct sequence to memorize
local activeTweens = {} -- Track active animations for cancellation
local totalStages = 1 -- Total stages to complete the hack
local currentStageNumber = 1 -- Current stage progress
local isTransitioning = false -- Prevents input during stage transitions

-- Animation settings
local buttonAnimationDuration = 0.2
local buttonTweenInfo = TweenInfo.new(buttonAnimationDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, true)

-- Progress event for stage completion
local progressEvent = script.progress

-- Returns a random unused symbol ID and marks it as used
local function getRandomUniqueSymbol()
	local randomId = symbolAssetIds[math.random(1, #symbolAssetIds)]
	
	-- Recursively find unused symbol
	if table.find(usedSymbolIds, randomId) then
		return getRandomUniqueSymbol()
	end
	
	table.insert(usedSymbolIds, randomId)
	return randomId
end

-- Initialize buttons with random unique symbols
for _, button: TextButton in buttonsContainer:GetChildren() do
	if not button:IsA("TextButton") then
		continue
	end
	button:FindFirstChildWhichIsA("ImageLabel").Image = getRandomUniqueSymbol()
end

-- Starts a new stage: generates pattern, assigns new symbols, and shows the sequence
local function startNewStage()
	currentPattern = {}
	playerSequence = {}

	-- Assign new random symbols to all buttons
	for _, button: TextButton in buttonsContainer:GetChildren() do
		if not button:IsA("TextButton") then
			continue
		end
		button:FindFirstChildWhichIsA("ImageLabel").Image = getRandomUniqueSymbol()
	end

	usedSymbolIds = {}
	
	-- Generate a pattern of 6 button presses (buttons numbered 1-4)
	for i = 1, 6 do
		table.insert(currentPattern, math.random(1, 4))
	end
	
	-- Run pattern display loop in parallel
	task.spawn(function()
		local stageSnapshot = currentStageNumber

		-- Continue looping while UI is enabled and stage hasn't changed
		while script.Parent.Parent and script.Parent.Parent.Enabled and currentStageNumber == stageSnapshot do
			-- Check if player completed the pattern
			if #playerSequence >= #currentPattern then
				progressEvent:Fire()
				break
			end
			
			task.wait()
			
			-- If player recently pressed a button, wait before showing pattern again
			if (os.time() - lastPlayerInputTime) <= 3 then
				continue
			end

			-- Show the pattern sequence
			for i, buttonNumber in currentPattern do
				-- Break if player pressed a button during pattern display
				if (os.time() - lastPlayerInputTime) <= 3 then
					break
				end

				-- Reset player input since we're showing pattern again
				playerSequence = {}

				local button: TextButton = buttonsContainer:FindFirstChild(tostring(buttonNumber))
				button.Size = defaultButtonSize
				button.BackgroundColor3 = colorDefault
				button:FindFirstChildWhichIsA("Sound"):Play()
				
				-- Animate button to show it's part of the pattern
				local tween = tweenService:Create(button, buttonTweenInfo, {
					Size = enlargedButtonSize, 
					BackgroundColor3 = colorShowPattern
				})
				table.insert(activeTweens, tween)
				tween:Play()
				
				-- Wait for animation to complete plus small delay
				task.wait((buttonAnimationDuration * 2) + 0.05)
			end
			
			-- Wait 3 seconds before showing pattern again
			task.wait(3)
		end
	end)
end

-- Animates the UI in or out with fade effects
-- tweenOut: true to fade out, false to fade in
local function animateUI(tweenOut)
	for _, element: Instance in script.Parent:GetDescendants() do
		local savedProperties = {}
		local canTween = false

		-- Handle Frame transparency
		if element:IsA("Frame") then
			savedProperties.BackgroundTransparency = element.BackgroundTransparency
			if not tweenOut then
				element.BackgroundTransparency = 1 -- Start invisible
			else
				local tween = tweenService:Create(element, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
					BackgroundTransparency = 1,
				})
				tween:Play()
			end
			canTween = true
			
		-- Handle TextButton transparency
		elseif element:IsA("TextButton") then
			savedProperties.BackgroundTransparency = element.BackgroundTransparency
			savedProperties.TextTransparency = element.TextTransparency
			if not tweenOut then
				element.TextTransparency = 1
				element.BackgroundTransparency = 1
			else
				local tween = tweenService:Create(element, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
					BackgroundTransparency = 1,
					TextTransparency = 1,
				})
				tween:Play()
			end
			canTween = true
			
		-- Handle ImageLabel transparency
		elseif element:IsA("ImageLabel") then
			savedProperties.BackgroundTransparency = element.BackgroundTransparency
			savedProperties.ImageTransparency = element.ImageTransparency
			if not tweenOut then
				element.ImageTransparency = 1
				element.BackgroundTransparency = 1
			else
				local tween = tweenService:Create(element, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
					BackgroundTransparency = 1,
					ImageTransparency = 1,
				})
				tween:Play()
			end
			canTween = true
			
		-- Handle UIStroke thickness
		elseif element:IsA("UIStroke") then
			savedProperties.Thickness = element.Thickness
			if not tweenOut then
				element.Thickness = 0
			else
				local tween = tweenService:Create(element, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
					Thickness = 0,
				})
				tween:Play()
			end
			canTween = true
			
		-- Handle TextLabel transparency
		elseif element:IsA("TextLabel") then
			savedProperties.BackgroundTransparency = element.BackgroundTransparency
			savedProperties.TextTransparency = element.TextTransparency
			if not tweenOut then
				element.BackgroundTransparency = 1
				element.TextTransparency = 1
			else
				local tween = tweenService:Create(element, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
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

		-- Fade in: immediately tween to saved properties
		if not tweenOut then
			local tween = tweenService:Create(element, TweenInfo.new(1.5), savedProperties)
			tween:Play()
		-- Fade out: restore properties after fade completes
		else
			task.delay(2.2, function()
				local tween = tweenService:Create(element, TweenInfo.new(0), savedProperties)
				tween:Play()
			end)
		end
	end
end

-- Event: Start the hacking minigame
script.Parent.StartHack.Event:Connect(function(targetField)
	-- Prevent starting if already active
	if script.Parent.Parent.Enabled then
		return
	end
	
	currentStageNumber = 1
	hackTarget = targetField
	usedSymbolIds = {}
	
	-- Show UI and start first stage
	script.Parent.Parent.Enabled = true
	animateUI(false) -- Fade in
	task.wait(2)
	startNewStage()
end)

-- Setup button click handlers
for _, button: TextButton in buttonsContainer:GetChildren() do
	if not button:IsA("TextButton") then
		continue
	end
	
	local debounce = false

	button.MouseButton1Click:Connect(function()
		lastPlayerInputTime = os.time()
	
		-- Prevent input during debounce, when UI disabled, or during transitions
		if debounce or not script.Parent.Parent.Enabled or isTransitioning then
			return
		end

		-- Cancel all active button animations
		for _, tween: Tween in activeTweens do
			tween:Cancel()
		end
		
		task.wait()
		
		-- Reset all buttons to default state
		for _, resetButton in buttonsContainer:GetChildren() do
			if not resetButton:IsA("TextButton") then
				continue
			end
			resetButton.Size = defaultButtonSize
			resetButton.BackgroundColor3 = colorDefault
		end

		local isCorrect = true

		-- Check if clicked button matches next expected button in pattern
		if currentPattern[#playerSequence + 1] ~= tonumber(button.Name) then
			isCorrect = false
		end

		if isCorrect then
			-- Correct input: add to sequence and show green feedback
			table.insert(playerSequence, tonumber(button.Name))	
			button:FindFirstChildWhichIsA("Sound"):Play()
			local buttonTween = tweenService:Create(button, buttonTweenInfo, {
				Size = enlargedButtonSize, 
				BackgroundColor3 = colorUserCorrect
			})
			buttonTween:Play()
		else
			-- Wrong input: reset sequence and show red feedback on all buttons
			playerSequence = {}
			script.Parent.Error:Play()
			
			for _, errorButton in buttonsContainer:GetChildren() do
				if not errorButton:IsA("TextButton") then
					continue
				end
				local buttonTween = tweenService:Create(errorButton, buttonTweenInfo, {
					Size = enlargedButtonSize, 
					BackgroundColor3 = colorFail
				})
				buttonTween:Play()
			end
		end

		-- Debounce to prevent rapid clicks
		debounce = true
		task.wait((buttonAnimationDuration * 2) - 0.1)
		debounce = false
	end)
end

-- Event: Handle stage progression or completion
progressEvent.Event:Connect(function()
	isTransitioning = true
	
	-- Show success animation on all buttons
	for _, button in buttonsContainer:GetChildren() do
		if not button:IsA("TextButton") then
			continue
		end
		local buttonTween = tweenService:Create(button, buttonTweenInfo, {
			Size = enlargedButtonSize, 
			BackgroundColor3 = colorUserCorrect
		})
		buttonTween:Play()
	end
	
	script.Parent.Success:Play()
	task.wait(buttonAnimationDuration * 2 + 0.1)
	
	-- Check if all stages completed
	if currentStageNumber + 1 > totalStages then
		-- Hack complete: fade out UI and notify server
		animateUI(true)
		task.wait(2)
		script.Parent.Parent.Enabled = false
		game.ReplicatedStorage.MainStorage.RemoteEvent.FieldHacking.HackingCompleated:FireServer(hackTarget)
		hackTarget = nil
	else
		-- Move to next stage
		currentStageNumber += 1
		startNewStage()
		
		-- Allow input after delay
		task.delay(5, function()
			isTransitioning = false
		end)
		return
	end
	
	isTransitioning = false
end)
