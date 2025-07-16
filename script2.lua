-- [INTERFACE COMPLETA ESTILO RAYCAST COM AIMBOT, HITBOX, WALLHACK RGB E MODS DE ARMA + HITBOX POPUP E VERIFICAÇÕES MELHORADAS]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Variáveis Globais Padrão
_G.aimbotAutoEnabled = _G.aimbotAutoEnabled or false
_G.aimbotLegitEnabled = _G.aimbotLegitEnabled or false
_G.modInfiniteAmmo = _G.modInfiniteAmmo or false
_G.modNoRecoil = _G.modNoRecoil or false
_G.modInstantReload = _G.modInstantReload or false
_G.hitboxSelection = _G.hitboxSelection or {
    Head = true, Torso = false, LeftArm = false, RightArm = false, LeftLeg = false, RightLeg = false
}
_G.FOV_RADIUS = _G.FOV_RADIUS or 200

-- GUI PRINCIPAL
local gui = Instance.new("ScreenGui")
gui.Name = "RaycastUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 280, 0, 280)
mainFrame.Position = UDim2.new(0, 20, 0.5, -140)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = gui

-- Drag Bar + Minimize Button
local dragBar = Instance.new("Frame")
dragBar.Size = UDim2.new(1, 0, 0, 25)
dragBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
dragBar.Parent = mainFrame

local dragLabel = Instance.new("TextLabel")
dragLabel.Text = "⮟ Menu"
dragLabel.Font = Enum.Font.GothamBold
dragLabel.TextSize = 14
dragLabel.TextColor3 = Color3.new(1, 1, 1)
dragLabel.BackgroundTransparency = 1
dragLabel.Size = UDim2.new(0.8, 0, 1, 0)
dragLabel.TextXAlignment = Enum.TextXAlignment.Left
dragLabel.Position = UDim2.new(0, 10, 0, 0)
dragLabel.Parent = dragBar

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Text = "–"
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 18
minimizeBtn.TextColor3 = Color3.new(1, 1, 1)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
minimizeBtn.Size = UDim2.new(0, 30, 0, 25)
minimizeBtn.Position = UDim2.new(1, -35, 0, 0)
minimizeBtn.Parent = dragBar

local minimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    for _, child in pairs(mainFrame:GetChildren()) do
        if child ~= dragBar then
            child.Visible = not minimized
        end
    end
    dragLabel.Text = minimized and "⮝ Menu" or "⮟ Menu"
end)

-- Drag Logic
local dragging = false
local dragInput, mousePos, framePos

dragBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        mousePos = UserInputService:GetMouseLocation()
        framePos = Vector2.new(mainFrame.Position.X.Offset, mainFrame.Position.Y.Offset)
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

dragBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = UserInputService:GetMouseLocation() - mousePos
        mainFrame.Position = UDim2.new(0, framePos.X + delta.X, 0, framePos.Y + delta.Y)
    end
end)

-- Tab Buttons Frame
local tabButtonsFrame = Instance.new("Frame")
tabButtonsFrame.Size = UDim2.new(1, 0, 0, 30)
tabButtonsFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
tabButtonsFrame.Position = UDim2.new(0, 0, 0, 25)
tabButtonsFrame.Parent = mainFrame

-- Tabs
local tabs = {
    Aimbot = Instance.new("Frame"),
    Hitbox = Instance.new("Frame"),
    ModArma = Instance.new("Frame")
}

local tabOrder = {"Aimbot", "Hitbox", "ModArma"}

for _, name in ipairs(tabOrder) do
    local frame = tabs[name]
    frame.Size = UDim2.new(1, 0, 1, -55)
    frame.Position = UDim2.new(0, 0, 0, 55)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.Visible = false
    frame.Parent = mainFrame
end

tabs.Aimbot.Visible = true

-- Create Tab Buttons
for index, name in ipairs(tabOrder) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1/#tabOrder, -2, 1, 0)
    btn.Position = UDim2.new((index-1)/#tabOrder, index > 1 and 2 or 0, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Text = name
    btn.Parent = tabButtonsFrame

    btn.MouseButton1Click:Connect(function()
        for _, frame in pairs(tabs) do
            frame.Visible = false
        end
        tabs[name].Visible = true
    end)
end

-- Função para criar toggle buttons no estilo raycast
local function createToggleRay(name, yOffset, globalName, parent)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 240, 0, 28)
    btn.Position = UDim2.new(0, 20, 0, yOffset)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Text = name .. ": OFF"
    btn.Parent = parent

    local function update()
        local isActive = _G[globalName]
        btn.Text = name .. ": " .. (isActive and "ON" or "OFF")
        btn.BackgroundColor3 = isActive and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(35, 35, 35)
    end

    btn.MouseButton1Click:Connect(function()
        -- Exclusividade entre Aimbots
        if globalName == "aimbotAutoEnabled" then
            _G.aimbotLegitEnabled = false
        elseif globalName == "aimbotLegitEnabled" then
            _G.aimbotAutoEnabled = false
        end

        _G[globalName] = not _G[globalName]
        update()
    end)

    update()
