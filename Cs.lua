-- [[ CONFIGURAÇÃO E OFUSCAÇÃO ]]
local _G_S = game.GetService
local Plrs = _G_S(game, "Players")
local RunS = _G_S(game, "RunService")
local UIS = _G_S(game, "UserInputService")
local L_Plr = Plrs.LocalPlayer
local Cam = workspace.CurrentCamera

local _CORE = game:GetService("CoreGui")
local _RAND_ID = "vfx_" .. math.random(100, 999) -- ID dinâmico para a GUI

local Settings = {
    A = false, -- Aimbot
    S = false, -- Silent
    T = false, -- Trigger
    M = 0,     -- DotMode (0:Off, 1:Ponto, 2:Cruz)
    P = false, -- Party
    F = 90,    -- FOV
    Sm = 0.15  -- Smooth
}

local Cols = {Color3.new(1,0,0), Color3.new(0,1,0), Color3.new(0,0,1), Color3.new(1,1,0)}
local C_Idx = 1

-- [[ INTERFACE DISCRETIZADA ]]
local G = Instance.new("ScreenGui")
G.Name = _RAND_ID
G.Parent = _CORE

local T_Btn = Instance.new("TextButton", G)
T_Btn.Size = UDim2.new(0, 45, 0, 45)
T_Btn.Position = UDim2.new(0.1, 0, 0.1, 0)
T_Btn.Text = "X"
T_Btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
T_Btn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", T_Btn).CornerRadius = UDim.new(1, 0)
T_Btn.Draggable = true

local M_Frame = Instance.new("Frame", T_Btn)
M_Frame.Size = UDim2.new(0, 160, 0, 280)
M_Frame.Position = UDim2.new(0, 0, 1.2, 0)
M_Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
M_Frame.Visible = false

T_Btn.MouseButton1Click:Connect(function() M_Frame.Visible = not M_Frame.Visible end)

-- [[ GERADOR DE BOTÕES ]]
local function NewB(txt, y, var, isDot)
    local b = Instance.new("TextButton", M_Frame)
    b.Size = UDim2.new(isDot and 0.7 or 0.9, 0, 0, 30)
    b.Position = UDim2.new(0.05, 0, 0, y)
    b.Text = txt
    b.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
    b.TextColor3 = Color3.new(1, 1, 1)

    if not isDot then
        b.MouseButton1Click:Connect(function()
            Settings[var] = not Settings[var]
            b.BackgroundColor3 = Settings[var] and Color3.fromRGB(30, 80, 30) or Color3.fromRGB(80, 30, 30)
        end)
    end
    return b
end

NewB("AIMBOT", 10, "A")
NewB("SILENT", 45, "S")
NewB("TRIGGER", 80, "T")
local dotB = NewB("DOT: OFF", 115, "M", true)
NewB("PARTY", 150, "P")

-- Botão de Cor
local cB = Instance.new("TextButton", M_Frame)
cB.Size = UDim2.new(0.15, 0, 0, 30)
cB.Position = UDim2.new(0.8, 0, 0, 115)
cB.Text = "C"
cB.BackgroundColor3 = Color3.fromRGB(50, 50, 50)

-- [[ DESENHOS (FOV TRANSPARENTE) ]]
local FOV_C = Drawing.new("Circle")
FOV_C.Thickness = 1
FOV_C.Filled = false -- Transparente por dentro
FOV_C.Transparency = 0.6
FOV_C.Color = Color3.new(1, 1, 1)
FOV_C.Visible = true

local Dot_C = Drawing.new("Circle")
Dot_C.Radius = 3
Dot_C.Filled = true
Dot_C.Visible = false

local Cr_V = Drawing.new("Line")
local Cr_H = Drawing.new("Line")
Cr_V.Thickness = 1.5
Cr_H.Thickness = 1.5

