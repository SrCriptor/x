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

-- PARTE 1: Funções auxiliares, criação da GUI e controle de botões

local dragging = false
local dragStart, startPos
local currentTarget = nil
local page = 1

local gui = Instance.new("ScreenGui")
gui.Name = "MobileAimbotGUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 220, 0, 260)
panel.Position = UDim2.new(0, 20, 0.5, -120)
panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
panel.BackgroundTransparency = 0.2
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = gui

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

-- Botão minimizar 🔽
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 40, 0, 30)
toggleButton.Position = UDim2.new(1, -50, 0, 5)
toggleButton.Text = "🔽"
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 18
toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Parent = panel

local minimized = false
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
		panel.Size = UDim2.new(0, 220, 0, 260)
		panel.BackgroundTransparency = 0.2
		toggleButton.Position = UDim2.new(1, -50, 0, 5)
	end
end)

-- Botões de navegação de página
local function createPageNavigation()
	local prevButton = Instance.new("TextButton")
	prevButton.Size = UDim2.new(0, 30, 0, 30)
	prevButton.Position = UDim2.new(0, 5, 1, -35)
	prevButton.Text = "◀️"
	prevButton.Font = Enum.Font.SourceSansBold
	prevButton.TextSize = 16
	prevButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	prevButton.TextColor3 = Color3.new(1, 1, 1)
	prevButton.Parent = panel

	local nextButton = Instance.new("TextButton")
	nextButton.Size = UDim2.new(0, 30, 0, 30)
	nextButton.Position = UDim2.new(1, -35, 1, -35)
	nextButton.Text = "▶️"
	nextButton.Font = Enum.Font.SourceSansBold
	nextButton.TextSize = 16
	nextButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	nextButton.TextColor3 = Color3.new(1, 1, 1)
	nextButton.Parent = panel

	prevButton.MouseButton1Click:Connect(function()
		page = math.max(1, page - 1)
	end)

	nextButton.MouseButton1Click:Connect(function()
		page = math.min(3, page + 1)
	end)
end

createPageNavigation()

-- PARTE 2: AIMBOT AUTO / MANUAL / LEGIT

local function isAliveCharacter(character)
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
    return #table.getn(teams) <= 1
end

local function hasLineOfSight(targetPart)
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local result = workspace:Raycast(origin, direction, raycastParams)
    return result and result.Instance and result.Instance:IsDescendantOf(targetPart.Parent)
end

local function getHitboxTarget(character)
    for partName, priority in pairs(_G.hitboxSelection) do
        if priority == "Prioritário" then
            local part = character:FindFirstChild(partName)
            if part then return part end
        end
    end
    return character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
end

local function getClosestEnemy()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local shortestDistance = _G.FOV_RADIUS
    local closestEnemy = nil
    local ffa = isFFA()

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer or not player.Character or not isAliveCharacter(player.Character) then continue end

        if not ffa and player.Team == LocalPlayer.Team and not _G.espAlliesEnabled then continue end
        if not ffa and player.Team ~= LocalPlayer.Team and not _G.espEnemiesEnabled then continue end
        if ffa and not _G.espEnemiesEnabled then continue end

        local part = getHitboxTarget(player.Character)
        if not part then continue end

        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end

        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if dist > shortestDistance then continue end

        if not hasLineOfSight(part) then continue end

        shortestDistance = dist
        closestEnemy = player
    end

    return closestEnemy
end

