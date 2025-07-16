-- GUI e Sistema Aimbot + ESP + Página Extra com Infinite Ammo, Auto Spread, etc.

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
_G.infiniteAmmo = true
_G.autoSpread = true
_G.instantReload = true
_G.fastShot = true

local shooting = false
local aiming = false
local dragging = false
local dragStart, startPos
local currentTarget = nil

local aimButton = LocalPlayer.PlayerScripts:WaitForChild("Assets").Ui.TouchInputController.BlasterTouchGui.Buttons:WaitForChild("AimButton")
local shootButton = LocalPlayer.PlayerScripts:WaitForChild("Assets").Ui.TouchInputController.BlasterTouchGui.Buttons:WaitForChild("ShootButton")

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
    button.Text = text .. ": OFF"
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 16
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Parent = panel

    button.MouseButton1Click:Connect(function()
        _G[flagName] = not _G[flagName]
        if exclusiveFlag and _G[flagName] then _G[exclusiveFlag] = false end
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
toggleButton.Text = "\ud83d\udd3d"
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 18
toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Parent = panel

toggleButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    toggleButton.Text = minimized and "\ud83d\udd3c" or "\ud83d\udd3d"
    for _, v in pairs(panel:GetChildren()) do
        if v:IsA("TextButton") and v ~= toggleButton and v.Name ~= "NavButton" then
            v.Visible = not minimized
        end
    end
    panel.Size = minimized and UDim2.new(0, 60, 0, 40) or UDim2.new(0, 220, 0, 240)
    panel.BackgroundTransparency = minimized and 1 or 0.2
    toggleButton.Position = minimized and UDim2.new(0, 10, 0, 5) or UDim2.new(1, -50, 0, 5)
end)

-- Botões página 1
local aimbotAutoBtn = createToggleButton("Aimbot Auto", 40, "aimbotAutoEnabled", "aimbotManualEnabled")
local aimbotManualBtn = createToggleButton("Aimbot Manual", 75, "aimbotManualEnabled", "aimbotAutoEnabled")
local espEnemiesBtn = createToggleButton("ESP Inimigos", 110, "espEnemiesEnabled")
local espAlliesBtn = createToggleButton("ESP Aliados", 145, "espAlliesEnabled")
local showFOVBtn = createToggleButton("Mostrar FOV", 180, "FOV_VISIBLE")
createFOVAdjustButton("- FOV", 215, -5)
createFOVAdjustButton("+ FOV", 215, 5)

-- Página 2 (extra)
local extraPage = panel:Clone()
extraPage.Parent = gui
extraPage.Visible = false
for _, child in pairs(extraPage:GetChildren()) do
    if child:IsA("TextButton") and child.Name ~= "NavButton" then child:Destroy() end
end

local function createExtraButton(text, yPos, flagName)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 30)
    button.Position = UDim2.new(0, 10, 0, yPos)
    button.Text = text .. ": OFF"
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 16
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Parent = extraPage
    button.MouseButton1Click:Connect(function()
        _G[flagName] = not _G[flagName]
        button.Text = text .. (_G[flagName] and ": ON" or ": OFF")
    end)
end

createExtraButton("Infinite Ammo", 40, "infiniteAmmo")
createExtraButton("Auto Spread", 75, "autoSpread")
createExtraButton("Instant Reload", 110, "instantReload")
createExtraButton("Fast Shot", 145, "fastShot")

-- Botão único de navegação centralizado
local navButton = Instance.new("TextButton")
navButton.Name = "NavButton"
navButton.Size = UDim2.new(0, 60, 0, 30)
navButton.Position = UDim2.new(0.5, -30, 1, -35)
navButton.Text = "▶️"
navButton.Font = Enum.Font.SourceSansBold
navButton.TextSize = 18
navButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
navButton.TextColor3 = Color3.new(1, 1, 1)
navButton.Parent = panel

local navBack = navButton:Clone()
navBack.Text = "◀️"
navBack.Parent = extraPage

local onMainPage = true
local function togglePages()
    onMainPage = not onMainPage
    panel.Visible = onMainPage
    extraPage.Visible = not onMainPage
end

navButton.MouseButton1Click:Connect(togglePages)
navBack.MouseButton1Click:Connect(togglePages)

panel:GetPropertyChangedSignal("Position"):Connect(function()
    extraPage.Position = panel.Position
end)

panel:GetPropertyChangedSignal("Size"):Connect(function()
    extraPage.Size = panel.Size
end)

panel:GetPropertyChangedSignal("Visible"):Connect(function()
    extraPage.Visible = not onMainPage and panel.Visible
end)

-- LT Settings aplicadas via flags
local ltValues = {
    ["_ammo"] = 200,
    ["rateOfFire"] = 200,
    ["recoilAimReduction"] = Vector2.new(0, 0),
    ["recoilMax"] = Vector2.new(0, 0),
    ["recoilMin"] = Vector2.new(0, 0),
    ["spread"] = 0,
    ["reloadTime"] = 0,
    ["zoom"] = 3,
    ["magazineSize"] = 200
}

LocalPlayer.CharacterAdded:Connect(function(char)
    local tool
    while not tool and task.wait() do tool = char:FindFirstChildWhichIsA("Tool") end
    if tool then
        for i, v in ltValues do
            if (_G.infiniteAmmo and i == "_ammo") or
               (_G.fastShot and i == "rateOfFire") or
               ((_G.autoSpread or _G.fastShot) and (i == "recoilAimReduction" or i == "recoilMax" or i == "recoilMin")) or
               (_G.autoSpread and i == "spread") or
               (_G.instantReload and i == "reloadTime") or
               (_G.infiniteAmmo and i == "magazineSize") then
                tool:SetAttribute(i, v)
            end
        end
    end
end)

-- Auto Spread Dinâmico
RunService.Heartbeat:Connect(function()
    if not _G.autoSpread then return end
    local char, hit = LocalPlayer.Character, LocalPlayer:GetMouse().Hit
    if char and hit then
        local tool, hd = char:FindFirstChildWhichIsA("Tool"), char:FindFirstChild("Head")
        if tool and hd then
            tool:SetAttribute("spread", 30 - (hd.Position - hit.Position).Magnitude / 5)
        end
    end
end)

return gui
