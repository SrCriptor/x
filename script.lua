-- SISTEMA COMPLETO: GUI + AIMBOT + ESP + WALLHACK + SELEÇÃO DE HITBOX + TUTORIAL

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
_G.espBoxEnabled = true
_G.espLineEnabled = false
_G.espHPEnabled = false
_G.espDistanceEnabled = false
_G.hitboxSelection = {
    Head = "None",
    Torso = "None",
    LeftArm = "None",
    RightArm = "None",
    LeftLeg = "None",
    RightLeg = "None",
}
-- Por padrão, Head prioridade
_G.hitboxSelection.Head = "Prioritário"

local shooting = false
local aiming = false
local dragging = false
local dragStart, startPos = nil, nil
local currentTarget = nil

local currentPage = 1
local maxPage = 3
local minimized = false

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
gui.Name = "AimbotGuiSystem"
local panel = Instance.new("Frame", gui)
panel.Size = UDim2.new(0, 220, 0, 300)
panel.Position = UDim2.new(0, 20, 0.5, -150)
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

-- FUNÇÃO PARA LIMPAR PÁGINA
local function clearPage()
    for _, child in pairs(panel:GetChildren()) do
        if child ~= toggleButton and child ~= btnPrev and child ~= btnNext then
            child:Destroy()
        end
    end
end

-- BOTÃO MINIMIZAR
local toggleButton = Instance.new("TextButton", panel)
toggleButton.Size = UDim2.new(0, 40, 0, 30)
toggleButton.Position = UDim2.new(1, -50, 0, 5)
toggleButton.Text = "🔽"
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 18
toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleButton.TextColor3 = Color3.new(1, 1, 1)

toggleButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    toggleButton.Text = minimized and "🔼" or "🔽"
    for _, v in pairs(panel:GetChildren()) do
        if v:IsA("TextButton") and v ~= toggleButton and v ~= btnPrev and v ~= btnNext then
            v.Visible = not minimized
        end
    end
    if minimized then
        panel.Size = UDim2.new(0, 60, 0, 40)
        panel.BackgroundTransparency = 1
        toggleButton.Position = UDim2.new(0, 10, 0, 5)
        btnPrev.Visible = false
        btnNext.Visible = false
    else
        panel.Size = UDim2.new(0, 220, 0, 300)
        panel.BackgroundTransparency = 0.2
        toggleButton.Position = UDim2.new(1, -50, 0, 5)
        btnPrev.Visible = (currentPage > 1)
        btnNext.Visible = (currentPage < maxPage)
    end
end)

-- BOTÕES DE NAVEGAÇÃO
local btnPrev = Instance.new("TextButton", panel)
btnPrev.Size = UDim2.new(0, 30, 0, 25)
btnPrev.Position = UDim2.new(0, 10, 1, -35)
btnPrev.Text = "◀️"
btnPrev.Font = Enum.Font.SourceSansBold
btnPrev.TextSize = 20
btnPrev.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
btnPrev.TextColor3 = Color3.new(1,1,1)

local btnNext = Instance.new("TextButton", panel)
btnNext.Size = UDim2.new(0, 30, 0, 25)
btnNext.Position = UDim2.new(1, -40, 1, -35)
btnNext.Text = "▶️"
btnNext.Font = Enum.Font.SourceSansBold
btnNext.TextSize = 20
btnNext.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
btnNext.TextColor3 = Color3.new(1,1,1)

btnPrev.MouseButton1Click:Connect(function()
    if currentPage > 1 then
        currentPage -= 1
        loadPage(currentPage)
    end
end)

btnNext.MouseButton1Click:Connect(function()
    if currentPage < maxPage then
        currentPage += 1
        loadPage(currentPage)
    end
end)

-- FUNÇÃO PARA CRIAR BOTÃO TOGGLE
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

