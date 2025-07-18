--[[
    Script Avançado de Aimbot & ESP para Roblox - Versão Melhorada
    Criado para uso com Delta Executor
    
    Novas Funcionalidades:
    - Menu ESP expandido com opções detalhadas
    - Controle de Rapid Fire ajustável
    - ESP com Linha, Nome, Distância, HP e Quadrados
    - Wallhack separado para inimigos e aliados
    - Interface compacta e organizada
    
    Versão: 3.0 - Português BR
]]--

-- Serviços do Roblox
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Configurações globais melhoradas
_G.FOV_RADIUS = 80
_G.FOV_VISIBLE = true
_G.aimbotAutoEnabled = false
_G.aimbotManualEnabled = false

-- Configurações ESP Inimigos
_G.espInimigosAtivado = true
_G.espInimigosLinha = false
_G.espInimigosNome = false
_G.espInimigosDistancia = false
_G.espInimigosHP = false
_G.espInimigosQuadrado = true  -- Ativo por padrão
_G.wallhackInimigos = false

-- Configurações ESP Aliados
_G.espAliadosAtivado = false
_G.espAliadosLinha = false
_G.espAliadosNome = false
_G.espAliadosDistancia = false
_G.espAliadosHP = false
_G.espAliadosQuadrado = false
_G.wallhackAliados = false

-- Configurações de Armas
_G.noRecoilEnabled = true
_G.infiniteAmmoEnabled = true
_G.instantReloadEnabled = true
_G.rapidFireEnabled = false
_G.rapidFireRate = 0.1  -- Taxa de disparo (menor = mais rápido)

-- Valores predefinidos para rapid fire
local RAPID_FIRE_PRESETS = {
    {nome = "Padrão", valor = 0.5},
    {nome = "Rápido", valor = 0.2},
    {nome = "Muito Rápido", valor = 0.1},
    {nome = "Ultra Rápido", valor = 0.05},
    {nome = "Extremo", valor = 0.02},
    {nome = "Absurdo", valor = 0.01}
}
_G.rapidFirePresetIndex = 3  -- Começa em "Muito Rápido"

-- Variáveis para controle de modificações ativas
local armasModificadas = {}
local conexoesAmmo = {}

-- Variáveis do sistema
local gui = nil
local mainMenu = nil
local currentTab = "aimbot"
local minimized = false
local espObjects = {}
local highlights = {}

-- Cores do tema
local CORES = {
    Fundo = Color3.fromRGB(20, 20, 25),
    FundoSecundario = Color3.fromRGB(30, 30, 35),
    Principal = Color3.fromRGB(70, 130, 255),
    Secundaria = Color3.fromRGB(50, 110, 235),
    Texto = Color3.fromRGB(255, 255, 255),
    TextoSecundario = Color3.fromRGB(180, 180, 180),
    Ativo = Color3.fromRGB(0, 200, 0),
    Inativo = Color3.fromRGB(60, 60, 60),
    Vermelho = Color3.fromRGB(255, 80, 80),
    Verde = Color3.fromRGB(80, 255, 80),
    Azul = Color3.fromRGB(80, 180, 255),
    Amarelo = Color3.fromRGB(255, 255, 80)
}

-- Função para criar interface principal
local function criarInterfacePrincipal()
    -- ScreenGui
    gui = Instance.new("ScreenGui")
    gui.Name = "MenuAimbotESPAvancado"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    -- Menu principal compacto
    mainMenu = Instance.new("Frame")
    mainMenu.Size = UDim2.new(0, 300, 0, 400)
    mainMenu.Position = UDim2.new(0, 20, 0, 80)
    mainMenu.BackgroundColor3 = CORES.Fundo
    mainMenu.BorderSizePixel = 0
    mainMenu.ClipsDescendants = true
    mainMenu.Parent = gui
    mainMenu.Active = true

    local menuCorner = Instance.new("UICorner")
    menuCorner.CornerRadius = UDim.new(0, 12)
    menuCorner.Parent = mainMenu

    -- Cabeçalho
    local cabecalho = Instance.new("Frame")
    cabecalho.Size = UDim2.new(1, 0, 0, 40)
    cabecalho.BackgroundColor3 = CORES.Principal
    cabecalho.BorderSizePixel = 0
    cabecalho.Parent = mainMenu

    local cabecalhoCorner = Instance.new("UICorner")
    cabecalhoCorner.CornerRadius = UDim.new(0, 12)
    cabecalhoCorner.Parent = cabecalho

    -- Título
    local titulo = Instance.new("TextLabel")
    titulo.Text = "🎯 Menu Avançado v3.0"
    titulo.Size = UDim2.new(1, -80, 1, 0)
    titulo.Position = UDim2.new(0, 10, 0, 0)
    titulo.BackgroundTransparency = 1
    titulo.TextColor3 = CORES.Texto
    titulo.Font = Enum.Font.GothamBold
    titulo.TextSize = 16
    titulo.TextXAlignment = Enum.TextXAlignment.Left
    titulo.Parent = cabecalho

    -- Botões de controle
    local botaoMinimizar = Instance.new("TextButton")
    botaoMinimizar.Size = UDim2.new(0, 30, 0, 30)
    botaoMinimizar.Position = UDim2.new(1, -65, 0.5, -15)
    botaoMinimizar.BackgroundColor3 = CORES.Verde
    botaoMinimizar.TextColor3 = CORES.Texto
    botaoMinimizar.Font = Enum.Font.GothamBold
    botaoMinimizar.TextSize = 14
    botaoMinimizar.Text = "−"
    botaoMinimizar.Parent = cabecalho

    local cornerMin = Instance.new("UICorner")
    cornerMin.CornerRadius = UDim.new(0, 6)
    cornerMin.Parent = botaoMinimizar

    local botaoFechar = Instance.new("TextButton")
    botaoFechar.Size = UDim2.new(0, 30, 0, 30)
    botaoFechar.Position = UDim2.new(1, -32, 0.5, -15)
    botaoFechar.BackgroundColor3 = CORES.Vermelho
    botaoFechar.TextColor3 = CORES.Texto
    botaoFechar.Font = Enum.Font.GothamBold
    botaoFechar.TextSize = 12
    botaoFechar.Text = "✕"
    botaoFechar.Parent = cabecalho

    local cornerFechar = Instance.new("UICorner")
    cornerFechar.CornerRadius = UDim.new(0, 6)
    cornerFechar.Parent = botaoFechar

    -- Funcionalidade dos botões
    botaoMinimizar.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            mainMenu.Size = UDim2.new(0, 300, 0, 40)
            botaoMinimizar.Text = "+"
        else
            mainMenu.Size = UDim2.new(0, 300, 0, 400)
            botaoMinimizar.Text = "−"
        end
    end)

    botaoFechar.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)

    -- Sistema de arrastar
    local arrastando = false
    local inicioArrastamento = nil
    local posicaoInicial = nil

    cabecalho.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            arrastando = true
            inicioArrastamento = input.Position
            posicaoInicial = mainMenu.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    arrastando = false
                end
            end)
        end
    end)

    cabecalho.InputChanged:Connect(function(input)
        if arrastando and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - inicioArrastamento
            mainMenu.Position = UDim2.new(
                posicaoInicial.X.Scale,
                posicaoInicial.X.Offset + delta.X,
                posicaoInicial.Y.Scale,
                posicaoInicial.Y.Offset + delta.Y
            )
        end
    end)

    return mainMenu
