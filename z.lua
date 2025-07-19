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

-- Criação do GUI principal
local gui = Instance.new("ScreenGui")
gui.Name = "MobileAimbotGUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local menu = Instance.new("Frame")
menu.Size = UDim2.new(0, 220, 0, 480)
menu.AnchorPoint = Vector2.new(0, 0)
menu.Position = UDim2.new(0, 20, 0, 100)
menu.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
menu.BackgroundTransparency = 0.1
menu.BorderSizePixel = 0
menu.ClipsDescendants = true
menu.Parent = gui
menu.Name = "MainMenu"
menu.Active = true

local uicorner = Instance.new("UICorner")
uicorner.CornerRadius = UDim.new(0, 12)
uicorner.Parent = menu

-- Título do menu (efeito RGB/Matrix)
local title = Instance.new("TextLabel")
title.Text = "Krypton Tools"
title.Size = UDim2.new(1, 0, 0, 36)
title.BackgroundTransparency = 1
title.Font = Enum.Font.Code
title.TextSize = 28
title.Parent = menu
title.Name = "Title"
title.AnchorPoint = Vector2.new(0, 0)

-- Efeito RGB/Matrix no título
local hue = 0
RunService.RenderStepped:Connect(function()
    hue = (hue + 0.003) % 1
    local color = Color3.fromHSV(hue, 1, 1)
    title.TextColor3 = color
end)

-- Drag para mover o menu pela barra do título (corrigido)
local dragging = false
local dragStart = nil
local startPos = nil

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = menu.Position
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

title.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        menu.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- Botão minimizar/maximizar
local toggleVisibilityBtn = Instance.new("TextButton")
toggleVisibilityBtn.Size = UDim2.new(0, 40, 0, 30)
toggleVisibilityBtn.Position = UDim2.new(1, -45, 0, 3)
toggleVisibilityBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleVisibilityBtn.TextColor3 = Color3.new(1,1,1)
toggleVisibilityBtn.Font = Enum.Font.GothamBold
toggleVisibilityBtn.TextSize = 20
toggleVisibilityBtn.Text = "–"
toggleVisibilityBtn.Parent = menu
toggleVisibilityBtn.Name = "ToggleVisibility"

local minimized = false
toggleVisibilityBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        -- anima esconder o menu, só deixa o título visível
        menu.Size = UDim2.new(0, 220, 0, 36)
        toggleVisibilityBtn.Text = "+"
    else
        menu.Size = UDim2.new(0, 220, 0, 480)
        toggleVisibilityBtn.Text = "–"
    end
end)

-- Função para criar toggles arredondados com animação e debounce
local function createToggle(text, y)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 40)
    frame.Position = UDim2.new(0, 10, 0, y)
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
    toggleBtn.Size = UDim2.new(0, 50, 0, 25)
    toggleBtn.Position = UDim2.new(0.75, 0, 0.25, 0)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    toggleBtn.AutoButtonColor = false
    toggleBtn.Text = "OFF"
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
    toggleCircle.Position = UDim2.new(0, 5, 0.15, 0)
    toggleCircle.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    toggleCircle.Parent = toggleBtn
    local cornerCircle = Instance.new("UICorner")
    cornerCircle.CornerRadius = UDim.new(1, 0)
    cornerCircle.Parent = toggleCircle

    -- Hover effect
    toggleBtn.MouseEnter:Connect(function()
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(90, 90, 90)}):Play()
    end)
    toggleBtn.MouseLeave:Connect(function()
        local color = toggleBtn.Text == "ON" and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(70, 70, 70)
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
    end)

    local debounce = false
    -- Função para atualizar visual do toggle com animação
    local function updateToggleState(isOn)
        if debounce then return end
        debounce = true
        if isOn then
            toggleBtn.Text = "ON"
            local tween1 = TweenService:Create(toggleBtn, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(0, 170, 0)})
            local tween2 = TweenService:Create(toggleCircle, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 25, 0.15, 0)})
            tween1:Play()
            tween2:Play()
            tween2.Completed:Wait()
        else
            toggleBtn.Text = "OFF"
            local tween1 = TweenService:Create(toggleBtn, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(70, 70, 70)})
            local tween2 = TweenService:Create(toggleCircle, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 5, 0.15, 0)})
            tween1:Play()
            tween2:Play()
            tween2.Completed:Wait()
        end
        debounce = false
    end

    return {
        frame = frame,
        toggleBtn = toggleBtn,
        update = updateToggleState,
        getState = function() return toggleBtn.Text == "ON" end
    }
