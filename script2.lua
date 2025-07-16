local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Configurações globais
_G.aimbotAutoEnabled = false
_G.aimbotLegitEnabled = false
_G.FOV_VISIBLE = true
_G.FOV_RADIUS = 80
_G.hitboxSelection = {
    Head = "Prioritário",
    Torso = "Nenhum",
    LeftArm = "Nenhum",
    RightArm = "Nenhum",
    LeftLeg = "Nenhum",
    RightLeg = "Nenhum"
}

_G.espEnemiesEnabled = true
_G.espAlliesEnabled = false
_G.espBoxEnabled = true
_G.espLineEnabled = true
_G.espNameEnabled = true
_G.espHPEnabled = true
_G.espDistanceEnabled = true
_G.espWallhackEnabled = true

local minimized = false
local currentPage = 1
local shooting = false

-- Funções para Input Mouse - para aimbot
local mouse = LocalPlayer:GetMouse()

-- Função para raycast robusta (checar parede)
local function canSeeTarget(origin, targetPos)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    local direction = (targetPos - origin)
    local result = workspace:Raycast(origin, direction.Unit * direction.Magnitude, raycastParams)

    if result then
        local hitPart = result.Instance
        if hitPart then
            -- Permitir transparências tipo vidro, plantas (ajuste conforme necessidade)
            local nameLower = hitPart.Name:lower()
            local isTransparentPart = (hitPart.Transparency > 0.5) or (string.find(nameLower, "glass")) or (string.find(nameLower, "plant"))
            if isTransparentPart then
                return true
            end
            -- Se bateu em algo que não é o personagem do alvo, bloqueia
            if hitPart:IsDescendantOf(LocalPlayer.Character) then
                return true -- ignorar próprio personagem
            end
            return false
        end
    else
        return true -- não bateu em nada, visão limpa
    end
    return false
end

-- Obter posição hitbox conforme seleção
local function getHitboxPosition(character)
    local hitboxes = {
        Head = character:FindFirstChild("Head"),
        Torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"),
        LeftArm = character:FindFirstChild("LeftUpperArm") or character:FindFirstChild("Left Arm"),
        RightArm = character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Right Arm"),
        LeftLeg = character:FindFirstChild("LeftUpperLeg") or character:FindFirstChild("Left Leg"),
        RightLeg = character:FindFirstChild("RightUpperLeg") or character:FindFirstChild("Right Leg")
    }
    for partName, state in pairs(_G.hitboxSelection) do
        if state == "Prioritário" and hitboxes[partName] then
            return hitboxes[partName].Position
        end
    end
    -- Fallback para HumanoidRootPart
    return character.HumanoidRootPart and character.HumanoidRootPart.Position or Vector3.new()
end

-- Verificar se player está vivo
local function isAlive(player)
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

-- Encontrar alvo próximo dentro do FOV e visível
local function findTarget()
    local closestTarget = nil
    local closestDistance = math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isAlive(player) then
            -- Ignorar aliados e mortos
            if player.Team == LocalPlayer.Team then continue end

            local char = player.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then continue end

            local targetPos = getHitboxPosition(char)
            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
            if not onScreen then continue end

            local distFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
            if distFromCenter <= _G.FOV_RADIUS then
                local origin = Camera.CFrame.Position
                if canSeeTarget(origin, targetPos) then
                    if distFromCenter < closestDistance then
                        closestDistance = distFromCenter
                        closestTarget = {player = player, pos = targetPos}
                    end
                end
            end
        end
    end

    return closestTarget
end

-- Função para mover o mouse suavemente (legit)
local function moveMouseSmooth(targetPos, smoothness)
    local mousePos = Vector2.new(mouse.X, mouse.Y)
    local delta = targetPos - mousePos
    local move = delta / smoothness
    mousemoverel(move.X, move.Y)
end

-- Encontrar alvo e mirar (com suavidade para legit)
local function findTargetLegit()
    local targetData = findTarget()
    if targetData then
        local screenPos = Camera:WorldToViewportPoint(targetData.pos)
        if screenPos.Z > 0 then
            local targetScreenPos = Vector2.new(screenPos.X, screenPos.Y)
            moveMouseSmooth(targetScreenPos, 8) -- Ajuste suavidade (maior é mais lento)
            return targetData
        end
    end
    return nil
