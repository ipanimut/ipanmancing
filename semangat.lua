-- fishit.lua
-- Clean, full-feature template for Fish It features from screenshots
-- No HTTP/webhook, no obfuscation. Replace the REMOTE placeholders with actual Remote names from the game.

-- ====== CONFIG / GLOBALS ======
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

getgenv().AutoFishing = false
getgenv().AutoFishingPerfect = false
getgenv().FishingDelay = 0.7
getgenv().AutoSell = false
getgenv().AutoSellThreshold = 2 -- default
getgenv().AutoFarm = false
getgenv().AntiAFK = true
getgenv().AntiLag = false
getgenv().FloatOnWater = false
getgenv().TradeNoDelay = false -- placeholder
getgenv().UnlimitedOxygen = false -- depends on game implementation
getgenv().InfinityJump = false
getgenv().WalkSpeed = 16

-- REMOTE placeholders (you must replace these strings with real RemoteEvent/Function names)
local REMOTE_CAST = "REMOTES_CAST_HERE"      -- e.g. "Remotes.CastRod"
local REMOTE_REEL = "REMOTES_REEL_HERE"      -- e.g. "Remotes.Reel"
local REMOTE_SELL = "REMOTES_SELL_HERE"      -- e.g. "Remotes.SellAll"
local REMOTE_TELEPORT = "REMOTES_TELEPORT_HERE" -- if game uses remotes for teleportation (optional)

-- Teleport preset coords (fill with accurate positions from your server using explorer / position read)
local Teleports = {
    ["Dock"] = CFrame.new(0,5,0),
    ["Coral Reefs"] = CFrame.new(100,5,200),
    ["Kohana"] = CFrame.new(-50,5,300),
    ["Esoteric Island"] = CFrame.new(400,5,700),
    ["Lost Isle"] = CFrame.new(-800,5,1200),
    ["Shop"] = CFrame.new(10,5,10),
}

-- simple helper to safely call possible remote (if present in ReplicatedStorage)
local function safeFireRemote(pathStr, ...)
    -- pathStr example: "Remotes.CastRod" or "RemoteFolder.SomeEvent"
    local ok, parts = pcall(function() return string.split(pathStr, ".") end)
    if not ok then return end
    local node = ReplicatedStorage
    for _,p in ipairs(parts) do
        if node and node:FindFirstChild(p) then
            node = node[p]
        else
            node = nil
            break
        end
    end
    if node and node:IsA("RemoteEvent") then
        pcall(function() node:FireServer(...) end)
    elseif node and node:IsA("RemoteFunction") then
        pcall(function() node:InvokeServer(...) end)
    end
end

-- ====== GUI (built-in, no external lib) ======
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FishIt_Clean_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 380, 0, 460)
MainFrame.Position = UDim2.new(0.03,0,0.1,0)
MainFrame.BackgroundTransparency = 0.06
MainFrame.BackgroundColor3 = Color3.fromRGB(245,245,245)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Name = "MainFrame"

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -20, 0, 36)
Title.Position = UDim2.new(0, 10, 0, 8)
Title.BackgroundTransparency = 1
Title.Text = "Fish It Script - Clean"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextColor3 = Color3.fromRGB(35,35,35)
Title.TextXAlignment = Enum.TextXAlignment.Left

local UIList = Instance.new("UIListLayout", MainFrame)
UIList.Padding = UDim.new(0,8)
UIList.HorizontalAlignment = Enum.HorizontalAlignment.Left
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0,6)
UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() end)

-- small utility for creating labeled toggles/sliders/buttons
local function makeSection(title)
    local sec = Instance.new("Frame", MainFrame)
    sec.Size = UDim2.new(1, -20, 0, 72)
    sec.BackgroundTransparency = 1
    -- label
    local lbl = Instance.new("TextLabel", sec)
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.Position = UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = title
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 14
    lbl.TextColor3 = Color3.fromRGB(40,40,40)
    return sec
end

local function makeToggle(parent, text, initial, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 34)
    frame.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0.85, 0, 1, 0)
    lbl.Position = UDim2.new(0, 6, 0, 0)
    lbl.Text = text
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextColor3 = Color3.fromRGB(30,30,30)
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0.14, -6, 0.7, 0)
    btn.Position = UDim2.new(0.86, 0, 0.15, 0)
    btn.Text = initial and "ON" or "OFF"
    btn.BackgroundColor3 = initial and Color3.fromRGB(60,180,80) or Color3.fromRGB(200,200,200)
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.TextScaled = true
    btn.MouseButton1Click:Connect(function()
        initial = not initial
        btn.Text = initial and "ON" or "OFF"
        btn.BackgroundColor3 = initial and Color3.fromRGB(60,180,80) or Color3.fromRGB(200,200,200)
        pcall(callback, initial)
    end)
    return frame, btn
