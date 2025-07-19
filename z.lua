-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Flags globais padrão
_G.FOV_RADIUS = 65
_G.FOV_VISIBLE = true
_G.aimbotAutoEnabled = false
_G.aimbotManualEnabled = false
_G.espEnemiesEnabled = true
_G.espAlliesEnabled = false
_G.noRecoilEnabled = true
_G.infiniteAmmoEnabled = false
_G.instantReloadEnabled = true
_G.rapidFireEnabled = false
_G.rateOfFire = nil

-- Armazenar valores padrões das armas
local defaultWeaponValues = {}

-- Função para guardar valores padrões da arma
local function storeDefaultWeaponValues(tool)
    if not tool or not tool:IsA("Tool") then return end
    if not defaultWeaponValues[tool] then
        defaultWeaponValues[tool] = {
            rateOfFire = tool:GetAttribute("rateOfFire"),
            recoilAimReduction = tool:GetAttribute("recoilAimReduction"),
            recoilMax = tool:GetAttribute("recoilMax"),
            recoilMin = tool:GetAttribute("recoilMin"),
            spread = tool:GetAttribute("spread"),
            _ammo = tool:GetAttribute("_ammo"),
            magazineSize = tool:GetAttribute("magazineSize"),
            reloadTime = tool:GetAttribute("reloadTime"),
        }
    end
end

-- Função para restaurar valores padrões da arma
local function restoreDefaultWeaponValues(tool)
    local defaults = defaultWeaponValues[tool]
    if not defaults then return end
    for k, v in pairs(defaults) do
        if v ~= nil then
            tool:SetAttribute(k, v)
        end
    end
end

-- GUI principal
local gui = Instance.new("ScreenGui")
gui.Name = "KryptonToolsGUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Menu responsivo (ScrollingFrame)
local menu = Instance.new("ScrollingFrame")
menu.Size = UDim2.new(0, 240, 0, 480)
menu.CanvasSize = UDim2.new(0, 0, 0, 600)
menu.AnchorPoint = Vector2.new(0, 0)
menu.Position = UDim2.new(0, 20, 0, 40)
menu.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
menu.BackgroundTransparency = 0.08
menu.BorderSizePixel = 0
menu.ClipsDescendants = true
menu.ScrollBarThickness = 4
menu.Active = true
menu.Parent = gui
menu.Name = "MainMenu"

local uicorner = Instance.new("UICorner")
uicorner.CornerRadius = UDim.new(0, 12)
uicorner.Parent = menu

-- Título com efeito RGB/Matrix
local title = Instance.new("TextLabel")
title.Text = "Krypton Tools"
title.Size = UDim2.new(1, 0, 0, 42)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(0, 1, 0)
title.Font = Enum.Font.Code
title.TextSize = 28
title.Parent = menu
title.Name = "Title"
title.AnchorPoint = Vector2.new(0, 0)
title.Position = UDim2.new(0, 0, 0, 0)

-- Efeito RGB animado no título
task.spawn(function()
    local t = 0
    while true do
        t += 0.05
        local r = math.abs(math.sin(t)) * 0.8 + 0.2
        local g = math.abs(math.sin(t + 2)) * 0.8 + 0.2
        local b = math.abs(math.sin(t + 4)) * 0.8 + 0.2
        title.TextColor3 = Color3.new(r, g, b)
        task.wait(0.05)
    end
end)

-- Botão engrenagem para tamanho do menu
local menuSizeOptions = {
    {size = UDim2.new(0, 240, 0, 480), canvas = UDim2.new(0, 0, 0, 600)},
    {size = UDim2.new(0, 300, 0, 540), canvas = UDim2.new(0, 0, 0, 700)},
    {size = UDim2.new(0, 180, 0, 400), canvas = UDim2.new(0, 0, 0, 520)},
}
local currentMenuSizeIndex = 1

local sizeBtn = Instance.new("TextButton")
sizeBtn.Size = UDim2.new(0, 36, 0, 36)
sizeBtn.Position = UDim2.new(1, -42, 0, 3)
sizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
sizeBtn.TextColor3 = Color3.new(1, 1, 1)
sizeBtn.Font = Enum.Font.GothamBold
sizeBtn.TextSize = 22
sizeBtn.Text = "⚙️"
sizeBtn.Parent = menu
sizeBtn.Name = "SizeButton"
local sizeBtnCorner = Instance.new("UICorner")
sizeBtnCorner.CornerRadius = UDim.new(1, 0)
sizeBtnCorner.Parent = sizeBtn