end

-- Função para criar abas
local function criarAbas(parent)
    local abasFrame = Instance.new("Frame")
    abasFrame.Size = UDim2.new(1, 0, 0, 35)
    abasFrame.Position = UDim2.new(0, 0, 0, 45)
    abasFrame.BackgroundColor3 = CORES.FundoSecundario
    abasFrame.BorderSizePixel = 0
    abasFrame.Parent = parent

    local abasCorner = Instance.new("UICorner")
    abasCorner.CornerRadius = UDim.new(0, 8)
    abasCorner.Parent = abasFrame

    local abas = {"Aimbot", "ESP Inimigos", "ESP Aliados", "Armas"}
    local botoesAbas = {}

    for i, nomeAba in ipairs(abas) do
        local botaoAba = Instance.new("TextButton")
        botaoAba.Size = UDim2.new(0.25, -2, 1, -4)
        botaoAba.Position = UDim2.new((i-1) * 0.25, 1, 0, 2)
        botaoAba.BackgroundColor3 = currentTab == nomeAba:lower():gsub(" ", "") and CORES.Principal or CORES.Inativo
        botaoAba.TextColor3 = CORES.Texto
        botaoAba.Font = Enum.Font.GothamMedium
        botaoAba.TextSize = 12
        botaoAba.Text = nomeAba
        botaoAba.Parent = abasFrame

        local cornerAba = Instance.new("UICorner")
        cornerAba.CornerRadius = UDim.new(0, 6)
        cornerAba.Parent = botaoAba

        botaoAba.MouseButton1Click:Connect(function()
            currentTab = nomeAba:lower():gsub(" ", "")
            atualizarAbas()
        end)

        botoesAbas[nomeAba:lower():gsub(" ", "")] = botaoAba
    end

    function atualizarAbas()
        for nome, botao in pairs(botoesAbas) do
            botao.BackgroundColor3 = nome == currentTab and CORES.Principal or CORES.Inativo
        end
        atualizarConteudo()
    end

    return abasFrame
end

-- Função para criar toggle melhorado
local function criarToggle(parent, texto, posY, flagName, tamanho)
    tamanho = tamanho or UDim2.new(1, -10, 0, 30)
    
    local frame = Instance.new("Frame")
    frame.Size = tamanho
    frame.Position = UDim2.new(0, 5, 0, posY)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Text = texto
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = CORES.Texto
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 45, 0, 20)
    toggleBtn.Position = UDim2.new(0.75, 0, 0.25, 0)
    toggleBtn.BackgroundColor3 = _G[flagName] and CORES.Ativo or CORES.Inativo
    toggleBtn.AutoButtonColor = false
    toggleBtn.Text = _G[flagName] and "ON" or "OFF"
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextColor3 = CORES.Texto
    toggleBtn.TextSize = 11
    toggleBtn.Parent = frame

    local cornerBtn = Instance.new("UICorner")
    cornerBtn.CornerRadius = UDim.new(0, 10)
    cornerBtn.Parent = toggleBtn

    local toggleCircle = Instance.new("Frame")
    toggleCircle.Size = UDim2.new(0, 16, 0, 16)
    toggleCircle.Position = _G[flagName] and UDim2.new(0, 27, 0.1, 0) or UDim2.new(0, 2, 0.1, 0)
    toggleCircle.BackgroundColor3 = CORES.Texto
    toggleCircle.Parent = toggleBtn
    
    local cornerCircle = Instance.new("UICorner")
    cornerCircle.CornerRadius = UDim.new(1, 0)
    cornerCircle.Parent = toggleCircle

    toggleBtn.MouseButton1Click:Connect(function()
        _G[flagName] = not _G[flagName]
        
        local novaCor = _G[flagName] and CORES.Ativo or CORES.Inativo
        local novaPos = _G[flagName] and UDim2.new(0, 27, 0.1, 0) or UDim2.new(0, 2, 0.1, 0)
        local novoTexto = _G[flagName] and "ON" or "OFF"
        
        toggleBtn.Text = novoTexto
        
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = novaCor}):Play()
        TweenService:Create(toggleCircle, TweenInfo.new(0.2), {Position = novaPos}):Play()
        
        -- Reaplicar modificações quando toggles de armas mudarem
        if flagName == "noRecoilEnabled" or flagName == "infiniteAmmoEnabled" or 
           flagName == "instantReloadEnabled" or flagName == "rapidFireEnabled" then
            reaplicarModificacoes()
        end
    end)

    return frame
