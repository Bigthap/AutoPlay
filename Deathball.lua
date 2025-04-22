repeat wait() until game:IsLoaded() and game.Players.LocalPlayer and game.Players.LocalPlayer.Character

loadstring(game:HttpGet("https://raw.githubusercontent.com/GoGo707/Death-ball-script/refs/heads/main/Auto%20Parry"))()

local vu = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:connect(function()
   vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
   wait(1)
   vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
end)

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local PLACE_ID = game.PlaceId
local MINIMUM_PLAYERS = 4
local teleportPoints = {
	Vector3.new(582.8479614257812, 281.8297424316406, -787.8519897460938),
	Vector3.new(547.5407104492188, 281.86981201171875, -771.9777221679688),
	Vector3.new(585.7130737304688, 281.8482666015625, -772.0980224609375)
}

-- ตัวแปร bot
local followDistance = 60
local changeTargetChance = 0.1
local randomMoveChance = 0.2
local jumpChance = 0.05
local dashChance = 0.03
local lookAroundChance = 0.15
local minWaitTime = 0.5
local maxWaitTime = 1.5
local cameraLookAngleRange = 80
local lookAroundCooldown = 2

local currentTarget = nil
local lastLookAroundTime = 0
local botIsActive = false

-- Function: get character component
local function getCharacterComponents()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local hrp = character:WaitForChild("HumanoidRootPart")
	return humanoid, hrp
end

-- Function: simulate dash
local function simulateDash()
	-- กระโดดก่อน
	VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
	task.wait(0.1)
	VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)

	-- รอให้กระโดดขึ้นเล็กน้อยก่อน dash
	task.wait(0.2)

	-- Dash (กด Q)
	VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
	task.wait(0.1)
	VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
end

-- Function: look around
local function lookAroundRandomly()
	local camera = Workspace.CurrentCamera
	if not camera then return end

	local currentCFrame = camera.CFrame
	local randomYaw = math.rad(math.random(-cameraLookAngleRange, cameraLookAngleRange))
	local randomPitch = math.rad(math.random(-cameraLookAngleRange / 2, cameraLookAngleRange / 2))
	local newCFrame = currentCFrame * CFrame.Angles(0, randomYaw, 0) * CFrame.Angles(randomPitch, 0, 0)

	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local tween = TweenService:Create(camera, tweenInfo, {CFrame = newCFrame})
	tween:Play()

	lastLookAroundTime = tick()
end

-- Function: find target
local function findNewTarget()
	local potentialTargets = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p:GetAttribute("IsInGame") == true and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChildOfClass("Humanoid") and p.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
			table.insert(potentialTargets, p)
		end
	end
	if #potentialTargets > 0 then
		return potentialTargets[math.random(#potentialTargets)]
	end
	return nil
end

-- Function: check player count and teleport
local function findServer()
	local url = "https://games.roblox.com/v1/games/" .. PLACE_ID .. "/servers/Public?sortOrder=Asc&limit=100"
	local success, result = pcall(function()
		return HttpService:JSONDecode(game:HttpGet(url))
	end)
	if success and result and result.data then
		for _, server in ipairs(result.data) do
			if server.playing >= MINIMUM_PLAYERS and server.id ~= game.JobId then
				return server.id
			end
		end
	end
	return nil
end

local function checkPlayersAndTeleport()
	if #Players:GetPlayers() < MINIMUM_PLAYERS then
		local serverId = findServer()
		if serverId then
			for _, p in pairs(Players:GetPlayers()) do
				TeleportService:TeleportToPlaceInstance(PLACE_ID, serverId, p)
			end
		else
			warn("ไม่พบ server ที่เหมาะสม")
		end
	end
end

-- Function: auto teleport back if not in game
local currentTarget1 = nil

spawn(function()
	while true do
		task.wait(3)

		if player:GetAttribute("IsInGame") ~= true then
			local character = player.Character or player.CharacterAdded:Wait()
			local humanoid = character:FindFirstChildWhichIsA("Humanoid")
			local hrp = character:FindFirstChild("HumanoidRootPart")

			if humanoid and hrp then
				if not currentTarget1 then
					-- สุ่มเป้าหมาย 1 จุด
					currentTarget1 = teleportPoints[math.random(1, #teleportPoints)]
				end

				humanoid:MoveTo(currentTarget1)
			end
		else
			-- Reset จุดหมาย ถ้า InGame
			currentTarget1 = nil
		end
	end
end)


-- Loop: Server Teleport
spawn(function()
	while true do
		wait(5)
		checkPlayersAndTeleport()
	end
end)

-- Main Bot Loop
while true do
	task.wait(math.random() * (maxWaitTime - minWaitTime) + minWaitTime)
	if player:GetAttribute("IsInGame") == true then
		if not botIsActive then
			botIsActive = true
			currentTarget = nil
		end

		local character = player.Character
		local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		if not (character and humanoid and rootPart and humanoid.Health > 0) then continue end

		local shouldFindNewTarget = false
		if not currentTarget or not currentTarget.Parent or not currentTarget.Character or not currentTarget.Character:FindFirstChild("HumanoidRootPart") or not currentTarget.Character:FindFirstChildOfClass("Humanoid") or currentTarget.Character:FindFirstChildOfClass("Humanoid").Health <= 0 or currentTarget:GetAttribute("IsInGame") ~= true then
			shouldFindNewTarget = true
		elseif math.random() < changeTargetChance then
			shouldFindNewTarget = true
		end

		if shouldFindNewTarget then
			currentTarget = findNewTarget()
		end

		if currentTarget and currentTarget.Character then
			local targetRoot = currentTarget.Character:FindFirstChild("HumanoidRootPart")
			if targetRoot then
				if math.random() < randomMoveChance then
					humanoid:MoveTo(rootPart.Position + Vector3.new(math.random(-25, 25), 0, math.random(-25, 25)))
				else
					local dir = (targetRoot.Position - rootPart.Position).Unit
					humanoid:MoveTo(targetRoot.Position - (dir * followDistance))
				end
			else
				currentTarget = nil
				humanoid:MoveTo(rootPart.Position + Vector3.new(math.random(-25, 25), 0, math.random(-25, 25)))
			end
		else
			humanoid:MoveTo(rootPart.Position + Vector3.new(math.random(-30, 30), 0, math.random(-30, 30)))
		end

		if math.random() < jumpChance then
			humanoid.Jump = true
		end
		if math.random() < dashChance then
			simulateDash()
		end
		if math.random() < lookAroundChance and (tick() - lastLookAroundTime > lookAroundCooldown) then
			lookAroundRandomly()
		end
	else
		if botIsActive then
			botIsActive = false
			currentTarget = nil
			local character = player.Character
			local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
			if humanoid then
				humanoid:MoveTo(humanoid.Parent.HumanoidRootPart.Position)
			end
		end
	end
end
