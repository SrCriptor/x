local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

-- Configurações globais
_G.FOV_RADIUS = 65
_G.FOV_VISIBLE = true
_G.aimbotAutoEnabled = false
_G.aimbotManualEnabled = false
_G.aimbotSilentEnabled = false
_G.espBoxEnabled = true
_G.espLineEnabled = true
_G.espNameEnabled = true
_G.espDistanceEnabled = true
_G.wallhackEnabled = false
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
local dragStart, startPos
local currentTarget = nil
local currentPage = 1 -- 1 = Principal, 2 = Outros

-- Referências aos botões mobile (ajustar paths conforme seu jogo)
local aimButton = LocalPlayer.PlayerScripts:WaitForChild("Assets")
    .Ui.TouchInputController.BlasterTouchGui.Buttons:WaitForChild("AimButton")
local shootButton = LocalPlayer.PlayerScripts:WaitForChild("Assets")
    .Ui.TouchInputController.BlasterTouchGui.Buttons:WaitForChild("ShootButton")

-- Funções auxiliares (isFFA, isEnemy, isAliveCharacter) e silentAimTo mantidas iguais (mesmo que antes)

local function isFFA()
    local teams = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player.Team then teams[player.Team] = true end
    end
    local count = 0
    for _ in pairs(teams) do count = count + 1 end
    return count <= 1
end

local function isEnemy(player)
    local ffa = isFFA()
    if ffa then return true end
    if player.Team and LocalPlayer.Team then
        return player.Team ~= LocalPlayer.Team
    end
    return false
end

local function isAliveCharacter(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function shouldAimAt(player)
    if player == LocalPlayer then return false end
    if not player.Character then return false end
    if not isAliveCharacter(player.Character) then return false end
    if not isEnemy(player) and not _G.espAlliesEnabled then return false end
    return true
end

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
            -- Permitir vidro e transparência > 0.5
            if hitPart.Material == Enum.Material.Glass then return true end
            if hitPart.Transparency > 0.5 then return true end
            return false
        end
    else
        return true
    end
end

local function silentAimTo(part)
    if not part then return end
    local endCFrame = CFrame.new(Camera.CFrame.Position, part.Position)
    local tween = TweenService:Create(Camera, TweenInfo.new(0.15, Enum.EasingStyle.Linear), {CFrame = endCFrame})
    tween:Play()
end

-- Criação do GUI
local gui = Instance.new("ScreenGui")
gui.Name = "MobileAimbotGUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 220, 0, 280)
panel.Position = UDim2.new(0, 20, 0.5, -140)
panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
panel.BackgroundTransparency = 0.2
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = gui

-- Drag da interface (touch e mouse)
panel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = panel.Position
    end
end)

panel.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- Minimizar/Expandir
local minimized = false
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 40, 0, 30)
toggleButton.Position = UDim2.new(1, -50, 0, 5)
toggleButton.Text = "🔽"
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 18
toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Parent = panel

toggleButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    toggleButton.Text = minimized and "🔼" or "🔽"

    for _, v in pairs(panel:GetChildren()) do
        if v:IsA("TextButton") and v ~= toggleButton then
            v.Visible = not minimized
        end
    end

    if minimized then
        panel.Size = UDim2.new(0, 60, 0, 40)
        panel.BackgroundTransparency = 1
        toggleButton.Position = UDim2.new(0, 10, 0, 5)
    else
        panel.Size = UDim2.new(0, 220, 0, 280)
        panel.BackgroundTransparency = 0.2
        toggleButton.Position = UDim2.new(1, -50, 0, 5)
    end
end)

-- Função para criar botão toggle com GothamBold
local function createToggleButton(text, yPos, flagName, exclusiveFlag)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 30)
    button.Position = UDim2.new(0, 10, 0, yPos)
    button.Text = text .. ": OFF"
    button.Font = Enum.Font.GothamBold
    button.TextSize = 16
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Parent = panel

    button.MouseButton1Click:Connect(function()
        _G[flagName] = not _G[flagName]
        -- Exclusividade entre aimbots
        if exclusiveFlag and _G[flagName] then
            _G[exclusiveFlag] = false
        end
        button.Text = text .. (_G[flagName] and ": ON" or ": OFF")

        -- Atualiza botão irmão exclusivo
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

-- Função criar botão simples (para página)
local function createSimpleButton(text, posX, posY)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 80, 0, 30)
    btn.Position = UDim2.new(0, posX, 0, posY)
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Parent = panel
    return btn
end

-- Criar botões da Página 1 (Principal)
local aimbotAutoBtn = createToggleButton("Aimbot Auto", 40, "aimbotAutoEnabled", "aimbotManualEnabled")
local aimbotManualBtn = createToggleButton("Aimbot Manual", 75, "aimbotManualEnabled", "aimbotAutoEnabled")
local aimbotSilentBtn = createToggleButton("Aimbot Silent", 110, "aimbotSilentEnabled", "aimbotAutoEnabled") -- exclusão com auto

