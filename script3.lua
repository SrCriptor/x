local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Flags globais ativadas para teste
_G.FOV_RADIUS = 65
_G.FOV_VISIBLE = true
_G.aimbotAutoEnabled = false
_G.aimbotManualEnabled = false
_G.espEnemiesEnabled = true
_G.espAlliesEnabled = false
_G.infiniteAmmo = true
_G.instantReload = true
_G.noRecoil = true
_G.noSpread = true
_G.fastShoot = false

local dragging = false
local dragStart, startPos
local currentPage = 1

local gui = Instance.new("ScreenGui")
gui.Name = "MobileAimbotGUI"
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Enabled = true -- importante para garantir que esteja ativo

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 220, 0, 280)
panel.Position = UDim2.new(0, 20, 0.5, -140)
panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
panel.BackgroundTransparency = 0.2
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = gui
panel.Visible = true

-- Drag da interface
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

local buttonsPage1 = {}
local buttonsPage2 = {}

local function createToggleButton(text, yPos, flagName, exclusiveFlag, page)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 30)
    button.Position = UDim2.new(0, 10, 0, yPos)
    button.Text = text .. (_G[flagName] and ": ON" or ": OFF")
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 16
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Visible = page == currentPage
    button.Parent = panel

    table.insert(page == 1 and buttonsPage1 or buttonsPage2, button)

    button.MouseButton1Click:Connect(function()
        _G[flagName] = not _G[flagName]
        if exclusiveFlag and _G[flagName] then
            _G[exclusiveFlag] = false
        end
        button.Text = text .. (_G[flagName] and ": ON" or ": OFF")
    end)
end

local function createFOVAdjustButton(text, yPos, delta)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.5, -15, 0, 30)
    button.Position = UDim2.new(text == "- FOV" and 0 or 0.5, 10, 0, yPos)
    button.Text = text
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 16
    button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Visible = currentPage == 1
    button.Parent = panel
    table.insert(buttonsPage1, button)

    button.MouseButton1Click:Connect(function()
        _G.FOV_RADIUS = math.clamp(_G.FOV_RADIUS + delta, 10, 300)
    end)
end

local function updatePage(page)
    currentPage = page
    for _, b in pairs(buttonsPage1) do b.Visible = page == 1 end
    for _, b in pairs(buttonsPage2) do b.Visible = page == 2 end
end

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 40, 0, 30)
toggleButton.Position = UDim2.new(1, -50, 0, 5)
toggleButton.Text = "🔽"
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 18
toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Parent = panel

local page1Btn = Instance.new("TextButton")
page1Btn.Size = UDim2.new(0.5, -10, 0, 30)
page1Btn.Position = UDim2.new(0, 10, 1, -35)
page1Btn.Text = "1/2"
page1Btn.Font = Enum.Font.SourceSansBold
page1Btn.TextSize = 16
page1Btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
page1Btn.TextColor3 = Color3.new(1, 1, 1)
page1Btn.Parent = panel

local page2Btn = Instance.new("TextButton")
page2Btn.Size = UDim2.new(0.5, -10, 0, 30)
page2Btn.Position = UDim2.new(0.5, 0, 1, -35)
page2Btn.Text = "2/2"
page2Btn.Font = Enum.Font.SourceSansBold
page2Btn.TextSize = 16
page2Btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
page2Btn.TextColor3 = Color3.new(1, 1, 1)
page2Btn.Parent = panel

page1Btn.MouseButton1Click:Connect(function()
    updatePage(1)
end)

page2Btn.MouseButton1Click:Connect(function()
    updatePage(2)
end)

toggleButton.MouseButton1Click:Connect(function()
    local minimized = toggleButton.Text == "🔽"
    toggleButton.Text = minimized and "🔼" or "🔽"
    if minimized then
        panel.Size = UDim2.new(0, 60, 0, 40)
        panel.BackgroundTransparency = 1
        toggleButton.Position = UDim2.new(0, 10, 0, 5)
        for _, v in pairs(panel:GetChildren()) do
            if v:IsA("TextButton") and v ~= toggleButton then
                v.Visible = false
            end
        end
    else
        panel.Size = UDim2.new(0, 220, 0, 280)
        panel.BackgroundTransparency = 0.2
        toggleButton.Position = UDim2.new(1, -50, 0, 5)
        updatePage(currentPage)
    end
end)

local y = 40
local spacing = 35
createToggleButton("Aimbot Auto", y, "aimbotAutoEnabled", "aimbotManualEnabled", 1)
y = y + spacing
createToggleButton("Aimbot Manual", y, "aimbotManualEnabled", "aimbotAutoEnabled", 1)
y = y + spacing
createToggleButton("ESP Inimigos", y, "espEnemiesEnabled", nil, 1)
y = y + spacing
createToggleButton("ESP Aliados", y, "espAlliesEnabled", nil, 1)
y = y + spacing
createToggleButton("Mostrar FOV", y, "FOV_VISIBLE", nil, 1)
createFOVAdjustButton("- FOV", y, -5)
createFOVAdjustButton("+ FOV", y, 5)

local y2 = 40
createToggleButton("Infinite Ammo", y2, "infiniteAmmo", nil, 2)
y2 = y2 + spacing
createToggleButton("Instant Reload", y2, "instantReload", nil, 2)
y2 = y2 + spacing
createToggleButton("No Recoil", y2, "noRecoil", nil, 2)
y2 = y2 + spacing
createToggleButton("No Spread", y2, "noSpread", nil, 2)
y2 = y2 + spacing
createToggleButton("Fast Shoot", y2, "fastShoot", nil, 2)

updatePage(currentPage)

RunService.RenderStepped:Connect(function()
    if _G.infiniteAmmo then
        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool and tool:FindFirstChild("Ammo") then
            tool.Ammo.Value = 999
        end
    end

    if _G.instantReload then
        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool and tool:FindFirstChild("Reloading") then
            tool.Reloading.Value = false
        end
    end

    if _G.noRecoil then
        Camera.CFrame = Camera.CFrame
    end

    if _G.fastShoot then
        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool and tool:FindFirstChild("FireRate") then
            tool.FireRate.Value = 0.01
        end
    end
end)
