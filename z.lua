-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Bandeiras globais
_G.FOV_RADIUS = 65
_G.FOV_VISIBLE = true
_G.aimbotAutoEnabled = false
_G.aimbotManualEnabled = false
_G.espEnemiesEnabled = true
_G.espAlliesEnabled = false
_G.noRecoilEnabled = true
_G.infiniteAmmoEnabled = true
_G.instantReloadEnabled = true

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "MobileAimbotGUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local menu = Instance.new("Frame")
menu.Size = UDim2.new(0, 220, 0, 360)
menu.AnchorPoint = Vector2.new(0, 0)
menu.Position = UDim2.new(0, 20, 0, 100)
menu.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
menu.BackgroundTransparency = 0.1
menu.BorderSizePixel = 0
menu.ClipsDescendants = true
menu.Parent = gui
menu.Name = "MainMenu"
menu.Active = true

local uicorner = Instance.new("UICorner")
uicorner.CornerRadius = UDim.new(0, 12)
uicorner.Parent = menu

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

local toggles = {}
local function bindToggle(text, flagName, y)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 30)
    frame.Position = UDim2.new(0, 10, 0, y)
    frame.BackgroundTransparency = 1
    frame.Parent = menu

    local label = Instance.new("TextLabel")
    label.Text = text
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.Gotham
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 60, 0, 25)
    button.Position = UDim2.new(1, -65, 0, 2)
    button.BackgroundColor3 = _G[flagName] and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(70, 70, 70)
    button.Text = _G[flagName] and "ON" or "OFF"
    button.Font = Enum.Font.GothamBold
    button.TextColor3 = Color3.new(1,1,1)
    button.TextSize = 14
    button.Parent = frame

    button.MouseButton1Click:Connect(function()
        _G[flagName] = not _G[flagName]
        button.Text = _G[flagName] and "ON" or "OFF"
        button.BackgroundColor3 = _G[flagName] and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(70, 70, 70)
    end)

    toggles[flagName] = button
end

-- Bind toggles
bindToggle("Aimbot Automático", "aimbotAutoEnabled", 40)
bindToggle("Manual do Aimbot", "aimbotManualEnabled", 70)
bindToggle("ESP Inimigos", "espEnemiesEnabled", 100)
bindToggle("ESP Aliados", "espAlliesEnabled", 130)
bindToggle("Sem recuo", "noRecoilEnabled", 160)
bindToggle("Munição Infinita", "infiniteAmmoEnabled", 190)
bindToggle("Recarga Instantânea", "instantReloadEnabled", 220)

-- FOV
local fovLabel = Instance.new("TextLabel")
fovLabel.Text = "FOV: ".._G.FOV_RADIUS
fovLabel.Size = UDim2.new(1, -20, 0, 20)
fovLabel.Position = UDim2.new(0, 10, 0, 260)
fovLabel.BackgroundTransparency = 1
fovLabel.TextColor3 = Color3.new(1,1,1)
fovLabel.Font = Enum.Font.GothamBold
fovLabel.TextSize = 16
fovLabel.TextXAlignment = Enum.TextXAlignment.Center
fovLabel.Parent = menu

local function updateFOVLabel()
    fovLabel.Text = "FOV: ".._G.FOV_RADIUS
end

local function createFOVButton(text, xPos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 50, 0, 30)
    btn.Position = UDim2.new(0, xPos, 0, 290)
    btn.BackgroundColor3 = Color3.fromRGB(70,70,70)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 20
    btn.Text = text
    btn.Parent = menu

    btn.MouseButton1Click:Connect(function()
        if text == "+" then
            _G.FOV_RADIUS = math.clamp(_G.FOV_RADIUS + 5, 10, 300)
        else
            _G.FOV_RADIUS = math.clamp(_G.FOV_RADIUS - 5, 10, 300)
        end
        updateFOVLabel()
    end)
end

createFOVButton("-", 55)
createFOVButton("+", 135)

updateFOVLabel()

-- Aplicar atributos na arma
local function applyGunAttributes(tool)
    if not tool or not tool:IsA("Tool") then return end

    if _G.noRecoilEnabled then
        tool:SetAttribute("recoilAimReduction", Vector2.new(0, 0))
        tool:SetAttribute("recoilMax", Vector2.new(0, 0))
        tool:SetAttribute("recoilMin", Vector2.new(0, 0))
        tool:SetAttribute("spread", 0)
        if tool:FindFirstChild("Recoil") then
            tool.Recoil.Value = 0
        end
    end

    if _G.infiniteAmmoEnabled then
        tool:SetAttribute("_ammo", 200)
        tool:SetAttribute("magazineSize", 200)
        if tool:FindFirstChild("Ammo") then
            tool.Ammo.Value = math.huge
        end
    end

    if _G.instantReloadEnabled then
        tool:SetAttribute("reloadTime", 0)
        if tool:FindFirstChild("ReloadTime") then
            tool.ReloadTime.Value = 0
        end
    end
end

local function onCharacterAdded(character)
    for _, tool in pairs(character:GetChildren()) do
        if tool:IsA("Tool") then
            applyGunAttributes(tool)
        end
    end

    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait(0.1)
            applyGunAttributes(child)
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

if LocalPlayer.Character then
    onCharacterAdded(LocalPlayer.Character)
end

LocalPlayer.CharacterRemoving:Connect(function()
    currentTarget = nil
end)