-- Aimbot: execução no RenderStepped
RunService.RenderStepped:Connect(function()
    local target = getClosestEnemy()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    -- Aimbot Auto
    if _G.aimbotAutoEnabled and target and target.Character then
        local part = getHitboxTarget(target.Character)
        if part then
            local screenPos, visible = Camera:WorldToViewportPoint(part.Position)
            if visible and (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude <= _G.FOV_RADIUS then
                currentTarget = target
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
            end
        end
    end

    -- Aimbot Manual
    if _G.aimbotManualEnabled and aiming then
        if target and target.Character then
            local part = getHitboxTarget(target.Character)
            if part then
                local screenPos, visible = Camera:WorldToViewportPoint(part.Position)
                if visible and (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude <= _G.FOV_RADIUS then
                    currentTarget = target
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
                end
            end
        end
    end

    -- Aimbot Legit
    if _G.aimbotLegitEnabled and aiming and shooting then
        if target and target.Character then
            local part = getHitboxTarget(target.Character)
            if part then
                local screenPos, visible = Camera:WorldToViewportPoint(part.Position)
                if visible and (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude <= _G.FOV_RADIUS then
                    currentTarget = target
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
                end
            end
        end
    end

    -- Limpa o alvo se não for mais válido
    if currentTarget and (not currentTarget.Character or not isAliveCharacter(currentTarget.Character)) then
        currentTarget = nil
    end
end)

-- PARTE 3: ESP (BOX, LINHA, NOME, VIDA, DISTÂNCIA)

local espData = {}
local highlights = {}

local function isAlive(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function updateHighlight(player, color, isTarget)
    if not player.Character then return end
    local chams = highlights[player]
    if not chams then
        chams = Instance.new("Highlight")
        chams.Parent = workspace
        highlights[player] = chams
    end
    chams.Adornee = player.Character
    chams.Enabled = true
    chams.FillColor = color
    chams.OutlineColor = isTarget and Color3.fromRGB(255, 255, 0) or Color3.new(1, 1, 1)
    chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
end

local function disableHighlight(player)
    local chams = highlights[player]
    if chams then
        chams.Enabled = false
    end
end

local function createESP(player)
    if player == LocalPlayer then return end

    local box = Drawing.new("Square")
    box.Thickness = 1.5
    box.Filled = false
    box.Visible = false

    local line = Drawing.new("Line")
    line.Thickness = 1
    line.Color = Color3.new(1, 1, 1)
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
    distanceTag.Size = 14
    distanceTag.Center = true
    distanceTag.Outline = true
    distanceTag.Color = Color3.fromRGB(255, 255, 255)
    distanceTag.Visible = false

    espData[player] = {
        box = box,
        line = line,
        nameTag = nameTag,
        healthBar = healthBar,
        distanceTag = distanceTag,
    }

    RunService.RenderStepped:Connect(function()
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") or not isAlive(char) then
            box.Visible = false
            line.Visible = false
            nameTag.Visible = false
            healthBar.Visible = false
            distanceTag.Visible = false
            disableHighlight(player)
            return
        end

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

        local hrp = char.HumanoidRootPart
        local head = char:FindFirstChild("Head")
        local humanoid = char:FindFirstChildOfClass("Humanoid")

        local topLeftPos, topLeftVis = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(-2, 3, 0))
        local bottomRightPos, bottomRightVis = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(2, -3, 0))
        local headPos, headVis = Camera:WorldToViewportPoint(head.Position)

        if topLeftVis and bottomRightVis and headVis and topLeftPos.Z > 0 and bottomRightPos.Z > 0 and headPos.Z > 0 then
            local width = bottomRightPos.X - topLeftPos.X
            local height = bottomRightPos.Y - topLeftPos.Y
            local x = topLeftPos.X
            local y = topLeftPos.Y

            if _G.espBoxEnabled then
                box.Size = Vector2.new(width, height)
                box.Position = Vector2.new(x, y)
                box.Color = (player == currentTarget) and Color3.fromRGB(255, 255, 0) or (player.Team == LocalPlayer.Team and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(255, 0, 0))
                box.Visible = true
            else
                box.Visible = false
            end

            if _G.espLineEnabled then
                line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                line.To = Vector2.new((topLeftPos.X + bottomRightPos.X) / 2, bottomRightPos.Y)
                line.Color = (player == currentTarget) and Color3.fromRGB(255, 255, 0) or (player.Team == LocalPlayer.Team and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(255, 0, 0))
                line.Visible = true
            else
                line.Visible = false
            end

            if _G.espNameEnabled then
                nameTag.Text = player.Name
                nameTag.Position = Vector2.new(headPos.X, headPos.Y - 20)
                nameTag.Color = (player == currentTarget) and Color3.fromRGB(255, 255, 0) or (player.Team == LocalPlayer.Team and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(255, 255, 255))
                nameTag.Visible = true
            else
                nameTag.Visible = false
            end

            if _G.espHealthBarEnabled then
                local healthPercent = humanoid.Health / humanoid.MaxHealth
                local barHeight = height
                local barWidth = 5
                local barX = x - barWidth - 3
                local barY = y + (height * (1 - healthPercent))

                healthBar.Size = Vector2.new(barWidth, barHeight * healthPercent)
                healthBar.Position = Vector2.new(barX, barY)
                healthBar.Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
                healthBar.Visible = true
            else
                healthBar.Visible = false
            end

            if _G.espDistanceEnabled then
                local distance = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude)
                distanceTag.Text = tostring(distance) .. "m"
                distanceTag.Position = Vector2.new(x + width / 2, y + height + 10)
                distanceTag.Visible = true
            else
                distanceTag.Visible = false
            end
        else
            box.Visible = false
            line.Visible = false
            nameTag.Visible = false
            healthBar.Visible = false
            distanceTag.Visible = false
        end
    end)
end

for _, player in pairs(Players:GetPlayers()) do
    createESP(player)
end
Players.PlayerAdded:Connect(createESP)

-- PARTE 4: WALLHACK NEON COM CONTORNO AMARELO NO ALVO

local neonHighlights = {}

local function updateWallhack(player, isTarget)
    if not player.Character then return end

    local highlight = neonHighlights[player]
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "NeonHighlight"
        highlight.Parent = workspace
        highlight.Adornee = player.Character
        highlight.DepthMode = Enum.HighlightDepthMode.Occluded
        highlight.FillColor = Color3.fromRGB(0, 170, 255) -- cor neon azul
        highlight.OutlineColor = Color3.fromRGB(0, 170, 255)
        neonHighlights[player] = highlight
    end

    highlight.Enabled = true

    if isTarget then
        highlight.OutlineColor = Color3.fromRGB(255, 255, 0) -- amarelo no contorno do alvo
        highlight.FillColor = Color3.fromRGB(0, 170, 255)
    else
        highlight.OutlineColor = Color3.fromRGB(0, 170, 255) -- azul para os outros
        highlight.FillColor = Color3.fromRGB(0, 170, 255)
    end
end

local function disableWallhack(player)
    local highlight = neonHighlights[player]
    if highlight then
        highlight.Enabled = false
    end
end

RunService.RenderStepped:Connect(function()
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            disableWallhack(player)
            continue
        end

        local alive = isAlive(player.Character)
        if not alive or not (_G.espEnemiesEnabled or _G.espAlliesEnabled) then
            disableWallhack(player)
            continue
        end

        local isEnemy = player.Team ~= LocalPlayer.Team
        if isEnemy and not _G.espEnemiesEnabled then
            disableWallhack(player)
            continue
        end

        if not isEnemy and not _G.espAlliesEnabled then
            disableWallhack(player)
            continue
        end

        local isTarget = (player == currentTarget)

        updateWallhack(player, isTarget)
    end
end)

-- PARTE 5: MENU BACON (POPUP 2D SELEÇÃO DE HITBOX)

local hitboxMenuEnabled = false
local hitboxMenuGui = Instance.new("ScreenGui")
hitboxMenuGui.Name = "HitboxMenuGui"
hitboxMenuGui.ResetOnSpawn = false
hitboxMenuGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
hitboxMenuGui.Enabled = false

-- Fundo escuro semi-transparente para o popup
local bgFrame = Instance.new("Frame")
bgFrame.Size = UDim2.new(1, 0, 1, 0)
bgFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
bgFrame.BackgroundTransparency = 0.6
bgFrame.Parent = hitboxMenuGui

-- Container centralizado para o menu
local container = Instance.new("Frame")
container.Size = UDim2.new(0, 400, 0, 450)
container.Position = UDim2.new(0.5, -200, 0.5, -225)
container.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
container.BorderSizePixel = 0
container.Parent = bgFrame

-- Título
local title = Instance.new("TextLabel")
title.Text = "Selecionar Hitbox Prioritária"
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 24
title.Parent = container

-- Imagem do personagem "Bacon"
local baconImage = Instance.new("ImageLabel")
baconImage.Size = UDim2.new(0, 300, 0, 400)
baconImage.Position = UDim2.new(0.5, -150, 0, 40)
baconImage.BackgroundTransparency = 1
baconImage.Image = "rbxassetid://5102930101" -- Exemplo de ID do modelo Bacon Roblox, substitua se quiser
baconImage.Parent = container

-- Tabela das partes do corpo e seus retângulos clicáveis (ajuste posições/tamanhos conforme imagem)
local hitboxParts = {
    Head = {Pos = UDim2.new(0.5, -30, 0, 10), Size = UDim2.new(0, 60, 0, 60)},
    Torso = {Pos = UDim2.new(0.5, -50, 0, 80), Size = UDim2.new(0, 100, 0, 120)},
    LeftArm = {Pos = UDim2.new(0.5, -120, 0, 80), Size = UDim2.new(0, 60, 0, 110)},
    RightArm = {Pos = UDim2.new(0.5, 60, 0, 80), Size = UDim2.new(0, 60, 0, 110)},
    LeftLeg = {Pos = UDim2.new(0.5, -50, 0, 200), Size = UDim2.new(0, 40, 0, 140)},
    RightLeg = {Pos = UDim2.new(0.5, 10, 0, 200), Size = UDim2.new(0, 40, 0, 140)},
}

local function updateHitboxVisual()
    for partName, partInfo in pairs(hitboxParts) do
        local btn = container:FindFirstChild(partName .. "Btn")
        if btn then
            local state = _G.hitboxSelection[partName] or "Nenhum"
            if state == "Nenhum" then
                btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                btn.BackgroundTransparency = 0.7
            elseif state == "Prioritário" then
                btn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                btn.BackgroundTransparency = 0.4
            end
        end
    end
end

-- Criação dos botões invisíveis sobre as partes do corpo
for partName, partInfo in pairs(hitboxParts) do
    local btn = Instance.new("TextButton")
    btn.Name = partName .. "Btn"
    btn.Size = partInfo.Size
    btn.Position = partInfo.Pos
    btn.BackgroundTransparency = 0.7
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.BorderSizePixel = 0
    btn.Text = partName
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 18
    btn.Parent = container

    btn.MouseButton1Click:Connect(function()
        -- Toggle entre Nenhum e Prioritário
        if _G.hitboxSelection[partName] == "Prioritário" then
            _G.hitboxSelection[partName] = "Nenhum"
        else
            -- Para garantir que só 1 parte seja Prioritário, zera os outros
            for k in pairs(_G.hitboxSelection) do
                _G.hitboxSelection[k] = "Nenhum"
            end
            _G.hitboxSelection[partName] = "Prioritário"
        end
        updateHitboxVisual()
    end)
end

-- Botão fechar
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 80, 0, 35)
closeBtn.Position = UDim2.new(1, -90, 0, 10)
closeBtn.Text = "Fechar"
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 18
closeBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Parent = container

