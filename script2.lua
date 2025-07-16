--[[
  Script Completo - Aimbot, ESP, Mods e Menu Rayfield-like
  Por: ChatGPT
  Uso: Roblox Lua
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local baseWidth, baseHeight = 220, 280
local scaleOptions = {0.8, 1.0, 1.2}
local currentScaleIndex = 2 -- começa com 1.0


-- Variáveis Globais padrão
_G.aimbotAutoEnabled = _G.aimbotAutoEnabled or false
_G.aimbotLegitEnabled = _G.aimbotLegitEnabled or false

_G.modInfiniteAmmo = _G.modInfiniteAmmo or false
_G.modNoRecoil = _G.modNoRecoil or false
_G.modInstantReload = _G.modInstantReload or false

_G.showFOV = _G.showFOV or true

_G.espAlly = _G.espAlly or false
_G.espEnemy = _G.espEnemy or true
_G.espBox = _G.espBox or true
_G.espName = _G.espName or true
_G.espLine = _G.espLine or true
_G.espDistance = _G.espDistance or true
_G.espHealth = _G.espHealth or true
_G.espWallhack = _G.espWallhack or true

_G.ignoreWall = _G.ignoreWall or false

_G.hitboxSelection = _G.hitboxSelection or {
    Head = true, Torso = false, LeftArm = false, RightArm = false, LeftLeg = false, RightLeg = false
}

_G.FOV_RADIUS = _G.FOV_RADIUS or 200
_G.lt = _G.lt or {
    ["rateOfFire"] = 200,
    ["spread"] = 0,
    ["zoom"] = 3,
}

-- Função para aplicar atributos na arma equipada
local function applyAttributesToTool(tool)
    if not tool then return end
    for attr, val in pairs(_G.lt) do
        tool:SetAttribute(attr, val)
    end
end

-- Atualiza arma ao equipar
LocalPlayer.CharacterAdded:Connect(function(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            applyAttributesToTool(child)
        end
    end)
end)

-- Atualiza arma equipada no Heartbeat caso atributos mudem no menu
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChildWhichIsA("Tool")
        if tool then
            applyAttributesToTool(tool)
        end
    end
end)



-- Criação do GUI
local gui = Instance.new("ScreenGui")
gui.Name = "RaycastUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Função auxiliar para criar botões toggle
local function createToggle(name, parent, posY, globalVar)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 240, 0, 30)
    btn.Position = UDim2.new(0, 10, 0, posY)
    btn.BackgroundColor3 = _G[globalVar] and Color3.fromRGB(0,170,0) or Color3.fromRGB(35,35,35)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 15
    btn.Text = name .. ": " .. (_G[globalVar] and "ON" or "OFF")
    btn.Parent = parent

    btn.MouseButton1Click:Connect(function()
        _G[globalVar] = not _G[globalVar]
        btn.BackgroundColor3 = _G[globalVar] and Color3.fromRGB(0,170,0) or Color3.fromRGB(35,35,35)
        btn.Text = name .. ": " .. (_G[globalVar] and "ON" or "OFF")

        -- Exclusividade Aimbot Auto/Legit
        if globalVar == "aimbotAutoEnabled" and _G.aimbotAutoEnabled then
            _G.aimbotLegitEnabled = false
        elseif globalVar == "aimbotLegitEnabled" and _G.aimbotLegitEnabled then
            _G.aimbotAutoEnabled = false
        end
    end)

    return btn
end

