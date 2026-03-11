-- [[ UNIVERSAL PC HUB - VERSÃO FINAL REFATORADA ]] --
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Configurações de Performance
local Settings = {
    Aimbot = false,
    Legit = false,
    ESP_E = true,
    ESP_A = false,
    FOV = 80,
    FOV_Vis = true,
    Recoil = true,
    Ammo = true,
    Smooth = 0.2,
    MenuKey = Enum.KeyCode.Insert
}

-- Criar Interface PC
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "FinalHubPC"
ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 200, 0, 280)
Main.Position = UDim2.new(0.5, -100, 0.5, -140)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true

local UIList = Instance.new("UIListLayout", Main)
UIList.Padding = UDim.new(0, 4)
UIList.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- FOV FIXO NO CENTRO (CORRIGIDO)
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.Color = Color3.new(1, 1, 1)
FOVCircle.Filled = false
FOVCircle.Transparency = 0.8

-- GESTÃO DE ESP E HIGHLIGHTS (AUTO-RELOAD)
local function ApplyESP(player)
    local function Update()
        local char = player.Character
        if not char then return end
        
        local isAlly = (player.Team == LocalPlayer.Team)
        local shouldShow = (isAlly and Settings.ESP_A) or (not isAlly and Settings.ESP_E)
        
        local hl = char:FindFirstChild("ESP_HL")
        if shouldShow then
            if not hl then
                hl = Instance.new("Highlight", char)
                hl.Name = "ESP_HL"
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            end
            hl.FillColor = isAlly and Color3.fromRGB(0, 160, 255) or Color3.fromRGB(255, 50, 50)
            hl.FillTransparency = 0.5
        elseif hl then
            hl:Destroy()
        end
    end
    player.CharacterAdded:Connect(function() task.wait(0.5); Update() end)
    task.spawn(function() while task.wait(2) do Update() end end) -- Garante que o ESP volte se sumir
end

-- Lógica de Alvo
local function GetClosestTarget()
    local target, dist = nil, Settings.FOV
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                if p.Team == LocalPlayer.Team and not Settings.ESP_A then continue end
                
                local pos, vis = Camera:WorldToViewportPoint(p.Character.Head.Position)
                if vis then
                    local mag = (Vector2.new(pos.X, pos.Y) - center).Magnitude
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

-- LOOP DE RENDERIZAÇÃO (REWRITE)
RunService.RenderStepped:Connect(function()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    
    -- Sync FOV Fixo
    FOVCircle.Visible = Settings.FOV_Vis
    FOVCircle.Radius = Settings.FOV
    FOVCircle.Position = center
    
    -- Modificar Armas (Atributos Universais)
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
    if tool then
        if Settings.Recoil then tool:SetAttribute("Recoil", 0); tool:SetAttribute("Spread", 0) end
        if Settings.Ammo then tool:SetAttribute("Ammo", 999); tool:SetAttribute("MaxAmmo", 999) end
    end

    -- Lógica Aimbot Smooth
    if Settings.Aimbot then
        local isAiming = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        if not Settings.Legit or isAiming then
            local t = GetClosestTarget()
            if t then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, t.Position), Settings.Smooth)
            end
        end
    end
end)

-- Sistema de Menu (Botões e Atalho)
UserInputService.InputBegan:Connect(function(i)
    if i.KeyCode == Settings.MenuKey then Main.Visible = not Main.Visible end
end)

local function AddBtn(text, set)
    local b = Instance.new("TextButton", Main)
    b.Size = UDim2.new(0, 190, 0, 32)
    b.Text = text .. ": OFF"
    b.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.SourceSansBold
    b.BorderSizePixel = 0
    
    b.MouseButton1Click:Connect(function()
        Settings[set] = not Settings[set]
        b.Text = text .. (Settings[set] and ": ON" or ": OFF")
        b.BackgroundColor3 = Settings[set] and Color3.fromRGB(50, 130, 50) or Color3.fromRGB(35, 35, 35)
    end)
end

-- Inicialização
for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then ApplyESP(p) end end
Players.PlayerAdded:Connect(ApplyESP)

AddBtn("Aimbot Master", "Aimbot")
AddBtn("Legit (Botão Direito)", "Legit")
AddBtn("ESP Inimigos", "ESP_E")
AddBtn("ESP Aliados", "ESP_A")
AddBtn("Sem Recuo", "Recoil")
AddBtn("Munição Infinita", "Ammo")
AddBtn("Mostrar FOV", "FOV_Vis")

print("Universal Hub PC Carregado! Atalho: Tecla INSERT")