end

-- Função para criar slider de presets do rapid fire
local function criarSliderRapidFire(parent, texto, posY)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 50)
    frame.Position = UDim2.new(0, 5, 0, posY)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    local presetAtual = RAPID_FIRE_PRESETS[_G.rapidFirePresetIndex]
    label.Text = texto .. ": " .. presetAtual.nome .. " (" .. presetAtual.valor .. "s)"
    label.Size = UDim2.new(1, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.TextColor3 = CORES.Texto
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    -- Botão anterior
    local botaoAnterior = Instance.new("TextButton")
    botaoAnterior.Size = UDim2.new(0, 30, 0, 25)
    botaoAnterior.Position = UDim2.new(0, 5, 0, 22)
    botaoAnterior.BackgroundColor3 = CORES.Secundaria
    botaoAnterior.TextColor3 = CORES.Texto
    botaoAnterior.Font = Enum.Font.GothamBold
    botaoAnterior.TextSize = 14
    botaoAnterior.Text = "◀"
    botaoAnterior.Parent = frame

    local cornerAnterior = Instance.new("UICorner")
    cornerAnterior.CornerRadius = UDim.new(0, 5)
    cornerAnterior.Parent = botaoAnterior

    -- Slider visual
    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -80, 0, 25)
    sliderBg.Position = UDim2.new(0, 40, 0, 22)
    sliderBg.BackgroundColor3 = CORES.Inativo
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = frame

    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 12)
    sliderCorner.Parent = sliderBg

    local sliderFill = Instance.new("Frame")
    local progresso = (_G.rapidFirePresetIndex - 1) / (#RAPID_FIRE_PRESETS - 1)
    sliderFill.Size = UDim2.new(progresso, 0, 1, 0)
    sliderFill.BackgroundColor3 = CORES.Principal
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 12)
    fillCorner.Parent = sliderFill

    -- Botão próximo
    local botaoProximo = Instance.new("TextButton")
    botaoProximo.Size = UDim2.new(0, 30, 0, 25)
    botaoProximo.Position = UDim2.new(1, -35, 0, 22)
    botaoProximo.BackgroundColor3 = CORES.Secundaria
    botaoProximo.TextColor3 = CORES.Texto
    botaoProximo.Font = Enum.Font.GothamBold
    botaoProximo.TextSize = 14
    botaoProximo.Text = "▶"
    botaoProximo.Parent = frame

    local cornerProximo = Instance.new("UICorner")
    cornerProximo.CornerRadius = UDim.new(0, 5)
    cornerProximo.Parent = botaoProximo

    local function atualizarSliderPreset()
        local preset = RAPID_FIRE_PRESETS[_G.rapidFirePresetIndex]
        _G.rapidFireRate = preset.valor
        label.Text = texto .. ": " .. preset.nome .. " (" .. preset.valor .. "s)"
        
        local novoProgresso = (_G.rapidFirePresetIndex - 1) / (#RAPID_FIRE_PRESETS - 1)
        TweenService:Create(sliderFill, TweenInfo.new(0.2), {Size = UDim2.new(novoProgresso, 0, 1, 0)}):Play()
    end

    botaoAnterior.MouseButton1Click:Connect(function()
        if _G.rapidFirePresetIndex > 1 then
            _G.rapidFirePresetIndex = _G.rapidFirePresetIndex - 1
            atualizarSliderPreset()
        end
    end)

    botaoProximo.MouseButton1Click:Connect(function()
        if _G.rapidFirePresetIndex < #RAPID_FIRE_PRESETS then
            _G.rapidFirePresetIndex = _G.rapidFirePresetIndex + 1
            atualizarSliderPreset()
        end
    end)

    return frame
end

-- Função para criar slider padrão
local function criarSlider(parent, texto, posY, flagName, minVal, maxVal, step)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 35)
    frame.Position = UDim2.new(0, 5, 0, posY)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Text = texto .. ": " .. tostring(_G[flagName])
    label.Size = UDim2.new(1, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.TextColor3 = CORES.Texto
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -10, 0, 12)
    sliderBg.Position = UDim2.new(0, 5, 0, 20)
    sliderBg.BackgroundColor3 = CORES.Inativo
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = frame

    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 6)
    sliderCorner.Parent = sliderBg

    local sliderFill = Instance.new("Frame")
    local progress = (_G[flagName] - minVal) / (maxVal - minVal)
    sliderFill.Size = UDim2.new(progress, 0, 1, 0)
    sliderFill.BackgroundColor3 = CORES.Principal
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 6)
    fillCorner.Parent = sliderFill

    local function atualizarSlider(mousePos)
        local relativePos = math.clamp((mousePos - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        local novoValor = minVal + (maxVal - minVal) * relativePos
        novoValor = math.floor(novoValor / step + 0.5) * step
        
        _G[flagName] = novoValor
        label.Text = texto .. ": " .. tostring(novoValor)
        sliderFill.Size = UDim2.new(relativePos, 0, 1, 0)
    end

    local arrastando = false
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            arrastando = true
            atualizarSlider(input.Position.X)
        end
    end)

    sliderBg.InputChanged:Connect(function(input)
        if arrastando and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            atualizarSlider(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            arrastando = false
        end
    end)

    return frame
end

-- Função para criar área de conteúdo
local function criarAreaConteudo(parent)
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, 0, 1, -85)
    scrollFrame.Position = UDim2.new(0, 0, 0, 85)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ScrollBarImageColor3 = CORES.Principal
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 300)
    scrollFrame.Parent = parent
    
    return scrollFrame
