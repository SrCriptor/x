-- 🔥 ANTI-DUPLICAÇÃO
if _G.AimbotScriptLoaded then
    if _G.AimbotCleanup then
        pcall(_G.AimbotCleanup)
    end
end
_G.AimbotScriptLoaded = true

-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- CONFIG
_G.FOV_RADIUS = 65
_G.FOV_VISIBLE = true
_G.aimbotMode = "OFF"
_G.espEnemiesEnabled = true
_G.espAlliesEnabled = false

-- PARTES
local selectedParts = {Head = true, HumanoidRootPart = false}
local bodyParts = {"Head"}

local function updateParts()
    bodyParts = {}
    for p,v in pairs(selectedParts) do
        if v then table.insert(bodyParts,p) end
    end
end
updateParts()

local aiming, shooting = false, false
local currentTarget = nil

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "MatrixUI"
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- PANEL
local panel = Instance.new("Frame", gui)
panel.Size = UDim2.new(0,260,0,320)
panel.Position = UDim2.new(0,20,0.5,-160)
panel.BackgroundColor3 = Color3.fromRGB(5,10,5)
panel.BorderSizePixel = 0
panel.Active = true

Instance.new("UICorner", panel).CornerRadius = UDim.new(0,10)

-- LIST LAYOUT (NÃO BUGA MAIS)
local layout = Instance.new("UIListLayout", panel)
layout.Padding = UDim.new(0,6)
layout.SortOrder = Enum.SortOrder.LayoutOrder

local padding = Instance.new("UIPadding", panel)
padding.PaddingTop = UDim.new(0,10)
padding.PaddingLeft = UDim.new(0,10)
padding.PaddingRight = UDim.new(0,10)

-- DRAG
local dragging, dragStart, startPos
panel.InputBegan:Connect(function(input)
    if input.UserInputType.Name:find("Mouse") then
        dragging=true
        dragStart=input.Position
        startPos=panel.Position
        input.Changed:Connect(function()
            if input.UserInputState==Enum.UserInputState.End then dragging=false end
        end)
    end
end)

panel.InputChanged:Connect(function(input)
    if dragging then
        local delta=input.Position-dragStart
        panel.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
    end
end)

-- HUB
local hub = Instance.new("TextButton", gui)
hub.Size = UDim2.new(0,50,0,50)
hub.Position = panel.Position
hub.Text = "●"
hub.Visible = false
hub.BackgroundColor3 = Color3.fromRGB(0,255,0)
Instance.new("UICorner", hub).CornerRadius = UDim.new(1,0)

hub.MouseButton1Click:Connect(function()
    panel.Visible = true
    hub.Visible = false
end)

-- MINIMIZAR
local minimize = Instance.new("TextButton")
minimize.Size = UDim2.new(1,0,0,25)
minimize.Text = "[ MINIMIZE ]"
minimize.TextColor3 = Color3.fromRGB(0,255,0)
minimize.BackgroundColor3 = Color3.fromRGB(10,20,10)
minimize.Parent = panel

minimize.MouseButton1Click:Connect(function()
    panel.Visible = false
    hub.Position = panel.Position
    hub.Visible = true
end)

-- FUNÇÃO BOTÃO MATRIX
local function createButton(text,callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,28)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(10,20,10)
    btn.TextColor3 = Color3.fromRGB(0,255,0)
    btn.Font = Enum.Font.Code
    btn.Parent = panel

    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(20,40,20)
    end)

    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(10,20,10)
    end)

    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- AIMBOT
local aimbotBtn = createButton("AIMBOT: OFF", function()
    if _G.aimbotMode=="OFF" then _G.aimbotMode="AUTO"
    elseif _G.aimbotMode=="AUTO" then _G.aimbotMode="LEGIT"
    else _G.aimbotMode="OFF" end
    aimbotBtn.Text = "AIMBOT: ".._G.aimbotMode
end)

-- ESP
createButton("ESP ENEMIES", function()
    _G.espEnemiesEnabled = not _G.espEnemiesEnabled
end)

createButton("ESP ALLIES", function()
    _G.espAlliesEnabled = not _G.espAlliesEnabled
end)

createButton("TOGGLE FOV", function()
    _G.FOV_VISIBLE = not _G.FOV_VISIBLE
end)

-- TARGET CONFIG
createButton("TARGET CONFIG", function()
    for p,v in pairs(selectedParts) do
        selectedParts[p] = not v
    end
    updateParts()
end)

-- FOV
local fovCircle = Drawing.new("Circle")
RunService.RenderStepped:Connect(function()
    fovCircle.Radius = _G.FOV_RADIUS
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
    fovCircle.Visible = _G.FOV_VISIBLE
end)

-- ESP
local highlights = {}
local function updateESP()
    for _,p in pairs(Players:GetPlayers()) do
        if p~=LocalPlayer and p.Character then
            local h = highlights[p] or Instance.new("Highlight",workspace)
            highlights[p]=h
            h.Adornee=p.Character
            h.Enabled=true

            local ally = p.Team==LocalPlayer.Team
            if p==currentTarget then
                h.FillColor=Color3.fromRGB(255,255,0)
            else
                h.FillColor = ally and Color3.fromRGB(0,255,255) or Color3.fromRGB(0,255,0)
            end
        end
    end
end

-- AIMBOT
local function getClosest()
    local center=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
    local closest,dist=nil,_G.FOV_RADIUS

    for _,p in pairs(Players:GetPlayers()) do
        if p~=LocalPlayer and p.Character then
            for _,partName in pairs(bodyParts) do
                local part=p.Character:FindFirstChild(partName)
                if part then
                    local pos,vis=Camera:WorldToViewportPoint(part.Position)
                    if vis then
                        local mag=(Vector2.new(pos.X,pos.Y)-center).Magnitude
                        if mag<dist then dist=mag closest=p end
                    end
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    updateESP()

    if _G.aimbotMode=="OFF" then return end

    local target=getClosest()
    currentTarget=target

    if target and target.Character then
        local part=target.Character:FindFirstChild(bodyParts[1])
        if part then
            Camera.CFrame=CFrame.new(Camera.CFrame.Position,part.Position)
        end
    end
end)

-- CLEANUP
_G.AimbotCleanup = function()
    if gui then gui:Destroy() end
    if fovCircle then pcall(function() fovCircle:Remove() end) end
end
