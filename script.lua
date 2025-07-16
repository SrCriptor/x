local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
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
_G.espBoxEnabled = true
_G.espLineEnabled = false
_G.espDistanceEnabled = false
_G.espHealthBarEnabled = true
_G.espNameEnabled = true

-- Hitbox padrão
_G.hitboxSelection = {
    Head = "Prioritário",
    Torso = "Nenhum",
    LeftArm = "Nenhum",
    RightArm = "Nenhum",
    LeftLeg = "Nenhum",
    RightLeg = "Nenhum",
}

local gui = Instance.new("ScreenGui")
gui.Name = "AimbotGUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 250, 0, 280)
panel.Position = UDim2.new(0, 20, 0.5, -140)
panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
panel.BackgroundTransparency = 0.2
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = gui

-- Variáveis de estado para drag
local dragging = false
local dragStart
local startPos

-- Drag no painel
panel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Botão minimizar/maximizar
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 40, 0, 30)
toggleButton.Position = UDim2.new(1, -50, 0, 5)
toggleButton.Text = "🔽"
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 20
toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Parent = panel

local toggleDragging = false
local toggleDragStart
local toggleStartPos

-- Drag do toggleButton independente do painel
toggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        toggleDragging = true
        toggleDragStart = input.Position
        toggleStartPos = toggleButton.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                toggleDragging = false
            end
        end)
    end
end)

toggleButton.InputChanged:Connect(function(input)
    if toggleDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - toggleDragStart
        toggleButton.Position = UDim2.new(toggleStartPos.X.Scale, toggleStartPos.X.Offset + delta.X, toggleStartPos.Y.Scale, toggleStartPos.Y.Offset + delta.Y)
    end
end)

local minimized = false
toggleButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    toggleButton.Text = minimized and "🔼" or "🔽"

    if minimized then
        panel.Size = UDim2.new(0, 60, 0, 40)
        panel.BackgroundTransparency = 1
        -- Esconder todos os botões exceto toggle e navegação
        for _, child in pairs(panel:GetChildren()) do
            if child:IsA("TextButton") and child ~= toggleButton and child ~= prevPageBtn and child ~= nextPageBtn then
                child.Visible = false
            end
        end
    else
        panel.Size = UDim2.new(0, 250, 0, 280)
        panel.BackgroundTransparency = 0.2
        updatePage()
    end
end)

-- Controle de páginas
local currentPage = 1
local totalPages = 3

local prevPageBtn = Instance.new("TextButton")
prevPageBtn.Size = UDim2.new(0, 40, 0, 30)
prevPageBtn.Position = UDim2.new(0, 10, 1, -40)
prevPageBtn.Text = "◀️"
prevPageBtn.Font = Enum.Font.SourceSansBold
prevPageBtn.TextSize = 20
prevPageBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
prevPageBtn.TextColor3 = Color3.new(1, 1, 1)
prevPageBtn.Parent = panel

local nextPageBtn = Instance.new("TextButton")
nextPageBtn.Size = UDim2.new(0, 40, 0, 30)
nextPageBtn.Position = UDim2.new(1, -50, 1, -40)
nextPageBtn.Text = "▶️"
nextPageBtn.Font = Enum.Font.SourceSansBold
nextPageBtn.TextSize = 20
nextPageBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
nextPageBtn.TextColor3 = Color3.new(1, 1, 1)
nextPageBtn.Parent = panel

-- Containers por página
local page1Container = Instance.new("Frame")
page1Container.Size = UDim2.new(1, -20, 1, -70)
page1Container.Position = UDim2.new(0, 10, 0, 40)
page1Container.BackgroundTransparency = 1
page1Container.Parent = panel

local page2Container = Instance.new("Frame")
page2Container.Size = page1Container.Size
page2Container.Position = page1Container.Position
page2Container.BackgroundTransparency = 1
page2Container.Parent = panel

local page3Container = Instance.new("Frame")
page3Container.Size = page1Container.Size
page3Container.Position = page1Container.Position
page3Container.BackgroundTransparency = 1
page3Container.Parent = panel

-- FUNÇÃO PARA ATUALIZAR PÁGINAS
local function updatePage()
    prevPageBtn.Visible = currentPage > 1 and not minimized
    nextPageBtn.Visible = currentPage < totalPages and not minimized

    page1Container.Visible = (currentPage == 1 and not minimized)
    page2Container.Visible = (currentPage == 2 and not minimized)
    page3Container.Visible = (currentPage == 3 and not minimized)