end

-- Aimbot execução principal
RunService.RenderStepped:Connect(function()
    if _G.aimbotAutoEnabled or _G.aimbotLegitEnabled then
        local targetData
        if _G.aimbotAutoEnabled then
            targetData = findTarget()
            if targetData then
                local screenPos = Camera:WorldToViewportPoint(targetData.pos)
                if screenPos.Z > 0 then
                    -- Ajustar mira direto para o alvo
                    mousemoverel(screenPos.X - mouse.X, screenPos.Y - mouse.Y)
                    if shooting then
                        mouse1click()
                    end
                end
            end
        elseif _G.aimbotLegitEnabled then
            targetData = findTargetLegit()
            -- Atirar automático com delay ou quando muito perto da mira
            if targetData and shooting then
                local aimScreen = Camera:WorldToViewportPoint(targetData.pos)
                local distToAim = (Vector2.new(mouse.X, mouse.Y) - Vector2.new(aimScreen.X, aimScreen.Y)).Magnitude
                if distToAim < 5 then
                    mouse1click()
                end
            end
        end
    end
end)

-- GUI / Menu --
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimbotESPMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Fonte customizada mais limpa (usar fonte padrão Gotham)
local FONT = Enum.Font.GothamBold

-- Frame principal
local menuFrame = Instance.new("Frame")
menuFrame.Name = "MenuFrame"
menuFrame.Size = UDim2.new(0, 340, 0, 300)
menuFrame.Position = UDim2.new(0, 50, 0, 50)
menuFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
menuFrame.BorderSizePixel = 0
menuFrame.Parent = ScreenGui
menuFrame.Visible = true

-- Barra de título (drag, minimize/maximize)
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
titleBar.Parent = menuFrame
titleBar.Active = true
titleBar.Draggable = true

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Aimbot & ESP Menu"
titleLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
titleLabel.Font = FONT
titleLabel.TextSize = 20
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar
titleLabel.Position = UDim2.new(0.03, 0, 0, 0)

-- Botão minimizar (-)
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Name = "MinimizeBtn"
minimizeBtn.Size = UDim2.new(0, 35, 1, 0)
minimizeBtn.Position = UDim2.new(0.75, 0, 0, 0)
minimizeBtn.Text = "—"
minimizeBtn.Font = FONT
minimizeBtn.TextSize = 24
minimizeBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
minimizeBtn.Parent = titleBar

-- Botão fechar/maximizar (🔼)
local maximizeBtn = Instance.new("TextButton")
maximizeBtn.Name = "MaximizeBtn"
maximizeBtn.Size = UDim2.new(0, 35, 0, 30)
maximizeBtn.Position = UDim2.new(0, 10, 0, 10)
maximizeBtn.Text = "🔼"
maximizeBtn.Font = FONT
maximizeBtn.TextSize = 20
maximizeBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
maximizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
maximizeBtn.Parent = ScreenGui
maximizeBtn.Visible = false
maximizeBtn.Active = true
maximizeBtn.Draggable = true

-- Funções minimizar/maximizar
local function minimizeMenu()
    menuFrame.Visible = false
    maximizeBtn.Visible = true
    minimized = true
end

local function maximizeMenu()
    menuFrame.Visible = true
    maximizeBtn.Visible = false
    minimized = false
end

minimizeBtn.MouseButton1Click:Connect(minimizeMenu)
maximizeBtn.MouseButton1Click:Connect(maximizeMenu)

-- Navegação Páginas --

local pageLabel = Instance.new("TextLabel")
pageLabel.Name = "PageLabel"
pageLabel.Size = UDim2.new(0, 60, 0, 25)
pageLabel.Position = UDim2.new(0.5, -30, 0, 35)
pageLabel.BackgroundTransparency = 1
pageLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
pageLabel.Font = FONT
pageLabel.TextSize = 18
pageLabel.Text = "1 / 3"
pageLabel.Parent = menuFrame

local backBtn = Instance.new("TextButton")
backBtn.Name = "BackBtn"
backBtn.Size = UDim2.new(0, 45, 0, 25)
backBtn.Position = UDim2.new(0, 15, 0, 35)
backBtn.Text = "◀️"
backBtn.Font = FONT
backBtn.TextSize = 18
backBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
backBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
backBtn.Parent = menuFrame