-- [[ LÓGICA DO PONTO/CRUZ ]]
dotB.MouseButton1Click:Connect(function()
    Settings.M = (Settings.M + 1) % 3
    if Settings.M == 0 then dotB.Text = "OFF" dotB.BackgroundColor3 = Color3.fromRGB(80,30,30)
    elseif Settings.M == 1 then dotB.Text = "PONTO" dotB.BackgroundColor3 = Color3.fromRGB(30,80,30)
    else dotB.Text = "CRUZ" dotB.BackgroundColor3 = Color3.fromRGB(30,30,80) end
end)

cB.MouseButton1Click:Connect(function()
    C_Idx = (C_Idx % #Cols) + 1
    Dot_C.Color = Cols[C_Idx]
    Cr_V.Color = Cols[C_Idx]
    Cr_H.Color = Cols[C_Idx]
end)

-- [[ LOOP DE RENDERIZAÇÃO ]]
RunS.RenderStepped:Connect(function()
    local mousePos = UIS:GetMouseLocation()
    FOV_C.Position = mousePos
    FOV_C.Radius = Settings.F
    
    -- Atualiza Mira Central
    Dot_C.Position = mousePos
    Dot_C.Visible = (Settings.M == 1)
    
    local s = 5 -- Tamanho da cruz
    Cr_V.From = mousePos - Vector2.new(0, s)
    Cr_V.To = mousePos + Vector2.new(0, s)
    Cr_H.From = mousePos - Vector2.new(s, 0)
    Cr_H.To = mousePos + Vector2.new(s, 0)
    Cr_V.Visible = (Settings.M == 2)
    Cr_H.Visible = (Settings.M == 2)

    -- Aimbot Logic
    if Settings.A and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = nil
        local maxDist = Settings.F
        
        for _, p in pairs(Plrs:GetPlayers()) do
            if p ~= L_Plr and p.Character and p.Character:FindFirstChild("Head") and p.Team ~= L_Plr.Team then
                local screenPos, onScreen = Cam:WorldToViewportPoint(p.Character.Head.Position)
                local mag = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if onScreen and mag < maxDist then
                    target = p.Character.Head.Position
                    maxDist = mag
                end
            end
        end
        
        if target then
            if Settings.S then
                Cam.CFrame = Cam.CFrame:Lerp(CFrame.new(Cam.CFrame.Position, target), Settings.Sm)
            else
                Cam.CFrame = CFrame.new(Cam.CFrame.Position, target)
            end
        end
    end
end)
ToggleBtn.MouseButton1Click:Connect(function()
    Main.Visible = not Main.Visible
    ToggleBtn.Text = Main.Visible and "-" or "+"
end)

-- FUNÇÃO CRIAR TOGGLES
local function CreateToggle(text, pos, varName, hasColor)
    local btn = Instance.new("TextButton", Main)
    btn.Size = UDim2.new(hasColor and 0.7 or 0.9, 0, 0, 35)
    btn.Position = UDim2.new(0.05, 0, 0, pos)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
    btn.TextColor3 = Color3.new(1, 1, 1)

    btn.MouseButton1Click:Connect(function()
        Config[varName] = not Config[varName]
        btn.BackgroundColor3 = Config[varName] and Color3.fromRGB(40, 100, 40) or Color3.fromRGB(100, 40, 40)
        if varName == "RedDot" then Config.DotObj.Visible = Config.RedDot end
    end)
    
    if hasColor then
        local cBtn = Instance.new("TextButton", Main)
        cBtn.Size = UDim2.new(0.15, 0, 0, 35)
        cBtn.Position = UDim2.new(0.8, 0, 0, pos)
        cBtn.Text = "🎨"
        cBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        cBtn.MouseButton1Click:Connect(function()
            CurCol = (CurCol % #ColorList) + 1
            if Config.DotObj then Config.DotObj.Color = ColorList[CurCol] end
        end)
    end
end

CreateToggle("Aimbot", 10, "Aimbot")
CreateToggle("Silent", 50, "Silent")
CreateToggle("Trigger", 90, "Trigger")
CreateToggle("Red Dot", 130, "RedDot", true)
CreateToggle("Modo Festa 🌈", 170, "PartyMode") -- Novo botão

-- FOV SEÇÃO
local fovDisplay = Instance.new("TextLabel", Main)
fovDisplay.Size = UDim2.new(0.9, 0, 0, 25)
fovDisplay.Position = UDim2.new(0.05, 0, 0, 215)
fovDisplay.Text = "FOV: " .. Config.FOV
fovDisplay.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
fovDisplay.TextColor3 = Color3.new(1, 1, 1)

local fovPlus = Instance.new("TextButton", Main)
fovPlus.Size = UDim2.new(0.42, 0, 0, 30)
fovPlus.Position = UDim2.new(0.05, 0, 0, 245)
fovPlus.Text = "+"
fovPlus.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
fovPlus.TextColor3 = Color3.new(1, 1, 1)

local fovMinus = Instance.new("TextButton", Main)
fovMinus.Size = UDim2.new(0.42, 0, 0, 30)
fovMinus.Position = UDim2.new(0.53, 0, 0, 245)
fovMinus.Text = "-"
fovMinus.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
fovMinus.TextColor3 = Color3.new(1, 1, 1)

fovPlus.MouseButton1Click:Connect(function() Config.FOV = Config.FOV + 10 fovDisplay.Text = "FOV: "..Config.FOV end)
fovMinus.MouseButton1Click:Connect(function() Config.FOV = math.max(10, Config.FOV - 10) fovDisplay.Text = "FOV: "..Config.FOV end)

-- DESENHOS
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.Visible = true
local Dot = Drawing.new("Circle")
Dot.Radius = 4
Dot.Filled = true
Dot.Visible = false
Config.DotObj = Dot

-- LOOP PRINCIPAL
RunService.RenderStepped:Connect(function()
    local center = (UserInputService.TouchEnabled and Camera.ViewportSize/2) or UserInputService:GetMouseLocation()
    FOVCircle.Position = center
    FOVCircle.Radius = Config.FOV
    Dot.Position = center
    
    -- Modo Festa (Ciclo de Cores para Inimigos)
    if Config.PartyMode then
        local hue = tick() % 1 -- Ciclo baseado no tempo
        local rainbowColor = Color3.fromHSV(hue, 1, 1)
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Team ~= LocalPlayer.Team and p.Character then
                for _, part in pairs(p.Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.Color = rainbowColor
                        part.Material = Enum.Material.Neon
                    end
                end
            end
        end
    end

    -- Lógica Aimbot (Simplificada)
    local isAiming = (UserInputService.TouchEnabled and Config.Aimbot) or (not UserInputService.TouchEnabled and Config.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2))
    if isAiming then
        local target = nil
        local dist = Config.FOV
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Team ~= LocalPlayer.Team then
                local pos, vis = Camera:WorldToViewportPoint(p.Character.Head.Position)
                if vis and (Vector2.new(pos.X, pos.Y) - center).Magnitude < dist then
                    target = p.Character.Head.Position
                    break
                end
            end
        end
        if target then
            if Config.Silent then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, target), Config.Smoothness)
            else
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, target)
            end
        end
    end
end)

-- ESP ESTÁTICO
local function ApplyESP(p)
    p.CharacterAdded:Connect(function(c)
        task.wait(0.5)
        local isAlly = (p.Team == LocalPlayer.Team)
        local hl = Instance.new("Highlight", c)
        hl.FillColor = isAlly and Color3.fromRGB(0, 162, 255) or Color3.fromRGB(255, 0, 0)
        hl.FillTransparency = 0.5
        -- Cor base inicial
        for _, part in pairs(c:GetChildren()) do
            if part:IsA("BasePart") then
                part.Color = isAlly and Color3.fromRGB(0, 162, 255) or Color3.fromRGB(200, 140, 60)
            end
        end
    end)
end
for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then ApplyESP(p) end end
Players.PlayerAdded:Connect(ApplyESP)
