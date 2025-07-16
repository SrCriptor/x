--[[
Mobile Aimbot GUI
- Painel arrastável: pela borda (maximizado) ou pelo toggle button (minimizado)
- Botão ⚙️ para trocar tamanho do menu entre 3 alturas fixas
- Toggle para minimizar/maximizar
- Botões toggle para opções do aimbot, esp, etc
- Círculo FOV e ESP visual
- Aimbot automático simplificado
--]]

-- Serviços principais
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Flags globais
_G.FOV_RADIUS = 65
_G.FOV_VISIBLE = true
_G.aimbotAutoEnabled = false
_G.aimbotManualEnabled = false
_G.espEnemiesEnabled = true
_G.espAlliesEnabled = false
_G.instareload = false
_G.noRecol = false
_G.infiniteAmmo = false

local shooting = false
local aiming = false
local dragging = false
local dragStart, startPos
local currentTarget = nil

-- Botões mobile (ajuste se necessário)
local aimButton = LocalPlayer.PlayerScripts:WaitForChild("Assets")
    .Ui.TouchInputController.BlasterTouchGui.Buttons:WaitForChild("AimButton")
local shootButton = LocalPlayer.PlayerScripts:WaitForChild("Assets")
    .Ui.TouchInputController.BlasterTouchGui.Buttons:WaitForChild("ShootButton")

-- Função para verificar modo FFA
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

-- Criando GUI
local gui = Instance.new("ScreenGui")
gui.Name = "MobileAimbotGUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 220, 0, 180)
panel.Position = UDim2.new(0, 20, 0.5, -90)
panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
panel.BackgroundTransparency = 0.2
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = gui

-- Estado menu
local minimized = false
local scaleIndex = 2
local scales = {120, 180, 240}

-- BOTÃO minimizar/maximizar (setinha)
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
        if v:IsA("TextButton") and v ~= toggleButton and v ~= gearButton then
            v.Visible = not minimized
        end
    end
    if minimized then
        panel.Size = UDim2.new(0, 60, 0, 40)
        panel.BackgroundTransparency = 1
        toggleButton.Position = UDim2.new(0, 10, 0, 5)
        gearButton.Visible = false
    else
        panel.BackgroundTransparency = 0.2
        toggleButton.Position = UDim2.new(1, -50, 0, 5)
        gearButton.Visible = true
        panel.Size = UDim2.new(0, 220, 0, scales[scaleIndex])
    end
end)

-- BOTÃO engrenagem para alternar tamanhos predefinidos do painel
local gearButton = Instance.new("TextButton")
gearButton.Size = UDim2.new(0, 30, 0, 30)
gearButton.Position = UDim2.new(1, -90, 0, 5)
gearButton.Text = "⚙️"
gearButton.Font = Enum.Font.SourceSansBold
gearButton.TextSize = 18
gearButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
gearButton.TextColor3 = Color3.new(1, 1, 1)
gearButton.Parent = panel

gearButton.MouseButton1Click:Connect(function()
    scaleIndex = scaleIndex + 1
    if scaleIndex > #scales then
        scaleIndex = 1
    end
    panel.Size = UDim2.new(0, 220, 0, scales[scaleIndex])
end)

-- ARRASTAR painel segurando a BORDAS (10px) quando maximizado
local draggingBorder = false
local borderDragStart, borderStartPos
local borderSize = 10 -- margem das bordas para detectar drag

panel.InputBegan:Connect(function(input)
    if minimized then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local pos = input.Position
        local absPos = panel.AbsolutePosition
        local absSize = panel.AbsoluteSize

        local xRel = pos.X - absPos.X
        local yRel = pos.Y - absPos.Y

        if xRel <= borderSize or xRel >= absSize.X - borderSize or yRel <= borderSize or yRel >= absSize.Y - borderSize then
            draggingBorder = true
            borderDragStart = pos
            borderStartPos = panel.Position
            input:Capture()
        end
    end
end)

panel.InputChanged:Connect(function(input)
    if draggingBorder and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - borderDragStart
        panel.Position = UDim2.new(borderStartPos.X.Scale, borderStartPos.X.Offset + delta.X, borderStartPos.Y.Scale, borderStartPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingBorder = false
    end
end)

-- ARRASTAR painel segurando o BOTÃO toggle (setinha) quando minimizado
local draggingToggle = false
local toggleDragStart, toggleStartPos
local dragThreshold = 10 -- distância mínima para iniciar drag
local draggingConfirmed = false

toggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingConfirmed = false
        toggleDragStart = input.Position
        toggleStartPos = panel.Position
        input:Capture()
    end
end)

toggleButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if not draggingConfirmed then
            local delta = input.Position - toggleDragStart
            if delta.Magnitude > dragThreshold then
                draggingConfirmed = true
                draggingToggle = true
            end
        end
        if draggingToggle then
            local delta = input.Position - toggleDragStart
            panel.Position = UDim2.new(toggleStartPos.X.Scale, toggleStartPos.X.Offset + delta.X, toggleStartPos.Y.Scale, toggleStartPos.Y.Offset + delta.Y)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingToggle = false
        draggingConfirmed = false
    end
end)