end

local function makeSlider(parent, text, minv, maxv, default, step, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, 0, 0, 16)
    lbl.Position = UDim2.new(0,6,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text .. " : " .. tostring(default)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextColor3 = Color3.fromRGB(30,30,30)
    -- slider frame
    local sliderBg = Instance.new("Frame", frame)
    sliderBg.Size = UDim2.new(1, -12, 0, 12)
    sliderBg.Position = UDim2.new(0,6,0,22)
    sliderBg.BackgroundColor3 = Color3.fromRGB(230,230,230)
    sliderBg.BorderSizePixel = 0
    local sliderFill = Instance.new("Frame", sliderBg)
    sliderFill.Size = UDim2.new((default - minv)/(maxv - minv), 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(80,160,240)
    sliderFill.BorderSizePixel = 0

    local function setValueFromRatio(ratio)
        local val = minv + math.floor(((maxv-minv)*ratio)/step + 0.5)*step
        lbl.Text = text .. " : " .. tostring(val)
        sliderFill.Size = UDim2.new(ratio, 0, 1, 0)
        pcall(callback, val)
    end
    -- mouse handling
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local conn
            conn = UserInputService.InputChanged:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseMovement then
                    local rel = math.clamp((UserInputService:GetMouseLocation().X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
                    setValueFromRatio(rel)
                end
            end)
            UserInputService.InputEnded:Wait()
            conn:Disconnect()
        end
    end)
    return frame
end

-- build GUI sections
local sectionAF = makeSection("Auto Fishing")
sectionAF.Parent = MainFrame
local tf1 = makeToggle(sectionAF, "Auto Fishing Perfect Cast", false, function(v) getgenv().AutoFishingPerfect = v end)
local sliderDelay = makeSlider(sectionAF, "Auto Fishing Delay (s)", 0.2, 3, 0.7, 0.05, function(v) getgenv().FishingDelay = v end)

local sectionAS = makeSection("Auto Sell")
sectionAS.Parent = MainFrame
local thresholdBox = Instance.new("TextBox", sectionAS)
thresholdBox.Size = UDim2.new(0.4,0,0,28)
thresholdBox.Position = UDim2.new(0.02,0,0,28)
thresholdBox.Text = tostring(getgenv().AutoSellThreshold)
thresholdBox.PlaceholderText = "Threshold"
thresholdBox.ClearTextOnFocus = false
thresholdBox.FocusLost:Connect(function(enter)
    local n = tonumber(thresholdBox.Text)
    if n and n >= 0 then
        getgenv().AutoSellThreshold = n
    else
        thresholdBox.Text = tostring(getgenv().AutoSellThreshold)
    end
end)
local tf2 = makeToggle(sectionAS, "Auto Sell", false, function(v) getgenv().AutoSell = v end)

local sectionPS = makeSection("Player Set")
sectionPS.Parent = MainFrame
local tfFloat = makeToggle(sectionPS, "Float on Water", false, function(v) getgenv().FloatOnWater = v end)
local tfTrade = makeToggle(sectionPS, "Trade No Delay (placeholder)", false, function(v) getgenv().TradeNoDelay = v end)
local tfOxy = makeToggle(sectionPS, "Unlimited Oxygen (placeholder)", false, function(v) getgenv().UnlimitedOxygen = v end)
local tfInf = makeToggle(sectionPS, "Infinity Jump", false, function(v)
    getgenv().InfinityJump = v
    if v then
        LocalPlayer.CharacterAdded:Connect(function(char)
            local hum = char:WaitForChild("Humanoid")
            hum.Jumping:Connect(function() end)
        end)
    end
end)
local walkLabelContainer = Instance.new("Frame", sectionPS)
walkLabelContainer.Size = UDim2.new(1,0,0,34)
walkLabelContainer.BackgroundTransparency = 1
local walkLabel = Instance.new("TextLabel", walkLabelContainer)
walkLabel.Size = UDim2.new(0.6,0,1,0)
walkLabel.Position = UDim2.new(0,6,0,0)
walkLabel.BackgroundTransparency = 1
walkLabel.Text = "Walk Speed"
walkLabel.Font = Enum.Font.Gotham
walkLabel.TextSize = 13
walkLabel.TextColor3 = Color3.fromRGB(30,30,30)
local walkBox = Instance.new("TextBox", walkLabelContainer)
walkBox.Size = UDim2.new(0.35, -8, 1, 0)
walkBox.Position = UDim2.new(0.62, 0, 0, 0)
walkBox.Text = tostring(getgenv().WalkSpeed)
walkBox.PlaceholderText = "Speed"
walkBox.ClearTextOnFocus = false
walkBox.FocusLost:Connect(function()
    local n = tonumber(walkBox.Text)
    if n and n > 0 and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        getgenv().WalkSpeed = n
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = n
    else
        walkBox.Text = tostring(getgenv().WalkSpeed)
    end
end)

local sectionTP = makeSection("Teleport")
sectionTP.Parent = MainFrame
for name, cf in pairs(Teleports) do
    local b = Instance.new("TextButton", sectionTP)
    b.Text = "Teleport → " .. name
    b.Size = UDim2.new(1, -12, 0, 30)
    b.Position = UDim2.new(0,6,0,0)
    b.BackgroundColor3 = Color3.fromRGB(235,235,235)
    b.MouseButton1Click:Connect(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character:PivotTo(cf)
        end
    end)
end

local sectionEv = makeSection("Event / Misc")
sectionEv.Parent = MainFrame
local tfAFEvent = makeToggle(sectionEv, "Auto Farm Event (template)", false, function(v) getgenv().AutoFarm = v end)
local tfAntiAFK = makeToggle(sectionEv, "Anti AFK", getgenv().AntiAFK, function(v) getgenv().AntiAFK = v end)
local tfAntiLag = makeToggle(sectionEv, "Anti Lag (disable particles)", false, function(v) 
    getgenv().AntiLag = v
    -- toggle done in loop below
end)

-- small footer
local footer = Instance.new("TextLabel", MainFrame)
footer.Size = UDim2.new(1, -20, 0, 20)
footer.Position = UDim2.new(0, 10, 1, -28)
footer.BackgroundTransparency = 1
footer.Text = "Clean Script — replace REMOTE_* with actual names for full automation"
footer.Font = Enum.Font.Gotham
footer.TextSize = 12
footer.TextColor3 = Color3.fromRGB(100,100,100)
footer.TextXAlignment = Enum.TextXAlignment.Left

-- ===== BACKEND WORKERS =====

-- Anti AFK
if getgenv().AntiAFK then
    spawn(function()
        local vu = game:GetService("VirtualUser")
        LocalPlayer.Idled:Connect(function()
            vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end)
    end)
end

-- Infinity jump handler
UserInputService.InputBegan:Connect(function(inp, processed)
    if processed then return end
    if getgenv().InfinityJump and inp.KeyCode == Enum.KeyCode.Space then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

-- Anti-lag: toggle particle/trail emitters
spawn(function()
    while true do
        if getgenv().AntiLag then
            for _,v in ipairs(workspace:GetDescendants()) do
                pcall(function()
                    if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") then
                        v.Enabled = false
                    end
                    if v:IsA("Decal") or v:IsA("Texture") then
                        v.Transparency = math.clamp(v.Transparency or 0, 0.7, 1)
                    end
                end)
            end
        end
        task.wait(3)
    end
end)

-- Auto Sell by threshold: (attempt inventory check, fallback to sell button)
local function trySellAll()
    -- prefer using REMOTE_SELL if provided
    if REMOTE_SELL and REMOTE_SELL ~= "REMOTES_SELL_HERE" then
        safeFireRemote(REMOTE_SELL)
        return
    end
    -- fallback: attempt to find a Sell button in PlayerGui
    pcall(function()
        for _,v in ipairs(PlayerGui:GetDescendants()) do
            if v:IsA("TextButton") or v:IsA("ImageButton") then
                local txt = ""
                pcall(function() txt = v.Text or "" end)
                if txt and (txt:lower():find("sell") or txt:lower():find("jual")) then
                    pcall(function() v:Activate() end)
                    task.wait(0.2)
                    pcall(function() v:MouseButton1Click() end)
                end
            end
        end
    end)
end

-- Helper: count fish in inventory (game-specific - replace with actual logic)
local function getFishCount()
    -- default fallback: try reading a GUI counter e.g. "Jual 65 Ikan" on screen
    local count = 0
    pcall(function()
        for _,v in ipairs(PlayerGui:GetDescendants()) do
            if v:IsA("TextLabel") then
                local s = v.Text
                if type(s) == "string" and s:lower():find("jual") and s:match("%d+") then
                    count = tonumber(s:match("%d+")) or count
                end
            end
        end
    end)
    return count
end

-- AutoFishing worker (scans GUI for "Reel/Perfect" or uses remotes if set)
spawn(function()
    while true do
        if getgenv().AutoFishing then
            -- if REMOTE_CAST/REMOTE_REEL provided, try to use them (more reliable)
            if (REMOTE_CAST ~= "REMOTES_CAST_HERE") and (REMOTE_REEL ~= "REMOTES_REEL_HERE") then
                -- example usage: call cast then wait then reel - adjust per actual remote signature
                pcall(function() safeFireRemote(REMOTE_CAST) end)
                task.wait(getgenv().FishingDelay)
                pcall(function() safeFireRemote(REMOTE_REEL) end)
                task.wait(getgenv().FishingDelay)
            else
                -- fallback GUI scanning: detect "Reel", "Perfect", "Hook", etc and click
                pcall(function()
                    for _,v in ipairs(PlayerGui:GetDescendants()) do
                        if v:IsA("TextButton") or v:IsA("ImageButton") or v:IsA("TextLabel") then
                            local txt = ""
                            pcall(function() txt = v.Text or "" end)
                            if txt and (txt:lower():find("perfect") or txt:lower():find("reel") or txt:lower():find("hook") or txt:lower():find("catch") or txt:lower():find("tarik")) then
                                -- Perfect cast: if enabled, try click immediately
                                if getgenv().AutoFishingPerfect then
                                    -- try Activate / click or send keyboard space press
                                    pcall(function() if v.Activated then v:Activate() end end)
                                    pcall(function() if v.MouseButton1Click then v:MouseButton1Click() end end)
                                    -- send a quick keypress as alternative
                                    pcall(function()
                                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                                        task.wait(0.03)
                                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                                    end)
                                else
                                    pcall(function() if v.Activated then v:Activate() end end)
                                end
                                task.wait(getgenv().FishingDelay)
                            end
                        end
                    end
                end)
            end
            -- after loop, check auto-sell by threshold
            if getgenv().AutoSell then
                local c = getFishCount()
                if c >= (tonumber(getgenv().AutoSellThreshold) or 0) then
                    trySellAll()
                end
            end
        end
        task.wait(0.12)
    end
end)

-- AutoFarm Event template: teleport around and fish; game-specific logic to be implemented if needed
spawn(function()
    while true do
        if getgenv().AutoFarm then
            -- simple implementation: cycle teleports and attempt fishing
            for name, cf in pairs(Teleports) do
                if not getgenv().AutoFarm then break end
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    pcall(function() LocalPlayer.Character:PivotTo(cf) end)
                end
                -- attempt few casts at each spot using remote or gui fallback
                for i=1,3 do
                    if not getgenv().AutoFarm then break end
                    if REMOTE_CAST ~= "REMOTES_CAST_HERE" then
                        pcall(function() safeFireRemote(REMOTE_CAST) end)
                    else
                        -- try to "click" cast buttons
                        pcall(function()
                            for _,v in ipairs(PlayerGui:GetDescendants()) do
                                if v:IsA("TextButton") and (v.Text:lower():find("cast") or v.Text:lower():find("lempar") or v.Text:lower():find("tebar")) then
                                    pcall(function() v:Activate() end)
                                end
                            end
                        end)
                    end
                    task.wait(getgenv().FishingDelay + 0.4)
                end
            end
        end
        task.wait(1)
    end
end)

-- Infinity jump enforcement (robust)
spawn(function()
    while true do
        if getgenv().InfinityJump then
            local char = LocalPlayer.Character
            if char and char:FindFirstChildOfClass("Humanoid") then
                local hum = char:FindFirstChildOfClass("Humanoid")
                hum.JumpPower = 60
            end
        else
            local char = LocalPlayer.Character
            if char and char:FindFirstChildOfClass("Humanoid") then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum.WalkSpeed ~= getgenv().WalkSpeed then hum.WalkSpeed = getgenv().WalkSpeed end
            end
        end
        task.wait(1)
    end
end)

-- Keep WalkSpeed applied
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:WaitForChild("Humanoid")
    if hum and getgenv().WalkSpeed then
        hum.WalkSpeed = getgenv().WalkSpeed
    end
end)

-- Quick chat command for teleport: /tp Name
LocalPlayer.Chatted:Connect(function(msg)
    local s = tostring(msg)
    if s:sub(1,3):lower() == "/tp" then
        local name = s:sub(5)
        if Teleports[name] then
            pcall(function() LocalPlayer.Character:PivotTo(Teleports[name]) end)
        end
    end
end)

-- final print
print("FishIt Clean script loaded. Edit REMOTE_* and Teleports table to match game specifics.")