local function changeMenuSize()
    currentMenuSizeIndex = currentMenuSizeIndex % #menuSizeOptions + 1
    local opt = menuSizeOptions[currentMenuSizeIndex]
    menu.Size = opt.size
    menu.CanvasSize = opt.canvas
    -- Ajustar elementos
    sizeBtn.Position = UDim2.new(1, -42, 0, 3)
    title.Size = UDim2.new(1, 0, 0, 42)
    -- Reposicionar todos os elementos filhos (exceto engrenagem e título)
    local y = 50
    for _, v in ipairs(menu:GetChildren()) do
        if v:IsA("Frame") and v.Name ~= "FOVFrame" and v.Name ~= "RapidFireFrame" then
            v.Position = UDim2.new(0, 10, 0, y)
            y = y + 48
        end
    end
    -- FOV e RapidFire
    if menu:FindFirstChild("FOVFrame") then
        menu.FOVFrame.Position = UDim2.new(0, 10, 0, y)
        y = y + 48
    end
    if menu:FindFirstChild("RapidFireFrame") then
        menu.RapidFireFrame.Position = UDim2.new(0, 10, 0, y)
    end
end

sizeBtn.MouseButton1Click:Connect(changeMenuSize)

-- Drag responsivo (respeita topo da tela, não centraliza mais)
local dragging = false
local dragStart, startPos
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = menu.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
title.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        local newX = math.clamp(startPos.X.Offset + delta.X, 0, Camera.ViewportSize.X - menu.AbsoluteSize.X)
        local newY = math.clamp(startPos.Y.Offset + delta.Y, 0, Camera.ViewportSize.Y - 40)
        menu.Position = UDim2.new(0, newX, 0, newY)
    end
end)

-- Função para criar toggles responsivos
local function createToggle(text, flagName, y)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 40)
    frame.Position = UDim2.new(0, 10, 0, y)
    frame.BackgroundTransparency = 1
    frame.Parent = menu
    frame.Name = text

    local label = Instance.new("TextLabel")
    label.Text = text
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.Gotham
    label.TextSize = 18
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 50, 0, 25)
    toggleBtn.Position = UDim2.new(0.75, 0, 0.25, 0)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    toggleBtn.AutoButtonColor = false
    toggleBtn.Text = _G[flagName] and "ON" or "OFF"
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextColor3 = Color3.new(1, 1, 1)
    toggleBtn.TextSize = 16
    toggleBtn.Parent = frame
    toggleBtn.Name = "ToggleButton"

    local cornerBtn = Instance.new("UICorner")
    cornerBtn.CornerRadius = UDim.new(0, 8)
    cornerBtn.Parent = toggleBtn

    local toggleCircle = Instance.new("Frame")
    toggleCircle.Size = UDim2.new(0, 20, 0, 20)
    toggleCircle.Position = _G[flagName] and UDim2.new(0, 25, 0.15, 0) or UDim2.new(0, 5, 0.15, 0)
    toggleCircle.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    toggleCircle.Parent = toggleBtn
    local cornerCircle = Instance.new("UICorner")
    cornerCircle.CornerRadius = UDim.new(1, 0)
    cornerCircle.Parent = toggleCircle

    local function updateToggleState(isOn)
        toggleBtn.Text = isOn and "ON" or "OFF"
        local color = isOn and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(70, 70, 70)
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
        TweenService:Create(toggleCircle, TweenInfo.new(0.2), {Position = isOn and UDim2.new(0, 25, 0.15, 0) or UDim2.new(0, 5, 0.15, 0)}):Play()
    end

    toggleBtn.MouseButton1Click:Connect(function()
        _G[flagName] = not _G[flagName]
        updateToggleState(_G[flagName])
        -- Cheats: restaurar valores padrões ao desligar
        if flagName == "noRecoilEnabled" or flagName == "infiniteAmmoEnabled" or flagName == "instantReloadEnabled" then
            local char = LocalPlayer.Character
            if char then
                for _, tool in pairs(char:GetChildren()) do
                    if tool:IsA("Tool") then
                        if not _G[flagName] then
                            restoreDefaultWeaponValues(tool)
                        end
                    end
                end
            end
        end
        if flagName == "FOV_VISIBLE" then
            -- nada extra, só alterna
        end
    end)
    updateToggleState(_G[flagName])
    return frame
end

-- Layout dos toggles
local y = 50
local togglesList = {
    {"Aimbot Auto", "aimbotAutoEnabled"},
    {"Aimbot Manual", "aimbotManualEnabled"},
    {"ESP Inimigos", "espEnemiesEnabled"},
    {"ESP Aliados", "espAlliesEnabled"},
    {"No Recoil", "noRecoilEnabled"},
    {"Munição Infinita", "infiniteAmmoEnabled"},
    {"Recarga Instantânea", "instantReloadEnabled"},
}
for _, v in ipairs(togglesList) do
    local frame = createToggle(v[1], v[2], y)
    y = y + 48
end

-- Toggle Mostrar FOV
local fovToggle = createToggle("Mostrar FOV", "FOV_VISIBLE", y)
y = y + 48

