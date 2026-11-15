--[[
    [FPS] Flick — NYAN SCRIPT (Obsidian UI)
    Автор: jeffkiller231451
    Главный кодер: Fox
    Моральная поддержка: liloxa58
]]

local Obsidian = loadstring(game:HttpGet("https://raw.githubusercontent.com/mstudio45/Obsidian/main/Obsidian.lua"))()

local Window = Obsidian:CreateWindow({
    Title = "Nyan Script | Flick",
    Subtitle = "by jeffkiller231451 & Fox",
    TabWidth = 160,
    Size = UDim2.fromOffset(830, 480),
    Theme = "Dark",
    KeySystem = false,
})

-- ==== ВКЛАДКИ ====
local MainTab = Window:Tab("Главная")
local CombatTab = Window:Tab("Основные")
local AuthorsTab = Window:Tab("Авторы")
local SettingsTab = Window:Tab("Настройки")
local AddonsTab = Window:Tab("Аддоны")

-- ==== СОСТОЯНИЕ ====
local State = {
    AimBot = false,
    TriggerBot = false,
    TriggerDelay = 0.1,
    FOV = 250,
    MaxDistance = 150,
    WalkSpeed = 16,
    CustomFOV = false,
    FOVValue = 70,
    ESP = false,
    ESP_Box = true,
    ESP_Skeleton = true,
    ESP_Health = true,
    ESP_Name = true,
    ESP_Tracer = true,
    Crosshair = true,
    ShowFOV = false,
    BHop = false,
    BHopSpeed = 35,
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RenderStepped = RunService.RenderStepped

-- ==== ВОДЯНОЙ ЗНАК ====
local watermark = Drawing.new("Text")
watermark.Text = "Nyan Script | jeffkiller231451 & Fox"
watermark.Size = 18
watermark.Color = Color3.fromRGB(255, 50, 50)
watermark.Outline = true
watermark.Position = Vector2.new(15, 15)
watermark.Visible = true

-- ==== ПОИСК ЦЕЛИ ====
local function getClosestPlayer()
    local closest = nil
    local shortestWorldDist = State.MaxDistance 
    local center = Camera.ViewportSize / 2
    local camPos = Camera.CFrame.Position

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Parent and p.Character and p.Character:FindFirstChild("Head") then
            local char = p.Character
            local hum = char:FindFirstChild("Humanoid")
            if not hum or hum.Health <= 0 then continue end
            
            local head = char.Head
            local worldDist = (camPos - head.Position).Magnitude
            if worldDist > shortestWorldDist then continue end

            local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                if screenDist < State.FOV then
                    shortestWorldDist = worldDist
                    closest = head
                end
            end
        end
    end
    return closest
end

-- ==== ПРОВЕРКА СТЕН ====
local function isVisible(target)
    if not target then return false end
    local camPos = Camera.CFrame.Position
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local dir = (target.Position - camPos)
    local result = workspace:Raycast(camPos, dir, rayParams)
    
    if result and (result.Instance == target or result.Instance:IsDescendantOf(target.Parent)) then
        return true
    end
    return false
end

-- ==== АИМБОТ И ТРИГГЕР ====
local lastTriggerTime = 0

RenderStepped:Connect(function()
    if not State.AimBot and not State.TriggerBot then return end
    local target = getClosestPlayer()
    if not target then return end
    
    if State.AimBot then
        if mousemoverel then
            local screenPos = Camera:WorldToViewportPoint(target.Position)
            local center = Camera.ViewportSize / 2
            mousemoverel(screenPos.X - center.X, screenPos.Y - center.Y)
        end
    end
    
    if State.TriggerBot then
        if isVisible(target) then
            if tick() - lastTriggerTime >= State.TriggerDelay then
                if mouse1click then mouse1click() end
                lastTriggerTime = tick()
            end
        end
    end
end)

-- ==== FOV CHANGER ====
RenderStepped:Connect(function()
    if State.CustomFOV then
        if Camera.FieldOfView ~= State.FOVValue then
            Camera.FieldOfView = State.FOVValue
        end
    end
end)

-- ==== BUNNY HOP ====
local lastJumpTime = 0

RenderStepped:Connect(function()
    if not State.BHop then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local hum = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    
    if hum and root then
        if hum.FloorMaterial ~= Enum.Material.Air then
            local moveDir = hum.MoveDirection
            if moveDir.Magnitude > 0 then
                if tick() - lastJumpTime > 0.1 then
                    root.Velocity = Vector3.new(moveDir.X * State.BHopSpeed, root.Velocity.Y + 50, moveDir.Z * State.BHopSpeed)
                    hum.Jump = true
                    lastJumpTime = tick()
                end
            end
        end
    end
end)

-- ==== ПРИЦЕЛ ====
local crosshairDot = Drawing.new("Circle")
crosshairDot.Thickness = 2
crosshairDot.Radius = 3
crosshairDot.Filled = true
crosshairDot.Visible = false

local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1
fovCircle.Filled = false
fovCircle.Visible = false

RenderStepped:Connect(function()
    local center = Camera.ViewportSize / 2
    crosshairDot.Color = Color3.fromRGB(255, 50, 50)
    if State.Crosshair then
        crosshairDot.Position = center; crosshairDot.Visible = true
    else
        crosshairDot.Visible = false
    end

    if State.ShowFOV then
        fovCircle.Position = center; fovCircle.Radius = State.FOV; fovCircle.Visible = true
    else
        fovCircle.Visible = false
    end
end)

-- ==== ESP ====
local espCache = {}
local function createESP(player)
    if espCache[player] then return end
    local d = {
        box = Drawing.new("Square"), health = Drawing.new("Square"), healthBg = Drawing.new("Square"),
        name = Drawing.new("Text"), tracer = Drawing.new("Line"),
        skeleton = { Head = Drawing.new("Line"), Torso = Drawing.new("Line"), LeftArm = Drawing.new("Line"), RightArm = Drawing.new("Line"), LeftLeg = Drawing.new("Line"), RightLeg = Drawing.new("Line") }
    }
    d.box.Thickness = 1.5; d.box.Filled = false
    d.healthBg.Filled = true; d.healthBg.Color = Color3.fromRGB(0, 0, 0); d.health.Filled = true; d.health.Color = Color3.fromRGB(0, 255, 0)
    d.name.Size = 14; d.name.Center = true; d.name.Outline = true; d.name.Color = Color3.fromRGB(255, 255, 255)
    d.tracer.Thickness = 1.5
    for _, line in pairs(d.skeleton) do line.Thickness = 1.5 end
    espCache[player] = d
end

local function hideESP(d)
    d.box.Visible = false; d.health.Visible = false; d.healthBg.Visible = false; d.name.Visible = false; d.tracer.Visible = false
    for _, line in pairs(d.skeleton) do line.Visible = false end
end

local function removeESP(player)
    if espCache[player] then
        local d = espCache[player]
        d.box:Remove(); d.health:Remove(); d.healthBg:Remove(); d.name:Remove(); d.tracer:Remove()
        for _, line in pairs(d.skeleton) do line:Remove() end
        espCache[player] = nil
    end
end

Players.PlayerRemoving:Connect(function(player) removeESP(player) end)

RenderStepped:Connect(function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if not espCache[p] then createESP(p) end
            local d = espCache[p]
            
            if not State.ESP or not p.Parent or not p.Character or not p.Character:FindFirstChild("HumanoidRootPart") then 
                hideESP(d) continue 
            end
            
            local char = p.Character; local hum = char:FindFirstChild("Humanoid"); local root = char.HumanoidRootPart
            
            if not hum or hum.Health <= 0 then hideESP(d) continue end
            if not root.Position or root.Position.Magnitude == 0 then hideESP(d) continue end
            
            local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            if onScreen then
                local dist = (Camera.CFrame.Position - root.Position).Magnitude
                local boxSize = Vector2.new(2000 / dist, 3000 / dist)
                local boxPos = Vector2.new(screenPos.X - boxSize.X / 2, screenPos.Y - boxSize.Y / 2)
                
                if State.ESP_Box then d.box.Size = boxSize; d.box.Position = boxPos; d.box.Visible = true else d.box.Visible = false end
                if State.ESP_Name then d.name.Text = p.Name .. " [" .. math.floor(dist) .. "m]"; d.name.Position = Vector2.new(screenPos.X, boxPos.Y - 18); d.name.Visible = true else d.name.Visible = false end
                if State.ESP_Tracer then d.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y); d.tracer.To = Vector2.new(screenPos.X, screenPos.Y); d.tracer.Visible = true else d.tracer.Visible = false end
                if State.ESP_Health then
                    local hPercent = hum.Health / hum.MaxHealth; local hHeight = boxSize.Y * hPercent
                    d.healthBg.Size = Vector2.new(3, boxSize.Y); d.healthBg.Position = Vector2.new(boxPos.X - 6, boxPos.Y)
                    d.health.Size = Vector2.new(3, hHeight); d.health.Position = Vector2.new(boxPos.X - 6, boxPos.Y + (boxSize.Y - hHeight))
                    d.healthBg.Visible = true; d.health.Visible = true
                else d.healthBg.Visible = false; d.health.Visible = false end
                if State.ESP_Skeleton then
                    local function getPos(n) local part = char:FindFirstChild(n); if part then local pos, on = Camera:WorldToViewportPoint(part.Position); if on then return Vector2.new(pos.X, pos.Y) end end return nil end
                    local head, torso = getPos("Head"), getPos("UpperTorso") or getPos("Torso")
                    local lArm, rArm = getPos("LeftUpperArm") or getPos("Left Arm"), getPos("RightUpperArm") or getPos("Right Arm")
                    local lLeg, rLeg = getPos("LeftUpperLeg") or getPos("Left Leg"), getPos("RightUpperLeg") or getPos("Right Leg")
                    local function setLine(l, p1, p2) if p1 and p2 then l.From = p1; l.To = p2; l.Visible = true else l.Visible = false end end
                    setLine(d.skeleton.Head, head, torso); setLine(d.skeleton.LeftArm, lArm, torso); setLine(d.skeleton.RightArm, rArm, torso)
                    setLine(d.skeleton.LeftLeg, lLeg, torso); setLine(d.skeleton.RightLeg, rLeg, torso); setLine(d.skeleton.Torso, lLeg, rLeg)
                else for _, line in pairs(d.skeleton) do line.Visible = false end end
            else hideESP(d) end
        end
    end
end)

