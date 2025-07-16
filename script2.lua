local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Settings = {
    aimbotAutoEnabled = false,
    FOV_RADIUS = 200,

    espEnabled = true,
    espBox = true,
    espName = true,

    modInfiniteAmmo = false,
    modNoRecoil = false,
    modInstantReload = false,

    hitboxSelection = {
        Head = true,
        Torso = false,
        LeftArm = false,
        RightArm = false,
        LeftLeg = false,
        RightLeg = false,
    }
}

local gui = Instance.new("ScreenGui")
gui.Name = "SimpleAimbotESP"
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
gui.ResetOnSpawn = false

local baseWidth, baseHeight = 280, 320
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, baseWidth, 0, baseHeight)
mainFrame.Position = UDim2.new(0.5, -baseWidth/2, 0.5, -baseHeight/2)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = gui

local tabButtonsFrame = Instance.new("Frame")
tabButtonsFrame.Size = UDim2.new(1, 0, 0, 30)
tabButtonsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
tabButtonsFrame.Parent = mainFrame

local tabs = {
    Aimbot = Instance.new("Frame"),
    ESP = Instance.new("Frame"),
    Mods = Instance.new("Frame"),
    Hitbox = Instance.new("Frame"),
}

local tabOrder = {"Aimbot", "ESP", "Mods", "Hitbox"}

for _, tabName in ipairs(tabOrder) do
    local frame = tabs[tabName]
    frame.Size = UDim2.new(1, 0, 1, -30)
    frame.Position = UDim2.new(0, 0, 0, 30)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.Visible = false
    frame.Parent = mainFrame
end
tabs.Aimbot.Visible = true

for i, tabName in ipairs(tabOrder) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1/#tabOrder, -2, 1, 0)
    btn.Position = UDim2.new((i-1)/#tabOrder, i>1 and 2 or 0, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Text = tabName
    btn.Parent = tabButtonsFrame

    btn.MouseButton1Click:Connect(function()
        for _, f in pairs(tabs) do
            f.Visible = false
        end
        tabs[tabName].Visible = true
    end)
end

local function createToggle(text, parent, posY, settingKey)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 30)
    btn.Position = UDim2.new(0, 10, 0, posY)
    btn.BackgroundColor3 = Settings[settingKey] and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(70, 70, 70)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Text = text .. ": " .. (Settings[settingKey] and "ON" or "OFF")
    btn.Parent = parent

    btn.MouseButton1Click:Connect(function()
        Settings[settingKey] = not Settings[settingKey]
        btn.BackgroundColor3 = Settings[settingKey] and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(70, 70, 70)
        btn.Text = text .. ": " .. (Settings[settingKey] and "ON" or "OFF")
    end)

    return btn
end

local function createSlider(text, parent, posY, settingKey, minVal, maxVal, step)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 40)
    frame.Position = UDim2.new(0, 10, 0, posY)
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.Text = string.format("%s: %d", text, Settings[settingKey])
    label.Parent = frame

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -20, 0, 10)
    sliderBg.Position = UDim2.new(0, 10, 0, 30)
    sliderBg.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    sliderBg.Parent = frame

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((Settings[settingKey] - minVal) / (maxVal - minVal), 0, 1, 0)
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
            Settings[settingKey] = val
            label.Text = string.format("%s: %d", text, val)
        end
    end)

    return frame
end

-- Abas: Criar toggles e slider
-- Aimbot
createToggle("Aimbot Auto", tabs.Aimbot, 10, "aimbotAutoEnabled")
createSlider("FOV Radius", tabs.Aimbot, 50, "FOV_RADIUS", 50, 400, 10)

-- ESP
createToggle("Enable ESP", tabs.ESP, 10, "espEnabled")
createToggle("ESP Box", tabs.ESP, 50, "espBox")
createToggle("ESP Name", tabs.ESP, 90, "espName")

-- Mods
createToggle("Infinite Ammo", tabs.Mods, 10, "modInfiniteAmmo")
createToggle("No Recoil", tabs.Mods, 50, "modNoRecoil")
createToggle("Instant Reload", tabs.Mods, 90, "modInstantReload")

