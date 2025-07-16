local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- FLAGS GLOBAIS padrão true ON
_G.FOV_RADIUS = 65
_G.FOV_VISIBLE = true
_G.aimbotAutoEnabled = false
_G.aimbotManualEnabled = false -- aqui usado como "Aimbot Legit"
_G.espEnemiesEnabled = true
_G.espAlliesEnabled = false
_G.noRecoilEnabled = true
_G.infiniteAmmoEnabled = true
_G.instantReloadEnabled = true

local currentTarget = nil
local aiming = false
local shooting = false
local dragging = false
local dragStart, startPos

-- ======== GUI ========

local gui = Instance.new("ScreenGui")
gui.Name = "MobileAimbotGUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 220, 0, 320)
panel.Position = UDim2.new(0, 20, 0.5, -160)
panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
panel.BackgroundTransparency = 0.2
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = gui

-- Botão minimizar/abrir que também pode ser arrastado
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 40, 0, 30)
toggleButton.Position = UDim2.new(1, -50, 0, 5)
toggleButton.Text = "🔽"
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 18
toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Parent = gui

local minimized = false
local function updateToggleState()
    if minimized then
        panel.Visible = false
        toggleButton.Text = "🔼"
    else
        panel.Visible = true
        toggleButton.Text = "🔽"
    end
end

toggleButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    updateToggleState()
end)

-- Drag para painel e para toggleButton (pode arrastar quando minimizado)
local function setupDrag(guiElement)
    guiElement.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = guiElement.Position
        end
    end)
    guiElement.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            guiElement.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
setupDrag(panel)
setupDrag(toggleButton)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- Botão toggle criado com exclusividade opcional (exclusiveFlag)
local function createToggleButton(text, yPos, flagName, exclusiveFlag)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 30)
    button.Position = UDim2.new(0, 10, 0, yPos)
    button.Text = text .. ": ON"
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 16
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Parent = panel

    button.MouseButton1Click:Connect(function()
        _G[flagName] = not _G[flagName]
        if exclusiveFlag and _G[flagName] then
            _G[exclusiveFlag] = false
        end
        button.Text = text .. (_G[flagName] and ": ON" or ": OFF")

        if exclusiveFlag then
            for _, sibling in pairs(panel:GetChildren()) do
                if sibling:IsA("TextButton") and sibling ~= button then
                    local siblingText = sibling.Text:lower()
                    local exclusiveFlagText = exclusiveFlag:gsub("([A-Z])", " %1"):lower()
                    exclusiveFlagText = exclusiveFlagText:gsub("^%l", string.upper)
                    if siblingText:find(exclusiveFlagText) then
                        sibling.Text = sibling.Text:sub(1, sibling.Text:find(":")) .. (_G[exclusiveFlag] and " ON" or " OFF")
                    end
                end
            end
        end
    end)
    return button
end

local function createFOVAdjustButton(text, yPos, delta)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.5, -15, 0, 30)
    button.Position = UDim2.new(text == "- FOV" and 0 or 0.5, 10, 0, yPos)
    button.Text = text
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 16
    button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Parent = panel
    button.MouseButton1Click:Connect(function()
        _G.FOV_RADIUS = math.clamp(_G.FOV_RADIUS + delta, 10, 300)
    end)
end

-- Criar botões conforme solicitado (posições no painel ajustadas)
local noRecoilBtn = createToggleButton("No Recoil", 40, "noRecoilEnabled")
local infiniteAmmoBtn = createToggleButton("Infinite Ammo", 75, "infiniteAmmoEnabled")
local instantReloadBtn = createToggleButton("Instant Reload", 110, "instantReloadEnabled")
local aimbotAutoBtn = createToggleButton("Aimbot Auto", 145, "aimbotAutoEnabled", "aimbotManualEnabled")
local aimbotLegitBtn = createToggleButton("Aimbot Legit", 180, "aimbotManualEnabled", "aimbotAutoEnabled")
local espEnemiesBtn = createToggleButton("ESP Inimigos", 215, "espEnemiesEnabled")
local espAlliesBtn = createToggleButton("ESP Aliados", 250, "espAlliesEnabled")
local showFOVBtn = createToggleButton("Mostrar FOV", 285, "FOV_VISIBLE")
createFOVAdjustButton("- FOV", 320, -5)
createFOVAdjustButton("+ FOV", 320, 5)

-- ======= DESENHO DO FOV =======
local fovCircle = Drawing.new("Circle")
fovCircle.Transparency = 0.2
fovCircle.Thickness = 1.5
fovCircle.Filled = false
fovCircle.Color = Color3.new(1, 1, 1)

RunService.RenderStepped:Connect(function()
    fovCircle.Radius = _G.FOV_RADIUS
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    fovCircle.Visible = _G.FOV_VISIBLE
end)