local showFOVBtn = createToggleButton("Mostrar FOV", 145, "FOV_VISIBLE")
local fovMinusBtn = createSimpleButton("- FOV", 10, 180)
local fovPlusBtn = createSimpleButton("+ FOV", 110, 180)

-- Próxima página
local nextPageBtn = createSimpleButton("⏩ Outros", 110, 220)

-- Função para atualizar visibilidade da página
local function updatePage()
    if currentPage == 1 then
        aimbotAutoBtn.Visible = true
        aimbotManualBtn.Visible = true
        aimbotSilentBtn.Visible = true
        showFOVBtn.Visible = true
        fovMinusBtn.Visible = true
        fovPlusBtn.Visible = true
        nextPageBtn.Visible = true

        -- Página 2 fica oculta
        espBoxToggle.Visible = false
        espLineToggle.Visible = false
        espNameToggle.Visible = false
        espDistToggle.Visible = false
        wallhackToggle.Visible = false
        prevPageBtn.Visible = false
        selectHitboxBtn.Visible = false

    else
        aimbotAutoBtn.Visible = false
        aimbotManualBtn.Visible = false
        aimbotSilentBtn.Visible = false
        showFOVBtn.Visible = false
        fovMinusBtn.Visible = false
        fovPlusBtn.Visible = false
        nextPageBtn.Visible = false

        espBoxToggle.Visible = true
        espLineToggle.Visible = true
        espNameToggle.Visible = true
        espDistToggle.Visible = true
        wallhackToggle.Visible = true
        prevPageBtn.Visible = true
        selectHitboxBtn.Visible = true
    end
end

-- Ajustar FOV
fovMinusBtn.MouseButton1Click:Connect(function()
    _G.FOV_RADIUS = math.clamp(_G.FOV_RADIUS - 5, 10, 300)
end)
fovPlusBtn.MouseButton1Click:Connect(function()
    _G.FOV_RADIUS = math.clamp(_G.FOV_RADIUS + 5, 10, 300)
end)

-- Criar botões da Página 2 (Outros)
local espBoxToggle = createToggleButton("ESP Caixa", 40, "espBoxEnabled")
local espLineToggle = createToggleButton("ESP Linha", 75, "espLineEnabled")
local espNameToggle = createToggleButton("ESP Nome", 110, "espNameEnabled")
local espDistToggle = createToggleButton("ESP Distância", 145, "espDistanceEnabled")
local wallhackToggle = createToggleButton("Wallhack", 180, "wallhackEnabled")

local prevPageBtn = createSimpleButton("⏪ Voltar", 10, 220)
local selectHitboxBtn = createSimpleButton("Selecionar Hitbox", 110, 220)

-- Navegação entre páginas
nextPageBtn.MouseButton1Click:Connect(function()
    currentPage = 2
    updatePage()
end)
prevPageBtn.MouseButton1Click:Connect(function()
    currentPage = 1
    updatePage()
end)

updatePage()

-- POPUP HITBOX

local hitboxGui = Instance.new("ScreenGui")
hitboxGui.Name = "HitboxSelector"
hitboxGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
hitboxGui.Enabled = false

local popup = Instance.new("Frame")
popup.Size = UDim2.new(0, 300, 0, 400)
popup.Position = UDim2.new(0.5, -150, 0.5, -200)
popup.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
popup.BackgroundTransparency = 0.1
popup.BorderSizePixel = 0
popup.Parent = hitboxGui

local image = Instance.new("ImageLabel")
image.Size = UDim2.new(1, 0, 1, 0)
image.Position = UDim2.new(0, 0, 0, 0)
image.Image = "rbxassetid://14883729223" -- Bacon dummy
image.BackgroundTransparency = 1
image.Parent = popup

local parts = {
    Head = UDim2.new(0.45, 0, 0.05, 0),
    Torso = UDim2.new(0.35, 0, 0.2, 0),
    LeftArm = UDim2.new(0.15, 0, 0.2, 0),
    RightArm = UDim2.new(0.65, 0, 0.2, 0),
    LeftLeg = UDim2.new(0.35, 0, 0.55, 0),
    RightLeg = UDim2.new(0.55, 0, 0.55, 0)
}

local function updateHighlightVisual(button, partName)
    -- Reset all to None first
    for name in pairs(_G.hitboxSelection) do
        _G.hitboxSelection[name] = "None"
    end
    -- Set selected as Prioritário
    _G.hitboxSelection[partName] = "Prioritário"

    -- Update colors
    for _, btn in pairs(popup:GetChildren()) do
        if btn:IsA("TextButton") then
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        end
    end
    button.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- vermelho