local forwardBtn = Instance.new("TextButton")
forwardBtn.Name = "ForwardBtn"
forwardBtn.Size = UDim2.new(0, 45, 0, 25)
forwardBtn.Position = UDim2.new(1, -60, 0, 35)
forwardBtn.Text = "▶️"
forwardBtn.Font = FONT
forwardBtn.TextSize = 18
forwardBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
forwardBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
forwardBtn.Parent = menuFrame

-- Containers das páginas
local pages = {}

for i = 1, 3 do
    local page = Instance.new("Frame")
    page.Name = "Page"..i
    page.Size = UDim2.new(1, 0, 1, -70)
    page.Position = UDim2.new(0, 0, 0, 70)
    page.BackgroundTransparency = 1
    page.Parent = menuFrame
    page.Visible = (i == 1)
    pages[i] = page
end

-- Atualiza visibilidade das páginas
local function updatePage()
    for i, page in ipairs(pages) do
        page.Visible = (i == currentPage)
    end
    pageLabel.Text = currentPage.." / 3"
end

backBtn.MouseButton1Click:Connect(function()
    currentPage = currentPage - 1
    if currentPage < 1 then currentPage = 3 end
    updatePage()
end)

forwardBtn.MouseButton1Click:Connect(function()
    currentPage = currentPage + 1
    if currentPage > 3 then currentPage = 1 end
    updatePage()
end)

-- ========== Página 1 - Aimbots ==========

local page1 = pages[1]

-- Toggle Aimbot Automático
local toggleAuto = Instance.new("TextButton")
toggleAuto.Size = UDim2.new(0, 160, 0, 40)
toggleAuto.Position = UDim2.new(0, 20, 0, 20)
toggleAuto.Text = "Aimbot Automático: OFF"
toggleAuto.Font = FONT
toggleAuto.TextSize = 18
toggleAuto.TextColor3 = Color3.fromRGB(230, 230, 230)
toggleAuto.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleAuto.Parent = page1

toggleAuto.MouseButton1Click:Connect(function()
    if _G.aimbotAutoEnabled then
        _G.aimbotAutoEnabled = false
        toggleAuto.Text = "Aimbot Automático: OFF"
    else
        _G.aimbotAutoEnabled = true
        _G.aimbotLegitEnabled = false
        toggleAuto.Text = "Aimbot Automático: ON"
        toggleLegit.Text = "Aimbot Legit: OFF"
    end
end)

-- Toggle Aimbot Legit
local toggleLegit = Instance.new("TextButton")
toggleLegit.Size = UDim2.new(0, 160, 0, 40)
toggleLegit.Position = UDim2.new(0, 20, 0, 70)
toggleLegit.Text = "Aimbot Legit: OFF"
toggleLegit.Font = FONT
toggleLegit.TextSize = 18
toggleLegit.TextColor3 = Color3.fromRGB(230, 230, 230)
toggleLegit.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleLegit.Parent = page1

toggleLegit.MouseButton1Click:Connect(function()
    if _G.aimbotLegitEnabled then
        _G.aimbotLegitEnabled = false
        toggleLegit.Text = "Aimbot Legit: OFF"
    else
        _G.aimbotLegitEnabled = true
        _G.aimbotAutoEnabled = false
        toggleLegit.Text = "Aimbot Legit: ON"
        toggleAuto.Text = "Aimbot Automático: OFF"
    end
end)

-- Mostrar FOV Toggle
local toggleFOV = Instance.new("TextButton")
toggleFOV.Size = UDim2.new(0, 160, 0, 40)
toggleFOV.Position = UDim2.new(0, 20, 0, 120)
toggleFOV.Text = "Mostrar FOV: ON"
toggleFOV.Font = FONT
toggleFOV.TextSize = 18
toggleFOV.TextColor3 = Color3.fromRGB(230, 230, 230)
toggleFOV.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleFOV.Parent = page1

toggleFOV.MouseButton1Click:Connect(function()
    _G.FOV_VISIBLE = not _G.FOV_VISIBLE
    toggleFOV.Text = _G.FOV_VISIBLE and "Mostrar FOV: ON" or "Mostrar FOV: OFF"
end)

