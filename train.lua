-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- CONFIG
_G.FOV_RADIUS = 65
_G.FOV_VISIBLE = true
_G.aimbotMode = "OFF" -- OFF / AUTO / LEGIT

-- PARTES DO CORPO
local selectedParts = {
    Head = true,
    HumanoidRootPart = false,
    UpperTorso = false
}

local bodyParts = {"Head"}

local function updateParts()
    bodyParts = {}
    for part, enabled in pairs(selectedParts) do
        if enabled then
            table.insert(bodyParts, part)
        end
    end
end

updateParts()

local aiming = false
local shooting = false

-- GUI
local gui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false

-- PANEL
local panel = Instance.new("Frame", gui)
panel.Size = UDim2.new(0, 240, 0, 320)
panel.Position = UDim2.new(0, 20, 0.5, -160)
panel.BackgroundColor3 = Color3.fromRGB(25,25,25)
panel.BackgroundTransparency = 0.1
panel.Active = true
Instance.new("UICorner", panel).CornerRadius = UDim.new(0,10)

-- HUB
local hub = Instance.new("TextButton", gui)
hub.Size = UDim2.new(0,50,0,50)
hub.Position = panel.Position
hub.Text = "⚙️"
hub.TextScaled = true
hub.BackgroundColor3 = Color3.fromRGB(35,35,35)
hub.TextColor3 = Color3.new(1,1,1)
hub.Visible = false
Instance.new("UICorner", hub).CornerRadius = UDim.new(1,0)

-- DRAG
local dragging, dragStart, startPos

local function setupDrag(guiElement)
    guiElement.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiElement.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    guiElement.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            guiElement.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

setupDrag(panel)
setupDrag(hub)

-- MINIMIZAR
local minimizeBtn = Instance.new("TextButton", panel)
minimizeBtn.Size = UDim2.new(0,30,0,30)
minimizeBtn.Position = UDim2.new(1,-35,0,5)
minimizeBtn.Text = "—"
minimizeBtn.BackgroundColor3 = Color3.fromRGB(45,45,45)
minimizeBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", minimizeBtn)

local function minimize()
    local tween = TweenService:Create(panel, TweenInfo.new(0.25), {
        Size = UDim2.new(0,0,0,0),
        BackgroundTransparency = 1
    })
    tween:Play()

    task.wait(0.2)
    panel.Visible = false

    hub.Position = panel.Position
    hub.Visible = true
end

local function maximize()
    panel.Visible = true
    panel.Size = UDim2.new(0,0,0,0)
    panel.BackgroundTransparency = 1

    local tween = TweenService:Create(panel, TweenInfo.new(0.25), {
        Size = UDim2.new(0,240,0,320),
        BackgroundTransparency = 0.1
    })
    tween:Play()

    hub.Visible = false
end

minimizeBtn.MouseButton1Click:Connect(minimize)
hub.MouseButton1Click:Connect(maximize)

-- BOTÃO AIMBOT
local aimbotBtn = Instance.new("TextButton", panel)
aimbotBtn.Size = UDim2.new(1,-20,0,30)
aimbotBtn.Position = UDim2.new(0,10,0,50)
aimbotBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
aimbotBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", aimbotBtn)

local function updateAimbotText()
    aimbotBtn.Text = "Aimbot: " .. _G.aimbotMode
end

aimbotBtn.MouseButton1Click:Connect(function()
    if _G.aimbotMode == "OFF" then
        _G.aimbotMode = "AUTO"
    elseif _G.aimbotMode == "AUTO" then
        _G.aimbotMode = "LEGIT"
    else
        _G.aimbotMode = "OFF"
    end
    updateAimbotText()
end)

updateAimbotText()

-- MENU PARTES
local partMenu = Instance.new("Frame", panel)
partMenu.Size = UDim2.new(1,-20,0,120)
partMenu.Position = UDim2.new(0,10,0,90)
partMenu.BackgroundColor3 = Color3.fromRGB(35,35,35)
partMenu.Visible = false
Instance.new("UICorner", partMenu)

local partsList = {"Head","HumanoidRootPart","UpperTorso"}

local y = 5
for _, partName in pairs(partsList) do
    local btn = Instance.new("TextButton", partMenu)
    btn.Size = UDim2.new(1,-10,0,25)
    btn.Position = UDim2.new(0,5,0,y)
    y += 30

    btn.Text = partName .. " [ON]"
    btn.BackgroundColor3 = Color3.fromRGB(60,60,60)

    btn.MouseButton1Click:Connect(function()
        selectedParts[partName] = not selectedParts[partName]
        btn.Text = partName .. (selectedParts[partName] and " [ON]" or " [OFF]")
        updateParts()
    end)
end

-- BOTÃO TARGET CONFIG
local partToggleBtn = Instance.new("TextButton", panel)
partToggleBtn.Size = UDim2.new(1,-20,0,30)
partToggleBtn.Position = UDim2.new(0,10,0,15)
partToggleBtn.Text = "🎯 Target Config"
partToggleBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
Instance.new("UICorner", partToggleBtn)

partToggleBtn.MouseButton1Click:Connect(function()
    partMenu.Visible = not partMenu.Visible
end)

-- FOV
local fovCircle = Drawing.new("Circle")
fovCircle.Transparency = 0.2
fovCircle.Thickness = 1.5
fovCircle.Filled = false

RunService.RenderStepped:Connect(function()
    fovCircle.Radius = _G.FOV_RADIUS
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    fovCircle.Visible = _G.FOV_VISIBLE
end)

-- INPUT
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aiming = true
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        shooting = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aiming = false
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        shooting = false
    end
end)

-- TARGET
local function getClosest()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local closest, dist = nil, _G.FOV_RADIUS

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            for _, partName in pairs(bodyParts) do
                local part = player.Character:FindFirstChild(partName)
                if part then
                    local pos, visible = Camera:WorldToViewportPoint(part.Position)
                    if visible then
                        local mag = (Vector2.new(pos.X,pos.Y)-center).Magnitude
                        if mag < dist then
                            dist = mag
                            closest = part
                        end
                    end
                end
            end
        end
    end

    return closest
end

-- AIMBOT
RunService.RenderStepped:Connect(function()
    if _G.aimbotMode == "OFF" then return end

    if _G.aimbotMode == "LEGIT" and not (aiming and shooting) then
        return
    end

    local targetPart = getClosest()

    if targetPart then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
    end
end)