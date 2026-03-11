-- SERVIÇOS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- CONFIGURAÇÕES GLOBAIS (PC)
_G.FOV_RADIUS = 80
_G.FOV_VISIBLE = true
_G.aimbotAutoEnabled = false
_G.aimbotManualEnabled = false
_G.espEnemiesEnabled = true
_G.espAlliesEnabled = false
_G.noRecoilEnabled = true
_G.infiniteAmmoEnabled = true
_G.instantReloadEnabled = true

-- GUI ADAPTADA PARA PC
local gui = Instance.new("ScreenGui")
gui.Name = "PC_CheatMenu"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 220, 0, 360)
panel.Position = UDim2.new(0.05, 0, 0.3, 0)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
panel.BorderSizePixel = 2
panel.Active = true
panel.Draggable = true -- Nativo para Mouse no PC
panel.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
title.Text = "MENU PC [INSERT]"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 16
title.Parent = panel

-- ALTERNAR VISIBILIDADE (TECLA INSERT)
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.Insert then
        panel.Visible = not panel.Visible
    end
end)

-- FUNÇÃO PARA CRIAR BOTÕES
local function createButton(text, yPos, flagName, exclusiveFlag)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 30)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Parent = panel

    local function updateUI()
        btn.Text = text .. (_G[flagName] and ": [LIGADO]" or ": [DESLIGADO]")
        btn.BackgroundColor3 = _G[flagName] and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(50, 50, 50)
    end

    btn.MouseButton1Click:Connect(function()
        _G[flagName] = not _G[flagName]
        if exclusiveFlag and _G[flagName] then _G[exclusiveFlag] = false end
        updateUI()
        -- Atualiza visualmente os botões dependentes
        for _, v in pairs(panel:GetChildren()) do if v:IsA("TextButton") then v.Text = v.Text end end 
    end)

    RunService.Heartbeat:Connect(updateUI) -- Mantém o texto atualizado se mudado por outro botão
    return btn
end

-- ADICIONANDO FUNÇÕES AO PAINEL
createButton("No Recoil", 45, "noRecoilEnabled")
createButton("Infinite Ammo", 80, "infiniteAmmoEnabled")
createButton("Aimbot Automático", 115, "aimbotAutoEnabled", "aimbotManualEnabled")
createButton("Aimbot Legit (RMB)", 150, "aimbotManualEnabled", "aimbotAutoEnabled")
createButton("ESP Inimigos", 185, "espEnemiesEnabled")
createButton("ESP Aliados", 220, "espAlliesEnabled")
createButton("Mostrar FOV", 255, "FOV_VISIBLE")

-- CÍRCULO DE FOV (PC DRAWING)
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1.5
fovCircle.Color = Color3.new(1, 1, 1)
fovCircle.Transparency = 0.7
fovCircle.Filled = false

-- LÓGICA DE ALVO
local function getClosestEnemy()
    local target = nil
    local shortestDist = _G.FOV_RADIUS
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            -- Verifica Time (Simples)
            if not _G.espAlliesEnabled and player.Team == LocalPlayer.Team then continue end
            
            local pos, onScreen = Camera:WorldToViewportPoint(player.Character.Head.Position)
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    target = player
                end
            end
        end
    end
    return target
end

-- LOOP PRINCIPAL (RENDER STEPPED)
RunService.RenderStepped:Connect(function()
    -- Atualiza FOV Circle
    fovCircle.Visible = _G.FOV_VISIBLE
    fovCircle.Radius = _G.FOV_RADIUS
    fovCircle.Position = UserInputService:GetMouseLocation()

    -- Lógica de Aimbot
    local isRmbPressed = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    
    if _G.aimbotAutoEnabled or (_G.aimbotManualEnabled and isRmbPressed) then
        local target = getClosestEnemy()
        if target and target.Character:FindFirstChild("Head") then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Character.Head.Position)
        end
    end
end)

print("Script PC carregado com sucesso!")