end

prevPageBtn.MouseButton1Click:Connect(function()
    if currentPage > 1 then
        currentPage = currentPage - 1
        updatePage()
    end
end)

nextPageBtn.MouseButton1Click:Connect(function()
    if currentPage < totalPages then
        currentPage = currentPage + 1
        updatePage()
    end
end)

updatePage()

-- ======= Conteúdo da página 1 =======

local aimbotAutoBtn = Instance.new("TextButton")
aimbotAutoBtn.Size = UDim2.new(1, 0, 0, 30)
aimbotAutoBtn.Position = UDim2.new(0, 0, 0, 0)
aimbotAutoBtn.Text = "Aimbot Auto: OFF"
aimbotAutoBtn.Font = Enum.Font.SourceSansBold
aimbotAutoBtn.TextSize = 18
aimbotAutoBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
aimbotAutoBtn.TextColor3 = Color3.new(1, 1, 1)
aimbotAutoBtn.Parent = page1Container

local aimbotManualBtn = Instance.new("TextButton")
aimbotManualBtn.Size = aimbotAutoBtn.Size
aimbotManualBtn.Position = UDim2.new(0, 0, 0, 40)
aimbotManualBtn.Text = "Aimbot Manual: OFF"
aimbotManualBtn.Font = aimbotAutoBtn.Font
aimbotManualBtn.TextSize = aimbotAutoBtn.TextSize
aimbotManualBtn.BackgroundColor3 = aimbotAutoBtn.BackgroundColor3
aimbotManualBtn.TextColor3 = aimbotAutoBtn.TextColor3
aimbotManualBtn.Parent = page1Container

local aimbotLegitBtn = Instance.new("TextButton")
aimbotLegitBtn.Size = aimbotAutoBtn.Size
aimbotLegitBtn.Position = UDim2.new(0, 0, 0, 80)
aimbotLegitBtn.Text = "Aimbot Legit: OFF"
aimbotLegitBtn.Font = aimbotAutoBtn.Font
aimbotLegitBtn.TextSize = aimbotAutoBtn.TextSize
aimbotLegitBtn.BackgroundColor3 = aimbotAutoBtn.BackgroundColor3
aimbotLegitBtn.TextColor3 = aimbotAutoBtn.TextColor3
aimbotLegitBtn.Parent = page1Container

local showFOVBtn = Instance.new("TextButton")
showFOVBtn.Size = aimbotAutoBtn.Size
showFOVBtn.Position = UDim2.new(0, 0, 0, 120)
showFOVBtn.Text = "Mostrar FOV: OFF"
showFOVBtn.Font = aimbotAutoBtn.Font
showFOVBtn.TextSize = aimbotAutoBtn.TextSize
showFOVBtn.BackgroundColor3 = aimbotAutoBtn.BackgroundColor3
showFOVBtn.TextColor3 = aimbotAutoBtn.TextColor3
showFOVBtn.Parent = page1Container

local minusFOVBtn = Instance.new("TextButton")
minusFOVBtn.Size = UDim2.new(0.5, -10, 0, 30)
minusFOVBtn.Position = UDim2.new(0, 0, 0, 160)
minusFOVBtn.Text = "- FOV"
minusFOVBtn.Font = aimbotAutoBtn.Font
minusFOVBtn.TextSize = 18
minusFOVBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
minusFOVBtn.TextColor3 = Color3.new(1,1,1)
minusFOVBtn.Parent = page1Container

local plusFOVBtn = Instance.new("TextButton")
plusFOVBtn.Size = minusFOVBtn.Size
plusFOVBtn.Position = UDim2.new(0.5, 10, 0, 160)
plusFOVBtn.Text = "+ FOV"
plusFOVBtn.Font = minusFOVBtn.Font
plusFOVBtn.TextSize = minusFOVBtn.TextSize
plusFOVBtn.BackgroundColor3 = minusFOVBtn.BackgroundColor3
plusFOVBtn.TextColor3 = minusFOVBtn.TextColor3
plusFOVBtn.Parent = page1Container

-- Funções toggle para aimbot
local function toggleButton(btn, flagName, exclusiveFlags)
    btn.MouseButton1Click:Connect(function()
        _G[flagName] = not _G[flagName]
        if exclusiveFlags then
            for _, flag in pairs(exclusiveFlags) do
                if flag ~= flagName then
                    _G[flag] = false
                end
            end
        end
        btn.Text = btn.Text:match("^(.-):") .. ": " .. (_G[flagName] and "ON" or "OFF")
        updatePage() -- garante atualização visual
    end)
