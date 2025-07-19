-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Flags globais padrão
_G.FOV_RADIUS = 65
_G.FOV_VISIBLE = true
_G.aimbotAutoEnabled = false
_G.aimbotManualEnabled = false
_G.espEnemiesEnabled = true
_G.espAlliesEnabled = false
_G.noRecoilEnabled = true
_G.infiniteAmmoEnabled = false
_G.instantReloadEnabled = true
_G.rateOfFire = 70

-- Tamanhos do menu
local menuSizes = {
    {w = 200, h = 400, font = 18, title = 28, btn = 18, pad = 8},
    {w = 240, h = 500, font = 20, title = 34, btn = 20, pad = 12},
    {w = 300, h = 600, font = 24, title = 40, btn = 24, pad = 16},
}
local menuSizeIdx = 2

-- Criação do GUI principal
local gui = Instance.new("ScreenGui")
gui.Name = "KryptonToolsGUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Menu principal como ScrollingFrame
local menu = Instance.new("ScrollingFrame")
menu.Size = UDim2.new(0, menuSizes[menuSizeIdx].w, 0, menuSizes[menuSizeIdx].h)
menu.Position = UDim2.new(0, 20, 0, 80)
menu.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
menu.BackgroundTransparency = 0.08
menu.BorderSizePixel = 0
menu.ScrollBarThickness = 6
menu.CanvasSize = UDim2.new(0, 0, 0, 800)
menu.ClipsDescendants = true
menu.Parent = gui
menu.Name = "MainMenu"
menu.Active = true
menu.AutomaticCanvasSize = Enum.AutomaticSize.Y

local uicorner = Instance.new("UICorner")
uicorner.CornerRadius = UDim.new(0, 12)
uicorner.Parent = menu

-- Título com efeito RGB/Matrix
local title = Instance.new("TextLabel")
title.Text = "Krypton Tools"
title.Size = UDim2.new(1, 0, 0, menuSizes[menuSizeIdx].title)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(0,255,0)
title.Font = Enum.Font.Code
title.TextSize = menuSizes[menuSizeIdx].title
title.Parent = menu
title.Name = "Title"
title.Position = UDim2.new(0, 0, 0, 0)
title.TextStrokeTransparency = 0.7

-- RGB/Matrix effect
task.spawn(function()
    local t = 0
    while true do
        t += 0.03
        local r = math.abs(math.sin(t)) * 0.7 + 0.3
        local g = math.abs(math.sin(t + 2)) * 0.7 + 0.3
        local b = math.abs(math.sin(t + 4)) * 0.7 + 0.3
        title.TextColor3 = Color3.new(r, g, b)
        task.wait(0.03)
    end
end)

-- Botão minimizar/maximizar
local toggleVisibilityBtn = Instance.new("TextButton")
toggleVisibilityBtn.Size = UDim2.new(0, 36, 0, menuSizes[menuSizeIdx].title - 6)
toggleVisibilityBtn.Position = UDim2.new(1, -44, 0, 4)
toggleVisibilityBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleVisibilityBtn.TextColor3 = Color3.new(1,1,1)
toggleVisibilityBtn.Font = Enum.Font.Code
toggleVisibilityBtn.TextSize = menuSizes[menuSizeIdx].btn
toggleVisibilityBtn.Text = "–"
toggleVisibilityBtn.Parent = menu
toggleVisibilityBtn.Name = "ToggleVisibility"
local minimized = false

toggleVisibilityBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        menu.CanvasPosition = Vector2.new(0,0)
        menu.Size = UDim2.new(0, menuSizes[menuSizeIdx].w, 0, menuSizes[menuSizeIdx].title + 8)
        toggleVisibilityBtn.Text = "+"
        for _, v in ipairs(menu:GetChildren()) do
            if v ~= title and v ~= toggleVisibilityBtn and v ~= sizeBtn then v.Visible = false end
        end
    else
        menu.Size = UDim2.new(0, menuSizes[menuSizeIdx].w, 0, menuSizes[menuSizeIdx].h)
        toggleVisibilityBtn.Text = "–"
        for _, v in ipairs(menu:GetChildren()) do
            v.Visible = true
        end
    end
end)

-- Botão engrenagem para alternar tamanho
local sizeBtn = Instance.new("TextButton")
sizeBtn.Size = UDim2.new(0, 32, 0, menuSizes[menuSizeIdx].title - 6)
sizeBtn.Position = UDim2.new(1, -84, 0, 4)
sizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
sizeBtn.TextColor3 = Color3.new(1,1,1)
sizeBtn.Font = Enum.Font.Code
sizeBtn.TextSize = menuSizes[menuSizeIdx].btn
sizeBtn.Text = "⚙️"
sizeBtn.Parent = menu
sizeBtn.Name = "SizeButton"

