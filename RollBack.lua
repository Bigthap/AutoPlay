local DataSer = require(game:GetService("ReplicatedStorage").Modules.DataService)

-- ดึง SavedObjects มาเก็บ
local savedData = DataSer:GetData().SavedObjects

-- สร้าง UI Template
local function createEggUI(petEggModel, displayText)
    if petEggModel:FindFirstChild("EggInfoUI") then
        petEggModel.EggInfoUI:Destroy()
    end

    local gui = Instance.new("BillboardGui")
    gui.Name = "EggInfoUI"
    gui.Size = UDim2.new(0, 200, 0, 50)
    gui.StudsOffset = Vector3.new(0, 3, 0)
    gui.Adornee = petEggModel:FindFirstChildWhichIsA("BasePart") or petEggModel.PrimaryPart
    gui.AlwaysOnTop = true

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 0.2
    label.TextScaled = true
    label.Text = displayText
    label.TextColor3 = Color3.fromRGB(255, 255, 0)
    label.Parent = gui

    gui.Parent = petEggModel
end

-- ลูปทุกฟาร์ม
for _, farm in pairs(workspace.Farm:GetChildren()) do
    local success, important = pcall(function()
        return farm:WaitForChild("Important", 3)
    end)

    if success and important then
        local objectsFolder = important:FindFirstChild("Objects_Physical")
        if objectsFolder then
            for _, model in pairs(objectsFolder:GetChildren()) do
                if model:IsA("Model") and model.Name == "PetEgg" and model:GetAttribute("OBJECT_UUID") then
                    local uuid = model:GetAttribute("OBJECT_UUID") -- ใช้ UUID ตรง ๆ โดยไม่ลบ {}

                    local obj = savedData[uuid]
                    if obj and obj.ObjectType == "PetEgg" then
                        local petData = obj.Data
                        local info = ""

                        if petData.RandomPetData then
                            local petName = petData.RandomPetData.Name or "???"
                            local canHatch = tostring(petData.CanHatch)
                            local weight = petData.BaseWeight and string.format("%.2f", petData.BaseWeight) or "N/A"
                            
                            info = string.format("Ready: %s\nPet: %s\nWeight: %s KG", canHatch, petName, weight)
                        else
                            info = "กำลังสร้าง..."
                        end
                        

                        createEggUI(model, info)
                    else
                        warn("ไม่พบข้อมูล SaveObject สำหรับ UUID:", uuid)
                        
                        -- DEBUG เพิ่มเติม: แสดงว่าใน savedData มี key อะไรบ้าง
                        for key, _ in pairs(savedData) do
                            print("ใน savedData มี UUID:", key)
                        end
                    end
                end
            end
        else
            warn("ไม่พบ Objects_Physical ในฟาร์ม:", farm.Name)
        end
    else
        warn("ไม่พบ Important ในฟาร์ม:", farm.Name)
    end
end
