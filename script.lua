local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

-- ======== Variáveis Globais ========
_G.FOV_RADIUS = 65
_G.FOV_VISIBLE = true

-- Aimbots (auto / legit) só 1 ativo por vez
_G.aimbotAutoEnabled = false
_G.aimbotLegitEnabled = false

-- ESP Config
_G.espEnemiesEnabled = true
_G.espAlliesEnabled = false
_G.espBoxEnabled = true
_G.espLineEnabled = false
_G.espNameEnabled = true
_G.espHPEnabled = true
_G.espDistanceEnabled = false
_G.espWallhackEnabled = true

-- Hitbox Selection: tabela {Head = "Prioritário"/"Nenhum", Torso = ..., etc}
-- Inicial: cabeça e torso prioritários por padrão
_G.hitboxSelection = {
    Head = "Prioritário",
    Torso = "Prioritário",
    LeftArm = "Nenhum",
    RightArm = "Nenhum",
    LeftLeg = "Nenhum",
    RightLeg = "Nenhum",
}

-- Variáveis internas
local shooting, aiming = false, false
local currentTarget = nil
local dragging = false
local dragStart, startPos
local minimized = false
local currentPage = 1

-- Referências de botões mobile (ajuste conforme seu jogo)
local aimButton = LocalPlayer.PlayerScripts:WaitForChild("Assets")
    .Ui.TouchInputController.BlasterTouchGui.Buttons:WaitForChild("AimButton")
local shootButton = LocalPlayer.PlayerScripts:WaitForChild("Assets")
    .Ui.TouchInputController.BlasterTouchGui.Buttons:WaitForChild("ShootButton")

-- Utils
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

-- Hitbox parts ordenados por prioridade para o aimbot
local hitboxPriorityOrder = {"Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}

-- Checa se uma parte pode ser alvo (selecionada como "Prioritário")
local function isHitboxPrioritary(partName)
    return _G.hitboxSelection[partName] == "Prioritário"
end

-- Retorna lista de partes selecionadas para mira do inimigo
local function getTargetableHitboxes(character)
    local parts = {}
    for _, partName in ipairs(hitboxPriorityOrder) do
        local part = character:FindFirstChild(partName)
        if part and isHitboxPrioritary(partName) then
            table.insert(parts, part)
        end
    end
    return parts
end

-- Raycast checando visibilidade considerando vidro, plantas etc (usando CanCollide e Transparência)
local function canSeeTarget(part)
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin).Unit * (part.Position - origin).Magnitude

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local result = workspace:Raycast(origin, direction, raycastParams)
    if not result then return true end

    local hitInstance = result.Instance
    if hitInstance:IsDescendantOf(part.Parent) then
        return true
    end

    -- Checa se o objeto que bloqueia é transparente ou "permitido" para mira (vidro, plantas, etc)
    local material = hitInstance.Material
    local transparency = hitInstance.Transparency
    local canCollide = hitInstance.CanCollide

    local allowedMaterials = {
        Enum.Material.Glass,
        Enum.Material.ForceField,
        Enum.Material.Water,
        Enum.Material.LeafyGrass,
        Enum.Material.Fabric,
        Enum.Material.Plastic,
    }

    local allowed = false
    for _, mat in pairs(allowedMaterials) do
        if material == mat then
            allowed = true
            break
        end
    end

    if allowed and transparency < 0.7 then -- vidro/planta mas não totalmente invisível
        return true
    end

    return false
end

-- Retorna a parte alvo mais próxima dentro do FOV, que está visível (para aimbot)
local function getClosestHitboxInFOV(character, center)
    local hitboxes = getTargetableHitboxes(character)
    local shortestDistance = _G.FOV_RADIUS + 1
    local chosenPart = nil
    for _, part in pairs(hitboxes) do
        local screenPos, visible = Camera:WorldToViewportPoint(part.Position)
        if visible then
            local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
            if dist < shortestDistance and dist <= _G.FOV_RADIUS and canSeeTarget(part) then
                shortestDistance = dist
                chosenPart = part
            end
        end
    end
    return chosenPart
end

-- Retorna o inimigo mais próximo dentro do FOV e visível, que pode ser alvo
local function getClosestVisibleEnemy()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local shortestDistance = _G.FOV_RADIUS + 1
    local closestPlayer = nil
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

        local targetPart = getClosestHitboxInFOV(player.Character, center)
        if targetPart then
            local screenPos, visible = Camera:WorldToViewportPoint(targetPart.Position)
            if visible then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                if dist < shortestDistance then
                    shortestDistance = dist
                    closestPlayer = player
                end
            end
        end
    end
    return closestPlayer
