repeat wait() until game:IsLoaded() and game.Players.LocalPlayer and game.Players.LocalPlayer.Character

script_key="IMBBPzGNNAwKxECIGLSBotRCNukOHEnA";
(loadstring or load)(game:HttpGet("https://getnative.cc/script/loader"))()

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
local targetPlaceId = 83678792452277


local MINIMUM_PLAYERS = 4
local teleportPoints = {
	Vector3.new(577.6295776367188, 280.74200439453125, -771.4892578125),
	Vector3.new(558.7540893554688, 280.7420349121094, -777.024658203125),
	Vector3.new(559.5577392578125, 280.74200439453125, -767.7656860351562)
}

-- ตัวแปร bot
local followDistance = 60
local changeTargetChance = 0.1
local randomMoveChance = 0.2
local jumpChance = 0.05
local dashChance = 0.03
local lookAroundChance = 0.50
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

spawn(function()
	while true do
		wait(5)
		checkPlayersAndTeleport()
		if PLACE_ID == 15002061926 then
			TeleportService:Teleport(targetPlaceId, player)
		end
	end
end)

-- ฟังก์ชัน rejoin
local function rejoin()
	TeleportService:Teleport(targetPlaceId, player)
end

-- ทำทุก 30 นาที (1800 วินาที)
spawn(function()
	while true do
		wait(1800)
		rejoin()
	end
end)

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


-- Main Bot Loop
local lastDecisionTime = 0
local decisionCooldown = 0.5 -- ครึ่งวิค่อยตัดสินใจใหม่ เหมือนมนุษย์คิด
local idleWanderRadius = 18

while true do
	-- เพิ่ม reaction time เล็กน้อย
	task.wait(math.random() * (maxWaitTime - minWaitTime) + minWaitTime)

	if player:GetAttribute("IsInGame") == true then
		if not botIsActive then
			botIsActive = true
			currentTarget = nil
		end

		local character = player.Character
		local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		if not (character and humanoid and rootPart and humanoid.Health > 0) then
			continue
		end

		-- จำกัดความถี่การตัดสินใจ เปลี่ยนเป้าหมายไม่ถี่เกิน
		local now = tick()
		local shouldFindNewTarget = false

		-- เช็กว่าเป้าปัจจุบันยัง "สมเหตุสมผล" ไหม
		local targetHum, targetRoot
		if currentTarget and currentTarget.Character then
			targetHum = currentTarget.Character:FindFirstChildOfClass("Humanoid")
			targetRoot = currentTarget.Character:FindFirstChild("HumanoidRootPart")
		end

		-- เหตุผลที่ต้องหาเป้าใหม่
		if not currentTarget
			or not currentTarget.Parent
			or not targetRoot
			or not targetHum
			or targetHum.Health <= 0
			or currentTarget:GetAttribute("IsInGame") ~= true
		then
			shouldFindNewTarget = true
		elseif math.random() < changeTargetChance then
			-- เปลี่ยนใจแบบมนุษย์
			shouldFindNewTarget = true
		end

		-- ให้มันตัดสินใจได้แค่ทุก ๆ decisionCooldown
		if shouldFindNewTarget and (now - lastDecisionTime) > decisionCooldown then
			currentTarget = findNewTarget() -- ถ้าจะเนียนกว่านี้ให้หาเฉพาะคนที่อยู่ในมุมมองก่อน
			lastDecisionTime = now
		end

		if currentTarget and currentTarget.Character then
			local targetRoot = currentTarget.Character:FindFirstChild("HumanoidRootPart")
			if targetRoot then
				-- โอกาสวิ่งมั่วเบาๆ เหมือนหลบ/อ่านเกมผิด
				if math.random() < randomMoveChance then
					local offset = Vector3.new(math.random(-25, 25), 0, math.random(-25, 25))
					humanoid:MoveTo(rootPart.Position + offset)
				else
					-- เดินตามแต่เผื่อระยะไม่ให้ชนหัวเป้า
					local dir = (targetRoot.Position - rootPart.Position)
					local dist = dir.Magnitude

					-- ป้องกัน bug unit = NaN
					if dist > 0.1 then
						local unitDir = dir.Unit
						-- ใส่ความคลาดเคลื่อนให้เหมือนคนเล็งไม่ตรง
						local sideJitter = Vector3.new(math.random(-2,2),0,math.random(-2,2))
						local followPos = targetRoot.Position - (unitDir * followDistance) + sideJitter
						humanoid:MoveTo(followPos)
					end
				end

				-- มองรอบตัวแบบมีคูลดาวน์
				if math.random() < lookAroundChance and (tick() - lastLookAroundTime > lookAroundCooldown) then
					lookAroundRandomly()
				end

			else
				-- เป้าหายไปแล้ว เดินวนแบบคนหา
				currentTarget = nil
				humanoid:MoveTo(rootPart.Position + Vector3.new(math.random(-25, 25), 0, math.random(-25, 25)))
			end
		else
			-- ไม่มีเป้า: เดินเตร็ดเตร่ในรัศมีเล็กๆ เหมือนมองหา
			local wanderOffset = Vector3.new(
				math.random(-idleWanderRadius, idleWanderRadius),
				0,
				math.random(-idleWanderRadius, idleWanderRadius)
			)
			humanoid:MoveTo(rootPart.Position + wanderOffset)
		end

		-- action แบบไม่ทุกครั้ง เหมือนมนุษย์มีจังหวะ
		if math.random() < jumpChance then
			humanoid.Jump = true
		end
		if math.random() < dashChance then
			simulateDash()
		end

	else
		-- ออกจากเกม เคลียร์สถานะให้เหมือนคนหยุดเล่น
		if botIsActive then
			botIsActive = false
			currentTarget = nil
			local character = player.Character
			local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
			if humanoid and humanoid.Parent:FindFirstChild("HumanoidRootPart") then
				humanoid:MoveTo(humanoid.Parent.HumanoidRootPart.Position)
			end
		end
	end
end
