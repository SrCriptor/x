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
mainFrame.Size = UDim2.new(0, 280, 0, 440)
mainFrame.Position = UDim2.new(0, 20, 0.5, -220)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = gui
mainFrame.Active = true
mainFrame.Draggable = false -- Usaremos drag manual para poder fazer só no título

-- Título do menu
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
titleBar.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Text = "Raycast Menu"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 22
titleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
titleLabel.BackgroundTransparency = 1
titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Botão minimizar/maximizar
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Text = "−"
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 28
minimizeBtn.TextColor3 = Color3.new(1,1,1)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -70, 0, 5)
minimizeBtn.AutoButtonColor = false
minimizeBtn.Parent = titleBar

-- Botão fechar
local closeBtn = Instance.new("TextButton")
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 22
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.AutoButtonColor = false
closeBtn.Parent = titleBar

-- Container para botões e sliders
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, 0, 1, -40)
contentFrame.Position = UDim2.new(0, 0, 0, 40)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

-- Barra de abas
local tabs = {"Aimbot", "Hitbox", "Mods"}
local tabFrames = {}
local tabButtonsFrame = Instance.new("Frame")
tabButtonsFrame.Size = UDim2.new(1, 0, 0, 36)
tabButtonsFrame.Position = UDim2.new(0, 0, 0, 0)
tabButtonsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
tabButtonsFrame.BorderSizePixel = 0
tabButtonsFrame.Parent = contentFrame

-- Criar botões de abas com espaçamento e estilo
local function createTabButton(name, idx)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 85, 0, 32)
    btn.Position = UDim2.new(0, (idx - 1) * 90 + 10, 0, 2)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.AutoButtonColor = false
    btn.Parent = tabButtonsFrame
    return btn
end

for i, tabName in ipairs(tabs) do
    local frame = Instance.new("ScrollingFrame")
    frame.Size = UDim2.new(1, 0, 1, -36)
    frame.Position = UDim2.new(0, 0, 0, 36)
    frame.BackgroundTransparency = 1
    frame.CanvasSize = UDim2.new(0, 0, 3, 0)
    frame.ScrollBarThickness = 5
    frame.Visible = i == 1 -- Só a primeira aba fica visível inicialmente
    frame.Parent = contentFrame
    tabFrames[tabName] = frame
end

-- Atualizar visual do botão ativo
local function setActiveTab(activeName)
    for name, frame in pairs(tabFrames) do
        frame.Visible = name == activeName
    end
    for _, btn in pairs(tabButtonsFrame:GetChildren()) do
        if btn:IsA("TextButton") then
            btn.BackgroundColor3 = (btn.Text == activeName) and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
        end
    end
end

-- Criar botões e conectar troca de abas
for i, btn in ipairs(tabButtonsFrame:GetChildren()) do
    if btn:IsA("TextButton") then
        btn.MouseButton1Click:Connect(function()
            setActiveTab(btn.Text)
        end)
    end
end

setActiveTab("Aimbot")

-- Função para criar botões toggle dentro das abas e chamar callback
local function createToggleInFrame(text, frame, yPos, default, cb)
    return createToggleButton(text, frame, UDim2.new(0,
-- Variáveis e sliders para controle fino de arma
_G.lt = _G.lt or {
	["rateOfFire"] = 200,
	["spread"] = 0,
	["zoom"] = 3,
}

local function applyWeaponAttributes(tool)
	for key, value in pairs(_G.lt) do
		tool:SetAttribute(key, value)
	end
end

-- Aplica ao equipar arma
LocalPlayer.CharacterAdded:Connect(function(char)
	char:WaitForChild("HumanoidRootPart")
	local tool
	repeat
		tool = char:FindFirstChildWhichIsA("Tool")
		RunService.RenderStepped:Wait()
	until tool
	applyWeaponAttributes(tool)
end)

-- Atualiza spread com base na distância do mouse (dispersão adaptativa)
RunService.RenderStepped:Connect(function()
	local char = LocalPlayer.Character
	local mouse = LocalPlayer:GetMouse()
	if char and mouse and mouse.Hit then
		local tool = char:FindFirstChildWhichIsA("Tool")
		local head = char:FindFirstChild("Head")
		if tool and head then
			local dist = (head.Position - mouse.Hit.Position).Magnitude
			local spread = math.clamp(30 - dist / 5, 0, 30)
			tool:SetAttribute("spread", spread)
		end
	end
end)

-- Criar sliders na aba de Mods
local function createSlider(label, defaultValue, minVal, maxVal, step, posY, parent, key)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(0, 240, 0, 40)
	container.Position = UDim2.new(0, 20, 0, posY)
	container.BackgroundTransparency = 1
	container.Parent = parent

	local labelTxt = Instance.new("TextLabel")
	labelTxt.Size = UDim2.new(1, 0, 0, 20)
	labelTxt.Position = UDim2.new(0, 0, 0, 0)
	labelTxt.Text = label .. ": " .. tostring(defaultValue)
	labelTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
	labelTxt.Font = Enum.Font.Gotham
	labelTxt.TextSize = 14
	labelTxt.BackgroundTransparency = 1
	labelTxt.TextXAlignment = Enum.TextXAlignment.Left
	labelTxt.Parent = container

	local sliderBack = Instance.new("Frame")
	sliderBack.Size = UDim2.new(1, 0, 0, 10)
	sliderBack.Position = UDim2.new(0, 0, 0, 25)
	sliderBack.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	sliderBack.BorderSizePixel = 0
	sliderBack.Parent = container

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new((defaultValue - minVal) / (maxVal - minVal), 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
	fill.Parent = sliderBack

	local dragging = false

	local function updateSlider(x)
		local relative = math.clamp(x - sliderBack.AbsolutePosition.X, 0, sliderBack.AbsoluteSize.X)
		local percent = relative / sliderBack.AbsoluteSize.X
		local value = math.floor((minVal + percent * (maxVal - minVal)) / step + 0.5) * step
		_G.lt[key] = value
		labelTxt.Text = label .. ": " .. tostring(value)
		fill.Size = UDim2.new((value - minVal) / (maxVal - minVal), 0, 1, 0)
	end

	sliderBack.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			updateSlider(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateSlider(input.Position.X)
		end
	end)
end

-- Achar aba de mods pelo nome
local modTab
for _, child in ipairs(gui:GetDescendants()) do
	if child:IsA("TextButton") and child.Text == "ModArma" then
		child.MouseButton1Click:Connect(function()
			modTab.Visible = true
		end)
	end
	if child:IsA("Frame") and child.Name == "ModArma" then
		modTab = child
	end
end

if modTab then
	createSlider("Rate Of Fire", _G.lt.rateOfFire, 50, 1000, 10, 140, modTab, "rateOfFire")
	createSlider("Spread", _G.lt.spread, 0, 30, 1, 190, modTab, "spread")
	createSlider("Zoom", _G.lt.zoom, 1, 10, 0.1, 240, modTab, "zoom")
end
