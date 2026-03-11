local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

-- 1. SISTEMA ANTI-DUPLICAÇÃO
local GUI_NAME = "MyTrainerHub_Unique"
local oldGui = LocalPlayer.PlayerGui:FindFirstChild(GUI_NAME)
if oldGui then oldGui:Destroy() end

-- 2. CONFIGURAÇÕES GERAIS
local Settings = {
    ESPAly = false,
    ESPEnm = false,
    Wallhack = false,
    Aimbot = false,
    AimbotLegit = false,
    FOVValue = 90,
    ShowFOVCircle = false,
    FOVRadius = 100
}

-- 3. INTERFACE PRINCIPAL (GUI)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer.PlayerGui

local isMobile = UserInputService.TouchEnabled
local MainFrame = Instance.new("Frame")
MainFrame.Size = isMobile and UDim2.new(0, 280, 0, 320) or UDim2.new(0, 220, 0, 300)
MainFrame.Position = UDim2.new(0.5, -110, 0.5, -150)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.Parent = MainFrame

-- Título
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
Title.Text = "TRAINER ELITE"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

-- Círculo do FOV (Visual)
local FOVVisual = Instance.new("Frame")
FOVVisual.Name = "FOVVisual"
FOVVisual.BackgroundTransparency = 1
FOVVisual.Size = UDim2.new(0, Settings.FOVRadius * 2, 0, Settings.FOVRadius * 2)
FOVVisual.Visible = false
FOVVisual.Parent = ScreenGui

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Thickness = 2
FOVStroke.Color = Color3.new(1,1,1)
FOVStroke.Parent = FOVVisual

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVVisual

-- 4. FUNÇÕES DE CRIAÇÃO DO MENU
local Container = Instance.new("ScrollingFrame")
Container.Size = UDim2.new(1, -20, 1, -50)
Container.Position = UDim2.new(0, 10, 0, 40)
Container.BackgroundTransparency = 1
Container.ScrollBarThickness = 2
Container.Parent = MainFrame

local UIList = Instance.new("UIListLayout")
UIList.Padding = UDim.new(0, 5)
UIList.Parent = Container

local function makeToggle(text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
    btn.Text = text .. ": OFF"
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.Gotham
    btn.Parent = Container
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(40, 150, 40) or Color3.fromRGB(150, 40, 40)
        btn.Text = text .. (state and ": ON" or ": OFF")
        callback(state)
    end)
end

-- Botões
makeToggle("ESP Aliado", function(s) Settings.ESPAly = s end)
makeToggle("ESP Inimigo", function(s) Settings.ESPEnm = s end)
makeToggle("Wallhack Neon", function(s) Settings.Wallhack = s end)
makeToggle("Aimbot", function(s) Settings.Aimbot = s end)
makeToggle("Aimbot Legit", function(s) Settings.AimbotLegit = s end)
makeToggle("Exibir FOV", function(s) Settings.ShowFOVCircle = s end)

-- Controle FOV (+ / -)
local fovInfo = Instance.new("TextLabel")
fovInfo.Size = UDim2.new(1,0,0,20)
fovInfo.Text = "FOV: 90"
fovInfo.BackgroundTransparency = 1
fovInfo.TextColor3 = Color3.new(1,1,1)
fovInfo.Parent = Container

local fovBtns = Instance.new("Frame")
fovBtns.Size = UDim2.new(1,0,0,30)
fovBtns.BackgroundTransparency = 1
fovBtns.Parent = Container

local function createFovBtn(txt, val, posX)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.45, 0, 1, 0)
    b.Position = UDim2.new(posX, 0, 0, 0)
    b.Text = txt
    b.BackgroundColor3 = Color3.fromRGB(60,60,60)
    b.TextColor3 = Color3.new(1,1,1)
    b.Parent = fovBtns
    b.MouseButton1Click:Connect(function()
        Settings.FOVValue = math.clamp(Settings.FOVValue + val, 30, 120)
        fovInfo.Text = "FOV: "..Settings.FOVValue
        Camera.FieldOfView = Settings.FOVValue
    end)
end
createFovBtn("-", -5, 0)
createFovBtn("+", 5, 0.55)

-- 5. LÓGICA FUNCIONAL (Aimbot & ESP)
local function getClosest()
    local target, dist = nil, Settings.FOVRadius
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            if p.Team ~= LocalPlayer.Team then
                local pos, visible = Camera:WorldToViewportPoint(p.Character.Head.Position)
                if visible then
                    local mag = (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
                    if mag < dist then
                        target = p.Character.Head
                        dist = mag
                    end
                end
            end
        end
    end
    return target
end

RunService.RenderStepped:Connect(function()
    -- Círculo FOV
    FOVVisual.Visible = Settings.ShowFOVCircle
    FOVVisual.Position = UDim2.new(0, UserInputService:GetMouseLocation().X - Settings.FOVRadius, 0, UserInputService:GetMouseLocation().Y - Settings.FOVRadius)
    
    -- Lógica Aimbot
    if Settings.Aimbot or Settings.AimbotLegit then
        local target = getClosest()
        if target then
            if Settings.AimbotLegit then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, target.Position), 0.08)
            else
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
            end
        end
    end

    -- Lógica ESP/Wallhack
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local isAlly = (p.Team == LocalPlayer.Team)
            local enabled = (isAlly and Settings.ESPAly) or (not isAlly and Settings.ESPEnm)
            local hl = p.Character:FindFirstChild("EliteHighlight")
            
            if enabled then
                if not hl then
                    hl = Instance.new("Highlight", p.Character)
                    hl.Name = "EliteHighlight"
                end
                hl.OutlineColor = isAlly and Color3.new(0,1,0) or Color3.new(1,0,0)
                hl.FillTransparency = Settings.Wallhack and 0 or 1
                hl.FillColor = Color3.fromHSV(tick() % 5 / 5, 1, 1) -- RGB Effect
            elseif hl then
                hl:Destroy()
            end
        end
    end
end)