-- Função auxiliar para criar sliders (adaptada para tabelas dentro de _G)
local function createSlider(name, parent, posY, tbl, key, minVal, maxVal, step, default)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 240, 0, 50)
    frame.Position = UDim2.new(0, 10, 0, posY)
    frame.BackgroundColor3 = Color3.fromRGB(35,35,35)
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.Text = string.format("%s: %d", name, tbl[key] or default)
    label.Parent = frame

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -20, 0, 10)
    sliderBg.Position = UDim2.new(0, 10, 0, 30)
    sliderBg.BackgroundColor3 = Color3.fromRGB(50,50,50)
    sliderBg.Parent = frame

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new(((tbl[key] or default) - minVal) / (maxVal - minVal), 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    sliderFill.Parent = sliderBg

    local sliderBtn = Instance.new("TextButton")
    sliderBtn.Size = UDim2.new(0, 14, 0, 14)
    sliderBtn.Position = UDim2.new(sliderFill.Size.X.Scale, 0, 0.5, -7)
    sliderBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    sliderBtn.BorderSizePixel = 0
    sliderBtn.AutoButtonColor = false
    sliderBtn.Parent = sliderBg

    local dragging = false
    sliderBtn.MouseButton1Down:Connect(function()
        dragging = true
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local relativeX = math.clamp(input.Position.X - sliderBg.AbsolutePosition.X, 0, sliderBg.AbsoluteSize.X)
            local scale = relativeX / sliderBg.AbsoluteSize.X
            sliderFill.Size = UDim2.new(scale, 0, 1, 0)
            sliderBtn.Position = UDim2.new(scale, 0, 0.5, -7)

            local val = math.floor(minVal + (maxVal - minVal) * scale)
            val = math.floor(val / step + 0.5) * step
            tbl[key] = val
            label.Text = string.format("%s: %d", name, val)
        end
    end)

    return frame
end

-- Cria janela popup de hitbox (boneco bacon)
local function createHitboxPopup(parent)
    local popup = Instance.new("Frame")
    popup.Size = UDim2.new(0, 260, 0, 350)
    popup.Position = UDim2.new(0.5, -130, 0.5, -175)
    popup.BackgroundColor3 = Color3.fromRGB(30,30,30)
    popup.BorderSizePixel = 0
    popup.Visible = false
    popup.Active = true
    popup.ZIndex = 1000
    popup.Parent = parent

    local img = Instance.new("ImageLabel")
    img.Size = UDim2.new(0, 140, 0, 280)
    img.Position = UDim2.new(0.5, -70, 0, 15)
    img.BackgroundTransparency = 1
    img.Image = "rbxassetid://3926305904" -- Bacon Roblox
    img.Parent = popup

    local closeBtn = Instance.new("TextButton")
    closeBtn.Text = "Fechar"
    closeBtn.Size = UDim2.new(0, 80, 0, 30)
    closeBtn.Position = UDim2.new(1, -90, 0, 10)
    closeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.TextSize = 16
    closeBtn.Parent = popup

    closeBtn.MouseButton1Click:Connect(function()
        popup.Visible = false
    end)

    local function createHitboxButton(name, pos, size)
        local btn = Instance.new("TextButton")
        btn.Size = size
        btn.Position = pos
        btn.BackgroundColor3 = Color3.new(0,0,0)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.ZIndex = 1100
        btn.Parent = popup

        local border = Instance.new("Frame")
        border.Size = UDim2.new(1,0,1,0)
        border.Position = UDim2.new(0,0,0,0)
        border.BorderSizePixel = 2
        border.BorderColor3 = Color3.fromRGB(255,0,0)
        border.BackgroundTransparency = 1
        border.Visible = _G.hitboxSelection[name] or false
        border.Parent = btn

        btn.MouseButton1Click:Connect(function()
            _G.hitboxSelection[name] = not _G.hitboxSelection[name]
            border.Visible = _G.hitboxSelection[name]
        end)
    end

    -- Posiciona os botões conforme partes do corpo
    createHitboxButton("Head", UDim2.new(0.46, 0, 0.03, 0), UDim2.new(0, 40, 0, 40))
    createHitboxButton("Torso", UDim2.new(0.41, 0, 0.28, 0), UDim2.new(0, 60, 0, 75))
    createHitboxButton("LeftArm", UDim2.new(0.22, 0, 0.30, 0), UDim2.new(0, 40, 0, 70))
    createHitboxButton("RightArm", UDim2.new(0.73, 0, 0.30, 0), UDim2.new(0, 40, 0, 70))
    createHitboxButton("LeftLeg", UDim2.new(0.43, 0, 0.73, 0), UDim2.new(0, 40, 0, 70))
    createHitboxButton("RightLeg", UDim2.new(0.54, 0, 0.73, 0), UDim2.new(0, 40, 0, 70))

    return popup
end

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 280, 0, 360)
mainFrame.Position = UDim2.new(0, 20, 0.5, -180)
mainFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = gui

