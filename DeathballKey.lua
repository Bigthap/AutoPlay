-- Services
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Player = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- ========= Config =========
local DEBUG = true                      -- เปิด/ปิด log
local TTI_ON  = 0.25                    -- กดเมื่อ TTI ลดลงข้ามค่านี้ (วินาที)
local TTI_OFF = 0.20                    -- ต้องดีดกลับเกินค่านี้ก่อนจะ “armed” อีกครั้ง (hysteresis)
local MIN_SPEED = 2.0                   -- studs/s ช้ากว่านี้ไม่สนใจ
local PARRY_COOLDOWN = 0.04             -- กันกดถี่เกินไป (รวม ๆ)
local PER_BALL_CD = 0.10                -- กันลูกเดียวกันสั่งติดกัน
local GLOBAL_GATE = 0.05                -- หน้าต่างกันกดซ้อนจากหลายลูก
local REQUIRE_HIGHLIGHT_TO_TARGET = true -- ส่วนใหญ่เกมไม่ได้ใส่ Highlight ที่ตัวผู้เล่น

-- ========= Debug helper =========
local function dprint(...)
    if DEBUG then print("[AP]", ...) end
end
local function fullname(x) return x and x:GetFullName() or "nil" end

-- ========= UI Toggle =========
local AutoParryEnabled = false
do
    local gui = Instance.new("ScreenGui")
    gui.Name = "AutoParryGui"
    gui.ResetOnSpawn = false
    gui.Parent = Player:WaitForChild("PlayerGui")

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 150, 0, 50)
    btn.Position = UDim2.new(0.05, 0, 0.1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 22
    btn.Text = "Auto Parry: OFF"
    btn.Parent = gui

    btn.MouseButton1Click:Connect(function()
        AutoParryEnabled = not AutoParryEnabled
        btn.Text = AutoParryEnabled and "Auto Parry: ON" or "Auto Parry: OFF"
        btn.BackgroundColor3 = AutoParryEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,0)
        dprint("Toggle:", AutoParryEnabled and "ON" or "OFF")
    end)
end

