--[[
    [FPS] Flick — NYAN SCRIPT (Fixed Ghost ESP)
    Автор: jeffkiller231451
    Главный кодер: Fox
    Моральная поддержка: liloxa58
]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Nyan Script | Flick",
    LoadingTitle = "Nyan Script",
    LoadingSubtitle = "by jeffkiller231451 & Fox",
    ConfigurationSaving = { Enabled = true, FolderName = "NyanScript", FileName = "cfg" },
    KeySystem = false,
})

local CombatTab = Window:CreateTab("Combat", nil)
local VisualsTab = Window:CreateTab("Visuals", nil)
local ESPTab = Window:CreateTab("ESP", nil)
local InfoTab = Window:CreateTab("Info", nil)

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

-- Удаляем ESP, когда игрок выходит из игры
Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

RenderStepped:Connect(function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if not espCache[p] then createESP(p) end
            local d = espCache[p]
            
            -- ЖЁСТКАЯ ПРОВЕРКА: Игрок в игре? Живой? Есть персонаж?
            if not State.ESP or not p.Parent or not p.Character or not p.Character:FindFirstChild("HumanoidRootPart") then 
                hideESP(d) 
                continue 
            end
            
            local char = p.Character; local hum = char:FindFirstChild("Humanoid"); local root = char.HumanoidRootPart
            
            if not hum or hum.Health <= 0 then 
                hideESP(d) 
                continue 
            end

            -- Проверка, что голова и корень двигаются (а не просто в памяти висят)
            if not root.Position or root.Position.Magnitude == 0 then
                hideESP(d)
                continue
            end
            
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
CombatTab:CreateToggle({ Name = "AimBot", CurrentValue = false, Flag = "AimBot", Callback = function(v) State.AimBot = v end })
CombatTab:CreateToggle({ Name = "TriggerBot", CurrentValue = false, Flag = "TriggerBot", Callback = function(v) State.TriggerBot = v end })
CombatTab:CreateSlider({ Name = "Trigger Delay", Range = {0.01, 1}, Increment = 0.01, Suffix = " sec", CurrentValue = 0.1, Flag = "TrigDelay", Callback = function(v) State.TriggerDelay = v end })
CombatTab:CreateSlider({ Name = "Aim FOV", Range = {50, 800}, Increment = 10, Suffix = " px", CurrentValue = 250, Flag = "FOV", Callback = function(v) State.FOV = v end })
CombatTab:CreateSlider({ Name = "Max Distance", Range = {10, 1000}, Increment = 10, Suffix = " m", CurrentValue = 150, Flag = "MaxDist", Callback = function(v) State.MaxDistance = v end })

VisualsTab:CreateToggle({ Name = "Custom FOV", CurrentValue = false, Flag = "CustomFOV", Callback = function(v) State.CustomFOV = v end })
VisualsTab:CreateSlider({ Name = "FOV Value", Range = {40, 120}, Increment = 1, CurrentValue = 70, Flag = "FOVVal", Callback = function(v) State.FOVValue = v end })
VisualsTab:CreateToggle({ Name = "Crosshair", CurrentValue = true, Flag = "Crosshair", Callback = function(v) State.Crosshair = v end })
VisualsTab:CreateToggle({ Name = "Show FOV Circle", CurrentValue = false, Flag = "ShowFOV", Callback = function(v) State.ShowFOV = v end })
VisualsTab:CreateSlider({ Name = "WalkSpeed", Range = {16, 100}, Increment = 1, Suffix = " studs", CurrentValue = 16, Flag = "WS", Callback = function(v) State.WalkSpeed = v end })

ESPTab:CreateToggle({ Name = "ESP", CurrentValue = false, Flag = "ESP", Callback = function(v) State.ESP = v end })
ESPTab:CreateToggle({ Name = "Box", CurrentValue = true, Flag = "ESP_Box", Callback = function(v) State.ESP_Box = v end })
ESPTab:CreateToggle({ Name = "Skeleton", CurrentValue = true, Flag = "ESP_Skeleton", Callback = function(v) State.ESP_Skeleton = v end })
ESPTab:CreateToggle({ Name = "Health", CurrentValue = true, Flag = "ESP_Health", Callback = function(v) State.ESP_Health = v end })
ESPTab:CreateToggle({ Name = "Name", CurrentValue = true, Flag = "ESP_Name", Callback = function(v) State.ESP_Name = v end })
ESPTab:CreateToggle({ Name = "Tracers", CurrentValue = true, Flag = "ESP_Tracer", Callback = function(v) State.ESP_Tracer = v end })

InfoTab:CreateParagraph({ Title = "Информация", Content = "Автор: jeffkiller231451\nКодер: Fox\nСаппорт: liloxa58\n\nТГ: https://t.me/hatanyana" })
InfoTab:CreateButton({ Name = "Скопировать ТГ", Callback = function() setclipboard("https://t.me/hatanyana") Rayfield:Notify({Title = "Nyan", Content = "TG скопирован!", Duration = 5}) end })

RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then char.Humanoid.WalkSpeed = State.WalkSpeed end
end)

Rayfield:Notify({ Title = "Nyan Script", Content = "Загружено! Призраки удалены.", Duration = 5 })
