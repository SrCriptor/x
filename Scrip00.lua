-- [[ VERIFICAÇÃO DE EXECUÇÃO DUPLICADA ]]
if _G.ScriptExecutado then 
    warn("Script já está rodando! Removendo menu antigo...")
    local antigo = game:GetService("CoreGui"):FindFirstChild("MobileAimbotV2")
    if antigo then antigo:Destroy() end
end
_G.ScriptExecutado = true

-- [[ SERVIÇOS ]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- [[ FLAGS GLOBAIS ]]
_G.FOV_RADIUS = 65
_G.FOV_VISIBLE = true
_G.aimbotAutoEnabled = false
_G.aimbotManualEnabled = false
_G.aimbotNPCEnabled = false 
_G.espEnemiesEnabled = true
_G.espAlliesEnabled = false
_G.noRecoilEnabled = true
_G.infiniteAmmoEnabled = true
_G.instantReloadEnabled = true

-- [[ GUI PRINCIPAL ]]
local gui = Instance.new("ScreenGui")
gui.Name = "MobileAimbotV2"
gui.Parent = game:GetService("CoreGui")
gui.ResetOnSpawn = false

local toggleButton = Instance.new("TextButton", gui)
toggleButton.Name = "MainButton"
toggleButton.Size = UDim2.new(0, 50, 0, 50)
toggleButton.Position = UDim2.new(0.1, 0, 0.4, 0)
toggleButton.Text = "M"
toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Active = true
toggleButton.Draggable = true
Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(1, 0)

local panel = Instance.new("Frame", toggleButton)
panel.Name = "MenuPanel"
panel.Size = UDim2.new(0, 200, 0, 430) 
panel.Position = UDim2.new(1.2, 0, 0, 0)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
panel.Visible = false
Instance.new("UICorner", panel)

toggleButton.MouseButton1Click:Connect(function()
    panel.Visible = not panel.Visible
    toggleButton.Text = panel.Visible and "-" or "M"
end)

-- [[ FUNÇÃO GERADORA DE BOTÕES CORRIGIDA ]]
local function createToggle(text, yPos, flagName, exclusive)
    local btn = Instance.new("TextButton", panel)
    btn.Name = flagName .. "Btn"
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.Position = UDim2.new(0.05, 0, 0, yPos)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", btn)
    
    local function updateVisual()
        btn.Text = text .. (_G[flagName] and ": ON" or ": OFF")
        btn.BackgroundColor3 = _G[flagName] and Color3.fromRGB(40, 100, 40) or Color3.fromRGB(100, 40, 40)
    end

    btn.MouseButton1Click:Connect(function()
        _G[flagName] = not _G[flagName]
        if exclusive and _G[flagName] then 
            _G[exclusive] = false 
            -- Força atualização do outro botão exclusivo se ele existir
            for _, v in pairs(panel:GetChildren()) do
                if v:IsA("TextButton") and v.Name:find("aimbot") then
                    -- Pequeno delay para garantir a troca de flag
                    task.wait(0.05)
                end
            end
        end
    end)
    
    -- Loop de atualização visual constante para evitar erros de sync
    RunService.RenderStepped:Connect(updateVisual)
    
    return btn
end

-- [[ LISTA DE BOTÕES (AGORA APARECERÃO TODOS) ]]
createToggle("Aimbot Auto", 10, "aimbotAutoEnabled", "aimbotManualEnabled")
createToggle("Aimbot Legit", 50, "aimbotManualEnabled", "aimbotAutoEnabled")
createToggle("Aimbot NPC", 90, "aimbotNPCEnabled")
createToggle("No Recoil", 135, "noRecoilEnabled")
createToggle("Inf. Ammo", 175, "infiniteAmmoEnabled")
createToggle("Fast Reload", 215, "instantReloadEnabled")
createToggle("ESP Inimigos", 260, "espEnemiesEnabled")
createToggle("ESP Aliados", 300, "espAlliesEnabled")
createToggle("Mostrar FOV", 340, "FOV_VISIBLE")

-- Botoes de Ajuste de FOV
local function fovAdjust(txt, x, delta)
    local b = Instance.new("TextButton", panel)
    b.Size = UDim2.new(0.42, 0, 0, 35)
    b.Position = UDim2.new(x, 0, 0, 385)
    b.Text = txt
    b.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    b.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function() _G.FOV_RADIUS = math.clamp(_G.FOV_RADIUS + delta, 10, 500) end)
end
fovAdjust("- FOV", 0.05, -10)
fovAdjust("+ FOV", 0.53, 10)

-- [[ DESENHO DO FOV ]]
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1
fovCircle.Filled = false
fovCircle.Color = Color3.new(1, 1, 1)
fovCircle.Transparency = 0.7

-- [[ LÓGICA DE FUNCIONAMENTO ]]
local function isAlive(char)
    local h = char and char:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function getTarget()
    local mouse = UserInputService:GetMouseLocation()
    local target = nil
    local dist = _G.FOV_RADIUS

    -- Jogadores
    if _G.aimbotAutoEnabled or _G.aimbotManualEnabled then
        for _, p in pairs(Players:GetPlayers()) do
            if p == LocalPlayer or not p.Character or not isAlive(p.Character) then continue end
            if p.Team == LocalPlayer.Team and not _G.espAlliesEnabled then continue end
            local h = p.Character:FindFirstChild("Head")
            if h then
                local pos, vis = Camera:WorldToViewportPoint(h.Position)
                local mag = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
                if vis and mag < dist then
                    dist = mag
                    target = h
                end
            end
        end
    end

    -- NPCs
    if not target and _G.aimbotNPCEnabled then
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("Humanoid") and v.Parent and not Players:GetPlayerFromCharacter(v.Parent) then
                if v.Health > 0 and v.Parent:FindFirstChild("Head") then
                    local h = v.Parent.Head
                    local pos, vis = Camera:WorldToViewportPoint(h.Position)
                    local mag = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
                    if vis and mag < dist then
                        dist = mag
                        target = h
                    end
                end
            end
        end
    end
    return target
end

-- [[ LOOP DE ATUALIZAÇÃO ]]
RunService.RenderStepped:Connect(function()
    fovCircle.Radius = _G.FOV_RADIUS
    fovCircle.Position = UserInputService:GetMouseLocation()
    fovCircle.Visible = _G.FOV_VISIBLE

    -- Atributos de Arma
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
    if tool then
        if _G.noRecoilEnabled then tool:SetAttribute("recoilAimReduction", Vector2.new(0,0)) tool:SetAttribute("spread", 0) end
        if _G.infiniteAmmoEnabled then tool:SetAttribute("_ammo", 999) tool:SetAttribute("magazineSize", 999) end
        if _G.instantReloadEnabled then tool:SetAttribute("reloadTime", 0) end
    end

    -- Aimbot
    local active = _G.aimbotAutoEnabled or _G.aimbotNPCEnabled or (_G.aimbotManualEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2))
    if active then
        local target = getTarget()
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        end
    end
end)
