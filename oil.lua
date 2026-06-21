-- idk, try to use this and figure out how the lib works ig?
local httpService = game:GetService('HttpService')
local repo = "https://raw.githubusercontent.com/uhfork/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

--make autosteal and make it modify time to use proximity prompt to 1 or 0 cause u can do that apparently

Library.ForceCheckbox = false 
Library.ShowToggleFrameInKeybinds = true

local Loading = Library:CreateLoading({
    Title = "coconut.xyz",
    Icon = 125779171427078,
    TotalSteps = 4
})

Loading:SetMessage("Initializing...")
Loading:SetDescription("Waiting for game to load...")
task.wait(1)
 
Loading:SetCurrentStep(1)
Loading:SetDescription("Loading configuration...")
task.wait(1)

Loading:SetCurrentStep(2)
Loading:ShowSidebarPage(true)
Loading.Sidebar:AddLabel("User: " .. game.Players.LocalPlayer.Name)
Loading.Sidebar:AddLabel("Version: v1.0.0")
task.wait(1)
 
Loading:SetCurrentStep(3)
Loading:SetDescription("Ready to start!")
task.wait(1)
 
Loading:SetCurrentStep(4)
Loading:Continue()

local Window = Library:CreateWindow({
	Title = "coconut.xyz",
	Footer = "version: 1.0.0",
	Icon = 125779171427078,
	CornerElements = false,
	NotifySide = "Right",
	ShowCustomCursor = true,
})

-- ============================================================
--  AutoCollect + AutoSell + AutoBuyZones Script
--  LocalScript – place inside StarterPlayerScripts
-- ============================================================

local Players                = game:GetService("Players")
local RunService             = game:GetService("RunService")
local ReplicatedStorage      = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

local LocalPlayer      = Players.LocalPlayer
local Character        = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- ============================================================
--  CONFIGURATION
-- ============================================================

local CONFIG = {
    -- AUTO COLLECT
    AutoCollect      = false,
    CollectDelay     = 0.05,                 -- Seconds between each refinery fire (keep >= 0.05)
    CycleDelay       = 0.1,                  -- Seconds between full collect cycles
    TeleportOffset   = Vector3.new(0, 4, 0), -- Land above the refinery (used by zone buyer only)

    -- AUTO SELL
    AutoSell            = false,
    SellInterval        = 5,                 -- Seconds between each SellGas fire

    -- SELL PRICE FILTER
    -- When SellOnlyAtMinPrice is true, gas will only be sold if the current
    -- GasPrice Value >= MinSellPrice. Range in-game is 1–15.
    SellOnlyAtMinPrice  = false,             -- Toggle price filter on/off
    MinSellPrice        = 10,                -- Only sell when GasPrice >= this

    -- AUTO BUY ZONES
    AutoBuyZones     = false,
    BuyCheckInterval = 2,                    -- Seconds between full zone scan cycles

    -- ZONE COSTS
    -- Set the price for each zone here. The script will only buy a zone
    -- when your Cash >= the cost defined here. Set to 0 to always attempt.
    -- Format:  ["ZoneX"] = cost
    ZoneCosts = {
        ["Zone1"]  = 5000,
        ["Zone2"]  = 20000,
        ["Zone3"]  = 50000,
        ["Zone4"]  = 150000,
        ["Zone5"]  = 500000,
        ["Zone6"]  = 2500000,
        ["Zone7"]  = 100000000,
        ["Zone8"]  = 500000000,
        ["Zone9"]  = 100000000000,
        ["Zone10"] = 1000000000000,
        ["Zone11"] = 99000000000000,
    },

    -- AUTO STEAL
    AutoSteal        = false,                -- Toggle AutoSteal on/off
    StealCycleDelay  = 1,                    -- Seconds between full steal cycles
    StealUnderOffset = Vector3.new(0, -3, 0),-- Teleport slightly under the StealAtc attachment

    -- MISC
    Debug = false,
}

-- ============================================================
--  REMOTES & LIVE VALUES
-- ============================================================

local SellGasRemote = ReplicatedStorage
    :WaitForChild("Packages")
    :WaitForChild("Knit")
    :WaitForChild("Services")
    :WaitForChild("BaseService")
    :WaitForChild("RE")
    :WaitForChild("SellGas")

-- GasPrice lives at ReplicatedStorage.GasPrice — it has a .Value (number, range 1–15)
local GasPriceObject = ReplicatedStorage:WaitForChild("GasPrice")

local function GetGasPrice()
    if GasPriceObject and GasPriceObject.Value then
        return GasPriceObject.Value
    end
    return 0
end

-- DrillShop purchase remote
local DrillPurchaseRemote = ReplicatedStorage
    :WaitForChild("Packages")
    :WaitForChild("Knit")
    :WaitForChild("Services")
    :WaitForChild("StoresService")
    :WaitForChild("RE")
    :WaitForChild("Purchase")

-- ============================================================
--  UTILITIES
-- ============================================================

local function Log(...)
    if CONFIG.Debug then
        print("[Script]", ...)
    end
end

local function SafeWait(seconds)
    local endTime = tick() + seconds
    repeat RunService.Heartbeat:Wait() until tick() >= endTime
end

-- Returns current Cash from leaderstats
local function GetCash()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if not leaderstats then return 0 end
    local cashVal = leaderstats:FindFirstChild("Cash")
    if not cashVal then return 0 end
    return cashVal.Value
end

-- ============================================================
--  STEP 1 – FIND PLOT
-- ============================================================