-- ========= Helpers =========
local lastParryAt = 0
local function tryParry(why)
    local now = tick()
    if now - lastParryAt < GLOBAL_GATE then
        dprint("Global gate: skip")
        return
    end
    if now - lastParryAt < PARRY_COOLDOWN then
        dprint("Parry blocked by cooldown")
        return
    end
    lastParryAt = now
    dprint(("PARRY -> %s"):format(why or ""))
    -- หมายเหตุ: เกมบางเกมต้องใช้ true ที่พารามิเตอร์ gameProcessedEvent แทน false
    VirtualInputManager:SendKeyEvent(true,  Enum.KeyCode.F, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
end

local function isTarget()
    if not REQUIRE_HIGHLIGHT_TO_TARGET then return true end
    local char = Player.Character
    local highlight = char and char:FindFirstChild("Highlight")

    if highlight and highlight:IsA("Highlight") then
        -- เปรียบเทียบ FillColor ว่าเป็นสีแดง
        local col = highlight.FillColor
        local targetColor = Color3.fromRGB(255,0,0)

        -- ถ้าต้องตรงเป๊ะ
        if col == targetColor then
            return true
        end

        -- หรือใช้ tolerance กันสีเพี้ยนเล็กน้อย
        local function isClose(c1, c2, tol)
            return math.abs(c1.R - c2.R) < tol
               and math.abs(c1.G - c2.G) < tol
               and math.abs(c1.B - c2.B) < tol
        end

        if isClose(col, targetColor, 0.05) then
            return true
        end
    end

    if DEBUG then
        dprint("isTarget=false (no red Highlight)")
    end
    return false
end


local function getTargetPosition()
    local char = Player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then return hrp.Position end
    if workspace.CurrentCamera then return workspace.CurrentCamera.CFrame.Position end
    return Vector3.zero
end

-- ปรับฟิลเตอร์ให้ตรงเกม: ตอนนี้จับ BasePart ที่ชื่อ "Part" หรือ "Ball"
local function verifyBall(inst)
    local ok = inst:IsA("BasePart") and (inst.Name == "Part" or inst.Name == "Ball")
    if DEBUG and ok then
        local h = inst:FindFirstChild("Highlight")
        local info = h and " (has Ball.Highlight)" or ""
        dprint("verifyBall=TRUE:", inst.Name, inst.ClassName, fullname(inst), info)
    end
    return ok
end

-- ========= Attach per ball =========
local attached = {} -- [Instance] = {posConn=..., ancConn=...}

local function detachBall(ball)
    local rec = attached[ball]
    if not rec then return end
    if rec.posConn then rec.posConn:Disconnect() end
    if rec.ancConn then rec.ancConn:Disconnect() end
    attached[ball] = nil
    dprint("Detached:", fullname(ball))
end

local function attachBall(ball)
    if attached[ball] or not ball or not ball:IsDescendantOf(workspace) then return end

    dprint("Attach:", fullname(ball), "Anchored=", ball.Anchored, "CanCollide=", ball.CanCollide)

    local lastPos  = ball.Position
    local lastTick = tick()
    local lastLog  = 0

    -- state ต่อบอล
    local armed         = true            -- พร้อมยิงเมื่อ TTI ลดผ่าน TTI_ON
    local perBallLastAt = 0               -- เวลากดล่าสุดของลูกนี้
    local prevTTI       = math.huge

    local function onPosChanged()
        if not AutoParryEnabled then return end
        if not isTarget() then return end

        local now = tick()
        local dt  = now - lastTick
        if dt <= 0 then return end

        local curPos   = ball.Position
        local target   = getTargetPosition()
        local dist     = (curPos - target).Magnitude
        local moveVec  = (curPos - lastPos)
        local speed    = moveVec.Magnitude / dt

        -- กำลังเคลื่อนเข้าหาเป้าหมาย?
        local dirToTarget = (target - curPos)
        local approaching = (moveVec:Dot(dirToTarget) > 0)

        local tti = (speed > 1e-3) and (dist / speed) or math.huge

        -- throttle log
        if DEBUG and (now - lastLog) > 0.1 then
            dprint(("Ball %s | dt=%.3f dist=%.2f spd=%.2f TTI=%.3f armed=%s approaching=%s")
                :format(ball.Name, dt, dist, speed, tti, tostring(armed), tostring(approaching)))
            lastLog = now
        end

        -- hysteresis: re-arm เมื่อหลุดโซน
        if not armed and tti >= TTI_OFF then
            armed = true
            dprint("Re-armed (TTI back above OFF)")
        end

        -- edge-trigger + guards
        if armed
           and speed >= MIN_SPEED
           and approaching
           and prevTTI > TTI_ON
           and tti     <= TTI_ON
           and (now - perBallLastAt) >= PER_BALL_CD
        then
            perBallLastAt = now
            armed = false -- จะ armed ใหม่เมื่อ TTI >= TTI_OFF
            tryParry(string.format("TTI=%.3f Dist=%.2f Spd=%.2f", tti, dist, speed))
        end

        prevTTI  = tti
        lastPos  = curPos
        lastTick = now
    end

    local posConn = ball:GetPropertyChangedSignal("Position"):Connect(onPosChanged)
    local ancConn = ball.AncestryChanged:Connect(function(_, parent)
        if not parent then detachBall(ball) end
    end)

    attached[ball] = {posConn = posConn, ancConn = ancConn}
end

-- ========= Bootstrap =========
-- ติดกับลูกบอลที่มีอยู่แล้ว
for _, inst in ipairs(workspace:GetDescendants()) do
    if verifyBall(inst) then
        attachBall(inst)
    end
end

-- และลูกบอลที่เกิดใหม่
workspace.DescendantAdded:Connect(function(inst)
    if verifyBall(inst) then
        attachBall(inst)
    elseif DEBUG and inst:IsA("BasePart") then
        -- เปิดถ้าอยากดูว่ามีอะไร spawn บ้าง
        -- dprint("Reject:", inst.Name, inst.ClassName, fullname(inst))
    end
end)

Players.LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    dprint("Character added; system ready.")
end)
