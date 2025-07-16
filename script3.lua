local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Configurações globais (flags)
_G.FOV_RADIUS = 65
_G.FOV_VISIBLE = true
_G.aimbotAutoEnabled = false
_G.aimbotManualEnabled = false
_G.espEnemiesEnabled = true
_G.espAlliesEnabled = false

_G.infiniteAmmo = true
_G.instantReload = true
_G.noRecoil = true
_G.noSpread = true
_G.fastShoot = true

local shooting = false
local aiming = false
local dragging = false
local dragStart, startPos
local currentTarget = nil
local currentPage = 1

-- Referências aos botões mobile (ajuste conforme seu jogo)
local aimButton = LocalPlayer.PlayerScripts:WaitForChild("Assets")
    .Ui.TouchInputController.BlasterTouchGui.Buttons:WaitForChild("AimButton")
local shootButton = LocalPlayer.PlayerScripts:WaitForChild("Assets")
    .Ui.TouchInputController.BlasterTouchGui.Buttons:WaitForChild("ShootButton")

-- Função para detectar se o jogo está em modo FFA (todos contra todos)
local function isFFA()
    local teams = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player.Team then
            teams[player.Team] = true
        end
    end
    local count = 0
    for _ in pairs(teams) do count = count + 1 end
    return count <= 1
end

-- ======= INTERFACE =======

local gui = Instance.new("ScreenGui")
gui.Name = "MobileAimbotGUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 220, 0, 280)
panel.Position = UDim2.new(0, 20, 0.5, -140)
panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
panel.BackgroundTransparency = 0.2
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = gui

-- Drag da interface
panel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = panel.Position
    end
end)

panel.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

local buttonsPage1 = {}
local buttonsPage2 = {}

local function createToggleButton(text, yPos, flagName, exclusiveFlag, page)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 30)
    button.Position = UDim2.new(0, 10, 0, yPos)
    -- Ajusta texto já no estado inicial da flag
    button.Text = text .. (_G[flagName] and ": ON" or ": OFF")
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 16
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Visible = page == 1
    button.Parent = panel

    table.insert(page == 1 and buttonsPage1 or buttonsPage2, button)

    button.MouseButton1Click:Connect(function()
        _G[flagName] = not _G[flagName]
        if exclusiveFlag and _G[flagName] then
            _G[exclusiveFlag] = false
        end
        button.Text = text .. (_G[flagName] and ": ON" or ": OFF")
    end)
end

local function createFOVAdjustButton(text, yPos, delta)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.5, -15, 0, 30)
    button.Position = UDim2.new(text == "- FOV" and 0 or 0.5, 10, 0, yPos)
    button.Text = text
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 16
    button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Visible = currentPage == 1
    button.Parent = panel
    table.insert(buttonsPage1, button)

    button.MouseButton1Click:Connect(function()
        _G.FOV_RADIUS = math.clamp(_G.FOV_RADIUS + delta, 10, 300)
    end)
end

local function updatePage(page)
    currentPage = page
    for _, b in pairs(buttonsPage1) do b.Visible = page == 1 end
    for _, b in pairs(buttonsPage2) do b.Visible = page == 2 end
end

-- Toggle minimizar
local minimized = false
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 40, 0, 30)
toggleButton.Position = UDim2.new(1, -50, 0, 5)
toggleButton.Text = "🔽"
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 18
toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Parent = panel

-- Botões de navegação de página
local page1Btn = Instance.new("TextButton")
page1Btn.Size = UDim2.new(0.5, -10, 0, 30)
page1Btn.Position = UDim2.new(0, 10, 1, -35)
page1Btn.Text = "1/2"
page1Btn.Font = Enum.Font.SourceSansBold
page1Btn.TextSize = 16
page1Btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
page1Btn.TextColor3 = Color3.new(1, 1, 1)
page1Btn.Parent = panel

local page2Btn = Instance.new("TextButton")
page2Btn.Size = UDim2.new(0.5, -10, 0, 30)
page2Btn.Position = UDim2.new(0.5, 0, 1, -35)
page2Btn.Text = "2/2"
page2Btn.Font = Enum.Font.SourceSansBold
page2Btn.TextSize = 16
page2Btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
page2Btn.TextColor3 = Color3.new(1, 1, 1)
page2Btn.Parent = panel

page1Btn.MouseButton1Click:Connect(function()
    updatePage(1)
end)
page2Btn.MouseButton1Click:Connect(function()
    updatePage(2)
end)

toggleButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    toggleButton.Text = minimized and "🔼" or "🔽"

    for _, v in pairs(panel:GetChildren()) do
        if v:IsA("TextButton") and v ~= toggleButton then
            v.Visible = not minimized and ((currentPage == 1 and table.find(buttonsPage1, v)) or (currentPage == 2 and table.find(buttonsPage2, v)))
        end
    end

    if minimized then
        panel.Size = UDim2.new(0, 60, 0, 40)
        panel.BackgroundTransparency = 1
        toggleButton.Position = UDim2.new(0, 10, 0, 5)
    else
        panel.Size = UDim2.new(0, 220, 0, 280)
        panel.BackgroundTransparency = 0.2
        toggleButton.Position = UDim2.new(1, -50, 0, 5)
    end
end)

-- Página 1
local y = 40
local spacing = 35
createToggleButton("Aimbot Auto", y, "aimbotAutoEnabled", "aimbotManualEnabled", 1) y += spacing
createToggleButton("Aimbot Manual", y, "aimbotManualEnabled", "aimbotAutoEnabled", 1) y += spacing
createToggleButton("ESP Inimigos", y, "espEnemiesEnabled", nil, 1) y += spacing
createToggleButton("ESP Aliados", y, "espAlliesEnabled", nil, 1) y += spacing
createToggleButton("Mostrar FOV", y, "FOV_VISIBLE", nil, 1) y += spacing
createFOVAdjustButton("- FOV", y, -5)
createFOVAdjustButton("+ FOV", y, 5)

-- Página 2
local y2 = 40
createToggleButton("Infinite Ammo", y2, "infiniteAmmo", nil, 2) y2 += spacing
createToggleButton("Instant Reload", y2, "instantReload", nil, 2) y2 += spacing
createToggleButton("No Recoil", y2, "noRecoil", nil, 2) y2 += spacing
createToggleButton("No Spread", y2, "noSpread", nil, 2) y2 += spacing
createToggleButton("Fast Shoot", y2, "fastShoot", nil, 2)

-- ======= DESENHO DO FOV =======
local Drawing = Drawing or require(game:GetService("ReplicatedStorage"):FindFirstChild("Drawing") or nil)
local fovCircle = Drawing and Drawing.new and Drawing.new("Circle") or nil
if fovCircle then
    fovCircle.Transparency = 0.2
    fovCircle.Thickness = 1.5
    fovCircle.Filled = false
    fovCircle.Color = Color3.new(1, 1, 1)
end

RunService.RenderStepped:Connect(function()
    if fovCircle then
        fovCircle.Radius = _G.FOV_RADIUS
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        fovCircle.Visible = _G.FOV_VISIBLE
    end
end)

-- ======= ESP + CHAMS =======
local espData = {}
local highlights = {}

