--[[
    [FPS] Flick — NYAN SCRIPT (Full)
    Автор: jeffkiller231451
    Главный кодер: Fox
    Моральная поддержка: liloxa58
    Telegram: https://t.me/hatanyana
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
local ColorTab = Window:CreateTab("Colors", nil)
local InfoTab = Window:CreateTab("Info", nil)

local State = {
    AimBot = false,
    TriggerBot = false,
    FOV = 250,
    MaxDistance = 150,
    WalkSpeed = 16,
    
    ESP = false,
    ESP_Box = true,
    ESP_Skeleton = true,
    ESP_Health = true,
    ESP_Name = true,
    ESP_Tracer = true,
    
    Crosshair = true,
    ShowFOV = true,
    
    Color_Box = {255, 255, 255},
    Color_Skeleton = {255, 255, 255},
    Color_Tracer = {255, 0, 0},
    Color_FOV = {255, 255, 255},
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
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
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

-- ==== ПРОВЕРКА СТЕН (WALLCHECK) ====
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
RenderStepped:Connect(function()
    if not State.AimBot and not State.TriggerBot then return end
    
    local target = getClosestPlayer()
    if not target then return end
    
    -- АИМ (Крутим камеру)
    if State.AimBot then
        if mousemoverel then
            local screenPos = Camera:WorldToViewportPoint(target.Position)
            local center = Camera.ViewportSize / 2
            mousemoverel(screenPos.X - center.X, screenPos.Y - center.Y)
        else
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        end
    end
    
    -- ТРИГГЕР (Стреляем только если нет стены)
    if State.TriggerBot then
        if isVisible(target) then
            if mouse1click then
                mouse1click()
            elseif mouse1press and mouse1release then
                mouse1press()
                task.wait(0.05)
                mouse1release()
            end
        end
    end
end)

-- ==== ПРИЦЕЛ И FOV ====
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
    fovCircle.Color = Color3.fromRGB(State.Color_FOV[1], State.Color_FOV[2], State.Color_FOV[3])
    
    if State.Crosshair then
        crosshairDot.Position = center
        crosshairDot.Visible = true
        fovCircle.Position = center
        fovCircle.Radius = State.FOV
        fovCircle.Visible = State.ShowFOV
    else
        crosshairDot.Visible = false
        fovCircle.Visible = false
    end
end)

-- ==== ESP ====
local espCache = {}

local function createESP(player)
    if espCache[player] then return end
    if not Drawing then return end
    
    local d = {
        box = Drawing.new("Square"),
        health = Drawing.new("Square"),
        healthBg = Drawing.new("Square"),
        name = Drawing.new("Text"),
        tracer = Drawing.new("Line"),
        skeleton = {
            Head = Drawing.new("Line"), Torso = Drawing.new("Line"),
            LeftArm = Drawing.new("Line"), RightArm = Drawing.new("Line"),
            LeftLeg = Drawing.new("Line"), RightLeg = Drawing.new("Line"),
        }
    }
    
    d.box.Thickness = 1.5; d.box.Filled = false
    d.healthBg.Filled = true; d.healthBg.Color = Color3.fromRGB(0, 0, 0)
    d.health.Filled = true; d.health.Color = Color3.fromRGB(0, 255, 0)
    d.name.Size = 14; d.name.Center = true; d.name.Outline = true; d.name.Color = Color3.fromRGB(255, 255, 255)
    d.tracer.Thickness = 1.5
    
    for _, line in pairs(d.skeleton) do line.Thickness = 1.5 end
    espCache[player] = d
end

local function hideESP(d)
    d.box.Visible = false; d.health.Visible = false; d.healthBg.Visible = false; d.name.Visible = false; d.tracer.Visible = false
    for _, line in pairs(d.skeleton) do line.Visible = false end
end

RenderStepped:Connect(function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if not espCache[p] then createESP(p) end
            local d = espCache[p]
            if not d then continue end
            
            if not State.ESP or not p.Character or not p.Character:FindFirstChild("HumanoidRootPart") then
                hideESP(d) continue
            end
            
            local char = p.Character
            local hum = char:FindFirstChild("Humanoid")
            local root = char.HumanoidRootPart
            
            if not hum or hum.Health <= 0 then hideESP(d) continue end
            
            local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            
            if onScreen then
                local dist = (Camera.CFrame.Position - root.Position).Magnitude
                local boxSize = Vector2.new(2000 / dist, 3000 / dist)
                local boxPos = Vector2.new(screenPos.X - boxSize.X / 2, screenPos.Y - boxSize.Y / 2)
                
                local cBox = Color3.fromRGB(State.Color_Box[1], State.Color_Box[2], State.Color_Box[3])
                local cSkel = Color3.fromRGB(State.Color_Skeleton[1], State.Color_Skeleton[2], State.Color_Skeleton[3])
                local cTracer = Color3.fromRGB(State.Color_Tracer[1], State.Color_Tracer[2], State.Color_Tracer[3])
                
                d.box.Color = cBox; d.tracer.Color = cTracer
                for _, line in pairs(d.skeleton) do line.Color = cSkel end
                
                if State.ESP_Box then d.box.Size = boxSize; d.box.Position = boxPos; d.box.Visible = true else d.box.Visible = false end
                if State.ESP_Name then d.name.Text = p.Name .. " [" .. math.floor(dist) .. "m]"; d.name.Position = Vector2.new(screenPos.X, boxPos.Y - 18); d.name.Visible = true else d.name.Visible = false end
                
                if State.ESP_Tracer then
                    d.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    d.tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                    d.tracer.Visible = true
                else d.tracer.Visible = false end
                
                if State.ESP_Health then
                    local hPercent = hum.Health / hum.MaxHealth
                    local hHeight = boxSize.Y * hPercent
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

-- ==== КНОПКА И UI ====
local function getGuiParent()
    if gethui then local ok, hui = pcall(gethui); if ok and hui then return hui end end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end); if ok and cg then return cg end
    return game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NyanMobileBtn"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = getGuiParent()

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 60, 0, 60)
ToggleBtn.Position = UDim2.new(1, -80, 1, -120)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ToggleBtn.BackgroundTransparency = 0.3
ToggleBtn.Text = "🐱"
ToggleBtn.TextSize = 32
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Active = true
ToggleBtn.Draggable = true
ToggleBtn.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = ToggleBtn

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(0, 255, 255)
UIStroke.Thickness = 2
UIStroke.Parent = ToggleBtn

ToggleBtn.MouseButton1Click:Connect(function()
    local ok = pcall(function() Rayfield:Toggle(true) end)
    if not ok then pcall(function() Rayfield:Open() end) end
end)

-- Базовые настройки
CombatTab:CreateToggle({ Name = "AimBot (Наводка)", CurrentValue = false, Flag = "AimBot", Callback = function(v) State.AimBot = v end })
CombatTab:CreateToggle({ Name = "TriggerBot (Стрельба)", CurrentValue = false, Flag = "TriggerBot", Callback = function(v) State.TriggerBot = v end })
CombatTab:CreateSlider({ Name = "Aim FOV", Range = {50, 800}, Increment = 10, Suffix = " px", CurrentValue = 250, Flag = "FOV", Callback = function(v) State.FOV = v end })
CombatTab:CreateSlider({ Name = "Max Distance", Range = {10, 1000}, Increment = 10, Suffix = " m", CurrentValue = 150, Flag = "MaxDist", Callback = function(v) State.MaxDistance = v end })

VisualsTab:CreateToggle({ Name = "Crosshair", CurrentValue = true, Flag = "Crosshair", Callback = function(v) State.Crosshair = v end })
VisualsTab:CreateToggle({ Name = "Show FOV", CurrentValue = true, Flag = "ShowFOV", Callback = function(v) State.ShowFOV = v end })
VisualsTab:CreateSlider({ Name = "WalkSpeed", Range = {16, 100}, Increment = 1, Suffix = " studs", CurrentValue = 16, Flag = "WS", Callback = function(v) State.WalkSpeed = v end })

ESPTab:CreateToggle({ Name = "ESP", CurrentValue = false, Flag = "ESP", Callback = function(v) State.ESP = v end })
ESPTab:CreateToggle({ Name = "Box", CurrentValue = true, Flag = "ESP_Box", Callback = function(v) State.ESP_Box = v end })
ESPTab:CreateToggle({ Name = "Skeleton", CurrentValue = true, Flag = "ESP_Skeleton", Callback = function(v) State.ESP_Skeleton = v end })
ESPTab:CreateToggle({ Name = "Health", CurrentValue = true, Flag = "ESP_Health", Callback = function(v) State.ESP_Health = v end })
ESPTab:CreateToggle({ Name = "Name", CurrentValue = true, Flag = "ESP_Name", Callback = function(v) State.ESP_Name = v end })
ESPTab:CreateToggle({ Name = "Tracers", CurrentValue = true, Flag = "ESP_Tracer", Callback = function(v) State.ESP_Tracer = v end })

ColorTab:CreateSlider({ Name = "Box R", Range = {0, 255}, Increment = 1, CurrentValue = 255, Flag = "BoxR", Callback = function(v) State.Color_Box[1] = v end })
ColorTab:CreateSlider({ Name = "Box G", Range = {0, 255}, Increment = 1, CurrentValue = 255, Flag = "BoxG", Callback = function(v) State.Color_Box[2] = v end })
ColorTab:CreateSlider({ Name = "Box B", Range = {0, 255}, Increment = 1, CurrentValue = 255, Flag = "BoxB", Callback = function(v) State.Color_Box[3] = v end })

ColorTab:CreateSlider({ Name = "Skeleton R", Range = {0, 255}, Increment = 1, CurrentValue = 255, Flag = "SkelR", Callback = function(v) State.Color_Skeleton[1] = v end })
ColorTab:CreateSlider({ Name = "Skeleton G", Range = {0, 255}, Increment = 1, CurrentValue = 255, Flag = "SkelG", Callback = function(v) State.Color_Skeleton[2] = v end })
ColorTab:CreateSlider({ Name = "Skeleton B", Range = {0, 255}, Increment = 1, CurrentValue = 255, Flag = "SkelB", Callback = function(v) State.Color_Skeleton[3] = v end })

ColorTab:CreateSlider({ Name = "Tracer R", Range = {0, 255}, Increment = 1, CurrentValue = 255, Flag = "TracerR", Callback = function(v) State.Color_Tracer[1] = v end })
ColorTab:CreateSlider({ Name = "Tracer G", Range = {0, 255}, Increment = 1, CurrentValue = 0, Flag = "TracerG", Callback = function(v) State.Color_Tracer[2] = v end })
ColorTab:CreateSlider({ Name = "Tracer B", Range = {0, 255}, Increment = 1, CurrentValue = 0, Flag = "TracerB", Callback = function(v) State.Color_Tracer[3] = v end })

ColorTab:CreateSlider({ Name = "FOV Circle R", Range = {0, 255}, Increment = 1, CurrentValue = 255, Flag = "FovR", Callback = function(v) State.Color_FOV[1] = v end })
ColorTab:CreateSlider({ Name = "FOV Circle G", Range = {0, 255}, Increment = 1, CurrentValue = 255, Flag = "FovG", Callback = function(v) State.Color_FOV[2] = v end })
ColorTab:CreateSlider({ Name = "FOV Circle B", Range = {0, 255}, Increment = 1, CurrentValue = 255, Flag = "FovB", Callback = function(v) State.Color_FOV[3] = v end })

-- ВКЛАДКА С АВТОРАМИ И ТГ
InfoTab:CreateParagraph({
    Title = "Информация", 
    Content = "Автор скрипта: jeffkiller231451\nГлавный кодер: Fox\nМоральная поддержка: liloxa58\n\nТГ канал: https://t.me/hatanyana\n\nЗаходи за обновлениями и новыми скриптами!"
})
InfoTab:CreateButton({
    Name = "Скопировать ссылку на ТГ", 
    Callback = function()
        setclipboard("https://t.me/hatanyana")
        Rayfield:Notify({Title = "Nyan Script", Content = "Ссылка на ТГ скопирована!", Duration = 5})
    end
})

RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then char.Humanoid.WalkSpeed = State.WalkSpeed end
end)

Rayfield:Notify({ Title = "Nyan Script", Content = "by jeffkiller231451 | TG: @hatanyana", Duration = 5 })