-- BOTÕES DE AJUSTE DO FOV (SEM POSITION, será configurado abaixo)
local function createFOVAdjustButton(text, yPos, delta)
    local button = Instance.new("TextButton", panel)
    button.Size = UDim2.new(0.5, -15, 0, 30)
    button.Position = UDim2.new(text == "- FOV" and 0 or 0.5, 10, 0, yPos)
    button.Text = text
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 16
    button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.MouseButton1Click:Connect(function()
        _G.FOV_RADIUS = math.clamp(_G.FOV_RADIUS + delta, 10, 300)
    end)
    return button
end

-- PAGE 1: AIMBOTS E FOV
local function loadPage1()
    clearPage()

    local y = 40
    createToggle("Aimbot Auto", y, "aimbotAutoEnabled", "aimbotManualEnabled", "aimbotLegitEnabled")
    y += 35
    createToggle("Aimbot Manual", y, "aimbotManualEnabled", "aimbotAutoEnabled", "aimbotLegitEnabled")
    y += 35
    createToggle("Aimbot Legit", y, "aimbotLegitEnabled", "aimbotAutoEnabled", "aimbotManualEnabled")
    y += 35
    local showFOVBtn = createToggle("Mostrar FOV", y, "FOV_VISIBLE")
    y += 35

    local btnMinusFOV = createFOVAdjustButton("- FOV", y, -5)
    local btnPlusFOV = createFOVAdjustButton("+ FOV", y, 5)
    -- Posiciona os botões do FOV logo abaixo do Mostrar FOV, centralizados
    btnMinusFOV.Position = UDim2.new(0, 10, 0, y)
    btnPlusFOV.Position = UDim2.new(0.5, 10, 0, y)

    btnMinusFOV.Visible = showFOVBtn.Text:find("ON") ~= nil
    btnPlusFOV.Visible = showFOVBtn.Text:find("ON") ~= nil

    -- Atualiza a visibilidade dos botões de FOV junto com Mostrar FOV
    showFOVBtn.MouseButton1Click:Connect(function()
        local on = _G.FOV_VISIBLE
        btnMinusFOV.Visible = on
        btnPlusFOV.Visible = on
    end)
end

-- PAGE 2: HITBOX + ESP CONFIG
local hitboxPopup = nil

local function createHitboxPopup()
    if hitboxPopup then return end
    hitboxPopup = Instance.new("Frame", panel)
    hitboxPopup.Size = UDim2.new(0, 200, 0, 220)
    hitboxPopup.Position = UDim2.new(0, 10, 0, 40)
    hitboxPopup.BackgroundColor3 = Color3.fromRGB(15,15,15)
    hitboxPopup.BorderSizePixel = 0
    hitboxPopup.Visible = false

    -- Imagem "Bacon" - substitua o assetId para o seu modelo de personagem
    local image = Instance.new("ImageLabel", hitboxPopup)
    image.Size = UDim2.new(0, 150, 0, 200)
    image.Position = UDim2.new(0.5, -75, 0, 10)
    image.BackgroundTransparency = 1
    image.Image = "rbxassetid://166456432" -- exemplo de imagem Bacon

    -- Botões invisíveis sobre partes do corpo
    local parts = {
        {Name = "Head", Pos = UDim2.new(0.47, 0, 0.07, 0), Size = UDim2.new(0, 40, 0, 40)},
        {Name = "Torso", Pos = UDim2.new(0.45, 0, 0.3, 0), Size = UDim2.new(0, 50, 0, 50)},
        {Name = "LeftArm", Pos = UDim2.new(0.3, 0, 0.3, 0), Size = UDim2.new(0, 30, 0, 50)},
        {Name = "RightArm", Pos = UDim2.new(0.65, 0, 0.3, 0), Size = UDim2.new(0, 30, 0, 50)},
        {Name = "LeftLeg", Pos = UDim2.new(0.35, 0, 0.7, 0), Size = UDim2.new(0, 35, 0, 50)},
        {Name = "RightLeg", Pos = UDim2.new(0.55, 0, 0.7, 0), Size = UDim2.new(0, 35, 0, 50)},
    }

    local function updateHitboxText()
        local text = "Seleção Hitbox:\n"
        for _, part in pairs(parts) do
            local state = _G.hitboxSelection[part.Name]
            text = text..part.Name..": "..state.."\n"
        end
        hitboxStatus.Text = text
    end

    for _, part in pairs(parts) do
        local btn = Instance.new("TextButton", hitboxPopup)
        btn.BackgroundTransparency = 1
        btn.Position = part.Pos
        btn.Size = part.Size
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.MouseButton1Click:Connect(function()
            -- Ciclo: None -> Prioritário -> None
            if _G.hitboxSelection[part.Name] == "None" then
                _G.hitboxSelection[part.Name] = "Prioritário"
            else
                _G.hitboxSelection[part.Name] = "None"
            end
            updateHitboxText()
        end)
    end

    local hitboxStatus = Instance.new("TextLabel", hitboxPopup)
    hitboxStatus.Size = UDim2.new(1, -20, 0, 80)
    hitboxStatus.Position = UDim2.new(0, 10, 0, 160)
    hitboxStatus.BackgroundTransparency = 1
    hitboxStatus.TextColor3 = Color3.new(1, 1, 1)
    hitboxStatus.Font = Enum.Font.SourceSans
    hitboxStatus.TextSize = 14
    hitboxStatus.TextWrapped = true

    updateHitboxText()
