-- Serviços principais
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Configurações globais (flags)
_G.FOV_RADIUS = 65
_G.FOV_VISIBLE = true
_G.aimbotAutoEnabled = false
_G.aimbotManualEnabled = false
_G.espEnemiesEnabled = true
_G.espAlliesEnabled = false
_G.instareload = false
_G.noRecol = false
_G.infiniteAmmo = false

local shooting = false
local aiming = false
local dragging = false
local dragStart, startPos
local currentTarget = nil

-- Referência aos botões mobile
local aimButton = LocalPlayer.PlayerScripts:WaitForChild("Assets")
    .Ui.TouchInputController.BlasterTouchGui.Buttons:WaitForChild("AimButton")
local shootButton = LocalPlayer.PlayerScripts:WaitForChild("Assets")
    .Ui.TouchInputController.BlasterTouchGui.Buttons:WaitForChild("ShootButton")

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "MobileAimbotGUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 220, 0, 280)
panel.Position = UDim2.new(0, 20, 0.5, -140)
panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
panel.BackgroundTransparency = 0.2
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = gui

-- Drag
panel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = panel.Position
    end
end)

panel.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- Botão toggle
local function createToggleButton(text, yPos, flagName, exclusiveFlag)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 30)
    button.Position = UDim2.new(0, 10, 0, yPos)
    button.Text = text .. ": OFF"
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 16
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Parent = panel

    button.MouseButton1Click:Connect(function()
        _G[flagName] = not _G[flagName]
        if exclusiveFlag and _G[flagName] then
            _G[exclusiveFlag] = false
        end
        button.Text = text .. (_G[flagName] and ": ON" or ": OFF")

        if exclusiveFlag then
            for _, sibling in pairs(panel:GetChildren()) do
                if sibling:IsA("TextButton") and sibling ~= button then
                    local siblingText = sibling.Text:lower()
                    local exclusiveFlagText = exclusiveFlag:gsub("([A-Z])", " %1"):lower()
                    exclusiveFlagText = exclusiveFlagText:gsub("^%l", string.upper)
                    if siblingText:find(exclusiveFlagText) then
                        sibling.Text = sibling.Text:sub(1, sibling.Text:find(":")) .. (_G[exclusiveFlag] and " ON" or " OFF")
                    end
                end
            end
        end

        if flagName == "instareload" or flagName == "noRecol" or flagName == "infiniteAmmo" then
            local char = LocalPlayer.Character
            if char then
                local tool = char:FindFirstChildWhichIsA("Tool")
                if tool then
                    applyWeaponMods(tool)
                end
            end
        end
    end)
    return button
end

-- FOV Ajuste
local function createFOVAdjustButton(text, yPos, delta)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.5, -15, 0, 30)
    button.Position = UDim2.new(text == "- FOV" and 0 or 0.5, 10, 0, yPos)
    button.Text = text
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 16
    button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Parent = panel
    button.MouseButton1Click:Connect(function()
        _G.FOV_RADIUS = math.clamp(_G.FOV_RADIUS + delta, 10, 300)
    end)
end

-- Minimizar painel
local minimized = false
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 40, 0, 30)
toggleButton.Position = UDim2.new(1, -50, 0, 5)
toggleButton.Text = "🔽"
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 18
toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Parent = panel

toggleButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    toggleButton.Text = minimized and "🔼" or "🔽"
    for _, v in pairs(panel:GetChildren()) do
        if v:IsA("TextButton") and v ~= toggleButton then
            v.Visible = not minimized
        end
    end
    panel.Size = minimized and UDim2.new(0, 60, 0, 40) or UDim2.new(0, 220, 0, 280)
    panel.BackgroundTransparency = minimized and 1 or 0.2
    toggleButton.Position = minimized and UDim2.new(0, 10, 0, 5) or UDim2.new(1, -50, 0, 5)
end)

-- Botões do menu
createToggleButton("Aimbot Auto", 40, "aimbotAutoEnabled", "aimbotManualEnabled")
createToggleButton("Aimbot Manual", 75, "aimbotManualEnabled", "aimbotAutoEnabled")
createToggleButton("ESP Inimigos", 110, "espEnemiesEnabled")
createToggleButton("ESP Aliados", 145, "espAlliesEnabled")
createToggleButton("Instant Reload", 180, "instareload")
createToggleButton("No Recoil", 215, "noRecol")
createToggleButton("Infinite Ammo", 250, "infiniteAmmo")
createToggleButton("Mostrar FOV", 285, "FOV_VISIBLE")
createFOVAdjustButton("- FOV", 320, -5)
createFOVAdjustButton("+ FOV", 320, 5)

-- Aplicação de modificadores
function applyWeaponMods(tool)
    if not tool then return end

    if _G.instareload then
        tool:SetAttribute("reloadTime", 0)
    end
    if _G.noRecol then
        tool:SetAttribute("recoilAimReduction", Vector2.new(0, 0))
        tool:SetAttribute("recoilMax", Vector2.new(0, 0))
        tool:SetAttribute("recoilMin", Vector2.new(0, 0))
    end
    if _G.infiniteAmmo then
        tool:SetAttribute("_ammo", math.huge)
        tool:SetAttribute("magazineSize", math.huge)

        -- Exibição visual fixa de 200 balas
        local hud = tool:FindFirstChild("AmmoDisplay")
        if hud and hud:IsA("TextLabel") then
            hud.Text = "200"
        end
    end
end

-- Círculo FOV
local fovCircle = Drawing.new("Circle")
fovCircle.Transparency = 0.2
fovCircle.Thickness = 1.5
fovCircle.Filled = false
fovCircle.Color = Color3.new(1, 1, 1)

RunService.RenderStepped:Connect(function()
    fovCircle.Radius = _G.FOV_RADIUS
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    fovCircle.Visible = _G.FOV_VISIBLE
end)

return gui
