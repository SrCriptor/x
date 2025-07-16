local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- FLAGS GLOBAIS (estado das funções)
_G.FOV_RADIUS = 65
_G.FOV_VISIBLE = true
_G.aimbotAutoEnabled = false
_G.aimbotManualEnabled = false
_G.aimbotLegitEnabled = false
_G.espEnemiesEnabled = true
_G.espAlliesEnabled = false
_G.espBoxEnabled = true
_G.espLineEnabled = false
_G.espDistanceEnabled = false
_G.espHealthBarEnabled = true
_G.espNameEnabled = true
_G.hitboxSelection = {
    Head = "Prioritário",
    Torso = "Nenhum",
    LeftArm = "Nenhum",
    RightArm = "Nenhum",
    LeftLeg = "Nenhum",
    RightLeg = "Nenhum",
}

-- Estado da interface
local currentPage = 1
local totalPages = 3

-- Criação do ScreenGui principal
local gui = Instance.new("ScreenGui")
gui.Name = "AimbotESPGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Container principal do menu
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 250, 0, 320)
panel.Position = UDim2.new(0, 20, 0.5, -160)
panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
panel.BackgroundTransparency = 0.2
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = gui

-- Função para criar botão padrão
local function createButton(text, positionY, parent)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 30)
    btn.Position = UDim2.new(0, 10, 0, positionY)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 16
    btn.Text = text
    btn.Parent = parent
    return btn
end

-- Função para criar toggle button (liga/desliga)
local function createToggleButton(text, yPos, flagName, exclusiveFlag)
    local button = createButton(text .. ": OFF", yPos, panel)
    button.MouseButton1Click:Connect(function()
        _G[flagName] = not _G[flagName]
        if exclusiveFlag and _G[flagName] then
            _G[exclusiveFlag] = false
        end
        button.Text = text .. (_G[flagName] and ": ON" or ": OFF")
        -- Atualiza botão irmão exclusivo
        if exclusiveFlag then
            for _, child in pairs(panel:GetChildren()) do
                if child:IsA("TextButton") and child ~= button then
                    local childText = child.Text:lower()
                    local exFlagText = exclusiveFlag:gsub("([A-Z])", " %1"):lower()
                    exFlagText = exFlagText:gsub("^%l", string.upper)
                    if childText:find(exFlagText) then
                        child.Text = child.Text:sub(1, child.Text:find(":")) .. (_G[exclusiveFlag] and " ON" or " OFF")
                    end
                end
            end
        end
    end)
    return button
end

-- Criação dos botões da página 1
local aimbotAutoBtn = createToggleButton("Aimbot Auto", 40, "aimbotAutoEnabled", "aimbotManualEnabled")
local aimbotManualBtn = createToggleButton("Aimbot Manual", 75, "aimbotManualEnabled", "aimbotAutoEnabled")
local aimbotLegitBtn = createToggleButton("Aimbot Legit", 110, "aimbotLegitEnabled")
local espEnemiesBtn = createToggleButton("ESP Inimigos", 145, "espEnemiesEnabled")
local espAlliesBtn = createToggleButton("ESP Aliados", 180, "espAlliesEnabled")
local showFOVBtn = createToggleButton("Mostrar FOV", 215, "FOV_VISIBLE")

-- Botões para ajustar FOV abaixo do Mostrar FOV
local function createFOVAdjustButton(text, yPos, delta)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.5, -15, 0, 30)
    btn.Position = UDim2.new(text == "- FOV" and 0 or 0.5, 10, 0, yPos)
    btn.Text = text
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 16
    btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Parent = panel
    btn.MouseButton1Click:Connect(function()
        _G.FOV_RADIUS = math.clamp(_G.FOV_RADIUS + delta, 10, 300)
    end)
    return btn
end

local fovMinusBtn = createFOVAdjustButton("- FOV", 255, -5)
local fovPlusBtn = createFOVAdjustButton("+ FOV", 255, 5)

-- Botões de navegação de páginas ▶️ e ◀️
local btnNext = createButton("▶️", 290, panel)
local btnBack = createButton("◀️", 290, panel)
btnBack.Position = UDim2.new(0, 10, 0, 290)
btnNext.Position = UDim2.new(1, -40, 0, 290)

btnBack.Visible = false -- começa na página 1, sem voltar

