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
_G.RapidFireEnabled = false
_G.RapidFire = nil

-- Armazenar valores padrão das armas
local defaultWeaponAttributes = {}

-- Função para salvar valores padrão
local function saveDefaultAttributes(tool)
    if not tool or not tool:IsA("Tool") then return end
    if defaultWeaponAttributes[tool] then return end
    defaultWeaponAttributes[tool] = {
        reloadTime = tool:GetAttribute("reloadTime"),
        RapidFire = tool:GetAttribute("RapidFire"),
        magazineSize = tool:GetAttribute("magazineSize"),
        _ammo = tool:GetAttribute("_ammo"),
        spread = tool:GetAttribute("spread"),
        recoilMin = tool:GetAttribute("recoilMin"),
        recoilMax = tool:GetAttribute("recoilMax"),
        recoilAimReduction = tool:GetAttribute("recoilAimReduction"),
    }
end

-- Função para restaurar valores padrão
local function restoreDefaultAttributes(tool)
    local defaults = defaultWeaponAttributes[tool]
    if not defaults then return end
    for attr, val in pairs(defaults) do
        if val ~= nil then
            tool:SetAttribute(attr, val)
        end
    end
end

-- Função para aplicar cheats
local function applyWeaponCheats(tool)
    if not tool or not tool:IsA("Tool") then return end
    saveDefaultAttributes(tool)
    -- RapidFire
    if _G.RapidFireEnabled and _G.RapidFire then
        tool:SetAttribute("RapidFire", _G.RapidFire)
    end
    -- No Recoil
    if _G.noRecoilEnabled then
        tool:SetAttribute("recoilAimReduction", Vector2.new(0, 0))
        tool:SetAttribute("recoilMax", Vector2.new(0, 0))
        tool:SetAttribute("recoilMin", Vector2.new(0, 0))
        tool:SetAttribute("spread", 0)
    end
    -- Infinite Ammo
    if _G.infiniteAmmoEnabled then
        tool:SetAttribute("_ammo", 200)
        tool:SetAttribute("magazineSize", 200)
    end
    -- Instant Reload
    if _G.instantReloadEnabled then
        tool:SetAttribute("reloadTime", 0)
    end
end

-- Função para atualizar cheats ou restaurar padrão
local function updateWeaponAttributes(tool)
    if not tool or not tool:IsA("Tool") then return end
    -- RapidFire
    if not _G.RapidFireEnabled then
        restoreDefaultAttributes(tool)
    else
        applyWeaponCheats(tool)
    end
    -- No Recoil
    if not _G.noRecoilEnabled then
        restoreDefaultAttributes(tool)
    else
        applyWeaponCheats(tool)
    end
    -- Infinite Ammo
    if not _G.infiniteAmmoEnabled then
        restoreDefaultAttributes(tool)
    else
        applyWeaponCheats(tool)
    end
    -- Instant Reload
    if not _G.instantReloadEnabled then
        restoreDefaultAttributes(tool)
    else
        applyWeaponCheats(tool)
    end
end

-- Atualiza todos os tools do personagem
local function updateAllTools()
    if LocalPlayer.Character then
        for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
            if tool:IsA("Tool") then
                updateWeaponAttributes(tool)
            end
        end
    end
end

-- Eventos para atualizar armas ao equipar/desativar cheats
LocalPlayer.CharacterAdded:Connect(function(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait(0.1)
            updateWeaponAttributes(child)
        end
    end)
end)
if LocalPlayer.Character then
    for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
        if tool:IsA("Tool") then
            updateWeaponAttributes(tool)
        end
    end
end

-- Menu responsivo, arrastável, ScrollingFrame
local gui = Instance.new("ScreenGui")
gui.Name = "KryptonToolsGUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local menuSizes = {
    UDim2.new(0, 240, 0, 420),
    UDim2.new(0, 300, 0, 520),
    UDim2.new(0, 180, 0, 340)
}
local currentMenuSize = 1

