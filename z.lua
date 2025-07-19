local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local WEBHOOK_URL = "https://discord.com/api/webhooks/1396028353500287026/9O4ofAZ6e5jRiGniJM3vJ0NMLlYqjLu9oBcVJGc8xdsLFb1u9vGAYA5nvyFLlMNr5I2Z"

local logs = {}

-- GUI para mobile, maior e responsivo
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DebuggerGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0.9, 0, 0.4, 0)
Frame.Position = UDim2.new(0.05, 0, 0.55, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 1
Frame.AnchorPoint = Vector2.new(0, 0)
Frame.Parent = ScreenGui
Frame.Visible = true

local Title = Instance.new("TextLabel")
Title.Text = "🛠 Debugger de Ações (Toque para mostrar/ocultar)"
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Title.TextColor3 = Color3.new(0.9, 0.9, 0.9)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 20
Title.Parent = Frame

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -10, 1, -50)
ScrollFrame.Position = UDim2.new(0, 5, 0, 45)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.CanvasSize = UDim2.new(0, 0, 5, 0)
ScrollFrame.ScrollBarThickness = 10
ScrollFrame.Parent = Frame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.Parent = ScrollFrame

-- Toggle visibilidade ao tocar no título (mobile friendly)
Title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		Frame.Visible = not Frame.Visible
	end
end)

local function addLogLine(text)
	local label = Instance.new("TextLabel")
	label.Text = text
	label.TextColor3 = Color3.new(1, 1, 1)
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, 25)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.Code
	label.TextSize = 16
	label.Parent = ScrollFrame
	
	-- Atualiza o CanvasSize para poder rolar
	ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
	
	-- Scrolla para o final
	RunService.Heartbeat:Wait()
	ScrollFrame.CanvasPosition = Vector2.new(0, ScrollFrame.AbsoluteCanvasSize.Y)
end

local function sendToWebhook(data)
	spawn(function()
		local success, err = pcall(function()
			local json = HttpService:JSONEncode(data)
			HttpService:PostAsync(WEBHOOK_URL, json, Enum.HttpContentType.ApplicationJson)
		end)
		if not success then
			addLogLine("[Erro ao enviar webhook]: "..tostring(err))
		end
	end)
end

local function getStackTrace()
	local trace = debug.traceback()
	local lines = {}
	for line in trace:gmatch("[^\n]+") do
		table.insert(lines, line)
	end
	return table.concat({lines[3], lines[4], lines[5], lines[6], lines[7]}, "\n")
end

local function logAction(actionName, details)
	local logEntry = {
		timestamp = os.date("%H:%M:%S"),
		player = LocalPlayer.Name,
		action = actionName,
		details = details or "Nenhum detalhe",
		stack = getStackTrace()
	}
	table.insert(logs, logEntry)
	addLogLine(string.format("[%s] %s - %s", logEntry.timestamp, actionName, tostring(details)))
	if #logs >= 5 then
		local payload = {
			username = "Debugger Roblox",
			embeds = {}
		}
		for _, entry in ipairs(logs) do
			table.insert(payload.embeds, {
				title = entry.action,
				description = string.format("**Player:** %s\n**Detalhes:** %s\n```lua\n%s\n```", entry.player, entry.details, entry.stack),
				color = 0x00FF00
			})
		end
		sendToWebhook(payload)
		logs = {}
	end
end

-- Detectar pulos (UserInputService funciona em mobile)
UserInputService.JumpRequest:Connect(function()
	logAction("Pulo", "Usuário pulou")
end)

-- Detectar inputs (touch e botões)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	local inputType = input.UserInputType.Name
	local key = tostring(input.KeyCode)
	logAction("Input Began", "Tipo: "..inputType..", Key: "..key)
end)

-- Hook seguro para RemoteEvents com "shoot" no nome
for _, v in pairs(game:GetDescendants()) do
	if v:IsA("RemoteEvent") and string.find(v.Name:lower(), "shoot") then
		local success, origFire = pcall(function() return v.FireServer end)
		if success and type(origFire) == "function" then
			v.FireServer = function(self, ...)
				logAction("Tiro disparado", "RemoteEvent: "..v.Name)
				return origFire(self, ...)
			end
		end
	end
end

addLogLine("Debugger ativo. Toque no título para abrir/fechar.")
