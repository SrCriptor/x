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


-- Modular GUI with 3 pages, navigation, and draggable/minimizable panel
local gui = Instance.new("ScreenGui")
gui.Name = "MobileAimbotGUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- State for menu
local currentPage = 1
local totalPages = 3
local minimized = false
local panel, navLeft, navRight, minimizeBtn, hitboxPopup, hitboxSelectionBtns, tutorialPage
local dragObj, dragOffset

-- Helper: create draggable frame
local function makeDraggable(frame, dragBtn)
    local dragging = false
    local dragStart, startPos
    local function onInputBegan(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end
    local function onInputChanged(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end
    local function onInputEnded(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end
    (dragBtn or frame).InputBegan:Connect(onInputBegan)
    (dragBtn or frame).InputChanged:Connect(onInputChanged)
    UserInputService.InputEnded:Connect(onInputEnded)
end

-- Main panel
panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 240, 0, 270)
panel.Position = UDim2.new(0, 20, 0.5, -135)
panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
panel.BackgroundTransparency = 0.2
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = gui
makeDraggable(panel)

-- Minimize/maximize button (draggable when minimized)
minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 40, 0, 30)
minimizeBtn.Position = UDim2.new(1, -50, 0, 5)
minimizeBtn.Text = "🔽"
minimizeBtn.Font = Enum.Font.SourceSansBold
minimizeBtn.TextSize = 18
minimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
minimizeBtn.TextColor3 = Color3.new(1, 1, 1)
minimizeBtn.Parent = panel

-- Navigation buttons
navLeft = Instance.new("TextButton")
navLeft.Size = UDim2.new(0, 30, 0, 30)
navLeft.Position = UDim2.new(0, 10, 1, -40)
navLeft.Text = "◀️"
navLeft.Font = Enum.Font.SourceSansBold
navLeft.TextSize = 18
navLeft.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
navLeft.TextColor3 = Color3.new(1, 1, 1)
navLeft.Parent = panel

navRight = Instance.new("TextButton")
navRight.Size = UDim2.new(0, 30, 0, 30)
navRight.Position = UDim2.new(1, -40, 1, -40)
navRight.Text = "▶️"
navRight.Font = Enum.Font.SourceSansBold
navRight.TextSize = 18
navRight.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
navRight.TextColor3 = Color3.new(1, 1, 1)
navRight.Parent = panel

-- Hide navigation on page 3 (tutorial) if needed
local function updateNav()
    navLeft.Visible = currentPage > 1
    navRight.Visible = currentPage < totalPages
end
updateNav()

navLeft.MouseButton1Click:Connect(function()
    if currentPage > 1 then currentPage = currentPage - 1 end
    updateNav()
end)
navRight.MouseButton1Click:Connect(function()
    if currentPage < totalPages then currentPage = currentPage + 1 end
    updateNav()
end)

-- Minimize/maximize logic
local function setMinimized(state)
    minimized = state
    if minimized then
        panel.Size = UDim2.new(0, 60, 0, 40)
        panel.BackgroundTransparency = 1
        minimizeBtn.Text = "🔼"
        minimizeBtn.Position = UDim2.new(0, 10, 0, 5)
        for _, v in pairs(panel:GetChildren()) do
            if v:IsA("TextButton") and v ~= minimizeBtn then v.Visible = false end
        end
    else
        panel.Size = UDim2.new(0, 240, 0, 270)
        panel.BackgroundTransparency = 0.2
        minimizeBtn.Text = "🔽"
        minimizeBtn.Position = UDim2.new(1, -50, 0, 5)
        for _, v in pairs(panel:GetChildren()) do
            if v:IsA("TextButton") and v ~= minimizeBtn then v.Visible = true end
        end
        updateNav()
    end
end
minimizeBtn.MouseButton1Click:Connect(function()
    setMinimized(not minimized)
end)
makeDraggable(panel, minimizeBtn)


-- ======= FUNÇÕES DE MODIFICAÇÃO DE ARMA =======
_G.infiniteAmmoEnabled = false
_G.noRecoilEnabled = false
_G.noSpreadEnabled = false
_G.instantReloadEnabled = false

local function applyWeaponMods(tool)
    if not tool then return end
    if _G.infiniteAmmoEnabled then
        tool:SetAttribute("magazineSize", 200)
        tool:SetAttribute("_ammo", 200)
    end
    if _G.noRecoilEnabled then
        tool:SetAttribute("recoilAimReduction", Vector2.new(0,0))
        tool:SetAttribute("recoilMax", Vector2.new(0,0))
        tool:SetAttribute("recoilMin", Vector2.new(0,0))
    end
    if _G.noSpreadEnabled then
        tool:SetAttribute("spread", 0)
    end
    if _G.instantReloadEnabled then
        tool:SetAttribute("reloadTime", 0)
    end
end

local function resetWeaponMods(tool)
    if not tool then return end
    -- Reset to default or do nothing (depends on your game, here we just set to some defaults)
    if not _G.infiniteAmmoEnabled then
        tool:SetAttribute("magazineSize", 30)
        tool:SetAttribute("_ammo", 30)
    end
    if not _G.noRecoilEnabled then
        tool:SetAttribute("recoilAimReduction", Vector2.new(0.5,0.5))
        tool:SetAttribute("recoilMax", Vector2.new(2,2))
        tool:SetAttribute("recoilMin", Vector2.new(1,1))
    end
    if not _G.noSpreadEnabled then
        tool:SetAttribute("spread", 2)
    end
    if not _G.instantReloadEnabled then
        tool:SetAttribute("reloadTime", 1.5)
    end
end

local function updateWeaponMods()
    local char = LocalPlayer.Character
    if not char then return end
    local tool = char:FindFirstChildWhichIsA("Tool")
    if tool then
        applyWeaponMods(tool)
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait(0.1)
            applyWeaponMods(child)
        end
    end)
    -- Se já tem tool
    local tool = char:FindFirstChildWhichIsA("Tool")
    if tool then applyWeaponMods(tool) end