-- Tabs
local tabButtonsFrame = Instance.new("Frame")
tabButtonsFrame.Size = UDim2.new(1, 0, 0, 30)
tabButtonsFrame.BackgroundColor3 = Color3.fromRGB(15,15,15)
tabButtonsFrame.Parent = mainFrame

local tabs = {
    Aimbot = Instance.new("Frame"),
    ESP = Instance.new("Frame"),
    Hitbox = Instance.new("Frame"),
    Mods = Instance.new("Frame"),
    Ajustes = Instance.new("Frame")
}

local tabOrder = {"Aimbot","ESP","Hitbox","Mods","Ajustes"}

for _, tabName in ipairs(tabOrder) do
    local frame = tabs[tabName]
    frame.Size = UDim2.new(1,0,1,-30)
    frame.Position = UDim2.new(0,0,0,30)
    frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
    frame.Visible = false
    frame.Parent = mainFrame
end

tabs.Aimbot.Visible = true

-- Criar botões das tabs
for i, tabName in ipairs(tabOrder) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1/#tabOrder, -2, 1, 0)
    btn.Position = UDim2.new((i-1)/#tabOrder, i>1 and 2 or 0, 0, 0)
    btn.Text = tabName
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 15
    btn.TextColor3 = Color3.new(1,1,1)
    btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    btn.Parent = tabButtonsFrame

    btn.MouseButton1Click:Connect(function()
        for _, f in pairs(tabs) do f.Visible = false end
        tabs[tabName].Visible = true
    end)
end

-- PopUp Hitbox
local popupHitbox = createHitboxPopup(gui)

-- Função para permitir arrastar GUI
local function makeDraggable(frame)
    local dragging, dragInput, dragStart, startPos

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

makeDraggable(mainFrame)
makeDraggable(popupHitbox)

-- Abas: Aimbot
createToggle("Aimbot Automático", tabs.Aimbot, 20, "aimbotAutoEnabled")
createToggle("Aimbot Legit", tabs.Aimbot, 60, "aimbotLegitEnabled")
createSlider("FOV", tabs.Aimbot, 110, "FOV_RADIUS", 50, 500, 5, _G.FOV_RADIUS)

-- Abas: ESP
createToggle("Mostrar ESP Aliado", tabs.ESP, 20, "espAlly")
createToggle("Mostrar ESP Inimigo", tabs.ESP, 60, "espEnemy")
createToggle("Mostrar Box", tabs.ESP, 100, "espBox")
createToggle("Mostrar Nome", tabs.ESP, 140, "espName")
createToggle("Mostrar Linha", tabs.ESP, 180, "espLine")
createToggle("Mostrar Distância", tabs.ESP, 220, "espDistance")
createToggle("Mostrar HP", tabs.ESP, 260, "espHealth")
createToggle("Wallhack Neon RGB", tabs.ESP, 300, "espWallhack")
createToggle("Ignorar Parede (Aim/ESP)", tabs.ESP, 340, "ignoreWall")

-- Abas: Mods de Arma
createToggle("Munição Infinita", tabs.Mods, 20, "modInfiniteAmmo")
createToggle("Sem Recoil", tabs.Mods, 60, "modNoRecoil")
createToggle("Recarga Instantânea", tabs.Mods, 100, "modInstantReload")
createSlider("Rate of Fire", tabs.Mods, 150, _G.lt, "rateOfFire", 50, 500, 10, _G.lt.rateOfFire)
createSlider("Spread", tabs.Mods, 200, _G.lt, "spread", 0, 50, 1, _G.lt.spread)
createSlider("Zoom", tabs.Mods, 250, _G.lt, "zoom", 1, 10, 1, _G.lt.zoom)

-- Abas: Ajustes (espaço reservado para futuras configs)
local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -20, 0, 30)
label.Position = UDim2.new(0, 10, 0, 20)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.new(1,1,1)
label.Font = Enum.Font.GothamBold
label.TextSize = 16
label.Text = "Configurações adicionais"
label.Parent = tabs.Ajustes