end

toggleButton(aimbotAutoBtn, "aimbotAutoEnabled", {"aimbotManualEnabled", "aimbotLegitEnabled"})
toggleButton(aimbotManualBtn, "aimbotManualEnabled", {"aimbotAutoEnabled", "aimbotLegitEnabled"})
toggleButton(aimbotLegitBtn, "aimbotLegitEnabled", {"aimbotAutoEnabled", "aimbotManualEnabled"})
toggleButton(showFOVBtn, "FOV_VISIBLE")

minusFOVBtn.MouseButton1Click:Connect(function()
    _G.FOV_RADIUS = math.clamp(_G.FOV_RADIUS - 5, 10, 300)
end)

plusFOVBtn.MouseButton1Click:Connect(function()
    _G.FOV_RADIUS = math.clamp(_G.FOV_RADIUS + 5, 10, 300)
end)

-- ======= Conteúdo da página 2 =======

local espEnemiesBtn = Instance.new("TextButton")
espEnemiesBtn.Size = aimbotAutoBtn.Size
espEnemiesBtn.Position = UDim2.new(0, 0, 0, 0)
espEnemiesBtn.Text = "ESP Inimigos: ON"
espEnemiesBtn.Font = aimbotAutoBtn.Font
espEnemiesBtn.TextSize = aimbotAutoBtn.TextSize
espEnemiesBtn.BackgroundColor3 = aimbotAutoBtn.BackgroundColor3
espEnemiesBtn.TextColor3 = aimbotAutoBtn.TextColor3
espEnemiesBtn.Parent = page2Container

local espAlliesBtn = Instance.new("TextButton")
espAlliesBtn.Size = aimbotAutoBtn.Size
espAlliesBtn.Position = UDim2.new(0, 0, 0, 40)
espAlliesBtn.Text = "ESP Aliados: OFF"
espAlliesBtn.Font = aimbotAutoBtn.Font
espAlliesBtn.TextSize = aimbotAutoBtn.TextSize
espAlliesBtn.BackgroundColor3 = aimbotAutoBtn.BackgroundColor3
espAlliesBtn.TextColor3 = aimbotAutoBtn.TextColor3
espAlliesBtn.Parent = page2Container

local espBoxBtn = Instance.new("TextButton")
espBoxBtn.Size = aimbotAutoBtn.Size
espBoxBtn.Position = UDim2.new(0, 0, 0, 80)
espBoxBtn.Text = "Box ESP: ON"
espBoxBtn.Font = aimbotAutoBtn.Font
espBoxBtn.TextSize = aimbotAutoBtn.TextSize
espBoxBtn.BackgroundColor3 = aimbotAutoBtn.BackgroundColor3
espBoxBtn.TextColor3 = aimbotAutoBtn.TextColor3
espBoxBtn.Parent = page2Container

local espLineBtn = Instance.new("TextButton")
espLineBtn.Size = aimbotAutoBtn.Size
espLineBtn.Position = UDim2.new(0, 0, 0, 120)
espLineBtn.Text = "Linha ESP: OFF"
espLineBtn.Font = aimbotAutoBtn.Font
espLineBtn.TextSize = aimbotAutoBtn.TextSize
espLineBtn.BackgroundColor3 = aimbotAutoBtn.BackgroundColor3
espLineBtn.TextColor3 = aimbotAutoBtn.TextColor3
espLineBtn.Parent = page2Container

local espHPBtn = Instance.new("TextButton")
espHPBtn.Size = aimbotAutoBtn.Size
espHPBtn.Position = UDim2.new(0, 0, 0, 160)
espHPBtn.Text = "HP ESP: ON"
espHPBtn.Font = aimbotAutoBtn.Font
espHPBtn.TextSize = aimbotAutoBtn.TextSize
espHPBtn.BackgroundColor3 = aimbotAutoBtn.BackgroundColor3
espHPBtn.TextColor3 = aimbotAutoBtn.TextColor3
espHPBtn.Parent = page2Container

