-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Bandeiras globais padrão
_G.FOV_RADIUS = 65
_G.FOV_VISIBLE = true
_G.aimbotAutoEnabled = false
_G.aimbotManualEnabled = false
_G.espEnemiesEnabled = true
_G.espAlliesEnabled = false
_G.noRecoilEnabled = true
_G.infiniteAmmoEnabled = true
_G.instantReloadEnabled = true

-- Criação da GUI principal
local gui = Instance.new("ScreenGui")
gui.Name = "MobileAimbotGUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local menu = Instance.new("Frame")
menu.Size = UDim2.new(0, 220, 0, 360) -- altura reduzida
menu.AnchorPoint = Vector2.new(0, 0)
menu.Position = UDim2.new(0, 20, 0, 100)
menu.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
menu.BackgroundTransparency = 0.1
menu.BorderSizePixel = 0
menu.ClipsDescendants = true
menu.Parent = gui
menu.Name = "MenuPrincipal"
menu.Active = true

local uicorner = Instance.new("UICorner")
uicorner.CornerRadius = UDim.new(0, 12)
uicorner.Parent = menu

-- Título
local title = Instance.new("TextLabel")
title.Text = "Menu Aimbot e ESP"
title.Size = UDim2.new(1, 0, 0, 36)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.Parent = menu
title.Name = "Title"
title.AnchorPoint = Vector2.new(0, 0)

-- Botão de minimizar
local toggleVisibilityBtn = Instance.new("TextButton")
toggleVisibilityBtn.Size = UDim2.new(0, 40, 0, 30)
toggleVisibilityBtn.Position = UDim2.new(1, -45, 0, 3)
toggleVisibilityBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleVisibilityBtn.TextColor3 = Color3.new(1,1,1)
toggleVisibilityBtn.Font = Enum.Font.GothamBold
toggleVisibilityBtn.TextSize = 20
toggleVisibilityBtn.Text = "–"
toggleVisibilityBtn.Parent = menu
toggleVisibilityBtn.Name = "ToggleVisibility"

local minimized = false
toggleVisibilityBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        menu.Size = UDim2.new(0, 220, 0, 36)
        toggleVisibilityBtn.Text = "+"
    else
        menu.Size = UDim2.new(0, 220, 0, 360)
        toggleVisibilityBtn.Text = "–"
    end
end)

-- Função para criar toggles
local function createToggle(text, y)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 30)
    frame.Position = UDim2.new(0, 10, 0, y)
    frame.BackgroundTransparency = 1
    frame.Parent = menu

    local label = Instance.new("TextLabel")
    label.Text = text
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.Gotham
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 50, 0, 25)
    toggleBtn.Position = UDim2.new(0.7, 5, 0, 2)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    toggleBtn.AutoButtonColor = false
    toggleBtn.Text = "DESLIGADO"
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextColor3 = Color3.new(1, 1, 1)
    toggleBtn.TextSize = 14
    toggleBtn.Parent = frame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = toggleBtn

    local toggleCircle = Instance.new("Frame")
    toggleCircle.Size = UDim2.new(0, 20, 0, 20)
    toggleCircle.Position = UDim2.new(0, 5, 0.15, 0)
    toggleCircle.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    toggleCircle.Parent = toggleBtn

    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = toggleCircle

    toggleBtn.MouseEnter:Connect(function()
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(90, 90, 90)}):Play()
    end)

    toggleBtn.MouseLeave:Connect(function()
        local color = toggleBtn.Text == "LIGADO" and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(70, 70, 70)
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
    end)

    local debounce = false
    local function updateToggleState(isOn)
        if debounce then return end
        debounce = true
        if isOn then
            toggleBtn.Text = "LIGADO"
            TweenService:Create(toggleBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(0, 170, 0)}):Play()
            TweenService:Create(toggleCircle, TweenInfo.new(0.3), {Position = UDim2.new(0, 25, 0.15, 0)}):Play()
        else
            toggleBtn.Text = "DESLIGADO"
            TweenService:Create(toggleBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(70, 70, 70)}):Play()
            TweenService:Create(toggleCircle, TweenInfo.new(0.3), {Position = UDim2.new(0, 5, 0.15, 0)}):Play()
        end
        task.wait(0.3)
        debounce = false
    end

    return {
        frame = frame,
        toggleBtn = toggleBtn,
        update = updateToggleState,
        getState = function() return toggleBtn.Text == "LIGADO" end
    }
end

-- CONTINUA NA PARTE 2
