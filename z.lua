local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Criar GUI de Debug
local gui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
gui.Name = "DebuggerGUI"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 400, 0, 300)
frame.Position = UDim2.new(1, -410, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel", frame)
title.Text = "🔍 Krypton Debugger"
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.Code
title.TextSize = 20

local scrolling = Instance.new("ScrollingFrame", frame)
scrolling.Size = UDim2.new(1, -10, 1, -40)
scrolling.Position = UDim2.new(0, 5, 0, 35)
scrolling.BackgroundTransparency = 1
scrolling.CanvasSize = UDim2.new(0, 0, 10, 0)
scrolling.ScrollBarThickness = 4

local layout = Instance.new("UIListLayout", scrolling)
layout.SortOrder = Enum.SortOrder.LayoutOrder

-- Função para adicionar linha
local function addLine(text)
    local label = Instance.new("TextLabel")
    label.Text = text
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(200, 255, 200)
    label.Font = Enum.Font.Code
    label.TextSize = 14
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = scrolling

    -- Limitar quantidade de linhas
    if #scrolling:GetChildren() > 200 then
        scrolling:GetChildren()[1]:Destroy()
    end

    -- Scroll automático para o fim
    RunService.RenderStepped:Wait()
    scrolling.CanvasPosition = Vector2.new(0, scrolling.AbsoluteCanvasSize.Y)
end

-- LOG INPUT
UIS.InputBegan:Connect(function(input, processed)
    if not processed then
        local name = input.KeyCode and input.KeyCode.Name or input.UserInputType.Name
        addLine("🎮 Input: " .. name)
    end
end)

-- LOG CLIQUES EM BOTÕES
LocalPlayer.PlayerGui.DescendantAdded:Connect(function(obj)
    if obj:IsA("TextButton") or obj:IsA("ImageButton") then
        obj.MouseButton1Click:Connect(function()
            addLine("🖱️ Botão clicado: " .. obj:GetFullName())
        end)
    end
end)

-- LOG MUDANÇA DE VALORES NA ARMA
local function watchTool(tool)
    for _, v in pairs(tool:GetDescendants()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") or v:IsA("BoolValue") then
            v:GetPropertyChangedSignal("Value"):Connect(function()
                addLine("📊 Valor mudado: " .. v:GetFullName() .. " = " .. tostring(v.Value))
            end)
        end
    end
end

-- Quando equipar arma
LocalPlayer.CharacterAdded:Connect(function(char)
    char.ChildAdded:Connect(function(obj)
        if obj:IsA("Tool") then
            addLine("🧰 Nova Tool: " .. obj.Name)
            watchTool(obj)
        end
    end)
end)

-- LOG REMOTES (__namecall hook)
local mt = getrawmetatable(game)
setreadonly(mt, false)
local old = mt.__namecall

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if method == "FireServer" or method == "InvokeServer" then
        addLine("📡 Remote: " .. self:GetFullName() .. " → " .. method)
    end
    return old(self, ...)
end)
setreadonly(mt, true)

addLine("✅ Debugger iniciado")