end

-- Função para atualizar conteúdo baseado na aba selecionada
function atualizarConteudo()
    local conteudo = mainMenu:FindFirstChild("ConteudoArea")
    if conteudo then conteudo:Destroy() end
    
    local novoConteudo = criarAreaConteudo(mainMenu)
    novoConteudo.Name = "ConteudoArea"
    
    if currentTab == "aimbot" then
        criarConteudoAimbot(novoConteudo)
    elseif currentTab == "espinimigos" then
        criarConteudoESPInimigos(novoConteudo)
    elseif currentTab == "espaliados" then
        criarConteudoESPAliados(novoConteudo)
    elseif currentTab == "armas" then
        criarConteudoArmas(novoConteudo)
    end
end

-- Conteúdo da aba Aimbot
function criarConteudoAimbot(parent)
    criarToggle(parent, "🎯 Aimbot Automático", 10, "aimbotAutoEnabled")
    criarToggle(parent, "🖱️ Aimbot Manual", 45, "aimbotManualEnabled")
    criarSlider(parent, "📐 Campo de Visão", 85, "FOV_RADIUS", 20, 300, 5)
    
    parent.CanvasSize = UDim2.new(0, 0, 0, 140)
end

-- Conteúdo da aba ESP Inimigos
function criarConteudoESPInimigos(parent)
    criarToggle(parent, "🔴 ESP Inimigos Ativo", 10, "espInimigosAtivado")
    criarToggle(parent, "📏 ESP Linha", 45, "espInimigosLinha")
    criarToggle(parent, "📝 ESP Nome", 80, "espInimigosNome")
    criarToggle(parent, "📏 ESP Distância", 115, "espInimigosDistancia")
    criarToggle(parent, "❤️ ESP HP", 150, "espInimigosHP")
    criarToggle(parent, "⬜ ESP Quadrado", 185, "espInimigosQuadrado")
    criarToggle(parent, "👻 Wallhack Inimigos", 220, "wallhackInimigos")
    
    parent.CanvasSize = UDim2.new(0, 0, 0, 270)
end

-- Conteúdo da aba ESP Aliados
function criarConteudoESPAliados(parent)
    criarToggle(parent, "🔵 ESP Aliados Ativo", 10, "espAliadosAtivado")
    criarToggle(parent, "📏 ESP Linha", 45, "espAliadosLinha")
    criarToggle(parent, "📝 ESP Nome", 80, "espAliadosNome")
    criarToggle(parent, "📏 ESP Distância", 115, "espAliadosDistancia")
    criarToggle(parent, "❤️ ESP HP", 150, "espAliadosHP")
    criarToggle(parent, "⬜ ESP Quadrado", 185, "espAliadosQuadrado")
    criarToggle(parent, "👻 Wallhack Aliados", 220, "wallhackAliados")
    
    parent.CanvasSize = UDim2.new(0, 0, 0, 270)
end

-- Conteúdo da aba Armas
function criarConteudoArmas(parent)
    criarToggle(parent, "🎯 Sem Recuo", 10, "noRecoilEnabled")
    criarToggle(parent, "🔫 Munição Infinita", 45, "infiniteAmmoEnabled")
    criarToggle(parent, "⚡ Recarga Instantânea", 80, "instantReloadEnabled")
    criarToggle(parent, "🔥 Rapid Fire", 115, "rapidFireEnabled")
    criarSliderRapidFire(parent, "🔥 Velocidade de Disparo", 155)
    
    parent.CanvasSize = UDim2.new(0, 0, 0, 230)
end

