local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Espera o personagem e ferramenta carregarem
repeat wait() until LocalPlayer.Character
local char = LocalPlayer.Character
local tool = char:FindFirstChildOfClass("Tool")

if not tool then
    warn("❌ Nenhuma arma (Tool) equipada.")
    return
end

local lines = {}
table.insert(lines, "🔫 DEBUG: Inspeção da arma \"" .. tool.Name .. "\"")
table.insert(lines, "----------------------------")

-- Atributos
table.insert(lines, "\n📦 Atributos:")
for key, value in pairs(tool:GetAttributes()) do
    local val = typeof(value) == "Vector2" and ("Vector2.new("..value.X..", "..value.Y..")") or tostring(value)
    table.insert(lines, "    " .. key .. " = " .. val)
end

-- Valores internos
table.insert(lines, "\n🧪 Valores internos:")
for _, obj in pairs(tool:GetDescendants()) do
    if obj:IsA("NumberValue") or obj:IsA("IntValue") or obj:IsA("BoolValue") or obj:IsA("StringValue") then
        table.insert(lines, "    " .. obj.Name .. " ("..obj.ClassName..") = " .. tostring(obj.Value))
    end
end

-- Juntar tudo como texto
local result = table.concat(lines, "\n")

-- Mostrar no console
print("\n\n====== DUMP DE ARMA ======\n" .. result .. "\n==========================")

-- (Opcional) Salvar em um StringValue no Workspace (visível pelo Explorer para copiar)
local dump = Instance.new("StringValue")
dump.Name = "GunDebug_" .. tool.Name
dump.Value = result
dump.Parent = workspace

-- Notificação simples (se suportado)
pcall(function()
    game.StarterGui:SetCore("SendNotification", {
        Title = "Debugger",
        Text = "Inspeção da arma salva como StringValue em Workspace.",
        Duration = 4
    })
end)
