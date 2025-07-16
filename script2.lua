-- [INTERFACE COMPLETA ESTILO RAYCAST COM AIMBOT, HITBOX E MODS DE ARMA + HITBOX POPUP E VERIFICAÇÕES MELHORADAS]

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

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 280, 0, 260)
mainFrame.Position = UDim2.new(0, 20, 0.5, -130)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = gui

local tabButtonsFrame = Instance.new("Frame")
tabButtonsFrame.Size = UDim2.new(1, 0, 0, 25)
tabButtonsFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
tabButtonsFrame.Parent = mainFrame

local tabs = {
    Aimbot = Instance.new("Frame"),
    Hitbox = Instance.new("Frame"),
    ModArma = Instance.new("Frame")
}

for name, frame in pairs(tabs) do
    frame.Size = UDim2.new(1, 0, 1, -25)
    frame.Position = UDim2.new(0, 0, 0, 25)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.Visible = false
    frame.Parent = mainFrame
end

tabs.Aimbot.Visible = true

local function createTabButton(name, index)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.25, -2, 1, 0)
    btn.Position = UDim2.new(0.25 * (index - 1), index > 1 and (index - 1) * 2 or 0, 0, 0)
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.Parent = tabButtonsFrame
    return btn
end

local tabIndex = 1
for tabName, tabFrame in pairs(tabs) do
    local button = createTabButton(tabName, tabIndex)
    button.MouseButton1Click:Connect(function()
        for _, frame in pairs(tabs) do frame.Visible = false end
        tabFrame.Visible = true
    end)
    tabIndex += 1
end

local function createToggleRay(name, yOffset, globalName, parent)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 240, 0, 25)
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
        for _, other in pairs({"aimbotAutoEnabled", "aimbotLegitEnabled"}) do
            if other ~= globalName and (globalName == "aimbotAutoEnabled" or globalName == "aimbotLegitEnabled") then
                _G[other] = false
            end
        end
        _G[globalName] = not _G[globalName]
        update()
    end)

    update()
end

-- Aimbot
createToggleRay("Aimbot Automático", 40, "aimbotAutoEnabled", tabs.Aimbot)
createToggleRay("Aimbot Legit", 80, "aimbotLegitEnabled", tabs.Aimbot)

-- Mods
createToggleRay("Infinite Ammo", 30, "modInfiniteAmmo", tabs.ModArma)
createToggleRay("No Recoil", 65, "modNoRecoil", tabs.ModArma)
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

local popup = createHitboxPopup()

local hitboxBtn = Instance.new("TextButton")
hitboxBtn.Text = "Selecionar Hitbox"
hitboxBtn.Size = UDim2.new(0, 240, 0, 30)
hitboxBtn.Position = UDim2.new(0, 20, 0, 40)
hitboxBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
hitboxBtn.TextColor3 = Color3.new(1, 1, 1)
hitboxBtn.Font = Enum.Font.SourceSansBold
hitboxBtn.TextSize = 14
hitboxBtn.Parent = tabs.Hitbox

hitboxBtn.MouseButton1Click:Connect(function()
    popup.Visible = not popup.Visible
end)

-- FOV Check e Visibilidade
local function canShootThrough(part)
    if not part then return false end
    local mat = part.Material
    return mat == Enum.Material.Glass or mat == Enum.Material.ForceField or mat == Enum.Material.Fabric
end

local function canSee(part)
    local origin = Camera.CFrame.Position
    local dir = (part.Position - origin).Unit * 500
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    local result = workspace:Raycast(origin, dir, rayParams)
    if result then
        return result.Instance:IsDescendantOf(part.Parent) or canShootThrough(result.Instance)
    end
    return true
end

-- Aplicar Mods
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

RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChildWhichIsA("Tool")
        if tool then
            applyWeaponMods(tool)
        end
    end
end)
