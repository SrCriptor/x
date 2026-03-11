-- [[ TRAINER ELITE UNIVERSAL - V3 FINAL ]] --

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- 1. SISTEMA ANTI-DUPLICAÇÃO
local GUI_NAME = "EliteTrainer_Final_v3"
local oldGui = LocalPlayer.PlayerGui:FindFirstChild(GUI_NAME)
if oldGui then oldGui:Destroy() end

-- 2. CONFIGURAÇÕES
local Settings = {
    ESPAly = false,
    ESPEnm = false,
    Wallhack = false,
    Aimbot = false,
    AimbotLegit = false,
    ShowFOV = false,
    FOVRadius = 150
}

-- 3. INTERFACE ADAPTÁVEL (PC/MOBILE)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer.PlayerGui

local isMobile = UserInputService.TouchEnabled
local menuSize = isMobile and UDim2.new(0, 280, 0, 360) or UDim2.new(0, 230, 0, 330)

local MainFrame = Instance.new("Frame")
MainFrame.Size = menuSize
MainFrame.Position = UDim2.new(0.5, -menuSize.X.Offset/2, 0.5, -menuSize.Y.Offset/2)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
Title.Text = "ELITE TRAINER V3"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 12)

-- Círculo do FOV (Centralizado)
local FOVVisual = Instance.new("Frame")
FOVVisual.BackgroundColor3 = Color3.new(1, 1, 1)
FOVVisual.BackgroundTransparency = 1
FOVVisual.Visible = false
FOVVisual.Parent = ScreenGui
Instance.new("UIStroke", FOVVisual).Thickness = 1.5
Instance.new("UICorner", FOVVisual).CornerRadius = UDim.new(1, 0)

-- Container
local Container = Instance.new("ScrollingFrame")
Container.Size = UDim2.new(1, -20, 1, -60)
Container.Position = UDim2.new(0, 10, 0, 50)
Container.BackgroundTransparency = 1
Container.ScrollBarThickness = 0
Container.Parent = MainFrame
Instance.new("UIListLayout", Container).Padding = UDim.new(0, 8)

-- Função de Botão
local function makeToggle(text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
    btn.Text = text .. ": OFF"
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamSemibold
    btn.Parent = Container
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(40, 150, 40) or Color3.fromRGB(150, 40, 40)
        btn.Text = text .. (state and ": ON" or ": OFF")
        callback(state)
    end)
end

makeToggle("ESP Aliado", function(s) Settings.ESPAly = s end)
makeToggle("ESP Inimigo", function(s) Settings.ESPEnm = s end)
makeToggle("Wallhack Neon", function(s) Settings.Wallhack = s end)
makeToggle("Aimbot (Rage)", function(s) Settings.Aimbot = s end)
makeToggle("Aimbot (Legit)", function(s) Settings.AimbotLegit = s end)
makeToggle("Exibir FOV", function(s) Settings.ShowFOV = s end)

-- Ajuste de FOV
local fovLabel = Instance.new("TextLabel")
fovLabel.Size = UDim2.new(1, 0, 0, 20)
fovLabel.Text = "FOV Radius: 150"
fovLabel.BackgroundTransparency = 1
fovLabel.TextColor3 = Color3.new(1,1,1)
fovLabel.Parent = Container

local fovCtrl = Instance.new("Frame")
fovCtrl.Size = UDim2.new(1, 0, 0, 30)
fovCtrl.BackgroundTransparency = 1
fovCtrl.Parent = Container

local function fBtn(t, v, p)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.45, 0, 1, 0)
    b.Position = UDim2.new(p, 0, 0, 0)
    b.Text = t
    b.BackgroundColor3 = Color3.fromRGB(60,60,70)
    b.TextColor3 = Color3.new(1,1,1)
    b.Parent = fovCtrl
    Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function()
        Settings.FOVRadius = math.clamp(Settings.FOVRadius + v, 30, 600)
        fovLabel.Text = "FOV Radius: " .. Settings.FOVRadius
    end)
end
fBtn("-", -10, 0)
fBtn("+", 10, 0.55)

-- 4. LÓGICA UNIVERSAL (ESP & AIMBOT)
local function getTargetPart(char)
    return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
end

RunService.RenderStepped:Connect(function()
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    -- Atualizar Círculo FOV no Centro
    FOVVisual.Visible = Settings.ShowFOV
    FOVVisual.Size = UDim2.new(0, Settings.FOVRadius * 2, 0, Settings.FOVRadius * 2)
    FOVVisual.Position = UDim2.new(0, screenCenter.X - Settings.FOVRadius, 0, screenCenter.Y - Settings.FOVRadius)

    local closestTarget = nil
    local shortestDist = Settings.FOVRadius

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local char = p.Character
            local targetPart = getTargetPart(char)
            local isAlly = (p.Team == LocalPlayer.Team)
            local shouldShow = (isAlly and Settings.ESPAly) or (not isAlly and Settings.ESPEnm)

            -- LÓGICA ESP/WALLHACK (Highlight Universal)
            local hl = char:FindFirstChild("UniversalHighlight")
            if shouldShow then
                if not hl then
                    hl = Instance.new("Highlight", char)
                    hl.Name = "UniversalHighlight"
                    hl.Adornee = char
                end
                hl.OutlineColor = isAlly and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
                hl.FillTransparency = Settings.Wallhack and 0 or 1
                hl.FillColor = Color3.fromHSV(tick() % 5 / 5, 1, 1) -- Efeito Neon RGB
            elseif hl then
                hl:Destroy()
            end

            -- LÓGICA DE SELEÇÃO DE ALVO (AIMBOT)
            if not isAlly and targetPart then
                local pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                    if dist < shortestDist then
                        closestTarget = targetPart
                        shortestDist = dist
                    end
                end
            end
        end
    end

    -- EXECUÇÃO DO AIMBOT
    if (Settings.Aimbot or Settings.AimbotLegit) and closestTarget then
        if Settings.AimbotLegit then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, closestTarget.Position), 0.08)
        else
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, closestTarget.Position)
        end
    end
end)
