--[[
    [FPS] Flick — NYAN SCRIPT (Karpware Style + Always-On ESP)
    Автор: jeffkiller231451
    Главный кодер: Fox
    Моральная поддержка: liloxa58
]]

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Karpware 6.1.0 | Nyan",
    SubTitle = "by jeffkiller231451 & Fox",
    TabWidth = 160,
    Size = UDim2.fromOffset(700, 500),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightShift
})

local Tabs = {
    Ragebot = Window:AddTab({ Title = "Ragebot", Icon = "crosshair" }),
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" }),
    Misc = Window:AddTab({ Title = "Miscellaneous", Icon = "settings" }),
}

local State = {
    AimBot = false, TriggerBot = false, TriggerDelay = 0.1, FOV = 250, MaxDistance = 150,
    WalkSpeed = 16, CustomFOV = false, FOVValue = 70,
    ESP = false, ESP_Box = true, ESP_Skeleton = true, ESP_Health = true, ESP_Name = true, ESP_Tracer = true,
    Crosshair = true, ShowFOV = false, BHop = false, BHopSpeed = 35,
    AimMethod = "Mouse",
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RenderStepped = RunService.RenderStepped

local Toggles = {}

-- ==== ВОДЯНОЙ ЗНАК ====
local watermark = Drawing.new("Text")
watermark.Text = "Nyan Script | Karpware Style"
watermark.Size = 18
watermark.Color = Color3.fromRGB(255, 50, 50)
watermark.Outline = true
watermark.Position = Vector2.new(15, 15)
watermark.Visible = true

local hotkeyInfo = Drawing.new("Text")
hotkeyInfo.Text = "[HOTKEYS] Z: AimBot | X: Trigger | C: ESP | V: BHop | F: WalkSpeed | G: Aim Method"
hotkeyInfo.Size = 16
hotkeyInfo.Color = Color3.fromRGB(255, 255, 255)
hotkeyInfo.Outline = true
hotkeyInfo.Position = Vector2.new(15, 35)
hotkeyInfo.Visible = true

-- ==== ЛОГИКА ЧИТОВ ====
local function getClosestPlayer()
    local closest = nil
    local shortestWorldDist = State.MaxDistance 
    local center = Camera.ViewportSize / 2
    local camPos = Camera.CFrame.Position
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local head = p.Character.Head
            local worldDist = (camPos - head.Position).Magnitude
            if worldDist <= shortestWorldDist then
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
    end
    return closest
end

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

local lastTriggerTime = 0
RenderStepped:Connect(function()
    if not State.AimBot and not State.TriggerBot then return end
    local target = getClosestPlayer()
    if not target then return end

    if State.AimBot then
        if State.AimMethod == "Mouse" and mousemoverel then
            local screenPos = Camera:WorldToViewportPoint(target.Position)
            local center = Camera.ViewportSize / 2
            mousemoverel(screenPos.X - center.X, screenPos.Y - center.Y)
        elseif State.AimMethod == "Camera" then
            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, target.Position)
        end
    end

    if State.TriggerBot and isVisible(target) and tick() - lastTriggerTime >= State.TriggerDelay then
        if mouse1click then mouse1click() end
        lastTriggerTime = tick()
    end
end)

RenderStepped:Connect(function()
    if State.CustomFOV and Camera.FieldOfView ~= State.FOVValue then Camera.FieldOfView = State.FOVValue end
end)