closeBtn.MouseButton1Click:Connect(function()
    hitboxMenuGui.Enabled = false
    hitboxMenuEnabled = false
end)

local function toggleHitboxMenu()
    hitboxMenuEnabled = not hitboxMenuEnabled
    hitboxMenuGui.Enabled = hitboxMenuEnabled
    if hitboxMenuEnabled then
        updateHitboxVisual()
    end
end

-- Exemplo: botão para abrir o menu (você deve conectar este toggle a algum botão no menu principal)
-- Assumindo que exista um botão criado chamado 'hitboxSelectBtn', conecte assim:
-- hitboxSelectBtn.MouseButton1Click:Connect(toggleHitboxMenu)

-- PARTE 6: PÁGINA 3 - TUTORIAL DE USO

local tutorialGui = Instance.new("ScreenGui")
tutorialGui.Name = "TutorialGui"
tutorialGui.ResetOnSpawn = false
tutorialGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
tutorialGui.Enabled = false

local tutorialFrame = Instance.new("Frame")
tutorialFrame.Size = UDim2.new(0, 420, 0, 350)
tutorialFrame.Position = UDim2.new(0.5, -210, 0.5, -175)
tutorialFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
tutorialFrame.BorderSizePixel = 0
tutorialFrame.Visible = true
tutorialFrame.Parent = tutorialGui

