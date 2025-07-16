local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Criar ScreenGui principal
local gui = Instance.new("ScreenGui")
gui.Name = "AimbotESPGui"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

-- Painel principal
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 380, 0, 300)
panel.Position = UDim2.new(0.5, -190, 0.5, -150)
panel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
panel.BorderSizePixel = 0
panel.Parent = gui

-- Função para criar botões simples
local function createButton(text, posY)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 30)
    btn.Position = UDim2.new(0, 10, 0, posY)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 16
    btn.Text = text
    btn.Parent = panel
    return btn
end

-- Criar botões da página 1 (Aimbots + FOV)
local aimbotAutoBtn = createButton("Aimbot Automático", 10)
local aimbotManualBtn = createButton("Aimbot Manual", 50)
local aimbotLegitBtn = createButton("Aimbot Legit", 90)

local showFOVBtn = createButton("Mostrar FOV: OFF", 130)
local btnFovMinus = createButton("- FOV", 170)
local btnFovPlus = createButton("+ FOV", 210)

-- Criar botões da página 2 (ESP + Seleção Hitbox)
local espEnemiesBtn = createButton("ESP Inimigos", 10)
local espAlliesBtn = createButton("ESP Aliados", 50)
local espBoxBtn = createButton("Box ESP", 90)
local espLineBtn = createButton("Linha ESP", 130)
local espNameBtn = createButton("Nome ESP", 170)
local espHealthBtn = createButton("HP ESP", 210)
local espDistanceBtn = createButton("Distância ESP", 250)
local btnSelectHitbox = createButton("Selecionar Hitbox", 290)

-- Inicialmente esconder página 2 e 3
local function setPageVisibility(page)
    local p1Buttons = {aimbotAutoBtn, aimbotManualBtn, aimbotLegitBtn, showFOVBtn, btnFovMinus, btnFovPlus}
    local p2Buttons = {espEnemiesBtn, espAlliesBtn, espBoxBtn, espLineBtn, espNameBtn, espHealthBtn, espDistanceBtn, btnSelectHitbox}
    local p3Elements = {} -- preencher depois

    for _, btn in pairs(p1Buttons) do
        btn.Visible = (page == 1)
    end
    for _, btn in pairs(p2Buttons) do
        btn.Visible = (page == 2)
    end
    -- p3: mostrar tutorial, etc (se existir)
end

-- Botões de navegação
local btnNext = Instance.new("TextButton")
btnNext.Size = UDim2.new(0, 40, 0, 30)
btnNext.Position = UDim2.new(1, -50, 1, -40)
btnNext.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
btnNext.TextColor3 = Color3.new(1, 1, 1)
btnNext.Font = Enum.Font.SourceSansBold
btnNext.TextSize = 22
btnNext.Text = "▶️"
btnNext.Parent = panel

local btnBack = Instance.new("TextButton")
btnBack.Size = UDim2.new(0, 40, 0, 30)
btnBack.Position = UDim2.new(0, 10, 1, -40)
btnBack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
btnBack.TextColor3 = Color3.new(1, 1, 1)
btnBack.Font = Enum.Font.SourceSansBold
btnBack.TextSize = 22
btnBack.Text = "◀️"
btnBack.Parent = panel

local currentPage = 1
setPageVisibility(currentPage)

btnNext.MouseButton1Click:Connect(function()
    if currentPage < 3 then
        currentPage = currentPage + 1
        setPageVisibility(currentPage)
    end
end)

btnBack.MouseButton1Click:Connect(function()
    if currentPage > 1 then
        currentPage = currentPage - 1
        setPageVisibility(currentPage)
    end
end)

-- Criar popup seleção hitbox
local hitboxPopup = Instance.new("Frame")
hitboxPopup.Size = UDim2.new(0, 280, 0, 380)
hitboxPopup.Position = UDim2.new(0.5, -140, 0.5, -190)
hitboxPopup.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
hitboxPopup.BorderSizePixel = 0
hitboxPopup.Visible = false
hitboxPopup.Parent = gui

local closePopupBtn = Instance.new("TextButton")
closePopupBtn.Size = UDim2.new(0, 80, 0, 30)
closePopupBtn.Position = UDim2.new(1, -90, 0, 10)
closePopupBtn.Text = "Fechar"
closePopupBtn.Font = Enum.Font.SourceSansBold
closePopupBtn.TextSize = 16
closePopupBtn.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
closePopupBtn.TextColor3 = Color3.new(1, 1, 1)
closePopupBtn.Parent = hitboxPopup

closePopupBtn.MouseButton1Click:Connect(function()
    hitboxPopup.Visible = false
end)

local baconImage = Instance.new("ImageLabel")
baconImage.Size = UDim2.new(1, -20, 1, -60)
baconImage.Position = UDim2.new(0, 10, 0, 50)
baconImage.BackgroundTransparency = 1
baconImage.Image = "rbxassetid://8967307840" -- Substitua pela imagem desejada
baconImage.Parent = hitboxPopup

-- Criar botões invisíveis para cada parte do corpo
local parts = {
    {Name = "Head", Position = UDim2.new(0.35, 0, 0.05, 0), Size = UDim2.new(0, 60, 0, 60)},
    {Name = "Torso", Position = UDim2.new(0.3, 0, 0.35, 0), Size = UDim2.new(0, 80, 0, 110)},
    {Name = "LeftArm", Position = UDim2.new(0.1, 0, 0.35, 0), Size = UDim2.new(0, 50, 0, 110)},
    {Name = "RightArm", Position = UDim2.new(0.65, 0, 0.35, 0), Size = UDim2.new(0, 50, 0, 110)},
    {Name = "LeftLeg", Position = UDim2.new(0.35, 0, 0.75, 0), Size = UDim2.new(0, 50, 0, 100)},
    {Name = "RightLeg", Position = UDim2.new(0.55, 0, 0.75, 0), Size = UDim2.new(0, 50, 0, 100)},
}

local hitboxSelection = {
    Head = "Prioritário",
    Torso = "Nenhum",
    LeftArm = "Nenhum",
    RightArm = "Nenhum",
    LeftLeg = "Nenhum",
    RightLeg = "Nenhum",
}

local hitboxButtons = {}

local function updateHitboxBtnVisual(btn, state)
    if state == "Nenhum" then
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        btn.BackgroundTransparency = 0.7
    elseif state == "Prioritário" then
        btn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        btn.BackgroundTransparency = 0.3
    end
end

for _, part in ipairs(parts) do
    local btn = Instance.new("TextButton")
    btn.Name = part.Name .. "Button"
    btn.Size = part.Size
    btn.Position = part.Position
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.BackgroundTransparency = 0.7
    btn.Text = ""
    btn.Parent = baconImage
    btn.ZIndex = 2

    btn.MouseButton1Click:Connect(function()
        if hitboxSelection[part.Name] == "Nenhum" then
            hitboxSelection[part.Name] = "Prioritário"
        else
            hitboxSelection[part.Name] = "Nenhum"
        end
        updateHitboxBtnVisual(btn, hitboxSelection[part.Name])
        _G.hitboxSelection = hitboxSelection -- Atualiza global
    end)

    updateHitboxBtnVisual(btn, hitboxSelection[part.Name])
    hitboxButtons[part.Name] = btn
end

-- Abrir popup ao clicar no botão de selecionar hitbox
btnSelectHitbox.MouseButton1Click:Connect(function()
    hitboxPopup.Visible = true
end)

-- Atualiza o global hitboxSelection para o uso do aimbot
_G.hitboxSelection = hitboxSelection

return gui
