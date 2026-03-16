-- SCRIPT TOTALMENTE FUNCIONAL - INVISIBILIDADE + ARRASTE PROFISSIONAL
local UIS = game:GetService("UserInputService")
local player = game:GetService("Players").LocalPlayer
local pgui = player:WaitForChild("PlayerGui")

-- 1. LIMPA VERSÕES ANTIGAS PARA EVITAR BUG
if pgui:FindFirstChild("InvisSystem_Final") then pgui["InvisSystem_Final"]:Destroy() end
_G.InvisSessao = tick()
local minhaSessao = _G.InvisSessao
_G.Ativado = false

-- 2. CRIANDO A INTERFACE (GUI)
local sg = Instance.new("ScreenGui", pgui)
sg.Name = "InvisSystem_Final"
sg.ResetOnSpawn = false
sg.DisplayOrder = 999 -- Garante que fique por cima de tudo

local btn = Instance.new("TextButton", sg)
btn.Size = UDim2.new(0, 160, 0, 50)
btn.Position = UDim2.new(0.5, -80, 0.5, -25) -- Nasce no centro da tela
btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
btn.BorderSizePixel = 2
btn.BorderColor3 = Color3.fromRGB(200, 0, 0)
btn.Text = "INVISIBILIDADE: OFF"
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Font = Enum.Font.SourceSansBold
btn.TextSize = 16
btn.ClipsDescendants = true
btn.Active = true
btn.Draggable = false -- Desativamos o nativo que buga e usamos o código abaixo

-- Arredondamento
local corner = Instance.new("UICorner", btn)
corner.CornerRadius = UDim.new(0, 10)

-- 3. SISTEMA DE ARRASTE (ESTE NÃO FALHA)
local dragging, dragInput, dragStart, startPos
local function update(input)
	local delta = input.Position - dragStart
	btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
btn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = btn.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)
btn.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UIS.InputChanged:Connect(function(input)
	if input == dragInput and dragging then update(input) end
end)

-- 4. FUNÇÃO DE INVISIBILIDADE (TOTAL)
local function AtualizarInvis()
	local char = player.Character
	if not char then return end

	local t = _G.Ativado and 1 or 0
	local vis = not _G.Ativado

	-- Esconde Nome/Barra de Vida
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then 
		hum.DisplayDistanceType = _G.Ativado and Enum.HumanoidDisplayDistanceType.None or Enum.HumanoidDisplayDistanceType.Viewer 
	end

	-- Varre todos os objetos (Corpo, Espada, Acessórios, Brilhos)
	for _, item in pairs(char:GetDescendants()) do
		if item:IsA("BasePart") or item:IsA("Decal") then
			if item.Name ~= "HumanoidRootPart" then 
				item.Transparency = t 
			end
		elseif item:IsA("ParticleEmitter") or item:IsA("Trail") or item:IsA("Beam") or item:IsA("Light") then
			item.Enabled = vis
		elseif item:IsA("SelectionBox") or item:IsA("BoxHandleAdornment") or item:IsA("SelectionPartLasso") then
			item.Visible = vis
		end
	end
end

-- 5. EVENTO DE CLIQUE (ATIVAR/DESATIVAR)
btn.MouseButton1Click:Connect(function()
	_G.Ativado = not _G.Ativado
	if _G.Ativado then
		btn.Text = "INVISIBILIDADE: ON"
		btn.BorderColor3 = Color3.fromRGB(0, 255, 0)
		btn.BackgroundColor3 = Color3.fromRGB(0, 50, 0)
	else
		btn.Text = "INVISIBILIDADE: OFF"
		btn.BorderColor3 = Color3.fromRGB(255, 0, 0)
		btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	end
	AtualizarInvis()
end)

-- 6. LOOP DE PERSISTÊNCIA (PARA QUANDO MUDAR DE MAPA OU RESETAR)
task.spawn(function()
	while task.wait(0.2) do -- Checa muito rápido
		if _G.InvisSessao ~= minhaSessao then break end
		pcall(AtualizarInvis)
	end
end)

print("MENU CARREGADO! Clique para ativar e segure para arrastar.")