local function isAlive(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function hasLineOfSight(targetPart)
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local raycastResult = workspace:Raycast(origin, direction, raycastParams)
    if raycastResult then
        local hitPart = raycastResult.Instance
        if hitPart and hitPart:IsDescendantOf(targetPart.Parent) then
            return true
        else
            return false
        end
    else
        return true
    end
end

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

    local box = Drawing and Drawing.new and Drawing.new("Square") or nil
    local nameTag = Drawing and Drawing.new and Drawing.new("Text") or nil
    local healthBar = Drawing and Drawing.new and Drawing.new("Square") or nil

    if not box or not nameTag or not healthBar then return end

    box.Thickness = 1.5
    box.Filled = false
    box.Visible = false

    nameTag.Size = 14
    nameTag.Center = true
    nameTag.Outline = true
    nameTag.Color = Color3.fromRGB(255, 255, 255)
    nameTag.Visible = false

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
        local head = char:FindFirstChild("Head")
        local humanoid = char:FindFirstChildOfClass("Humanoid")

        local topLeftPos, topLeftVis = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(-2, 3, 0))
        local bottomRightPos, bottomRightVis = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(2, -3, 0))
        local headPos, headVis = Camera:WorldToViewportPoint(head.Position)

        if topLeftVis and bottomRightVis and headVis and topLeftPos.Z > 0 and bottomRightPos.Z > 0 and headPos.Z > 0 then
            local width = bottomRightPos.X - topLeftPos.X
            local height = bottomRightPos.Y - topLeftPos.Y
            local x = topLeftPos.X
            local y = topLeftPos.Y

            box.Size = Vector2.new(width, height)
            box.Position = Vector2.new(x, y)

            -- Cor do ESP
            if player == currentTarget then
                box.Color = Color3.fromRGB(255, 255, 0) -- amarelo no alvo
                updateHighlight(player, Color3.fromRGB(255, 255, 0))
            else
                if player.Team == LocalPlayer.Team and _G.espAlliesEnabled then
                    box.Color = Color3.fromRGB(0, 150, 255) -- azul para aliados
                    updateHighlight(player, Color3.fromRGB(0, 150, 255))
                elseif player.Team ~= LocalPlayer.Team and _G.espEnemiesEnabled then
                    box.Color = Color3.fromRGB(255, 0, 0) -- vermelho para inimigos
                    updateHighlight(player, Color3.fromRGB(255, 0, 0))
                else
                    box.Color = Color3.fromRGB(255, 255, 255)
                    disableHighlight(player)
                end
            end

            box.Visible = true
            nameTag.Text = player.Name
            nameTag.Position = Vector2.new(headPos.X, headPos.Y - 20)

            if player == currentTarget then
                nameTag.Color = Color3.fromRGB(255, 255, 0) -- amarelo no alvo
            else
                if player.Team == LocalPlayer.Team and _G.espAlliesEnabled then
                    nameTag.Color = Color3.fromRGB(0, 150, 255) -- azul aliados
                elseif player.Team ~= LocalPlayer.Team and _G.espEnemiesEnabled then
                    nameTag.Color = Color3.fromRGB(255, 255, 255) -- branco inimigos
                else
                    nameTag.Color = Color3.fromRGB(255, 255, 255)
                end
            end

            nameTag.Visible = true

            local healthPercent = humanoid.Health / humanoid.MaxHealth
            local barHeight = height
            local barWidth = 5
            local barX = x - barWidth - 3
            local barY = y + (height * (1 - healthPercent))

            healthBar.Size = Vector2.new(barWidth, barHeight * healthPercent)
            healthBar.Position = Vector2.new(barX, barY)
            healthBar.Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
            healthBar.Visible = true
        else
            box.Visible = false
            nameTag.Visible = false
            healthBar.Visible = false
            disableHighlight(player)
        end
    end)
end

-- Cria ESP para todos os jogadores
for _, player in pairs(Players:GetPlayers()) do
    createESP(player)
end
Players.PlayerAdded:Connect(createESP)

-- ======= FUNÇÕES AUXILIARES =======
local function isAliveCharacter(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function getClosestVisibleEnemy()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local shortestDistance = _G.FOV_RADIUS
    local target = nil

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and isAliveCharacter(player.Character) then
            local ffa = isFFA()
            if not ffa and player.Team == LocalPlayer.Team then
                if not _G.espAlliesEnabled then
                    goto continue
                end
            elseif not _G.espEnemiesEnabled then
                goto continue
            end

            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local mousePos = UserInputService:GetMouseLocation()
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if distance <= shortestDistance then
                        -- Optional: checar linha de visão aqui
                        target = player
                        shortestDistance = distance
                    end
                end
            end
        end
        ::continue::
    end
    return target
end

-- ======= AIMBOT =======
RunService.RenderStepped:Connect(function()
    -- Atualiza o alvo
    if _G.aimbotAutoEnabled then
        currentTarget = getClosestVisibleEnemy()
    elseif _G.aimbotManualEnabled and aiming then
        currentTarget = getClosestVisibleEnemy()
    else
        currentTarget = nil
    end

    -- Mira no alvo se existir
    if currentTarget and currentTarget.Character then
        local hrp = currentTarget.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local cameraCFrame = Camera.CFrame
            local direction = (hrp.Position - cameraCFrame.Position).Unit
            local newCFrame = CFrame.new(cameraCFrame.Position, hrp.Position)
            Camera.CFrame = newCFrame
        end
    end
end)

-- Funções de disparo modificadas
RunService.RenderStepped:Connect(function()
    if _G.infiniteAmmo then
        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool and tool:FindFirstChild("Ammo") then
            tool.Ammo.Value = 999
        end
    end

    if _G.instantReload then
        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool and tool:FindFirstChild("Reloading") then
            tool.Reloading.Value = false
        end
    end

    if _G.noRecoil then
        -- Simplesmente cancela qualquer alteração de recoil na câmera
        Camera.CFrame = Camera.CFrame
    end

    if _G.fastShoot then
        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool and tool:FindFirstChild("FireRate") then
            tool.FireRate.Value = 0.01
        end
    end

    -- No Spread precisa de adaptação conforme o jogo
end)

-- Detecta botão de mira para modo manual (se precisar ajustar, faça aqui)
aimButton.TouchStarted:Connect(function()
    aiming = true
end)
aimButton.TouchEnded:Connect(function()
    aiming = false
end)

return gui