-- FOV: apenas botões + e - centralizados
local fovFrame = Instance.new("Frame")
fovFrame.Size = UDim2.new(1, -20, 0, 40)
fovFrame.Position = UDim2.new(0, 10, 0, y)
fovFrame.BackgroundTransparency = 1
fovFrame.Parent = menu
fovFrame.Name = "FOVFrame"

local minusBtn = Instance.new("TextButton")
minusBtn.Size = UDim2.new(0, 40, 0, 30)
minusBtn.Position = UDim2.new(0.25, -20, 0.25, 0)
minusBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
minusBtn.TextColor3 = Color3.new(1, 1, 1)
minusBtn.Font = Enum.Font.GothamBold
minusBtn.TextSize = 22
minusBtn.Text = "-"
minusBtn.Parent = fovFrame
local minusCorner = Instance.new("UICorner")
minusCorner.CornerRadius = UDim.new(1, 0)
minusCorner.Parent = minusBtn

local plusBtn = Instance.new("TextButton")
plusBtn.Size = UDim2.new(0, 40, 0, 30)
plusBtn.Position = UDim2.new(0.75, -20, 0.25, 0)
plusBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
plusBtn.TextColor3 = Color3.new(1, 1, 1)
plusBtn.Font = Enum.Font.GothamBold
plusBtn.TextSize = 22
plusBtn.Text = "+"
plusBtn.Parent = fovFrame
local plusCorner = Instance.new("UICorner")
plusCorner.CornerRadius = UDim.new(1, 0)
plusCorner.Parent = plusBtn

minusBtn.MouseButton1Click:Connect(function()
    _G.FOV_RADIUS = math.clamp(_G.FOV_RADIUS - 5, 10, 300)
end)
plusBtn.MouseButton1Click:Connect(function()
    _G.FOV_RADIUS = math.clamp(_G.FOV_RADIUS + 5, 10, 300)
end)
y = y + 48

-- RAPID FIRE toggle e botão de modo
local rapidFireFrame = Instance.new("Frame")
rapidFireFrame.Size = UDim2.new(1, -20, 0, 80)
rapidFireFrame.Position = UDim2.new(0, 10, 0, y)
rapidFireFrame.BackgroundTransparency = 1
rapidFireFrame.Parent = menu
rapidFireFrame.Name = "RapidFireFrame"

local rapidToggle = createToggle("RAPID FIRE", "rapidFireEnabled", 0)
rapidToggle.Parent = rapidFireFrame
rapidToggle.Position = UDim2.new(0, 0, 0, 0)

local fireRateOptions = {nil, 200, 500, 999999999999}
local fireRateNames = {"Padrão", "Legit", "Médio", "Agressivo"}
local fireRateBtn = Instance.new("TextButton")
fireRateBtn.Size = UDim2.new(0, 120, 0, 30)
fireRateBtn.Position = UDim2.new(0.5, -60, 0, 42)
fireRateBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
fireRateBtn.TextColor3 = Color3.new(1, 1, 1)
fireRateBtn.Font = Enum.Font.GothamBold
fireRateBtn.TextSize = 18
fireRateBtn.Text = fireRateNames[1]
fireRateBtn.Parent = rapidFireFrame
local fireRateCorner = Instance.new("UICorner")
fireRateCorner.CornerRadius = UDim.new(1, 0)
fireRateCorner.Parent = fireRateBtn

local currentFireRateIndex = 1
fireRateBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    currentFireRateIndex = (currentFireRateIndex % #fireRateOptions) + 1
    local selected = fireRateOptions[currentFireRateIndex]
    fireRateBtn.Text = fireRateNames[currentFireRateIndex]
    _G.rateOfFire = selected
    if char then
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                storeDefaultWeaponValues(tool)
                if selected == nil then
                    -- Volta pro padrão
                    restoreDefaultWeaponValues(tool)
                else
                    tool:SetAttribute("rateOfFire", selected)
                end
            end
        end
    end
end)

-- Ao ativar/desativar RAPID FIRE, aplica ou restaura o valor
rapidToggle.ToggleButton.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    if char then
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                storeDefaultWeaponValues(tool)
                if _G.rapidFireEnabled and _G.rateOfFire then
                    tool:SetAttribute("rateOfFire", _G.rateOfFire)
                else
                    restoreDefaultWeaponValues(tool)
                end
            end
        end
    end
end)

-- Atualiza layout ao trocar tamanho
changeMenuSize()

-- ...restante do seu código (aimbot, ESP, cheats, etc)...
-- Certifique-se de usar storeDefaultWeaponValues(tool) ao equipar arma nova
LocalPlayer.CharacterAdded:Connect(function(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            storeDefaultWeaponValues(child)
        end
    end)
end)
if LocalPlayer.Character then
    for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
        if tool:IsA("Tool") then
            storeDefaultWeaponValues(tool)
        end
    end
end

-- O resto do seu código de cheats, aimbot, ESP, etc, pode ser mantido igual, apenas usando storeDefaultWeaponValues/restoreDefaultWeaponValues