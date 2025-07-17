local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StylishToggleMenu"
screenGui.Parent = PlayerGui
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 260, 0, 360)
frame.Position = UDim2.new(0, 20, 0, 60)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 18)
uiCorner.Parent = frame

local uiStroke = Instance.new("UIStroke")
uiStroke.Color = Color3.fromRGB(255, 255, 255)
uiStroke.Transparency = 0.7
uiStroke.Thickness = 2
uiStroke.Parent = frame

-- Title bar (drag area)
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundTransparency = 1
titleBar.Parent = frame

local title = Instance.new("TextLabel")
title.Text = "Configurações"
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextYAlignment = Enum.TextYAlignment.Center
title.Parent = titleBar

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 40, 0, 30)
minimizeBtn.Position = UDim2.new(1, -45, 0, 5)
minimizeBtn.Text = "🔽"
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 20
minimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
minimizeBtn.TextColor3 = Color3.new(1, 1, 1)
minimizeBtn.Parent = titleBar
minimizeBtn.AutoButtonColor = true

local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, 0, 1, -40)
contentFrame.Position = UDim2.new(0, 0, 0, 40)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = frame

local minimized = false
local function updateToggleVisibility()
    contentFrame.Visible = not minimized
    minimizeBtn.Text = minimized and "🔼" or "🔽"
    if minimized then
        frame.Size = UDim2.new(0, 260, 0, 40)
    else
        frame.Size = UDim2.new(0, 260, 0, 360)
    end
end

minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    updateToggleVisibility()
end)

-- Dragging pela titleBar e botão minimizar
local dragging = false
local dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                              startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

local function startDrag(input)
    dragging = true
    dragStart = input.Position
    startPos = frame.Position
    input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.End then
            dragging = false
        end
    end)
end

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        startDrag(input)
    end
end)

minimizeBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        startDrag(input)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

minimizeBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

-- Função para criar toggles
local function createToggle(name, parent, posY, defaultValue, callback)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, -20, 0, 40)
    toggleFrame.Position = UDim2.new(0, 10, 0, posY)
    toggleFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    toggleFrame.Parent = parent
    toggleFrame.ClipsDescendants = true

    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 14)
    uiCorner.Parent = toggleFrame

    local label = Instance.new("TextLabel")
    label.Text = name
    label.Font = Enum.Font.Gotham
    label.TextSize = 18
    label.TextColor3 = Color3.fromRGB(230, 230, 230)
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = toggleFrame

    local switch = Instance.new("Frame")
    switch.Size = UDim2.new(0, 50, 0, 26)
    switch.Position = UDim2.new(1, -60, 0, 7)
    switch.BackgroundColor3 = defaultValue and Color3.fromRGB(50, 205, 50) or Color3.fromRGB(100, 100, 100)
    switch.Parent = toggleFrame

    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = switch

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 22, 0, 22)
    circle.Position = defaultValue and UDim2.new(1, -24, 0, 2) or UDim2.new(0, 2, 0, 2)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    circle.Parent = switch

    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = circle

    local toggled = defaultValue

    local function toggleSwitch()
        toggled = not toggled
        if toggled then
            switch.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
            circle:TweenPosition(UDim2.new(1, -24, 0, 2), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
        else
            switch.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            circle:TweenPosition(UDim2.new(0, 2, 0, 2), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
        end
        callback(toggled)
    end

    switch.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            toggleSwitch()
        end
    end)
    label.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            toggleSwitch()
        end
    end)

    return toggleFrame
end

-- Cria toggles e conecta as flags _G
local toggles = {
    {name = "Aimbot Auto", flag = "aimbotAutoEnabled"},
    {name = "ESP Inimigos", flag = "espEnemiesEnabled"},
    {name = "ESP Aliados", flag = "espAlliesEnabled"},
    {name = "Munição Infinita", flag = "infiniteAmmoEnabled"},
    {name = "Sem Recoil", flag = "noRecoilEnabled"},
    {name = "Recarga Instantânea", flag = "instantReloadEnabled"},
}

for i, t in ipairs(toggles) do
    createToggle(t.name, contentFrame, 10 + (i - 1) * 50, _G[t.flag] or false, function(state)
        _G[t.flag] = state
        print(t.name .. " set to " .. tostring(state))
    end)
end
