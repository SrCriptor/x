-- SISTEMA COMPLETO: GUI + AIMBOT + ESP + WALLHACK + SELEÇÃO DE HITBOX

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- FLAGS GLOBAIS
_G.FOV_RADIUS = 65
_G.FOV_VISIBLE = true
_G.aimbotAutoEnabled = false
_G.aimbotManualEnabled = false
_G.aimbotLegitEnabled = false
_G.espEnemiesEnabled = true
_G.espAlliesEnabled = false
_G.hitboxSelection = {
    Head = "Prioritário",
    Torso = "None",
    LeftArm = "None",
    RightArm = "None",
    LeftLeg = "None",
    RightLeg = "None",
}

local shooting = false
local aiming = false
local dragging = false
local dragStart, startPos = nil, nil
local currentTarget = nil

-- BOTÕES MOBILE
local aimButton = LocalPlayer.PlayerScripts:WaitForChild("Assets").Ui.TouchInputController.BlasterTouchGui.Buttons:WaitForChild("AimButton")
local shootButton = LocalPlayer.PlayerScripts:WaitForChild("Assets").Ui.TouchInputController.BlasterTouchGui.Buttons:WaitForChild("ShootButton")

-- FFA CHECK
local function isFFA()
    local teams = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p.Team then teams[p.Team] = true end
    end
    local count = 0 for _ in pairs(teams) do count += 1 end
    return count <= 1
end

local function isEnemy(p)
    return isFFA() or (p.Team and LocalPlayer.Team and p.Team ~= LocalPlayer.Team)
end

local function isAlive(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function shouldAimAt(p)
    return p ~= LocalPlayer and p.Character and isAlive(p.Character) and (isEnemy(p) or _G.espAlliesEnabled)
end

-- GUI PRINCIPAL
local gui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
local panel = Instance.new("Frame", gui)
panel.Size = UDim2.new(0, 220, 0, 280)
panel.Position = UDim2.new(0, 20, 0.5, -140)
panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
panel.BackgroundTransparency = 0.2
panel.BorderSizePixel = 0
panel.Active = true

-- DRAG
panel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = panel.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- TOGGLE BOTÃO MINIMIZAR (🔽/🔼)
local minimized = false
local toggleButton = Instance.new("TextButton", panel)
toggleButton.Size = UDim2.new(0, 40, 0, 30)
toggleButton.Position = UDim2.new(1, -50, 0, 5)
toggleButton.Text = "🔽"
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 18
toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleButton.TextColor3 = Color3.new(1, 1, 1)

-- Deixar o botão de minimizar também arrastável
toggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = panel.Position
    end
end)

toggleButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    toggleButton.Text = minimized and "🔼" or "🔽"
    for _, v in pairs(panel:GetChildren()) do
        if v:IsA("TextButton") and v ~= toggleButton and v ~= btnNext and v ~= btnPrev then
            v.Visible = not minimized
        end
    end
    btnNext.Visible = not minimized and currentPage < maxPage
    btnPrev.Visible = not minimized and currentPage > 1
    panel.Size = minimized and UDim2.new(0, 60, 0, 40) or UDim2.new(0, 220, 0, 280)
    panel.BackgroundTransparency = minimized and 1 or 0.2
    toggleButton.Position = minimized and UDim2.new(0, 10, 0, 5) or UDim2.new(1, -50, 0, 5)
end)

-- FUNÇÃO PARA CRIAR TOGGLE BUTTONS
local function createToggle(text, y, flagName, exclusive1, exclusive2)
    local b = Instance.new("TextButton", panel)
    b.Size = UDim2.new(1, -20, 0, 30)
    b.Position = UDim2.new(0, 10, 0, y)
    b.Text = text .. ": OFF"
    b.Font = Enum.Font.SourceSansBold
    b.TextSize = 16
    b.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.MouseButton1Click:Connect(function()
        _G[flagName] = not _G[flagName]
        if _G[flagName] then
            if exclusive1 then _G[exclusive1] = false end
            if exclusive2 then _G[exclusive2] = false end
        end
        b.Text = text .. (_G[flagName] and ": ON" or ": OFF")
    end)
    return b
end

