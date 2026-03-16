-- SCRIPT COM MEMÓRIA DE POSIÇÃO E ESTADO (JSON)
local UIS = game:GetService("UserInputService")
local player = game:GetService("Players").LocalPlayer
local pgui = player:WaitForChild("PlayerGui")
local HttpService = game:GetService("HttpService")

local FILE_NAME = "InvisConfig.json"

-- --- FUNÇÕES DE PERSISTÊNCIA ---
local function SalvarConfig(pos, status)
    local dados = {
        posicao = {pos.X.Scale, pos.X.Offset, pos.Y.Scale, pos.Y.Offset},
        ativado = status
    }
    -- Tenta salvar no arquivo (apenas funciona em executores)
    pcall(function()
        writefile(FILE_NAME, HttpService:JSONEncode(dados))
    end)
end

local function CarregarConfig()
    local sucesso, resultado = pcall(function()
        if isfile(FILE_NAME) then
            return HttpService:JSONDecode(readfile(FILE_NAME))
        end
    end)
    return sucesso and resultado or nil
end

-- Carrega os dados salvos antes de criar a interface
local configSalva = CarregarConfig()

-- 1. LIMPA VERSÕES ANTIGAS
if pgui:FindFirstChild("InvisSystem_Final") then pgui["InvisSystem_Final"]:Destroy() end
_G.InvisSessao = tick()
local minhaSessao = _G.InvisSessao

-- Define o estado inicial baseado no que foi salvo
_G.Ativado = false
if configSalva and configSalva.ativado ~= nil then
    _G.Ativado = configSalva.ativado
end

-- 2. CRIANDO A INTERFACE (GUI)
local sg = Instance.new("ScreenGui", pgui)
sg.Name = "InvisSystem_Final"
sg.ResetOnSpawn = false
sg.DisplayOrder = 999

local btn = Instance.new("TextButton", sg)
btn.Size = UDim2.new(0, 160, 0, 50)

-- Aplica a posição salva ou centraliza se for a primeira vez
if configSalva and configSalva.posicao then
    btn.Position = UDim2.new(unpack(configSalva.posicao))
else
    btn.Position = UDim2.new(0.5, -80, 0.5, -25)
end

btn.BorderSizePixel = 2
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Font = Enum.Font.SourceSansBold
btn.TextSize = 16
btn.ClipsDescendants = true
btn.Active = true

-- Função para atualizar visual do botão
local function AtualizarBotaoUI()
    if _G.Ativado then
        btn.Text = "INVISIBILIDADE: ON"
        btn.BorderColor3 = Color3.fromRGB(0, 255, 0)
        btn.BackgroundColor3 = Color3.fromRGB(0, 50, 0)
    else
        btn.Text = "INVISIBILIDADE: OFF"
        btn.BorderColor3 = Color3.fromRGB(200, 0, 0)
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end
end
AtualizarBotaoUI()

local corner = Instance.new("UICorner", btn)
corner.CornerRadius = UDim.new(0, 10)

-- 3. SISTEMA DE ARRASTE (ATUALIZADO PARA SALVAR AO SOLTAR)
local dragging, dragInput, dragStart, startPos
btn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = btn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then 
                dragging = false 
                SalvarConfig(btn.Position, _G.Ativado) -- Salva quando você para de arrastar
            end
        end)
    end
end)

btn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)

UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- 4. FUNÇÃO DE INVISIBILIDADE
local function AplicarEfeitoInvis()
    local char = player.Character
    if not char then return end

    local t = _G.Ativado and 1 or 0
    local vis = not _G.Ativado

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then 
        hum.DisplayDistanceType = _G.Ativado and Enum.HumanoidDisplayDistanceType.None or Enum.HumanoidDisplayDistanceType.Viewer 
    end

    for _, item in pairs(char:GetDescendants()) do
        if item:IsA("BasePart") or item:IsA("Decal") then
            if item.Name ~= "HumanoidRootPart" then 
                item.Transparency = t 
            end
        elseif item:IsA("ParticleEmitter") or item:IsA("Trail") or item:IsA("Beam") or item:IsA("Light") then
            item.Enabled = vis
        end
    end
end

-- 5. EVENTO DE CLIQUE
btn.MouseButton1Click:Connect(function()
    _G.Ativado = not _G.Ativado
    AtualizarBotaoUI()
    SalvarConfig(btn.Position, _G.Ativado) -- Salva o novo estado (ON/OFF)
    AplicarEfeitoInvis()
end)

-- 6. LOOP DE PERSISTÊNCIA (PARA RESPAWN E MANUTENÇÃO)
task.spawn(function()
    while task.wait(0.3) do
        if _G.InvisSessao ~= minhaSessao then break end
        pcall(AplicarEfeitoInvis)
    end
end)

print("MENU CARREGADO COM MEMÓRIA!")
