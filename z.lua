--[[
Debugger completo para monitorar ações/funções no Roblox
Envia dados organizados para Discord webhook e exibe GUI no Delta Executor (mobile compatível).

IMPORTANTE:
- Use no ambiente local (LocalScript)
- Substitua o webhook abaixo pela sua URL

Feito para monitorar: tiro, pulo, recarregar, rapid fire, e tudo que puder ser "hookado"
--]]

local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local WEBHOOK_URL = "https://discord.com/api/webhooks/1396028353500287026/9O4ofAZ6e5jRiGniJM3vJ0NMLlYqjLu9oBcVJGc8xdsLFb1u9vGAYA5nvyFLlMNr5I2Z"

-- Tabela para armazenar logs antes de enviar ao webhook
local logs = {}

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DebuggerGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0.4, 0, 0.4, 0)
Frame.Position = UDim2.new(0.3, 0, 0.55, 0)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.BorderSizePixel = 1
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Text = "🛠 Debugger de Ações (Pressione D para mostrar/ocultar)"
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.new(0.8, 0.8, 0.8)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 18
Title.Parent = Frame

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -10, 1, -35)
ScrollFrame.Position = UDim2.new(0, 5, 0, 30)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.ScrollBarThickness = 6
ScrollFrame.Parent = Frame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = ScrollFrame

-- Alternar visibilidade da GUI com a tecla D
local guiVisible = true
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.D then
		guiVisible = not guiVisible
		ScreenGui.Enabled = guiVisible
	end
end)

ScreenGui.Enabled = guiVisible

-- Função para adicionar uma linha na GUI
local function addLogLine(text)
	local label = Instance.new("TextLabel")
	label.Text = text
	label.TextColor3 = Color3.new(1, 1, 1)
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, 20)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.Code
	label.TextSize = 14
	label.Parent = ScrollFrame
	
	-- Scrolla para baixo automaticamente
	wait(0.05)
	ScrollFrame.CanvasPosition = Vector2.new(0, ScrollFrame.AbsoluteCanvasSize.Y)
end

-- Função para enviar dados para o webhook (JSON formatado)
local function sendToWebhook(data)
    local success, err = pcall(function()
        local json = HttpService:JSONEncode(data)
        HttpService:PostAsync(WEBHOOK_URL, json, Enum.HttpContentType.ApplicationJson)
    end)
    if not success then
        addLogLine("[Erro ao enviar webhook]: "..tostring(err))
    end
end

-- Função para capturar stack trace para saber origem da chamada
local function getStackTrace()
	local trace = debug.traceback()
	local lines = {}
	for line in trace:gmatch("[^\n]+") do
		table.insert(lines, line)
	end
	-- Retornar as primeiras 5 linhas depois da primeira (que é a própria função)
	return table.concat({lines[3], lines[4], lines[5], lines[6], lines[7]}, "\n")
end

-- Função para registrar uma ação
local function logAction(actionName, details)
	local logEntry = {
		timestamp = os.date("%Y-%m-%d %H:%M:%S"),
		player = LocalPlayer.Name,
		action = actionName,
		details = details or "Nenhum detalhe",
		stack = getStackTrace()
	}
	table.insert(logs, logEntry)
	
	-- Atualiza GUI
	addLogLine(string.format("[%s] %s - %s", logEntry.timestamp, actionName, tostring(details)))
	
	-- Enviar para webhook em lotes de 5
	if #logs >= 5 then
		local payload = {
			username = "Roblox Debugger",
			embeds = {}
		}
		for i, entry in ipairs(logs) do
			table.insert(payload.embeds, {
				title = entry.action,
				description = string.format("**Player:** %s\n**Detalhes:** %s\n**Stack trace:**\n```lua\n%s\n```", entry.player, entry.details, entry.stack),
				color = 16711680
			})
		end
		sendToWebhook(payload)
		logs = {} -- limpa logs enviados
	end
end

-- Hook de funções importantes

-- 1. Detectar tiros (Assumindo RemoteEvents)
for _, v in pairs(game:GetDescendants()) do
	if v:IsA("RemoteEvent") and string.find(v.Name:lower(), "shoot") then
		local origFire = v.FireServer
		v.FireServer = function(self, ...)
			logAction("Tiro disparado", "RemoteEvent: "..v.Name)
			return origFire(self, ...)
		end
	end
end

-- 2. Detectar pulos (modificando JumpRequest)
UserInputService.JumpRequest:Connect(function()
	logAction("Pulo", "Usuário pulou")
end)

-- 3. Detectar recarregar e rapid fire - tentando hookar funções globais (exemplo genérico)
-- Aqui você precisa adaptar para o seu jogo, ex:
local mt = getrawmetatable(game)
local oldIndex = mt.__index
setreadonly(mt, false)

mt.__index = newcclosure(function(t,k)
	if tostring(k):lower():find("reload") or tostring(k):lower():find("fire") then
		logAction("Método acessado", "Campo: "..tostring(k))
	end
	return oldIndex(t,k)
end)

setreadonly(mt, true)

-- 4. Hook de Input para clicks, teclas e etc
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	logAction("Input Began", "Tipo: "..input.UserInputType.Name..", KeyCode: "..tostring(input.KeyCode))
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	logAction("Input Ended", "Tipo: "..input.UserInputType.Name..", KeyCode: "..tostring(input.KeyCode))
end)

-- 5. Hook em RemoteFunctions, RemoteEvents genéricos para capturar todas chamadas
local function hookRemote(remote)
	local origInvoke = remote.InvokeServer
	if origInvoke then
		remote.InvokeServer = function(self, ...)
			logAction("RemoteFunction InvokeServer", remote.Name)
			return origInvoke(self, ...)
		end
	end
	local origFire = remote.FireServer
	if origFire then
		remote.FireServer = function(self, ...)
			logAction("RemoteEvent FireServer", remote.Name)
			return origFire(self, ...)
		end
	end
end

for _, rem in pairs(game:GetDescendants()) do
	if rem:IsA("RemoteEvent") or rem:IsA("RemoteFunction") then
		hookRemote(rem)
	end
end

-- 6. Capturar mudanças importantes em valores (exemplo: se a arma tem um "RapidFire" BoolValue)
local function monitorValue(value)
	if value:IsA("BoolValue") or value:IsA("NumberValue") or value:IsA("StringValue") then
		value.Changed:Connect(function(new)
			logAction("Valor alterado", string.format("%s mudou para %s", value.Name, tostring(new)))
		end)
	end
end

for _, v in pairs(game:GetDescendants()) do
	monitorValue(v)
end

-- Atualização contínua da GUI para evitar travar (limpa após 100 linhas)
RunService.Heartbeat:Connect(function()
	if #ScrollFrame:GetChildren() > 100 then
		for _, child in pairs(ScrollFrame:GetChildren()) do
			if child:IsA("TextLabel") then
				child:Destroy()
			end
		end
	end
end)

-- Mensagem inicial
addLogLine("Debugger iniciado. Aperte D para mostrar/ocultar.")

