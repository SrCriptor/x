local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Configurações globais (flags)
_G.FOV_RADIUS = 65
_G.FOV_VISIBLE = true
_G.aimbotAutoEnabled = false
_G.aimbotManualEnabled = false
_G.espEnemiesEnabled = true
_G.espAlliesEnabled = false

local shooting = false
local aiming = false
local dragging = false
local dragStart, startPos
local currentTarget = nil

-- Referências aos botões mobile (ajuste conforme seu jogo)
local aimButton = LocalPlayer.PlayerScripts:WaitForChild("Assets")
    .Ui.TouchInputController.BlasterTouchGui.Buttons:WaitForChild("AimButton")
local shootButton = LocalPlayer.PlayerScripts:WaitForChild("Assets")
    .Ui.TouchInputController.BlasterTouchGui.Buttons:WaitForChild("ShootButton")

-- Função para detectar se o jogo está em modo FFA (todos contra todos)
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

-- ======= INTERFACE =======

local gui = Instance.new("ScreenGui")
gui.Name = "MobileAimbotGUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")


local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 220, 0, 240)
panel.Position = UDim2.new(0, 20, 0.5, -120)
panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
panel.BackgroundTransparency = 0.2
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = gui

-- Controle de páginas do menu
local currentPage = 1
local totalPages = 2
local pageObjects = {{}, {}} -- lista de objetos por página

-- Drag da interface
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

-- Função para criar botões toggle com exclusividade entre 2 flags
local function createToggleButton(text, yPos, flagName, exclusiveFlag, page)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 30)
    button.Position = UDim2.new(0, 10, 0, yPos)
    button.Text = text .. ": OFF"
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 16
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Parent = panel
    if page then table.insert(pageObjects[page], button) end

    button.MouseButton1Click:Connect(function()
        _G[flagName] = not _G[flagName]
        -- Exclusividade entre aimbots automático e manual
        if exclusiveFlag and _G[flagName] then
            _G[exclusiveFlag] = false
        end
        button.Text = text .. (_G[flagName] and ": ON" or ": OFF")

        -- Atualiza botão irmão (exclusivo)
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

local function createFOVAdjustButton(text, yPos, delta, page)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.5, -15, 0, 30)
    button.Position = UDim2.new(text == "- FOV" and 0 or 0.5, 10, 0, yPos)
    button.Text = text
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 16
    button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Parent = panel
    if page then table.insert(pageObjects[page], button) end
    button.MouseButton1Click:Connect(function()
        _G.FOV_RADIUS = math.clamp(_G.FOV_RADIUS + delta, 10, 300)
    end)
end

local minimized = false
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 40, 0, 30)
toggleButton.Position = UDim2.new(1, -50, 0, 5)
toggleButton.Text = "🔽"
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 18
toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Parent = panel

toggleButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    toggleButton.Text = minimized and "🔼" or "🔽"

    for _, v in pairs(panel:GetChildren()) do
        if v:IsA("TextButton") and v ~= toggleButton and v.Name ~= "NavLeft" and v.Name ~= "NavRight" then
            v.Visible = not minimized and (not v._page or v._page == currentPage)
        end
    end

    if minimized then
        panel.Size = UDim2.new(0, 60, 0, 40)
        panel.BackgroundTransparency = 1
        toggleButton.Position = UDim2.new(0, 10, 0, 5)
    else
        panel.Size = UDim2.new(0, 220, 0, 240)
        panel.BackgroundTransparency = 0.2
        toggleButton.Position = UDim2.new(1, -50, 0, 5)
    end
end)

-- Setas de navegação
local navLeft = Instance.new("TextButton")
navLeft.Name = "NavLeft"
navLeft.Size = UDim2.new(0, 30, 0, 30)
navLeft.Position = UDim2.new(0, 5, 1, -35)
navLeft.Text = "<"
navLeft.Font = Enum.Font.SourceSansBold
navLeft.TextSize = 18
navLeft.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
navLeft.TextColor3 = Color3.new(1, 1, 1)
navLeft.Parent = panel
navLeft.Visible = false

local navRight = Instance.new("TextButton")
navRight.Name = "NavRight"
navRight.Size = UDim2.new(0, 30, 0, 30)
navRight.Position = UDim2.new(1, -35, 1, -35)
navRight.Text = ">"
navRight.Font = Enum.Font.SourceSansBold
navRight.TextSize = 18
navRight.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
navRight.TextColor3 = Color3.new(1, 1, 1)
navRight.Parent = panel
navRight.Visible = true