-- Funções auxiliares do sistema
local function estaVivo(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function ehFFA()
    local teams = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player.Team then teams[player.Team] = true end
    end
    return next(teams) == nil or next(teams, next(teams)) == nil
end

local function temLinhadeVisao(targetPart)
    local origem = Camera.CFrame.Position
    local direcao = (targetPart.Position - origem).Unit * 500
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local resultado = workspace:Raycast(origem, direcao, raycastParams)
    return not resultado or resultado.Instance:IsDescendantOf(targetPart.Parent)
end

local function obterInimigoMaisProximo()
    local centro = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local inimigoMaisProximo = nil
    local menorDistancia = _G.FOV_RADIUS
    local ffa = ehFFA()

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer or not player.Character then continue end
        if not estaVivo(player.Character) then continue end

        local ehAliado = player.Team == LocalPlayer.Team
        if not ffa and ehAliado then continue end

        local cabeca = player.Character:FindFirstChild("Head")
        if cabeca then
            local posicaoTela, visivel = Camera:WorldToViewportPoint(cabeca.Position)
            local dist = (Vector2.new(posicaoTela.X, posicaoTela.Y) - centro).Magnitude
            if visivel and dist <= menorDistancia and temLinhadeVisao(cabeca) then
                menorDistancia = dist
                inimigoMaisProximo = player
            end
        end
    end
    return inimigoMaisProximo
end

-- Sistema ESP avançado
local function criarESPObjeto(player)
    if espObjects[player] then return end
    
    espObjects[player] = {
        linha = nil,
        nome = nil,
        distancia = nil,
        hp = nil,
        quadrado = nil
    }
end

local function atualizarESP(player, ehInimigo)
    if not player.Character or not estaVivo(player.Character) then
        if espObjects[player] then
            local obj = espObjects[player]
            if obj.linha then obj.linha:Remove() end
            if obj.nome then obj.nome:Remove() end
            if obj.distancia then obj.distancia:Remove() end
            if obj.hp then obj.hp:Remove() end
            if obj.quadrado then obj.quadrado:Remove() end
            espObjects[player] = nil
        end
        return
    end

    local cabeca = player.Character:FindFirstChild("Head")
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    local humanoid = player.Character:FindFirstChild("Humanoid")
    
    if not cabeca or not humanoidRootPart or not humanoid then return end

    -- Verificar configurações
    local espAtivo = ehInimigo and _G.espInimigosAtivado or _G.espAliadosAtivado
    if not espAtivo then
        if espObjects[player] then
            local obj = espObjects[player]
            if obj.linha then obj.linha.Visible = false end
            if obj.nome then obj.nome.Visible = false end
            if obj.distancia then obj.distancia.Visible = false end
            if obj.hp then obj.hp.Visible = false end
            if obj.quadrado then obj.quadrado.Visible = false end
        end
        return
    end

    criarESPObjeto(player)
    local espObj = espObjects[player]
    
    local posicaoTela, visivel = Camera:WorldToViewportPoint(humanoidRootPart.Position)
    if not visivel then 
        if espObj.linha then espObj.linha.Visible = false end
        if espObj.nome then espObj.nome.Visible = false end
        if espObj.distancia then espObj.distancia.Visible = false end
        if espObj.hp then espObj.hp.Visible = false end
        if espObj.quadrado then espObj.quadrado.Visible = false end
        return 
    end

    local distancia = (LocalPlayer.Character.HumanoidRootPart.Position - humanoidRootPart.Position).Magnitude
    local cor = ehInimigo and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(50, 150, 255)

    -- ESP Linha
    local espLinha = ehInimigo and _G.espInimigosLinha or _G.espAliadosLinha
    if espLinha then
        if not espObj.linha then
            espObj.linha = Drawing.new("Line")
        end
        espObj.linha.Visible = true
        espObj.linha.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        espObj.linha.To = Vector2.new(posicaoTela.X, posicaoTela.Y)
        espObj.linha.Color = cor
        espObj.linha.Thickness = 2
    elseif espObj.linha then
        espObj.linha.Visible = false
    end

    -- ESP Nome
    local espNome = ehInimigo and _G.espInimigosNome or _G.espAliadosNome
    if espNome then
        if not espObj.nome then
            espObj.nome = Drawing.new("Text")
            espObj.nome.Size = 16
            espObj.nome.Font = 2
            espObj.nome.Outline = true
        end
        espObj.nome.Visible = true
        espObj.nome.Position = Vector2.new(posicaoTela.X, posicaoTela.Y - 40)
        espObj.nome.Text = player.Name
        espObj.nome.Color = cor
        espObj.nome.Center = true
    elseif espObj.nome then
        espObj.nome.Visible = false
    end

    -- ESP Distância
    local espDistancia = ehInimigo and _G.espInimigosDistancia or _G.espAliadosDistancia
    if espDistancia then
        if not espObj.distancia then
            espObj.distancia = Drawing.new("Text")
            espObj.distancia.Size = 14
            espObj.distancia.Font = 2
            espObj.distancia.Outline = true
        end
        espObj.distancia.Visible = true
        espObj.distancia.Position = Vector2.new(posicaoTela.X, posicaoTela.Y + 20)
        espObj.distancia.Text = math.floor(distancia) .. "m"
        espObj.distancia.Color = cor
        espObj.distancia.Center = true
    elseif espObj.distancia then
        espObj.distancia.Visible = false
    end

    -- ESP HP
    local espHP = ehInimigo and _G.espInimigosHP or _G.espAliadosHP
    if espHP then
        if not espObj.hp then
            espObj.hp = Drawing.new("Text")
            espObj.hp.Size = 14
            espObj.hp.Font = 2
            espObj.hp.Outline = true
        end
        espObj.hp.Visible = true
        espObj.hp.Position = Vector2.new(posicaoTela.X, posicaoTela.Y + 35)
        espObj.hp.Text = math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
        local healthPercent = humanoid.Health / humanoid.MaxHealth
        espObj.hp.Color = Color3.fromRGB(
            255 * (1 - healthPercent),
            255 * healthPercent,
            0
        )
        espObj.hp.Center = true
    elseif espObj.hp then
        espObj.hp.Visible = false
    end

    -- ESP Quadrado
    local espQuadrado = ehInimigo and _G.espInimigosQuadrado or _G.espAliadosQuadrado
    if espQuadrado then
        if not espObj.quadrado then
            espObj.quadrado = Drawing.new("Square")
            espObj.quadrado.Thickness = 2
            espObj.quadrado.Filled = false
        end
        espObj.quadrado.Visible = true
        local tamanho = math.clamp(1000 / distancia, 4, 150)
        espObj.quadrado.Size = Vector2.new(tamanho, tamanho * 1.5)
        espObj.quadrado.Position = Vector2.new(posicaoTela.X - tamanho/2, posicaoTela.Y - tamanho * 0.75)
        espObj.quadrado.Color = cor
    elseif espObj.quadrado then
        espObj.quadrado.Visible = false
    end
end

-- Sistema de Wallhack com Highlights
local function atualizarWallhack(player, ehInimigo)
    if not player.Character or not estaVivo(player.Character) then
        if highlights[player] then
            highlights[player]:Destroy()
            highlights[player] = nil
        end
        return
    end

    local wallhackAtivo = ehInimigo and _G.wallhackInimigos or _G.wallhackAliados
    
    if wallhackAtivo then
        if not highlights[player] then
            highlights[player] = Instance.new("Highlight")
            highlights[player].Parent = workspace
            highlights[player].DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlights[player].FillTransparency = 0.5
            highlights[player].OutlineTransparency = 0
        end
        
        highlights[player].Adornee = player.Character
        highlights[player].FillColor = ehInimigo and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(50, 150, 255)
        highlights[player].OutlineColor = ehInimigo and Color3.fromRGB(150, 0, 0) or Color3.fromRGB(0, 100, 200)
    else
        if highlights[player] then
            highlights[player]:Destroy()
            highlights[player] = nil
        end
    end
end

-- Sistema de Aimbot
local alvoAtual = nil
local mirando = false

local function mirarNoAlvo(alvo)
    if not alvo or not alvo.Character then return end
    local cabeca = alvo.Character:FindFirstChild("Head")
    if not cabeca then return end

    local cameraCFrame = Camera.CFrame
    local direcao = (cabeca.Position - cameraCFrame.Position).Unit
    Camera.CFrame = CFrame.lookAt(cameraCFrame.Position, cabeca.Position)
end

-- Sistema de tiro rápido customizado
local function atirarArma(tool)
    if not tool then return end
    local taxaDisparo = tool:GetAttribute("rateOfFire") or 70
    local intervalos = math.floor(_G.rapidFireRate * 1000) -- Converter para ms
    
    for i = 1, 5 do
        if _G.rapidFireEnabled then
            task.wait(intervalos / 1000) -- Converter de volta para segundos
            -- Simular disparo
            if tool.Parent == LocalPlayer.Character then
                local evento = tool:FindFirstChild("RemoteEvent") or tool:FindFirstChild("Fire")
                if evento and evento:IsA("RemoteEvent") then
                    evento:FireServer()
                end
            end
        else
            break
        end
    end
end

-- Função para restaurar valores originais de uma arma
local function restaurarArma(tool)
    if not tool or not armasModificadas[tool] then return end
    
    local dadosOriginais = armasModificadas[tool]
    
    -- Restaurar valores originais
    for objeto, valorOriginal in pairs(dadosOriginais.valores) do
        if objeto and objeto.Parent then
            objeto.Value = valorOriginal
        end
    end
    
    -- Limpar conexões
    for _, conexao in pairs(dadosOriginais.conexoes) do
        if conexao then conexao:Disconnect() end
    end
    
    armasModificadas[tool] = nil
end

-- Sistema de modificação de armas melhorado com ativação/desativação
local function modificarArma(tool)
    if not tool or not tool:IsA("Tool") then return end
    
    -- Se já foi modificada, restaurar primeiro
    if armasModificadas[tool] then
        restaurarArma(tool)
    end
    
    spawn(function()
        wait(0.1)
        
        local dadosArma = {
            valores = {},
            conexoes = {}
        }
        
        -- Rapid Fire com rateOfFire
        if _G.rapidFireEnabled then
            -- Modificar atributo rateOfFire se existir
            if tool:GetAttribute("rateOfFire") then
                dadosArma.valores[tool] = tool:GetAttribute("rateOfFire")
                tool:SetAttribute("rateOfFire", math.floor(1 / _G.rapidFireRate))
            end
            
            -- Procurar por valores relacionados a taxa de disparo
            for _, child in pairs(tool:GetDescendants()) do
                if child.Name:lower():find("firerate") or child.Name:lower():find("rateoffire") or 
                   child.Name:lower():find("cooldown") or child.Name:lower():find("delay") then
                    if child:IsA("NumberValue") or child:IsA("IntValue") then
                        dadosArma.valores[child] = child.Value
                        child.Value = _G.rapidFireRate
                    end
                end
            end
            
            -- Conectar ao evento de ativação para tiro customizado
            local conexaoTiro = tool.Activated:Connect(function()
                if _G.rapidFireEnabled then
                    spawn(function()
                        atirarArma(tool)
                    end)
                end
            end)
            table.insert(dadosArma.conexoes, conexaoTiro)
        end
        
        -- Sem Recuo
        if _G.noRecoilEnabled then
            for _, child in pairs(tool:GetDescendants()) do
                if child.Name:lower():find("recoil") or child.Name:lower():find("kick") or 
                   child.Name:lower():find("spread") then
                    if child:IsA("NumberValue") or child:IsA("IntValue") then
                        dadosArma.valores[child] = child.Value
                        child.Value = 0
                    end
                end
            end
        end
        
        -- Munição Infinita
        if _G.infiniteAmmoEnabled then
            for _, child in pairs(tool:GetDescendants()) do
                if child.Name:lower():find("ammo") or child.Name:lower():find("mag") or 
                   child.Name:lower():find("bullet") or child.Name:lower():find("clip") then
                    if child:IsA("NumberValue") or child:IsA("IntValue") then
                        dadosArma.valores[child] = child.Value
                        child.Value = math.huge
                        
                        -- Monitorar mudanças e manter infinito
                        local conexaoAmmo = child.Changed:Connect(function()
                            if _G.infiniteAmmoEnabled and child.Value ~= math.huge then
                                child.Value = math.huge
                            end
                        end)
                        table.insert(dadosArma.conexoes, conexaoAmmo)
                    end
                end
            end
        end
        
        -- Recarga Instantânea
        if _G.instantReloadEnabled then
            for _, child in pairs(tool:GetDescendants()) do
                if child.Name:lower():find("reload") or child.Name:lower():find("reloadtime") then
                    if child:IsA("NumberValue") or child:IsA("IntValue") then
                        dadosArma.valores[child] = child.Value
                        child.Value = 0
                    end
                end
            end
        end
        
        -- Salvar dados da arma modificada
        armasModificadas[tool] = dadosArma
        
        -- Limpar quando a ferramenta for removida
        local conexaoLimpeza = tool.AncestryChanged:Connect(function()
            if not tool.Parent then
                restaurarArma(tool)
            end
        end)
        table.insert(dadosArma.conexoes, conexaoLimpeza)
    end)
end

-- Função para reaplicar modificações em todas as armas quando configurações mudarem
local function reaplicarModificacoes()
    if LocalPlayer.Character then
        for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
            if tool:IsA("Tool") then
                modificarArma(tool)
            end
        end
    end
end

-- Eventos de entrada
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        mirando = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        mirando = false
    end
end)