end

-- Criar toggles e ligar aos flags globais
local toggles = {}

local function bindToggle(text, flagName, y)
    local tog = createToggle(text, y)
    tog.update(_G[flagName])
    tog.toggleBtn.MouseButton1Click:Connect(function()
        _G[flagName] = not _G[flagName]
        tog.update(_G[flagName])
    end)
    toggles[flagName] = tog
end

bindToggle("Aimbot Auto", "aimbotAutoEnabled", 50)
bindToggle("Aimbot Manual", "aimbotManualEnabled", 100)
bindToggle("ESP Inimigos", "espEnemiesEnabled", 150)
bindToggle("ESP Aliados", "espAlliesEnabled", 200)
bindToggle("No Recoil", "noRecoilEnabled", 250)
bindToggle("Munição Infinita", "infiniteAmmoEnabled", 300)
bindToggle("Recarga Instantânea", "instantReloadEnabled", 350)

-- Ajuste do tamanho do menu e interface
local menuSizeOptions = {
    {size = UDim2.new(0, 200, 0, 340), yStep = 36, btnW = 40, btnH = 26, font = 16},
    {size = UDim2.new(0, 240, 0, 400), yStep = 44, btnW = 50, btnH = 30, font = 18},
    {size = UDim2.new(0, 170, 0, 260), yStep = 30, btnW = 32, btnH = 20, font = 13}
}
local currentMenuSizeIndex = 1

-- Função para atualizar layout dos toggles e botões
local function updateMenuLayout()
    local opt = menuSizeOptions[currentMenuSizeIndex]
    menu.Size = opt.size
    -- Não centraliza, mantém no canto
    menu.Position = UDim2.new(0, 20, 0, 100)
    title.Size = UDim2.new(1, 0, 0, opt.yStep)
    title.TextSize = opt.font + 6
    toggleVisibilityBtn.Size = UDim2.new(0, opt.btnW, 0, opt.btnH)
    toggleVisibilityBtn.Position = UDim2.new(1, -opt.btnW-5, 0, 3)
    sizeBtn.Size = UDim2.new(0, opt.btnW, 0, opt.btnH)
    sizeBtn.Position = UDim2.new(1, -2*opt.btnW-10, 0, 3)

    -- Reposiciona os toggles
    local y = opt.yStep + 10
    local step = opt.yStep + 4
    for _, flag in ipairs({
        {"Aimbot Auto", "aimbotAutoEnabled"},
        {"Aimbot Manual", "aimbotManualEnabled"},
        {"ESP Inimigos", "espEnemiesEnabled"},
        {"ESP Aliados", "espAlliesEnabled"},
        {"No Recoil", "noRecoilEnabled"},
        {"Munição Infinita", "infiniteAmmoEnabled"},
        {"Recarga Instantânea", "instantReloadEnabled"},
    }) do
        local tog = toggles[flag[2]]
        if tog then
            tog.frame.Size = UDim2.new(1, -20, 0, opt.yStep)
            tog.frame.Position = UDim2.new(0, 10, 0, y)
            tog.toggleBtn.Size = UDim2.new(0, opt.btnW, 0, opt.btnH)
            tog.toggleBtn.Position = UDim2.new(0.75, 0, 0.5, -opt.btnH/2)
            tog.toggleBtn.TextSize = opt.font
            y = y + step
        end
    end

    -- Mostrar FOV toggle
    if toggles["showFov"] then
        toggles["showFov"].frame.Size = UDim2.new(1, -20, 0, opt.yStep)
        toggles["showFov"].frame.Position = UDim2.new(0, 10, 0, y)
        toggles["showFov"].toggleBtn.Size = UDim2.new(0, opt.btnW, 0, opt.btnH)
        toggles["showFov"].toggleBtn.Position = UDim2.new(0.75, 0, 0.5, -opt.btnH/2)
        toggles["showFov"].toggleBtn.TextSize = opt.font
        y = y + step
    end

    -- FOV + e - botões
    fovMinusBtn.Size = UDim2.new(0, opt.btnW, 0, opt.btnH)
    fovPlusBtn.Size = UDim2.new(0, opt.btnW, 0, opt.btnH)
    fovMinusBtn.Position = UDim2.new(0, 40, 0, y)
    fovPlusBtn.Position = UDim2.new(0, 120, 0, y)
    fovMinusBtn.TextSize = opt.font + 2
    fovPlusBtn.TextSize = opt.font + 2
end