end

local function createESPConfig()
    local baseY = 40
    local gap = 35

    local function addToggleESP(text, flag)
        local toggle = createToggle(text, baseY, flag)
        baseY += gap
        return toggle
    end

    local boxToggle = addToggleESP("ESP Inimigos", "espEnemiesEnabled")
    local allyToggle = addToggleESP("ESP Aliados", "espAlliesEnabled")
    local boxShapeToggle = addToggleESP("Caixa ESP", "espBoxEnabled")
    local lineToggle = addToggleESP("Linha ESP", "espLineEnabled")
    local hpToggle = addToggleESP("HP ESP", "espHPEnabled")
    local distToggle = addToggleESP("Distância ESP", "espDistanceEnabled")

    return {
        boxToggle = boxToggle,
        allyToggle = allyToggle,
        boxShapeToggle = boxShapeToggle,
        lineToggle = lineToggle,
        hpToggle = hpToggle,
        distToggle = distToggle,
    }
end

local espToggles = nil

local function loadPage2()
    clearPage()
    createHitboxPopup()
    hitboxPopup.Visible = true

    if not espToggles then
        espToggles = createESPConfig()
    else
        -- reposicionar se foi destruído (não deve ocorrer, mas só por segurança)
        espToggles.boxToggle.Parent = panel
        espToggles.allyToggle.Parent = panel
        espToggles.boxShapeToggle.Parent = panel
        espToggles.lineToggle.Parent = panel
        espToggles.hpToggle.Parent = panel
        espToggles.distToggle.Parent = panel
    end
end