-- Botão para abrir popup hitbox
local hitboxBtn = Instance.new("TextButton")
hitboxBtn.Text = "Selecionar Hitbox"
hitboxBtn.Size = UDim2.new(0, 240, 0, 35)
hitboxBtn.Position = UDim2.new(0, 10, 1, -45)
hitboxBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
hitboxBtn.TextColor3 = Color3.new(1,1,1)
hitboxBtn.Font = Enum.Font.GothamBold
hitboxBtn.TextSize = 18
hitboxBtn.Parent = mainFrame

hitboxBtn.MouseButton1Click:Connect(function()
    popupHitbox.Visible = not popupHitbox.Visible
end)

-- Função para garantir exclusividade entre aimbots (auto vs legit)
RunService.Heartbeat:Connect(function()
    if _G.aimbotAutoEnabled and _G.aimbotLegitEnabled then
        _G.aimbotLegitEnabled = false
    end
end)

-- Função para criar os elementos ESP para cada player
local function createESP(player)
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    -- Container para todos os ESP elements
    local espContainer = Instance.new("Folder")
    espContainer.Name = "ESPContainer"
    espContainer.Parent = player

    -- Box
    local box = Instance.new("BoxHandleAdornment")
    box.Adornee = char:FindFirstChild("HumanoidRootPart")
    box.AlwaysOnTop = true
    box.ZIndex = 2
    box.Size = Vector3.new(4, 6, 1)
    box.Transparency = 0.6
    box.Color3 = player.Team == LocalPlayer.Team and Color3.fromRGB(0,255,255) or Color3.fromRGB(255,0,0)
    box.Parent = espContainer

    -- Line from player to enemy
    local line = Instance.new("LineHandleAdornment")
    line.Adornee = char:FindFirstChild("HumanoidRootPart")
    line.AlwaysOnTop = true
    line.ZIndex = 2
    line.Color3 = box.Color3
    line.Transparency = 0.7
    line.Parent = espContainer

    -- Name label
    local nameBillboard = Instance.new("BillboardGui")
    nameBillboard.Adornee = char:FindFirstChild("HumanoidRootPart")
    nameBillboard.Size = UDim2.new(0,100,0,30)
    nameBillboard.AlwaysOnTop = true
    nameBillboard.Parent = espContainer

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1,0,1,0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = box.Color3
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.Parent = nameBillboard

    -- Distance label
    local distBillboard = Instance.new("BillboardGui")
    distBillboard.Adornee = char:FindFirstChild("HumanoidRootPart")
    distBillboard.Size = UDim2.new(0,100,0,20)
    distBillboard.AlwaysOnTop = true
    distBillboard.Parent = espContainer

    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1,0,1,0)
    distLabel.BackgroundTransparency = 1
    distLabel.TextColor3 = box.Color3
    distLabel.TextStrokeTransparency = 0
    distLabel.Font = Enum.Font.GothamBold
    distLabel.TextSize = 12
    distLabel.Parent = distBillboard

    -- HP bar
    local hpBar = Instance.new("BillboardGui")
    hpBar.Adornee = char:FindFirstChild("HumanoidRootPart")
    hpBar.Size = UDim2.new(0, 60, 0, 10)
    hpBar.AlwaysOnTop = true
    hpBar.Parent = espContainer

    local hpFrame = Instance.new("Frame")
    hpFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    hpFrame.Size = UDim2.new(1, 0, 1, 0)
    hpFrame.Parent = hpBar

    local hpFill = Instance.new("Frame")
    hpFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    hpFill.Size = UDim2.new(1, 0, 1, 0)
    hpFill.Parent = hpFrame

    -- Wallhack neon effect
    local neonParts = {}
    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            local neon = Instance.new("Highlight")
            neon.Name = "NeonHighlight"
            neon.Adornee = part
            neon.FillColor = Color3.fromHSV(tick()%5/5,1,1) -- RGB cycling
            neon.FillTransparency = 0.5
            neon.OutlineColor = Color3.new(0,0,0)
            neon.OutlineTransparency = 1
            neon.Parent = part
            neonParts[#neonParts+1] = neon
        end
    end

    -- Store refs for updating
    return {
        container = espContainer,
        box = box,
        line = line,
        nameLabel = nameLabel,
        distLabel = distLabel,
        hpFill = hpFill,
        neonParts = neonParts,
        char = char
    }
end

local ESPs = {}

-- Atualiza ESP a cada frame
RunService.RenderStepped:Connect(function()
    local camPos = Camera.CFrame.Position

    for player, espData in pairs(ESPs) do
        local char = espData.char
        if char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart") and char.Humanoid.Health > 0 then
            local isEnemy = player.Team ~= LocalPlayer.Team

            -- Verifica visibilidade (raycast)
            local canSee = true
            if not _G.ignoreWall then
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
                rayParams.FilterType = Enum.RaycastFilterType.Blacklist

                local direction = (char.Head.Position - camPos)
                local raycastResult = workspace:Raycast(camPos, direction, rayParams)

                if raycastResult and not raycastResult.Instance:IsDescendantOf(char) then
                    canSee = false
                end
            end

            -- Atualiza visibilidade dos ESPs conforme toggles e visão
            local showESP = (isEnemy and _G.espEnemy or not isEnemy and _G.espAlly)
            local showWallhack = _G.espWallhack

            -- Box
            espData.box.Adornee = char.HumanoidRootPart
            espData.box.Enabled = showESP and _G.espBox and canSee

            -- Linha
            espData.line.Adornee = char.HumanoidRootPart
            espData.line.Enabled = showESP and _G.espLine and canSee
            espData.line.From = camPos
            espData.line.To = char.HumanoidRootPart.Position

            -- Nome
            espData.nameLabel.Parent.Parent.Enabled = showESP and _G.espName and canSee

            -- Distância
            local dist = (camPos - char.HumanoidRootPart.Position).Magnitude
            espData.distLabel.Text = string.format("%.1fm", dist)
            espData.distLabel.Parent.Parent.Enabled = showESP and _G.espDistance and canSee

            -- HP barra
            local humanoid = char:FindFirstChild("Humanoid")
            if humanoid then
                local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                espData.hpFill.Size = UDim2.new(healthPercent, 0, 1, 0)
                espData.hpFill.BackgroundColor3 = Color3.fromHSV(healthPercent * 0.33, 1, 1) -- verde para vermelho
            end
            espData.hpFill.Parent.Parent.Enabled = showESP and _G.espHealth and canSee

            -- Neon wallhack
            for _, neon in pairs(espData.neonParts) do
                neon.FillColor = Color3.fromHSV((tick() % 5) / 5, 1, 1) -- ciclo RGB
                neon.Enabled = showWallhack and canSee
            end

            -- Se inimigo estiver mirado pelo aimbot, aplicar borda amarela forte
            if _G.aimbotAutoEnabled or _G.aimbotLegitEnabled then
                local fovRadius = _G.FOV_RADIUS
                local screenPos, onScreen = Camera:WorldToScreenPoint(char.Head.Position)
                local mousePos = UserInputService:GetMouseLocation()
                local distMouse = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(mousePos.X, mousePos.Y)).Magnitude

                if onScreen and distMouse <= fovRadius and canSee then
                    for _, neon in pairs(espData.neonParts) do
                        neon.OutlineColor = Color3.new(1, 1, 0)
                        neon.OutlineTransparency = 0
                    end
                else
                    for _, neon in pairs(espData.neonParts) do
                        neon.OutlineTransparency = 1
                    end
                end
            else
                for _, neon in pairs(espData.neonParts) do
                    neon.OutlineTransparency = 1
                end
            end
        else
            -- Limpa ESP se personagem morrer ou sumir
            for _, v in pairs(espData.neonParts) do
                v:Destroy()
            end
            if espData.container then espData.container:Destroy() end
            ESPs[player] = nil
        end
    end
end)