local espDistBtn = Instance.new("TextButton")
espDistBtn.Size = aimbotAutoBtn.Size
espDistBtn.Position = UDim2.new(0, 0, 0, 200)
espDistBtn.Text = "Distância ESP: OFF"
espDistBtn.Font = aimbotAutoBtn.Font
espDistBtn.TextSize = aimbotAutoBtn.TextSize
espDistBtn.BackgroundColor3 = aimbotAutoBtn.BackgroundColor3
espDistBtn.TextColor3 = aimbotAutoBtn.TextColor3
espDistBtn.Parent = page2Container

-- Toggle para ESPs
toggleButton(espEnemiesBtn, "espEnemiesEnabled")
toggleButton(espAlliesBtn, "espAlliesEnabled")
toggleButton(espBoxBtn, "espBoxEnabled")
toggleButton(espLineBtn, "espLineEnabled")
toggleButton(espHPBtn, "espHealthBarEnabled")
toggleButton(espDistBtn, "espDistanceEnabled")

-- ======= Conteúdo da página 3 (Tutorial) =======

local tutorialText = [[
Como usar o menu:

Página 1: Controle dos Aimbots e FOV
- Aimbot Auto: Mira e atira automaticamente
- Aimbot Manual: Mira automática, você atira
- Aimbot Legit: Mira e atira precisos e seguros
- Mostrar FOV: Exibe o círculo do campo de visão
- +FOV / -FOV: Ajusta o tamanho do círculo do FOV

Página 2: ESP e Wallhack
- Ative/desative ESP para inimigos e aliados
- Escolha exibir box, linha, HP e distância dos jogadores

Página 3: Tutorial
- Esta página mostra informações sobre o uso do menu
- Clique no botão para fechar este tutorial
]]

local tutorialLabel = Instance.new("TextLabel")
tutorialLabel.Size = UDim2.new(1, -20, 1, -40)
tutorialLabel.Position = UDim2.new(0, 10, 0, 10)
tutorialLabel.BackgroundTransparency = 1
tutorialLabel.TextColor3 = Color3.new(1,1,1)
tutorialLabel.Font = Enum.Font.SourceSans
tutorialLabel.TextSize = 16
tutorialLabel.TextWrapped = true
tutorialLabel.Text = tutorialText
tutorialLabel.Parent = page3Container

local closeTutorialBtn = Instance.new("TextButton")
closeTutorialBtn.Size = UDim2.new(0, 80, 0, 30)
closeTutorialBtn.Position = UDim2.new(1, -90, 1, -40)
closeTutorialBtn.Text = "Fechar"
closeTutorialBtn.Font = Enum.Font.SourceSansBold
closeTutorialBtn.TextSize = 16
closeTutorialBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
closeTutorialBtn.TextColor3 = Color3.new(1,1,1)
closeTutorialBtn.Parent = page3Container

closeTutorialBtn.MouseButton1Click:Connect(function()
    page3Container.Visible = false
end)

-- Inicializa página 3 invisível (abre só clicando em tutorial)
page3Container.Visible = false

-- Botão para abrir tutorial (sempre visível no painel)
local openTutorialBtn = Instance.new("TextButton")
openTutorialBtn.Size = UDim2.new(1, 0, 0, 30)
openTutorialBtn.Position = UDim2.new(0, 0, 1, -40)
openTutorialBtn.Text = "Abrir Tutorial"
openTutorialBtn.Font = Enum.Font.SourceSansBold
openTutorialBtn.TextSize = 18
openTutorialBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
openTutorialBtn.TextColor3 = Color3.new(1,1,1)
openTutorialBtn.Parent = panel

openTutorialBtn.MouseButton1Click:Connect(function()
    page3Container.Visible = true
end)

-- Função para atualizar visibilidade após abrir tutorial
local oldUpdatePage = updatePage
updatePage = function()
    if minimized then
        prevPageBtn.Visible = false
        nextPageBtn.Visible = false
        page1Container.Visible = false
        page2Container.Visible = false
        page3Container.Visible = false
        openTutorialBtn.Visible = false
    else
        -- Se tutorial aberto, esconde páginas normais
        if page3Container.Visible then
            prevPageBtn.Visible = false
            nextPageBtn.Visible = false
            page1Container.Visible = false
            page2Container.Visible = false
            openTutorialBtn.Visible = false
        else
            prevPageBtn.Visible = currentPage > 1
            nextPageBtn.Visible = currentPage < totalPages
            page1Container.Visible = currentPage == 1
            page2Container.Visible = currentPage == 2
            page3Container.Visible = false
            openTutorialBtn.Visible = true
        end
    end