local function updatePageVisibility()
    for page, objs in ipairs(pageObjects) do
        for _, obj in ipairs(objs) do
            obj.Visible = (page == currentPage) and not minimized
        end
    end
    navLeft.Visible = currentPage > 1 and not minimized
    navRight.Visible = currentPage < totalPages and not minimized
end

navLeft.MouseButton1Click:Connect(function()
    if currentPage > 1 then
        currentPage = currentPage - 1
        updatePageVisibility()
    end
end)
navRight.MouseButton1Click:Connect(function()
    if currentPage < totalPages then
        currentPage = currentPage + 1
        updatePageVisibility()
    end
end)


-- Página 1: Principal
local aimbotAutoBtn = createToggleButton("Aimbot Auto", 40, "aimbotAutoEnabled", "aimbotManualEnabled", 1)
local aimbotManualBtn = createToggleButton("Aimbot Manual", 75, "aimbotManualEnabled", "aimbotAutoEnabled", 1)
local espEnemiesBtn = createToggleButton("ESP Inimigos", 110, "espEnemiesEnabled", nil, 1)
local espAlliesBtn = createToggleButton("ESP Aliados", 145, "espAlliesEnabled", nil, 1)
local showFOVBtn = createToggleButton("Mostrar FOV", 180, "FOV_VISIBLE", nil, 1)
createFOVAdjustButton("- FOV", 215, -5, 1)
createFOVAdjustButton("+ FOV", 215, 5, 1)


-- Botão para ir para página de mods (centralizado entre -FOV e +FOV)
local outrosBtn = Instance.new("TextButton")
outrosBtn.Size = UDim2.new(0, 100, 0, 30)
outrosBtn.Position = UDim2.new(0.5, -50, 1, -35)
outrosBtn.Text = "Outros >"
outrosBtn.Font = Enum.Font.SourceSansBold
outrosBtn.TextSize = 16
outrosBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
outrosBtn.TextColor3 = Color3.new(1, 1, 1)
outrosBtn.Parent = panel
table.insert(pageObjects[1], outrosBtn)
outrosBtn.MouseButton1Click:Connect(function()
    currentPage = 2
    updatePageVisibility()
end)



-- Página 2: Mods de arma usando createToggleButton
createToggleButton("Infinite Ammo", 40, "modInfiniteAmmo", nil, 2)
createToggleButton("No Recoil", 75, "modNoRecoil", nil, 2)
createToggleButton("No Spread", 110, "modNoSpread", nil, 2)
createToggleButton("Instant Reload", 145, "modInstantReload", nil, 2)
createToggleButton("Fast Shot", 180, "modFastShot", nil, 2)
createToggleButton("Zoom", 215, "modZoom", nil, 2)


-- Botão para voltar ao menu principal (centralizado entre -FOV e +FOV)
local voltarBtn = Instance.new("TextButton")
voltarBtn.Size = UDim2.new(0, 100, 0, 30)
voltarBtn.Position = UDim2.new(0.5, -50, 1, -35)
voltarBtn.Text = "< Voltar"
voltarBtn.Font = Enum.Font.SourceSansBold
voltarBtn.TextSize = 16
voltarBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
voltarBtn.TextColor3 = Color3.new(1, 1, 1)
voltarBtn.Parent = panel
table.insert(pageObjects[2], voltarBtn)
voltarBtn.MouseButton1Click:Connect(function()
    currentPage = 1
    updatePageVisibility()
end)


updatePageVisibility()

-- ======= MODS DE ARMA (APLICAÇÃO) =======
-- Salva o valor original do rateOfFire para restaurar ao desativar Fast Shot
local originalRateOfFire = {}
local function applyWeaponMods(tool)
    if not tool then return end
    -- Infinite Ammo
    if _G.modInfiniteAmmo then
        tool:SetAttribute("_ammo", 200)
        tool:SetAttribute("magazineSize", 200)
    end
    -- No Recoil
    if _G.modNoRecoil then
        tool:SetAttribute("recoilAimReduction", Vector2.new(0,0))
        tool:SetAttribute("recoilMax", Vector2.new(0,0))
        tool:SetAttribute("recoilMin", Vector2.new(0,0))
    end
    -- No Spread
    if _G.modNoSpread then
        tool:SetAttribute("spread", 0)
    end
    -- Instant Reload
    if _G.modInstantReload then
        tool:SetAttribute("reloadTime", 0)
    end
    -- Fast Shot
    if _G.modFastShot then
        if not originalRateOfFire[tool] then
            originalRateOfFire[tool] = tool:GetAttribute("rateOfFire")
        end
        tool:SetAttribute("rateOfFire", 200)
    elseif originalRateOfFire[tool] then
        -- Restaurar valor original ao desativar
        tool:SetAttribute("rateOfFire", originalRateOfFire[tool])
        originalRateOfFire[tool] = nil
    end
    -- Zoom
    if _G.modZoom then
        tool:SetAttribute("zoom", 3)
    end
