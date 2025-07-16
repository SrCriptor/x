-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Globals padrão
_G.aimbotAutoEnabled = _G.aimbotAutoEnabled or false
_G.aimbotLegitEnabled = _G.aimbotLegitEnabled or false
_G.modInfiniteAmmo = _G.modInfiniteAmmo or false
_G.modNoRecoil = _G.modNoRecoil or false
_G.modInstantReload = _G.modInstantReload or false
_G.hitboxSelection = _G.hitboxSelection or {
    Head = true, Torso = false, LeftArm = false, RightArm = false, LeftLeg = false, RightLeg = false
}
_G.FOV_RADIUS = _G.FOV_RADIUS or 200
_G.lt = _G.lt or {
    rateOfFire = 200,
    spread = 0,
    zoom = 3,
}

-- Criar ScreenGui
local gui = Instance.new("ScreenGui")
gui.Name = "RayfieldMenu"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Função pra criar texto estilizado
local function createLabel(text, parent, size, pos)
    local lbl = Instance.new("TextLabel")
    lbl.Size = size or UDim2.new(1, 0, 0, 25)
    lbl.Position = pos or UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(230, 230, 230)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 16
    lbl.Text = text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent
    return lbl
end

-- Função para criar botão toggle (botão que muda ON/OFF)
local function createToggleButton(text, parent, pos, defaultState, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 220, 0, 30)
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Text = text .. ": OFF"
    btn.AutoButtonColor = false
    btn.Parent = parent

    local active = defaultState or false
    local function update()
        btn.Text = text .. ": " .. (active and "ON" or "OFF")
        btn.BackgroundColor3 = active and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
    end

    btn.MouseButton1Click:Connect(function()
        active = not active
        update()
        if callback then
            callback(active)
        end
    end)

    update()
    return btn
end

-- Função para criar slider (barra de ajuste)
local function createSlider(text, parent, pos, minVal, maxVal, step, defaultVal, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 220, 0, 50)
    container.Position = pos
    container.BackgroundTransparency = 1
    container.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(230, 230, 230)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.Text = text .. ": " .. tostring(defaultVal)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, 0, 0, 12)
    sliderBg.Position = UDim2.new(0, 0, 0, 30)
    sliderBg.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = container

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    fill.Parent = sliderBg

    local dragging = false

    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)

    sliderBg.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local relativePos = math.clamp(input.Position.X - sliderBg.AbsolutePosition.X, 0, sliderBg.AbsoluteSize.X)
            local value = minVal + (relativePos / sliderBg.AbsoluteSize.X) * (maxVal - minVal)
            value = math.floor(value / step + 0.5) * step
            label.Text = text .. ": " .. tostring(value)
            fill.Size = UDim2.new((value - minVal) / (maxVal - minVal), 0, 1, 0)
            if callback then
                callback(value)
            end
        end
    end)

    return container
end

-- Frame principal do menu
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 260, 0, 400)
mainFrame.Position = UDim2.new(0, 20, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = gui

-- Título do menu
local titleLabel = Instance.new("TextLabel")
titleLabel.Text = "Raycast Menu"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 20
titleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
titleLabel.BackgroundTransparency = 1
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.Parent = mainFrame

-- Container para botões e sliders
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, 0, 1, -30)
contentFrame.Position = UDim2.new(0, 0, 0, 30)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

-- Tab Buttons
local tabs = {"Aimbot", "Hitbox", "Mods"}
local tabFrames = {}
local tabButtonsFrame = Instance.new("Frame")
tabButtonsFrame.Size = UDim2.new(1, 0, 0, 30)
tabButtonsFrame.Position = UDim2.new(0, 0, 0, 0)
tabButtonsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
tabButtonsFrame.Parent = contentFrame

