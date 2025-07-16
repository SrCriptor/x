-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Variáveis globais padrão
_G.aimbotAutoEnabled = false
_G.aimbotManualEnabled = false
_G.FOV_RADIUS = 65
_G.hitboxSelection = {
    Head = true,       -- Head começa como prioritário selecionado
    Torso = false,
    LeftArm = false,
    RightArm = false,
    LeftLeg = false,
    RightLeg = false,
}

-- Função para criar ToggleButton simples
local function createToggleButton(text, posY, flagName, exclusiveFlag)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 25)  -- menor altura
    btn.Position = UDim2.new(0, 10, 0, posY)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14                   -- fonte menor
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Text = text..": OFF"
    btn.Parent = nil -- será definido pelo criador do menu

    btn.MouseButton1Click:Connect(function()
        _G[flagName] = not _G[flagName]
        if exclusiveFlag and _G[flagName] then
            _G[exclusiveFlag] = false
        end
        btn.Text = text .. (_G[flagName] and ": ON" or ": OFF")
        -- Atualizar exclusividade no botão complementar
        if exclusiveFlag and btn.Parent then
            for _, v in pairs(btn.Parent:GetChildren()) do
                if v:IsA("TextButton") and v ~= btn then
                    if v.Text:lower():find(exclusiveFlag:lower()) then
                        v.Text = v.Text:sub(1, v.Text:find(":")) .. (_G[exclusiveFlag] and " ON" or " OFF")
                    end
                end
            end
        end
    end)

    return btn
end