local tutorialTitle = Instance.new("TextLabel")
tutorialTitle.Size = UDim2.new(1, 0, 0, 40)
tutorialTitle.Position = UDim2.new(0, 0, 0, 0)
tutorialTitle.BackgroundTransparency = 1
tutorialTitle.Text = "Tutorial de Uso"
tutorialTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
tutorialTitle.Font = Enum.Font.SourceSansBold
tutorialTitle.TextSize = 26
tutorialTitle.Parent = tutorialFrame

local tutorialText = Instance.new("TextLabel")
tutorialText.Size = UDim2.new(1, -20, 1, -80)
tutorialText.Position = UDim2.new(0, 10, 0, 45)
tutorialText.BackgroundTransparency = 1
tutorialText.TextColor3 = Color3.fromRGB(230, 230, 230)
tutorialText.Font = Enum.Font.SourceSans
tutorialText.TextSize = 16
tutorialText.TextWrapped = true
tutorialText.TextYAlignment = Enum.TextYAlignment.Top
tutorialText.Text = [[
• Aimbot Auto: Mira automaticamente no inimigo mais próximo dentro do FOV.
• Aimbot Legit: Mira com precisão e atira automaticamente quando o inimigo está visado, sem desperdiçar munição.
• Aimbot Manual: Você mira manualmente com o botão de mira; o script não mira nem atira sozinho.
• ESP: Exibe caixas, linhas, nomes, vida e distância dos jogadores habilitados.
• Wallhack: Destaca inimigos com efeito neon; o inimigo visado recebe contorno amarelo.
• Selecione a hitbox prioritária no menu "Selecionar Hitbox".
• Use os botões +FOV e -FOV para ajustar o alcance do campo de visão do aimbot.
• Use as setas ▶️ e ◀️ para navegar entre as páginas do menu.
• O botão 🔽 minimiza e maximiza o menu para liberar espaço na tela.
]]