local function createTabButton(name, idx)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1/#tabs, -4, 1, 0)
    btn.Position = UDim2.new((idx-1)/#tabs, 2, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 15
    btn.TextColor3 = Color3.new(1,1,1)
    btn.AutoButtonColor = false
    btn.Parent = tabButtonsFrame
    return btn
end

for i, tabName in ipairs(tabs) do
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, -30)
    frame.Position = UDim2.new(0, 0, 0, 30)
    frame.BackgroundTransparency = 1
    frame.Visible = i == 1 -- Só a primeira aba fica visível inicialmente
    frame.Parent = contentFrame
    tabFrames[tabName] = frame
end

-- Lógica para trocar abas
for i, btn in ipairs(tabButtonsFrame:GetChildren()) do
    if btn:IsA("TextButton") then
        btn.MouseButton1Click:Connect(function()
            for _, frame in pairs(tabFrames) do
                frame.Visible = false
            end
            tabFrames[btn.Text].Visible = true
            for _, b in pairs(tabButtonsFrame:GetChildren()) do
                if b:IsA("TextButton") then
                    b.BackgroundColor3 = Color3.fromRGB(50,50,50)
                end
            end
            btn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        end)
    end
end

-- Criar os botões e sliders da aba Aimbot
local aimbotFrame = tabFrames["Aimbot"]
local aimbotAutoToggle = createToggleButton("Aimbot Automático", aimbotFrame, UDim2.new(0, 20, 0, 20), _G.aimbotAutoEnabled, function(val) _G.aimbotAutoEnabled = val if val then _G.aimbotLegitEnabled = false end end)
local aimbotLegitToggle = createToggleButton("Aimbot Legit", aimbotFrame, UDim2.new(0, 20, 0, 70), _G.aimbotLegitEnabled, function(val) _G.aimbotLegitEnabled = val if val then _G.aimbotAutoEnabled = false end end)

-- Criar botão para abrir popup hitbox
local hitboxPopupBtn = createToggleButton("Selecionar Hitbox", tabFrames["Hitbox"], UDim2.new(0, 20, 0, 20), false)

-- Popup para seleção de hitbox
local hitboxPopup = Instance.new("Frame")
hitboxPopup.Size = UDim2.new(0, 280, 0, 360)
hitboxPopup.Position = UDim2.new(0.5, -140, 0.5, -180)
hitboxPopup.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
hitboxPopup.BorderSizePixel = 0
hitboxPopup.Visible = false
hitboxPopup.Parent = gui

local popupTitle = createLabel("Selecionar Hitbox", hitboxPopup, UDim2.new(1, 0, 0, 30), UDim2.new(0, 10, 0, 10))

local closePopupBtn = Instance.new("TextButton")
closePopupBtn.Text = "Fechar"
closePopupBtn.Font = Enum.Font.GothamBold
closePopupBtn.TextSize = 16
closePopupBtn.TextColor3 = Color3.new(1,1,1)
closePopupBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
closePopupBtn.Size = UDim2.new(0, 70, 0, 30)
closePopupBtn.Position = UDim2.new(1, -80, 0, 10)
closePopupBtn.Parent = hitboxPopup

closePopupBtn.MouseButton1Click:Connect(function()
    hitboxPopup.Visible = false
    hitboxPopupBtn.Text = "Selecionar Hitbox: OFF"
    hitboxPopupBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
end)

hitboxPopupBtn.MouseButton1Click:Connect(function()
    hitboxPopup.Visible = not hitboxPopup.Visible
    if hitboxPopup.Visible then
        hitboxPopupBtn.Text = "Selecionar Hitbox: ON"
        hitboxPopupBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    else
        hitboxPopupBtn.Text = "Selecionar Hitbox: OFF"
        hitboxPopupBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end
end)