-- ======== FUNÇÕES AUXILIARES ========
local function isAlive(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function isFFA()
    local teams = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player.Team then
            teams[player.Team] = true
        end
    end
    local count = 0
    for _ in pairs(teams) do count = count + 1 end
    return count <= 1
end

local function hasLineOfSight(targetPart)
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit * 500
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

        if not hasLineOfSight(head) then continue end

        shortestDistance = distToCenter
        closestEnemy = player
    end

    return closestEnemy
end

-- ======== WALLHACK RGB + ESP + HIGHLIGHT ========
local highlights = {}

local function updateHighlight(player, isTarget, alive, isVisible)
    if not player.Character then return end
    local highlight = highlights[player]
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Parent = workspace
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlights[player] = highlight
    end

    if not alive or not isVisible then
        highlight.Enabled = false
        return
    end

    highlight.Adornee = player.Character
    highlight.Enabled = true

    if isTarget then
        highlight.FillColor = Color3.fromRGB(255, 255, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
        highlight.FillTransparency = 0.3
    else
        local t = tick() * 2
        local r = (math.sin(t) + 1) / 2
        local g = (math.sin(t + 2) + 1) / 2
        local b = (math.sin(t + 4) + 1) / 2
        highlight.FillColor = Color3.new(r, g, b)
        highlight.OutlineColor = Color3.new(r * 0.3, g * 0.3, b * 0.3)
        highlight.FillTransparency = 0.5
    end
end

local function updateAllHighlights()
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then
            if highlights[player] then
                highlights[player].Enabled = false
            end
            continue
        end

        local char = player.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then
            if highlights[player] then highlights[player].Enabled = false end
            continue
        end

        local isFFA = isFFA()
        local isAlly = (not isFFA) and (player.Team == LocalPlayer.Team)

        if (isAlly and not _G.espAlliesEnabled) or (not isAlly and not _G.espEnemiesEnabled) then
            if highlights[player] then highlights[player].Enabled = false end
            continue
        end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            if highlights[player] then highlights[player].Enabled = false end
            continue
        end

        local visible = hasLineOfSight(hrp)
        if not visible then
            if highlights[player] then highlights[player].Enabled = false end
            continue
        end

        local isTarget = (player == currentTarget)
        updateHighlight(player, isTarget, true, true)
    end
end

RunService.RenderStepped:Connect(function()
    updateAllHighlights()
end)

-- ======== AIMBOT ========

RunService.RenderStepped:Connect(function()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    -- Aimbot Automático
    if _G.aimbotAutoEnabled then
        local target = getClosestVisibleEnemy()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local head = target.Character.Head
            local headPos, visible = Camera:WorldToViewportPoint(head.Position)
            if visible then
                local dist = (Vector2.new(headPos.X, headPos.Y) - center).Magnitude
                if dist <= _G.FOV_RADIUS and hasLineOfSight(head) then
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

    -- Aimbot Legit (manual automático)
    if _G.aimbotManualEnabled and aiming and shooting then
        local target = getClosestVisibleEnemy()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local head = target.Character.Head
            local headPos, visible = Camera:WorldToViewportPoint(head.Position)
            if visible then
                local dist = (Vector2.new(headPos.X, headPos.Y) - center).Magnitude
                if dist <= _G.FOV_RADIUS and hasLineOfSight(head) then
                    currentTarget = target
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
                    -- Aqui poderia disparar tiro automático com delay "legit"
                else
                    currentTarget = nil
                end
            else
                currentTarget = nil
            end
        else
            currentTarget = nil
        end
    elseif not (_G.aimbotManualEnabled and aiming and shooting) and not _G.aimbotAutoEnabled then
        currentTarget = nil
    end
end)

-- ======== NO RECOIL, INFINITE AMMO, INSTANT RELOAD ========
-- Implementação básica, adaptável conforme seu jogo

local function applyGunAttributes(tool)
    if not tool then return end
    tool:SetAttribute("_ammo", 200)
    tool:SetAttribute("magazineSize", 200)
    tool:SetAttribute("reloadTime", 0)
    tool:SetAttribute("spread", 0)
    tool:SetAttribute("recoilAimReduction", Vector2.new(0, 0))
    tool:SetAttribute("recoilMax", Vector2.new(0, 0))
    tool:SetAttribute("recoilMin", Vector2.new(0, 0))
    tool:SetAttribute("rateOfFire", 250)
    tool:SetAttribute("zoom", 3)
end

local function updateGunAttributes()
    local char = LocalPlayer.Character
    if not char then return end
    local tool = char:FindFirstChildWhichIsA("Tool")
    if not tool then return end

    if _G.noRecoilEnabled or _G.infiniteAmmoEnabled or _G.instantReloadEnabled then
        applyGunAttributes(tool)
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.2)
    updateGunAttributes()
end)

RunService.RenderStepped:Connect(function()
    updateGunAttributes()
end)

-- ======== CONTROLES DE INPUT PARA AIMBOT LEGIT ========
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aiming = true
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        shooting = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aiming = false
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        shooting = false
    end
end)