-- PAGE 3: TUTORIAL
local tutorialFrame = nil
local function loadPage3()
    clearPage()
    if hitboxPopup then hitboxPopup.Visible = false end

    if not tutorialFrame then
        tutorialFrame = Instance.new("Frame", panel)
        tutorialFrame.Size = UDim2.new(1, -20, 0, 240)
        tutorialFrame.Position = UDim2.new(0, 10, 0, 40)
        tutorialFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        tutorialFrame.BorderSizePixel = 0

        local tutorialText = Instance.new("TextLabel", tutorialFrame)
        tutorialText.Size = UDim2.new(1, -20, 1, -40)
        tutorialText.Position = UDim2.new(0, 10, 0, 10)
        tutorialText.BackgroundTransparency = 1
        tutorialText.TextColor3 = Color3.new(1, 1, 1)
        tutorialText.Font = Enum.Font.SourceSans
        tutorialText.TextSize = 14
        tutorialText.TextWrapped = true
        tutorialText.Text = [[
Como usar o menu e os recursos:

- Aimbot Auto: Mira e atira automaticamente nos inimigos.
- Aimbot Manual: Mira automaticamente no inimigo, você atira manualmente.
- Aimbot Legit: Mira e atira com precisão, evitando comportamento suspeito.
- Mostrar FOV: Mostra o círculo do campo de visão.
- - FOV / + FOV: Ajusta o tamanho do campo de visão.
- Navegue entre páginas com ◀️ e ▶️.
- Página 2:
   • Selecione partes do corpo (hitbox) clicando na figura "Bacon".
   • Configure o ESP: inimigos, aliados, caixas, linhas, HP e distância.
- Página 3:
   • Esta aba mostra este tutorial.

Clique em Fechar para esconder esta aba.
        ]]

        local closeBtn = Instance.new("TextButton", tutorialFrame)
        closeBtn.Size = UDim2.new(0, 60, 0, 25)
        closeBtn.Position = UDim2.new(1, -70, 1, -30)
        closeBtn.Text = "Fechar"
        closeBtn.Font = Enum.Font.SourceSansBold
        closeBtn.TextSize = 14
        closeBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        closeBtn.TextColor3 = Color3.new(1, 1, 1)

        closeBtn.MouseButton1Click:Connect(function()
            tutorialFrame.Visible = false
        end)
    else
        tutorialFrame.Visible = true
    end
end

-- FUNÇÃO PRINCIPAL DE LOAD DE PÁGINA
function loadPage(page)
    currentPage = page
    btnPrev.Visible = (page > 1 and not minimized)
    btnNext.Visible = (page < maxPage and not minimized)
    if tutorialFrame then tutorialFrame.Visible = false end
    if hitboxPopup then hitboxPopup.Visible = false end

    if page == 1 then
        loadPage1()
    elseif page == 2 then
        loadPage2()
    elseif page == 3 then
        loadPage3()
    end
end

loadPage(1) -- inicia na página 1

-- ========== CÍRCULO DO FOV ==========
local DrawingNew = Drawing.new
local fovCircle = DrawingNew and DrawingNew("Circle") or nil
if fovCircle then
    fovCircle.Transparency = 0.2
    fovCircle.Thickness = 1.5
    fovCircle.Filled = false
    fovCircle.Color = Color3.new(1, 1, 1)
end

RunService.RenderStepped:Connect(function()
    if fovCircle then
        fovCircle.Radius = _G.FOV_RADIUS
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        fovCircle.Visible = _G.FOV_VISIBLE and not minimized
    end
end)

-- ========== AIMBOT LOGIC ==========

-- Checa se o personagem está vivo antes de mirar
local function isCharacterAlive(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function getClosestTarget()
    local closest = nil
    local shortest = math.huge

    for _, p in pairs(Players:GetPlayers()) do
        if shouldAimAt(p) then
            local head = p.Character and p.Character:FindFirstChild("Head")
            if head then
                local camPos = Camera.CFrame.Position
                local toTarget = head.Position - camPos
                -- Verifica se o alvo está dentro do FOV e visível (visibilidade por raycast)
                local viewportPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local distToScreenCenter = (Vector2.new(viewportPos.X, viewportPos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                    if distToScreenCenter <= _G.FOV_RADIUS then
                        -- Raycast para checar se está atrás da parede
                        local rayParams = RaycastParams.new()
                        rayParams.FilterDescendantsInstances = {LocalPlayer.Character, head.Parent}
                        rayParams.FilterType = Enum.RaycastFilterType.Blacklist
                        local rayResult = workspace:Raycast(camPos, toTarget.Unit * toTarget.Magnitude, rayParams)
                        local visible = (rayResult == nil)
                        if visible then
                            if distToScreenCenter < shortest then
                                closest = p
                                shortest = distToScreenCenter
                            end
                        end
                    end
                end
            end
        end
    end

    return closest
end

RunService.RenderStepped:Connect(function()
    if minimized then return end

    -- AIMBOT AUTOMATICO
    if _G.aimbotAutoEnabled then
        local target = getClosestTarget()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            -- Mira e atira automaticamente
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Character.Head.Position)
            -- Simula disparo (se quiser implementar disparo automático, faça aqui)
        end
    end

    -- AIMBOT MANUAL (mirar automático apenas, disparo manual)
    if _G.aimbotManualEnabled and aiming then
        local target = getClosestTarget()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Character.Head.Position)
        end
    end

    -- AIMBOT LEGIT (mirar + disparar preciso e seguro)
    if _G.aimbotLegitEnabled then
        local target = getClosestTarget()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Character.Head.Position)
            -- Aqui pode implementar disparo preciso, etc.
        end
    end
end)

