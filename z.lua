-- Serviços e variáveis iniciais
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Variáveis globais que controlam o script
_G.aimbotAutoEnabled = false
_G.aimbotManualEnabled = false
_G.espEnemiesEnabled = true
_G.espAlliesEnabled = false
_G.noRecoilEnabled = true
_G.infiniteAmmoEnabled = true
_G.instantReloadEnabled = true
_G.FOV_RADIUS = 65
_G.FOV_VISIBLE = true

-- Criar GUI

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RoundedToggleMenu"
screenGui.Parent = PlayerGui
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 280, 0, 360)
mainFrame.Position = UDim2.new(0, 50, 0, 50)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 0
mainFrame.AnchorPoint = Vector2.new(0, 0)
mainFrame.Parent = screenGui

local uicorner = Instance.new("UICorner")
uicorner.CornerRadius = UDim.new(0, 20)
uicorner.Parent = mainFrame

local uistroke = Instance.new("UIStroke")
uistroke.Color = Color3.fromRGB(180, 180, 180)
uistroke.Thickness = 1.8
uistroke.Parent = mainFrame

-- Barra de título para arrastar e botão minimizar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundTransparency = 1
titleBar.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -60, 1, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Menu de Configurações"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 20
titleLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 35, 0, 30)
toggleBtn.Position = UDim2.new(1, -45, 0, 5)
toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = "—"
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 24
toggleBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
toggleBtn.AutoButtonColor = true
toggleBtn.Parent = titleBar

local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Size = UDim2.new(1, -20, 1, -50)
contentFrame.Position = UDim2.new(0, 10, 0, 40)
contentFrame.CanvasSize = UDim2.new(0, 0, 0, 300)
contentFrame.BackgroundTransparency = 1
contentFrame.ScrollBarThickness = 6
contentFrame.Parent = mainFrame

