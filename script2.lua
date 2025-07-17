-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Flags globais padrões
_G.FOV_RADIUS = 65
_G.FOV_VISIBLE = true
_G.aimbotAutoEnabled = false
_G.aimbotManualEnabled = false
_G.espEnemiesEnabled = true
_G.espAlliesEnabled = false
_G.noRecoilEnabled = true
_G.infiniteAmmoEnabled = true
_G.instantReloadEnabled = true

local currentTarget = nil
local aiming = false
local shooting = false
local dragging = false
local dragStart, startPos

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "MobileAimbotGUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 220, 0, 320)
panel.Position = UDim2.new(0, 20, 0.5, -160)
panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
panel.BackgroundTransparency = 0.2
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = gui

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 40, 0, 30)
toggleButton.Position = UDim2.new(0, 250, 0.5, -160)
toggleButton.Text = "🔽"
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 20
toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Parent = gui

local minimized = false
local function updateToggleState()
    panel.Visible = not minimized
    toggleButton.Text = minimized and "🔼" or "🔽"
end

toggleButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    updateToggleState()
end)

local function setupDrag(guiElement)
    guiElement.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = guiElement.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    guiElement.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            guiElement.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
setupDrag(panel)
setupDrag(toggleButton)

local function createToggleButton(text, yPos, flagName, exclusiveFlag)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 30)
    button.Position = UDim2.new(0, 10, 0, yPos)
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 16
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Parent = panel
    button.Text = text .. (_G[flagName] and ": ON" or ": OFF")

    button.MouseButton1Click:Connect(function()
        _G[flagName] = not _G[flagName]
        if exclusiveFlag and _G[flagName] then
            _G[exclusiveFlag] = false
        end
        button.Text = text .. (_G[flagName] and ": ON" or ": OFF")

        if exclusiveFlag then
            for _, sibling in pairs(panel:GetChildren()) do
                if sibling:IsA("TextButton") and sibling ~= button then
                    if sibling.Text:lower():find(exclusiveFlag:lower()) then
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

local aimbotAutoBtn = createToggleButton("Aimbot Auto", 145, "aimbotAutoEnabled", "aimbotManualEnabled")
local aimbotLegitBtn = createToggleButton("Aimbot Legit", 180, "aimbotManualEnabled", "aimbotAutoEnabled")
local espEnemiesBtn = createToggleButton("ESP Inimigos", 215, "espEnemiesEnabled")
local espAlliesBtn = createToggleButton("ESP Aliados", 250, "espAlliesEnabled")
local noRecoilBtn = createToggleButton("No Recoil", 40, "noRecoilEnabled")
local infiniteAmmoBtn = createToggleButton("Infinite Ammo", 75, "infiniteAmmoEnabled")
local instantReloadBtn = createToggleButton("Instant Reload", 110, "instantReloadEnabled")
local showFOVBtn = createToggleButton("Mostrar FOV", 285, "FOV_VISIBLE")
createFOVAdjustButton("- FOV", 320, -5)
createFOVAdjustButton("+ FOV", 320, 5)

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

-- 💡 ESP CORRIGIDO AQUI
local highlights = {}

local function getCharacterPart(character)
    return character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart") or character:FindFirstChildWhichIsA("BasePart")
end

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

local function disableOtherAimbot(activeFlag)
    if activeFlag == "aimbotAutoEnabled" then
        _G.aimbotManualEnabled = false
        aimbotLegitBtn.Text = "Aimbot Legit: OFF"
    elseif activeFlag == "aimbotManualEnabled" then
        _G.aimbotAutoEnabled = false
        aimbotAutoBtn.Text = "Aimbot Auto: OFF"
    end
end

aimbotAutoBtn.MouseButton1Click:Connect(function()
    if _G.aimbotAutoEnabled then disableOtherAimbot("aimbotAutoEnabled") end
end)
aimbotLegitBtn.MouseButton1Click:Connect(function()
    if _G.aimbotManualEnabled then disableOtherAimbot("aimbotManualEnabled") end
end)

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

local function shootGun(tool)
    if not tool then return end
    for i = 1, 5 do
        task.wait(0.04)
    end
end

RunService.RenderStepped:Connect(function()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    if _G.aimbotAutoEnabled or (_G.aimbotManualEnabled and aiming and shooting) then
        local target = getClosestVisibleEnemy()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local head = target.Character.Head
            local headPos, visible = Camera:WorldToViewportPoint(head.Position)
            if visible and (Vector2.new(headPos.X, headPos.Y) - center).Magnitude <= _G.FOV_RADIUS and hasLineOfSight(head) then
                currentTarget = target
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
                local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
                if tool then
                    shootGun(tool)
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
end

local function onCharacterAdded(character)
    local tool
    repeat
        tool = character:FindFirstChildWhichIsA("Tool")
        task.wait()
    until tool
    applyGunAttributes(tool)
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
if LocalPlayer.Character then onCharacterAdded(LocalPlayer.Character) end
LocalPlayer.CharacterRemoving:Connect(function()
    currentTarget = nil
end)
