_G.TargetName = "Queen Bee"
local notrejoin = false
local DataSer = require(game:GetService("ReplicatedStorage").Modules.DataService)
while true do wait()
    for i,v in pairs(DataSer:GetData().SavedObjects) do
        if v.ObjectType == "PetEgg" then
            if v.Data.RandomPetData ~= nil then
                if v.Data.CanHatch then
                    if v.Data.RandomPetData.Name == _G.TargetName then
                        notrejoin = true
                    end 
                end
            end
        end
    end
    if notrejoin then
        print("Found Eggs!")
    else
        wait(3)
        game:GetService("Players").LocalPlayer:Kick("Don't have your target pet\Rejoin")
        task.wait(1)
        game:GetService("TeleportService"):Teleport(game.PlaceId, game:GetService("Players").LocalPlayer)
    end
end