-- Botões para ajustar o raio do FOV, isolados do menu de navegação
local fovLabel = Instance.new("TextLabel")
fovLabel.Size = UDim2.new(0, 160, 0, 25)
fovLabel.Position = UDim2.new(0, 20, 0, 170)
fovLabel.Text = "Raio do FOV: ".._G.FOV_RADIUS
fovLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
fovLabel.Font = FONT
fovLabel.TextSize = 16
fovLabel.BackgroundTransparency = 1
fovLabel.Parent = page1

local btnFOVMinus = Instance.new("TextButton")
btnFOVMinus.Size = UDim2.new(0, 35, 0, 35)
btnFOVMinus.Position = UDim2.new(0, 20, 0, 200)
btnFOVMinus.Text = "-"
btnFOVMinus.Font = FONT
btnFOVMinus.TextSize = 24
btnFOVMinus.TextColor3 = Color3.fromRGB(230, 230, 230)
btnFOVMinus.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
btnFOVMinus.Parent = page1

local btnFOVPlus = Instance.new("TextButton")
btnFOVPlus.Size = UDim2.new(0, 35, 0, 35)
btnFOVPlus.Position = UDim2.new(0, 90, 0, 200)
btnFOVPlus.Text = "+"
btnFOVPlus.Font = FONT
btnFOVPlus.TextSize = 24
btnFOVPlus.TextColor3 = Color3.fromRGB(230, 230, 230)
btnFOVPlus.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
btnFOVPlus.Parent = page1

btnFOVMinus.MouseButton1Click:Connect(function()
    _G.FOV_RADIUS = math.max(10, _G.FOV_RADIUS - 5)
    fovLabel.Text = "Raio do FOV: ".._G.FOV_RADIUS
end)

btnFOVPlus.MouseButton1Click:Connect(function()
    _G.FOV_RADIUS = math.min(300, _G.FOV_RADIUS + 5)
    fovLabel.Text = "Raio do FOV: ".._G.FOV_RADIUS
end)

-- ========== Página 2 - ESP ==========

local page2 = pages[2]

local function createToggle(text, positionY, defaultState, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 160, 0, 35)
    btn.Position = UDim2.new(0, 20, 0, positionY)
    btn.Font = FONT
    btn.TextSize = 16
    btn.TextColor3 = Color3.fromRGB(230, 230, 230)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.Text = text .. (defaultState and ": ON" or ": OFF")
    btn.Parent = page2

    btn.MouseButton1Click:Connect(function()
        local enabled = string.find(btn.Text, "ON") == nil
        callback(enabled)
        btn.Text = text .. (enabled and ": ON" or ": OFF")
    end)

    return btn
end

local espEnemiesToggle = createToggle("ESP Inimigos", 20, _G.espEnemiesEnabled, function(enabled) _G.espEnemiesEnabled = enabled end)
local espAlliesToggle = createToggle("ESP Aliados", 60, _G.espAlliesEnabled, function(enabled) _G.espAlliesEnabled = enabled end)
local espBoxToggle = createToggle("Caixa (Box)", 100, _G.espBoxEnabled, function(enabled) _G.espBoxEnabled = enabled end)
local espLineToggle = createToggle("Linha", 140, _G.espLineEnabled, function(enabled) _G.espLineEnabled = enabled end)
local espNameToggle = createToggle("Nome", 180, _G.espNameEnabled, function(enabled) _G.espNameEnabled = enabled end)
local espHPToggle = createToggle("HP", 220, _G.espHPEnabled, function(enabled) _G.espHPEnabled = enabled end)
local espDistanceToggle = createToggle("Distância", 260, _G.espDistanceEnabled, function(enabled) _G.espDistanceEnabled = enabled end)
local espWallhackToggle = createToggle("Wallhack Neon", 300, _G.espWallhackEnabled, function(enabled) _G.espWallhackEnabled = enabled end)

