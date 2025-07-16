
-- Criação do Menu GUI
local player = game.Players.LocalPlayer
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CustomMenuGUI"
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 200)
frame.Position = UDim2.new(0.5, -150, 0.5, -100)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Parent = screenGui

-- Página atual
local currentPage = 1

-- Função para limpar botões antigos
local function clearButtons()
    for _, child in ipairs(frame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
end

-- Função para criar botões da página 1
local function createPage1()
    clearButtons()
    local btnNames = {"Infinite Ammo", "Auto Spread", "Instant Reload", "Fastshot"}
    for i, name in ipairs(btnNames) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 260, 0, 35)
        btn.Position = UDim2.new(0, 20, 0, 20 + (i-1)*45)
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.Text = name
        btn.Font = Enum.Font.SourceSansBold
        btn.TextSize = 20
        btn.Parent = frame
        -- Aqui você pode conectar as funções dos botões depois
    end
end

-- ======= MENU DE PÁGINAS E BOTÕES EXTRAS =======
local currentPage = 1
local pageButtons = {}

local function clearPageButtons()
    for _, btn in ipairs(pageButtons) do
        if btn and btn.Parent then btn:Destroy() end
    end
    pageButtons = {}
end

local infiniteAmmoEnabled = false
local autoSpreadEnabled = false
local instantReloadEnabled = false
local fastShotEnabled = false

local function applyGunMods(tool)
    if not tool then return end
    if infiniteAmmoEnabled then
        tool:SetAttribute("_ammo", 200)
        tool:SetAttribute("magazineSize", 200)
    end
    if autoSpreadEnabled then
        tool:SetAttribute("spread", 0)
        tool:SetAttribute("recoilAimReduction", Vector2.new(0,0))
        tool:SetAttribute("recoilMax", Vector2.new(0,0))
        tool:SetAttribute("recoilMin", Vector2.new(0,0))
    end
    if instantReloadEnabled then
        tool:SetAttribute("reloadTime", 0)
    end
    if fastShotEnabled then
        tool:SetAttribute("rateOfFire", 200)
    end
end

local function resetGunMods(tool)
    if not tool then return end
    -- Aqui você pode colocar valores padrão do jogo, se souber
    -- Exemplo:
    -- tool:SetAttribute("_ammo", 30)
    -- tool:SetAttribute("magazineSize", 30)
    -- tool:SetAttribute("spread", 1)
    -- tool:SetAttribute("recoilAimReduction", Vector2.new(0.1,0.1))
    -- tool:SetAttribute("recoilMax", Vector2.new(1,1))
    -- tool:SetAttribute("recoilMin", Vector2.new(0.5,0.5))
    -- tool:SetAttribute("reloadTime", 1.5)
    -- tool:SetAttribute("rateOfFire", 10)
end

local function updateGunMods()
    local char = player.Character
    if not char then return end
    local tool = char:FindFirstChildWhichIsA("Tool")
    if tool then
        applyGunMods(tool)
    end
end

player.CharacterAdded:Connect(function(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait(0.1)
            applyGunMods(child)
        end
    end)
end)

local function createPage1Buttons()
    clearPageButtons()
    -- Infinite Ammo
    local btn1 = Instance.new("TextButton")
    btn1.Size = UDim2.new(1, -20, 0, 30)
    btn1.Position = UDim2.new(0, 10, 0, 40)
    btn1.Text = "Infinite Ammo: OFF"
    btn1.Font = Enum.Font.SourceSansBold
    btn1.TextSize = 16
    btn1.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn1.TextColor3 = Color3.new(1, 1, 1)
    btn1.Parent = frame
    btn1.MouseButton1Click:Connect(function()
        infiniteAmmoEnabled = not infiniteAmmoEnabled
        btn1.Text = "Infinite Ammo: "..(infiniteAmmoEnabled and "ON" or "OFF")
        updateGunMods()
    end)
    table.insert(pageButtons, btn1)

    -- Auto Spread
    local btn2 = Instance.new("TextButton")
    btn2.Size = UDim2.new(1, -20, 0, 30)
    btn2.Position = UDim2.new(0, 10, 0, 75)
    btn2.Text = "Auto Spread: OFF"
    btn2.Font = Enum.Font.SourceSansBold
    btn2.TextSize = 16
    btn2.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn2.TextColor3 = Color3.new(1, 1, 1)
    btn2.Parent = frame
    btn2.MouseButton1Click:Connect(function()
        autoSpreadEnabled = not autoSpreadEnabled
        btn2.Text = "Auto Spread: "..(autoSpreadEnabled and "ON" or "OFF")
        updateGunMods()
    end)
    table.insert(pageButtons, btn2)

    -- Instant Reload
    local btn3 = Instance.new("TextButton")
    btn3.Size = UDim2.new(1, -20, 0, 30)
    btn3.Position = UDim2.new(0, 10, 0, 110)
    btn3.Text = "Instant Reload: OFF"
    btn3.Font = Enum.Font.SourceSansBold
    btn3.TextSize = 16
    btn3.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn3.TextColor3 = Color3.new(1, 1, 1)
    btn3.Parent = frame
    btn3.MouseButton1Click:Connect(function()
        instantReloadEnabled = not instantReloadEnabled
        btn3.Text = "Instant Reload: "..(instantReloadEnabled and "ON" or "OFF")
        updateGunMods()
    end)
    table.insert(pageButtons, btn3)

    -- Fast Shot
    local btn4 = Instance.new("TextButton")
    btn4.Size = UDim2.new(1, -20, 0, 30)
    btn4.Position = UDim2.new(0, 10, 0, 145)
    btn4.Text = "Fast Shot: OFF"
    btn4.Font = Enum.Font.SourceSansBold
    btn4.TextSize = 16
    btn4.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn4.TextColor3 = Color3.new(1, 1, 1)
    btn4.Parent = frame
    btn4.MouseButton1Click:Connect(function()
        fastShotEnabled = not fastShotEnabled
        btn4.Text = "Fast Shot: "..(fastShotEnabled and "ON" or "OFF")
        updateGunMods()
    end)
    table.insert(pageButtons, btn4)