-- Loop principal
RunService.RenderStepped:Connect(function()
    -- Sistema de Aimbot
    if _G.aimbotAutoEnabled or (_G.aimbotManualEnabled and mirando) then
        alvoAtual = obterInimigoMaisProximo()
        if alvoAtual then
            mirarNoAlvo(alvoAtual)
        end
    else
        alvoAtual = nil
    end
    
    -- Atualizar ESP e Wallhack para todos os jogadores
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local ffa = ehFFA()
            local ehInimigo = ffa or (player.Team ~= LocalPlayer.Team)
            
            atualizarESP(player, ehInimigo)
            atualizarWallhack(player, ehInimigo)
        end
    end
end)

-- Eventos de jogadores
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        wait(1)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    if espObjects[player] then
        local obj = espObjects[player]
        if obj.linha then obj.linha:Remove() end
        if obj.nome then obj.nome:Remove() end
        if obj.distancia then obj.distancia:Remove() end
        if obj.hp then obj.hp:Remove() end
        if obj.quadrado then obj.quadrado:Remove() end
        espObjects[player] = nil
    end
    if highlights[player] then
        highlights[player]:Destroy()
        highlights[player] = nil
    end
end)

-- Monitorar armas
LocalPlayer.CharacterAdded:Connect(function(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            modificarArma(child)
        end
    end)
end)