-- PÁGINA ATUAL E TOTAL DE PÁGINAS
local currentPage = 1
local maxPage = 2

-- BOTÕES DE NAVEGAÇÃO ENTRE PÁGINAS
local btnNext = Instance.new("TextButton", panel)
btnNext.Size = UDim2.new(0, 40, 0, 30)
btnNext.Position = UDim2.new(1, -45, 1, -35)
btnNext.Text = "▶️"
btnNext.Font = Enum.Font.SourceSansBold
btnNext.TextSize = 20
btnNext.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
btnNext.TextColor3 = Color3.new(1, 1, 1)

local btnPrev = Instance.new("TextButton", panel)
btnPrev.Size = UDim2.new(0, 40, 0, 30)
btnPrev.Position = UDim2.new(0, 5, 1, -35)
btnPrev.Text = "◀️"
btnPrev.Font = Enum.Font.SourceSansBold
btnPrev.TextSize = 20
btnPrev.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
btnPrev.TextColor3 = Color3.new(1, 1, 1)

btnNext.MouseButton1Click:Connect(function()
    if currentPage < maxPage then
        currentPage += 1
        loadPage(currentPage)
    end
end)

btnPrev.MouseButton1Click:Connect(function()
    if currentPage > 1 then
        currentPage -= 1
        loadPage(currentPage)
    end
end)

-- FUNÇÃO PARA LIMPAR ITENS DA PÁGINA
local function clearPage()
    for _, v in pairs(panel:GetChildren()) do
        if v:IsA("TextButton") or v:IsA("TextLabel") then
            if v ~= toggleButton and v ~= btnNext and v ~= btnPrev then
                v:Destroy()
            end
        end
    end
end

-- FUNÇÃO PARA CARREGAR PÁGINAS DO MENU
function loadPage(page)
    clearPage()
    if minimized then return end

    if page == 1 then
        -- Página 1: Aimbots + ESP + FOV
        local yBase = 40
        local gap = 35

        -- Toggles principais
        local toggleAuto = createToggle("Aimbot Auto", yBase + gap*0, "aimbotAutoEnabled", "aimbotManualEnabled", "aimbotLegitEnabled")
        local toggleManual = createToggle("Aimbot Manual", yBase + gap*1, "aimbotManualEnabled", "aimbotAutoEnabled", "aimbotLegitEnabled")
        local toggleLegit = createToggle("Aimbot Legit", yBase + gap*2, "aimbotLegitEnabled", "aimbotAutoEnabled", "aimbotManualEnabled")
        local toggleEspEnemies = createToggle("ESP Inimigos", yBase + gap*3, "espEnemiesEnabled")
        local toggleEspAllies = createToggle("ESP Aliados", yBase + gap*4, "espAlliesEnabled")
        local toggleFOVVisible = createToggle("Mostrar FOV", yBase + gap*5, "FOV_VISIBLE")

        -- Botões -FOV e +FOV
        local btnMinus = Instance.new("TextButton", panel)
        btnMinus.Size = UDim2.new(0, 40, 0, 25)
        btnMinus.Position = UDim2.new(0, 20, 0, yBase + gap*5 + 35)
        btnMinus.Text = "- FOV"
        btnMinus.Font = Enum.Font.SourceSansBold
        btnMinus.TextSize = 16
        btnMinus.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        btnMinus.TextColor3 = Color3.new(1, 1, 1)

        local btnPlus = Instance.new("TextButton", panel)
        btnPlus.Size = UDim2.new(0, 40, 0, 25)
        btnPlus.Position = UDim2.new(0, 120, 0, yBase + gap*5 + 35)
        btnPlus.Text = "+ FOV"
        btnPlus.Font = Enum.Font.SourceSansBold
        btnPlus.TextSize = 16
        btnPlus.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        btnPlus.TextColor3 = Color3.new(1, 1, 1)

        btnMinus.MouseButton1Click:Connect(function()
            if _G.FOV_RADIUS > 10 then
                _G.FOV_RADIUS = _G.FOV_RADIUS - 5
            end
        end)

        btnPlus.MouseButton1Click:Connect(function()
            if _G.FOV_RADIUS < 300 then
                _G.FOV_RADIUS = _G.FOV_RADIUS + 5
            end
        end)

    elseif page == 2 then
        -- Página 2: Seleção de Hitbox
        local yStart = 40
        for part, mode in pairs(_G.hitboxSelection) do
            local label = Instance.new("TextLabel", panel)
            label.Size = UDim2.new(1, -20, 0, 25)
            label.Position = UDim2.new(0, 10, 0, yStart)
            label.Text = part .. ": " .. mode
            label.Font = Enum.Font.SourceSansBold
            label.TextSize = 14
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.new(1,1,1)
            yStart = yStart + 30
        end
    end

    btnNext.Visible = (page < maxPage) and not minimized
    btnPrev.Visible = (page > 1) and not minimized