-- Função para esconder todos botões (será usado para trocar páginas)
local function hideAllButtons()
    for _, child in pairs(panel:GetChildren()) do
        if child:IsA("TextButton") then
            child.Visible = false
        end
    end
end

-- Função para mostrar página 1 (Aimbots e ESP básico)
local function showPage1()
    hideAllButtons()
    aimbotAutoBtn.Visible = true
    aimbotManualBtn.Visible = true
    aimbotLegitBtn.Visible = true
    espEnemiesBtn.Visible = true
    espAlliesBtn.Visible = true
    showFOVBtn.Visible = true
    fovMinusBtn.Visible = true
    fovPlusBtn.Visible = true
    btnNext.Visible = true
    btnBack.Visible = false
end

btnNext.MouseButton1Click:Connect(function()
    if currentPage == 1 then
        currentPage = 2
        showPage2()
    elseif currentPage == 2 then
        currentPage = 3
        showPage3()
    end
end)

btnBack.MouseButton1Click:Connect(function()
    if currentPage == 3 then
        currentPage = 2
        showPage2()
    elseif currentPage == 2 then
        currentPage = 1
        showPage1()
    end
end)

-- TODO: showPage2 e showPage3 serão criadas já com o layout correto

-- Inicializa na página 1
showPage1()

-- Drag para mover o painel inteiro
local dragging = false
local dragStartPos, startPos

panel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStartPos = input.Position
        startPos = panel.Position
    end
end)
panel.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStartPos
        panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- Botão minimizar/maximizar (🔽/🔼) que fica separado e movível
local toggleBtn = createButton("🔽", 10, gui)
toggleBtn.Size = UDim2.new(0, 40, 0, 30)
toggleBtn.Position = UDim2.new(0, 280, 0.5, -160)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)

local toggleDragging = false
local toggleDragStart, toggleStartPos

toggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        toggleDragging = true
        toggleDragStart = input.Position
        toggleStartPos = toggleBtn.Position
    end
end)
toggleBtn.InputChanged:Connect(function(input)
    if toggleDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - toggleDragStart
        toggleBtn.Position = UDim2.new(toggleStartPos.X.Scale, toggleStartPos.X.Offset + delta.X, toggleStartPos.Y.Scale, toggleStartPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        toggleDragging = false
    end
end)

toggleBtn.MouseButton1Click:Connect(function()
    if panel.Visible then
        panel.Visible = false
        toggleBtn.Text = "🔼"
    else
        panel.Visible = true
        toggleBtn.Text = "🔽"
    end
end)

-- ======= Circulo do FOV =======
local fovCircle = Drawing.new("Circle")
fovCircle.Transparency = 0.2
fovCircle.Thickness = 1.5
fovCircle.Filled = false
fovCircle.Color = Color3.new(1,1,1)

RunService.RenderStepped:Connect(function()
    fovCircle.Radius = _G.FOV_RADIUS
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    fovCircle.Visible = _G.FOV_VISIBLE
end)

-- PARTE 2: Implementação dos AIMBOTS (Auto, Manual, Legit) com validação de paredes

local mouse = LocalPlayer:GetMouse()
local UserInput = UserInputService

-- Função para checar se a posição está visível (não bloqueada por parede)
local function isVisible(origin, targetPos)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    local direction = (targetPos - origin).Unit * (targetPos - origin).Magnitude
    local raycastResult = workspace:Raycast(origin, direction, raycastParams)
    if raycastResult then
        local hitPart = raycastResult.Instance
        if hitPart and hitPart:IsDescendantOf(workspace) then
            -- Se o objeto atingido NÃO for um inimigo (humano) ou parte da mesma equipe, retorna false
            -- Aqui supomos que o personagem está visível se o raio não colidiu antes do inimigo
            -- Ajuste conforme a lógica de seu jogo
            if (targetPos - origin).Magnitude < (raycastResult.Position - origin).Magnitude - 0.1 then
                return false
            end
        end
    end
    return true
end

-- Função para pegar o melhor inimigo dentro do FOV com base na seleção da hitbox
local function getBestTarget()
    local cameraPos = Camera.CFrame.Position
    local bestTarget = nil
    local bestDistance = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local origin = cameraPos
                local targetPartName = nil

                -- Verifica qual hitbox prioritária disponível
                for partName, priority in pairs(_G.hitboxSelection) do
                    if priority == "Prioritário" and player.Character:FindFirstChild(partName) then
                        targetPartName = partName
                        break
                    end
                end
                if not targetPartName then
                    -- Se nenhum prioritário, pega cabeça se tiver, senão humanoidrootpart
                    targetPartName = player.Character:FindFirstChild("Head") and "Head" or "HumanoidRootPart"
                end

                local targetPart = player.Character:FindFirstChild(targetPartName)
                if targetPart then
                    -- Verifica se está visível (não obstruído)
                    if isVisible(origin, targetPart.Position) then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                        if onScreen then
                            local centerX, centerY = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2
                            local distFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(centerX, centerY)).Magnitude

                            if distFromCenter <= _G.FOV_RADIUS and distFromCenter < bestDistance then
                                bestDistance = distFromCenter
                                bestTarget = {Player = player, Part = targetPart}
                            end
                        end
                    end
                end
            end
        end
    end

    return bestTarget