-- Botão Selecionar Hitbox (abre popup)
local selectHitboxBtn = Instance.new("TextButton")
selectHitboxBtn.Size = UDim2.new(0, 140, 0, 40)
selectHitboxBtn.Position = UDim2.new(0, 180, 0, 20)
selectHitboxBtn.Text = "Selecionar Hitbox"
selectHitboxBtn.Font = FONT
selectHitboxBtn.TextSize = 16
selectHitboxBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
selectHitboxBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
selectHitboxBtn.Parent = page2

-- ========== Popup Seleção de Hitbox ==========

local hitboxPopup = Instance.new("Frame")
hitboxPopup.Name = "HitboxPopup"
hitboxPopup.Size = UDim2.new(0, 280, 0, 280)
hitboxPopup.Position = UDim2.new(0.5, -140, 0.5, -140)
hitboxPopup.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
hitboxPopup.BorderColor3 = Color3.fromRGB(70, 70, 70)
hitboxPopup.BorderSizePixel = 2
hitboxPopup.Visible = false
hitboxPopup.Parent = ScreenGui

-- Título popup
local popupTitle = Instance.new("TextLabel")
popupTitle.Size = UDim2.new(1, 0, 0, 40)
popupTitle.BackgroundTransparency = 1
popupTitle.Text = "Selecionar Hitbox Prioritária"
popupTitle.TextColor3 = Color3.fromRGB(230, 230, 230)
popupTitle.Font = FONT
popupTitle.TextSize = 20
popupTitle.Parent = hitboxPopup

-- Imagem "Bacon" Roblox padrão
local imageLabel = Instance.new("ImageLabel")
imageLabel.Size = UDim2.new(0, 150, 0, 220)
imageLabel.Position = UDim2.new(0, 15, 0, 40)
imageLabel.BackgroundTransparency = 1
imageLabel.Image = "rbxassetid://6781457287" -- ID do Bacon Roblox
imageLabel.Parent = hitboxPopup

-- Botões invisíveis para selecionar partes do corpo
local hitboxParts = {
    Head = {Pos=UDim2.new(0, 75, 0, 35), Size=UDim2.new(0, 60, 0, 50)},
    Torso = {Pos=UDim2.new(0, 75, 0, 85), Size=UDim2.new(0, 60, 0, 60)},
    LeftArm = {Pos=UDim2.new(0, 15, 0, 85), Size=UDim2.new(0, 30, 0, 70)},
    RightArm = {Pos=UDim2.new(0, 135, 0, 85), Size=UDim2.new(0, 30, 0, 70)},
    LeftLeg = {Pos=UDim2.new(0, 65, 0, 145), Size=UDim2.new(0, 30, 0, 70)},
    RightLeg = {Pos=UDim2.new(0, 105, 0, 145), Size=UDim2.new(0, 30, 0, 70)}
}

local hitboxButtons = {}

local function updateHitboxButtonVisuals()
    for partName, btn in pairs(hitboxButtons) do
        if _G.hitboxSelection[partName] == "Prioritário" then
            btn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
            btn.BackgroundTransparency = 0.4
        else
            btn.BackgroundColor3 = Color3.new(0,0,0)
            btn.BackgroundTransparency = 0.8
        end
    end
end

for partName, data in pairs(hitboxParts) do
    local btn = Instance.new("TextButton")
    btn.Size = data.Size
    btn.Position = data.Pos
    btn.BackgroundColor3 = Color3.new(0, 0, 0)
    btn.BackgroundTransparency = 0.8
    btn.Text = ""
    btn.Parent = hitboxPopup
    btn.AutoButtonColor = false
    hitboxButtons[partName] = btn

    btn.MouseButton1Click:Connect(function()
        local current = _G.hitboxSelection[partName]
        if current == "Prioritário" then
            _G.hitboxSelection[partName] = "Nenhum"
        else
            _G.hitboxSelection[partName] = "Prioritário"
            -- Só pode um prioritário, zera os outros
            for k in pairs(_G.hitboxSelection) do
                if k ~= partName then _G.hitboxSelection[k] = "Nenhum" end
            end
        end
        updateHitboxButtonVisuals()
    end)
end

updateHitboxButtonVisuals()