-- Hitbox aba só texto explicativo + botão abrir popup já criado

-- Popup hitbox
local hitboxPopup = Instance.new("Frame")
hitboxPopup.Size = UDim2.new(0, 200, 0, 250)
hitboxPopup.Position = UDim2.new(0.5, -100, 0.5, -125)
hitboxPopup.BackgroundColor3 = Color3.fromRGB(40,40,40)
hitboxPopup.Visible = false
hitboxPopup.Parent = gui

local closeBtn = Instance.new("TextButton")
closeBtn.Text = "Fechar"
closeBtn.Size = UDim2.new(0, 80, 0, 30)
closeBtn.Position = UDim2.new(0.5, -40, 1, -40)
closeBtn.BackgroundColor3 = Color3.fromRGB(0,150,0)
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.Parent = hitboxPopup

closeBtn.MouseButton1Click:Connect(function()
    hitboxPopup.Visible = false
end)

local parts = {"Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}
for i, partName in ipairs(parts) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 140, 0, 30)
    btn.Position = UDim2.new(0, 30, 0, 10 + (i-1)*35)
    btn.BackgroundColor3 = Settings.hitboxSelection[partName] and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(70,70,70)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Text = partName
    btn.Parent = hitboxPopup

    btn.MouseButton1Click:Connect(function()
        Settings.hitboxSelection[partName] = not Settings.hitboxSelection[partName]
        btn.BackgroundColor3 = Settings.hitboxSelection[partName] and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(70,70,70)
    end)
end

local hitboxBtn = Instance.new("TextButton")
hitboxBtn.Text = "Selecionar Hitbox"
hitboxBtn.Size = UDim2.new(1, -20, 0, 35)
hitboxBtn.Position = UDim2.new(0, 10, 1, -45)
hitboxBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
hitboxBtn.TextColor3 = Color3.new(1,1,1)
hitboxBtn.Font = Enum.Font.GothamBold
hitboxBtn.TextSize = 16
hitboxBtn.Parent = mainFrame

hitboxBtn.MouseButton1Click:Connect(function()
    hitboxPopup.Visible = not hitboxPopup.Visible
end)

-- Função para achar inimigo mais próximo do mouse dentro do FOV
local function getClosestEnemyToMouse()
    local closestDist = math.huge
    local closestPlayer = nil
    local mousePos = UserInputService:GetMouseLocation()

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            local rootPart = plr.Character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(mousePos.X, mousePos.Y)).Magnitude
                    if dist < closestDist and dist <= Settings.FOV_RADIUS then
                        closestDist = dist
                        closestPlayer = plr
                    end
                end
            end
        end
    end
    return closestPlayer
end

RunService.RenderStepped:Connect(function()
    if Settings.aimbotAutoEnabled then
        local target = getClosestEnemyToMouse()
        if target and target.Character then
            local hitPart
            for _, partName in ipairs(parts) do
                if Settings.hitboxSelection[partName] then
                    local p = target.Character:FindFirstChild(partName)
                    if p then
                        hitPart = p
                        break
                    end
                end
            end
            if hitPart then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, hitPart.Position)
            end
        end
    end
end)

local espBoxes = {}
local espNames = {}

local function createESPBox(plr)
    local box = Instance.new("BoxHandleAdornment")
    box.Adornee = nil
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Size = Vector3.new(2, 5, 1)
    box.Color3 = Color3.fromRGB(0, 255, 0)
    box.Transparency = 0.5
    box.Parent = Camera
    return box
end

local function createESPName(plr)
    local bill = Instance.new("BillboardGui")
    bill.Size = UDim2.new(0, 100, 0, 25)
    bill.Adornee = nil
    bill.AlwaysOnTop = true
    bill.Parent = Camera

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0.5
    label.Text = plr.Name
    label.TextScaled = true
    label.Parent = bill
    return bill
end