local function FindPlayerPlot()
    local PlotsFolder = workspace:FindFirstChild("Plots")
    if not PlotsFolder then
        warn("[Script] 'Plots' folder not found!")
        return nil
    end

    for i = 1, 6 do
        local plot = PlotsFolder:FindFirstChild("Plot" .. i)
        if not plot then continue end

        local config = plot:FindFirstChild("Configuration")
        if not config then continue end

        local objVal = config:FindFirstChildWhichIsA("ObjectValue")
        if objVal and objVal.Value == LocalPlayer then
            Log("Plot found via ObjectValue: Plot" .. i)
            return plot
        end

        local strVal = config:FindFirstChildWhichIsA("StringValue")
        if strVal and strVal.Value == LocalPlayer.Name then
            Log("Plot found via StringValue: Plot" .. i)
            return plot
        end

        local ownerAttr = plot:GetAttribute("Owner")
        if ownerAttr and ownerAttr == LocalPlayer.Name then
            Log("Plot found via Owner attribute: Plot" .. i)
            return plot
        end
    end

    warn("[Script] No plot found for:", LocalPlayer.Name)
    return nil
end

-- ============================================================
--  STEP 2 – FIND REFINERIES
-- ============================================================

local function FindRefineries(plot)
    local refineries = {}

    local buildingsFolder = plot:FindFirstChild("Buildings")
    if not buildingsFolder then
        warn("[Script] No 'Buildings' folder in plot!")
        return refineries
    end

    Log("Scanning Buildings folder...")

    for _, child in ipairs(buildingsFolder:GetChildren()) do
        if child:IsA("Model") then
            local typeAttr = child:GetAttribute("Type")
            Log("  Checking:", child.Name, "| Type:", tostring(typeAttr))
            if typeAttr == "Refinery" then
                table.insert(refineries, child)
                Log("  -> Refinery found:", child.Name)
            end
        end
    end

    if #refineries == 0 then
        warn("[Script] No Refineries found.")
    else
        Log(#refineries .. " Refinery/Refineries found.")
    end

    return refineries
end

-- ============================================================
--  STEP 3 – TELEPORT HELPERS
-- ============================================================

local function GetModelCFrame(model)
    if model.PrimaryPart then
        return model.PrimaryPart.CFrame
    end
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            return part.CFrame
        end
    end
    return nil
end

local function TeleportToPart(part)
    Character        = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    HumanoidRootPart.CFrame = CFrame.new(part.Position + CONFIG.TeleportOffset)
end

local function TeleportToModel(model)
    Character        = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

    local cf = GetModelCFrame(model)
    if not cf then
        warn("[Script] Could not get CFrame for:", model.Name)
        return
    end

    HumanoidRootPart.CFrame = CFrame.new(cf.Position + CONFIG.TeleportOffset)
    Log("Teleported to:", model:GetAttribute("Name") or model.Name)
end

-- ============================================================
--  FEATURE 1 – AUTO COLLECT
--
--  Instead of teleporting, we find the TouchInterest inside
--  the Refinery's PrimaryPart and fire it with firetouchinterest.
--  Structure: Buildings > <GUID> > Primary > TouchInterest
-- ============================================================

-- Fires the TouchInterest on a part (executor built-in)
-- firetouchinterest(part, playerPart, type) — playerPart must be a BasePart
local function FireTouchInterest(part)
    -- Fire touch begin and end back-to-back with no wait — server handles it instantly
    firetouchinterest(part, HumanoidRootPart, 0) -- 0 = touch begin
    firetouchinterest(part, HumanoidRootPart, 2) -- 2 = touch end
    return true
end

-- Gets the Primary part from a refinery model
local function GetRefineryPrimary(refinery)
    -- PrimaryPart is set to "Primary" in the game
    if refinery.PrimaryPart then
        return refinery.PrimaryPart
    end
    -- Fallback: find child named "Primary"
    local primary = refinery:FindFirstChild("Primary")
    if primary and primary:IsA("BasePart") then
        return primary
    end
    warn("[Script] No Primary part found in refinery:", refinery.Name)
    return nil
end

local AutoCollectRunning = false

local function StartAutoCollect()
    if AutoCollectRunning then Log("AutoCollect already running.") return end
    AutoCollectRunning = true
    Log("AutoCollect started.")

    -- Cache primaries so we don't re-scan Buildings every single cycle
    local cachedPrimaries = {}
    local lastPlot = nil

    while CONFIG.AutoCollect do
        -- Refresh character reference once per cycle
        Character        = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

        local plot = FindPlayerPlot()
        if not plot then SafeWait(5) continue end

        -- Only re-scan Buildings if the plot changed or cache is empty
        if plot ~= lastPlot or #cachedPrimaries == 0 then
            lastPlot = plot
            cachedPrimaries = {}

            local refineries = FindRefineries(plot)
            if #refineries == 0 then SafeWait(5) continue end

            for _, refinery in ipairs(refineries) do
                local primary = GetRefineryPrimary(refinery)
                if primary then
                    table.insert(cachedPrimaries, primary)
                end
            end

            Log("Cached " .. #cachedPrimaries .. " refinery primary parts.")
        end

        -- Fire all primaries as fast as possible
        for i, primary in ipairs(cachedPrimaries) do
            if not CONFIG.AutoCollect then break end
            FireTouchInterest(primary)
            -- Tiny yield between each fire to avoid overwhelming the server
            if CONFIG.CollectDelay > 0 then
                task.wait(CONFIG.CollectDelay)
            end
        end

        -- Short pause before next full cycle
        if CONFIG.CycleDelay > 0 then
            task.wait(CONFIG.CycleDelay)
        end
    end

    AutoCollectRunning = false
    Log("AutoCollect stopped.")
end

-- ============================================================
--  FEATURE 2 – AUTO SELL
--
--  If SellOnlyAtMinPrice is enabled, checks the live GasPrice
--  value (ReplicatedStorage.GasPrice.Value) before every sell.
--  Only fires SellGas when GasPrice >= CONFIG.MinSellPrice.
-- ============================================================

local AutoSellRunning = false

local function StartAutoSell()
    if AutoSellRunning then Log("AutoSell already running.") return end
    AutoSellRunning = true
    Log("AutoSell started. Interval:", CONFIG.SellInterval .. "s")
    if CONFIG.SellOnlyAtMinPrice then
        Log("Price filter ON — will only sell at GasPrice >=", CONFIG.MinSellPrice)
    end

    while CONFIG.AutoSell do
        -- Check gas price if filter is enabled
        if CONFIG.SellOnlyAtMinPrice then
            local currentPrice = GetGasPrice()
            if currentPrice < CONFIG.MinSellPrice then
                Log(string.format("Price filter: GasPrice is %d, need >= %d — not selling.", currentPrice, CONFIG.MinSellPrice))
                -- Tick-by-tick wait, re-check every second in case price changes
                local waited = 0
                while CONFIG.AutoSell and waited < CONFIG.SellInterval do
                    waited += task.wait()
                end
                continue
            else
                Log(string.format("Price filter: GasPrice is %d >= %d — selling!", currentPrice, CONFIG.MinSellPrice))
            end
        end

        -- Fire the sell remote
        local ok, err = pcall(function()
            SellGasRemote:FireServer()
        end)
        if ok then
            Log("SellGas fired. GasPrice:", GetGasPrice())
        else
            warn("[Script] SellGas failed:", err)
        end

        -- Interval wait (tick-by-tick so toggle-off and interval changes apply fast)
        local waited = 0
        while CONFIG.AutoSell and waited < CONFIG.SellInterval do
            waited += task.wait()
        end
    end

    AutoSellRunning = false
    Log("AutoSell stopped.")
end

-- ============================================================
--  FEATURE 3 – AUTO BUY ZONES
--
--  Uses CONFIG.ZoneCosts to know what each zone costs.
--  Every cycle it reads your current Cash, then for each zone:
--    - Skip if already purchased (no Buy_Proxy present)
--    - Skip if cost is defined and you can't afford it yet
--    - Otherwise teleport to Hitbox and fire Buy_Proxy
-- ============================================================

local AutoBuyZonesRunning = false
local purchasedZones = {} -- tracks zones already bought so we never retry them

-- Trigger a proximity prompt using fireproximityprompt
local function FireProximityPrompt(prompt)
    Log("  Firing prompt:", prompt:GetFullName())
    local ok, err = pcall(fireproximityprompt, prompt)
    if ok then
        Log("  fireproximityprompt succeeded.")
    else
        warn("[Script] fireproximityprompt failed:", tostring(err))
    end
end

local function StartAutoBuyZones()
    if AutoBuyZonesRunning then Log("AutoBuyZones already running.") return end
    AutoBuyZonesRunning = true
    Log("AutoBuyZones started.")

    while CONFIG.AutoBuyZones do
        local plot = FindPlayerPlot()
        if not plot then
            Log("AutoBuyZones: plot not found, retrying in 5s...")
            SafeWait(5)
            continue
        end

        local zonesFolder = plot:FindFirstChild("Zones")
        if not zonesFolder then
            Log("AutoBuyZones: no Zones folder, retrying in 5s...")
            SafeWait(5)
            continue
        end

        local cash = GetCash()
        Log(string.format("AutoBuyZones cycle — Cash: $%s", tostring(cash)))

        -- Iterate zones in order using the ZoneCosts table
        -- Sorted by zone number so Zone0 is always attempted before Zone1 etc.
        local sortedZones = {}
        for zoneName, _ in pairs(CONFIG.ZoneCosts) do
            table.insert(sortedZones, zoneName)
        end
        table.sort(sortedZones, function(a, b)
            -- Extract number from "ZoneX" and sort numerically
            local numA = tonumber(a:match("%d+")) or 0
            local numB = tonumber(b:match("%d+")) or 0
            return numA < numB
        end)

        for _, zoneName in ipairs(sortedZones) do
            if not CONFIG.AutoBuyZones then break end

            local requiredCash = CONFIG.ZoneCosts[zoneName] or 0
            local zone = zonesFolder:FindFirstChild(zoneName)

            if not zone then
                Log("  " .. zoneName .. ": not found in Zones folder, skipping.")
                continue
            end

            -- Skip zones we've already successfully purchased this session
            if purchasedZones[zoneName] then
                Log("  " .. zoneName .. ": already purchased this session, skipping.")
                continue
            end

            local hitbox = zone:FindFirstChild("Hitbox")
            if not hitbox or not hitbox:IsA("BasePart") then
                Log("  " .. zoneName .. ": no Hitbox, skipping.")
                continue
            end

            -- If Buy_Proxy is gone the zone was already owned before the script ran
            local buyProxyObj = hitbox:FindFirstChild("Buy_Proxy")
            if not buyProxyObj then
                Log("  " .. zoneName .. ": already owned (no Buy_Proxy), marking as purchased.")
                purchasedZones[zoneName] = true
                continue
            end

            -- Resolve the actual ProximityPrompt instance
            -- Structure: Hitbox > Buy_Proxy > Buy (ProximityPrompt)
            local actualPrompt

            if buyProxyObj:IsA("ProximityPrompt") then
                -- Buy_Proxy itself is the prompt (unlikely but handled)
                actualPrompt = buyProxyObj
                Log("  " .. zoneName .. ": Buy_Proxy IS the ProximityPrompt.")
            else
                -- Method 1: direct child named "Buy" (confirmed structure)
                local buyChild = buyProxyObj:FindFirstChild("Buy")
                if buyChild and buyChild:IsA("ProximityPrompt") then
                    actualPrompt = buyChild
                    Log("  " .. zoneName .. ": found prompt as Buy_Proxy.Buy")
                end

                -- Method 2: any ProximityPrompt anywhere inside Buy_Proxy
                if not actualPrompt then
                    actualPrompt = buyProxyObj:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if actualPrompt then
                        Log("  " .. zoneName .. ": found prompt via deep search: " .. actualPrompt:GetFullName())
                    end
                end

                -- Method 3: Buy_Proxy itself might be a Part with a ProximityPrompt on it
                if not actualPrompt then
                    actualPrompt = buyProxyObj:FindFirstChildOfClass("ProximityPrompt")
                    if actualPrompt then
                        Log("  " .. zoneName .. ": found prompt as direct child of Buy_Proxy")
                    end
                end
            end

            if not actualPrompt then
                warn("[Script]   " .. zoneName .. ": no ProximityPrompt found. Path checked: " .. buyProxyObj:GetFullName())
                continue
            end

            -- Refresh cash before checking affordability
            cash = GetCash()

            if cash < requiredCash then
                Log(string.format("  %s: need $%d, have $%d — waiting.", zoneName, requiredCash, cash))
                continue
            end

            -- Can afford — buy it
            Log(string.format("  %s: buying! Cash $%d >= $%d required.", zoneName, cash, requiredCash))
            TeleportToPart(hitbox)
            task.wait(0.5)  -- let the server register you inside the hitbox
            FireProximityPrompt(actualPrompt)
            task.wait(1)    -- pause after purchase so the server can process it

            -- Mark as purchased so we never attempt this zone again
            purchasedZones[zoneName] = true
            Log("  " .. zoneName .. ": marked as purchased.")
        end

        -- Wait before next full scan cycle
        local waited = 0
        while CONFIG.AutoBuyZones and waited < CONFIG.BuyCheckInterval do
            waited += task.wait()
        end
    end

    AutoBuyZonesRunning = false
    Log("AutoBuyZones stopped.")
end

-- ============================================================
--  FEATURE 4 – AUTO STEAL
--
--  For every plot that is NOT the local player's:
--    1. Find all GUID models in Buildings where Type == "Refinery"
--    2. Check if Storage >= MaxStorage (full tank)
--    3. Find Primary > StealAtc (Attachment) > ProximityPrompt
--    4. Set HoldDuration to 0 so it fires instantly
--    5. Teleport under the attachment and fire the prompt
--    6. Teleport back to own plot's first refinery primary
-- ============================================================

local AutoStealRunning = false

-- Returns the owner name of a plot (string) using the same 3-method check as FindPlayerPlot
local function GetPlotOwner(plot)
    local config = plot:FindFirstChild("Configuration")
    if config then
        local objVal = config:FindFirstChildWhichIsA("ObjectValue")
        if objVal and objVal.Value then
            return objVal.Value.Name
        end
        local strVal = config:FindFirstChildWhichIsA("StringValue")
        if strVal and strVal.Value ~= "" then
            return strVal.Value
        end
    end
    local ownerAttr = plot:GetAttribute("Owner")
    if ownerAttr and ownerAttr ~= "" then
        return ownerAttr
    end
    return nil
end

-- Returns true if the plot belongs to another player (not local, not empty)
local function IsOtherPlayerPlot(plot)
    local owner = GetPlotOwner(plot)
    if not owner then return false end           -- unowned plot
    if owner == LocalPlayer.Name then return false end  -- our own plot
    return true
end

-- Finds all full refineries (Storage >= MaxStorage) in a plot's Buildings folder
local function FindFullRefineries(plot)
    local full = {}
    local buildings = plot:FindFirstChild("Buildings")
    if not buildings then return full end

    for _, child in ipairs(buildings:GetChildren()) do
        if child:IsA("Model") and child:GetAttribute("Type") == "Refinery" then
            local storage    = child:GetAttribute("Storage")
            local maxStorage = child:GetAttribute("MaxStorage")
            if storage and maxStorage and storage >= maxStorage and maxStorage > 0 then
                table.insert(full, child)
                Log("  Full refinery found:", child.Name,
                    string.format("(%d/%d)", storage, maxStorage))
            end
        end
    end
    return full
end

-- Gets the StealAtc attachment's world position from a refinery's Primary part
local function GetStealPosition(refinery)
    local primary = refinery:FindFirstChild("Primary")
        or (refinery.PrimaryPart)
    if not primary then return nil, nil end

    local stealAtc = primary:FindFirstChild("StealAtc")
    if not stealAtc then
        warn("[Script] No StealAtc found in:", refinery:GetFullName())
        return nil, nil
    end

    -- The ProximityPrompt lives inside the StealAtc attachment
    local prompt = stealAtc:FindFirstChildWhichIsA("ProximityPrompt")
    if not prompt then
        warn("[Script] No ProximityPrompt inside StealAtc:", stealAtc:GetFullName())
        return nil, nil
    end

    -- World position of the attachment
    local worldPos = primary.CFrame:PointToWorldSpace(stealAtc.Position)
    return worldPos, prompt
end

local function StartAutoSteal()
    if AutoStealRunning then Log("AutoSteal already running.") return end
    AutoStealRunning = true
    Log("AutoSteal started.")

    -- Cache our home position (first primary of our own plot) to return to after each steal
    local function GetHomeCFrame()
        local myPlot = FindPlayerPlot()
        if not myPlot then return nil end
        local buildings = myPlot:FindFirstChild("Buildings")
        if not buildings then return nil end
        for _, child in ipairs(buildings:GetChildren()) do
            if child:IsA("Model") and child:GetAttribute("Type") == "Refinery" then
                local primary = child:FindFirstChild("Primary") or child.PrimaryPart
                if primary then return primary.CFrame end
            end
        end
        return nil
    end

    local PlotsFolder = workspace:FindFirstChild("Plots")

    while CONFIG.AutoSteal do
        -- Refresh character
        Character        = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

        if not PlotsFolder then
            warn("[Script] AutoSteal: Plots folder missing.")
            SafeWait(5)
            continue
        end

        local stolenAny = false

        -- Loop through all plots
        for _, plot in ipairs(PlotsFolder:GetChildren()) do
            if not CONFIG.AutoSteal then break end
            if not IsOtherPlayerPlot(plot) then continue end

            local owner = GetPlotOwner(plot)
            local fullRefineries = FindFullRefineries(plot)

            if #fullRefineries == 0 then
                Log("  " .. tostring(owner) .. ": no full refineries.")
                continue
            end

            Log(string.format("  Stealing from %s — %d full refinery/refineries.", tostring(owner), #fullRefineries))

            for _, refinery in ipairs(fullRefineries) do
                if not CONFIG.AutoSteal then break end

                local stealPos, prompt = GetStealPosition(refinery)
                if not stealPos or not prompt then continue end

                -- Set HoldDuration to 0 so it fires instantly
                prompt.HoldDuration = 0

                -- Teleport under the attachment
                HumanoidRootPart.CFrame = CFrame.new(stealPos + CONFIG.StealUnderOffset)
                task.wait(0.15)

                -- Fire the proximity prompt
                local ok, err = pcall(fireproximityprompt, prompt)
                if ok then
                    Log("  Stole from " .. tostring(owner) .. " at " .. refinery.Name)
                    stolenAny = true
                else
                    warn("[Script] Steal prompt failed:", tostring(err))
                end

                task.wait(0.3)
            end
        end

        -- Return to own base after all steals
        if stolenAny then
            local homeCF = GetHomeCFrame()
            if homeCF then
                Character        = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
                HumanoidRootPart.CFrame = homeCF
                Log("Returned to home base.")
            end
        end

        -- Wait before next full steal cycle
        local waited = 0
        while CONFIG.AutoSteal and waited < CONFIG.StealCycleDelay do
            waited += task.wait()
        end
    end

    AutoStealRunning = false
    Log("AutoSteal stopped.")
end

-- ============================================================
--  DRILL SHOP
--
--  All available drills in upgrade order.
--  Use BuyDrill("Drill Name") to purchase.
--  Checks cash first and notifies if insufficient.
-- ============================================================

local DRILLS = {
    "Basic Drill",
    "Strong Drill",
    "Enhanced Drill",
    "Speed Drill",
    "Reinforced Drill",
    "Industrial Drill",
    "Double Industrial Drill",
    "Turbo Drill",
    "Mega Drill",
    "Mega Emerald Drill",
    "Hell Drill",
    "Plasma Drill",
    "Huge Long Drill",
    "Huge Plasma Drill",
    "Multi Drill",
    "Lava Drill",
    "Crystal Drill",
    "Ice Plasma Drill",
    "Diamond Drill",
    "Ruby Drill",
    "Fusion Drill",
    "Uranium Drill",
    "Radium Drill",
    "Palladium Drill",
    "Thorium Drill",
    "Barium Drill",
    "Plutonium Drill",
}

-- Drill costs table — fill these in with the actual in-game prices.
-- BuyDrill will check your cash against this before firing the remote.
-- Set to 0 for any drill you don't know the price of (will always attempt).
local DRILL_COSTS = {
    ["Basic Drill"]              = 0,
    ["Strong Drill"]             = 0,
    ["Enhanced Drill"]           = 0,
    ["Speed Drill"]              = 0,
    ["Reinforced Drill"]         = 0,
    ["Industrial Drill"]         = 0,
    ["Double Industrial Drill"]  = 0,
    ["Turbo Drill"]              = 0,
    ["Mega Drill"]               = 0,
    ["Mega Emerald Drill"]       = 0,
    ["Hell Drill"]               = 0,
    ["Plasma Drill"]             = 0,
    ["Huge Long Drill"]          = 0,
    ["Huge Plasma Drill"]        = 0,
    ["Multi Drill"]              = 0,
    ["Lava Drill"]               = 0,
    ["Crystal Drill"]            = 0,
    ["Ice Plasma Drill"]         = 0,
    ["Diamond Drill"]            = 0,
    ["Ruby Drill"]               = 0,
    ["Fusion Drill"]             = 0,
    ["Uranium Drill"]            = 0,
    ["Radium Drill"]             = 0,
    ["Palladium Drill"]          = 0,
    ["Thorium Drill"]            = 0,
    ["Barium Drill"]             = 0,
    ["Plutonium Drill"]          = 0,
}

-- Purchases a drill by name.
-- Checks cash if a cost is set, notifies on failure, fires remote on success.
local function BuyDrill(drillName)
    if not drillName or drillName == "" then
        warn("[Script] BuyDrill: no drill name provided.")
        return
    end

    local cost = DRILL_COSTS[drillName] or 0

    -- Cash check (only if a cost is set above 0)
    if cost > 0 then
        local cash = GetCash()
        if cash < cost then
            Log(string.format("BuyDrill: not enough money for %s (need $%d, have $%d)", drillName, cost, cash))
            if Library then
                Library:Notify("Not enough money", 4)
            end
            return
        end
    end

    Log("BuyDrill: purchasing", drillName)
    local ok, err = pcall(function()
        DrillPurchaseRemote:FireServer("DrillShop", drillName)
    end)

    if ok then
        Log("BuyDrill: purchased", drillName)
    else
        warn("[Script] BuyDrill: purchase failed:", tostring(err))
    end
end

-- ============================================================
--  REFINERY SHOP
--
--  All available refineries in upgrade order with real prices.
--  Use BuyRefinery("Refinery Name") to purchase.
--  Checks cash first and notifies if insufficient.
-- ============================================================

local REFINERIES = {
    "Basic Refinery",
    "Enhanced Refinery",
    "Reinforced Refinery",
    "Advanced Refinery",
    "Plasma Refinery",
    "Industrial Refinery",
    "Energy Refinery",
    "Mega Refinery",
    "Quantum Refinery",
    "Ice Refinery",
    "Hell Refinery",
    "Mega Quantum Refinery",
    "Mega Energy Refinery",
    "Lava Refinery",
    "Crystal Refinery",
    "Diamond Refinery",
    "Ruby Refinery",
    "Fusion Refinery",
    "Uranium Refinery",
    "Radium Refinery",
    "Palladium Refinery",
    "Thorium Refinery",
    "Barium Refinery",
    "Plutonium Refinery",
}

local REFINERY_COSTS = {
    ["Basic Refinery"]        = 500,
    ["Enhanced Refinery"]     = 2500,
    ["Reinforced Refinery"]   = 6250,
    ["Advanced Refinery"]     = 20000,
    ["Plasma Refinery"]       = 50000,
    ["Industrial Refinery"]   = 200000,
    ["Energy Refinery"]       = 700000,
    ["Mega Refinery"]         = 3000000,
    ["Quantum Refinery"]      = 5000000,
    ["Ice Refinery"]          = 8000000,
    ["Hell Refinery"]         = 16000000,
    ["Mega Quantum Refinery"] = 90000000,
    ["Mega Energy Refinery"]  = 150000000,
    ["Lava Refinery"]         = 360000000,
    ["Crystal Refinery"]      = 600000000,
    ["Diamond Refinery"]      = 5000000000,
    ["Ruby Refinery"]         = 50000000000,
    ["Fusion Refinery"]       = 285000000000,
    ["Uranium Refinery"]      = 625000000000,
    ["Radium Refinery"]       = 1050000000000,
    ["Palladium Refinery"]    = 2000000000000,
    ["Thorium Refinery"]      = 3375000000000,
    ["Barium Refinery"]       = 5500000000000,
    ["Plutonium Refinery"]    = 9000000000000,
}

local function BuyRefinery(refineryName)
    if not refineryName or refineryName == "" then
        warn("[Script] BuyRefinery: no refinery name provided.")
        return
    end

    local cost = REFINERY_COSTS[refineryName] or 0

    if cost > 0 then
        local cash = GetCash()
        if cash < cost then
            Log(string.format("BuyRefinery: not enough money for %s (need $%d, have $%d)", refineryName, cost, cash))
            if Library then
                Library:Notify("Not enough money", 4)
            end
            return
        end
    end

    Log("BuyRefinery: purchasing", refineryName)
    local ok, err = pcall(function()
        DrillPurchaseRemote:FireServer("RefineryShop", refineryName)
    end)

    if ok then
        Log("BuyRefinery: purchased", refineryName)
    else
        warn("[Script] BuyRefinery: purchase failed:", tostring(err))
    end
end

-- ============================================================
--  INITIALISE
-- ============================================================

LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character        = newChar
    HumanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
    Log("Character respawned.")
end)

task.spawn(function()
    SafeWait(2)
    Log("Script loaded.")
    Log("AutoCollect:", tostring(CONFIG.AutoCollect))
    Log("AutoSell:", tostring(CONFIG.AutoSell))
    Log("AutoBuyZones:", tostring(CONFIG.AutoBuyZones))

    if CONFIG.AutoCollect  then task.spawn(StartAutoCollect)  end
    if CONFIG.AutoSell     then task.spawn(StartAutoSell)     end
    if CONFIG.AutoBuyZones then task.spawn(StartAutoBuyZones) end
    if CONFIG.AutoSteal    then task.spawn(StartAutoSteal)    end
end)

-- ============================================================
--  GLOBAL EXPORTS
--
--  UI CALLBACKS – copy these into your UI script:
--
--  AutoBuyZones toggle:
--    Callback = function(Value)
--        _G.Config.AutoBuyZones = Value
--        if Value then task.spawn(_G.StartAutoBuyZones) end
--    end
--
--  AutoSell toggle:
--    Callback = function(Value)
--        _G.Config.AutoSell = Value
--        if Value then task.spawn(_G.StartAutoSell) end
--    end
--
--  AutoCollect toggle:
--    Callback = function(Value)
--        _G.Config.AutoCollect = Value
--        if Value then task.spawn(_G.StartAutoCollect) end
--    end
--
--  SellInterval slider:
--    Callback = function(Value)
--        _G.Config.SellInterval = Value
--    end
--
--  Changing a zone cost at runtime (e.g. from a textbox or input):
--    _G.Config.ZoneCosts["Zone3"] = 3000
-- ============================================================

_G.Config              = CONFIG
_G.StartAutoCollect    = StartAutoCollect
_G.StartAutoSell       = StartAutoSell
_G.StartAutoBuyZones   = StartAutoBuyZones
_G.StartAutoSteal      = StartAutoSteal
_G.BuyDrill            = BuyDrill
_G.Drills              = DRILLS
_G.DrillCosts          = DRILL_COSTS
_G.BuyRefinery         = BuyRefinery
_G.Refineries          = REFINERIES
_G.RefineryCosts       = REFINERY_COSTS

local function RedeemAllCodes()
    -- Define the list of all codes to redeem
    local codes = {
        "JUMPJUMPHAHA",
        "PRKROBY",
        "HMLNDR",
        "THX500K"
    }
    
    -- Access the RemoteEvent once beforehand to optimize the loop
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local codeRemote = replicatedStorage
        :WaitForChild("Packages")
        :WaitForChild("Knit")
        :WaitForChild("Services")
        :WaitForChild("CodeService")
        :WaitForChild("RE")
        :WaitForChild("Code")

    -- Loop through each code in the table and fire the server
    for _, code in ipairs(codes) do
        task.spawn(function()
            codeRemote:FireServer(code)
        end)
        -- Optional: Add a very short delay if the server rate-limits requests
        task.wait(0.1) 
    end
end


ThemeManager.BuiltInThemes = {
		['Default'] =         { 1, httpService:JSONDecode('{"MainColor":"242328","AccentColor":"faa614","OutlineColor":"323232","BackgroundColor":"212025","FontColor":"ffffff"}') },
        ['Gold'] =            { 2, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"373737","AccentColor":"e0d6b5","BackgroundColor":"232323","OutlineColor":"4b4b4b"}') },
        ['Gray'] =            { 2, httpService:JSONDecode('{"FontColor":"e8e8e8","MainColor":"5a5a5a","AccentColor":"5a5a5a","BackgroundColor":"080808","OutlineColor":"181818"}') },
        ['Red'] =             { 2, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"181818","AccentColor":"ff0000","BackgroundColor":"141414","OutlineColor":"1f1f1f"}') },
        ['Rose'] =            { 2, httpService:JSONDecode('{"FontColor":"e8d9e0","MainColor":"120b0e","AccentColor":"a5687a","BackgroundColor":"0a0507","OutlineColor":"1f1418"}') },
        ['Purple'] =          { 2, httpService:JSONDecode('{"FontColor":"e6e6ff","MainColor":"05000f","AccentColor":"b388ff","BackgroundColor":"0c0015","OutlineColor":"1a0033"}') },
        ['Pink'] =            { 2, httpService:JSONDecode('{"FontColor":"fdf1fe","MainColor":"0c0c0c","AccentColor":"b97ec5","BackgroundColor":"090909","OutlineColor":"080808"}') },
		['BBot'] 			= { 3, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1e1e1e","AccentColor":"7e48a3","BackgroundColor":"232323","OutlineColor":"141414"}') },
		['Fatality']		= { 4, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1e1842","AccentColor":"c50754","BackgroundColor":"191335","OutlineColor":"3c355d"}') },
		['Jester'] 			= { 5, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"242424","AccentColor":"db4467","BackgroundColor":"1c1c1c","OutlineColor":"373737"}') },
		['Mint'] 			= { 6, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"242424","AccentColor":"3db488","BackgroundColor":"1c1c1c","OutlineColor":"373737"}') },
		['Tokyo Night'] 	= { 7, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"191925","AccentColor":"6759b3","BackgroundColor":"16161f","OutlineColor":"323232"}') },
		['Ubuntu'] 			= { 8, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"3e3e3e","AccentColor":"e2581e","BackgroundColor":"323232","OutlineColor":"191919"}') },
		['Quartz'] 			= { 9, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"232330","AccentColor":"426e87","BackgroundColor":"1d1b26","OutlineColor":"27232f"}') },
	}

local Tabs = {
	Main = Window:AddTab("Main", "user"),
    Misc = Window:AddTab("Misc", "dices"),
	Settings = Window:AddTab("Settings", "settings"),
}

local TabBox = Tabs.Main:AddLeftTabbox()

local Tab1 = TabBox:AddTab("Collect", "fuel")

Tab1:AddToggle("AutoCollect", {
	Text = "Auto Collect",
	Tooltip = "Auto collect gas from all refineries in your plot.",
	DisabledTooltip = "I am disabled!",

	Default = false,
	Disabled = false,
	Visible = true,
	Risky = false,

	Callback = function(Value)
		 _G.Config.AutoCollect = Value
        if Value then
            task.spawn(_G.StartAutoCollect)
        end
	end,
})

Tab1:AddSlider("AutosellInterval", {
	Text = "Collect Delay",
	Default = 5,
	Min = 0,
	Max = 60,
	Rounding = 0,
	Callback = function(Value)
        _G.Config.CollectDelay = Value / 100
	end
})

local Tab2 = TabBox:AddTab("Sell", "trash-2")

Tab2:AddToggle("AutoSell", {
	Text = "Auto Sell",
	Tooltip = "Auto sell gas at all refineries in your plot.",
	DisabledTooltip = "I am disabled!",

	Default = false,
	Disabled = false,
	Visible = true,
	Risky = false,

	Callback = function(Value)
		_G.Config.AutoSell = Value
        if Value then
            task.spawn(_G.StartAutoSell) -- restart the loop when turned on
        end
	end,
})

Tab2:AddSlider("AutosellInterval", {
	Text = "Sell Delay",
	Default = 5,
	Min = 0,
	Max = 60,
	Rounding = 0,
	Callback = function(Value)
        _G.Config.SellInterval = Value
	end
})

-- Price filter toggle
Tab2:AddToggle("SellPriceFilter", {
    Text = "Min Price Filter",
    Default = false,
    Callback = function(Value)
        _G.Config.SellOnlyAtMinPrice = Value
    end,
})

-- Min price slider (1–15 matching the game's range)
Tab2:AddSlider("MinSellPrice", {
    Text = "Min Gas Price",
    Default = 10,
    Min = 1,
    Max = 15,
    Rounding = 0,
    Callback = function(Value)
        _G.Config.MinSellPrice = Value
    end,
})

local Tab3 = TabBox:AddTab("Steal", "hat-glasses")

Tab3:AddToggle("AutoSteal", {
    Text = "Auto Steal",
    Default = false,
    Callback = function(Value)
        _G.Config.AutoSteal = Value
        if Value then task.spawn(_G.StartAutoSteal) end
    end,
}) -- add tweens and tween speed ig

local TabBox1 = Tabs.Main:AddRightTabbox()

local BuyZones = TabBox1:AddTab("Zones", "dollar-sign")

BuyZones:AddToggle("AutoBuyZones", {
    Text = "Buy Zones",
    Tooltip = "Auto buy zones when you have enough money.",
    DisabledTooltip = "I am disabled!",

    Default = false,
    Disabled = false,
    Visible = true,
    Risky = false,

    Callback = function(Value)
        _G.Config.AutoBuyZones = Value          -- was _G.AutoBuyZones (wrong)
        if Value then
            task.spawn(_G.StartAutoBuyZones)    -- was missing entirely
        end
    end,
})

-- Drill tab example
local Tab3 = TabBox1:AddTab("Drills", "drill")
local selectedDrill = _G.Drills[1]

Tab3:AddDropdown("DrillSelect", {
    Text    = "Select Drill",
    Values  = _G.Drills,
    Default = _G.Drills[1],
    Callback = function(Value)
        selectedDrill = Value
    end,
})

Tab3:AddButton({
    Text = "Buy Drill",
    Func = function()
        _G.BuyDrill(selectedDrill)
    end,
})

local Tab3 = TabBox1:AddTab("Refinery", "factory")

local selectedRefinery = _G.Refineries[1]

Tab3:AddDropdown("RefinerySelect", {
    Text     = "Select Refinery",
    Values   = _G.Refineries,
    Default  = _G.Refineries[1],
    Callback = function(Value)
        selectedRefinery = Value
    end,
})

Tab3:AddButton({
    Text = "Buy Refinery",
    Func = function()
        _G.BuyRefinery(selectedRefinery)
    end,
})


-- ============================================================
--  CHARACTER MODIFIERS
-- ============================================================
local RunService = game:GetService("RunService")
local Players    = game:GetService("Players")

local player = Players.LocalPlayer

getgenv().WalkSpeed_Enabled = false
getgenv().WalkSpeed_Value   = 16
getgenv().JumpPower_Enabled = false
getgenv().JumpPower_Value   = 50

local originalWalkSpeed = nil
local lastHumanoid      = nil
local prevSpeedEnabled  = false
local prevJumpEnabled   = false

-- ============================================================
--  HELPERS
-- ============================================================

local function getHumanoid()
    local char = player.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function onHumanoidChanged(hum)
    if hum == lastHumanoid then return end

    -- Restore previous humanoid before switching
    if lastHumanoid and lastHumanoid.Parent then
        if originalWalkSpeed then
            lastHumanoid.WalkSpeed  = originalWalkSpeed
        end
        lastHumanoid.UseJumpPower = false
    end

    if hum then
        originalWalkSpeed = hum.WalkSpeed
    else
        originalWalkSpeed = nil
    end

    lastHumanoid = hum
end

-- ============================================================
--  HEARTBEAT
-- ============================================================
RunService.Heartbeat:Connect(function()
    local hum = getHumanoid()
    if not hum then return end

    onHumanoidChanged(hum)

    local speedEnabled = getgenv().WalkSpeed_Enabled
    local jumpEnabled  = getgenv().JumpPower_Enabled

    -- Walk speed
    if speedEnabled then
        hum.WalkSpeed = getgenv().WalkSpeed_Value
    elseif prevSpeedEnabled and not speedEnabled then
        if originalWalkSpeed then
            hum.WalkSpeed = originalWalkSpeed
        end
    end

    -- Jump power
    if jumpEnabled then
        hum.UseJumpPower = true
        hum.JumpPower    = getgenv().JumpPower_Value
    elseif prevJumpEnabled and not jumpEnabled then
        hum.UseJumpPower = false
    end

    prevSpeedEnabled = speedEnabled
    prevJumpEnabled  = jumpEnabled
end)
local Character = Tabs.Misc:AddLeftGroupbox('Character', 'user')

Character:AddToggle('WalkSpeed_Enable', {
    Text     = 'Walk Speed',
    Default  = false,
    Tooltip  = 'Enables custom walk speed',
    Callback = function(Value)
        getgenv().WalkSpeed_Enabled = Value
    end
})

Character:AddSlider('WalkSpeed_Value', {
    Text     = 'Walk Speed',
    Default  = 16,
    Min      = 0,
    Max      = 500,
    Rounding = 1,
    Compact  = false,
    Callback = function(Value)
        getgenv().WalkSpeed_Value = Value
    end
})

Character:AddToggle('JumpPower_Enable', {
    Text     = 'Jump Power',
    Default  = false,
    Tooltip  = 'Enables custom jump power',
    Callback = function(Value)
        getgenv().JumpPower_Enabled = Value
    end
})

Character:AddSlider('JumpPower_Value', {
    Text     = 'Jump Power',
    Default  = 50,
    Min      = 0,
    Max      = 500,
    Rounding = 1,
    Compact  = false,
    Callback = function(Value)
        getgenv().JumpPower_Value = Value
    end
})

local MiscFeatures = Tabs.Misc:AddRightGroupbox('Misc', 'eye-off')

MiscFeatures:AddButton({
    Text     = 'Redeem all codes',
    Tooltip  = 'Redeem all available codes',
    Callback = function()
        RedeemAllCodes()
    end
})

local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("KeybindMenuOpen", {
	Default = Library.KeybindFrame.Visible,
	Text = "Open Keybind Menu",
	Callback = function(value)
		Library.KeybindFrame.Visible = value
	end,
})
MenuGroup:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor",
	Default = true,
	Callback = function(Value)
		Library.ShowCustomCursor = Value
	end,
})
MenuGroup:AddDropdown("NotificationSide", {
	Values = { "Left", "Right" },
	Default = "Right",

	Text = "Notification Side",

	Callback = function(Value)
		Library:SetNotifySide(Value)
	end,
})
MenuGroup:AddDropdown("DPIDropdown", {
	Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
	Default = "100%",

	Text = "DPI Scale",

	Callback = function(Value)
		Value = Value:gsub("%%", "")
		local DPI = tonumber(Value)

		Library:SetDPIScale(DPI)
	end,
})

MenuGroup:AddSlider("UICornerSlider", {
	Text = "Corner Radius",
	Default = Library.CornerRadius,
	Min = 0,
	Max = 20,
	Rounding = 0,
	Callback = function(value)
		Window:SetCornerRadius(value)
	end
})

MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind")
	:AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

MenuGroup:AddButton("Unload", function()
	Library:Unload()
end)

MenuGroup:AddLabel('I LOVE MY WIFE ZEE', true)

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()

SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("coconut")
SaveManager:SetFolder("coconut/oil-empire")
SaveManager:SetSubFolder("oil-empire")

SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:AddThemeOptions(Tabs.Settings)

SaveManager:LoadAutoloadConfig()