end


-- Sempre manter infinite ammo em 200 (usando Heartbeat para garantir atualização)
local function maintainInfiniteAmmo()
    RunService.Heartbeat:Connect(function()
        if not _G.modInfiniteAmmo then return end
        local char = LocalPlayer.Character
        if not char then return end
        local tool = char:FindFirstChildWhichIsA("Tool")
        if not tool then return end
        if tool:GetAttribute("_ammo") ~= 200 then
            tool:SetAttribute("_ammo", 200)
        end
        if tool:GetAttribute("magazineSize") ~= 200 then
            tool:SetAttribute("magazineSize", 200)
        end
    end)
end


-- Atualiza mods ao trocar de arma ou respawnar
local function setupToolMods(char)
    local tool
    while not tool and task.wait() do tool = char:FindFirstChildWhichIsA("Tool") end
    if tool then
        applyWeaponMods(tool)
    end
end


LocalPlayer.CharacterAdded:Connect(function(char)
    setupToolMods(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait(0.1)
            applyWeaponMods(child)
        end
    end)
end)

-- Iniciar manutenção de infinite ammo
maintainInfiniteAmmo()


if LocalPlayer.Character then
    setupToolMods(LocalPlayer.Character)
    LocalPlayer.Character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait(0.1)
            applyWeaponMods(child)
        end
    end)
end

-- Atualiza mods ao ativar/desativar botão
for _, btn in ipairs(pageObjects[2]) do
    if btn:IsA("TextButton") then
        btn.MouseButton1Click:Connect(function()
            local char = LocalPlayer.Character
            if char then
                local tool = char:FindFirstChildWhichIsA("Tool")
                if tool then
                    applyWeaponMods(tool)
                end
            end
        end)
    end
end

-- ======= DESENHO DO FOV =======
local fovCircle = Drawing.new("Circle")
fovCircle.Transparency = 0.2
fovCircle.Thickness = 1.5
fovCircle.Filled = false
fovCircle.Color = Color3.new(1, 1, 1)

RunService.RenderStepped:Connect(function()
    fovCircle.Radius = _G.FOV_RADIUS
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    fovCircle.Visible = _G.FOV_VISIBLE
end)

-- ======= ESP + CHAMS =======

local espData = {}
local highlights = {}