RunService.RenderStepped:Connect(function()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            local rootPart = plr.Character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                if Settings.espEnabled and Settings.espBox then
                    if not espBoxes[plr] then
                        espBoxes[plr] = createESPBox(plr)
                    end
                    espBoxes[plr].Adornee = rootPart
                    espBoxes[plr].Enabled = true
                elseif espBoxes[plr] then
                    espBoxes[plr].Enabled = false
                end

                if Settings.espEnabled and Settings.espName then
                    if not espNames[plr] then
                        espNames[plr] = createESPName(plr)
                    end
                    espNames[plr].Adornee = rootPart
                    espNames[plr].Enabled = true
                elseif espNames[plr] then
                    espNames[plr].Enabled = false
                end
            end
        else
            if espBoxes[plr] then
                espBoxes[plr].Enabled = false
            end
            if espNames[plr] then
                espNames[plr].Enabled = false
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end

    tool:SetAttribute("InfiniteAmmo", Settings.modInfiniteAmmo)
    tool:SetAttribute("NoRecoil", Settings.modNoRecoil)
    tool:SetAttribute("InstantReload", Settings.modInstantReload)
end)

-- Tecla para abrir/fechar menu
local menuOpen = true
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        menuOpen = not menuOpen
        mainFrame.Visible = menuOpen
        hitboxPopup.Visible = false -- fecha popup ao fechar menu
    end
end)

-- Criar círculo FOV (desenhado na tela)
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Radius = Settings.FOV_RADIUS
FOVCircle.Color = Color3.fromRGB(0, 255, 0)
FOVCircle.Thickness = 2
FOVCircle.Filled = false

RunService.RenderStepped:Connect(function()
    if menuOpen and Settings.aimbotAutoEnabled then
        FOVCircle.Visible = true
        FOVCircle.Position = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
        FOVCircle.Radius = Settings.FOV_RADIUS
    else
        FOVCircle.Visible = false
    end
end)

-- Controle de auto disparo e disparo automático correto

local UIS = UserInputService
local mouseDown = false
UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        mouseDown = true
    end
end)
UIS.InputEnded:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        mouseDown = false
    end
end)

-- Função para simular tiro automático (depende do jogo, ajuste se necessário)
local function shootAt(targetPart)
    -- Exemplo genérico: se a arma tiver um método Fire()
    local char = LocalPlayer.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end

    if tool:FindFirstChild("Fire") and typeof(tool.Fire) == "RBXScriptSignal" then
        -- Se o jogo usa eventos para disparo, você pode disparar o evento.
        tool.Fire:FireServer(targetPart.Position)
    elseif tool:FindFirstChild("Handle") then
        -- Se for manual, pode tentar ativar o ClickDetector ou RemoteEvent do tool
        -- Ajuste aqui para o seu jogo.
    end
end

RunService.RenderStepped:Connect(function()
    if Settings.aimbotAutoEnabled and mouseDown then
        local target = getClosestEnemyToMouse()
        if target and target.Character then
            local hitPart
            for _, partName in ipairs(parts) do
                if Settings.hitboxSelection[partName] then
                    local p = target.Character:FindFirstChild(partName)
                    if p then
                        hitPart = p
                        break
                    end
                end
            end
            if hitPart then
                -- Mira no alvo
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, hitPart.Position)
                -- Dispara (ajuste para seu sistema de armas)
                shootAt(hitPart)
            end
        end
    end
end)

-- Auto Spread (remover ou reduzir spread)
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end

    if Settings.modNoRecoil then
        tool:SetAttribute("NoRecoil", true)
    else
        tool:SetAttribute("NoRecoil", false)
    end

    if Settings.modInstantReload then
        tool:SetAttribute("InstantReload", true)
    else
        tool:SetAttribute("InstantReload", false)
    end

    if Settings.modInfiniteAmmo then
        tool:SetAttribute("InfiniteAmmo", true)
    else
        tool:SetAttribute("InfiniteAmmo", false)
    end

    -- Caso o sistema não suporte atributos, pode tentar ajustar variáveis internas ou eventos do jogo
    -- Isso depende de como o jogo foi desenvolvido e pode exigir engenharia reversa.
end)

