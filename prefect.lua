-- LocalScript dentro de StarterGui ou ScreenGui
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Criando a ScreenGui principal
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TrainerMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- Detecção de Plataforma para Ajuste de Escala
local isMobile = UserInputService.TouchEnabled
local menuSize = isMobile and UDim2.new(0, 300, 0, 350) or UDim2.new(0, 250, 0, 320)

-- Frame Principal
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = menuSize
MainFrame.Position = UDim2.new(0.5, -menuSize.X.Offset/2, 0.5, -menuSize.Y.Offset/2)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true -- Nota: Draggable é legado, mas funcional para exemplos simples
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

-- Título
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "HUB PROFISSIONAL v1.0"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.Parent = Title

-- Container de Opções (Lista)
local Container = Instance.new("ScrollingFrame")
Container.Size = UDim2.new(1, -20, 1, -60)
Container.Position = UDim2.new(0, 10, 0, 50)
Container.BackgroundTransparency = 1
Container.ScrollBarThickness = 2
Container.Parent = MainFrame

local UIList = Instance.new("UIListLayout")
UIList.Padding = UDim.new(0, 8)
UIList.Parent = Container

-- Função para criar Botões de On/Off
local function createToggleButton(name, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(180, 50, 50) -- Inicial OFF (Vermelho)
    btn.Text = name .. ": OFF"
    btn.Font = Enum.Font.Gotham
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.AutoButtonColor = true
    btn.Parent = Container
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    
    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = name .. (state and ": ON" or ": OFF")
        btn.BackgroundColor3 = state and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50)
        callback(state)
    end)
end

-- Seção de FOV
local function createFOVControl()
    local fovFrame = Instance.new("Frame")
    fovFrame.Size = UDim2.new(1, 0, 0, 60)
    fovFrame.BackgroundTransparency = 1
    fovFrame.Parent = Container

    local fovLabel = Instance.new("TextLabel")
    fovLabel.Size = UDim2.new(1, 0, 0, 25)
    fovLabel.Text = "FOV: 90"
    fovLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    fovLabel.BackgroundTransparency = 1
    fovLabel.Font = Enum.Font.GothamSemibold
    fovLabel.Parent = fovFrame

    local currentFOV = 90
    
    local function updateFOV(val)
        currentFOV = math.clamp(currentFOV + val, 30, 120)
        fovLabel.Text = "FOV: " .. currentFOV
        workspace.CurrentCamera.FieldOfView = currentFOV
    end

    local minusBtn = Instance.new("TextButton")
    minusBtn.Size = UDim2.new(0.45, 0, 0, 30)
    minusBtn.Position = UDim2.new(0, 0, 0, 30)
    minusBtn.Text = "-"
    minusBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
    minusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minusBtn.Parent = fovFrame
    minusBtn.MouseButton1Click:Connect(function() updateFOV(-5) end)

    local plusBtn = Instance.new("TextButton")
    plusBtn.Size = UDim2.new(0.45, 0, 0, 30)
    plusBtn.Position = UDim2.new(0.55, 0, 0, 30)
    plusBtn.Text = "+"
    plusBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
    plusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    plusBtn.Parent = fovFrame
    plusBtn.MouseButton1Click:Connect(function() updateFOV(5) end)
end

-- Adicionando as funções ao Menu
createToggleButton("ESP Aliado", function(state) print("ESP Aliado:", state) end)
createToggleButton("ESP Inimigo", function(state) print("ESP Inimigo:", state) end)
createToggleButton("Wallhack Neon", function(state) print("Wallhack:", state) end)
createToggleButton("Aimbot", function(state) print("Aimbot:", state) end)
createToggleButton("Aimbot Legit", function(state) print("Aimbot Legit:", state) end)
createFOVControl()

print("Menu carregado para: " .. (isMobile and "Mobile" or "PC"))