-- Função para criar Popup de seleção de hitbox
local function createHitboxPopup()
    local popup = Instance.new("Frame")
    popup.Size = UDim2.new(0, 250, 0, 340)  -- menor tamanho
    popup.Position = UDim2.new(0.5, -125, 0.5, -170)
    popup.BackgroundColor3 = Color3.fromRGB(30,30,30)
    popup.BorderSizePixel = 0
    popup.Visible = false
    popup.Active = true
    popup.ZIndex = 10

    -- Imagem "Bacon" Roblox
    local img = Instance.new("ImageLabel")
    img.Size = UDim2.new(0, 130, 0, 260)
    img.Position = UDim2.new(0.5, -65, 0, 10)
    img.BackgroundTransparency = 1
    img.Image = "rbxassetid://3926305904" -- imagem do boneco Roblox Bacon (ajuste se quiser outra)
    img.Parent = popup

    -- Botão fechar
    local closeBtn = Instance.new("TextButton")
    closeBtn.Text = "Fechar"
    closeBtn.Size = UDim2.new(0, 70, 0, 25)
    closeBtn.Position = UDim2.new(1, -80, 0, 10)
    closeBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.TextSize = 14
    closeBtn.Parent = popup
    closeBtn.ZIndex = 11

    closeBtn.MouseButton1Click:Connect(function()
        popup.Visible = false
    end)

    -- Função para criar botão invisível sobre a parte do corpo
    local function createHitboxButton(name, position, size)
        local btn = Instance.new("TextButton")
        btn.BackgroundColor3 = Color3.new(0,0,0)
        btn.BackgroundTransparency = 1 -- invisível
        btn.Position = position
        btn.Size = size
        btn.Text = ""
        btn.ZIndex = 15
        btn.Parent = popup

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1,0,1,0)
        label.Position = UDim2.new(0,0,0,0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.new(1,0,0) -- vermelho para prioritário
        label.Font = Enum.Font.SourceSansBold
        label.TextSize = 14
        label.Text = name
        label.Parent = btn
        label.Visible = false

        -- Indicação de seleção prioritária (borda vermelha)
        local border = Instance.new("Frame")
        border.Size = UDim2.new(1,0,1,0)
        border.Position = UDim2.new(0,0,0,0)
        border.BorderColor3 = Color3.fromRGB(255, 0, 0)
        border.BorderSizePixel = 2
        border.BackgroundTransparency = 1
        border.Visible = false
        border.Parent = btn

        btn.MouseButton1Click:Connect(function()
            -- Alternar seleção: desliga se estava ativo, ativa se não
            if _G.hitboxSelection[name] then
                _G.hitboxSelection[name] = false
                border.Visible = false
                label.Visible = false
            else
                _G.hitboxSelection[name] = true
                border.Visible = true
                label.Visible = true
            end
        end)

        -- Atualiza visual ao abrir o popup
        local function updateVisual()
            if _G.hitboxSelection[name] then
                border.Visible = true
                label.Visible = true
            else
                border.Visible = false
                label.Visible = false
            end
        end

        popup:GetPropertyChangedSignal("Visible"):Connect(function()
            if popup.Visible then
                updateVisual()
            end
        end)

        return btn
    end

    -- Criar botões hitbox com posições aproximadas sobre o "Bacon"
    createHitboxButton("Head", UDim2.new(0.45, 0, 0.03, 0), UDim2.new(0, 35, 0, 35))
    createHitboxButton("Torso", UDim2.new(0.4, 0, 0.28, 0), UDim2.new(0, 50, 0, 70))
    createHitboxButton("LeftArm", UDim2.new(0.22, 0, 0.3, 0), UDim2.new(0, 30, 0, 60))
    createHitboxButton("RightArm", UDim2.new(0.73, 0, 0.3, 0), UDim2.new(0, 30, 0, 60))
    createHitboxButton("LeftLeg", UDim2.new(0.43, 0, 0.73, 0), UDim2.new(0, 30, 0, 60))
    createHitboxButton("RightLeg", UDim2.new(0.54, 0, 0.73, 0), UDim2.new(0, 30, 0, 60))

    return popup
end

-- Função para criar o menu principal com páginas
local function createMainMenu()
    local gui = Instance.new("ScreenGui")
    gui.Name = "AimbotControlGUI"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 200, 0, 280) -- menor painel
    panel.Position = UDim2.new(0, 20, 0.5, -140)
    panel.BackgroundColor3 = Color3.fromRGB(30,30,30)
    panel.BorderSizePixel = 0
    panel.Parent = gui

    -- Paginação (botões)
    local currentPage = 1

    local page1Btn = Instance.new("TextButton")
    page1Btn.Text = "Aimbots"
    page1Btn.Size = UDim2.new(0.5, -5, 0, 25)
    page1Btn.Position = UDim2.new(0, 5, 0, 5)
    page1Btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
    page1Btn.TextColor3 = Color3.new(1,1,1)
    page1Btn.Font = Enum.Font.SourceSansBold
    page1Btn.TextSize = 14
    page1Btn.Parent = panel

    local page2Btn = Instance.new("TextButton")
    page2Btn.Text = "Hitbox"
    page2Btn.Size = UDim2.new(0.5, -5, 0, 25)
    page2Btn.Position = UDim2.new(0.5, 0, 0, 5)
    page2Btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    page2Btn.TextColor3 = Color3.new(1,1,1)
    page2Btn.Font = Enum.Font.SourceSansBold
    page2Btn.TextSize = 14
    page2Btn.Parent = panel

    -- Container das páginas
    local page1 = Instance.new("Frame")
    page1.Size = UDim2.new(1, -10, 1, -40)
    page1.Position = UDim2.new(0, 5, 0, 35)
    page1.BackgroundTransparency = 1
    page1.Parent = panel

    local page2 = Instance.new("Frame")
    page2.Size = page1.Size
    page2.Position = page1.Position
    page2.BackgroundTransparency = 1
    page2.Visible = false
    page2.Parent = panel

    -- Página 1: toggles dos aimbots (exclusivos)
    local autoBtn = createToggleButton("Aimbot Automático", 10, "aimbotAutoEnabled", "aimbotManualEnabled")
    autoBtn.Parent = page1

    local legitBtn = createToggleButton("Aimbot Legit", 50, "aimbotManualEnabled", "aimbotAutoEnabled")
    legitBtn.Parent = page1

    -- Atualiza texto e estado para refletir exclusividade
    local function updateToggles()
        autoBtn.Text = "Aimbot Automático: " .. (_G.aimbotAutoEnabled and "ON" or "OFF")
        legitBtn.Text = "Aimbot Legit: " .. (_G.aimbotManualEnabled and "ON" or "OFF")
    end

    autoBtn.MouseButton1Click:Connect(function()
        if _G.aimbotAutoEnabled then
            _G.aimbotManualEnabled = false
        end
        updateToggles()
    end)

    legitBtn.MouseButton1Click:Connect(function()
        if _G.aimbotManualEnabled then
            _G.aimbotAutoEnabled = false
        end
        updateToggles()
    end)

    -- Página 2: botão abrir popup hitbox
    local openHitboxBtn = Instance.new("TextButton")
    openHitboxBtn.Text = "Selecionar Hitbox"
    openHitboxBtn.Size = UDim2.new(0.8, 0, 0, 30)
    openHitboxBtn.Position = UDim2.new(0.1, 0, 0, 15)
    openHitboxBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
    openHitboxBtn.TextColor3 = Color3.new(1,1,1)
    openHitboxBtn.Font = Enum.Font.SourceSansBold
    openHitboxBtn.TextSize = 14
    openHitboxBtn.Parent = page2

    local hitboxPopup = createHitboxPopup()
    hitboxPopup.Parent = gui

    openHitboxBtn.MouseButton1Click:Connect(function()
        hitboxPopup.Visible = not hitboxPopup.Visible
    end)

    -- Função de alternância entre páginas
    local function switchPage(pageNum)
        currentPage = pageNum
        if pageNum == 1 then
            page1.Visible = true
            page2.Visible = false
            page1Btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
            page2Btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
        else
            page1.Visible = false
            page2.Visible = true
            page1Btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
            page2Btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
        end
    end

    page1Btn.MouseButton1Click:Connect(function() switchPage(1) end)
    page2Btn.MouseButton1Click:Connect(function() switchPage(2) end)

    return gui
end

-- Cria o menu e retorna
local aimbotGUI = createMainMenu()

-- Retorno para uso externo
return aimbotGUI