-- ==== UI ====

-- Главная
local MainGroup = MainTab:Group("Список изменений")
MainGroup:Paragraph("03.10.2026\n[+] Added Anti Noise\n[+] Added Anti Crusher\n[+] Added Destroy Noise TV\n[+] Added trash Esp\n[+] Added more things on 'Ignore list'\n[+] Added auto parry Timoty\n[+] DO NOT ACTIVE THIS (beta)\n[+] Added Enable move tabs or no\n[+] Added Notify Structures")

-- Основные (Combat + ESP)
local CombatGroup = CombatTab:Group("Combat")
CombatGroup:Toggle("AimBot", false, function(v) State.AimBot = v end)
CombatGroup:Toggle("TriggerBot", false, function(v) State.TriggerBot = v end)
CombatGroup:Slider("Trigger Delay", 0.01, 1, 0.1, function(v) State.TriggerDelay = v end)
CombatGroup:Slider("Aim FOV", 50, 800, 250, function(v) State.FOV = v end)
CombatGroup:Slider("Max Distance", 10, 1000, 150, function(v) State.MaxDistance = v end)
CombatGroup:Toggle("BHop", false, function(v) State.BHop = v end)
CombatGroup:Slider("BHop Speed", 16, 100, 35, function(v) State.BHopSpeed = v end)

