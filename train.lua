-- 🔥 ANTI-DUPLICAÇÃO
if _G.MatrixUI_Loaded then
    if _G.MatrixUI_Cleanup then
        pcall(_G.MatrixUI_Cleanup)
    end
end
_G.MatrixUI_Loaded = true

-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- CONFIG
_G.Config = {
    Aimbot = "OFF",
    ESP_Enemy = true,
    ESP_Ally = false,

    ESP_Box = false,
    ESP_Name = false,
    ESP_Distance = false,
    ESP_Line = false
}

-- GUI
local gui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
gui.Name = "MatrixPremiumUI"

-- PANEL
local panel = Instance.new("Frame", gui)
panel.Size = UDim2.new(0,300,0,350)
panel.Position = UDim2.new(0,20,0.5,-175)
panel.BackgroundColor3 = Color3.fromRGB(10,15,10)
panel.Active = true
Instance.new("UICorner", panel)

-- DRAG FIX
local dragging, dragStart, startPos

panel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = panel.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- LAYOUT
local layout = Instance.new("UIListLayout", panel)
layout.Padding = UDim.new(0,6)

local padding = Instance.new("UIPadding", panel)
padding.PaddingTop = UDim.new(0,10)
padding.PaddingLeft = UDim.new(0,10)
padding.PaddingRight = UDim.new(0,10)

-- FUNÇÃO ROW (BOTÃO + CONFIG)
local function createRow(text, mainCallback, configCallback)
    local row = Instance.new("Frame", panel)
    row.Size = UDim2.new(1,0,0,32)
    row.BackgroundTransparency = 1

    local main = Instance.new("TextButton", row)
    main.Size = UDim2.new(0.75,-5,1,0)
    main.Text = text
    main.BackgroundColor3 = Color3.fromRGB(20,40,20)
    main.TextColor3 = Color3.fromRGB(0,255,0)
    main.Font = Enum.Font.Code

    local config = Instance.new("TextButton", row)
    config.Size = UDim2.new(0.25,-5,1,0)
    config.Position = UDim2.new(0.75,5,0,0)
    config.Text = "⚙"
    config.BackgroundColor3 = Color3.fromRGB(30,60,30)
    config.TextColor3 = Color3.fromRGB(0,255,0)

    main.MouseButton1Click:Connect(mainCallback)
    config.MouseButton1Click:Connect(configCallback)

    return main
end

-- AIMBOT
local aimbotBtn
aimbotBtn = createRow("Aimbot: OFF",
function()
    local modes = {"OFF","AUTO","LEGIT"}
    local i = table.find(modes,_G.Config.Aimbot) or 1
    i = i % #modes + 1
    _G.Config.Aimbot = modes[i]
    aimbotBtn.Text = "Aimbot: ".._G.Config.Aimbot
end,
function()
    print("Aimbot config (placeholder)")
end)

-- ESP ENEMY
createRow("ESP Enemy",
function()
    _G.Config.ESP_Enemy = not _G.Config.ESP_Enemy
end,
function()
    print("Enemy config")
end)

-- ESP ALLY
createRow("ESP Ally",
function()
    _G.Config.ESP_Ally = not _G.Config.ESP_Ally
end,
function()
    print("Ally config")
end)

-- 👁️ ESP CONFIG MENU
local espMenu = Instance.new("Frame", panel)
espMenu.Size = UDim2.new(1,0,0,120)
espMenu.Visible = false
espMenu.BackgroundTransparency = 1

local espLayout = Instance.new("UIListLayout", espMenu)
espLayout.Padding = UDim.new(0,4)

local function createESPOption(name,key)
    local b = Instance.new("TextButton", espMenu)
    b.Size = UDim2.new(1,0,0,25)
    b.Text = name..": OFF"
    b.BackgroundColor3 = Color3.fromRGB(15,30,15)
    b.TextColor3 = Color3.fromRGB(0,255,0)

    b.MouseButton1Click:Connect(function()
        _G.Config[key] = not _G.Config[key]
        b.Text = name..": "..(_G.Config[key] and "ON" or "OFF")
    end)
end

createESPOption("Box","ESP_Box")
createESPOption("Name","ESP_Name")
createESPOption("Distance","ESP_Distance")
createESPOption("Line","ESP_Line")

-- BOTÃO ESP ADV
createRow("👁️ ESP Advanced",
function()
    espMenu.Visible = not espMenu.Visible
end,
function() end)

-- SAVE CONFIG
createRow("💾 Save Config",
function()
    if writefile then
        writefile("matrix_config.json", HttpService:JSONEncode(_G.Config))
    end
end,
function() end)

-- FOV
local fovCircle = Drawing.new("Circle")
RunService.RenderStepped:Connect(function()
    fovCircle.Radius = 65
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
    fovCircle.Visible = true
end)

-- CLEANUP
_G.MatrixUI_Cleanup = function()
    if gui then gui:Destroy() end
    if fovCircle then pcall(function() fovCircle:Remove() end) end
end