local hitboxParts = {
    {Name = "Head", Position = UDim2.new(0.45, 0, 0.05, 0), Size = UDim2.new(0, 50, 0, 50)},
    {Name = "Torso", Position = UDim2.new(0.4, 0, 0.3, 0), Size = UDim2.new(0, 60, 0, 80)},
    {Name = "LeftArm", Position = UDim2.new(0.2, 0, 0.3, 0), Size = UDim2.new(0, 40, 0, 80)},
    {Name = "RightArm", Position = UDim2.new(0.75, 0, 0.3, 0), Size = UDim2.new(0, 40, 0, 80)},
    {Name = "LeftLeg", Position = UDim2.new(0.4, 0, 0.75, 0), Size = UDim2.new(0, 40, 0, 80)},
    {Name = "RightLeg", Position = UDim2.new(0.55, 0, 0.75, 0), Size = UDim2.new(0, 40, 0, 80)},
}

for _, part in ipairs(hitboxParts) do
    local btn = Instance.new("TextButton")
    btn.Name = part.Name
    btn.Text = ""
    btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    btn.BackgroundTransparency = 0.5
    btn.Size = part.Size
    btn.Position = part.Position
    btn.Parent = hitboxPopup

    local border = Instance.new("UIStroke")
    border.Thickness = 3
    border.Color = _G.hitboxSelection[part.Name] and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(100, 100, 100)
    border.Parent = btn

    btn.MouseButton1Click:Connect(function()
        _G.hitboxSelection[part.Name] = not _G.hitboxSelection[part.Name]
        border.Color = _G.hitboxSelection[part.Name] and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(100, 100, 100)
    end)
end

-- Criar botões toggles da aba Mods
local modsFrame = tabFrames["Mods"]

local infAmmoToggle = createToggleButton("Infinite Ammo", modsFrame, UDim2.new(0, 20, 0, 20), _G.modInfiniteAmmo, function(val) _G.modInfiniteAmmo = val end)
local noRecoilToggle = createToggleButton("No Recoil", modsFrame, UDim2.new(0, 20, 0, 70), _G.modNoRecoil, function(val) _G.modNoRecoil = val end)
local instantReloadToggle = createToggleButton("Instant Reload", modsFrame, UDim2.new(0, 20, 0, 120), _G.modInstantReload, function(val) _G.modInstantReload = val end)

-- Sliders para rateOfFire, spread e zoom
local rateOfFireSlider = createSlider("Rate Of Fire", modsFrame, UDim2.new(0, 20, 0, 180), 50, 1000, 10, _G.lt.rateOfFire, function(val) _G.lt.rateOfFire = val end)
local spreadSlider = createSlider("Spread", modsFrame, UDim2.new(0, 20, 0, 240), 0, 50, 1, _G.lt.spread, function(val) _G.lt.spread = val end)
local zoomSlider = createSlider("Zoom", modsFrame, UDim2.new(0, 20, 0, 300), 1, 10, 0.1, _G.lt.zoom, function(val) _G.lt.zoom = val end)

-- Função para aplicar mods na arma equipada
local function applyWeaponMods(tool)
    if not tool then return end
    if _G.modNoRecoil then
        tool:SetAttribute("recoilAimReduction", Vector2.new(0, 0))
        tool:SetAttribute("recoilMax", Vector2.new(0, 0))
        tool:SetAttribute("recoilMin", Vector2.new(0, 0))
    end
    if _G.modInfiniteAmmo then
        local mag = tool:GetAttribute("magazineSize") or 200
        tool:SetAttribute("_ammo", math.huge)
        tool:SetAttribute("magazineSize", mag)
        local display = tool:FindFirstChild("AmmoDisplay")
        if display and display:IsA("TextLabel") then
            display.Text = tostring(mag)
        end
    end
    if _G.modInstantReload then
        tool:SetAttribute("reloadTime", 0)
    end
    -- Aplicar rateOfFire, spread e zoom da _G.lt
    for k, v in pairs(_G.lt) do
        tool:SetAttribute(k, v)
    end
end

-- Aplicar mods e valores ao equipar arma
LocalPlayer.CharacterAdded:Connect(function(char)
    local tool
    repeat
        tool = char:FindFirstChildWhichIsA("Tool")
        task.wait()
    until tool
    applyWeaponMods(tool)
end)

RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChildWhichIsA("Tool")
        if tool then
            applyWeaponMods(tool)
        end
    end
end)