local ESPGroup = CombatTab:Group("ESP")
ESPGroup:Toggle("ESP", false, function(v) State.ESP = v end)
ESPGroup:Toggle("ESP Box", true, function(v) State.ESP_Box = v end)
ESPGroup:Toggle("ESP Skeleton", true, function(v) State.ESP_Skeleton = v end)
ESPGroup:Toggle("ESP Health", true, function(v) State.ESP_Health = v end)
ESPGroup:Toggle("ESP Name", true, function(v) State.ESP_Name = v end)
ESPGroup:Toggle("ESP Tracer", true, function(v) State.ESP_Tracer = v end)

-- Настройки (Visuals)
local VisGroup = SettingsTab:Group("Visuals")
VisGroup:Toggle("Custom FOV", false, function(v) State.CustomFOV = v end)
VisGroup:Slider("FOV Value", 40, 120, 70, function(v) 
    State.FOVValue = v 
    if State.CustomFOV then Camera.FieldOfView = v end
end)
VisGroup:Toggle("Crosshair", true, function(v) State.Crosshair = v end)
VisGroup:Toggle("Show FOV Circle", false, function(v) State.ShowFOV = v end)
VisGroup:Slider("WalkSpeed", 16, 100, 16, function(v) State.WalkSpeed = v end)

-- Авторы
local AuthorsGroup = AuthorsTab:Group("Информация")
AuthorsGroup:Paragraph("Автор: jeffkiller231451\nКодер: Fox\nСаппорт: liloxa58\n\nТГ: https://t.me/hatanyana\nДС: https://discord.gg/7bxaxuRjbg")
AuthorsGroup:Button("Скопировать ТГ", function() setclipboard("https://t.me/hatanyana") Obsidian:Notify("Nyan", "TG скопирован!") end)
AuthorsGroup:Button("Скопировать ДС", function() setclipboard("https://discord.gg/7bxaxuRjbg") Obsidian:Notify("Nyan", "Discord скопирован!") end)

-- Аддоны
local AddonsGroup = AddonsTab:Group("Аддоны")
AddonsGroup:Paragraph("Тут будут дополнительные модули. Пока пусто, блять.")

-- ==== HEARTBEAT ДЛЯ WALKSPEED ====
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then char.Humanoid.WalkSpeed = State.WalkSpeed end
end)

-- ==== УВЕДОМЛЕНИЕ О ЗАГРУЗКЕ ====
Obsidian:Notify("Nyan Script", "Загружено! ДС и ТГ в Info.")
