-- Logger completo de ações e eventos no jogo (uso local)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UIS = game:GetService("UserInputService")

-- LOG CLIQUES E INPUTS
UIS.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        print("🎮 Input:", input.UserInputType, input.KeyCode.Name)
    end
end)

-- LOG CLIQUES EM BOTÕES
LocalPlayer.PlayerGui.DescendantAdded:Connect(function(desc)
    if desc:IsA("TextButton") or desc:IsA("ImageButton") then
        desc.MouseButton1Click:Connect(function()
            print("🖱️ Botão clicado:", desc:GetFullName())
        end)
    end
end)

-- LOG MUDANÇAS DE PROPRIEDADES EM TEMPO REAL
local function watchChanges(obj)
    for _, v in pairs(obj:GetChildren()) do
        if v:IsA("NumberValue") or v:IsA("BoolValue") or v:IsA("IntValue") then
            v:GetPropertyChangedSignal("Value"):Connect(function()
                print("🔁", v:GetFullName(), "mudou para", v.Value)
            end)
        end
    end
end

-- Observar ferramentas/valores no personagem
LocalPlayer.CharacterAdded:Connect(function(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            print("🧰 Nova Tool equipada:", child.Name)
            watchChanges(child)
        end
    end)
end)

-- INTERCEPTAR FIRE/INVOKE DE REMOTES
local mt = getrawmetatable(game)
setreadonly(mt, false)
local oldNamecall = mt.__namecall

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if method == "FireServer" or method == "InvokeServer" then
        print("📡 Remote:", self:GetFullName(), "→", method)
        print("   Args:", ...)
    end
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)