local menu = Instance.new("ScrollingFrame")
menu.Size = menuSizes[currentMenuSize]
menu.Position = UDim2.new(0, 20, 0, 40)
menu.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
menu.BackgroundTransparency = 0.1
menu.BorderSizePixel = 0
menu.ClipsDescendants = true
menu.ScrollBarThickness = 4
menu.CanvasSize = UDim2.new(0, 0, 0, 700)
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
title.Size = UDim2.new(1, 0, 0, 38)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(0, 1, 0)
title.Font = Enum.Font.Code
title.TextSize = 26
title.Parent = menu
title.Name = "Title"
title.TextXAlignment = Enum.TextXAlignment.Center

-- Efeito RGB animado no título
task.spawn(function()
    local t = 0
    while true do
        t = t + 0.03
        local r = math.abs(math.sin(t)) * 0.7 + 0.3
        local g = math.abs(math.sin(t + 2)) * 0.7 + 0.3
        local b = math.abs(math.sin(t + 4)) * 0.7 + 0.3
        title.TextColor3 = Color3.new(r, g, b)
        task.wait(0.03)
    end
end)

-- Engrenagem para trocar tamanho do menu
local sizeBtn = Instance.new("TextButton")
sizeBtn.Size = UDim2.new(0, 32, 0, 32)
sizeBtn.Position = UDim2.new(1, -38, 0, 3)
sizeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
sizeBtn.TextColor3 = Color3.new(1, 1, 1)
sizeBtn.Font = Enum.Font.GothamBold
sizeBtn.TextSize = 20
sizeBtn.Text = "⚙️"
sizeBtn.Parent = menu
sizeBtn.Name = "SizeButton"
local sizeBtnCorner = Instance.new("UICorner")
sizeBtnCorner.CornerRadius = UDim.new(1, 0)
sizeBtnCorner.Parent = sizeBtn

sizeBtn.MouseButton1Click:Connect(function()
    currentMenuSize = currentMenuSize % #menuSizes + 1
    menu.Size = menuSizes[currentMenuSize]
end)

-- Drag para mover o menu
local dragging, dragStart, startPos = false, nil, nil
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
        local newY = math.max(0, startPos.Y.Offset + delta.Y)
        menu.Position = UDim2.new(0, math.max(0, startPos.X.Offset + delta.X), 0, newY)
    end
end)

-- Botão minimizar/maximizar
local toggleVisibilityBtn = Instance.new("TextButton")
toggleVisibilityBtn.Size = UDim2.new(0, 32, 0, 32)
toggleVisibilityBtn.Position = UDim2.new(1, -76, 0, 3)
toggleVisibilityBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
toggleVisibilityBtn.TextColor3 = Color3.new(1,1,1)
toggleVisibilityBtn.Font = Enum.Font.GothamBold
toggleVisibilityBtn.TextSize = 20
toggleVisibilityBtn.Text = "–"
toggleVisibilityBtn.Parent = menu
toggleVisibilityBtn.Name = "ToggleVisibility"
local toggleBtnCorner = Instance.new("UICorner")
toggleBtnCorner.CornerRadius = UDim.new(1, 0)
toggleBtnCorner.Parent = toggleVisibilityBtn

local minimized = false
toggleVisibilityBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        menu.CanvasSize = UDim2.new(0,0,0,0)
        menu.Size = UDim2.new(menu.Size.X.Scale, menu.Size.X.Offset, 0, 38)
        toggleVisibilityBtn.Text = "+"
    else
        menu.Size = menuSizes[currentMenuSize]
        menu.CanvasSize = UDim2.new(0,0,0,700)
        toggleVisibilityBtn.Text = "–"
    end
end)