local function applyMenuSize()
    local sz = menuSizes[menuSizeIdx]
    menu.Size = UDim2.new(0, sz.w, 0, minimized and (sz.title + 8) or sz.h)
    title.TextSize = sz.title
    toggleVisibilityBtn.TextSize = sz.btn
    sizeBtn.TextSize = sz.btn
    toggleVisibilityBtn.Size = UDim2.new(0, 36, 0, sz.title - 6)
    sizeBtn.Size = UDim2.new(0, 32, 0, sz.title - 6)
    toggleVisibilityBtn.Position = UDim2.new(1, -44, 0, 4)
    sizeBtn.Position = UDim2.new(1, -84, 0, 4)
    -- Ajustar todos os toggles e botões
    for _, v in ipairs(menu:GetChildren()) do
        if v:IsA("Frame") and v:FindFirstChild("Label") then
            v.Size = UDim2.new(1, -2*sz.pad, 0, sz.font + sz.pad*2)
            v.Label.TextSize = sz.font
            if v:FindFirstChild("ToggleButton") then
                v.ToggleButton.TextSize = sz.font
                v.ToggleButton.Size = UDim2.new(0, sz.font*2.2, 0, sz.font+sz.pad)
            end
        end
        if v:IsA("Frame") and v.Name == "FOVBtns" then
            for _, btn in ipairs(v:GetChildren()) do
                if btn:IsA("TextButton") then
                    btn.TextSize = sz.font
                    btn.Size = UDim2.new(0, sz.font*2.2, 0, sz.font+sz.pad)
                end
            end
        end
    end
end

sizeBtn.MouseButton1Click:Connect(function()
    menuSizeIdx = menuSizeIdx % #menuSizes + 1
    applyMenuSize()
end)

-- Drag para mover o menu pela barra do título
local dragging, dragStart, startPos = false, nil, nil
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = menu.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
title.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        menu.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- Função para criar toggles arredondados
local function createToggle(text, flagName, y)
    local sz = menuSizes[menuSizeIdx]
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -2*sz.pad, 0, sz.font + sz.pad*2)
    frame.Position = UDim2.new(0, sz.pad, 0, y)
    frame.BackgroundTransparency = 1
    frame.Parent = menu

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Text = text
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.Code
    label.TextSize = sz.font
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "ToggleButton"
    toggleBtn.Size = UDim2.new(0, sz.font*2.2, 0, sz.font+sz.pad)
    toggleBtn.Position = UDim2.new(0.75, 0, 0.15, 0)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    toggleBtn.AutoButtonColor = false
    toggleBtn.Text = _G[flagName] and "ON" or "OFF"
    toggleBtn.Font = Enum.Font.Code
    toggleBtn.TextColor3 = Color3.new(1, 1, 1)
    toggleBtn.TextSize = sz.font
    toggleBtn.Parent = frame

    local cornerBtn = Instance.new("UICorner")
    cornerBtn.CornerRadius = UDim.new(0, 8)
    cornerBtn.Parent = toggleBtn

    local function updateToggleState(isOn)
        toggleBtn.Text = isOn and "ON" or "OFF"
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = isOn and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(70, 70, 70)
        }):Play()
    end
    updateToggleState(_G[flagName])

    toggleBtn.MouseButton1Click:Connect(function()
        _G[flagName] = not _G[flagName]
        updateToggleState(_G[flagName])
    end)

    return frame
end

-- Criação dos toggles principais
local y = menuSizes[menuSizeIdx].title + menuSizes[menuSizeIdx].pad*2
local function addToggle(text, flag)
    local frame = createToggle(text, flag, y)
    y = y + frame.Size.Y.Offset + menuSizes[menuSizeIdx].pad
end

addToggle("Aimbot Auto", "aimbotAutoEnabled")
addToggle("Aimbot Manual", "aimbotManualEnabled")
addToggle("ESP Inimigos", "espEnemiesEnabled")
addToggle("ESP Aliados", "espAlliesEnabled")
addToggle("No Recoil", "noRecoilEnabled")
addToggle("Munição Infinita", "infiniteAmmoEnabled")
addToggle("Recarga Instantânea", "instantReloadEnabled")

-- Mostrar FOV: toggle ON/OFF
local fovToggleFrame = createToggle("Mostrar FOV", "FOV_VISIBLE", y)
y = y + fovToggleFrame.Size.Y.Offset + menuSizes[menuSizeIdx].pad