end

-- Função para mover a mira para o alvo suavemente (para legit)
local function moveMouseToTarget(part, smoothness)
    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
    if onScreen then
        local centerX, centerY = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2
        local deltaX = (screenPos.X - centerX) / smoothness
        local deltaY = (screenPos.Y - centerY) / smoothness

        -- Usa UserInputService para mover o mouse (simulação)
        -- Como não existe API oficial pra mover mouse em Roblox, isso pode ser um workaround via eventos de entrada
        -- Aqui um exemplo teórico, você precisaria usar algum método externo para mover mouse real
        -- Ou ajustar a câmera com Camera.CFrame para mirar (mais usado em Roblox)

        local newCFrame = Camera.CFrame * CFrame.Angles(-math.rad(deltaY * 0.15), -math.rad(deltaX * 0.15), 0)
        Camera.CFrame = newCFrame
    end
end

-- Evento principal para controlar a mira com base nos modos ativados
RunService.RenderStepped:Connect(function()
    if _G.aimbotAutoEnabled or _G.aimbotLegitEnabled then
        local target = getBestTarget()
        if target then
            if _G.aimbotAutoEnabled then
                -- Mira instantânea na hitbox selecionada
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Part.Position)
                -- Pode incluir disparo automático aqui se quiser
            elseif _G.aimbotLegitEnabled then
                -- Mira suave e precisa
                moveMouseToTarget(target.Part, 15) -- 15 é a suavidade, ajuste para mais lento ou mais rápido
                -- Disparo automático legítimo, exemplo:
                local mouseDown = UserInput:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                if mouseDown then
                    -- Aqui dispare só se o botão do mouse estiver pressionado, pra não atirar sozinho
                    -- Você pode chamar o disparo do seu jogo aqui
                end
            end
        end
    elseif _G.aimbotManualEnabled then
        -- Apenas mira manual, sem mover a câmera automaticamente
        -- O jogador mira e atira manualmente
    end
end)

-- PARTE 3: ESP + WALLHACK NEON COM CONTORNO AMARELO NO ALVO VISADO

local espData = {}
local highlights = {}

-- Cria ou atualiza o highlight neon para wallhack
local function updateHighlight(player, isTarget)
    if not player.Character then return end

    local highlight = highlights[player]
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Parent = workspace
        highlights[player] = highlight
    end

    highlight.Adornee = player.Character
    highlight.Enabled = _G.espEnemiesEnabled or _G.espAlliesEnabled
    highlight.FillColor = isTarget and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(0, 255, 255)
    highlight.OutlineColor = isTarget and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(0, 255, 255)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
end

local function disableHighlight(player)
    local highlight = highlights[player]
    if highlight then
        highlight.Enabled = false
    end
end

