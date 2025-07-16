local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Configurações globais (flags) com extras ativados
_G.FOV_RADIUS = 65
_G.FOV_VISIBLE = true
_G.aimbotAutoEnabled = false
_G.aimbotManualEnabled = false
_G.espEnemiesEnabled = true
_G.espAlliesEnabled = false

-- Novas flags ativadas para teste
_G.infiniteAmmo = true
_G.instantReload = true
_G.noRecoil = true
_G.noSpread = true
_G.fastShoot = false

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
panel.Size = UDim2.new(0, 220, 0, 400)
panel.Position = UDim2.new(0, 20, 0.5, -200)
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

local function createToggleButton(text, yPos, flagName, exclusiveFlag)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 30)
    button.Position = UDim2.new(0, 10, 0, yPos)
    button.Text = text .. ": " .. (_G[flagName] and "ON" or "OFF")
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
        button.Text = text .. ": " .. (_G[flagName] and "ON" or "OFF")
        if exclusiveFlag then
            for _, sibling in pairs(panel:GetChildren()) do
                if sibling:IsA("TextButton") and sibling ~= button then
                    local sibText = sibling.Text:lower()
                    local exText = exclusiveFlag:gsub("([A-Z])", " %1"):lower()
                    exText = exText:gsub("^%l", string.upper)
                    if sibText:find(exText) then
                        sibling.Text = sibling.Text:sub(1, sibling.Text:find(":")) .. (_G[exclusiveFlag] and "ON" or "OFF")
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
        panel.Size = UDim2.new(0, 220, 0, 400)
        panel.BackgroundTransparency = 0.2
        toggleButton.Position = UDim2.new(1, -50, 0, 5)
    end
end)

-- Botões de toggles principais
local aimbotAutoBtn = createToggleButton("Aimbot Auto", 40, "aimbotAutoEnabled", "aimbotManualEnabled")
local aimbotManualBtn = createToggleButton("Aimbot Manual", 75, "aimbotManualEnabled", "aimbotAutoEnabled")
local espEnemiesBtn = createToggleButton("ESP Inimigos", 110, "espEnemiesEnabled")
local espAlliesBtn = createToggleButton("ESP Aliados", 145, "espAlliesEnabled")
local showFOVBtn = createToggleButton("Mostrar FOV", 180, "FOV_VISIBLE")

-- Botões extras para armas
local infiniteAmmoBtn = createToggleButton("Infinite Ammo", 215, "infiniteAmmo")
local instantReloadBtn = createToggleButton("Instant Reload", 250, "instantReload")
local noRecoilBtn = createToggleButton("No Recoil", 285, "noRecoil")
local noSpreadBtn = createToggleButton("No Spread", 320, "noSpread")
local fastShootBtn = createToggleButton("Fast Shoot", 355, "fastShoot")

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

for _, player in pairs(Players:GetPlayers()) do
    createESP(player)
end
Players.PlayerAdded:Connect(createESP)

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
