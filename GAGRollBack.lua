_G.TargetPets = {
    -- ["ชื่อ Pet"] = น้ำหนักขั้นต่ำที่ยอมรับ
    ["Butterfly"] = 0.1,
    ["Disco Bee"] = 0.1,
    ["Dragonfly"] = 3.0,
    ["Red Fox"] = 0.1,
    ["Queen Bee"] = 0.1,
}

local function isTargetPet(name, weight)
    local minWeight = _G.TargetPets[name]
    return minWeight and weight and weight >= minWeight
end

local DataSer = require(game:GetService("ReplicatedStorage").Modules.DataService)
local nameofpet

repeat task.wait() until DataSer:GetData() and DataSer:GetData().SavedObjects

while true do
    task.wait()
    local notrejoin = false

    for _, v in pairs(DataSer:GetData().SavedObjects) do
        if v.ObjectType == "PetEgg" and v.Data.RandomPetData and v.Data.CanHatch then
            local petName = v.Data.RandomPetData.Name
            local petWeight = v.Data.BaseWeight
            
            if isTargetPet(petName, petWeight) then
                notrejoin = true
                nameofpet = petName
                break
            end
        end
    end

    if notrejoin then
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Bigthap/AutoPlay/refs/heads/main/RollBack.lua"))()
        print(nameofpet)
        break
    else
        task.wait(3)
        game:GetService("Players").LocalPlayer:Kick("Don't have your target pet\\Rejoin")
        task.wait(1)
        pcall(function()
            game:GetService("TeleportService"):Teleport(game.PlaceId, game:GetService("Players").LocalPlayer)
        end)
    end
end
