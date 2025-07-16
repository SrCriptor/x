-- SISTEMA COMPLETO: GUI + AIMBOT + ESP + WALLHACK + SELEÇÃO DE HITBOX

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- FLAGS GLOBAIS
_G.FOV_RADIUS = 65
_G.FOV_VISIBLE = true
_G.aimbotAutoEnabled = false
_G.aimbotManualEnabled = false
_G.aimbotLegitEnabled = false
_G.espEnemiesEnabled = true
_G.espAlliesEnabled = false
_G.hitboxSelection = {
    Head = "Prioritário",
    Torso = "None",
    LeftArm = "None",
    RightArm = "None",
    LeftLeg = "None",
    RightLeg = "None",
}

local shooting = false
local aiming = false
local dragging = false
local dragStart, startPos = nil, nil
local currentTarget = nil

-- BOTÕES MOBILE
local aimButton = LocalPlayer.PlayerScripts:WaitForChild("Assets").Ui.TouchInputController.BlasterTouchGui.Buttons:WaitForChild("AimButton")
local shootButton = LocalPlayer.PlayerScripts:WaitForChild("Assets").Ui.TouchInputController.BlasterTouchGui.Buttons:WaitForChild("ShootButton")

-- FFA CHECK
local function isFFA()
    local teams = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p.Team then teams[p.Team] = true end
    end
    local count = 0 for _ in pairs(teams) do count += 1 end
    return count <= 1
end

local function isEnemy(p)
    return isFFA() or (p.Team and LocalPlayer.Team and p.Team ~= LocalPlayer.Team)
end

local function isAlive(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function shouldAimAt(p)
    return p ~= LocalPlayer and p.Character and isAlive(p.Character) and (isEnemy(p) or _G.espAlliesEnabled)
end

-- GUI PRINCIPAL
local gui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
local panel = Instance.new("Frame", gui)
panel.Size = UDim2.new(0, 220, 0, 280)
panel.Position = UDim2.new(0, 20, 0.5, -140)
panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
panel.BackgroundTransparency = 0.2
panel.BorderSizePixel = 0
panel.Active = true

-- DRAG
panel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = panel.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- TOGGLE BUTTON
local minimized = false
local toggleButton = Instance.new("TextButton", panel)
toggleButton.Size = UDim2.new(0, 40, 0, 30)
toggleButton.Position = UDim2.new(1, -50, 0, 5)
toggleButton.Text = "🕽"
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 18
toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleButton.TextColor3 = Color3.new(1, 1, 1)

-- DEIXAR O BOTÃO TAMBÉM ARRASTÁVEL
toggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = panel.Position
    end
end)

-- TOGGLE
toggleButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    toggleButton.Text = minimized and "🕼" or "🕽"
    for _, v in pairs(panel:GetChildren()) do
        if v:IsA("TextButton") and v ~= toggleButton then v.Visible = not minimized end
    end
    panel.Size = minimized and UDim2.new(0, 60, 0, 40) or UDim2.new(0, 220, 0, 280)
    panel.BackgroundTransparency = minimized and 1 or 0.2
    toggleButton.Position = minimized and UDim2.new(0, 10, 0, 5) or UDim2.new(1, -50, 0, 5)
end)

-- FUNÇÕES DO MENU
local function createToggle(text, y, flagName, exclusive1, exclusive2)
    local b = Instance.new("TextButton", panel)
    b.Size = UDim2.new(1, -20, 0, 30)
    b.Position = UDim2.new(0, 10, 0, y)
    b.Text = text .. ": OFF"
    b.Font = Enum.Font.SourceSansBold
    b.TextSize = 16
    b.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.MouseButton1Click:Connect(function()
        _G[flagName] = not _G[flagName]
        if _G[flagName] then
            if exclusive1 then _G[exclusive1] = false end
            if exclusive2 then _G[exclusive2] = false end
        end
        b.Text = text .. (_G[flagName] and ": ON" or ": OFF")
    end)
    return b
end

createToggle("Aimbot Auto", 40, "aimbotAutoEnabled", "aimbotManualEnabled", "aimbotLegitEnabled")
createToggle("Aimbot Manual", 75, "aimbotManualEnabled", "aimbotAutoEnabled", "aimbotLegitEnabled")
createToggle("Aimbot Legit", 110, "aimbotLegitEnabled", "aimbotAutoEnabled", "aimbotManualEnabled")
createToggle("ESP Inimigos", 145, "espEnemiesEnabled")
createToggle("ESP Aliados", 180, "espAlliesEnabled")
createToggle("Mostrar FOV", 215, "FOV_VISIBLE")