end

-- CARREGAR PÁGINA INICIAL
loadPage(currentPage)

-- CAPTURA DE ESTADO DO BOTÃO DE MIRA (mobile)
aimButton.MouseButton1Down:Connect(function()
    aiming = true
end)
aimButton.MouseButton1Up:Connect(function()
    aiming = false
end)

shootButton.MouseButton1Down:Connect(function()
    shooting = true
end)
shootButton.MouseButton1Up:Connect(function()
    shooting = false
end)

-- FUNÇÕES DE ESP
local espData = {}
local highlights = {}

local function updateHighlight(player, color)
    if not player.Character then return end
    local chams = highlights[player]
    if not chams then
        chams = Instance.new("Highlight")
        chams.Parent = workspace
        highlights[player] = chams
    end
    chams.Adornee = player.Character
    chams.Enabled = true
    chams.FillColor = color
    chams.OutlineColor = Color3.new(0, 0, 0)
    chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
end

local function disableHighlight(player)
    local chams = highlights[player]
    if chams then
        chams.Enabled = false
    end
end

local function createESP(player)
    if player == LocalPlayer then return end

    local box = Drawing.new("Square")
    box.Thickness = 1.5
    box.Filled = false
    box.Visible = false

    local nameTag = Drawing.new("Text")
    nameTag.Size = 14
    nameTag.Center = true
    nameTag.Outline = true
    nameTag.Color = Color3.fromRGB(255, 255, 255)
    nameTag.Visible = false

    local healthBar = Drawing.new("Square")
    healthBar.Filled = true
    healthBar.Visible = false

    espData[player] = {box = box, nameTag = nameTag, healthBar = healthBar}

    RunService.RenderStepped:Connect(function()
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChildOfClass("Humanoid") then
            box.Visible = false
            nameTag.Visible = false
            healthBar.Visible = false
            disableHighlight(player)
            return
        end

        local ffa = isFFA()
        if not ffa then
            if player.Team == LocalPlayer.Team and not _G.espAlliesEnabled then
                box.Visible = false
                nameTag.Visible = false
                healthBar.Visible = false
                disableHighlight(player)
                return
            elseif player.Team ~= LocalPlayer.Team and not _G.espEnemiesEnabled then
                box.Visible = false
                nameTag.Visible = false
                healthBar.Visible = false
                disableHighlight(player)
                return
            end
        else
            if not _G.espEnemiesEnabled then
                box.Visible = false
                nameTag.Visible = false
                healthBar.Visible = false
                disableHighlight(player)
                return
            end
        end

        local hrp = char.HumanoidRootPart
        local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then
            box.Visible = false
            nameTag.Visible = false
            healthBar.Visible = false
            disableHighlight(player)
            return
        end

        local size = 1000 / pos.Z
        box.Size = Vector2.new(size, size)
        box.Position = Vector2.new(pos.X - size / 2, pos.Y - size / 2)
        box.Color = player.Team == LocalPlayer.Team and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
        box.Visible = true

        nameTag.Text = player.Name
        nameTag.Position = Vector2.new(pos.X, pos.Y - size / 2 - 15)
        nameTag.Visible = true

        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            local healthPercent = hum.Health / hum.MaxHealth
            healthBar.Size = Vector2.new(size * healthPercent, 5)
            healthBar.Position = Vector2.new(pos.X - size / 2, pos.Y + size / 2 + 5)
            healthBar.Color = Color3.fromRGB(0, 255, 0)
            healthBar.Visible = true
        else
            healthBar.Visible = false
        end

        -- Highlight para inimigos e aliados
        if player.Team == LocalPlayer.Team then
            disableHighlight(player)
            if _G.espAlliesEnabled then
                updateHighlight(player, Color3.fromRGB(0, 255, 0))
            end
        else
            disableHighlight(player)
            if _G.espEnemiesEnabled then
                updateHighlight(player, Color3.fromRGB(255, 0, 0))
            end
        end
    end)