local function isAlive(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
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
            return false
        end
    else
        return true
    end
end

local function updateHighlight(player, color)
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
    chams.OutlineColor = Color3.new(0, 0, 0)
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

    local nameTag = Drawing.new("Text")
    nameTag.Size = 14
    nameTag.Center = true
    nameTag.Outline = true
    nameTag.Color = Color3.fromRGB(255, 255, 255)
    nameTag.Visible = false

    local healthBar = Drawing.new("Square")
    healthBar.Filled = true
    healthBar.Visible = false

    espData[player] = {box = box, nameTag = nameTag, healthBar = healthBar}

    RunService.RenderStepped:Connect(function()
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChildOfClass("Humanoid") then
            box.Visible = false
            nameTag.Visible = false
            healthBar.Visible = false
            disableHighlight(player)
            return
        end

        local ffa = isFFA()
        if not ffa then
            if player.Team == LocalPlayer.Team and not _G.espAlliesEnabled then
                box.Visible = false
                nameTag.Visible = false
                healthBar.Visible = false
                disableHighlight(player)
                return
            elseif player.Team ~= LocalPlayer.Team and not _G.espEnemiesEnabled then
                box.Visible = false
                nameTag.Visible = false
                healthBar.Visible = false
                disableHighlight(player)
                return
            end
        else
            if not _G.espEnemiesEnabled then
                box.Visible = false
                nameTag.Visible = false
                healthBar.Visible = false
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

            box.Size = Vector2.new(width, height)
            box.Position = Vector2.new(x, y)

            -- Cor do ESP
            if player == currentTarget then
                box.Color = Color3.fromRGB(255, 255, 0) -- amarelo no alvo
                updateHighlight(player, Color3.fromRGB(255, 255, 0))
            else
                if player.Team == LocalPlayer.Team and _G.espAlliesEnabled then
                    box.Color = Color3.fromRGB(0, 150, 255) -- azul para aliados
                    updateHighlight(player, Color3.fromRGB(0, 150, 255))
                elseif player.Team ~= LocalPlayer.Team and _G.espEnemiesEnabled then
                    box.Color = Color3.fromRGB(255, 0, 0) -- vermelho para inimigos
                    updateHighlight(player, Color3.fromRGB(255, 0, 0))
                else
                    box.Color = Color3.fromRGB(255, 255, 255)
                    disableHighlight(player)
                end
            end

            box.Visible = true
            nameTag.Text = player.Name
            nameTag.Position = Vector2.new(headPos.X, headPos.Y - 20)

            if player == currentTarget then
                nameTag.Color = Color3.fromRGB(255, 255, 0) -- amarelo no alvo
            else
                if player.Team == LocalPlayer.Team and _G.espAlliesEnabled then
                    nameTag.Color = Color3.fromRGB(0, 150, 255) -- azul aliados
                elseif player.Team ~= LocalPlayer.Team and _G.espEnemiesEnabled then
                    nameTag.Color = Color3.fromRGB(255, 255, 255) -- branco inimigos
                else
                    nameTag.Color = Color3.fromRGB(255, 255, 255)
                end
            end

            nameTag.Visible = true

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
            box.Visible = false
            nameTag.Visible = false
            healthBar.Visible = false
            disableHighlight(player)
        end
    end)
end

-- Cria ESP para todos os jogadores
for _, player in pairs(Players:GetPlayers()) do
    createESP(player)
end
Players.PlayerAdded:Connect(createESP)

-- ======= FUNÇÕES AUXILIARES =======

local function isAliveCharacter(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function getClosestVisibleEnemy()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local shortestDistance = _G.FOV_RADIUS
    local closestEnemy = nil
    local ffa = isFFA()

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer or not player.Character then continue end
        if not isAliveCharacter(player.Character) then continue end

        if not ffa then
            if player.Team == LocalPlayer.Team and not _G.espAlliesEnabled then continue end
            if player.Team ~= LocalPlayer.Team and not _G.espEnemiesEnabled then continue end
        else
            if not _G.espEnemiesEnabled then continue end
        end

        local head = player.Character:FindFirstChild("Head")
        if not head then continue end

        local screenPos, visible = Camera:WorldToViewportPoint(head.Position)
        if not visible then continue end

        local distToCenter = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if distToCenter > shortestDistance then continue end

        if not hasLineOfSight(head) then continue end

        shortestDistance = distToCenter
        closestEnemy = player
    end

    return closestEnemy
end

-- ======= CONTROLE DOS BOTÕES =======

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

-- ======= AIMBOT =======

RunService.RenderStepped:Connect(function()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    -- Aimbot Automático
    if _G.aimbotAutoEnabled then
        local target = getClosestVisibleEnemy()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local head = target.Character.Head
            local headPos, visible = Camera:WorldToViewportPoint(head.Position)
            if visible then
                local dist = (Vector2.new(headPos.X, headPos.Y) - center).Magnitude
                if dist <= _G.FOV_RADIUS then
                    currentTarget = target
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
                else
                    currentTarget = nil
                end
            else
                currentTarget = nil
            end
        else
            currentTarget = nil
        end
    end

    -- Aimbot Manual (só mira se estiver mirando e atirando)
    if _G.aimbotManualEnabled and aiming and shooting then
        local target = getClosestVisibleEnemy()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local head = target.Character.Head
            local headPos, visible = Camera:WorldToViewportPoint(head.Position)
            if visible then
                local dist = (Vector2.new(headPos.X, headPos.Y) - center).Magnitude
                if dist <= _G.FOV_RADIUS then
                    currentTarget = target
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
                else
                    currentTarget = nil
                end
            else
                currentTarget = nil
            end
        else
            currentTarget = nil
        end
    elseif not (_G.aimbotManualEnabled and aiming and shooting) and not _G.aimbotAutoEnabled then
        currentTarget = nil
    end
end)

return gui