if LocalPlayer.Character then
    for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
        if tool:IsA("Tool") then
            modificarArma(tool)
        end
    end
end

-- Inicializar interface
criarInterfacePrincipal()
criarAbas(mainMenu)
atualizarConteudo()

-- Notificação
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "✅ Menu Avançado Carregado";
    Text = "Aimbot & ESP v3.0 ativo com todas as funcionalidades!";
    Duration = 3;
})

print("🎯 Menu Avançado de Aimbot & ESP v3.0 carregado!")
print("📱 Interface com abas criada e funcionando")
print("🔧 Funcionalidades implementadas:")
print("   - ESP com linha, nome, distância, HP e quadrados")
print("   - Wallhack separado para inimigos e aliados") 
print("   - Rapid Fire ajustável")
print("   - Interface compacta e organizada")
    end)
    toggleBtn.MouseLeave:Connect(function()
        local color = toggleBtn.Text == "ON" and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(70, 70, 70)
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
    end)

    local debounce = false
    -- Função para atualizar visual do toggle com animação
    local function updateToggleState(isOn)
        if debounce then return end
        debounce = true
        if isOn then
            toggleBtn.Text = "ON"
            local tween1 = TweenService:Create(toggleBtn, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(0, 170, 0)})
            local tween2 = TweenService:Create(toggleCircle, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 25, 0.15, 0)})
            tween1:Play()
            tween2:Play()
            tween2.Completed:Wait()
        else
            toggleBtn.Text = "OFF"
            local tween1 = TweenService:Create(toggleBtn, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(70, 70, 70)})
            local tween2 = TweenService:Create(toggleCircle, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 5, 0.15, 0)})
            tween1:Play()
            tween2:Play()
            tween2.Completed:Wait()
        end
        debounce = false
    end

    return {
        frame = frame,
        toggleBtn = toggleBtn,
        update = updateToggleState,
        getState = function() return toggleBtn.Text == "ON" end
    }
end

-- Criar toggles e ligar aos flags globais
local toggles = {}

local function bindToggle(text, flagName, y)
    local tog = createToggle(text, y)
    tog.update(_G[flagName])
    tog.toggleBtn.MouseButton1Click:Connect(function()
        _G[flagName] = not _G[flagName]
        tog.update(_G[flagName])
    end)
    toggles[flagName] = tog
end

bindToggle("Aimbot Auto", "aimbotAutoEnabled", 50)
bindToggle("Aimbot Manual", "aimbotManualEnabled", 100)
bindToggle("ESP Inimigos", "espEnemiesEnabled", 150)
bindToggle("ESP Aliados", "espAlliesEnabled", 200)
bindToggle("No Recoil", "noRecoilEnabled", 250)
bindToggle("Munição Infinita", "infiniteAmmoEnabled", 300)
bindToggle("Recarga Instantânea", "instantReloadEnabled", 350)

-- Label do FOV
local fovLabel = Instance.new("TextLabel")
fovLabel.Text = "FOV: ".._G.FOV_RADIUS
fovLabel.Size = UDim2.new(1, -20, 0, 30)
fovLabel.Position = UDim2.new(0, 10, 0, 410)
fovLabel.BackgroundTransparency = 1
fovLabel.TextColor3 = Color3.new(1,1,1)
fovLabel.Font = Enum.Font.GothamBold
fovLabel.TextSize = 20
fovLabel.TextXAlignment = Enum.TextXAlignment.Center
fovLabel.Parent = menu