end

updatePage()

-- CONTINUAÇÃO: Popup seleção de hitbox (menu Bacon)

local hitboxPopup = Instance.new("Frame")
hitboxPopup.Size = UDim2.new(0, 300, 0, 400)
hitboxPopup.Position = UDim2.new(0.5, -150, 0.5, -200)
hitboxPopup.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
hitboxPopup.BorderSizePixel = 0
hitboxPopup.Visible = false
hitboxPopup.ZIndex = 10
hitboxPopup.Parent = gui

-- Fundo escuro semi transparente para popup
local popupBg = Instance.new("TextButton")
popupBg.Size = UDim2.new(1, 0, 1, 0)
popupBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
popupBg.BackgroundTransparency = 0.7
popupBg.AutoButtonColor = false
popupBg.Text = ""
popupBg.Parent = hitboxPopup

popupBg.MouseButton1Click:Connect(function()
    hitboxPopup.Visible = false
end)

-- Imagem do personagem Bacon (use o asset correto do Roblox)
local baconImage = Instance.new("ImageLabel")
baconImage.Size = UDim2.new(0, 280, 0, 320)
baconImage.Position = UDim2.new(0, 10, 0, 10)
baconImage.BackgroundTransparency = 1
baconImage.Image = "rbxassetid://108276646" -- Exemplo: imagem do Bacon Roblox
baconImage.Parent = hitboxPopup

-- Título
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Seleção de Hitbox"
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 20
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.Parent = hitboxPopup

-- Função para criar área clicável invisível
local function createHitboxButton(name, pos, size)
    local btn = Instance.new("TextButton")
    btn.Size = size
    btn.Position = pos
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = baconImage

    btn.MouseButton1Click:Connect(function()
        local currentState = _G.hitboxSelection[name]
        if currentState == "Nenhum" then
            _G.hitboxSelection[name] = "Prioritário"
        else
            _G.hitboxSelection[name] = "Nenhum"
        end
        updateHitboxButtons()
    end)
    return btn
end

-- Criar botões invisíveis para as partes do corpo (ajuste posições e tamanhos conforme imagem Bacon)
local hitboxButtons = {
    Head = createHitboxButton("Head", UDim2.new(0.4, 0, 0.05, 0), UDim2.new(0.2, 0, 0.15, 0)),
    Torso = createHitboxButton("Torso", UDim2.new(0.35, 0, 0.2, 0), UDim2.new(0.3, 0, 0.3, 0)),
    LeftArm = createHitboxButton("LeftArm", UDim2.new(0.1, 0, 0.2, 0), UDim2.new(0.15, 0, 0.3, 0)),
    RightArm = createHitboxButton("RightArm", UDim2.new(0.75, 0, 0.2, 0), UDim2.new(0.15, 0, 0.3, 0)),
    LeftLeg = createHitboxButton("LeftLeg", UDim2.new(0.4, 0, 0.5, 0), UDim2.new(0.15, 0, 0.3, 0)),
    RightLeg = createHitboxButton("RightLeg", UDim2.new(0.55, 0, 0.5, 0), UDim2.new(0.15, 0, 0.3, 0)),
}

-- Função para atualizar visual das áreas com base no estado (desenhar bordas)
function updateHitboxButtons()
    for part, btn in pairs(hitboxButtons) do
        if _G.hitboxSelection[part] == "Prioritário" then
            btn.BackgroundTransparency = 0.5
            btn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        else
            btn.BackgroundTransparency = 1
        end
    end
end

updateHitboxButtons()

-- Botão para abrir o popup de hitbox na página 1
local openHitboxPopupBtn = Instance.new("TextButton")
openHitboxPopupBtn.Size = UDim2.new(1, 0, 0, 30)
openHitboxPopupBtn.Position = UDim2.new(0, 0, 0, 200)
openHitboxPopupBtn.Text = "Selecionar Hitbox"
openHitboxPopupBtn.Font = Enum.Font.SourceSansBold
openHitboxPopupBtn.TextSize = 18
openHitboxPopupBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
openHitboxPopupBtn.TextColor3 = Color3.new(1, 1, 1)
openHitboxPopupBtn.Parent = page1Container

openHitboxPopupBtn.MouseButton1Click:Connect(function()
    hitboxPopup.Visible = true
end)

-- Por fim, evitar que o GUI suma após morrer
return gui