-- Cria ESP para um jogador
local function createESP(player)
    if player == LocalPlayer then return end

    local box = Drawing.new("Square")
    box.Thickness = 1.5
    box.Filled = false
    box.Visible = false

    local line = Drawing.new("Line")
    line.Thickness = 1
    line.Color = Color3.fromRGB(255, 255, 255)
    line.Visible = false

    local nameTag = Drawing.new("Text")
    nameTag.Size = 14
    nameTag.Center = true
    nameTag.Outline = true
    nameTag.Color = Color3.fromRGB(255, 255, 255)
    nameTag.Visible = false

    local healthBar = Drawing.new("Square")
    healthBar.Filled = true
    healthBar.Visible = false

    local distanceTag = Drawing.new("Text")
    distanceTag.Size = 12
    distanceTag.Center = true
    distanceTag.Outline = true
    distanceTag.Color = Color3.fromRGB(255, 255, 255)
    distanceTag.Visible = false

    espData[player] = {
        box = box,
        line = line,
        nameTag = nameTag,
        healthBar = healthBar,
        distanceTag = distanceTag
    }

    RunService.RenderStepped:Connect(function()
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChildOfClass("Humanoid") then
            box.Visible = false
            line.Visible = false
            nameTag.Visible = false
            healthBar.Visible = false
            distanceTag.Visible = false
            disableHighlight(player)
            return
        end

        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local hrp = char.HumanoidRootPart

        local ffa = isFFA()
        if not ffa then
            if player.Team == LocalPlayer.Team and not _G.espAlliesEnabled then
                box.Visible = false
                line.Visible = false
                nameTag.Visible = false
                healthBar.Visible = false
                distanceTag.Visible = false
                disableHighlight(player)
                return
            elseif player.Team ~= LocalPlayer.Team and not _G.espEnemiesEnabled then
                box.Visible = false
                line.Visible = false
                nameTag.Visible = false
                healthBar.Visible = false
                distanceTag.Visible = false
                disableHighlight(player)
                return
            end
        else
            if not _G.espEnemiesEnabled then
                box.Visible = false
                line.Visible = false
                nameTag.Visible = false
                healthBar.Visible = false
                distanceTag.Visible = false
                disableHighlight(player)
                return
            end
        end

        local head = char:FindFirstChild("Head")
        if not head then return end

        local topLeftPos, topLeftVis = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(-2, 3, 0))
        local bottomRightPos, bottomRightVis = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(2, -3, 0))
        local headPos, headVis = Camera:WorldToViewportPoint(head.Position)

        if topLeftVis and bottomRightVis and headVis and topLeftPos.Z > 0 and bottomRightPos.Z > 0 and headPos.Z > 0 then
            local width = bottomRightPos.X - topLeftPos.X
            local height = bottomRightPos.Y - topLeftPos.Y
            local x = topLeftPos.X
            local y = topLeftPos.Y

            -- Atualiza caixa
            espData[player].box.Size = Vector2.new(width, height)
            espData[player].box.Position = Vector2.new(x, y)
            espData[player].box.Visible = _G.espBoxEnabled

            -- Atualiza linha (do centro inferior da tela até o personagem)
            local centerX, centerY = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y
            espData[player].line.From = Vector2.new(centerX, centerY)
            espData[player].line.To = Vector2.new(headPos.X, headPos.Y)
            espData[player].line.Color = (player == currentTarget) and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(255, 255, 255)
            espData[player].line.Visible = _G.espLineEnabled

            -- Atualiza nome
            espData[player].nameTag.Text = player.Name
            espData[player].nameTag.Position = Vector2.new(headPos.X, headPos.Y - 20)
            espData[player].nameTag.Color = (player == currentTarget) and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(255, 255, 255)
            espData[player].nameTag.Visible = _G.espNameEnabled

            -- Atualiza barra de vida
            local healthPercent = humanoid.Health / humanoid.MaxHealth
            local barHeight = height
            local barWidth = 5
            local barX = x - barWidth - 3
            local barY = y + (height * (1 - healthPercent))
            espData[player].healthBar.Size = Vector2.new(barWidth, barHeight * healthPercent)
            espData[player].healthBar.Position = Vector2.new(barX, barY)
            espData[player].healthBar.Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
            espData[player].healthBar.Visible = _G.espHealthBarEnabled

            -- Atualiza distância
            local distance = math.floor((hrp.Position - Camera.CFrame.Position).Magnitude)
            espData[player].distanceTag.Text = tostring(distance) .. "m"
            espData[player].distanceTag.Position = Vector2.new(x + width / 2, y + height + 10)
            espData[player].distanceTag.Visible = _G.espDistanceEnabled

            -- Atualiza highlight (wallhack neon)
            local isTarget = (player == currentTarget)
            if (player.Team == LocalPlayer.Team and _G.espAlliesEnabled) or (player.Team ~= LocalPlayer.Team and _G.espEnemiesEnabled) then
                updateHighlight(player, isTarget)
            else
                disableHighlight(player)
            end

        else
            espData[player].box.Visible = false
            espData[player].line.Visible = false
            espData[player].nameTag.Visible = false
            espData[player].healthBar.Visible = false
            espData[player].distanceTag.Visible = false
            disableHighlight(player)
        end
    end)