-- Botões + e - centralizados para FOV
local fovBtnsFrame = Instance.new("Frame")
fovBtnsFrame.Name = "FOVBtns"
fovBtnsFrame.Size = UDim2.new(1, -2*menuSizes[menuSizeIdx].pad, 0, menuSizes[menuSizeIdx].font + menuSizes[menuSizeIdx].pad*2)
fovBtnsFrame.Position = UDim2.new(0, menuSizes[menuSizeIdx].pad, 0, y)
fovBtnsFrame.BackgroundTransparency = 1
fovBtnsFrame.Parent = menu

local btnW = menuSizes[menuSizeIdx].font*2.2
local pad = menuSizes[menuSizeIdx].pad
local totalW = btnW*2 + pad
local startX = (fovBtnsFrame.AbsoluteSize.X - totalW) / 2

local function createFOVBtn(text, xPos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, btnW, 0, menuSizes[menuSizeIdx].font+pad)
    btn.Position = UDim2.new(0, xPos, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(70,70,70)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.Code
    btn.TextSize = menuSizes[menuSizeIdx].font
    btn.Text = text
    btn.Parent = fovBtnsFrame
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    btn.MouseButton1Click:Connect(function()
        if text == "+" then
            _G.FOV_RADIUS = math.clamp(_G.FOV_RADIUS + 5, 10, 300)
        else
            _G.FOV_RADIUS = math.clamp(_G.FOV_RADIUS - 5, 10, 300)
        end
    end)
end
createFOVBtn("-", 0)
createFOVBtn("+", btnW + pad)

y = y + fovBtnsFrame.Size.Y.Offset + menuSizes[menuSizeIdx].pad

-- Rate of Fire: toggle ON/OFF
local rofFrame = createToggle("Rate of Fire", "rateOfFireEnabled", y)
y = y + rofFrame.Size.Y.Offset + menuSizes[menuSizeIdx].pad

-- Botão centralizado para alternar modos de Rate of Fire
local rofModes = {
    {name = "Padrão", value = 150},
    {name = "Legit", value = 200},
    {name = "Médio", value = 500},
    {name = "Agressivo", value = 9999999},
}
local rofIdx = 1
_G.rateOfFire = rofModes[rofIdx].value

local rofBtn = Instance.new("TextButton")
rofBtn.Size = UDim2.new(0.7, 0, 0, menuSizes[menuSizeIdx].font+menuSizes[menuSizeIdx].pad)
rofBtn.Position = UDim2.new(0.15, 0, 0, y)
rofBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
rofBtn.TextColor3 = Color3.new(1,1,1)
rofBtn.Font = Enum.Font.Code
rofBtn.TextSize = menuSizes[menuSizeIdx].font
rofBtn.Text = rofModes[rofIdx].name
rofBtn.Parent = menu
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = rofBtn

rofBtn.MouseButton1Click:Connect(function()
    rofIdx = rofIdx % #rofModes + 1
    rofBtn.Text = rofModes[rofIdx].name
    _G.rateOfFire = rofModes[rofIdx].value
end)

y = y + rofBtn.Size.Y.Offset + menuSizes[menuSizeIdx].pad

-- Drag para mover o menu pela barra do título
local dragging = false
local dragStart = nil
local startPos = nil

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = menu.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

title.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        menu.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

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

-- Buscar inimigo visível mais próximo dentro do FOV
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

-- ESP Wallhack com Highlights
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

-- Variáveis do aimbot
local currentTarget = nil
local aiming = false
local shooting = false

-- Eventos de input para aimbot manual
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

-- Função para mirar no inimigo
local function aimAtTarget(target)
    if not target or not target.Character then return end
    local head = target.Character:FindFirstChild("Head")
    if not head then return end

    local cameraCFrame = Camera.CFrame
    local direction = (head.Position - cameraCFrame.Position).Unit
    Camera.CFrame = CFrame.new(cameraCFrame.Position, head.Position)
end

-- Loop principal do aimbot e ESP
RunService.RenderStepped:Connect(function()
    if _G.aimbotAutoEnabled or (_G.aimbotManualEnabled and aiming) then
        currentTarget = getClosestVisibleEnemy()
        if currentTarget then
            aimAtTarget(currentTarget)
        end
    else
        currentTarget = nil
    end
end)

-- Aplicar cheats na arma atual
local function patchWeapon(tool)
    if tool and tool:IsA("Tool") then
        if _G.infiniteAmmoEnabled and tool:FindFirstChild("Ammo") then
            tool.Ammo.Value = math.huge
        end
        if _G.noRecoilEnabled and tool:FindFirstChild("Recoil") then
            tool.Recoil.Value = 0
        end
        if _G.instantReloadEnabled and tool:FindFirstChild("ReloadTime") then
            tool.ReloadTime.Value = 0
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait(0.1)
            patchWeapon(child)
        end
    end)
end)

