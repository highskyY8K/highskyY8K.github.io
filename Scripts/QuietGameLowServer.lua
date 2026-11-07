if not getgenv().BHD then getgenv().BHD = true else return end
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LastStage, HidePlayer = 0, false
--
local GetTime, Server = function()
    return game.ReplicatedStorage:GetAttribute("Timer"), workspace.SignPart.SurfaceGui.Timer.Text
end, function()
    return ("https://highskyy8k.github.io/roblox/?place=" .. game.PlaceId .. "&job=" .. game.JobId)
end

ReplicatedStorage:GetAttributeChangedSignal("Timer"):Connect(function()
    if HidePlayer then
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0, 10000000, 0)
    end
    
    local Number = (GetTime())
    local Stage = Number <= 0 and 3 or Number <= 60 and 2 or Number <= 180 and 1 or 0
    if Stage <= LastStage then
        LastStage = Stage
        return
    end

    LastStage = Stage
    request({
        Url = "https://discord.com/api/webhooks/1568657002786455718/JFft54Kcdu3z49MpAhTmnM2bEWtaPwW" .. tonumber(20/2) .. "MSNQia0kIfD_0-QzPvYuaISBKKP4n0mCxI1",
        Method = "POST",
        Headers = {["content-type"] = "application/json"},
        Body = game:GetService("HttpService"):JSONEncode({
            ["embeds"] = {
                {
                    ["title"] = ({"Quiet game | 3 Minutes left!", "Quiet game | 1 Minute left!", "Quiet game | We won! 🎉"})[Stage],
                    ["description"] = `> [Join Here]({Server()})\n> Server ID: **{string.sub(game.JobId, 1, 5)}**\n> Server Time: **{select(2, GetTime())}**\n> Server players: {#game:GetService("Players"):GetPlayers()}`,
                    ["color"] = ({5763719, 5763719, 1752220})[Stage],
                    ["type"] = "rich",
                }
            }
        }),
    })
end)
