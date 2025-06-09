_G.TargetPets = {
    ["Butterfly"] = 0.1,
    ["Disco Bee"] = 0.1,
    ["Dragonfly"] = 2.0,
    ["Red Fox"] = 0.1,
    ["Queen Bee"] = 0.1,
}

local function isTargetPet(name, weight)
    local minWeight = _G.TargetPets[name]
    return minWeight and weight and weight >= minWeight
end

local DataSer = require(game:GetService("ReplicatedStorage").Modules.DataService)
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local username = Players.LocalPlayer.Name
local webhookUrl = "https://discordapp.com/api/webhooks/1381667238553190441/ENFg3X_XtCpETB4EWosyI6uLhXG4b7jDm2qMCLweHRfGH7-JFP39vV3_-6vpkNVxCeZD"

local function sendWebhook(petName, petWeight, isTarget)
    local content = ""
    if isTarget then
        content = "@everyone 🎯 เจอ Pet ที่ตรงกับเป้าหมาย!"
    end

    local payload = {
        content = content,
        embeds = {{
            title = "🐾 Pet Hatch Alert!",
            description = string.format("**ผู้เล่น:** %s\n**ชื่อ Pet:** %s\n**น้ำหนัก:** %.3f", username, petName, petWeight),
            color = isTarget and 0x00ff00 or 0xff9900,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        }}
    }

    local success, response = pcall(function()
        return HttpService:PostAsync(webhookUrl, HttpService:JSONEncode(payload), Enum.HttpContentType.ApplicationJson)
    end)

    if not success then
        warn("Failed to send webhook:", response)
    end
end

repeat task.wait() until DataSer:GetData() and DataSer:GetData().SavedObjects

while true do
    task.wait()
    local notrejoin = false
    local foundPetName = ""
    local foundWeight = 0

    for _, v in pairs(DataSer:GetData().SavedObjects) do
        if v.ObjectType == "PetEgg" and v.Data.RandomPetData and v.Data.CanHatch then
            local petName = v.Data.RandomPetData.Name
            local petWeight = v.Data.BaseWeight

            if _G.TargetPets[petName] then
                sendWebhook(petName, petWeight, isTargetPet(petName, petWeight))
            end

            if isTargetPet(petName, petWeight) then
                notrejoin = true
                foundPetName = petName
                foundWeight = petWeight
                break
            end
        end
    end

    if notrejoin then
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Bigthap/AutoPlay/refs/heads/main/RollBack.lua"))()
        print(foundPetName)
        break
    else
        task.wait(3)
        Players.LocalPlayer:Kick("Don't have your target pet\\Rejoin")
        task.wait(1)
        pcall(function()
            TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
        end)
    end
end