local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 12)
contentLayout.Parent = contentFrame
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Função para criar toggles bonitos e funcionais
local function createToggle(name, default, callback)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, 0, 0, 40)
    toggleFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    toggleFrame.BorderSizePixel = 0
    toggleFrame.Parent = contentFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = toggleFrame

    local label = Instance.new("TextLabel")
    label.Text = name
    label.Font = Enum.Font.Gotham
    label.TextSize = 18
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = toggleFrame

    local toggleButton = Instance.new("ImageButton")
    toggleButton.Size = UDim2.new(0, 50, 0, 26)
    toggleButton.Position = UDim2.new(1, -65, 0, 7)
    toggleButton.BackgroundColor3 = default and Color3.fromRGB(85, 220, 100) or Color3.fromRGB(100, 100, 100)
    toggleButton.BorderSizePixel = 0
    toggleButton.Parent = toggleFrame
    toggleButton.Name = "Toggle"

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggleButton

    local toggleCircle = Instance.new("Frame")
    toggleCircle.Size = UDim2.new(0, 22, 0, 22)
    toggleCircle.Position = default and UDim2.new(1, -24, 0, 2) or UDim2.new(0, 2, 0, 2)
    toggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    toggleCircle.Name = "Circle"
    toggleCircle.Parent = toggleButton

    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = toggleCircle

    local toggled = default

    local function updateVisual()
        if toggled then
            toggleButton.BackgroundColor3 = Color3.fromRGB(85, 220, 100)
            toggleCircle:TweenPosition(UDim2.new(1, -24, 0, 2), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
        else
            toggleButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            toggleCircle:TweenPosition(UDim2.new(0, 2, 0, 2), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
        end
    end

    toggleButton.MouseButton1Click:Connect(function()
        toggled = not toggled
        updateVisual()
        callback(toggled)
    end)

    updateVisual()
end

-- Corrigir o drag para funcionar bem
local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- Botão minimizar/maximizar
local minimized = false
toggleBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        contentFrame.Visible = false
        mainFrame.Size = UDim2.new(0, 280, 0, 40)
        toggleBtn.Text = "+"
    else
        contentFrame.Visible = true
        mainFrame.Size = UDim2.new(0, 280, 0, 360)
        toggleBtn.Text = "—"
    end
end)

-- Criar toggles e linkar com flags _G
local togglesData = {
    {name = "Aimbot Automático", flag = "aimbotAutoEnabled"},
    {name = "Aimbot Manual", flag = "aimbotManualEnabled"},
    {name = "ESP Inimigos", flag = "espEnemiesEnabled"},
    {name = "ESP Aliados", flag = "espAlliesEnabled"},
    {name = "Sem Recoil", flag = "noRecoilEnabled"},
    {name = "Munição Infinita", flag = "infiniteAmmoEnabled"},
    {name = "Recarga Instantânea", flag = "instantReloadEnabled"},
    {name = "Mostrar FOV", flag = "FOV_VISIBLE"},
}

for _, toggleInfo in ipairs(togglesData) do
    createToggle(toggleInfo.name, _G[toggleInfo.flag] or false, function(state)
        _G[toggleInfo.flag] = state
        print(toggleInfo.name .. " set to " .. tostring(state))
    end)
end

-- Funções auxiliares

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
    return next(teams) == nil or next(teams, next(teams)) == nil
end

local function hasLineOfSight(targetPart)
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit * 500
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local result = workspace:Raycast(origin, direction, raycastParams)
    return not result or result.Instance:IsDescendantOf(targetPart.Parent)
end

local function getClosestVisibleEnemy()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local closestEnemy = nil
    local shortestDistance = _G.FOV_RADIUS
    local ffa = isFFA()

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer or not player.Character then continue end
        if not isAlive(player.Character) then continue end

        local isAlly = player.Team == LocalPlayer.Team
        if not ffa then
            if isAlly and not _G.espAlliesEnabled then continue end
            if not isAlly and not _G.espEnemiesEnabled then continue end
        else
            if not _G.espEnemiesEnabled then continue end
        end

        local head = player.Character:FindFirstChild("Head")
        if head then
            local screenPos, visible = Camera:WorldToViewportPoint(head.Position)
            local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
            if visible and dist <= shortestDistance and hasLineOfSight(head) then
                shortestDistance = dist
                closestEnemy = player
            end
        end
    end
    return closestEnemy
end

-- Highlights para wallhack
local highlights = {}

local function updateHighlight(player, isTarget)
    if not player.Character then return end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        if highlights[player] then highlights[player].Enabled = false end
        return
    end

    local isAlly = (player.Team == LocalPlayer.Team)
    local ffa = isFFA()
    local show = false

    if ffa then
        show = _G.espEnemiesEnabled
    else
        show = (isAlly and _G.espAlliesEnabled) or (not isAlly and _G.espEnemiesEnabled)
    end

    if not show then
        if highlights[player] then highlights[player].Enabled = false end
        return
    end

    local highlight = highlights[player]
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Parent = workspace
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillTransparency = 0.5
        highlights[player] = highlight
    end

    highlight.Adornee = player.Character
    highlight.Enabled = true

    if isTarget then
        highlight.FillColor = Color3.fromRGB(255, 255, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
        highlight.FillTransparency = 0.3
    else
        if isAlly then
            highlight.FillColor = Color3.fromRGB(0, 170, 255)
            highlight.OutlineColor = Color3.fromRGB(0, 85, 170)
        else
            highlight.FillColor = Color3.fromRGB(255, 50, 50)
            highlight.OutlineColor = Color3.fromRGB(150, 0, 0)
        end
    end
end

local function updateAllHighlights()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            updateHighlight(player, player == currentTarget)
        elseif highlights[player] then
            highlights[player].Enabled = false
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        updateAllHighlights()
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    if highlights[player] then
        highlights[player]:Destroy()
        highlights[player] = nil
    end
end)

RunService.RenderStepped:Connect(function()
    updateAllHighlights()
end)

-- Aimbot e funcionalidades relacionadas
local currentTarget = nil
local aiming = false
local shooting = false

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

local function shootGun(tool)
    if not tool then return end
    for i = 1, 5 do
        task.wait(0.04)
    end
end

RunService.RenderStepped:Connect(function()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    if _G.aimbotAutoEnabled or (_G.aimbotManualEnabled and aiming and shooting) then
        local target = getClosestVisibleEnemy()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local head = target.Character.Head
            local headPos, visible = Camera:WorldToViewportPoint(head.Position)
            if visible and (Vector2.new(headPos.X, headPos.Y) - center).Magnitude <= _G.FOV_RADIUS and hasLineOfSight(head) then
                currentTarget = target
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
                local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
                if tool then
                    shootGun(tool)
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

-- Aplicar atributos de arma (munição infinita, sem recoil, recarga instantânea)
local function applyGunAttributes(tool)
    if not tool then return end
    if _G.noRecoilEnabled then
        tool:SetAttribute("recoilAimReduction", Vector2.new(0, 0))
        tool:SetAttribute("recoilMax", Vector2.new(0, 0))
        tool:SetAttribute("recoilMin", Vector2.new(0, 0))
        tool:SetAttribute("spread", 0)
    end
    if _G.infiniteAmmoEnabled then
        tool:SetAttribute("_ammo", 200)
        tool:SetAttribute("magazineSize", 200)
    end
    if _G.instantReloadEnabled then
        tool:SetAttribute("reloadTime", 0)
    end
end

local function onCharacterAdded(character)
    local tool
    repeat
        tool = character:FindFirstChildWhichIsA("Tool")
        task.wait()
    until tool
    applyGunAttributes(tool)
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
if LocalPlayer.Character then onCharacterAdded(LocalPlayer.Character) end
LocalPlayer.CharacterRemoving:Connect(function()
    currentTarget = nil
end)
