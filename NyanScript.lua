--[[
    [FPS] Flick — NYAN SCRIPT (Custom Drawing UI)
    Автор: jeffkiller231451
    Главный кодер: Fox
    Моральная поддержка: liloxa58
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ==== СОСТОЯНИЕ ====
local State = {
    AimBot = false,
    TriggerBot = false,
    TriggerDelay = 0.1,
    FOV = 250,
    MaxDistance = 150,
    WalkSpeed = 16,
    ESP = false,
    ESP_Box = true,
    ESP_Skeleton = true,
    ESP_Health = true,
    ESP_Name = true,
    BHop = false,
    BHopSpeed = 35,
}

-- ==== UI ====
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NyanScriptUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 600, 0, 400)
MainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 150, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -150, 1, 0)
Content.Position = UDim2.new(0, 150, 0, 0)
Content.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Content.BorderSizePixel = 0
Content.Parent = MainFrame

local function CreateTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = name
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 16
    btn.Parent = Sidebar
    return btn
end

local function CreateToggle(parent, text, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 30)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 50, 0, 25)
    toggleBtn.Position = UDim2.new(1, -50, 0, 0)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    toggleBtn.Text = default and "ON" or "OFF"
    toggleBtn.Parent = frame

    local state = default
    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        toggleBtn.Text = state and "ON" or "OFF"
        toggleBtn.BackgroundColor3 = state and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
        callback(state)
    end)
    return frame
end

-- Создаём вкладки
local tabCombat = CreateTab("Combat")
local tabVisuals = CreateTab("Visuals")
local tabESP = CreateTab("ESP")

-- Combat Content
local combatFrame = Instance.new("ScrollingFrame")
combatFrame.Size = UDim2.new(1, 0, 1, 0)
combatFrame.BackgroundTransparency = 1
combatFrame.Parent = Content
CreateToggle(combatFrame, "AimBot", false, function(v) State.AimBot = v end)
CreateToggle(combatFrame, "TriggerBot", false, function(v) State.TriggerBot = v end)

-- Visuals Content
local visualsFrame = Instance.new("ScrollingFrame")
visualsFrame.Size = UDim2.new(1, 0, 1, 0)
visualsFrame.BackgroundTransparency = 1
visualsFrame.Parent = Content
visualsFrame.Visible = false
CreateToggle(visualsFrame, "BHop", false, function(v) State.BHop = v end)

-- ESP Content
local espFrame = Instance.new("ScrollingFrame")
espFrame.Size = UDim2.new(1, 0, 1, 0)
espFrame.BackgroundTransparency = 1
espFrame.Parent = Content
espFrame.Visible = false
CreateToggle(espFrame, "ESP", false, function(v) State.ESP = v end)
CreateToggle(espFrame, "ESP Box", true, function(v) State.ESP_Box = v end)
CreateToggle(espFrame, "ESP Skeleton", true, function(v) State.ESP_Skeleton = v end)
CreateToggle(espFrame, "ESP Health", true, function(v) State.ESP_Health = v end)
CreateToggle(espFrame, "ESP Name", true, function(v) State.ESP_Name = v end)

-- Переключение вкладок
local tabs = { {btn = tabCombat, frame = combatFrame}, {btn = tabVisuals, frame = visualsFrame}, {btn = tabESP, frame = espFrame} }
for _, tab in ipairs(tabs) do
    tab.btn.MouseButton1Click:Connect(function()
        for _, t in ipairs(tabs) do
            t.frame.Visible = (t == tab)
            t.btn.BackgroundColor3 = (t == tab) and Color3.fromRGB(50, 50, 50) or Color3.fromRGB(30, 30, 30)
        end
    end)
end
tabCombat.BackgroundColor3 = Color3.fromRGB(50, 50, 50)

-- ==== ЛОГИКА ЧИТОВ ====

-- Watermark
local watermark = Drawing.new("Text")
watermark.Text = "Nyan Script | jeffkiller231451 & Fox"
watermark.Size = 18
watermark.Color = Color3.fromRGB(255, 50, 50)
watermark.Outline = true
watermark.Position = Vector2.new(15, 15)
watermark.Visible = true

-- AimBot / Trigger
local function getClosestPlayer()
    local closest = nil
    local shortest = State.MaxDistance
    local center = Camera.ViewportSize / 2
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local head = p.Character.Head
            local dist = (Camera.CFrame.Position - head.Position).Magnitude
            if dist < shortest then
                local sp, on = Camera:WorldToViewportPoint(head.Position)
                if on and (Vector2.new(sp.X, sp.Y) - center).Magnitude < State.FOV then
                    shortest = dist
                    closest = head
                end
            end
        end
    end
    return closest
end

local lastTrigger = 0
RunService.RenderStepped:Connect(function()
    if not State.AimBot and not State.TriggerBot then return end
    local target = getClosestPlayer()
    if not target then return end

    if State.AimBot and mousemoverel then
        local sp = Camera:WorldToViewportPoint(target.Position)
        mousemoverel(sp.X - Camera.ViewportSize.X / 2, sp.Y - Camera.ViewportSize.Y / 2)
    end
    if State.TriggerBot and tick() - lastTrigger > State.TriggerDelay and mouse1click then
        mouse1click()
        lastTrigger = tick()
    end
end)

-- BHop
RunService.RenderStepped:Connect(function()
    if not State.BHop then return end
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") and char.Humanoid.FloorMaterial ~= Enum.Material.Air then
        char.Humanoid.Jump = true
    end
end)

-- ESP
local espCache = {}
local function createESP(p)
    if espCache[p] then return end
    local d = {
        box = Drawing.new("Square"),
        name = Drawing.new("Text"),
        healthBg = Drawing.new("Square"),
        health = Drawing.new("Square")
    }
    d.box.Thickness = 1.5; d.box.Filled = false
    d.name.Size = 14; d.name.Center = true; d.name.Outline = true
    d.healthBg.Filled = true; d.healthBg.Color = Color3.fromRGB(0,0,0)
    d.health.Filled = true; d.health.Color = Color3.fromRGB(0,255,0)
    espCache[p] = d
end

RunService.RenderStepped:Connect(function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            if not espCache[p] then createESP(p) end
            local d = espCache[p]
            if State.ESP then
                local root = p.Character.HumanoidRootPart
                local sp, on = Camera:WorldToViewportPoint(root.Position)
                if on then
                    local dist = (Camera.CFrame.Position - root.Position).Magnitude
                    local size = Vector2.new(2000/dist, 3000/dist)
                    local pos = Vector2.new(sp.X - size.X/2, sp.Y - size.Y/2)
                    d.box.Size = size; d.box.Position = pos; d.box.Visible = true
                    d.name.Text = p.Name; d.name.Position = Vector2.new(sp.X, pos.Y - 18); d.name.Visible = true
                else
                    d.box.Visible = false; d.name.Visible = false
                end
            else
                d.box.Visible = false; d.name.Visible = false
            end
        end
    end
end)

-- WalkSpeed
RunService.Heartbeat:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = State.WalkSpeed
    end
end)