-- Gerenciar ESP para todos jogadores atuais e futuros
local function setupESPForPlayer(player)
    if player == LocalPlayer then return end
    player.CharacterAdded:Connect(function(char)
        wait(0.5)
        ESPs[player] = createESP(player)
    end)
    if player.Character then
        ESPs[player] = createESP(player)
    end
end

for _, plr in pairs(Players:GetPlayers()) do
    setupESPForPlayer(plr)
end

Players.PlayerAdded:Connect(function(plr)
    setupESPForPlayer(plr)
end)

-- Aplicar Mods a cada arma equipada
LocalPlayer.CharacterAdded:Connect(function(char)
    local tool
    while not tool do
        tool = char:FindFirstChildWhichIsA("Tool")
        task.wait()
    end
    for attr, val in pairs(_G.lt) do
        tool:SetAttribute(attr, val)
    end
end)

RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChildWhichIsA("Tool")
        if tool then
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
        end
    end
end)

-- Atualização dinâmica do spread baseado na distância do mouse para a cabeça
RunService.Heartbeat:Connect(function()
    local char, mouseHit = LocalPlayer.Character, LocalPlayer:GetMouse().Hit
    if char and mouseHit then
        local tool, head = char:FindFirstChildWhichIsA("Tool"), char:FindFirstChild("Head")
        if tool and head then
            local dist = (head.Position - mouseHit.Position).Magnitude
            local newSpread = 30 - dist / 5
            tool:SetAttribute("spread", math.clamp(newSpread, 0, 50))
        end
    end
end)