end

for partName, pos in pairs(parts) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 50, 0, 50)
    btn.Position = pos
    btn.Text = ""
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.BackgroundTransparency = 0.2
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = popup

    btn.MouseButton1Click:Connect(function()
        updateHighlightVisual(btn, partName)
    end)
end

-- Botão para abrir/fechar popup
selectHitboxBtn.MouseButton1Click:Connect(function()
    hitboxGui.Enabled = not hitboxGui.Enabled
end)

-- ======= DESENHO DO FOV =======
local fovCircle = Drawing.new("Circle")
fovCircle.Transparency = 0.2
fovCircle.Thickness = 1.5
fovCircle.Filled = false
fovCircle.Color = Color3.new(1, 1, 1)

RunService.RenderStepped:Connect(function()
    fovCircle.Radius = _G.FOV_RADIUS
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    fovCircle.Color = Color3.new(1, 1, 1)
    fovCircle.Visible = _G.FOV_VISIBLE
end)

-- Atualização da função getClosestVisibleEnemy com priorização da hitbox selecionada
local function getClosestVisibleEnemy()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local shortestDistance = _G.FOV_RADIUS
    local closestEnemy = nil

    for _, player in pairs(Players:GetPlayers()) do
        if not shouldAimAt(player) then continue end

        local bestPart = nil
        for _, partName in ipairs({"Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}) do
            if _G.hitboxSelection[partName] == "Prioritário" then
                local part = player.Character:FindFirstChild(partName)
                if part then
                    bestPart = part
                    break
                end
            end
        end

        if not bestPart then continue end

        local screenPos, visible = Camera:WorldToViewportPoint(bestPart.Position)
        if not visible then continue end

        local distToCenter = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if distToCenter > shortestDistance then continue end

        if not hasLineOfSight(bestPart) then continue end

        shortestDistance = distToCenter
        closestEnemy = player
    end

    return closestEnemy
end

-- Atualização do Aimbot (Auto/Manual/Silent)
RunService.RenderStepped:Connect(function()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    if _G.aimbotAutoEnabled or (_G.aimbotManualEnabled and aiming and shooting) or (_G.aimbotSilentEnabled and aiming) then
        local target = getClosestVisibleEnemy()
        if target then
            local part = nil
            for _, partName in ipairs({"Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}) do
                if _G.hitboxSelection[partName] == "Prioritário" then
                    part = target.Character and target.Character:FindFirstChild(partName)
                    if part then break end
                end
            end

            if part then
                local partPos, visible = Camera:WorldToViewportPoint(part.Position)
                if visible and (Vector2.new(partPos.X, partPos.Y) - center).Magnitude <= _G.FOV_RADIUS then
                    currentTarget = target
                    if _G.aimbotSilentEnabled then
                        silentAimTo(part)
                    else
                        Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
                    end
                else
                    currentTarget = nil
                end
            else
                currentTarget = nil
            end
        else
            currentTarget = nil
        end
    else
        currentTarget = nil
    end
end)

-- ESP / Wallhack

local function createHighlight(player, color)
    local character = player.Character
    if not character then return end
    local highlight = character:FindFirstChild("AimbotHighlight")
    if highlight then
        highlight.Adornee = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
        highlight.FillColor = color
        highlight.OutlineColor = color
        return highlight
    end

    highlight = Instance.new("Highlight")
    highlight.Name = "AimbotHighlight"
    highlight.Adornee = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.Parent = character
    return highlight
end

RunService.RenderStepped:Connect(function()
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character then continue end
        if not isAliveCharacter(player.Character) then continue end

        local highlight = player.Character:FindFirstChild("AimbotHighlight")
        if not highlight and (_G.wallhackEnabled or _G.espBoxEnabled or _G.espLineEnabled or _G.espNameEnabled or _G.espDistanceEnabled) then
            highlight = createHighlight(player, Color3.new(1,1,1))
        end

        if highlight then
            if player == currentTarget then
                highlight.FillColor = Color3.fromRGB(255, 255, 0) -- amarelo para alvo atual
                highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
            elseif isEnemy(player) then
                highlight.FillColor = Color3.fromRGB(255, 0, 0) -- vermelho para inimigo
                highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
            else
                highlight.FillColor = Color3.fromRGB(0, 255, 255) -- azul para aliado
                highlight.OutlineColor = Color3.fromRGB(0, 255, 255)
            end
            highlight.Enabled = (_G.wallhackEnabled or _G.espBoxEnabled)
        end
    end
end)

-- Atualização dos botões de tiro e mira mobile
aimButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        aiming = true
    end
end)

aimButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        aiming = false
    end
end)

shootButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        shooting = true
    end
end)

shootButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        shooting = false
    end
end)
