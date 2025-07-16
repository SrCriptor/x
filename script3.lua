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
_G.infiniteAmmo = false
_G.autoSpread = false
_G.instantReload = false
_G.fastShot = false

local dragging = false
local dragStart, startPos

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

local function updateButtonText(button, text, flag)
    button.Text = text .. (flag and ": ON" or ": OFF")
end

local function createToggleButton(text, yPos, flagName, exclusiveFlag)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 30)
    button.Position = UDim2.new(0, 10, 0, yPos)
    updateButtonText(button, text, _G[flagName])
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
        updateButtonText(button, text, _G[flagName])
        -- Atualizar botões exclusivos relacionados
        if exclusiveFlag then
            for _, sibling in pairs(panel:GetChildren()) do
                if sibling:IsA("TextButton") and sibling ~= button then
                    local sibText = sibling.Text:lower()
                    local exFlagText = exclusiveFlag:gsub("([A-Z])", " %1"):lower()
                    exFlagText = exFlagText:gsub("^%l", string.upper)
                    if sibText:find(exFlagText) then
                        updateButtonText(sibling, sibling.Text:match("(.+):"), _G[exclusiveFlag])
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
toggleButton.Text = "▼"
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 18
toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Parent = panel

toggleButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    toggleButton.Text = minimized and "▲" or "▼"
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
    updateButtonText(button, text, _G[flagName])
    button.MouseButton1Click:Connect(function()
        _G[flagName] = not _G[flagName]
        updateButtonText(button, text, _G[flagName])
    end)
end

createExtraButton("Infinite Ammo", 40, "infiniteAmmo")
createExtraButton("Auto Spread", 75, "autoSpread")
createExtraButton("Instant Reload", 110, "instantReload")
createExtraButton("Fast Shot", 145, "fastShot")

-- Botões de navegação centralizados
local navButton = Instance.new("TextButton")
navButton.Name = "NavButton"
navButton.Size = UDim2.new(0, 60, 0, 30)
navButton.Position = UDim2.new(0.5, -30, 1, -35)
navButton.Text = "1 / 2"
navButton.Font = Enum.Font.SourceSansBold
navButton.TextSize = 18
navButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
navButton.TextColor3 = Color3.new(1, 1, 1)
navButton.Parent = panel

local navBack = navButton:Clone()
navBack.Text = "2 / 2"
navBack.Parent = extraPage

local onMainPage = true
local function togglePages()
    onMainPage = not onMainPage
    panel.Visible = onMainPage and not minimized
    extraPage.Visible = not onMainPage and not minimized
end

navButton.MouseButton1Click:Connect(togglePages)
navBack.MouseButton1Click:Connect(togglePages)

-- Sincronizar posição, tamanho e visibilidade dos painéis
panel:GetPropertyChangedSignal("Position"):Connect(function()
    extraPage.Position = panel.Position
end)
panel:GetPropertyChangedSignal("Size"):Connect(function()
    extraPage.Size = panel.Size
end)
panel:GetPropertyChangedSignal("Visible"):Connect(function()
    -- Mantém coerência com togglePages e minimized
    extraPage.Visible = not onMainPage and panel.Visible and not minimized
end)

-- Valores base para atributos do Tool
local ltValues = {
    ["_ammo"] = 200,
    ["rateOfFire"] = 100, -- 100ms = 10 tiros por segundo
    ["recoilAimReduction"] = Vector2.new(0, 0),
    ["recoilMax"] = Vector2.new(0, 0),
    ["recoilMin"] = Vector2.new(0, 0),
    ["spread"] = 0,
    ["reloadTime"] = 0,
    ["zoom"] = 3,
    ["magazineSize"] = 200
}

-- Atualização dos atributos do Tool em tempo real conforme flags
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local tool = char:FindFirstChildWhichIsA("Tool")
    if not tool then return end

    -- Infinite Ammo
    if _G.infiniteAmmo then
        tool:SetAttribute("_ammo", ltValues["_ammo"])
        tool:SetAttribute("magazineSize", ltValues["magazineSize"])
    end

    -- Fast Shot
    if _G.fastShot then
        tool:SetAttribute("rateOfFire", ltValues["rateOfFire"])
        tool:SetAttribute("recoilAimReduction", ltValues["recoilAimReduction"])
        tool:SetAttribute("recoilMax", ltValues["recoilMax"])
        tool:SetAttribute("recoilMin", ltValues["recoilMin"])
    else
        -- Se fastShot desligado, resetar para valores padrão
        tool:SetAttribute("rateOfFire", nil)
        tool:SetAttribute("recoilAimReduction", nil)
        tool:SetAttribute("recoilMax", nil)
        tool:SetAttribute("recoilMin", nil)
    end

    -- Auto Spread
    if _G.autoSpread then
        local head = char:FindFirstChild("Head")
        if head then
            local hit = LocalPlayer:GetMouse().Hit
            if hit then
                local dist = (head.Position - hit.Position).Magnitude
                tool:SetAttribute("spread", math.clamp(30 - dist / 5, 0, 30))
            end
        end
        tool:SetAttribute("recoilAimReduction", ltValues["recoilAimReduction"])
        tool:SetAttribute("recoilMax", ltValues["recoilMax"])
        tool:SetAttribute("recoilMin", ltValues["recoilMin"])
    else
        tool:SetAttribute("spread", nil)
    end

    -- Instant Reload
    if _G.instantReload then
        tool:SetAttribute("reloadTime", ltValues["reloadTime"])
    else
        tool:SetAttribute("reloadTime", nil)
    end
end)

-- Display simples da munição no canto inferior direito
local ammoDisplay = Instance.new("TextLabel")
ammoDisplay.Size = UDim2.new(0, 120, 0, 30)
ammoDisplay.Position = UDim2.new(1, -130, 1, -40)
ammoDisplay.BackgroundTransparency = 0.5
ammoDisplay.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ammoDisplay.TextColor3 = Color3.new(1, 1, 1)
ammoDisplay.Font = Enum.Font.SourceSansBold
ammoDisplay.TextSize = 18
ammoDisplay.TextXAlignment = Enum.TextXAlignment.Right
ammoDisplay.Parent = gui

RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then
        ammoDisplay.Text = ""
        return
    end
    local tool = char:FindFirstChildWhichIsA("Tool")
    if not tool then
        ammoDisplay.Text = ""
        return
    end
    
    local maxAmmo = tool:GetAttribute("magazineSize") or ltValues["magazineSize"]
    if _G.infiniteAmmo then
        ammoDisplay.Text = "Ammo: ∞"
    else
        local currentAmmo = tool:GetAttribute("_ammo") or maxAmmo
        if currentAmmo > maxAmmo then currentAmmo = maxAmmo end
        ammoDisplay.Text = string.format("Ammo: %d / %d", currentAmmo, maxAmmo)
    end
end)

return gui
