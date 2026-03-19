-- 🌌 BACKGROUND STYLE
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)

local gradient = Instance.new("UIGradient", panel)
gradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30,30,35)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15,15,20))
}

Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

-- HEADER
local header = Instance.new("TextLabel", panel)
header.Size = UDim2.new(1,0,0,35)
header.Position = UDim2.new(0,0,0,0)
header.Text = "⚙️ Premium Menu"
header.TextColor3 = Color3.fromRGB(255,255,255)
header.BackgroundTransparency = 1
header.Font = Enum.Font.GothamBold
header.TextSize = 16

-- SEPARADOR
local function createSeparator(y)
    local line = Instance.new("Frame", panel)
    line.Size = UDim2.new(1,-20,0,1)
    line.Position = UDim2.new(0,10,0,y)
    line.BackgroundColor3 = Color3.fromRGB(60,60,70)
end

-- BOTÃO BONITO
local function createNiceButton(text, y, callback)
    local btn = Instance.new("TextButton", panel)
    btn.Size = UDim2.new(1,-20,0,32)
    btn.Position = UDim2.new(0,10,0,y)

    btn.BackgroundColor3 = Color3.fromRGB(40,40,50)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14
    btn.Text = text

    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)

    -- hover
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(55,55,70)
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(40,40,50)
    end)

    btn.MouseButton1Click:Connect(callback)

    return btn
end

-- BOTÃO TOGGLE (verde/vermelho)
local function createToggle(text, y, flag)
    local btn

    local function update()
        local state = _G[flag]
        btn.Text = text .. ": " .. (state and "ON" or "OFF")
        btn.BackgroundColor3 = state and Color3.fromRGB(40,120,60) or Color3.fromRGB(120,40,40)
    end

    btn = createNiceButton("", y, function()
        _G[flag] = not _G[flag]
        update()
    end)

    update()
end

-- 🎯 TARGET SECTION
local section1 = Instance.new("TextLabel", panel)
section1.Position = UDim2.new(0,10,0,40)
section1.Size = UDim2.new(1,-20,0,20)
section1.Text = "🎯 Target"
section1.BackgroundTransparency = 1
section1.TextColor3 = Color3.fromRGB(180,180,200)
section1.Font = Enum.Font.GothamBold
section1.TextSize = 13

local targetBtn = createNiceButton("🎯 Target Config", 65, function()
    partMenu.Visible = not partMenu.Visible
end)

-- 🎯 AIMBOT
local section2 = Instance.new("TextLabel", panel)
section2.Position = UDim2.new(0,10,0,105)
section2.Size = UDim2.new(1,-20,0,20)
section2.Text = "🎯 Aimbot"
section2.BackgroundTransparency = 1
section2.TextColor3 = Color3.fromRGB(180,180,200)
section2.Font = Enum.Font.GothamBold
section2.TextSize = 13

local aimbotBtn = createNiceButton("", 130, function()
    if _G.aimbotMode == "OFF" then
        _G.aimbotMode = "AUTO"
    elseif _G.aimbotMode == "AUTO" then
        _G.aimbotMode = "LEGIT"
    else
        _G.aimbotMode = "OFF"
    end
    aimbotBtn.Text = "Aimbot: " .. _G.aimbotMode
end)

aimbotBtn.Text = "Aimbot: " .. _G.aimbotMode

-- 👁️ ESP
local section3 = Instance.new("TextLabel", panel)
section3.Position = UDim2.new(0,10,0,170)
section3.Size = UDim2.new(1,-20,0,20)
section3.Text = "👁️ Visual"
section3.BackgroundTransparency = 1
section3.TextColor3 = Color3.fromRGB(180,180,200)
section3.Font = Enum.Font.GothamBold
section3.TextSize = 13

createToggle("ESP Inimigos", 195, "espEnemiesEnabled")
createToggle("ESP Aliados", 230, "espAlliesEnabled")
createToggle("Mostrar FOV", 265, "FOV_VISIBLE")
