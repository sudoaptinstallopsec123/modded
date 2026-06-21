-- Check the current PlaceId of the game
if game.PlaceId == 107095834793267 then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/sudoaptinstallopsec123/modded/refs/heads/main/oil.lua"))()
    
elseif game.PlaceId == 93623116896447 then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/sudoaptinstallopsec123/modded/refs/heads/main/dumplings"))()
    
elseif game.PlaceId == 6989310863 then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/sudoaptinstallopsec123/modded/refs/heads/main/horses.lua"))()
else
    local HttpService = game:GetService("HttpService")
local rawLink = "https://raw.githubusercontent.com/AxerRe/ProSite/refs/heads/main/views/AxrexNotifier.lua"

local success, NotificationLib = pcall(function()
    return loadstring(game:HttpGet(rawLink))()
end)

if success and NotificationLib then
    NotificationLib:Show("Error", "Game not supported.", 3)
else
    warn("Failed to load Notification from GitHub!")
end
end