end

for _, p in pairs(Players:GetPlayers()) do
    createESP(p)
end

Players.PlayerAdded:Connect(function(p)
    createESP(p)
end)

Players.PlayerRemoving:Connect(function(p)
    local data = espData[p]
    if data then
        data.box:Remove()
        data.nameTag:Remove()
        data.healthBar:Remove()
    end
    local chams = highlights[p]
    if chams then
        chams:Destroy()
        highlights[p] = nil
    end
end)

-- FOV DRAWING
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = _G.FOV_VISIBLE
fovCircle.Color = Color3.fromRGB(255, 255, 255)
fovCircle.Thickness = 1
fovCircle.NumSides = 64
fovCircle.Radius = _G.FOV_RADIUS
fovCircle.Transparency = 1

RunService.RenderStepped:Connect(function()
    fovCircle.Visible = _G.FOV_VISIBLE and not minimized
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    fovCircle.Radius = _G.FOV_RADIUS
end)

-- AIMBOT AUTO (mira e atira automático)
RunService.RenderStepped:Connect(function()
    if _G.aimbotAutoEnabled then
        local closest, shortest = nil, math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if shouldAimAt(p) then
                local head = p.Character and p.Character:FindFirstChild("Head")
                if head then
                    local pos, visible = Camera:WorldToViewportPoint(head.Position)
                    if visible then
                        local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
                        if dist <= _G.FOV_RADIUS and dist < shortest then
                            closest = p
                            shortest = dist
                        end
                    end
                end
            end
        end

        if closest and closest.Character and closest.Character:FindFirstChild("Head") then
            currentTarget = closest
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, closest.Character.Head.Position)
            if shooting == false then
                shooting = true
                -- Aqui pode colocar a função que simula disparo, ex: fire click, dependendo do jogo
            end
        else
            shooting = false
            currentTarget = nil
        end
    else
        shooting = false
        currentTarget = nil
    end
end)

-- AIMBOT MANUAL (mira automático, disparo manual)
RunService.RenderStepped:Connect(function()
    if _G.aimbotManualEnabled and aiming then
        local closest, shortest = nil, math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if shouldAimAt(p) then
                local head = p.Character and p.Character:FindFirstChild("Head")
                if head then
                    local pos, visible = Camera:WorldToViewportPoint(head.Position)
                    if visible then
                        local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
                        if dist <= _G.FOV_RADIUS and dist < shortest then
                            closest = p
                            shortest = dist
                        end
                    end
                end
            end
        end
        if closest and closest.Character and closest.Character:FindFirstChild("Head") then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, closest.Character.Head.Position)
            currentTarget = closest
        else
            currentTarget = nil
        end
    else
        currentTarget = nil
    end
end)

-- AIMBOT LEGIT (mira e atira automático, preciso e seguro)
RunService.RenderStepped:Connect(function()
    if _G.aimbotLegitEnabled then
        local closest, shortest = nil, math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if shouldAimAt(p) then
                local head = p.Character and p.Character:FindFirstChild("Head")
                if head then
                    local pos, visible = Camera:WorldToViewportPoint(head.Position)
                    if visible then
                        local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
                        if dist <= _G.FOV_RADIUS and dist < shortest then
                            closest = p
                            shortest = dist
                        end
                    end
                end
            end
        end
        if closest and closest.Character and closest.Character:FindFirstChild("Head") then
            currentTarget = closest
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, closest.Character.Head.Position)
            if shooting == false then
                shooting = true
                -- Aqui pode colocar a função que simula disparo preciso e seguro, sem gastar munição atoa
            end
        else
            shooting = false
            currentTarget = nil
        end
    else
        shooting = false
        currentTarget = nil
    end
end)