local lastJumpTime = 0
RenderStepped:Connect(function()
    if not State.BHop then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if hum and root and hum.FloorMaterial ~= Enum.Material.Air then
        local moveDir = hum.MoveDirection
        if moveDir.Magnitude > 0 and tick() - lastJumpTime > 0.1 then
            root.Velocity = Vector3.new(moveDir.X * State.BHopSpeed, root.Velocity.Y + 50, moveDir.Z * State.BHopSpeed)
            hum.Jump = true
            lastJumpTime = tick()
        end
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
    -- УБРАЛ ПРОВЕРКУ State.MenuOpen, ESP РАБОТАЕТ ВСЕГДА
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if not espCache[p] then createESP(p) end
            local d = espCache[p]
            if not State.ESP or not p.Parent or not p.Character or not p.Character:FindFirstChild("HumanoidRootPart") then 
                hideESP(d) continue 
            end
            local char = p.Character; local hum = char:FindFirstChild("Humanoid"); local root = char.HumanoidRootPart
            if not hum or hum.Health <= 0 or not root.Position then hideESP(d) continue end
            local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            if onScreen then
                local dist = (Camera.CFrame.Position - root.Position).Magnitude
                local boxSize = Vector2.new(2000 / dist, 3000 / dist)
                local boxPos = Vector2.new(screenPos.X - boxSize.X / 2, screenPos.Y - boxSize.Y / 2)
                if State.ESP_Box then d.box.Size = boxSize; d.box.Position = boxPos; d.box.Visible = true else d.box.Visible = false end
                if State.ESP_Name then d.name.Text = p.Name; d.name.Position = Vector2.new(screenPos.X, boxPos.Y - 18); d.name.Visible = true else d.name.Visible = false end
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

-- ==== ХОТКЕИ ====
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.Z then
        State.AimBot = not State.AimBot
        if Toggles.AimBot then Toggles.AimBot:Set(State.AimBot) end
        Fluent:Notify({ Title = "AimBot", Content = State.AimBot and "Включен" or "Выключен", Duration = 2 })
    end

    if input.KeyCode == Enum.KeyCode.X then
        State.TriggerBot = not State.TriggerBot
        if Toggles.TriggerBot then Toggles.TriggerBot:Set(State.TriggerBot) end
        Fluent:Notify({ Title = "TriggerBot", Content = State.TriggerBot and "Включен" or "Выключен", Duration = 2 })
    end

    if input.KeyCode == Enum.KeyCode.C then
        State.ESP = not State.ESP
        if Toggles.ESP then Toggles.ESP:Set(State.ESP) end
        Fluent:Notify({ Title = "ESP", Content = State.ESP and "Включен" or "Выключен", Duration = 2 })
    end

    if input.KeyCode == Enum.KeyCode.V then
        State.BHop = not State.BHop
        if Toggles.BHop then Toggles.BHop:Set(State.BHop) end
        Fluent:Notify({ Title = "BHop", Content = State.BHop and "Включен" or "Выключен", Duration = 2 })
    end

    if input.KeyCode == Enum.KeyCode.F then
        if State.WalkSpeed == 16 then State.WalkSpeed = 50
        elseif State.WalkSpeed == 50 then State.WalkSpeed = 100
        else State.WalkSpeed = 16 end
        Fluent:Notify({ Title = "WalkSpeed", Content = "Скорость: " .. State.WalkSpeed, Duration = 2 })
    end

    if input.KeyCode == Enum.KeyCode.G then
        State.AimMethod = (State.AimMethod == "Mouse") and "Camera" or "Mouse"
        Fluent:Notify({ Title = "Aim Method", Content = "Метод: " .. State.AimMethod, Duration = 2 })
    end
end)

-- ==== UI ====
Tabs.Ragebot:AddParagraph({ Title = "Ragebot Settings", Content = "Хоткеи: Z (AimBot) | X (Trigger) | G (Aim Method)" })
Toggles.AimBot = Tabs.Ragebot:AddToggle("AimBot", { Title = "AimBot", Default = false, Callback = function(v) State.AimBot = v end })
Toggles.TriggerBot = Tabs.Ragebot:AddToggle("TriggerBot", { Title = "TriggerBot", Default = false, Callback = function(v) State.TriggerBot = v end })
Tabs.Ragebot:AddSlider("FOV", { Title = "Field of view", Min = 50, Max = 800, Default = 250, Rounding = 0, Callback = function(v) State.FOV = v end })
Tabs.Ragebot:AddSlider("MaxDist", { Title = "Max distance", Min = 10, Max = 1000, Default = 150, Rounding = 0, Callback = function(v) State.MaxDistance = v end })

Tabs.Visuals:AddParagraph({ Title = "Visuals", Content = "Хоткей: C (ESP) | V (BHop)" })
Toggles.ESP = Tabs.Visuals:AddToggle("ESP", { Title = "ESP", Default = false, Callback = function(v) State.ESP = v end })
Tabs.Visuals:AddToggle("ESPBox", { Title = "Box", Default = true, Callback = function(v) State.ESP_Box = v end })
Tabs.Visuals:AddToggle("ESPSkeleton", { Title = "Skeleton", Default = true, Callback = function(v) State.ESP_Skeleton = v end })
Tabs.Visuals:AddToggle("ESPHealth", { Title = "Health", Default = true, Callback = function(v) State.ESP_Health = v end })
Tabs.Visuals:AddToggle("ESPName", { Title = "Name", Default = true, Callback = function(v) State.ESP_Name = v end })
Tabs.Visuals:AddToggle("ESPTracer", { Title = "Tracer", Default = true, Callback = function(v) State.ESP_Tracer = v end })
Toggles.BHop = Tabs.Visuals:AddToggle("BHop", { Title = "BHop", Default = false, Callback = function(v) State.BHop = v end })

Tabs.Misc:AddParagraph({ Title = "Miscellaneous", Content = "Хоткей: F (WalkSpeed Cycle) | G (Aim Method)" })
Tabs.Misc:AddToggle("Crosshair", { Title = "Crosshair", Default = true, Callback = function(v) State.Crosshair = v end })
Tabs.Misc:AddSlider("WalkSpeed", { Title = "WalkSpeed", Min = 16, Max = 100, Default = 16, Rounding = 0, Callback = function(v) State.WalkSpeed = v end })

RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then char.Humanoid.WalkSpeed = State.WalkSpeed end
end)

Fluent:Notify({ Title = "Karpware Style", Content = "Скрипт загружен! ESP всегда включен.", Duration = 5 })