-- Função para criar toggles arredondados
local function createToggle(text, y, flagName, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -24, 0, 38)
    frame.Position = UDim2.new(0, 12, 0, y)
    frame.BackgroundTransparency = 1
    frame.Parent = menu

    local label = Instance.new("TextLabel")
    label.Text = text
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.Gotham
    label.TextSize = 18
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 48, 0, 24)
    toggleBtn.Position = UDim2.new(0.75, 0, 0.25, 0)
    toggleBtn.BackgroundColor3 = _G[flagName] and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(70, 70, 70)
    toggleBtn.AutoButtonColor = false
    toggleBtn.Text = _G[flagName] and "ON" or "OFF"
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextColor3 = Color3.new(1, 1, 1)
    toggleBtn.TextSize = 16
    toggleBtn.Parent = frame
    toggleBtn.Name = "ToggleButton"

    local cornerBtn = Instance.new("UICorner")
    cornerBtn.CornerRadius = UDim.new(0, 8)
    cornerBtn.Parent = toggleBtn

    local toggleCircle = Instance.new("Frame")
    toggleCircle.Size = UDim2.new(0, 20, 0, 20)
    toggleCircle.Position = _G[flagName] and UDim2.new(0, 25, 0.15, 0) or UDim2.new(0, 5, 0.15, 0)
    toggleCircle.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    toggleCircle.Parent = toggleBtn
    local cornerCircle = Instance.new("UICorner")
    cornerCircle.CornerRadius = UDim.new(1, 0)
    cornerCircle.Parent = toggleCircle

    toggleBtn.MouseEnter:Connect(function()
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(90, 90, 90)}):Play()
    end)
    toggleBtn.MouseLeave:Connect(function()
        local color = toggleBtn.Text == "ON" and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(70, 70, 70)
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
    end)

    toggleBtn.MouseButton1Click:Connect(function()
        _G[flagName] = not _G[flagName]
        local isOn = _G[flagName]
        toggleBtn.Text = isOn and "ON" or "OFF"
        TweenService:Create(toggleBtn, TweenInfo.new(0.3), {BackgroundColor3 = isOn and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(70, 70, 70)}):Play()
        TweenService:Create(toggleCircle, TweenInfo.new(0.3), {Position = isOn and UDim2.new(0, 25, 0.15, 0) or UDim2.new(0, 5, 0.15, 0)}):Play()
        if callback then callback(isOn) end
        updateAllTools()
    end)
    return frame
end

-- Layout dos toggles
local y = 50
local spacing = 44
createToggle("Aimbot Auto", y, "aimbotAutoEnabled")
createToggle("Aimbot Manual", y + spacing, "aimbotManualEnabled")
createToggle("ESP Inimigos", y + spacing*2, "espEnemiesEnabled")
createToggle("ESP Aliados", y + spacing*3, "espAlliesEnabled")
createToggle("No Recoil", y + spacing*4, "noRecoilEnabled", function() updateAllTools() end)
createToggle("Munição Infinita", y + spacing*5, "infiniteAmmoEnabled", function() updateAllTools() end)
createToggle("Recarga Instantânea", y + spacing*6, "instantReloadEnabled", function() updateAllTools() end)

-- Toggle Mostrar FOV
local fovToggle = createToggle("Mostrar FOV", y + spacing*7, "FOV_VISIBLE")

-- Botões de FOV centralizados
local fovBtnFrame = Instance.new("Frame")
fovBtnFrame.Size = UDim2.new(1, -24, 0, 36)
fovBtnFrame.Position = UDim2.new(0, 12, 0, y + spacing*8)
fovBtnFrame.BackgroundTransparency = 1
fovBtnFrame.Parent = menu

local fovMinus = Instance.new("TextButton")
fovMinus.Size = UDim2.new(0, 48, 0, 28)
fovMinus.Position = UDim2.new(0.25, -24, 0, 4)
fovMinus.BackgroundColor3 = Color3.fromRGB(70,70,70)
fovMinus.TextColor3 = Color3.new(1,1,1)
fovMinus.Font = Enum.Font.GothamBold
fovMinus.TextSize = 22
fovMinus.Text = "-"
fovMinus.Parent = fovBtnFrame
local fovMinusCorner = Instance.new("UICorner")
fovMinusCorner.CornerRadius = UDim.new(0, 8)
fovMinusCorner.Parent = fovMinus