local function updateFOVLabel()
    fovLabel.Text = "FOV: ".._G.FOV_RADIUS
end

local function createFOVButton(text, xPos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 50, 0, 30)
    btn.Position = UDim2.new(0, xPos, 0, 450)
    btn.BackgroundColor3 = Color3.fromRGB(70,70,70)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 20
    btn.Text = text
    btn.Parent = menu

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(90,90,90)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70,70,70)}):Play()
    end)

    btn.MouseButton1Click:Connect(function()
        if text == "+" then
            _G.FOV_RADIUS = math.clamp(_G.FOV_RADIUS + 5, 10, 300)
        else
            _G.FOV_RADIUS = math.clamp(_G.FOV_RADIUS - 5, 10, 300)
        end
        updateFOVLabel()
    end)
end

createFOVButton("-", 55)
createFOVButton("+", 135)

updateFOVLabel()

-- Drag para mover o menu pela barra do título
local dragging = false
local dragStart = nil
local startPos = nil

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = menu.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

title.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        menu.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- Funções auxiliares
local function isAlive(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function isFFA()
    local teams = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player.Team then
            teams[player.Team] = true
        end
    end
    return next(teams) == nil or next(teams, next(teams)) == nil
end

local function hasLineOfSight(targetPart)
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit * 500
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local result = workspace:Raycast(origin, direction, raycastParams)
    return not result or result.Instance:IsDescendantOf(targetPart.Parent)
end

-- Buscar inimigo visível mais próximo dentro do FOV
local function getClosestVisibleEnemy()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local closestEnemy = nil
    local shortestDistance = _G.FOV_RADIUS
    local ffa = isFFA()

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer or not player.Character then continue end
        if not isAlive(player.Character) then continue end

        local isAlly = player.Team == LocalPlayer.Team
        if not ffa then
            if isAlly and not _G.espAlliesEnabled then continue end
            if not isAlly and not _G.espEnemiesEnabled then continue end
        else
            if not _G.espEnemiesEnabled then continue end
        end

        local head = player.Character:FindFirstChild("Head")
        if head then
            local screenPos, visible = Camera:WorldToViewportPoint(head.Position)
            local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
            if visible and dist <= shortestDistance and hasLineOfSight(head) then
                shortestDistance = dist
                closestEnemy = player
            end
        end
    end
    return closestEnemy
end

-- ESP Wallhack com Highlights
local highlights = {}

local function updateHighlight(player, isTarget)
    if not player.Character then return end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        if highlights[player] then highlights[player].Enabled = false end
        return
    end

    local isAlly = (player.Team == LocalPlayer.Team)
    local ffa = isFFA()
    local show = false

    if ffa then
        show = _G.espEnemiesEnabled
    else
        show = (isAlly and _G.espAlliesEnabled) or (not isAlly and _G.espEnemiesEnabled)
    end

    if not show then
        if highlights[player] then highlights[player].Enabled = false end
        return
    end

    local highlight = highlights[player]
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Parent = workspace
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillTransparency = 0.5
        highlights[player] = highlight
    end

    highlight.Adornee = player.Character
    highlight.Enabled = true

    if isTarget then
        highlight.FillColor = Color3.fromRGB(255, 255, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
        highlight.FillTransparency = 0.3
    else
        if isAlly then
            highlight.FillColor = Color3.fromRGB(0, 170, 255)
            highlight.OutlineColor = Color3.fromRGB(0, 85, 170)
        else
            highlight.FillColor = Color3.fromRGB(255, 50, 50)
            highlight.OutlineColor = Color3.fromRGB(150, 0, 0)
        end
    end
end

local function updateAllHighlights()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            updateHighlight(player, player == currentTarget)
        elseif highlights[player] then
            highlights[player].Enabled = false
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        updateAllHighlights()
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    if highlights[player] then
        highlights[player]:Destroy()
        highlights[player] = nil
    end
end)

RunService.RenderStepped:Connect(function()
    updateAllHighlights()
end)

-- Variáveis do aimbot
local currentTarget = nil
local aiming = false
local shooting = false

-- Eventos de input para aimbot manual
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aiming = true
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        shooting = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aiming = false
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        shooting = false
    end
end)

-- Função para mirar no inimigo
local function aimAtTarget(target)
    if not target or not target.Character then return end
    local head = target.Character:FindFirstChild("Head")
    if not head then return end

    local cameraCFrame = Camera.CFrame
    local direction = (head.Position - cameraCFrame.Position).Unit
    Camera.CFrame = CFrame.new(cameraCFrame.Position, head.Position)
end

-- Loop principal do aimbot e ESP
RunService.RenderStepped:Connect(function()
    if _G.aimbotAutoEnabled or (_G.aimbotManualEnabled and aiming) then
        currentTarget = getClosestVisibleEnemy()
        if currentTarget then
            aimAtTarget(currentTarget)
        end
    else
        currentTarget = nil
    end
end)

-- Aplicar cheats na arma atual
local function patchWeapon(tool)
    if tool and tool:IsA("Tool") then
        if _G.infiniteAmmoEnabled and tool:FindFirstChild("Ammo") then
            tool.Ammo.Value = math.huge
        end
        if _G.noRecoilEnabled and tool:FindFirstChild("Recoil") then
            tool.Recoil.Value = 0
        end
        if _G.instantReloadEnabled and tool:FindFirstChild("ReloadTime") then
            tool.ReloadTime.Value = 0
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait(0.1)
            patchWeapon(child)
        end
    end)
end)

if LocalPlayer.Character then
    for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
        if tool:IsA("Tool") then
            patchWeapon(tool)
        end
    end
end