-- CAPTURA DE ESTADO DO BOTÃO DE MIRA E TIRO
aimButton.MouseButton1Down:Connect(function()
    aiming = true
end)
aimButton.MouseButton1Up:Connect(function()
    aiming = false
    currentTarget = nil
end)
shootButton.MouseButton1Down:Connect(function()
    shooting = true
end)
shootButton.MouseButton1Up:Connect(function()
    shooting = false
end)

-- FUNÇÃO AUXILIAR PARA OBTER O ALVO MAIS PRÓXIMO VISÍVEL
local function getClosestVisibleEnemy()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local shortestDistance = _G.FOV_RADIUS
    local closestEnemy = nil
    local ffa = isFFA()

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer or not player.Character then continue end
        if not isAlive(player.Character) then continue end

        if not ffa then
            if player.Team == LocalPlayer.Team and not _G.espAlliesEnabled then continue end
            if player.Team ~= LocalPlayer.Team and not _G.espEnemiesEnabled then continue end
        else
            if not _G.espEnemiesEnabled then continue end
        end

        local head = player.Character:FindFirstChild("Head")
        if not head then continue end

        local screenPos, visible = Camera:WorldToViewportPoint(head.Position)
        if not visible then continue end

        local distToCenter = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if distToCenter > shortestDistance then continue end

        local function hasLineOfSight(targetPart)
            local origin = Camera.CFrame.Position
            local direction = (targetPart.Position - origin)
            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
            raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

            local raycastResult = workspace:Raycast(origin, direction, raycastParams)
            if raycastResult then
                local hitPart = raycastResult.Instance
                if hitPart and hitPart:IsDescendantOf(targetPart.Parent) then
                    return true
                else
                    return false
                end
            else
                return true
            end
        end

        if not hasLineOfSight(head) then continue end

        shortestDistance = distToCenter
        closestEnemy = player
    end

    return closestEnemy
end

-- AIMBOT AUTOMÁTICO (MIRA RÁPIDO)
RunService.RenderStepped:Connect(function()
    if _G.aimbotAutoEnabled then
        local target = getClosestVisibleEnemy()
        if target and target.Character and target.Character:FindFirstChild("Head") and isAlive(target.Character) then
            local head = target.Character.Head
            local headPos, visible = Camera:WorldToViewportPoint(head.Position)
            if visible then
                local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                local dist = (Vector2.new(headPos.X, headPos.Y) - center).Magnitude
                if dist <= _G.FOV_RADIUS then
                    currentTarget = target
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
                else
                    currentTarget = nil
                end
            else
                currentTarget = nil
            end
        else
            currentTarget = nil
        end
    end
end)

-- AIMBOT LEGIT (MIRA + ATIRA AUTOMATICAMENTE, PRECISE)
RunService.RenderStepped:Connect(function()
    if _G.aimbotLegitEnabled then
        local target = getClosestVisibleEnemy()
        if target and target.Character and target.Character:FindFirstChild("Head") and isAlive(target.Character) then
            local head = target.Character.Head
            local headPos, visible = Camera:WorldToViewportPoint(head.Position)
            if visible then
                local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                local dist = (Vector2.new(headPos.X, headPos.Y) - center).Magnitude
                if dist <= _G.FOV_RADIUS then
                    currentTarget = target
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
                    shooting = true -- Atira automaticamente
                else
                    currentTarget = nil
                    shooting = false
                end
            else
                currentTarget = nil
                shooting = false
            end
        else
            currentTarget = nil
            shooting = false
        end
    else
        shooting = false
    end
end)

-- AIMBOT MANUAL (SÓ MIRA QUANDO BOTÃO DE MIRA ESTIVER PRESSIONADO, O USUÁRIO DEVE ATIRAR)
RunService.RenderStepped:Connect(function()
    if _G.aimbotManualEnabled and aiming then
        local closest, shortest = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if shouldAimAt(p) then
                local head = p.Character:FindFirstChild("Head")
                if head then
                    local pos, visible = Camera:WorldToViewportPoint(head.Position)
                    if visible then
                        local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
                        if dist <= _G.FOV_RADIUS and dist < shortest then
                            closest = p
                            shortest = dist
                        end
                    end
                end
            end
        end
        if closest and closest.Character and closest.Character:FindFirstChild("Head") and isAlive(closest.Character) then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, closest.Character.Head.Position)
            currentTarget = closest
        else
            currentTarget = nil
        end
    end
end)

return gui