end

-- ======= ESP + Wallhack =======
local espData = {}
local highlights = {}

local function disableHighlight(player)
    local chams = highlights[player]
    if chams then
        chams.Enabled = false
    end
end

local function createHighlight(player, color, isTarget)
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
    chams.OutlineColor = isTarget and Color3.fromRGB(255, 255, 0) or Color3.new(0, 0, 0)
    chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
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
    distanceTag.Size = 12
    distanceTag.Center = true
    distanceTag.Outline = true
    distanceTag.Color = Color3.fromRGB(200, 200, 200)
    distanceTag.Visible = false

    espData[player] = {box = box, line = line, nameTag = nameTag, healthBar = healthBar, distanceTag = distanceTag}

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

                -- Cor do ESP e Wallhack neon
                if _G.espWallhackEnabled then
                    if player == currentTarget then
                        createHighlight(player, Color3.fromRGB(255, 255, 0), true) -- amarelo alvo
                        box.Color = Color3.fromRGB(255, 255, 0)
                        nameTag.Color = Color3.fromRGB(255, 255, 0)
                        line.Color = Color3.fromRGB(255, 255, 0)
                        healthBar.Color = Color3.fromRGB(255, 255, 0)
                        distanceTag.Color = Color3.fromRGB(255, 255, 0)
                    else
                        if player.Team == LocalPlayer.Team and _G.espAlliesEnabled then
                            createHighlight(player, Color3.fromRGB(0, 150, 255), false) -- azul aliados
                            box.Color = Color3.fromRGB(0, 150, 255)
                            nameTag.Color = Color3.fromRGB(0, 150, 255)
                            line.Color = Color3.fromRGB(0, 150, 255)
                            healthBar.Color = Color3.fromRGB(0, 150, 255)
                            distanceTag.Color = Color3.fromRGB(0, 150, 255)
                        elseif player.Team ~= LocalPlayer.Team and _G.espEnemiesEnabled then
                            createHighlight(player, Color3.fromRGB(255, 0, 0), false) -- vermelho inimigos
                            box.Color = Color3.fromRGB(255, 0, 0)
                            nameTag.Color = Color3.fromRGB(255, 255, 255)
                            line.Color = Color3.fromRGB(255, 0, 0)
                            healthBar.Color = Color3.fromRGB(255, 0, 0)
                            distanceTag.Color = Color3.fromRGB(255, 0, 0)
                        else
                            disableHighlight(player)
                            box.Color = Color3.fromRGB(255, 255, 255)
                            nameTag.Color = Color3.fromRGB(255, 255, 255)
                            line.Color = Color3.fromRGB(255, 255, 255)
                            healthBar.Color = Color3.fromRGB(255, 255, 255)
                            distanceTag.Color = Color3.fromRGB(255, 255, 255)
                        end
                    end
                else
                    disableHighlight(player)
                    box.Color = Color3.fromRGB(255, 255, 255)
                end

                box.Visible = true
            else
                box.Visible = false
                disableHighlight(player)
            end

            if _G.espLineEnabled then
                line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                line.To = Vector2.new(hrp.Position.X, hrp.Position.Y) -- This needs world to screen? Let's fix below
                local fromPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                local toPos, toVis = Camera:WorldToViewportPoint(hrp.Position)
                if toVis then
                    line.From = fromPos
                    line.To = Vector2.new(toPos.X, toPos.Y)
                    line.Visible = true
                else
                    line.Visible = false
                end
            else
                line.Visible = false
            end

            if _G.espNameEnabled then
                nameTag.Text = player.Name
                nameTag.Position = Vector2.new(headPos.X, headPos.Y - 20)
                nameTag.Visible = true
            else
                nameTag.Visible = false
            end

            if _G.espHPEnabled then
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
                local distance = math.floor((hrp.Position - Camera.CFrame.Position).Magnitude)
                distanceTag.Text = tostring(distance) .. "m"
                distanceTag.Position = Vector2.new(headPos.X, headPos.Y + 12)
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
            disableHighlight(player)
        end
    end)
end

for _, player in pairs(Players:GetPlayers()) do
    createESP(player)
end
Players.PlayerAdded:Connect(createESP)

