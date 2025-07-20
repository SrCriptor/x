--[[
    Krypton Tools v1.0
    Autor: SrCriptor
    Estrutura modularizada com OrionLib + botão de minimizar/maximizar arrastável
--]]

-- Carregar OrionLib
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jensonhirst/Orion/main/source"))()

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
_G.espEnemies = false
_G.espAllies = false

-- GUI OrionLib
local Window = OrionLib:MakeWindow({
    Name = "Krypton Tools",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "KryptonConfig"
})

-- Minimizar/Maximizar
local KryptonGui = Instance.new("ScreenGui", game.CoreGui)
KryptonGui.Name = "KryptonToggleUI"
KryptonGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MinButton = Instance.new("TextButton")
MinButton.Size = UDim2.new(0, 30, 0, 30)
MinButton.Position = UDim2.new(1, -35, 0, 5)
MinButton.Text = "-"
MinButton.Parent = Window.Gui
MinButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
MinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinButton.BorderSizePixel = 0
MinButton.AutoButtonColor = true
MinButton.MouseButton1Click:Connect(function()
    Window:Destroy() -- Fecha menu
    KryptonGui.Enabled = true
end)

local Icon = Instance.new("ImageButton")
Icon.Size = UDim2.new(0, 32, 0, 32)
Icon.Position = UDim2.new(0, 10, 0, 10)
Icon.BackgroundTransparency = 1
Icon.Image = "https://raw.githubusercontent.com/SrCriptor/x/refs/heads/main/2.ico"
Icon.Parent = KryptonGui
KryptonGui.Enabled = false

-- Arrastar ícone
local dragging, dragInput, dragStart, startPos
Icon.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Icon.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

Icon.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Icon.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Ao clicar no ícone, reabre o menu
Icon.MouseButton1Click:Connect(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/SrCriptor/SeuRepositorio/main/loader.lua"))() -- substitua com seu loader real
    KryptonGui.Enabled = false
end)

-- Gui Principal Tabs
local AimbotTab = Window:MakeTab({
    Name = "Aimbot",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local EspTab = Window:MakeTab({
    Name = "ESP",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local FovTab = Window:MakeTab({
    Name = "FOV",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Toggles Aimbot
AimbotTab:AddToggle({
    Name = "Aimbot Automático",
    Default = false,
    Callback = function(Value)
        _G.aimbotAutoEnabled = Value
    end
})

AimbotTab:AddToggle({
    Name = "Aimbot Manual (botão)",
    Default = false,
    Callback = function(Value)
        _G.aimbotManualEnabled = Value
    end
})

-- Toggles ESP
EspTab:AddToggle({
    Name = "ESP Inimigos",
    Default = false,
    Callback = function(Value)
        _G.espEnemies = Value
    end
})

EspTab:AddToggle({
    Name = "ESP Aliados",
    Default = false,
    Callback = function(Value)
        _G.espAllies = Value
    end
})

-- Slider FOV
FovTab:AddSlider({
    Name = "Tamanho do FOV",
    Min = 20,
    Max = 150,
    Default = _G.FOV_RADIUS,
    Increment = 1,
    ValueName = "px",
    Callback = function(Value)
        _G.FOV_RADIUS = Value
    end
})

FovTab:AddToggle({
    Name = "Exibir Círculo FOV",
    Default = true,
    Callback = function(Value)
        _G.FOV_VISIBLE = Value
    end
})
