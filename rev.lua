-- Fish It Simple Script
-- GUI sederhana dengan Auto Fish, Auto Sell, Teleport

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Teleports = {
    ["Spawn"] = Vector3.new(0, 5, 0),
    ["Shop"] = Vector3.new(50, 5, 0),
    ["Fishing Spot"] = Vector3.new(100, 5, 0)
}

-- Buat GUI
local ScreenGui = Instance.new("ScreenGui", Player:WaitForChild("PlayerGui"))
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 200, 0, 250)
Frame.Position = UDim2.new(0, 50, 0, 50)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

-- Tombol Auto Fish
local autoFish = false
local FishBtn = Instance.new("TextButton", Frame)
FishBtn.Size = UDim2.new(1, -10, 0, 40)
FishBtn.Position = UDim2.new(0, 5, 0, 10)
FishBtn.Text = "Auto Perfect Fishing: OFF"
FishBtn.MouseButton1Click:Connect(function()
    autoFish = not autoFish
    FishBtn.Text = "Auto Perfect Fishing: " .. (autoFish and "ON" or "OFF")
end)

-- Tombol Auto Sell
local autoSell = false
local SellBtn = Instance.new("TextButton", Frame)
SellBtn.Size = UDim2.new(1, -10, 0, 40)
SellBtn.Position = UDim2.new(0, 5, 0, 60)
SellBtn.Text = "Auto Sell: OFF"
SellBtn.MouseButton1Click:Connect(function()
    autoSell = not autoSell
    SellBtn.Text = "Auto Sell: " .. (autoSell and "ON" or "OFF")
end)

-- Dropdown Teleport
local TeleBtn = Instance.new("TextButton", Frame)
TeleBtn.Size = UDim2.new(1, -10, 0, 40)
TeleBtn.Position = UDim2.new(0, 5, 0, 110)
TeleBtn.Text = "Teleport: Spawn"
TeleBtn.MouseButton1Click:Connect(function()
    local choice = "Shop" -- contoh default
    if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        Player.Character.HumanoidRootPart.CFrame = CFrame.new(Teleports[choice])
    end
end)

-- Loop Auto
task.spawn(function()
    while task.wait(1) do
        if autoFish then
            -- isi mekanik auto perfect fishing di sini
            print("Fishing automatically...")
        end
        if autoSell then
            -- isi mekanik auto sell di sini
            print("Selling automatically...")
        end
    end
end)
