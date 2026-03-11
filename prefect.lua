-- [[ TRAINER PROFISSIONAL - LUA ROBLOX ]] --

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- 1. SISTEMA ANTI-DUPLICAÇÃO (Fecha o antigo e abre o novo)
local GUI_NAME = "EliteTrainer_v1"
local oldGui = LocalPlayer.PlayerGui:FindFirstChild(GUI_NAME)
if oldGui then oldGui:Destroy() end

-- 2. CONFIGURAÇÕES INICIAIS
local Settings = {
    ESPAly = false,
    ESPEnm = false,
    Wallhack = false,
    Aimbot = false,
    AimbotLegit = false,
    ShowFOV = false,
    FOVRadius = 150 -- Tamanho do círculo
}

-- 3. INTERFACE (GUI) ADAPTÁVEL
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer.PlayerGui

local isMobile = UserInputService.TouchEnabled
local menuSize = isMobile and UDim2.new(0, 280, 0, 350) or UDim2.new(0, 230, 0, 320)

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = menuSize
MainFrame.Position = UDim2.new(0.5, -menuSize.X.Offset/2, 0.5, -menuSize.Y.Offset/2)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true -- Funcional em PC e Mobile
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

-- Título
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
Title.Text = "ELITE TRAINER"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = MainFrame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

-- Círculo Visual do FOV (Fixo no Meio)
local FOVVisual = Instance.new("Frame")
FOVVisual.Name = "FOVVisual"
FOVVisual.BackgroundColor3 = Color3.new(1, 1, 1)
FOVVisual.BackgroundTransparency = 1
FOVVisual.Visible = false
FOVVisual.Parent = ScreenGui

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Thickness = 1.5
FOVStroke.Color = Color3.new(1, 1, 1)
FOVStroke.Parent = FOVVisual

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVVisual

-- 4. CONTAINER DE BOTÕES
local Container = Instance.new("ScrollingFrame")
Container.Size = UDim2.new(1, -20, 1, -60)
Container.Position = UDim2.new(0, 10, 0, 50)
Container.BackgroundTransparency = 1
Container.ScrollBarThickness = 2
Container.Parent = MainFrame

local UIList = Instance.new("UIListLayout")
UIList.Padding = UDim.new(0, 8)
UIList.Parent = Container

local function makeToggle(text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(180, 50, 50) -- Vermelho (OFF)
    btn.Text = text .. ": OFF"
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamSemibold
    btn.Parent = Container
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50)
        btn.Text = text .. (state and ": ON" or ": OFF")
        callback(state)
    end)
end

-- Adicionando Opções
makeToggle("ESP Aliado", function(s) Settings.ESPAly = s end)
makeToggle("ESP Inimigo", function(s) Settings.ESPEnm = s end)
makeToggle("Wallhack Neon", function(s) Settings.Wallhack = s end)
makeToggle("Aimbot (Rage)", function(s) Settings.Aimbot = s end)
makeToggle("Aimbot (Legit)", function(s) Settings.AimbotLegit = s end)
makeToggle("Exibir Circulo FOV", function(s) Settings.ShowFOV = s end)

-- Controle de FOV (+ / -)
local fovLabel = Instance.new("TextLabel")
fovLabel.Size = UDim2.new(1, 0, 0, 20)
fovLabel.Text = "Ajustar Raio FOV: 150"
fovLabel.BackgroundTransparency = 1
fovLabel.TextColor3 = Color3.new(1,1,1)
fovLabel.Font = Enum.Font.Gotham
fovLabel.Parent = Container

local fovCtrl = Instance.new("Frame")
fovCtrl.Size = UDim2.new(1, 0, 0, 35)
fovCtrl.BackgroundTransparency = 1
fovCtrl.Parent = Container

local function fovBtn(txt, val, pos)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.45, 0, 1, 0)
    b.Position = UDim2.new(pos, 0, 0, 0)
    b.Text = txt
    b.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    b.TextColor3 = Color3.new(1,1,1)
    b.Parent = fovCtrl
    Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function()
        Settings.FOVRadius = math.clamp(Settings.FOVRadius + val, 30, 500)
        fovLabel.Text = "Ajustar Raio FOV: " .. Settings.FOVRadius
    end)
end
fovBtn("-", -10, 0)
fovBtn("+", 10, 0.55)

-- 5. LÓGICA DE FUNCIONAMENTO (LOOP)
RunService.RenderStepped:Connect(function()
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    -- Atualizar Círculo FOV
    FOVVisual.Visible = Settings.ShowFOV
    FOVVisual.Size = UDim2.new(0, Settings.FOVRadius * 2, 0, Settings.FOVRadius * 2)
    FOVVisual.Position = UDim2.new(0, screenCenter.X - Settings.FOVRadius, 0, screenCenter.Y - Settings.FOVRadius)

    -- Lógica de Aimbot (Focado no Centro)
    if Settings.Aimbot or Settings.AimbotLegit then
        local target, closestDist = nil, Settings.FOVRadius
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                if p.Team ~= LocalPlayer.Team then -- Apenas Inimigos
                    local pos, onScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
                    if onScreen then
                        local dist = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                        if dist < closestDist then
                            target = p.Character.Head
                            closestDist = dist
                        end
                    end
                end
            end
        end

        if target then
            if Settings.AimbotLegit then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, target.Position), 0.08)
            else
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
            end
        end
    end

    -- Lógica de ESP e Wallhack Neon
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local isAlly = (p.Team == LocalPlayer.Team)
            local shouldShow = (isAlly and Settings.ESPAly) or (not isAlly and Settings.ESPEnm)
            local highlight = p.Character:FindFirstChild("TrainerHighlight")

            if shouldShow then
                if not highlight then
                    highlight = Instance.new("Highlight", p.Character)
                    highlight.Name = "TrainerHighlight"
                end
                highlight.OutlineColor = isAlly and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
                
                -- Se Wallhack ON -> Neon RGB / Se OFF -> Transparente (só borda)
                if Settings.Wallhack then
                    highlight.FillTransparency = 0
                    highlight.FillColor = Color3.fromHSV(tick() % 5 / 5, 1, 1)
                else
                    highlight.FillTransparency = 1
                end
            elseif highlight then
                highlight:Destroy()
            end
        end
    end
end)