-- ======= Aimbot =======
RunService.RenderStepped:Connect(function()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    -- Atualiza alvo e mira conforme tipo de aimbot ativo
    if _G.aimbotAutoEnabled or _G.aimbotLegitEnabled then
        local target = getClosestVisibleEnemy()
        if target and target.Character and isAlive(target.Character) then
            local hitboxPart = getClosestHitboxInFOV(target.Character, center)
            if hitboxPart and canSeeTarget(hitboxPart) then
                currentTarget = target
                local camPos = Camera.CFrame.Position
                local aimPos = hitboxPart.Position

                if _G.aimbotAutoEnabled then
                    -- Mira instantânea (snapping) no alvo
                    Camera.CFrame = CFrame.new(camPos, aimPos)
                elseif _G.aimbotLegitEnabled then
                    -- Aimbot Legit: suaviza movimento e dispara automático
                    local direction = (aimPos - camPos).Unit
                    local currentLook = Camera.CFrame.LookVector
                    local newLook = currentLook:Lerp(direction, 0.15) -- suavização (ajuste 0.15 para mais "legit")

                    Camera.CFrame = CFrame.new(camPos, camPos + newLook)

                    -- Atira automático se estiver mirando no alvo e atirando (checa distância FOV e visibilidade)
                    if aiming and shooting then
                        -- Simula clique ou chama função de disparo do jogo aqui
                        -- Como exemplo: você pode disparar via evento do jogo
                        -- Neste código, apenas deixamos uma flag para controle externo
                    end
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

-- Controle dos botões mobile
aimButton.MouseButton1Down:Connect(function()
    aiming = true
end)
aimButton.MouseButton1Up:Connect(function()
    aiming = false
    currentTarget = nil
end)
shootButton.MouseButton1Down:Connect(function()
    shooting = true
end)
shootButton.MouseButton1Up:Connect(function()
    shooting = false
end)

-- ======= GUI (Menu) =======

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimbotESPMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Container principal
local menuFrame = Instance.new("Frame")
menuFrame.Name = "MenuFrame"
menuFrame.Size = UDim2.new(0, 320, 0, 280)
menuFrame.Position = UDim2.new(0, 50, 0, 50)
menuFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
menuFrame.BorderSizePixel = 0
menuFrame.Parent = ScreenGui
menuFrame.Visible = true

-- Barra de título + minimizar/maximizar e arrastar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
titleBar.Parent = menuFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Aimbot & ESP Menu"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 18
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar
titleLabel.Position = UDim2.new(0.03, 0, 0, 0)

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Name = "MinimizeBtn"
minimizeBtn.Size = UDim2.new(0, 30, 1, 0)
minimizeBtn.Position = UDim2.new(0.75, 0, 0, 0)
minimizeBtn.Text = "-"
minimizeBtn.Font = Enum.Font.SourceSansBold
minimizeBtn.TextSize = 20
minimizeBtn.TextColor3 = Color3.new(1, 1, 1)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
minimizeBtn.Parent = titleBar

local maximizeBtn = Instance.new("TextButton")
maximizeBtn.Name = "MaximizeBtn"
maximizeBtn.Size = UDim2.new(0, 30, 1, 0)
maximizeBtn.Position = UDim2.new(0.8, 0, 0, 0)
maximizeBtn.Text = "🔼"
maximizeBtn.Font = Enum.Font.SourceSansBold
maximizeBtn.TextSize = 18
maximizeBtn.TextColor3 = Color3.new(1, 1, 1)
maximizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
maximizeBtn.Parent = ScreenGui
maximizeBtn.Visible = false

-- Função para esconder menu e mostrar só botão minimizar
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

-- Tornar botão maximizar arrastável
maximizeBtn.Active = true
maximizeBtn.Draggable = true

-- Tornar menu arrastável pelo título
titleBar.Active = true
titleBar.Draggable = true

-- Navegação entre páginas
local pageLabel = Instance.new("TextLabel")
pageLabel.Name = "PageLabel"
pageLabel.Size = UDim2.new(0, 50, 0, 25)
pageLabel.Position = UDim2.new(0.5, -25, 0, 35)
pageLabel.BackgroundTransparency = 1
pageLabel.TextColor3 = Color3.new(1, 1, 1)
pageLabel.Font = Enum.Font.SourceSansBold
pageLabel.TextSize = 18
pageLabel.Text = "1 / 3"
pageLabel.Parent = menuFrame

local backBtn = Instance.new("TextButton")
backBtn.Name = "BackBtn"
backBtn.Size = UDim2.new(0, 40, 0, 25)
backBtn.Position = UDim2.new(0, 10, 0, 35)
backBtn.Text = "◀️"
backBtn.Font = Enum.Font.SourceSansBold
backBtn.TextSize = 18
backBtn.TextColor3 = Color3.new(1, 1, 1)
backBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
backBtn.Parent = menuFrame

local forwardBtn = Instance.new("TextButton")
forwardBtn.Name = "ForwardBtn"
forwardBtn.Size = UDim2.new(0, 40, 0, 25)
forwardBtn.Position = UDim2.new(1, -50, 0, 35)
forwardBtn.Text = "▶️"
forwardBtn.Font = Enum.Font.SourceSansBold
forwardBtn.TextSize = 18
forwardBtn.TextColor3 = Color3.new(1, 1, 1)
forwardBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
forwardBtn.Parent = menuFrame

local function updatePage()
    pageLabel.Text = currentPage .. " / 3"
    for _, frame in pairs(menuFrame:GetChildren()) do
        if frame:IsA("Frame") and frame.Name:match("^Page%d$") then
            frame.Visible = frame.Name == ("Page" .. currentPage)
        end
    end
end

backBtn.MouseButton1Click:Connect(function()
    if currentPage > 1 then
        currentPage = currentPage - 1
        updatePage()
    end
end)

forwardBtn.MouseButton1Click:Connect(function()
    if currentPage < 3 then
        currentPage = currentPage + 1
        updatePage()
    end
end)

-- ============ Página 1: Aimbots ===============
local page1 = Instance.new("Frame")
page1.Name = "Page1"
page1.Size = UDim2.new(1, 0, 1, -60)
page1.Position = UDim2.new(0, 0, 0, 60)
page1.BackgroundTransparency = 1
page1.Parent = menuFrame

local aimbotAutoToggle = Instance.new("TextButton")
aimbotAutoToggle.Name = "AimbotAutoToggle"
aimbotAutoToggle.Size = UDim2.new(0, 140, 0, 40)
aimbotAutoToggle.Position = UDim2.new(0, 15, 0, 10)
aimbotAutoToggle.Text = "Aimbot Automático: OFF"
aimbotAutoToggle.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
aimbotAutoToggle.TextColor3 = Color3.new(1, 1, 1)
aimbotAutoToggle.Font = Enum.Font.SourceSansBold
aimbotAutoToggle.TextSize = 16
aimbotAutoToggle.Parent = page1

local aimbotLegitToggle = Instance.new("TextButton")
aimbotLegitToggle.Name = "AimbotLegitToggle"
aimbotLegitToggle.Size = UDim2.new(0, 140, 0, 40)
aimbotLegitToggle.Position = UDim2.new(0, 170, 0, 10)
aimbotLegitToggle.Text = "Aimbot Legit: OFF"
aimbotLegitToggle.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
aimbotLegitToggle.TextColor3 = Color3.new(1, 1, 1)
aimbotLegitToggle.Font = Enum.Font.SourceSansBold
aimbotLegitToggle.TextSize = 16
aimbotLegitToggle.Parent = page1

local fovToggle = Instance.new("TextButton")
fovToggle.Name = "FOVToggle"
fovToggle.Size = UDim2.new(0, 140, 0, 40)
fovToggle.Position = UDim2.new(0, 15, 0, 60)
fovToggle.Text = "Mostrar FOV: ON"
fovToggle.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
fovToggle.TextColor3 = Color3.new(1, 1, 1)
fovToggle.Font = Enum.Font.SourceSansBold
fovToggle.TextSize = 16
fovToggle.Parent = page1

local fovIncrease = Instance.new("TextButton")
fovIncrease.Name = "FOVIncrease"
fovIncrease.Size = UDim2.new(0, 40, 0, 40)
fovIncrease.Position = UDim2.new(0, 170, 0, 60)
fovIncrease.Text = "+"
fovIncrease.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
fovIncrease.TextColor3 = Color3.new(1, 1, 1)
fovIncrease.Font = Enum.Font.SourceSansBold
fovIncrease.TextSize = 30
fovIncrease.Parent = page1

local fovDecrease = Instance.new("TextButton")
fovDecrease.Name = "FOVDecrease"
fovDecrease.Size = UDim2.new(0, 40, 0, 40)
fovDecrease.Position = UDim2.new(0, 215, 0, 60)
fovDecrease.Text = "-"
fovDecrease.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
fovDecrease.TextColor3 = Color3.new(1, 1, 1)
fovDecrease.Font = Enum.Font.SourceSansBold
fovDecrease.TextSize = 30
fovDecrease.Parent = page1

local function updateAimbotToggles()
    aimbotAutoToggle.Text = "Aimbot Automático: " .. (_G.aimbotAutoEnabled and "ON" or "OFF")
    aimbotLegitToggle.Text = "Aimbot Legit: " .. (_G.aimbotLegitEnabled and "ON" or "OFF")
    fovToggle.Text = "Mostrar FOV: " .. (_G.FOV_VISIBLE and "ON" or "OFF")
end

aimbotAutoToggle.MouseButton1Click:Connect(function()
    if not _G.aimbotAutoEnabled then
        _G.aimbotAutoEnabled = true
        _G.aimbotLegitEnabled = false
    else
        _G.aimbotAutoEnabled = false
    end
    updateAimbotToggles()
end)

aimbotLegitToggle.MouseButton1Click:Connect(function()
    if not _G.aimbotLegitEnabled then
        _G.aimbotLegitEnabled = true
        _G.aimbotAutoEnabled = false
    else
        _G.aimbotLegitEnabled = false
    end
    updateAimbotToggles()
end)

fovToggle.MouseButton1Click:Connect(function()
    _G.FOV_VISIBLE = not _G.FOV_VISIBLE
    updateAimbotToggles()
end)

fovIncrease.MouseButton1Click:Connect(function()
    _G.FOV_RADIUS = math.min(_G.FOV_RADIUS + 5, 200)
end)
fovDecrease.MouseButton1Click:Connect(function()
    _G.FOV_RADIUS = math.max(_G.FOV_RADIUS - 5, 20)
end)

updateAimbotToggles()

-- Desenha círculo do FOV no centro da tela
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 2
fovCircle.NumSides = 50
fovCircle.Color = Color3.fromRGB(255, 255, 255)
fovCircle.Transparency = 0.6

RunService.RenderStepped:Connect(function()
    if _G.FOV_VISIBLE and not minimized then
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        fovCircle.Radius = _G.FOV_RADIUS
        fovCircle.Visible = true
    else
        fovCircle.Visible = false
    end
end)

-- ============ Página 2: ESP ===============
local page2 = Instance.new("Frame")
page2.Name = "Page2"
page2.Size = UDim2.new(1, 0, 1, -60)
page2.Position = UDim2.new(0, 0, 0, 60)
page2.BackgroundTransparency = 1
page2.Parent = menuFrame
page2.Visible = false

local function createToggle(text, pos, initialValue, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 140, 0, 35)
    btn.Position = pos
    btn.Text = text .. ": " .. (initialValue and "ON" or "OFF")
    btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 16
    btn.Parent = page2

    btn.MouseButton1Click:Connect(function()
        callback(not initialValue)
        initialValue = not initialValue
        btn.Text = text .. ": " .. (initialValue and "ON" or "OFF")
    end)

    return btn
end

local espEnemyToggle = createToggle("ESP Inimigos", UDim2.new(0, 15, 0, 10), _G.espEnemiesEnabled, function(val) _G.espEnemiesEnabled = val end)
local espAlliesToggle = createToggle("ESP Aliados", UDim2.new(0, 170, 0, 10), _G.espAlliesEnabled, function(val) _G.espAlliesEnabled = val end)
local espBoxToggle = createToggle("Caixa (Box)", UDim2.new(0, 15, 0, 55), _G.espBoxEnabled, function(val) _G.espBoxEnabled = val end)
local espLineToggle = createToggle("Linha", UDim2.new(0, 170, 0, 55), _G.espLineEnabled, function(val) _G.espLineEnabled = val end)
local espNameToggle = createToggle("Nome", UDim2.new(0, 15, 0, 100), _G.espNameEnabled, function(val) _G.espNameEnabled = val end)
local espHPToggle = createToggle("HP", UDim2.new(0, 170, 0, 100), _G.espHPEnabled, function(val) _G.espHPEnabled = val end)
local espDistanceToggle = createToggle("Distância", UDim2.new(0, 15, 0, 145), _G.espDistanceEnabled, function(val) _G.espDistanceEnabled = val end)
local espWallhackToggle = createToggle("Wallhack Neon", UDim2.new(0, 170, 0, 145), _G.espWallhackEnabled, function(val) _G.espWallhackEnabled = val end)

-- Popup seleção hitbox
local hitboxPopup = Instance.new("Frame")
hitboxPopup.Name = "HitboxPopup"
hitboxPopup.Size = UDim2.new(0, 280, 0, 280)
hitboxPopup.Position = UDim2.new(0.5, -140, 0.5, -140)
hitboxPopup.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
hitboxPopup.BorderSizePixel = 0
hitboxPopup.Visible = false
hitboxPopup.Parent = ScreenGui

-- Imagem "Bacon" Roblox (pode substituir pelo caminho de imagem real)
local baconImage = Instance.new("ImageLabel")
baconImage.Name = "BaconImage"
baconImage.Size = UDim2.new(0, 180, 0, 260)
baconImage.Position = UDim2.new(0, 50, 0, 10)
baconImage.BackgroundTransparency = 1
baconImage.Image = "rbxassetid://4483345998" -- Exemplo de modelo "Bacon"
baconImage.Parent = hitboxPopup

-- Botões invisíveis sobre o boneco para selecionar hitbox
local hitboxButtons = {}

local function createHitboxButton(name, pos, size)
    local btn = Instance.new("TextButton")
    btn.Name = name .. "Btn"
    btn.Size = size
    btn.Position = pos
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = hitboxPopup
    return btn
end

-- Posicionamento aproximado hitboxes no bacon
hitboxButtons.Head = createHitboxButton("Head", UDim2.new(0, 110, 0, 5), UDim2.new(0, 50, 0, 50))
hitboxButtons.Torso = createHitboxButton("Torso", UDim2.new(0, 90, 0, 60), UDim2.new(0, 80, 0, 90))
hitboxButtons.LeftArm = createHitboxButton("LeftArm", UDim2.new(0, 40, 0, 60), UDim2.new(0, 40, 0, 90))
hitboxButtons.RightArm = createHitboxButton("RightArm", UDim2.new(0, 170, 0, 60), UDim2.new(0, 40, 0, 90))
hitboxButtons.LeftLeg = createHitboxButton("LeftLeg", UDim2.new(0, 70, 0, 150), UDim2.new(0, 40, 0, 90))
hitboxButtons.RightLeg = createHitboxButton("RightLeg", UDim2.new(0, 130, 0, 150), UDim2.new(0, 40, 0, 90))

local function updateHitboxButtonVisuals()
    for partName, btn in pairs(hitboxButtons) do
        local state = _G.hitboxSelection[partName] or "Nenhum"
        btn.BackgroundColor3 = state == "Prioritário" and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(40, 40, 40)
        btn.BackgroundTransparency = state == "Prioritário" and 0.3 or 0.8
    end
end

for partName, btn in pairs(hitboxButtons) do
    btn.MouseButton1Click:Connect(function()
        local current = _G.hitboxSelection[partName]
        if current == "Prioritário" then
            _G.hitboxSelection[partName] = "Nenhum"
        else
            _G.hitboxSelection[partName] = "Prioritário"
        end
        updateHitboxButtonVisuals()
    end)
end

updateHitboxButtonVisuals()

local closeHitboxBtn = Instance.new("TextButton")
closeHitboxBtn.Name = "CloseHitboxBtn"
closeHitboxBtn.Size = UDim2.new(0, 40, 0, 30)
closeHitboxBtn.Position = UDim2.new(1, -50, 0, 10)
closeHitboxBtn.Text = "X"
closeHitboxBtn.Font = Enum.Font.SourceSansBold
closeHitboxBtn.TextSize = 20
closeHitboxBtn.TextColor3 = Color3.new(1, 1, 1)
closeHitboxBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
closeHitboxBtn.Parent = hitboxPopup

closeHitboxBtn.MouseButton1Click:Connect(function()
    hitboxPopup.Visible = false
end)

local selectHitboxBtn = Instance.new("TextButton")
selectHitboxBtn.Name = "SelectHitboxBtn"
selectHitboxBtn.Size = UDim2.new(0, 140, 0, 40)
selectHitboxBtn.Position = UDim2.new(0, 15, 0, 190)
selectHitboxBtn.Text = "Selecionar Hitbox"
selectHitboxBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
selectHitboxBtn.TextColor3 = Color3.new(1, 1, 1)
selectHitboxBtn.Font = Enum.Font.SourceSansBold
selectHitboxBtn.TextSize = 16
selectHitboxBtn.Parent = page2

selectHitboxBtn.MouseButton1Click:Connect(function()
    hitboxPopup.Visible = not hitboxPopup.Visible
end)

-- ============ Página 3: Tutorial ===============
local page3 = Instance.new("Frame")
page3.Name = "Page3"
page3.Size = UDim2.new(1, 0, 1, -60)
page3.Position = UDim2.new(0, 0, 0, 60)
page3.BackgroundTransparency = 1
page3.Parent = menuFrame
page3.Visible = false

local tutorialText = Instance.new("TextLabel")
tutorialText.Name = "TutorialText"
tutorialText.Size = UDim2.new(1, -20, 1, -20)
tutorialText.Position = UDim2.new(0, 10, 0, 10)
tutorialText.BackgroundTransparency = 1
tutorialText.TextColor3 = Color3.new(1, 1, 1)
tutorialText.TextWrapped = true
tutorialText.TextYAlignment = Enum.TextYAlignment.Top
tutorialText.Font = Enum.Font.SourceSans
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

local closeTutorialBtn = Instance.new("TextButton")
closeTutorialBtn.Name = "CloseTutorialBtn"
closeTutorialBtn.Size = UDim2.new(0, 40, 0, 30)
closeTutorialBtn.Position = UDim2.new(1, -50, 0, 10)
closeTutorialBtn.Text = "X"
closeTutorialBtn.Font = Enum.Font.SourceSansBold
closeTutorialBtn.TextSize = 20
closeTutorialBtn.TextColor3 = Color3.new(1, 1, 1)
closeTutorialBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
closeTutorialBtn.Parent = page3

closeTutorialBtn.MouseButton1Click:Connect(function()
    page3.Visible = false
    currentPage = 1
    updatePage()
end)

-- Navegação para abrir tutorial na página 1
local tutorialBtn = Instance.new("TextButton")
tutorialBtn.Name = "TutorialBtn"
tutorialBtn.Size = UDim2.new(0, 140, 0, 40)
tutorialBtn.Position = UDim2.new(0, 170, 0, 190)
tutorialBtn.Text = "Tutorial"
tutorialBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
tutorialBtn.TextColor3 = Color3.new(1, 1, 1)
tutorialBtn.Font = Enum.Font.SourceSansBold
tutorialBtn.TextSize = 16
tutorialBtn.Parent = page1

tutorialBtn.MouseButton1Click:Connect(function()
    page3.Visible = true
    currentPage = 3
    updatePage()
end)

updatePage()

-- ========== ESP Implementation ===========
local ESPObjects = {}

local function createESPForPlayer(player)
    local esp = {}
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    local hrp = character.HumanoidRootPart

    esp.Box = Drawing.new("Square")
    esp.Box.Visible = false
    esp.Box.Color = Color3.new(1, 1, 1)
    esp.Box.Thickness = 2

    esp.Line = Drawing.new("Line")
    esp.Line.Visible = false
    esp.Line.Color = Color3.new(1, 1, 1)
    esp.Line.Thickness = 1

    esp.Name = Drawing.new("Text")
    esp.Name.Visible = false
    esp.Name.Color = Color3.new(1, 1, 1)
    esp.Name.Center = true
    esp.Name.Outline = true
    esp.Name.Size = 16

    esp.HPBar = Drawing.new("Square")
    esp.HPBar.Visible = false
    esp.HPBar.Color = Color3.fromRGB(0, 255, 0)
    esp.HPBar.Thickness = 1

    esp.Distance = Drawing.new("Text")
    esp.Distance.Visible = false
    esp.Distance.Color = Color3.new(1, 1, 1)
    esp.Distance.Center = true
    esp.Distance.Outline = true
    esp.Distance.Size = 14

    ESPObjects[player] = esp
    return esp
end

local function updateESPForPlayer(player)
    local esp = ESPObjects[player]
    if not esp then
        esp = createESPForPlayer(player)
        if not esp then return end
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not character or not humanoid or humanoid.Health <= 0 then
        for _, obj in pairs(esp) do
            obj.Visible = false
        end
        return
    end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local cameraPos = Camera.CFrame.Position
    local rootPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
    if not onScreen then
        for _, obj in pairs(esp) do
            obj.Visible = false
        end
        return
    end

    local distance = (cameraPos - rootPart.Position).Magnitude

    -- Checar se está vivo, não é aliado (aqui supõe equipe, ajustar conforme jogo)
    local isEnemy = player.Team ~= LocalPlayer.Team
    if (not _G.espEnemiesEnabled and isEnemy) or (not _G.espAlliesEnabled and not isEnemy) then
        for _, obj in pairs(esp) do
            obj.Visible = false
        end
        return
    end

    -- Atualizar Box
    if _G.espBoxEnabled then
        local size = 100 / distance
        esp.Box.Size = Vector2.new(size, size)
        esp.Box.Position = Vector2.new(rootPos.X - size / 2, rootPos.Y - size / 2)
        esp.Box.Color = isEnemy and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 0, 255)
        esp.Box.Visible = true
    else
        esp.Box.Visible = false
    end

    -- Atualizar Linha
    if _G.espLineEnabled then
        esp.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        esp.Line.To = Vector2.new(rootPos.X, rootPos.Y)
        esp.Line.Color = isEnemy and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 0, 255)
        esp.Line.Visible = true
    else
        esp.Line.Visible = false
    end

    -- Atualizar Nome
    if _G.espNameEnabled then
        esp.Name.Text = player.Name
        esp.Name.Position = Vector2.new(rootPos.X, rootPos.Y - 60)
        esp.Name.Color = isEnemy and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 0, 255)
        esp.Name.Visible = true
    else
        esp.Name.Visible = false
    end

    -- Atualizar HP
    if _G.espHPEnabled and humanoid then
        local healthRatio = humanoid.Health / humanoid.MaxHealth
        local barHeight = 40
        esp.HPBar.Size = Vector2.new(6, barHeight * healthRatio)
        esp.HPBar.Position = Vector2.new(rootPos.X + 30, rootPos.Y - 20 + barHeight * (1 - healthRatio))
        esp.HPBar.Color = Color3.fromRGB(0, 255, 0)
        esp.HPBar.Visible = true
    else
        esp.HPBar.Visible = false
    end

    -- Atualizar Distância
    if _G.espDistanceEnabled then
        esp.Distance.Text = tostring(math.floor(distance)) .. "m"
        esp.Distance.Position = Vector2.new(rootPos.X, rootPos.Y + 40)
        esp.Distance.Visible = true
    else
        esp.Distance.Visible = false
    end

    -- Wallhack Neon (simplesmente mudar cor ou brilho)
    if _G.espWallhackEnabled then
        -- Aplicar efeito neon em humanoides inimigos visíveis e não atrás de parede
        -- (Aqui só exemplo, pois o Roblox não tem efeito direto no Drawing API)
        -- Poderia usar Highlight Instances para isso, mas depende do jogo.
        -- Implementação simplificada: mudar cor da box para neon se inimigo visível
        if isEnemy then
            esp.Box.Color = Color3.fromRGB(255, 140, 0) -- laranja neon
        end
    end