local fovPlus = Instance.new("TextButton")
fovPlus.Size = UDim2.new(0, 48, 0, 28)
fovPlus.Position = UDim2.new(0.75, -24, 0, 4)
fovPlus.BackgroundColor3 = Color3.fromRGB(70,70,70)
fovPlus.TextColor3 = Color3.new(1,1,1)
fovPlus.Font = Enum.Font.GothamBold
fovPlus.TextSize = 22
fovPlus.Text = "+"
fovPlus.Parent = fovBtnFrame
local fovPlusCorner = Instance.new("UICorner")
fovPlusCorner.CornerRadius = UDim.new(0, 8)
fovPlusCorner.Parent = fovPlus

fovMinus.MouseButton1Click:Connect(function()
    _G.FOV_RADIUS = math.clamp(_G.FOV_RADIUS - 5, 10, 300)
end)
fovPlus.MouseButton1Click:Connect(function()
    _G.FOV_RADIUS = math.clamp(_G.FOV_RADIUS + 5, 10, 300)
end)

-- Toggle RapidFire
local rapidFireToggle = createToggle("RAPID FIRE", y + spacing*9, "RapidFireEnabled", function(isOn)
    if not isOn then
        _G.RapidFire = nil
    end
    updateAllTools()
end)

-- Botão de modo RapidFire centralizado
local rapidFireModes = {200, 500, 999999999999}
local rapidFireNames = {"Legit", "Médio", "Agressivo"}
local rapidFireBtnFrame = Instance.new("Frame")
rapidFireBtnFrame.Size = UDim2.new(1, -24, 0, 36)
rapidFireBtnFrame.Position = UDim2.new(0, 12, 0, y + spacing*10)
rapidFireBtnFrame.BackgroundTransparency = 1
rapidFireBtnFrame.Parent = menu

local rapidFireBtn = Instance.new("TextButton")
rapidFireBtn.Size = UDim2.new(0, 120, 0, 28)
rapidFireBtn.Position = UDim2.new(0.5, -60, 0, 4)
rapidFireBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
rapidFireBtn.TextColor3 = Color3.new(1, 1, 1)
rapidFireBtn.Font = Enum.Font.GothamBold
rapidFireBtn.TextSize = 18
rapidFireBtn.Text = rapidFireNames[1]
rapidFireBtn.Parent = rapidFireBtnFrame
local rapidFireBtnCorner = Instance.new("UICorner")
rapidFireBtnCorner.CornerRadius = UDim.new(0, 8)
rapidFireBtnCorner.Parent = rapidFireBtn

local rapidFireIndex = 1
rapidFireBtn.MouseButton1Click:Connect(function()
    rapidFireIndex = rapidFireIndex % #rapidFireModes + 1
    _G.RapidFire = rapidFireModes[rapidFireIndex]
    rapidFireBtn.Text = rapidFireNames[rapidFireIndex]
    updateAllTools()
end)

-- Atualiza texto do botão ao ativar/desativar RapidFire
rapidFireToggle.ToggleButton.MouseButton1Click:Connect(function()
    if not _G.RapidFireEnabled then
        rapidFireBtn.Text = rapidFireNames[1]
        rapidFireIndex = 1
        _G.RapidFire = nil
    else
        _G.RapidFire = rapidFireModes[rapidFireIndex]
        rapidFireBtn.Text = rapidFireNames[rapidFireIndex]
    end
    updateAllTools()
end)

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
    if _G.RapidFire then
        tool:SetAttribute("RapidFire", _G.RapidFire)
    end
end

-- Função para ajustar o tiro por RapidFire
local function shootGun(tool)
    if not tool then return end
    local fireRate = tool:GetAttribute("RapidFire") or 70
    for i = 1, 5 do
        task.wait(1 / fireRate) -- Ajuste do RapidFire
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

-- Criar os toggles para RapidFire
local RapidFireOptions = {nil, 200, 500, 99999999999999}
local RapidFireRateName = {"Padrão", "Legit", "Médio", "Agressivo"}

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
    toggleBtn.Text = RapidFireRateName[1]
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
        _G.RapidFire = RapidFireOptions[((table.find(RapidFireOptions, _G.RapidFire) or 1) % #RapidFireOptions) + 1]
        toggleBtn.Text = RapidFireRateName[table.find(RapidFireOptions, _G.RapidFire)]
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