end

local function createPage2Buttons()
    clearPageButtons()
    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, -20, 0, 30)
    info.Position = UDim2.new(0, 10, 0, 40)
    info.BackgroundTransparency = 1
    info.TextColor3 = Color3.fromRGB(200,200,200)
    info.Text = "Página 2\n(Adicione mais funções aqui)"
    info.Font = Enum.Font.SourceSans
    info.TextSize = 18
    info.Parent = frame
    table.insert(pageButtons, info)
end

local function updatePage()
    if currentPage == 1 then
        createPage1Buttons()
    elseif currentPage == 2 then
        createPage2Buttons()
    end
end

-- Botão de avançar página ▶️
local nextBtn = Instance.new("TextButton")
nextBtn.Size = UDim2.new(0, 30, 0, 30)
nextBtn.Position = UDim2.new(1, -35, 1, -35)
nextBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
nextBtn.Text = "▶️"
nextBtn.Font = Enum.Font.SourceSansBold
nextBtn.TextSize = 20
nextBtn.TextColor3 = Color3.fromRGB(255,255,255)
nextBtn.Parent = frame

-- Botão de voltar página ◀️
local prevBtn = Instance.new("TextButton")
prevBtn.Size = UDim2.new(0, 30, 0, 30)
prevBtn.Position = UDim2.new(0, 5, 1, -35)
prevBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
prevBtn.Text = "◀️"
prevBtn.Font = Enum.Font.SourceSansBold
prevBtn.TextSize = 20
prevBtn.TextColor3 = Color3.fromRGB(255,255,255)
prevBtn.Parent = frame

nextBtn.MouseButton1Click:Connect(function()
    if currentPage < 2 then
        currentPage = currentPage + 1
        updatePage()
    end
end)
prevBtn.MouseButton1Click:Connect(function()
    if currentPage > 1 then
        currentPage = currentPage - 1
        updatePage()
    end
end)

-- Inicializa na página 1
updatePage()

-- Função para criar botões toggle com exclusividade entre 2 flags
local function createToggleButton(text, yPos, flagName, exclusiveFlag)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 30)
    button.Position = UDim2.new(0, 10, 0, yPos)
    button.Text = text .. ": OFF"
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 16
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Parent = frame

    button.MouseButton1Click:Connect(function()
        _G[flagName] = not _G[flagName]
        -- Exclusividade entre aimbots automático e manual
        if exclusiveFlag and _G[flagName] then
            _G[exclusiveFlag] = false
        end
        button.Text = text .. (_G[flagName] and ": ON" or ": OFF")

        -- Atualiza botão irmão (exclusivo)
        if exclusiveFlag then
            for _, sibling in pairs(frame:GetChildren()) do
                if sibling:IsA("TextButton") and sibling ~= button then
                    local siblingText = sibling.Text:lower()
                    local exclusiveFlagText = exclusiveFlag:gsub("([A-Z])", " %1"):lower()
                    exclusiveFlagText = exclusiveFlagText:gsub("^%l", string.upper)
                    if siblingText:find(exclusiveFlagText) then
                        sibling.Text = sibling.Text:sub(1, sibling.Text:find(":")) .. (_G[exclusiveFlag] and " ON" or " OFF")
                    end
                end
            end
        end
    end)
    return button
end

-- Função para criar botões da página 2 (exemplo, pode adicionar mais depois)
local function createPage2()
    clearButtons()
    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, 0, 1, 0)
    info.BackgroundTransparency = 1
    info.TextColor3 = Color3.fromRGB(200,200,200)
    info.Text = "Página 2\n(Adicione mais funções aqui)"
    info.Font = Enum.Font.SourceSans
    info.TextSize = 22
    info.Parent = frame
end

-- Botão de avançar página ▶️
local nextBtn = Instance.new("TextButton")
nextBtn.Size = UDim2.new(0, 40, 0, 40)
nextBtn.Position = UDim2.new(1, -45, 1, -45)
nextBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
nextBtn.Text = "▶️"
nextBtn.Font = Enum.Font.SourceSansBold
nextBtn.TextSize = 24
nextBtn.TextColor3 = Color3.fromRGB(255,255,255)
nextBtn.Parent = frame

-- Botão de voltar página ◀️
local prevBtn = Instance.new("TextButton")
prevBtn.Size = UDim2.new(0, 40, 0, 40)
prevBtn.Position = UDim2.new(0, 5, 1, -45)
prevBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
prevBtn.Text = "◀️"
prevBtn.Font = Enum.Font.SourceSansBold
prevBtn.TextSize = 24
prevBtn.TextColor3 = Color3.fromRGB(255,255,255)
prevBtn.Parent = frame

-- Funções de navegação
local function updatePage()
    if currentPage == 1 then
        createPage1()
    elseif currentPage == 2 then
        createPage2()
    end
end

nextBtn.MouseButton1Click:Connect(function()
    if currentPage < 2 then
        currentPage = currentPage + 1
        updatePage()
    end
end)

prevBtn.MouseButton1Click:Connect(function()
    if currentPage > 1 then
        currentPage = currentPage - 1
        updatePage()
    end
end)

-- Inicializa na página 1
updatePage()