end

-- Abas Aimbot
createToggleRay("Aimbot Automático", 20, "aimbotAutoEnabled", tabs.Aimbot)
createToggleRay("Aimbot Legit", 60, "aimbotLegitEnabled", tabs.Aimbot)

-- Abas Mods de Arma
createToggleRay("Infinite Ammo", 20, "modInfiniteAmmo", tabs.ModArma)
createToggleRay("No Recoil", 60, "modNoRecoil", tabs.ModArma)
createToggleRay("Instant Reload", 100, "modInstantReload", tabs.ModArma)

-- Hitbox Popup
local function createHitboxPopup()
    local popup = Instance.new("Frame")
    popup.Size = UDim2.new(0, 250, 0, 340)
    popup.Position = UDim2.new(0.5, -125, 0.5, -170)
    popup.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    popup.Visible = false
    popup.ZIndex = 10
    popup.Active = true
    popup.Parent = gui

    local closeBtn = Instance.new("TextButton")
    closeBtn.Text = "Fechar"
    closeBtn.Size = UDim2.new(0, 70, 0, 25)
    closeBtn.Position = UDim2.new(1, -80, 0, 10)
    closeBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.TextSize = 14
    closeBtn.Parent = popup

    closeBtn.MouseButton1Click:Connect(function()
        popup.Visible = false
    end)

    local function createHitboxButton(name, position, size)
        local btn = Instance.new("TextButton")
        btn.BackgroundTransparency = 1
        btn.Position = position
        btn.Size = size
        btn.Text = ""
        btn.ZIndex = 15
        btn.Parent = popup

        local border = Instance.new("Frame")
        border.Size = UDim2.new(1, 0, 1, 0)
        border.Position = UDim2.new(0, 0, 0, 0)
        border.BorderColor3 = Color3.fromRGB(255, 0, 0)
        border.BorderSizePixel = 2
        border.BackgroundTransparency = 1
        border.Visible = _G.hitboxSelection[name] or false
        border.Parent = btn

        btn.MouseButton1Click:Connect(function()
            _G.hitboxSelection[name] = not _G.hitboxSelection[name]
            border.Visible = _G.hitboxSelection[name]
        end)
    end

    createHitboxButton("Head", UDim2.new(0.45, 0, 0.03, 0), UDim2.new(0, 35, 0, 35))
    createHitboxButton("Torso", UDim2.new(0.4, 0, 0.28, 0), UDim2.new(0, 50, 0, 70))
    createHitboxButton("LeftArm", UDim2.new(0.22, 0, 0.3, 0), UDim2.new(0, 30, 0, 60))
    createHitboxButton("RightArm", UDim2.new(0.73, 0, 0.3, 0), UDim2.new(0, 30, 0, 60))
    createHitboxButton("LeftLeg", UDim2.new(0.43, 0, 0.73, 0), UDim2.new(0, 30, 0, 60))
    createHitboxButton("RightLeg", UDim2.new(0.54, 0, 0.73, 0), UDim2.new(0, 30, 0, 60))

    return popup
end

local hitboxPopup = createHitboxPopup()

local hitboxBtn = Instance.new("TextButton")
hitboxBtn.Text = "Selecionar Hitbox"
hitboxBtn.Size = UDim2.new(0, 240, 0, 30)
hitboxBtn.Position = UDim2.new(0, 20, 0, 20)
hitboxBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
hitboxBtn.TextColor3 = Color3.new(1, 1, 1)
hitboxBtn.Font = Enum.Font.SourceSansBold
hitboxBtn.TextSize = 14
hitboxBtn.Parent = tabs.Hitbox

hitboxBtn.MouseButton1Click:Connect(function()
    hitboxPopup.Visible = not hitboxPopup.Visible
end)

-- Função para verificar se pode atirar através do material
local function canShootThrough(part)
    if not part then return false end
    local mat = part.Material
    return mat == Enum.Material.Glass or mat == Enum.Material.ForceField or mat == Enum.Material.Fabric
end

