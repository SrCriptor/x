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
_G.espEnemiesEnabled = true
_G.espAlliesEnabled = false
_G.noRecoilEnabled = true
_G.infiniteAmmoEnabled = true
_G.instantReloadEnabled = true

-- [[ GUI ESTILIZADA ]]
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "MobileAimbotV2"

local toggleButton = Instance.new("TextButton", gui)
toggleButton.Size = UDim2.new(0, 50, 0, 50)
toggleButton.Position = UDim2.new(0.1, 0, 0.4, 0)
toggleButton.Text = "M"
toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Draggable = true
local Corner = Instance.new("UICorner", toggleButton)
Corner.CornerRadius = UDim.new(1, 0)

local panel = Instance.new("Frame", toggleButton)
panel.Size = UDim2.new(0, 200, 0, 380)
panel.Position = UDim2.new(0, 0, 1.1, 0)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
panel.Visible = false
Instance.new("UICorner", panel)

toggleButton.MouseButton1Click:Connect(function()
    panel.Visible = not panel.Visible
    toggleButton.Text = panel.Visible and "-" or "M"
end)

-- [[ FUNÇÃO GERADORA DE BOTÕES ]]
local function createToggle(text, yPos, flagName, exclusive)
    local btn = Instance.new("TextButton", panel)
    btn.Size = UDim2.new(0.9, 0, 0, 30)
    btn.Position = UDim2.new(0.05, 0, 0, yPos)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", btn)
    
    local function update()
        btn.Text = text .. (_G[flagName] and ": ON" or ": OFF")
        btn.BackgroundColor3 = _G[flagName] and Color3.fromRGB(40, 100, 40) or Color3.fromRGB(100, 40, 40)
    end

    btn.MouseButton1Click:Connect(function()
        _G[flagName] = not _G[flagName]
        if exclusive and _G[flagName] then _G[exclusive] = false end
        
        -- Atualiza todos os botões do painel para refletir mudanças exclusivas
        for _, v in pairs(panel:GetChildren()) do
            if v:IsA("TextButton") and v.Name == "Toggle" then v.UpdateFunc() end
        end
    end)
    
    btn.Name = "Toggle"
    btn.UpdateFunc = update
    update()
    return btn
end

-- [[ CRIAÇÃO DOS CONTROLES ]]
createToggle("Aimbot Auto", 10, "aimbotAutoEnabled", "aimbotManualEnabled")
createToggle("Aimbot Legit", 45, "aimbotManualEnabled", "aimbotAutoEnabled")
createToggle("No Recoil", 85, "noRecoilEnabled")
createToggle("Inf. Ammo", 120, "infiniteAmmoEnabled")
createToggle("Fast Reload", 155, "instantReloadEnabled")
createToggle("ESP Inimigos", 195, "espEnemiesEnabled")
createToggle("ESP Aliados", 230, "espAlliesEnabled")
createToggle("Mostrar FOV", 270, "FOV_VISIBLE")

-- Ajustes de FOV
local function fovBtn(txt, x, delta)
    local b = Instance.new("TextButton", panel)
    b.Size = UDim2.new(0.42, 0, 0, 30)
    b.Position = UDim2.new(x, 0, 0, 310)
    b.Text = txt
    b.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    b.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function() _G.FOV_RADIUS = math.clamp(_G.FOV_RADIUS + delta, 10, 400) end)
end
fovBtn("- FOV", 0.05, -5)
fovBtn("+ FOV", 0.53, 5)

-- [[ DESENHO DO FOV (TRANSPARENTE) ]]
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1
fovCircle.Filled = false
fovCircle.Color = Color3.new(1, 1, 1)
fovCircle.Transparency = 0.7

-- [[ FUNÇÕES DE LÓGICA ORIGINAL ]]
local function isAlive(character)
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function isFFA()
    local teams = {}
    for _, p in pairs(Players:GetPlayers()) do if p.Team then teams[p.Team] = true end end
    return next(teams) == nil or next(teams, next(teams)) == nil
end

local function hasLineOfSight(targetPart)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    local res = workspace:Raycast(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position).Unit * 500, rayParams)
    return not res or res.Instance:IsDescendantOf(targetPart.Parent)
end

local function getClosestVisibleEnemy()
    local center = UserInputService:GetMouseLocation()
    local target = nil
    local shortestDist = _G.FOV_RADIUS
    local ffa = isFFA()

    for _, p in pairs(Players:GetPlayers()) do
        if p == LocalPlayer or not p.Character or not isAlive(p.Character) then continue end
        
        local isAlly = p.Team == LocalPlayer.Team
        if not ffa then
            if isAlly and not _G.espAlliesEnabled then continue end
            if not isAlly and not _G.espEnemiesEnabled then continue end
        else
            if not _G.espEnemiesEnabled then continue end
        end

        local head = p.Character:FindFirstChild("Head")
        if head then
            local screenPos, vis = Camera:WorldToViewportPoint(head.Position)
            local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
            if vis and dist <= shortestDist and hasLineOfSight(head) then
                shortestDist = dist
                target = head
            end
        end
    end
    return target
end

-- [[ LOOPS DE EXECUÇÃO ]]
RunService.RenderStepped:Connect(function()
    -- Atualiza FOV
    fovCircle.Radius = _G.FOV_RADIUS
    fovCircle.Position = UserInputService:GetMouseLocation()
    fovCircle.Visible = _G.FOV_VISIBLE

    -- Lógica Aimbot (Auto ou Manual com Botão Direito)
    local aiming = _G.aimbotAutoEnabled or (_G.aimbotManualEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2))
    
    if aiming then
        local target = getClosestVisibleEnemy()
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        end
    end
end)