-- Botão engrenagem (ajuste de tamanho)
local sizeBtn = Instance.new("TextButton")
sizeBtn.Size = UDim2.new(0, 40, 0, 26)
sizeBtn.Position = UDim2.new(1, -85, 0, 3)
sizeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
sizeBtn.TextColor3 = Color3.new(1, 1, 1)
sizeBtn.Font = Enum.Font.GothamBold
sizeBtn.TextSize = 20
sizeBtn.Text = "⚙️"
sizeBtn.Parent = menu
sizeBtn.Name = "SizeButton"

sizeBtn.MouseButton1Click:Connect(function()
    currentMenuSizeIndex = currentMenuSizeIndex % #menuSizeOptions + 1
    updateMenuLayout()
end)

-- Remover label FOV antigo, criar toggle Mostrar FOV e botões +/-
if fovLabel then fovLabel:Destroy() end

local function bindShowFovToggle(y)
    local tog = createToggle("Mostrar FOV", y)
    tog.update(_G.FOV_VISIBLE)
    tog.toggleBtn.MouseButton1Click:Connect(function()
        _G.FOV_VISIBLE = not _G.FOV_VISIBLE
        tog.update(_G.FOV_VISIBLE)
    end)
    toggles["showFov"] = tog
end

bindShowFovToggle(410)

-- Botões + e - para FOV
local function createFOVButton(text, xPos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 40, 0, 26)
    btn.Position = UDim2.new(0, xPos, 0, 460)
    btn.BackgroundColor3 = Color3.fromRGB(70,70,70)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 20
    btn.Text = text
    btn.Parent = menu

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(90,90,90)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70,70,70)}):Play()
    end)

    btn.MouseButton1Click:Connect(function()
        if text == "+" then
            _G.FOV_RADIUS = math.clamp(_G.FOV_RADIUS + 5, 10, 300)
        else
            _G.FOV_RADIUS = math.clamp(_G.FOV_RADIUS - 5, 10, 300)
        end
    end)
    return btn
end

local fovMinusBtn = createFOVButton("-", 40)
local fovPlusBtn = createFOVButton("+", 120)

-- Inicializa layout adaptado
updateMenuLayout()

-- Drag para mover o menu pela barra do título
local dragging = false
local dragStart = nil
local startPos = nil

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = menu.Position
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

title.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
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
sizeBtn.Size = UDim2.new(0, 40, 0, 26)
sizeBtn.Position = UDim2.new(1, -85, 0, 3)
sizeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
sizeBtn.TextColor3 = Color3.new(1, 1, 1)
sizeBtn.Font = Enum.Font.GothamBold
sizeBtn.TextSize = 20
sizeBtn.Text = "⚙️"
sizeBtn.Parent = menu
sizeBtn.Name = "SizeButton"

sizeBtn.MouseButton1Click:Connect(function()
    currentMenuSizeIndex = currentMenuSizeIndex % #menuSizeOptions + 1
    updateMenuLayout()
end)

-- Remover label FOV antigo, criar toggle Mostrar FOV e botões +/-
if fovLabel then fovLabel:Destroy() end

local function bindShowFovToggle(y)
    local tog = createToggle("Mostrar FOV", y)
    tog.update(_G.FOV_VISIBLE)
    tog.toggleBtn.MouseButton1Click:Connect(function()
        _G.FOV_VISIBLE = not _G.FOV_VISIBLE
        tog.update(_G.FOV_VISIBLE)
    end)
    toggles["showFov"] = tog
end

bindShowFovToggle(410)

-- Botões + e - para FOV
local function createFOVButton(text, xPos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 40, 0, 26)
    btn.Position = UDim2.new(0, xPos, 0, 460)
    btn.BackgroundColor3 = Color3.fromRGB(70,70,70)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 20
    btn.Text = text
    btn.Parent = menu

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(90,90,90)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70,70,70)}):Play()
    end)

    btn.MouseButton1Click:Connect(function()
        if text == "+" then
            _G.FOV_RADIUS = math.clamp(_G.FOV_RADIUS + 5, 10, 300)
        else
            _G.FOV_RADIUS = math.clamp(_G.FOV_RADIUS - 5, 10, 300)
        end
    end)
    return btn
end

local fovMinusBtn = createFOVButton("-", 40)
local fovPlusBtn = createFOVButton("+", 120)

-- Inicializa layout adaptado
updateMenuLayout()

-- Drag para mover o menu pela barra do título
local dragging = false
local dragStart = nil
local startPos = nil

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = menu.Position
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

title.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        menu.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)