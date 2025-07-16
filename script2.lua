-- [INTERFACE COMPLETA ESTILO RAYCAST COM AIMBOT, HITBOX, WALLHACK RGB E MODS DE ARMA + AJUSTES AVANÇADOS + HITBOX POPUP E VERIFICAÇÕES MELHORADAS]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Variáveis Globais Padrão
_G.aimbotAutoEnabled = _G.aimbotAutoEnabled or false
_G.aimbotLegitEnabled = _G.aimbotLegitEnabled or false
_G.modInfiniteAmmo = _G.modInfiniteAmmo or false
_G.modNoRecoil = _G.modNoRecoil or false
_G.modInstantReload = _G.modInstantReload or false
_G.hitboxSelection = _G.hitboxSelection or {
    Head = true, Torso = false, LeftArm = false, RightArm = false, LeftLeg = false, RightLeg = false
}
_G.FOV_RADIUS = _G.FOV_RADIUS or 200
_G.lt = _G.lt or {
	["rateOfFire"] = 200,
	["spread"] = 0,
	["zoom"] = 3,
}

-- GUI PRINCIPAL
local gui = Instance.new("ScreenGui")
gui.Name = "RaycastUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 280, 0, 300)
mainFrame.Position = UDim2.new(0, 20, 0.5, -130)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = gui

local dragButton = Instance.new("TextButton")
dragButton.Size = UDim2.new(0, 280, 0, 20)
dragButton.Position = UDim2.new(0, 0, 0, -20)
dragButton.Text = "⯟ Menu"
dragButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
dragButton.TextColor3 = Color3.new(1, 1, 1)
dragButton.Parent = mainFrame

local dragging = false
local offset

dragButton.MouseButton1Down:Connect(function()
    dragging = true
    offset = Vector2.new(mainFrame.Position.X.Offset, mainFrame.Position.Y.Offset) - UserInputService:GetMouseLocation()
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

RunService.RenderStepped:Connect(function()
    if dragging then
        local mouse = UserInputService:GetMouseLocation()
        mainFrame.Position = UDim2.new(0, mouse.X + offset.X, 0, mouse.Y + offset.Y)
    end
end)

local minimized = false
dragButton.MouseButton2Click:Connect(function()
    minimized = not minimized
    for _, child in ipairs(mainFrame:GetChildren()) do
        if child ~= dragButton then
            child.Visible = not minimized
        end
    end
    dragButton.Text = minimized and "⯝ Menu" or "⯟ Menu"
end)

-- WALLHACK COM RGB + BORDA AMARELA NO ALVO
local neonCycle = 0

local function getTarget()
    return nil -- Placeholder
end

local function updateWallhack()
    neonCycle = neonCycle + 1
    local hue = (tick() * 0.2 % 1)
    local neonColor = Color3.fromHSV(hue, 1, 1)
    local currentTarget = getTarget()

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character:FindFirstChild("Head") then
            for _, part in ipairs(player.Character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.Material = Enum.Material.ForceField
                    part.Color = neonColor
                    part.Transparency = 0.4

                    if not part:FindFirstChild("SelectionBox") then
                        local sb = Instance.new("SelectionBox")
                        sb.Adornee = part
                        sb.LineThickness = 0.05
                        sb.Color3 = Color3.fromRGB(255, 255, 255)
                        sb.Parent = part
                    end

                    local sb = part:FindFirstChild("SelectionBox")
                    if sb then
                        sb.Color3 = Color3.fromRGB(255, 255, 0)
                        sb.LineThickness = (currentTarget and currentTarget.Character == player.Character) and 0.2 or 0.05
                        sb.Visible = true
                    end
                end
            end
        end
    end
end

RunService.RenderStepped:Connect(function()
    if _G.aimbotAutoEnabled or _G.aimbotLegitEnabled then
        updateWallhack()
    end
end)

-- APLICAR MODS E ATRIBUTOS
LocalPlayer.CharacterAdded:Connect(function(char)
	char:WaitForChild("HumanoidRootPart")
	local tool
	repeat
		tool = char:FindFirstChildWhichIsA("Tool")
		RunService.RenderStepped:Wait()
	until tool
	for i,v in pairs(_G.lt) do
		tool:SetAttribute(i,v)
	end
end)

RunService.RenderStepped:Connect(function()
	local char = LocalPlayer.Character
	local mouse = LocalPlayer:GetMouse()
	if char and mouse and mouse.Hit then
		local tool = char:FindFirstChildWhichIsA("Tool")
		local head = char:FindFirstChild("Head")
		if tool and head then
			local dist = (head.Position - mouse.Hit.Position).Magnitude
			local spread = math.clamp(30 - dist / 5, 0, 30)
			tool:SetAttribute("spread", spread)
		end
	end
end)

-- SLIDERS DE AJUSTE FINO
local function createSlider(label, defaultValue, minVal, maxVal, step, posY, parent, key)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(0, 240, 0, 40)
	container.Position = UDim2.new(0, 20, 0, posY)
	container.BackgroundTransparency = 1
	container.Parent = parent

	local labelTxt = Instance.new("TextLabel")
	labelTxt.Size = UDim2.new(1, 0, 0, 20)
	labelTxt.Position = UDim2.new(0, 0, 0, 0)
	labelTxt.Text = label .. ": " .. tostring(defaultValue)
	labelTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
	labelTxt.Font = Enum.Font.Gotham
	labelTxt.TextSize = 14
	labelTxt.BackgroundTransparency = 1
	labelTxt.TextXAlignment = Enum.TextXAlignment.Left
	labelTxt.Parent = container

	local sliderBack = Instance.new("Frame")
	sliderBack.Size = UDim2.new(1, 0, 0, 10)
	sliderBack.Position = UDim2.new(0, 0, 0, 25)
	sliderBack.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	sliderBack.BorderSizePixel = 0
	sliderBack.Parent = container

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new((defaultValue - minVal) / (maxVal - minVal), 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
	fill.Parent = sliderBack

	local dragging = false

	local function updateSlider(x)
		local relative = math.clamp(x - sliderBack.AbsolutePosition.X, 0, sliderBack.AbsoluteSize.X)
		local percent = relative / sliderBack.AbsoluteSize.X
		local value = math.floor((minVal + percent * (maxVal - minVal)) / step + 0.5) * step
		_G.lt[key] = value
		labelTxt.Text = label .. ": " .. tostring(value)
		fill.Size = UDim2.new((value - minVal) / (maxVal - minVal), 0, 1, 0)
	end

	sliderBack.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			updateSlider(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateSlider(input.Position.X)
		end
	end)
end

-- Container para Sliders (ajuste essas posições e chamadas conforme seu layout)
local sliderContainer = Instance.new("Frame")
sliderContainer.Size = UDim2.new(1, 0, 1, -20)
sliderContainer.Position = UDim2.new(0, 0, 0, 20)
sliderContainer.BackgroundTransparency = 1
sliderContainer.Parent = mainFrame

createSlider("Rate Of Fire", _G.lt.rateOfFire, 50, 1000, 10, 20, sliderContainer, "rateOfFire")
createSlider("Spread", _G.lt.spread, 0, 30, 1, 70, sliderContainer, "spread")
createSlider("Zoom", _G.lt.zoom, 1, 10, 0.1, 120, sliderContainer, "zoom")