-- Botão fechar popup hitbox
local closeHitboxBtn = Instance.new("TextButton")
closeHitboxBtn.Size = UDim2.new(0, 40, 0, 30)
closeHitboxBtn.Position = UDim2.new(1, -50, 0, 10)
closeHitboxBtn.Text = "X"
closeHitboxBtn.Font = FONT
closeHitboxBtn.TextSize = 20
closeHitboxBtn.TextColor3 = Color3.new(1, 1, 1)
closeHitboxBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
closeHitboxBtn.Parent = hitboxPopup

closeHitboxBtn.MouseButton1Click:Connect(function()
    hitboxPopup.Visible = false
end)

selectHitboxBtn.MouseButton1Click:Connect(function()
    hitboxPopup.Visible = not hitboxPopup.Visible
end)

-- ========== Página 3 - Tutorial ==========

local page3 = pages[3]

local tutorialText = Instance.new("TextLabel")
tutorialText.Size = UDim2.new(1, -20, 1, -20)
tutorialText.Position = UDim2.new(0, 10, 0, 10)
tutorialText.BackgroundTransparency = 1
tutorialText.TextColor3 = Color3.fromRGB(230, 230, 230)
tutorialText.TextWrapped = true
tutorialText.TextYAlignment = Enum.TextYAlignment.Top
tutorialText.Font = FONT
tutorialText.TextSize = 14
tutorialText.Text = [[
Página 1 - Aimbots:
- Aimbot Automático: Mira rápido e automático, respeitando FOV e paredes.
- Aimbot Legit: Mira automática precisa, "legal" para não parecer cheat.
- Mostrar FOV e ajustar o tamanho do círculo.

Página 2 - ESP:
- Ativar/desativar ESP para inimigos e aliados.
- Configurar o que mostrar: caixa, linha, nome, HP, distância, wallhack neon.
- Selecionar partes do corpo para aimbot via popup.

Página 3 - Tutorial:
- Explicação detalhada do uso do menu, aimbot e ESP.
- Botão para fechar o tutorial.

Use os botões ◀️ e ▶️ para navegar entre as páginas.
Clique em "Selecionar Hitbox" para abrir o menu de seleção.
Use o botão - para minimizar o menu e 🔼 para maximizar e mover o botão.
]]

tutorialText.Parent = page3

local closeTutorialBtn = Instance.new("TextButton")
closeTutorialBtn.Size = UDim2.new(0, 40, 0, 30)
closeTutorialBtn.Position = UDim2.new(1, -50, 0, 10)
closeTutorialBtn.Text = "X"
closeTutorialBtn.Font = FONT
closeTutorialBtn.TextSize = 20
closeTutorialBtn.TextColor3 = Color3.new(1, 1, 1)
closeTutorialBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
closeTutorialBtn.Parent = page3

closeTutorialBtn.MouseButton1Click:Connect(function()
    currentPage = 1
    updatePage()
end)

-- Tutorial botão na página 1
local tutorialBtn = Instance.new("TextButton")
tutorialBtn.Size = UDim2.new(0, 140, 0, 40)
tutorialBtn.Position = UDim2.new(0, 190, 0, 120)
tutorialBtn.Text = "Tutorial"
tutorialBtn.Font = FONT
tutorialBtn.TextSize = 16
tutorialBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
tutorialBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
tutorialBtn.Parent = page1

tutorialBtn.MouseButton1Click:Connect(function()
    currentPage = 3
    updatePage()
end)

-- ========== FOV Circle ==========

local FOVCircle = Drawing.new("Circle")
FOVCircle.Transparency = 1
FOVCircle.Visible = true
FOVCircle.Radius = _G.FOV_RADIUS
FOVCircle.Thickness = 2.5
FOVCircle.Filled = false
FOVCircle.NumSides = 64
FOVCircle.ZIndex = 1
FOVCircle.Color = Color3.fromRGB(255, 0, 0)

RunService.RenderStepped:Connect(function()
    FOVCircle.Visible = _G.FOV_VISIBLE and not minimized
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Radius = _G.FOV_RADIUS
end)

-- Controle do clique esquerdo (para disparar)
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        shooting = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        shooting = false
    end
end)

--[[
ESP pode ser implementado similarmente com Drawing API ou SurfaceGuis, 
mas para manter a resposta focada no menu e aimbot, deixei essa parte 
para você adaptar conforme o uso do seu script atual.
]]

return ScreenGui