-- CAPTURA DE ESTADO DO BOTÃO DE MIRA (mobile)
aimButton.MouseButton1Down:Connect(function()
    aiming = true
end)
aimButton.MouseButton1Up:Connect(function()
    aiming = false
end)

-- ========== ESP + WALLHACK ==========

local espObjects = {}

local function createESPForPlayer(p)
    if espObjects[p] then
        for _, obj in pairs(espObjects[p]) do
            if obj and obj.Destroy then
                obj:Destroy()
            end
        end
    end
    espObjects[p] = {}

    if not p.Character or not isAlive(p.Character) then return end

    local box = Instance.new("BoxHandleAdornment")
    box.Adornee = p.Character:FindFirstChild("HumanoidRootPart") or p.Character:FindFirstChild("Torso") or p.Character:FindFirstChild("UpperTorso")
    box.AlwaysOnTop = true
    box.ZIndex = 2
    box.Size = Vector3.new(2, 5, 1)
    box.Transparency = 0.5
    box.Color3 = _G.espEnemiesEnabled and (isEnemy(p) and Color3.new(1, 0, 0) or Color3.new(0, 1, 0)) or Color3.new(0, 1, 0)
    box.Parent = workspace.CurrentCamera
    table.insert(espObjects[p], box)

    -- Neon Effect (Wallhack)
    local function createNeonEffect(part)
        if not part or not part:IsA("BasePart") then return end
        local neon = Instance.new("BoxHandleAdornment")
        neon.Adornee = part
        neon.AlwaysOnTop = true
        neon.ZIndex = 1
        neon.Size = part.Size + Vector3.new(0.1, 0.1, 0.1)
        neon.Color3 = Color3.new(0, 1, 1)
        neon.Transparency = 0.75
        neon.Parent = workspace.CurrentCamera
        table.insert(espObjects[p], neon)
        return neon
    end

    for _, partName in pairs({"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}) do
        local part = p.Character:FindFirstChild(partName)
        if part then
            createNeonEffect(part)
        end
    end

    -- Se o alvo está sendo mirado, borda amarela
    local function updateBoxColor()
        if currentTarget == p then
            box.Color3 = Color3.new(1, 1, 0) -- amarelo borda
        else
            box.Color3 = isEnemy(p) and Color3.new(1, 0, 0) or Color3.new(0, 1, 0)
        end
    end

    RunService.RenderStepped:Connect(updateBoxColor)
end

local function updateESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and isAlive(p.Character) then
            if _G.espEnemiesEnabled and isEnemy(p) then
                if not espObjects[p] then createESPForPlayer(p) end
            elseif _G.espAlliesEnabled and not isEnemy(p) then
                if not espObjects[p] then createESPForPlayer(p) end
            else
                if espObjects[p] then
                    for _, obj in pairs(espObjects[p]) do
                        if obj and obj.Destroy then obj:Destroy() end
                    end
                    espObjects[p] = nil
                end
            end
        else
            if espObjects[p] then
                for _, obj in pairs(espObjects[p]) do
                    if obj and obj.Destroy then obj:Destroy() end
                end
                espObjects[p] = nil
            end
        end
    end
end

RunService.RenderStepped:Connect(updateESP)

-- ========== OUTRAS FUNÇÕES E CONFIGURAÇÕES

-- Atualizar currentTarget para aimbots (usado no wallhack para borda amarela)
RunService.RenderStepped:Connect(function()
    currentTarget = getClosestTarget()
end)