end

for _, player in pairs(Players:GetPlayers()) do
    createESP(player)
end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(function(player)
    local data = espData[player]
    if data then
        data.box:Remove()
        data.line:Remove()
        data.nameTag:Remove()
        data.healthBar:Remove()
        data.distanceTag:Remove()
        espData[player] = nil
    end
    disableHighlight(player)
end)

-- PARTE 4: MENU DE SELEÇÃO DE HITBOX (POPUP 2D COM BACON) + NAVEGAÇÃO E TUTORIAL

-- Cria o popup de seleção de hitbox (menu Bacon)
local hitboxPopup = Instance.new("Frame")
hitboxPopup.Size = UDim2.new(0, 300, 0, 400)
hitboxPopup.Position = UDim2.new(0.5, -150, 0.5, -200)
hitboxPopup.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
hitboxPopup.BorderSizePixel = 0
hitboxPopup.Visible = false
hitboxPopup.Parent = gui

-- Fundo semi-transparente para fechar popup ao clicar fora
local bgClose = Instance.new("TextButton")
bgClose.Size = UDim2.new(1, 0, 1, 0)
bgClose.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
bgClose.BackgroundTransparency = 0.6
bgClose.Text = ""
bgClose.Parent = hitboxPopup
bgClose.ZIndex = 0
bgClose.MouseButton1Click:Connect(function()
    hitboxPopup.Visible = false
end)

-- Imagem do Bacon (personagem Roblox)
local baconImage = Instance.new("ImageLabel")
baconImage.Size = UDim2.new(0, 280, 0, 380)
baconImage.Position = UDim2.new(0, 10, 0, 10)
baconImage.BackgroundTransparency = 1
baconImage.Image = "rbxassetid://8967307840" -- Exemplo de ID do Bacon, substitua se quiser
baconImage.Parent = hitboxPopup

-- Cria botões invisíveis sobre partes do corpo

local parts = {
    {Name = "Head", Position = UDim2.new(0.35, 0, 0.05, 0), Size = UDim2.new(0, 60, 0, 60)},
    {Name = "Torso", Position = UDim2.new(0.3, 0, 0.35, 0), Size = UDim2.new(0, 80, 0, 110)},
    {Name = "LeftArm", Position = UDim2.new(0.1, 0, 0.35, 0), Size = UDim2.new(0, 50, 0, 110)},
    {Name = "RightArm", Position = UDim2.new(0.65, 0, 0.35, 0), Size = UDim2.new(0, 50, 0, 110)},
    {Name = "LeftLeg", Position = UDim2.new(0.35, 0, 0.75, 0), Size = UDim2.new(0, 50, 0, 100)},
    {Name = "RightLeg", Position = UDim2.new(0.55, 0, 0.75, 0), Size = UDim2.new(0, 50, 0, 100)},
}

local function updateHitboxButtonColor(button, state)
    if state == "Nenhum" then
        button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        button.BackgroundTransparency = 0.7
    elseif state == "Prioritário" then
        button.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        button.BackgroundTransparency = 0.3
    end
end

local hitboxButtons = {}

for _, part in ipairs(parts) do
    local btn = Instance.new("TextButton")
    btn.Name = part.Name .. "Button"
    btn.Size = part.Size
    btn.Position = part.Position
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.BackgroundTransparency = 0.7
    btn.Text = part.Name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.Parent = baconImage
    btn.ZIndex = 2

    btn.MouseButton1Click:Connect(function()
        local currentState = _G.hitboxSelection[part.Name]
        if currentState == "Nenhum" then
            _G.hitboxSelection[part.Name] = "Prioritário"
        else
            _G.hitboxSelection[part.Name] = "Nenhum"
        end
        updateHitboxButtonColor(btn, _G.hitboxSelection[part.Name])
    end)

    updateHitboxButtonColor(btn, _G.hitboxSelection[part.Name])
    hitboxButtons[part.Name] = btn
end

-- ===== MENU DE NAVEGAÇÃO (3 páginas) =====
local currentPage = 1

