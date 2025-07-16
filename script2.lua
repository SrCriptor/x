-- Serviços
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

-- Valores para mods arma (rateOfFire, spread, zoom)
_G.lt = _G.lt or {
    rateOfFire = 200,
    spread = 0,
    zoom = 3,
}

-- Criação do GUI
local gui = Instance.new("ScreenGui")
gui.Name = "RaycastUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 280, 0, 300)
mainFrame.Position = UDim2.new(0, 20, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = gui

local dragButton = Instance.new("TextButton")
dragButton.Size = UDim2.new(1, 0, 0, 25)
dragButton.Position = UDim2.new(0, 0, 0, 0)
dragButton.Text = "⮟ Menu"
dragButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
dragButton.TextColor3 = Color3.new(1, 1, 1)
dragButton.Font = Enum.Font.GothamBold
dragButton.TextSize = 16
dragButton.Parent = mainFrame

-- Dragging logic
local dragging = false
local dragInput, mousePos, framePos

dragButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        mousePos = input.Position
        framePos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

dragButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - mousePos
        mainFrame.Position = UDim2.new(
            framePos.X.Scale,
            framePos.X.Offset + delta.X,
            framePos.Y.Scale,
            framePos.Y.Offset + delta.Y
        )
    end
end)

-- Minimize/Maximize
local minimized = false
dragButton.MouseButton2Click:Connect(function()
    minimized = not minimized
    for _, child in pairs(mainFrame:GetChildren()) do
        if child ~= dragButton then
            child.Visible = not minimized
        end
    end
    dragButton.Text = minimized and "⮝ Menu" or "⮟ Menu"
end)

-- Tabs
local tabButtonsFrame = Instance.new("Frame")
tabButtonsFrame.Size = UDim2.new(1, 0, 0, 30)
tabButtonsFrame.Position = UDim2.new(0, 0, 0, 25)
tabButtonsFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
tabButtonsFrame.Parent = mainFrame

local tabs = {
    Aimbot = Instance.new("Frame"),
    Hitbox = Instance.new("Frame"),
    ModArma = Instance.new("Frame"),
}

local tabOrder = {"Aimbot", "Hitbox", "ModArma"}

for _, tabName in ipairs(tabOrder) do
    local frame = tabs[tabName]
    frame.Size = UDim2.new(1, 0, 1, -55)
    frame.Position = UDim2.new(0, 0, 0, 55)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.Visible = false
    frame.Parent = mainFrame
end
tabs.Aimbot.Visible = true

local function createTabButton(name, index)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1 / #tabOrder, -4, 1, 0)
    btn.Position = UDim2.new((index - 1) / #tabOrder, 2, 0, 0)
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextColor3 = Color3.new(1,1,1)
    btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    btn.Parent = tabButtonsFrame
    btn.MouseButton1Click:Connect(function()
        for _, f in pairs(tabs) do f.Visible = false end
        tabs[name].Visible = true
    end)
    return btn
end

for i, name in ipairs(tabOrder) do
    createTabButton(name, i)
end

-- Toggle Button creator
local function createToggleRay(name, yOffset, globalName, parent)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 240, 0, 28)
    btn.Position = UDim2.new(0, 20, 0, yOffset)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 15
    btn.Text = name .. ": OFF"
    btn.Parent = parent

    local function update()
        local isActive = _G[globalName]
        btn.Text = name .. ": " .. (isActive and "ON" or "OFF")
        btn.BackgroundColor3 = isActive and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(35, 35, 35)
    end

    btn.MouseButton1Click:Connect(function()
        -- exclusividade entre aimbots autom. e legit
        if globalName == "aimbotAutoEnabled" then
            _G.aimbotLegitEnabled = false
        elseif globalName == "aimbotLegitEnabled" then
            _G.aimbotAutoEnabled = false
        end
        _G[globalName] = not _G[globalName]
        update()
    end)

    update()
    return btn
end

-- Sliders creator
local function createSlider(labelText, yOffset, minValue, maxValue, step, globalTableKey, parent)
    local label = Instance.new("TextLabel")
    label.Text = labelText .. ": " .. tostring(_G.lt[globalTableKey])
    label.Size = UDim2.new(0, 240, 0, 20)
    label.Position = UDim2.new(0, 20, 0, yOffset)
    label.TextColor3 = Color3.new(1,1,1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.Parent = parent

    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(0, 240, 0, 20)
    sliderFrame.Position = UDim2.new(0, 20, 0, yOffset + 20)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(40,40,40)
    sliderFrame.Parent = parent

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((_G.lt[globalTableKey] - minValue) / (maxValue - minValue), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    fill.Parent = sliderFrame

    local inputActive = false

    sliderFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            inputActive = true
        end
    end)

    sliderFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            inputActive = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and inputActive then
            local relativeX = math.clamp(input.Position.X - sliderFrame.AbsolutePosition.X, 0, sliderFrame.AbsoluteSize.X)
            local value = minValue + (relativeX / sliderFrame.AbsoluteSize.X) * (maxValue - minValue)
            value = math.floor(value / step + 0.5) * step
            _G.lt[globalTableKey] = value
            label.Text = labelText .. ": " .. tostring(value)
            fill.Size = UDim2.new((value - minValue) / (maxValue - minValue), 0, 1, 0)
        end
    end)

    return label, sliderFrame, fill