tutorialText.Parent = tutorialFrame

local closeTutorialBtn = Instance.new("TextButton")
closeTutorialBtn.Size = UDim2.new(0, 80, 0, 35)
closeTutorialBtn.Position = UDim2.new(1, -90, 1, -45)
closeTutorialBtn.Text = "Fechar"
closeTutorialBtn.Font = Enum.Font.SourceSansBold
closeTutorialBtn.TextSize = 18
closeTutorialBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
closeTutorialBtn.TextColor3 = Color3.new(1, 1, 1)
closeTutorialBtn.Parent = tutorialFrame

closeTutorialBtn.MouseButton1Click:Connect(function()
    tutorialGui.Enabled = false
end)

local tutorialPageEnabled = false

local function toggleTutorialPage()
    tutorialPageEnabled = not tutorialPageEnabled
    tutorialGui.Enabled = tutorialPageEnabled
end

-- Exemplo de uso: conecte este toggle a um botão no menu principal que abre a página de tutorial
-- exemplo: tutorialButton.MouseButton1Click:Connect(toggleTutorialPage)


-- PARTE 7: SISTEMA DE NAVEGAÇÃO ENTRE PÁGINAS E LAYOUT

local currentPage = 1
local totalPages = 3

-- Criar botões de navegação
local prevPageBtn = Instance.new("TextButton")
prevPageBtn.Size = UDim2.new(0, 40, 0, 30)
prevPageBtn.Position = UDim2.new(0, 10, 1, -40)
prevPageBtn.Text = "◀️"
prevPageBtn.Font = Enum.Font.SourceSansBold
prevPageBtn.TextSize = 18
prevPageBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
prevPageBtn.TextColor3 = Color3.new(1, 1, 1)
prevPageBtn.Parent = panel