local function showPage(page)
    currentPage = page
    -- Oculta tudo
    for _, child in pairs(panel:GetChildren()) do
        if child:IsA("TextButton") and not (child == toggleButton or child == btnNext or child == btnBack) then
            child.Visible = false
        end
    end
    tutorialText.Visible = false
    hitboxPopup.Visible = false

    if page == 1 then
        -- Página 1: Aimbots e Mostrar FOV + botões +FOV e -FOV
        aimbotAutoBtn.Visible = true
        aimbotManualBtn.Visible = true
        aimbotLegitBtn.Visible = true
        showFOVBtn.Visible = true
        btnFovMinus.Visible = true
        btnFovPlus.Visible = true
    elseif page == 2 then
        -- Página 2: ESP inimigos/aliados e opções do ESP
        espEnemiesBtn.Visible = true
        espAlliesBtn.Visible = true
        espBoxBtn.Visible = true
        espLineBtn.Visible = true
        espNameBtn.Visible = true
        espHealthBtn.Visible = true
        espDistanceBtn.Visible = true
        btnSelectHitbox.Visible = true
    elseif page == 3 then
        -- Página 3: Tutorial
        tutorialText.Visible = true
    end
end

-- Botão para abrir o popup de seleção de hitbox
local btnSelectHitbox = Instance.new("TextButton")
btnSelectHitbox.Size = UDim2.new(1, -20, 0, 30)
btnSelectHitbox.Position = UDim2.new(0, 10, 0, 200)
btnSelectHitbox.Text = "Selecionar Hitbox"
btnSelectHitbox.Font = Enum.Font.SourceSansBold
btnSelectHitbox.TextSize = 16
btnSelectHitbox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
btnSelectHitbox.TextColor3 = Color3.new(1, 1, 1)
btnSelectHitbox.Visible = false
btnSelectHitbox.Parent = panel

btnSelectHitbox.MouseButton1Click:Connect(function()
    hitboxPopup.Visible = true
end)

-- Botões de navegação entre páginas
local btnNext = Instance.new("TextButton")
btnNext.Size = UDim2.new(0, 40, 0, 30)
btnNext.Position = UDim2.new(1, -50, 1, -40)
btnNext.Text = "▶️"
btnNext.Font = Enum.Font.SourceSansBold
btnNext.TextSize = 20
btnNext.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
btnNext.TextColor3 = Color3.new(1, 1, 1)
btnNext.Parent = panel

local btnBack = Instance.new("TextButton")
btnBack.Size = UDim2.new(0, 40, 0, 30)
btnBack.Position = UDim2.new(0, 10, 1, -40)
btnBack.Text = "◀️"
btnBack.Font = Enum.Font.SourceSansBold
btnBack.TextSize = 20
btnBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
btnBack.TextColor3 = Color3.new(1, 1, 1)
btnBack.Parent = panel

btnNext.MouseButton1Click:Connect(function()
    if currentPage < 3 then
        showPage(currentPage + 1)
    end
end)

btnBack.MouseButton1Click:Connect(function()
    if currentPage > 1 then
        showPage(currentPage - 1)
    end
end)

-- Texto de tutorial (página 3)
local tutorialText = Instance.new("TextLabel")
tutorialText.Size = UDim2.new(1, -20, 1, -60)
tutorialText.Position = UDim2.new(0, 10, 0, 10)
tutorialText.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
tutorialText.BackgroundTransparency = 0.3
tutorialText.TextColor3 = Color3.new(1, 1, 1)
tutorialText.Font = Enum.Font.SourceSansBold
tutorialText.TextSize = 14
tutorialText.TextWrapped = true
tutorialText.TextYAlignment = Enum.TextYAlignment.Top
tutorialText.Visible = false
tutorialText.Parent = panel
tutorialText.Text = [[
Tutorial de Uso:

- Página 1: Controle os modos de aimbot e o círculo de FOV.
- Página 2: Ajuste as opções do ESP, selecione inimigos/aliados e personalize o hitbox.
- Página 3: Leia este tutorial para entender cada botão e funcionalidade.

Hitbox Prioritário: Quando ativado, o aimbot dará preferência para essa parte do corpo.
Aimbot Legit: Mira automática e atira com precisão, evitando tiros inúteis.
Aimbot Manual: Você mira e atira manualmente.
]]
-- Inicializa a página 1 ao iniciar
showPage(1)

return gui