end

-- Criar toggles da aba Aimbot
createToggleRay("Aimbot Automático", 20, "aimbotAutoEnabled", tabs.Aimbot)
createToggleRay("Aimbot Legit", 60, "aimbotLegitEnabled", tabs.Aimbot)

-- Criar toggles da aba ModArma
createToggleRay("Infinite Ammo", 10, "modInfiniteAmmo", tabs.ModArma)
createToggleRay("No Recoil", 50, "modNoRecoil", tabs.ModArma)
createToggleRay("Instant Reload", 90, "modInstantReload", tabs.ModArma)

-- Criar sliders na aba ModArma
createSlider("Rate of Fire", 140, 50, 500, 10, "rateOfFire", tabs.ModArma)
createSlider("Spread", 190, 0, 50, 1, "spread", tabs.ModArma)
createSlider("Zoom", 240, 1, 10, 0.1, "zoom", tabs.ModArma)

-- Hitbox popup e botão
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
    closeBtn.Font = Enum.Font.GothamBold
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
hitboxBtn.Font = Enum.Font.GothamBold
hitboxBtn.TextSize = 14
hitboxBtn.Parent = tabs.Hitbox

hitboxBtn.MouseButton1Click:Connect(function()
    hitboxPopup.Visible = not hitboxPopup.Visible
end)

-- Função para verificar se pode atirar através do material (glass, forcefield, fabric)
local function canShootThrough(part)
    if not part then return false end
    local mat = part.Material
    return mat == Enum.Material.Glass or mat == Enum.Material.ForceField or mat == Enum.Material.Fabric
end

-- Função para verificar visibilidade por raycast
local function canSee(part)
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

-- Wallhack neon RGB + borda amarela grossa no alvo aimbot
local function getTarget()
    -- Exemplo simples: seleciona o player mais próximo dentro do FOV e visível
    local closestPlayer = nil
    local closestDist = _G.FOV_RADIUS + 1
    local mousePos = UserInputService:GetMouseLocation()

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            local rootPart = plr.Character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(mousePos.X, mousePos.Y)).Magnitude
                    if dist < closestDist and dist <= _G.FOV_RADIUS and canSee(rootPart) then
                        closestPlayer = plr
                        closestDist = dist
                    end
                end
            end
        end
    end
    return closestPlayer
end

local neonHue = 0
local function updateWallhack()
    neonHue = (neonHue + 0.01) % 1
    local neonColor = Color3.fromHSV(neonHue, 1, 1)
    local target = getTarget()

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            for _, part in pairs(plr.Character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.Material = Enum.Material.ForceField
                    part.Color = neonColor
                    part.Transparency = 0.4

                    local selBox = part:FindFirstChild("SelectionBox")
                    if not selBox then
                        selBox = Instance.new("SelectionBox")
                        selBox.Adornee = part
                        selBox.Parent = part
                    end

                    if target and target.Character == plr.Character then
                        selBox.Color3 = Color3.fromRGB(255, 255, 0) -- amarelo
                        selBox.LineThickness = 0.2
                        selBox.Visible = true
                    else
                        selBox.Color3 = Color3.fromHSV(neonHue, 1, 1) -- RGB neon
                        selBox.LineThickness = 0.05
                        selBox.Visible = true
                    end
                end
            end
        end
    end
end

RunService.RenderStepped:Connect(function()
    if _G.aimbotAutoEnabled or _G.aimbotLegitEnabled then
        updateWallhack()
    else
        -- Remove seleção se wallhack desligado
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                for _, part in pairs(plr.Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        local selBox = part:FindFirstChild("SelectionBox")
                        if selBox then
                            selBox:Destroy()
                        end
                        part.Material = Enum.Material.Plastic
                        part.Transparency = 0
                        part.Color = Color3.fromRGB(255, 255, 255)
                    end
                end
            end
        end
    end
end)

-- Aplicar mods na arma equipada
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

-- Aplicar valores rateOfFire, spread e zoom atualizados
local mouse = LocalPlayer:GetMouse()
local function applyLtAttributes(tool, headPos)
    if not tool then return end
    for k,v in pairs(_G.lt) do
        tool:SetAttribute(k, v)
    end
    if headPos and mouse.Hit then
        local dist = (headPos - mouse.Hit.p).Magnitude
        local adjustedSpread = 30 - dist / 5
        tool:SetAttribute("spread", math.clamp(adjustedSpread, 0, 50))
    end
end

-- Atualizar arma quando personagem ou ferramenta mudar
LocalPlayer.CharacterAdded:Connect(function(char)
    local tool
    repeat
        tool = char:FindFirstChildWhichIsA("Tool")
        task.wait()
    until tool
    local head = char:WaitForChild("Head")
    applyWeaponMods(tool)
    applyLtAttributes(tool, head.Position)
end)

RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChildWhichIsA("Tool")
        local head = char:FindFirstChild("Head")
        if tool and head then
            applyWeaponMods(tool)
            applyLtAttributes(tool, head.Position)
        end
    end
end)
