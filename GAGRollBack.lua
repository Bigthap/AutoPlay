_G.TargetName = {
    "Butterfly",
    "Disco Bee",
    "Dragonfly",
    "Red Fox",
}

local function isTargetPet(name)
    for _, targetName in ipairs(_G.TargetName) do
        if name == targetName then
            return true
        end
    end
    return false
end

local DataSer = require(game:GetService("ReplicatedStorage").Modules.DataService)
local nameofpet

repeat task.wait() until DataSer:GetData() and DataSer:GetData().SavedObjects

while true do
    task.wait()
    local notrejoin = false

    for _, v in pairs(DataSer:GetData().SavedObjects) do
        if v.ObjectType == "PetEgg" and v.Data.RandomPetData and v.Data.CanHatch then
            if isTargetPet(v.Data.RandomPetData.Name) then
                notrejoin = true
                nameofpet = v.Data.RandomPetData.Name
                break
            end
        end
    end

    if notrejoin then
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