-- Função para aplicar mods na arma
local function applyWeaponMods(tool)
    if not tool then return end

    if _G.instareload then
        tool:SetAttribute("reloadTime", 0)
    else
        tool:SetAttribute("reloadTime", 1)
    end

    if _G.noRecol then
        tool:SetAttribute("recoilAimReduction", Vector2.new(0, 0))
        tool:SetAttribute("recoilMax", Vector2.new(0, 0))
        tool:SetAttribute("recoilMin", Vector2.new(0, 0))
    else
        tool:SetAttribute("recoilAimReduction", Vector2.new(1, 1))
        tool:SetAttribute("recoilMax", Vector2.new(1, 1))
        tool:SetAttribute("recoilMin", Vector2.new(1, 1))
    end

    if _G.infiniteAmmo then
        tool:SetAttribute("_ammo", math.huge)
        tool:SetAttribute("magazineSize", math.huge)
    else
        tool:SetAttribute("_ammo", 200)
        tool:SetAttribute("magazineSize", 200)
    end
end

-- Botão toggle genérico
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
        if exclusiveFlag and _G[flagName] then
            _G[exclusiveFlag] = false
        end
        button.Text = text .. (_G[flagName] and ": ON" or ": OFF")

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

        if flagName == "instareload" or flagName == "noRecol" or flagName == "infiniteAmmo" then
            local char = LocalPlayer.Character
            if char then
                local tool = char:FindFirstChildWhichIsA("Tool")
                if tool then
                    applyWeaponMods(tool)
                end
            end
        end
    end)
    return button
end

-- Botões para ajustar FOV
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

-- Criação dos botões toggle
local aimbotAutoBtn = createToggleButton("Aimbot Auto", 40, "aimbotAutoEnabled", "aimbotManualEnabled")
local aimbotManualBtn = createToggleButton("Aimbot Manual", 75, "aimbotManualEnabled", "aimbotAutoEnabled")
local espEnemiesBtn = createToggleButton("ESP Inimigos", 110, "espEnemiesEnabled")
local espAlliesBtn = createToggleButton("ESP Aliados", 145, "espAlliesEnabled")
local instantReloadBtn = createToggleButton("Instant Reload", 180, "instareload")
local noRecoilBtn = createToggleButton("No Recoil", 215, "noRecol")
local infiniteAmmoBtn = createToggleButton("Infinite Ammo", 250, "infiniteAmmo")
local showFOVBtn = createToggleButton("Mostrar FOV", 285, "FOV_VISIBLE")
createFOVAdjustButton("- FOV", 320, -5)
createFOVAdjustButton("+ FOV", 320, 5)

-- Forçar exibição visual fixa da munição para parecer 200
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end

    local tool = char:FindFirstChildWhichIsA("Tool")
    if not tool then return end

    if _G.infiniteAmmo then
        local hud = tool:FindFirstChild("AmmoDisplay")
        if hud and hud:IsA("TextLabel") then
            hud.Text = "200"
        end
    end
end)

-- Círculo do FOV
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

-- Funções do ESP

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
        local humanoid = char:FindFirstChildOfClass("Humanoid")

        local topLeftPos, topLeftVis = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(-1, 3, 0))
        local bottomRightPos, bottomRightVis = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(1, 0, 0))
        if not topLeftVis or not bottomRightVis then
            box.Visible = false
            nameTag.Visible = false
            healthBar.Visible = false
            disableHighlight(player)
            return
        end

        local boxSize = Vector2.new(bottomRightPos.X - topLeftPos.X, bottomRightPos.Y - topLeftPos.Y)
        box.Size = boxSize
        box.Position = Vector2.new(topLeftPos.X, topLeftPos.Y)
        box.Color = player.Team == LocalPlayer.Team and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
        box.Visible = true

        nameTag.Text = player.Name
        nameTag.Position = Vector2.new(topLeftPos.X + boxSize.X / 2, topLeftPos.Y - 15)
        nameTag.Visible = true

        local healthRatio = humanoid.Health / humanoid.MaxHealth
        healthBar.Size = Vector2.new(boxSize.X * healthRatio, 5)
        healthBar.Position = Vector2.new(topLeftPos.X, bottomRightPos.Y + 2)
        healthBar.Color = Color3.fromRGB(0, 255, 0)
        healthBar.Visible = true

        if player.Team == LocalPlayer.Team then
            if _G.espAlliesEnabled then
                updateHighlight(player, Color3.fromRGB(0, 255, 0))
            else
                disableHighlight(player)
            end
        else
            if _G.espEnemiesEnabled then
                updateHighlight(player, Color3.fromRGB(255, 0, 0))
            else
                disableHighlight(player)
            end
        end
    end)
end

for _, player in pairs(Players:GetPlayers()) do
    createESP(player)
end

Players.PlayerAdded:Connect(function(player)
    createESP(player)
end)

Players.PlayerRemoving:Connect(function(player)
    local data = espData[player]
    if data then
        data.box:Remove()
        data.nameTag:Remove()
        data.healthBar:Remove()
        espData[player] = nil
    end
    local hl = highlights[player]
    if hl then
        hl:Destroy()
        highlights[player] = nil
    end
end)

-- Função de aimbot (simplificada)
local function getClosestTarget()
    local closestDist = math.huge
    local target = nil

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and isAlive(player.Character) then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp and hasLineOfSight(hrp) then
                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if dist < _G.FOV_RADIUS and dist < closestDist then
                        closestDist = dist
                        target = player
                    end
                end
            end
        end
    end

    return target
end

RunService.RenderStepped:Connect(function()
    if _G.aimbotAutoEnabled then
        currentTarget = getClosestTarget()
        if currentTarget and not shooting then
            shooting = true
            -- Código para disparar depende do jogo
            wait(0.1)
            shooting = false
        end
    end
end)