end)

-- Loop para manter mods ativos
task.spawn(function()
    while true do
        task.wait(0.5)
        updateWeaponMods()
    end
end)

-- ======= BOTÕES DE MODS DE ARMA (PÁGINA 1) =======
local function createModButton(text, yPos, flagName)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 28)
    button.Position = UDim2.new(0, 10, 0, yPos)
    button.Text = text .. ": OFF"
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 15
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Parent = panel
    button.MouseButton1Click:Connect(function()
        _G[flagName] = not _G[flagName]
        button.Text = text .. (_G[flagName] and ": ON" or ": OFF")
        updateWeaponMods()
    end)
    return button
end

-- Ajuste os yPos conforme necessário para não sobrepor outros botões
local modBtnY = 250
local infiniteAmmoBtn = createModButton("Munição Infinita", modBtnY, "infiniteAmmoEnabled")
local noRecoilBtn = createModButton("Sem Recoil", modBtnY+32, "noRecoilEnabled")
local noSpreadBtn = createModButton("Sem Spread", modBtnY+64, "noSpreadEnabled")
local instantReloadBtn = createModButton("Reload Instantâneo", modBtnY+96, "instantReloadEnabled")

-- Função para criar botões toggle com exclusividade entre 2 flags
local function createToggleButton(text, yPos, flagName, exclusiveFlag)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 30)
    button.Position = UDim2.new(0, 10, 0, yPos)
    button.Text = text .. ": OFF"
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 16
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Parent = panel

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

local function createFOVAdjustButton(text, yPos, delta)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.5, -15, 0, 30)
    button.Position = UDim2.new(text == "- FOV" and 0 or 0.5, 10, 0, yPos)
    button.Text = text
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 16
    button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Parent = panel
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
        if v:IsA("TextButton") and v ~= toggleButton then
            v.Visible = not minimized
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

local aimbotAutoBtn = createToggleButton("Aimbot Auto", 40, "aimbotAutoEnabled", "aimbotManualEnabled")
local aimbotManualBtn = createToggleButton("Aimbot Manual", 75, "aimbotManualEnabled", "aimbotAutoEnabled")
local espEnemiesBtn = createToggleButton("ESP Inimigos", 110, "espEnemiesEnabled")
local espAlliesBtn = createToggleButton("ESP Aliados", 145, "espAlliesEnabled")
local showFOVBtn = createToggleButton("Mostrar FOV", 180, "FOV_VISIBLE")
createFOVAdjustButton("- FOV", 215, -5)
createFOVAdjustButton("+ FOV", 215, 5)

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