-- Função para checar se a parte está visível por raycast
local function canSee(part)
    if not part or not part.Parent then return false end
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin).Unit * 500
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist

    local result = workspace:Raycast(origin, direction, rayParams)
    if result then
        return result.Instance:IsDescendantOf(part.Parent) or canShootThrough(result.Instance)
    end
    return true
end

-- Aplicar Mods na arma
local function applyWeaponMods(tool)
    if not tool then return end

    if _G.modNoRecoil then
        tool:SetAttribute("recoilAimReduction", Vector2.new(0, 0))
        tool:SetAttribute("recoilMax", Vector2.new(0, 0))
        tool:SetAttribute("recoilMin", Vector2.new(0, 0))
    end

    if _G.modInfiniteAmmo then
        local mag = tool:GetAttribute("magazineSize") or 200
        tool:SetAttribute("_ammo", math.huge)
        tool:SetAttribute("magazineSize", mag)

        local display = tool:FindFirstChild("AmmoDisplay")
        if display and display:IsA("TextLabel") then
            display.Text = tostring(mag)
        end
    end

    if _G.modInstantReload then
        tool:SetAttribute("reloadTime", 0)
    end
end

-- Reaplicar mods no respawn
local function onCharacterAdded(char)
    local humanoid = char:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        wait(2)
        local newChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local tool = newChar:FindFirstChildWhichIsA("Tool")
        if tool then
            applyWeaponMods(tool)
        end
    end)

    -- Também aplica mods assim que personagem for carregado
    local tool = char:FindFirstChildWhichIsA("Tool")
    if tool then
        applyWeaponMods(tool)
    end
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
if LocalPlayer.Character then
    onCharacterAdded(LocalPlayer.Character)
end

-- WALLHACK RGB + BORDA AMARELA GROSSA NO ALVO MIRADO
local function getClosestTarget()
    local closestPlayer = nil
    local closestDistance = _G.FOV_RADIUS

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local head = player.Character:FindFirstChild("Head")
            if head and canSee(head) then
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local mousePos = UserInputService:GetMouseLocation()
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(mousePos.X, mousePos.Y)).Magnitude
                    if dist < closestDistance then
                        closestDistance = dist
                        closestPlayer = player
                    end
                end
            end
        end
    end

    return closestPlayer
end

-- Atualiza wallhack com neon rgb e borda amarela no alvo mirado
local neonHue = 0

local function updateWallhack()
    neonHue = (neonHue + 0.005) % 1
    local neonColor = Color3.fromHSV(neonHue, 1, 1)
    local target = getClosestTarget()

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            for _, part in ipairs(player.Character:GetChildren()) do
                if part:IsA("BasePart") then
                    -- Aplicar material neon RGB
                    part.Material = Enum.Material.Neon
                    part.Color = neonColor
                    part.Transparency = 0.4

                    -- Criar ou atualizar borda SelectionBox
                    local sb = part:FindFirstChildOfClass("SelectionBox")
                    if not sb then
                        sb = Instance.new("SelectionBox")
                        sb.Adornee = part
                        sb.Parent = part
                    end

                    if target and target.Character == player.Character then
                        sb.Color3 = Color3.fromRGB(255, 255, 0)
                        sb.LineThickness = 0.2
                    else
                        sb.Color3 = Color3.new(1, 1, 1)
                        sb.LineThickness = 0.05
                    end
                    sb.Visible = true
                end
            end
        end
    end
end

-- Atualiza wallhack a cada frame se algum aimbot estiver ativo
RunService.RenderStepped:Connect(function()
    if _G.aimbotAutoEnabled or _G.aimbotLegitEnabled then
        updateWallhack()
    else
        -- Esconde bordas se wallhack desligado
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                for _, part in ipairs(player.Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        local sb = part:FindFirstChildOfClass("SelectionBox")
                        if sb then
                            sb.Visible = false
                        end
                    end
                end
            end
        end
    end
end)

-- FUNÇÃO PRINCIPAL DE AIMBOT SIMPLIFICADA PARA EXEMPLO (SUBSTITUIR PELO SEU RAYCAST AIMBOT)
local function aimAt(target)
    if not target or not target.Character then return end
    local head = target.Character:FindFirstChild("Head")
    if not head then return end
    local origin = Camera.CFrame.Position
    local direction = (head.Position - origin).Unit
    local newCF = CFrame.new(origin, origin + direction)
    Camera.CFrame = newCF
end

-- Exemplo simples de loop de mira automática (pode substituir pela lógica real)
RunService.RenderStepped:Connect(function()
    if _G.aimbotAutoEnabled then
        local target = getClosestTarget()
        if target then
            aimAt(target)
        end
    end
end)
