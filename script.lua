-- SISTEMA COMPLETO: GUI + AIMBOT + ESP + WALLHACK + SELEÇÃO DE HITBOX + MENU ORGANIZADO

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = workspace
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- FLAGS GLOBAIS
_G.FOV_RADIUS = 65
_G.FOV_VISIBLE = true
_G.aimbotAutoEnabled = false
_G.aimbotManualEnabled = false
_G.aimbotLegitEnabled = false
_G.espEnemiesEnabled = true
_G.espAlliesEnabled = false

-- Hitbox selecionada (default "Head")
local selectedHitbox = "Head"

-- Tabela para os highlights/wallhack
local highlights = {}

-- Controle do menu
local dragging, dragStart, startPos = false, nil, nil
local minimized = false
local currentPage = 1
local maxPage = 3 -- 1: Aimbots + ESP, 2: Hitbox, 3: Configs (se quiser)

-- Função para verificar se o personagem está visível (não atrás de parede)
local function isVisible(origin, targetPos)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    local rayResult = Workspace:Raycast(origin, (targetPos - origin).Unit * (targetPos - origin).Magnitude, raycastParams)
    if rayResult then
        local hitPart = rayResult.Instance
        if hitPart and hitPart:IsDescendantOf(LocalPlayer.Character) then
            return true
        elseif hitPart and hitPart.Parent and Players:GetPlayerFromCharacter(hitPart.Parent) then
            -- Se atingiu outro jogador e é o alvo
            return true
        else
            return false
        end
    end
    return true
end

-- Função para saber se é modo FFA (free for all)
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
    if p == LocalPlayer then return false end
    if not p.Character or not isAlive(p.Character) then return false end
    if not isEnemy(p) and not _G.espAlliesEnabled then return false end

    local origin = Camera.CFrame.Position
    local targetPart = p.Character:FindFirstChild(selectedHitbox)
    if not targetPart then
        targetPart = p.Character:FindFirstChild("Head") or p.Character:FindFirstChild("HumanoidRootPart")
    end
    if not targetPart then return false end

    return isVisible(origin, targetPart.Position)
end

-- GUI PRINCIPAL
local gui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
gui.Name = "AimbotGui"

local panel = Instance.new("Frame", gui)
panel.Size = UDim2.new(0, 240, 0, 320)
panel.Position = UDim2.new(0, 20, 0.5, -160)
panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
panel.BackgroundTransparency = 0.2
panel.BorderSizePixel = 0
panel.Active = true
panel.Draggable = false

-- Drag para mover o painel
panel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = panel.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

panel.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- Função para criar toggles
local function createToggle(text, y, flagName, exclusive1, exclusive2)
    local btn = Instance.new("TextButton", panel)
    btn.Size = UDim2.new(1, -20, 0, 30)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 16
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Text = text .. ": OFF"
    btn.AutoButtonColor = false

    btn.MouseButton1Click:Connect(function()
        _G[flagName] = not _G[flagName]
        if _G[flagName] then
            if exclusive1 then _G[exclusive1] = false end
            if exclusive2 then _G[exclusive2] = false end
        end
        btn.Text = text .. (_G[flagName] and ": ON" or ": OFF")
        loadPage(currentPage)
    end)

    if _G[flagName] then
        btn.Text = text .. ": ON"
    end

    return btn
end

-- Função para criar botões -FOV e +FOV lado a lado
local function createFOVAdjustButtons(yPos)
    local container = Instance.new("Frame", panel)
    container.Size = UDim2.new(1, -20, 0, 35)
    container.Position = UDim2.new(0, 10, 0, yPos)
    container.BackgroundTransparency = 1

    local btnMinus = Instance.new("TextButton", container)
    btnMinus.Size = UDim2.new(0.5, -10, 1, 0)
    btnMinus.Position = UDim2.new(0, 0, 0, 0)
    btnMinus.Text = "- FOV"
    btnMinus.Font = Enum.Font.SourceSansBold
    btnMinus.TextSize = 16
    btnMinus.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    btnMinus.TextColor3 = Color3.new(1,1,1)

    local btnPlus = Instance.new("TextButton", container)
    btnPlus.Size = UDim2.new(0.5, -10, 1, 0)
    btnPlus.Position = UDim2.new(0.5, 10, 0, 0)
    btnPlus.Text = "+ FOV"
    btnPlus.Font = Enum.Font.SourceSansBold
    btnPlus.TextSize = 16
    btnPlus.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    btnPlus.TextColor3 = Color3.new(1,1,1)

    btnMinus.MouseButton1Click:Connect(function()
        _G.FOV_RADIUS = math.clamp(_G.FOV_RADIUS - 5, 10, 300)
    end)

    btnPlus.MouseButton1Click:Connect(function()
        _G.FOV_RADIUS = math.clamp(_G.FOV_RADIUS + 5, 10, 300)
    end)
