-- [[ PARTE 1: CORE & GUI SYSTEM ]] --
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Tabela de Configuração (Substitui _G para maior performance)
local Settings = {
    Aimbot = false,
    Legit = false,
    ESP_E = true,
    ESP_A = false,
    FOV = 65,
    FOV_Vis = true,
    Recoil = true,
    Ammo = true,
    Reload = true,
    Smooth = 0.25 -- Suavização para parecer humano no PC
}

-- Criar Menu Moderno para PC
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "UniversalHub_PC"
ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 220, 0, 300)
Main.Position = UDim2.new(0.5, -110, 0.5, -150)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true -- Ativado para PC

local function CreateToggle(name, setting, y)
    local btn = Instance.new("TextButton", Main)
    btn.Size = UDim2.new(1, -20, 0, 28)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = Settings[setting] and Color3.fromRGB(45, 150, 60) or Color3.fromRGB(40, 40, 40)
    btn.Text = name .. (Settings[setting] and ": ON" or ": OFF")
    btn.Font = Enum.Font.SourceSansBold
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.BorderSizePixel = 0
    
    btn.MouseButton1Click:Connect(function()
        Settings[setting] = not Settings[setting]
        btn.Text = name .. (Settings[setting] and ": ON" or ": OFF")
        btn.BackgroundColor3 = Settings[setting] and Color3.fromRGB(45, 150, 60) or Color3.fromRGB(40, 40, 40)
    end)
end

-- Botão de Fechar/Abrir Menu
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Insert then
        Main.Visible = not Main.Visible
    end
end)

-- [[ PARTE 2: TARGETING & ESP (FIXED & AUTO-RELOAD) ]] --
local FOV_Drawing = Drawing.new("Circle")
FOV_Drawing.Thickness = 1.5
FOV_Drawing.Filled = false
FOV_Drawing.Color = Color3.new(1, 1, 1)

-- Função para aplicar ESP em um personagem específico
local function ApplyESP(player)
    player.CharacterAdded:Connect(function(character)
        -- Espera o personagem carregar totalmente para evitar bugs visual
        character:WaitForChild("HumanoidRootPart")
        
        -- Remove Highlight antigo se existir
        local oldHl = character:FindFirstChild("Highlight")
        if oldHl then oldHl:Destroy() end

        -- Cria o novo Highlight
        local hl = Instance.new("Highlight")
        hl.Name = "Highlight"
        hl.Parent = character
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        
        -- Loop de atualização de cor (mais leve que RenderStepped global)
        task.spawn(function()
            while character and character.Parent do
                local isAlly = (player.Team == LocalPlayer.Team)
                hl.Enabled = (isAlly and Settings.ESP_A) or (not isAlly and Settings.ESP_E)
                hl.FillColor = isAlly and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(255, 50, 50)
                hl.OutlineColor = Color3.new(1, 1, 1)
                hl.FillTransparency = 0.5
                task.wait(1) -- Atualiza a cada 1 segundo (economiza CPU)
            end
        end)
    end)
end

-- Aplicar para quem já está no jogo
for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then 
        ApplyESP(p)
        -- Se já tiver personagem vivo, força o trigger do evento
        if p.Character then 
            task.spawn(function() 
                -- Simula o CharacterAdded para quem já nasceu
                local char = p.Character
                local hl = Instance.new("Highlight", char)
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            end)
        end
    end
end

-- Aplicar para novos jogadores que entrarem
Players.PlayerAdded:Connect(ApplyESP)

-- Lógica de busca de alvo (Otimizada)
local function GetClosestTarget()
    local target, shortestDist = nil, Settings.FOV
    local mousePos = UserInputService:GetMouseLocation()

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local isAlly = (p.Team == LocalPlayer.Team)
                if isAlly and not Settings.ESP_A then continue end
                
                local pos, visible = Camera:WorldToViewportPoint(p.Character.Head.Position)
                if visible then
                    local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                    if dist < shortestDist then
                        target = p.Character.Head
                        shortestDist = dist
                    end
                end
            end
        end
    end
    return target
end

local function UpdateESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hl = p.Character:FindFirstChild("Highlight") or Instance.new("Highlight", p.Character)
            local isAlly = (p.Team == LocalPlayer.Team)
            hl.Enabled = (isAlly and Settings.ESP_A) or (not isAlly and Settings.ESP_E)
            hl.FillColor = isAlly and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(255, 50, 50)
            hl.OutlineTransparency = 0
            hl.FillTransparency = 0.5
        end
    end
end

-- [[ PARTE 3: COMBAT & WEAPON MODS ]] --
local function ModWeapon()
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
    if tool then
        if Settings.Recoil then tool:SetAttribute("Recoil", 0) tool:SetAttribute("Spread", 0) end
        if Settings.Ammo then tool:SetAttribute("Ammo", 999) tool:SetAttribute("MaxAmmo", 999) end
        if Settings.Reload then tool:SetAttribute("ReloadTime", 0) end
    end
end

RunService.RenderStepped:Connect(function()
    -- Sync FOV
    FOV_Drawing.Visible = Settings.FOV_Vis
    FOV_Drawing.Radius = Settings.FOV
    FOV_Drawing.Position = UserInputService:GetMouseLocation()
    
    -- Sync Aimbot
    if Settings.Aimbot then
        local t = GetClosestTarget()
        if t and (not Settings.Legit or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)) then
            local goal = CFrame.new(Camera.CFrame.Position, t.Position)
            Camera.CFrame = Camera.CFrame:Lerp(goal, Settings.Smooth)
        end
    end
    
    UpdateESP()
    ModWeapon()
end)

-- Inserindo os Toggles no Menu
CreateToggle("Aimbot Master", "Aimbot", 40)
CreateToggle("Legit Mode (RightClick)", "Legit", 75)
CreateToggle("ESP Enemies", "ESP_E", 110)
CreateToggle("ESP Allies", "ESP_A", 145)
CreateToggle("No Recoil", "Recoil", 180)
CreateToggle("Infinite Ammo", "Ammo", 215)
CreateToggle("Show FOV Circle", "FOV_Vis", 250)

print("Hub Profissional Carregado! Pressione 'Insert' para abrir.")