-- Aimbot simples que mira no inimigo mais próximo dentro do FOV e linha de visão
RunService.Heartbeat:Connect(function()
    if not (_G.aimbotAutoEnabled or _G.aimbotLegitEnabled) then return end
    local char = LocalPlayer.Character
    local mousePos = UserInputService:GetMouseLocation()
    local closestDist = math.huge
    local closestPart = nil
    local targetPlayer = nil

    if not char then return end
    if not char:FindFirstChild("Head") then return end

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            local enemyChar = plr.Character
            local isEnemy = plr.Team ~= LocalPlayer.Team
            if isEnemy then
                local head = enemyChar:FindFirstChild("Head")
                if head then
                    local screenPos, onScreen = Camera:WorldToScreenPoint(head.Position)
                    if onScreen then
                        local distance = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(mousePos.X, mousePos.Y)).Magnitude
                        if distance <= _G.FOV_RADIUS then
                            -- Verifica linha de visão via raycast
                            local rayParams = RaycastParams.new()
                            rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
                            rayParams.FilterType = Enum.RaycastFilterType.Blacklist
                            local rayResult = workspace:Raycast(Camera.CFrame.Position, (head.Position - Camera.CFrame.Position), rayParams)

                            if _G.ignoreWall or (rayResult and rayResult.Instance:IsDescendantOf(enemyChar)) then
                                if distance < closestDist then
                                    closestDist = distance
                                    closestPart = head
                                    targetPlayer = plr
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if closestPart and targetPlayer then
        local mouse = LocalPlayer:GetMouse()
        local targetPos = closestPart.Position

        -- Move mouse towards target head position (simplified aimbot)
        -- Aqui você deve substituir pela sua função de mover a mira/ câmera do jogo conforme necessidade
        -- Exemplo (pseudo): mousemoverel(dx, dy)
        -- Ou usar: mousemoveabs(x, y) para Roblox hacks externos

        -- Como Roblox não permite mover mouse via script normal, isso é apenas conceito.

        -- Pseudocódigo:
        -- local screenPos = Camera:WorldToScreenPoint(targetPos)
        -- mover cursor para screenPos na tela

        -- Aqui você faria o movimento da câmera do jogador para mirar no targetPos

    end
end)