end

-- Função para limpar elementos do painel exceto os controles fixos
local function clearPage()
    for _, child in pairs(panel:GetChildren()) do
        if child ~= toggleButton and child ~= btnNext and child ~= btnPrev and child ~= fovCircleDrawing and child.Name ~= "HitboxMenuFrame" then
            child:Destroy()
        end
    end
    local hitboxMenuFrame = panel:FindFirstChild("HitboxMenuFrame")
    if hitboxMenuFrame then hitboxMenuFrame.Visible = false end
end

-- Botão minimizar 🔽 / 🔼
local toggleButton = Instance.new("TextButton", panel)
toggleButton.Size = UDim2.new(0, 40, 0, 30)
toggleButton.Position = UDim2.new(1, -50, 0, 5)
toggleButton.Text = "🔽"
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 18
toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleButton.TextColor3 = Color3.new(1,1,1)

toggleButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    toggleButton.Text = minimized and "🔼" or "🔽"
    if minimized then
        panel.Size = UDim2.new(0, 60, 0, 40)
        btnNext.Visible = false
        btnPrev.Visible = false
    else
        panel.Size = UDim2.new(0, 240, 0, 320)
        btnNext.Visible = (currentPage < maxPage)
        btnPrev.Visible = (currentPage > 1)
    end
    loadPage(currentPage)
end)

-- Botões de navegação ◀️ ▶️
local btnNext = Instance.new("TextButton", panel)
btnNext.Size = UDim2.new(0, 40, 0, 30)
btnNext.Position = UDim2.new(1, -50, 1, -40)
btnNext.Text = "▶️"
btnNext.Font = Enum.Font.SourceSansBold
btnNext.TextSize = 20
btnNext.BackgroundColor3 = Color3.fromRGB(40,40,40)
btnNext.TextColor3 = Color3.new(1,1,1)

local btnPrev = Instance.new("TextButton", panel)
btnPrev.Size = UDim2.new(0, 40, 0, 30)
btnPrev.Position = UDim2.new(0, 10, 1, -40)
btnPrev.Text = "◀️"
btnPrev.Font = Enum.Font.SourceSansBold
btnPrev.TextSize = 20
btnPrev.BackgroundColor3 = Color3.fromRGB(40,40,40)
btnPrev.TextColor3 = Color3.new(1,1,1)

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

