--[[ 
 🔍 DEBUGGER DE CLIQUES E INPUTS
 Rastreia tudo que o jogador clicar (botões na tela) e teclas pressionadas.
 Útil para descobrir nomes de botões e analisar GUI de jogos.
]]
local char = game.Players.LocalPlayer.Character
local tool = char:FindFirstChildOfClass("Tool")

if tool then
    if tool:FindFirstChild("Ammo") then
        tool.Ammo.Value = 999
    end
    tool:SetAttribute("rateOfFire", 9999)
    tool:SetAttribute("reloadTime", 0)
    tool:SetAttribute("recoilMax", Vector2.new(0, 0))
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Aguarda o PlayerGui estar disponível
repeat wait() until LocalPlayer:FindFirstChild("PlayerGui")
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

print("🟢 DEBUGGER ATIVO - Aguardando interfaces...")

-- Função para conectar a qualquer botão
local function trackButton(obj)
    if obj:IsA("TextButton") or obj:IsA("ImageButton") then
        obj.MouseButton1Click:Connect(function()
            print("🖱️ Clique em botão: " .. (obj:GetFullName()))
        end)
    end
end

-- Rastrear botões já existentes
for _, gui in pairs(playerGui:GetDescendants()) do
    trackButton(gui)
end

-- Rastrear novos botões adicionados
playerGui.DescendantAdded:Connect(function(obj)
    trackButton(obj)
end)

-- Rastrear teclas pressionadas
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            print("⌨️ Tecla pressionada: " .. input.KeyCode.Name)
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            print("🖱️ Clique do mouse detectado.")
        end
    end
end)