end

-- Atualizar ESP a cada frame
RunService.RenderStepped:Connect(function()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            updateESPForPlayer(player)
        end
    end
end)

-- ========== Aimbot Implementation ===========

local function isAlive(player)
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function canSeeTarget(origin, targetPos)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    local result = workspace:Raycast(origin, (targetPos - origin).Unit * (targetPos - origin).Magnitude, raycastParams)
    if result then
        -- Verifica se atingiu o inimigo (ex: vidro, planta permite tiro)
        local hitPart = result.Instance
        if hitPart and hitPart:IsDescendantOf(workspace) then
            local isTransparent = hitPart.Transparency > 0.5 or hitPart.Name:lower():find("glass") or hitPart.Name:lower():find("plant")
            if isTransparent then
                return true
            end
            return hitPart:IsDescendantOf(LocalPlayer.Character) == false
        end
    else
        return true
    end
    return false
end

local function getHitboxPosition(character)
    -- Retorna o Vector3 da hitbox selecionada prioritária
    -- Prioridade: cabeça, torso, braços, pernas, conforme _G.hitboxSelection
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
    -- Default fallback
    return character.HumanoidRootPart.Position
end

local function findTarget()
    local closestTarget = nil
    local closestDistance = math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isAlive(player) then
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                -- Checar time para não mirar aliado
                if player.Team == LocalPlayer.Team then
                    continue
                end

                local targetPos = getHitboxPosition(char)
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
                if not onScreen then
                    continue
                end

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
    end
    return closestTarget
end

local function findTargetLegit()
    -- Mira "legit", com delay e suavidade, checando parede
    -- Usa a mesma lógica de findTarget, mas mira de forma suave
    return findTarget()
end

RunService.RenderStepped:Connect(function()
    if _G.aimbotAutoEnabled or _G.aimbotLegitEnabled then
        local targetData = nil
        if _G.aimbotAutoEnabled then
            targetData = findTarget()
        elseif _G.aimbotLegitEnabled then
            targetData = findTargetLegit()
        end

        if targetData then
            local mouse = game.Players.LocalPlayer:GetMouse()
            local aimPos = targetData.pos
            local screenPos = Camera:WorldToViewportPoint(aimPos)
            if screenPos.Z > 0 then
                -- Ajustar a mira do mouse para o alvo
                mousemoverel(screenPos.X - Camera.ViewportSize.X / 2, screenPos.Y - Camera.ViewportSize.Y / 2)
                if shooting and _G.aimbotAutoEnabled then
                    mouse1click()
                end
            end
        end
    end
end)

return ScreenGui