-- MENU SELEÇÃO DE HITBOX COM IMAGEM BACON E BOTÕES INVISÍVEIS
local function createHitboxMenu()
    local frame = Instance.new("Frame", panel)
    frame.Name = "HitboxMenuFrame"
    frame.Size = UDim2.new(1, -20, 0, 180)
    frame.Position = UDim2.new(0, 10, 0, 40)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BorderSizePixel = 0
    frame.Visible = false

    -- Imagem do Bacon (link oficial ou local)
    local image = Instance.new("ImageLabel", frame)
    image.Size = UDim2.new(0, 150, 0, 180)
    image.Position = UDim2.new(0, 5, 0, 0)
    image.BackgroundTransparency = 1
    image.Image = "rbxassetid://11399149318" -- Exemplo Bacon Roblox

    -- Botões invisíveis para cada parte do corpo (hitbox)
    local hitboxes = {"Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}
    local btnHeight = 25
    for i, part in ipairs(hitboxes) do
        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(0, 70, 0, btnHeight)
        btn.Position = UDim2.new(0, 160, 0, (i-1)*btnHeight)
        btn.Text = part
        btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.SourceSansBold
        btn.TextSize = 14

        btn.MouseButton1Click:Connect(function()
            selectedHitbox = part
            loadPage(currentPage)
        end)
    end

    return frame
end

local hitboxMenuFrame = createHitboxMenu()

-- Função para carregar cada página
function loadPage(page)
    clearPage()

    if minimized then
        -- Se minimizado, não mostra nada além do toggle
        return
    end

    if page == 1 then
        -- Página 1: Aimbots + ESP + FOV
        local baseY = 40
        local gap = 35
        createToggle("Aimbot Auto", baseY + gap*0, "aimbotAutoEnabled", "aimbotManualEnabled", "aimbotLegitEnabled")
        createToggle("Aimbot Manual", baseY + gap*1, "aimbotManualEnabled", "aimbotAutoEnabled", "aimbotLegitEnabled")
        createToggle("Aimbot Legit", baseY + gap*2, "aimbotLegitEnabled", "aimbotAutoEnabled", "aimbotManualEnabled")
        createToggle("ESP Inimigos", baseY + gap*3, "espEnemiesEnabled")
        createToggle("ESP Aliados", baseY + gap*4, "espAlliesEnabled")
        local toggleFOV = createToggle("Mostrar FOV", baseY + gap*5, "FOV_VISIBLE")

        createFOVAdjustButtons(baseY + gap*5 + 40)

    elseif page == 2 then
        -- Página 2: Seleção Hitbox (abre menu bacon)
        hitboxMenuFrame.Visible = true
        hitboxMenuFrame.Position = UDim2.new(0, 10, 0, 40)
        local label = Instance.new("TextLabel", hitboxMenuFrame)
        label.Size = UDim2.new(1, -10, 0, 25)
        label.Position = UDim2.new(0, 0, 0, 160)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.new(1,1,1)
        label.Font = Enum.Font.SourceSansBold
        label.TextSize = 16
        label.Text = "Hitbox selecionada: "..selectedHitbox

    elseif page == 3 then
        -- Página 3: Configurações extras se quiser
        local y = 40
        local label = Instance.new("TextLabel", panel)
        label.Size = UDim2.new(1, -20, 0, 30)
        label.Position = UDim2.new(0, 10, 0, y)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.new(1,1,1)
        label.Font = Enum.Font.SourceSansBold
        label.TextSize = 16
        label.Text = "Configurações adicionais..."

        -- Aqui pode adicionar mais coisas depois
    end

    -- Atualizar visibilidade dos botões next/prev
    btnPrev.Visible = (currentPage > 1 and not minimized)
    btnNext.Visible = (currentPage < maxPage and not minimized)
end

-- Inicializa a página 1
loadPage(1)

-- DESENHO DO FOV (usando Drawing API)
local fovCircleDrawing = Drawing.new("Circle")
fovCircleDrawing.Transparency = 0.2
fovCircleDrawing.Thickness = 1.5
fovCircleDrawing.Filled = false
fovCircleDrawing.Color = Color3.new(1, 1, 1)

RunService.RenderStepped:Connect(function()
    fovCircleDrawing.Radius = _G.FOV_RADIUS
    fovCircleDrawing.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    fovCircleDrawing.Visible = _G.FOV_VISIBLE and not minimized
end)

-- ESP + WALLHACK com Neon e borda amarela quando mirando
local espData = {}
local function disableHighlight(player)
    if highlights[player] then
        highlights[player]:Destroy()
        highlights[player] = nil
    end
end

local function updateHighlight(player, color)
    local chams = highlights[player]
    if not chams then
        chams = Instance.new("Highlight")
        chams.Name = "AimbotHighlight"
        chams.Adornee = player.Character
        chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        chams.OutlineTransparency = 0.7
        chams.FillTransparency = 0.6
        chams.FillColor = color
        chams.OutlineColor = Color3.new(1,1,0) -- amarelo na borda
        chams.Parent = game.CoreGui
        highlights[player] = chams
    else
        chams.FillColor = color
        chams.OutlineColor = Color3.new(1,1,0)
        chams.Enabled = true
    end
end

local function updateESP(player)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    local char = player.Character
    local hrp = char.HumanoidRootPart
    local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
    if not onScreen then
        disableHighlight(player)
        return
    end

    -- Define cor do highlight (neon para inimigos e aliados)
    local baseColor = player.Team == LocalPlayer.Team and Color3.fromRGB(0,255,0) or Color3.fromRGB(1,0,0)

    if currentTarget == player then
        -- Se alvo atual, borda amarela
        updateHighlight(player, baseColor)
    else
        -- Caso contrário, neon normal (sem borda amarela)
        if highlights[player] then
            highlights[player].FillColor = baseColor
            highlights[player].OutlineColor = baseColor
            highlights[player].Enabled = true
        else
            local chams = Instance.new("Highlight")
            chams.Name = "AimbotHighlight"
            chams.Adornee = player.Character
            chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            chams.OutlineTransparency = 0.7
            chams.FillTransparency = 0.6
            chams.FillColor = baseColor
            chams.OutlineColor = baseColor
            chams.Parent = game.CoreGui
            highlights[player] = chams
        end
    end
end

-- Atualiza ESP e Wallhack de todos os players
RunService.RenderStepped:Connect(function()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if p.Character and isAlive(p.Character) then
                if (isEnemy(p) and _G.espEnemiesEnabled) or (not isEnemy(p) and _G.espAlliesEnabled) then
                    updateESP(p)
                else
                    disableHighlight(p)
                end
            else
                disableHighlight(p)
            end
        end
    end
end)

-- AIMBOT VARIÁVEIS
local aiming = false
local shooting = false
local currentTarget = nil

-- Captura do botão manual de mira (mobile)
local aimButton = LocalPlayer.PlayerScripts:WaitForChild("Assets").Ui.TouchInputController.BlasterTouchGui.Buttons:WaitForChild("AimButton")
local shootButton = LocalPlayer.PlayerScripts:WaitForChild("Assets").Ui.TouchInputController.BlasterTouchGui.Buttons:WaitForChild("ShootButton")

aimButton.MouseButton1Down:Connect(function()
    aiming = true
end)
aimButton.MouseButton1Up:Connect(function()
    aiming = false
end)

-- Função para encontrar o alvo mais próximo no FOV e visível
local function getClosestTarget()
    local closest, shortest = nil, math.huge
    local origin = Camera.CFrame.Position

    for _, p in pairs(Players:GetPlayers()) do
        if shouldAimAt(p) then
            local targetPart = p.Character:FindFirstChild(selectedHitbox)
            if not targetPart then
                targetPart = p.Character:FindFirstChild("Head") or p.Character:FindFirstChild("HumanoidRootPart")
            end
            if targetPart then
                local pos, visible = Camera:WorldToViewportPoint(targetPart.Position)
                if visible then
                    local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                    if dist <= _G.FOV_RADIUS and dist < shortest and isVisible(origin, targetPart.Position) then
                        closest = p
                        shortest = dist
                    end
                end
            end
        end
    end

    return closest
end

-- AIMBOT AUTO (mira e atira automático)
RunService.RenderStepped:Connect(function()
    if _G.aimbotAutoEnabled then
        local closest = getClosestTarget()
        if closest and closest.Character then
            local targetPart = closest.Character:FindFirstChild(selectedHitbox) or closest.Character:FindFirstChild("Head") or closest.Character:FindFirstChild("HumanoidRootPart")
            if targetPart then
                currentTarget = closest
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
                if not shooting then
                    shooting = true
                    -- Aqui insira função para atirar automático
                end
                return
            end
        end
        shooting = false
        currentTarget = nil
    end
end)

-- AIMBOT MANUAL (mira automática, atira manual)
RunService.RenderStepped:Connect(function()
    if _G.aimbotManualEnabled and aiming then
        local closest = getClosestTarget()
        if closest and closest.Character then
            local targetPart = closest.Character:FindFirstChild(selectedHitbox) or closest.Character:FindFirstChild("Head") or closest.Character:FindFirstChild("HumanoidRootPart")
            if targetPart then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
                currentTarget = closest
                return
            end
        end
        currentTarget = nil
    end
end)

-- AIMBOT LEGIT (mira e atira automático, preciso e seguro)
RunService.RenderStepped:Connect(function()
    if _G.aimbotLegitEnabled then
        local closest = getClosestTarget()
        if closest and closest.Character then
            local targetPart = closest.Character:FindFirstChild(selectedHitbox) or closest.Character:FindFirstChild("Head") or closest.Character:FindFirstChild("HumanoidRootPart")
            if targetPart then
                currentTarget = closest
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
                if not shooting then
                    shooting = true
                    -- Função para atirar de forma legit, sem gastar munição atoa
                end
                return
            end
        end
        shooting = false
        currentTarget = nil
    end
end)