local nextPageBtn = Instance.new("TextButton")
nextPageBtn.Size = UDim2.new(0, 40, 0, 30)
nextPageBtn.Position = UDim2.new(1, -50, 1, -40)
nextPageBtn.Text = "▶️"
nextPageBtn.Font = Enum.Font.SourceSansBold
nextPageBtn.TextSize = 18
nextPageBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
nextPageBtn.TextColor3 = Color3.new(1, 1, 1)
nextPageBtn.Parent = panel

-- Função para atualizar visibilidade dos botões e conteúdo por página
local function updatePage()
    prevPageBtn.Visible = (currentPage > 1)
    nextPageBtn.Visible = (currentPage < totalPages)
    
    -- Aqui: esconder/mostrar grupos de botões e elementos conforme currentPage
    -- Exemplo:
    if currentPage == 1 then
        -- Mostrar elementos da página 1, esconder outras páginas
        -- ex: page1Frame.Visible = true
        -- page2Frame.Visible = false
        -- page3Frame.Visible = false
    elseif currentPage == 2 then
        -- page1Frame.Visible = false
        -- page2Frame.Visible = true
        -- page3Frame.Visible = false
    elseif currentPage == 3 then
        -- page1Frame.Visible = false
        -- page2Frame.Visible = false
        -- page3Frame.Visible = true
    end
end

prevPageBtn.MouseButton1Click:Connect(function()
    if currentPage > 1 then
        currentPage = currentPage - 1
        updatePage()
    end
end)

nextPageBtn.MouseButton1Click:Connect(function()
    if currentPage < totalPages then
        currentPage = currentPage + 1
        updatePage()
    end
end)

-- Inicializa páginas
updatePage()

-- Drag geral do painel (qualquer parte)
local dragging = false
local dragStart, startPos

panel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = panel.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

panel.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Drag também para o botão toggle (🔽/🔼), para mover ele livremente mesmo com o painel minimizado
local toggleDragging = false
local toggleDragStart, toggleStartPos

toggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        toggleDragging = true
        toggleDragStart = input.Position
        toggleStartPos = toggleButton.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                toggleDragging = false
            end
        end)
    end
end)

toggleButton.InputChanged:Connect(function(input)
    if toggleDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - toggleDragStart
        toggleButton.Position = UDim2.new(toggleStartPos.X.Scale, toggleStartPos.X.Offset + delta.X, toggleStartPos.Y.Scale, toggleStartPos.Y.Offset + delta.Y)
    end
end)

-- Ajuste FOV Botões (embaixo do toggle Mostrar FOV)
local fovMinusBtn = createFOVAdjustButton("- FOV", 215, -5)
local fovPlusBtn = createFOVAdjustButton("+ FOV", 215, 5)

-- Posicionar esses botões logo abaixo do botão Mostrar FOV, mas só visíveis na página 1
fovMinusBtn.Visible = false
fovPlusBtn.Visible = false

-- Atualiza a visibilidade inicial e posição dos botões
updatePage()

-- Minimize toggle botão fica no topo direito, independente da página
toggleButton.Position = UDim2.new(1, -50, 0, 5)
toggleButton.Visible = true

return gui
