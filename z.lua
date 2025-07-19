-- DEBUGGER: Escuta cliques em todos os botões da interface
local function watchClicksInGui(gui)
    local function hookButton(obj)
        if obj:IsA("TextButton") or obj:IsA("ImageButton") then
            obj.MouseButton1Click:Connect(function()
                warn("[DEBUG] Botão clicado: " .. (obj.Name or tostring(obj)))
            end)
        end
    end

    -- Monitorar botões já existentes
    for _, obj in pairs(gui:GetDescendants()) do
        hookButton(obj)
    end

    -- Monitorar botões que forem adicionados no futuro
    gui.DescendantAdded:Connect(function(obj)
        hookButton(obj)
    end)
end

-- Esperar até que o PlayerGui e GUI existam
local Player = game:GetService("Players").LocalPlayer
repeat wait() until Player:FindFirstChild("PlayerGui")

-- Assumindo que seu GUI é o "MobileAimbotGUI"
local myGui = Player.PlayerGui:FindFirstChild("MobileAimbotGUI")
if myGui then
    watchClicksInGui(myGui)
    warn("[DEBUG] Debugger de botões ativado!")
else
    warn("[DEBUG] GUI não encontrado.")
end