if LocalPlayer.Character then
    for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
        if tool:IsA("Tool") then
            patchWeapon(tool)
        end
    end
end

-- Função para aplicar os atributos de arma
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
    if _G.rateOfFire then
        tool:SetAttribute("rateOfFire", _G.rateOfFire)
    end
end

-- Função para ajustar o tiro por rateOfFire
local function shootGun(tool)
    if not tool then return end
    local fireRate = tool:GetAttribute("rateOfFire") or 70
    for i = 1, 5 do
        task.wait(1 / fireRate) -- Ajuste do rateOfFire
    end
end

-- Atualiza os atributos das armas quando o personagem é adicionado
local function onCharacterAdded(character)
    local tool
    repeat
        tool = character:FindFirstChildWhichIsA("Tool")
        task.wait()
    until tool
    applyGunAttributes(tool)
end

-- Funções de eventos para quando o personagem entra ou sai
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
if LocalPlayer.Character then onCharacterAdded(LocalPlayer.Character) end
LocalPlayer.CharacterRemoving:Connect(function()
    currentTarget = nil
end)

-- Ajustar tamanho do menu
local menuSizeOptions = {UDim2.new(0, 220, 0, 480), UDim2.new(0, 250, 0, 480), UDim2.new(0, 180, 0, 480)}
local currentMenuSizeIndex = 1

local function changeMenuSize()
    currentMenuSizeIndex = currentMenuSizeIndex % #menuSizeOptions + 1
    local newSize = menuSizeOptions[currentMenuSizeIndex]
    menu.Size = newSize
    -- Recentralizar o menu no meio da tela
    menu.Position = UDim2.new(0.5, -newSize.X.Offset / 2, 0.5, -newSize.Y.Offset / 2)
    -- Garantir que título continue no topo
    title.Position = UDim2.new(0, 0, 0, 0)
    -- Reposicionar botão de minimizar no canto superior direito
    toggleVisibilityBtn.Position = UDim2.new(1, -45, 0, 3)
    -- Reposicionar botão engrenagem logo abaixo do botão minimizar
    sizeBtn.Position = UDim2.new(1, -45, 0, 40)
end

-- Adicionando o botão de configuração de tamanho
local sizeBtn = Instance.new("TextButton")
sizeBtn.Size = UDim2.new(0, 30, 0, 30)
sizeBtn.Position = UDim2.new(1, -45, 0, 50)
sizeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
sizeBtn.TextColor3 = Color3.new(1, 1, 1)
sizeBtn.Font = Enum.Font.GothamBold
sizeBtn.TextSize = 20
sizeBtn.Text = "⚙️"
sizeBtn.Parent = menu
sizeBtn.Name = "SizeButton"

sizeBtn.MouseButton1Click:Connect(function()
    changeMenuSize()
end)

-- Iniciar o menu no centro da tela
menu.Position = UDim2.new(0.5, -menu.Size.X.Offset / 2, 0.5, -menu.Size.Y.Offset / 2)

-- Título do menu ajustado
title.Position = UDim2.new(0.5, -title.Size.X.Offset / 2, 0, 0)

-- Criar os toggles para rateOfFire
local fireRateOptions = {50, 70, 100, 150, 200}
local fireRateNames = {"Padrão", "Médio", "Rápido", "Agressivo", "RapidFire"}

local function createFireRateToggle()
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 40)
    frame.Position = UDim2.new(0, 10, 0, 450)
    frame.BackgroundTransparency = 1
    frame.Parent = menu

    local label = Instance.new("TextLabel")
    label.Text = "Rate of Fire"
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.Gotham
    label.TextSize = 18
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 50, 0, 25)
    toggleBtn.Position = UDim2.new(0.75, 0, 0.25, 0)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    toggleBtn.AutoButtonColor = false
    toggleBtn.Text = fireRateNames[1]
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextColor3 = Color3.new(1, 1, 1)
    toggleBtn.TextSize = 16
    toggleBtn.Parent = frame
    toggleBtn.Name = "ToggleButton"

    local cornerBtn = Instance.new("UICorner")
    cornerBtn.CornerRadius = UDim.new(0, 8)
    cornerBtn.Parent = toggleBtn

    local debounce = false
    toggleBtn.MouseButton1Click:Connect(function()
        if debounce then return end
        debounce = true
        _G.rateOfFire = fireRateOptions[((table.find(fireRateOptions, _G.rateOfFire) or 1) % #fireRateOptions) + 1]
        toggleBtn.Text = fireRateNames[table.find(fireRateOptions, _G.rateOfFire)]
        debounce = false
    end)
end

createFireRateToggle()

-- Ajustar o tamanho do menu conforme solicitado
local dragging = false
local dragStart = nil
local startPos = nil

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = menu.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

title.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        menu.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)